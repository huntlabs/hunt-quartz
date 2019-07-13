
/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 *
 */

module hunt.quartz.core.QuartzSchedulerThread;

import hunt.quartz.core.JobRunShell;
import hunt.quartz.core.QuartzScheduler;
import hunt.quartz.core.QuartzSchedulerResources;

import hunt.quartz.Exceptions;
import hunt.quartz.Trigger;
import hunt.quartz.Trigger : CompletedExecutionInstruction;
import hunt.quartz.spi.JobStore;
import hunt.quartz.spi.OperableTrigger;
import hunt.quartz.spi.TriggerFiredBundle;
import hunt.quartz.spi.TriggerFiredResult;

import hunt.Exceptions;
import hunt.concurrency.atomic.AtomicHelper;
import hunt.concurrency.thread;
import hunt.collection.ArrayList;
import hunt.collection.List;
import hunt.logging.ConsoleLogger;
import hunt.time.LocalDateTime;
import hunt.time.Instant;
import hunt.time.ZoneOffset;
import hunt.util.DateTime;

import core.sync.condition;
import core.sync.mutex;
import core.thread;

import std.algorithm;
import std.conv;
import std.random;

/**
 * <p>
 * The thread responsible for performing the work of firing <code>{@link Trigger}</code>
 * s that are registered with the <code>{@link QuartzScheduler}</code>.
 * </p>
 *
 * @see QuartzScheduler
 * @see hunt.quartz.Job
 * @see Trigger
 *
 * @author James House
 */
class QuartzSchedulerThread : ThreadEx {
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Data members.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */
    private QuartzScheduler qs;

    private QuartzSchedulerResources qsRsrcs;

    private Mutex sigLock;
    private Condition sigCondition;

    private bool signaled;
    private long signaledNextFireTime;

    private bool paused;

    private shared bool halted;

    // private Random random = new Random(DateTimeHelper.currentTimeMillis());

    // When the scheduler finds there is no current trigger to fire, how long
    // it should wait until checking again...
    private enum long DEFAULT_IDLE_WAIT_TIME = 30L * 1000L;

    private long idleWaitTime = DEFAULT_IDLE_WAIT_TIME;

    private int idleWaitVariablness = 7 * 1000;


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Constructors.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Construct a new <code>QuartzSchedulerThread</code> for the given
     * <code>QuartzScheduler</code> as a non-daemon <code>Thread</code>
     * with normal priority.
     * </p>
     */
    this(QuartzScheduler qs, QuartzSchedulerResources qsRsrcs) {
        this(qs, qsRsrcs, qsRsrcs.getMakeSchedulerThreadDaemon(), Thread.PRIORITY_DEFAULT);
    }

    /**
     * <p>
     * Construct a new <code>QuartzSchedulerThread</code> for the given
     * <code>QuartzScheduler</code> as a <code>Thread</code> with the given
     * attributes.
     * </p>
     */
    this(QuartzScheduler qs, QuartzSchedulerResources qsRsrcs, bool setDaemon, int threadPrio) {
        super(qs.getSchedulerThreadGroup(), qsRsrcs.getThreadName());
        sigLock = new Mutex();
        sigCondition = new Condition(sigLock);
        this.qs = qs;
        this.qsRsrcs = qsRsrcs;
        this.isDaemon(setDaemon);
        if(qsRsrcs.isThreadsInheritInitializersClassLoadContext()) {
            info("QuartzSchedulerThread Inheriting ContextClassLoader of thread: " ~ Thread.getThis().name());
            // this.setContextClassLoader(Thread.getThis().getContextClassLoader());
        }

        this.priority(threadPrio);

        // start the underlying thread, but put this object into the 'paused'
        // state
        // so processing doesn't start yet...
        paused = true;
        halted = false;

        trace("Initializing QuartzSchedulerThread...");
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Interface.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    void setIdleWaitTime(long waitTime) {
        idleWaitTime = waitTime;
        idleWaitVariablness = cast(int) (waitTime * 0.2);
    }

    private long getRandomizedIdleWaitTime() {
        return idleWaitTime - uniform(0, idleWaitVariablness); // random.nextInt(idleWaitVariablness);
    }

    /**
     * <p>
     * Signals the main processing loop to pause at the next possible point.
     * </p>
     */
    void togglePause(bool pause) {
        sigLock.lock();
        scope(exit) sigLock.unlock();
         {
            paused = pause;

            if (paused) {
                signalSchedulingChange(0);
            } else {
                sigCondition.notifyAll();
            }
        }
    }

    /**
     * <p>
     * Signals the main processing loop to pause at the next possible point.
     * </p>
     */
    void halt(bool wait) {
        sigLock.lock();
        scope(exit) sigLock.unlock();

        halted = true;

        if (paused) {
            sigCondition.notifyAll();
        } else {
            signalSchedulingChange(0);
        }

        if (wait) {
            bool interrupted = false;
            try {
                while (true) {
                    try {
                        implementationMissing(false);
                        // FIXME: Needing refactor or cleanup -@zxp at 3/14/2019, 10:06:18 AM
                        // 
                        // join();
                        break;
                    } catch (InterruptedException _) {
                        interrupted = true;
                    }
                }
            } finally {
                if (interrupted) {
                    ThreadEx t = cast(ThreadEx)Thread.getThis();
                    if(t !is null) t.interrupt();
                }
            }
        }
    }

    bool isPaused() {
        return paused;
    }

    /**
     * <p>
     * Signals the main processing loop that a change in scheduling has been
     * made - in order to interrupt any sleeping that may be occuring while
     * waiting for the fire time to arrive.
     * </p>
     *
     * @param candidateNewNextFireTime the time (in millis) when the newly scheduled trigger
     * will fire.  If this method is being called do to some other even (rather
     * than scheduling a trigger), the caller should pass zero (0).
     */
    void signalSchedulingChange(long candidateNewNextFireTime) {        
        sigLock.lock();
        scope(exit) sigLock.unlock();
        {
            signaled = true;
            signaledNextFireTime = candidateNewNextFireTime;
            sigCondition.notifyAll();
        }
    }

    void clearSignaledSchedulingChange() {
        sigLock.lock();
        scope(exit) sigLock.unlock();
        {
            signaled = false;
            signaledNextFireTime = 0;
        }
    }

    bool isScheduleChanged() {        
        sigLock.lock();
        scope(exit) sigLock.unlock();
        {
            return signaled;
        }
    }

    long getSignaledNextFireTime() {
        sigLock.lock();
        scope(exit) sigLock.unlock();
        {
            return signaledNextFireTime;
        }
    }

    /**
     * <p>
     * The main processing loop of the <code>QuartzSchedulerThread</code>.
     * </p>
     */
    override
    void run() {
        int acquiresFailed = 0;

        version(HUNT_DEBUG)
            trace("runing QuartzSchedulerThread...");

        while (!halted) {
            import core.time;
            version(HUNT_DEBUG) {
                Thread.sleep(1.seconds); // slow down the process
                trace("scheduling...");
            }

            try {
                // check if we're supposed to pause...
                sigLock.lock(); 
                while (paused && !halted) {
                    try {
                        // wait until togglePause(false) is called...
                        sigCondition.wait(seconds(1));
                    } catch (InterruptedException ignore) {
                    }

                    // reset failure counter when paused, so that we don't
                    // wait again after unpausing
                    acquiresFailed = 0;
                }

                sigLock.unlock();
                if (halted) {
                    break;
                }

                // wait a bit, if reading from job store is consistently
                // failing (e.g. DB is down or restarting)..
                if (acquiresFailed > 1) {
                    info("acquiresFailed=%d", acquiresFailed);
                    try {
                        long delay = computeDelayForRepeatedErrors(qsRsrcs.getJobStore(), acquiresFailed);
                        Thread.sleep(delay.msecs);
                    } catch (Exception ignore) {
                    }
                }

                int availThreadCount = qsRsrcs.getThreadPool().blockForAvailableThreads();
                if(availThreadCount <= 0) { 
                    version(HUNT_DEBUG) warning("no thread available.");
                    // should never happen, if threadPool.blockForAvailableThreads() follows contract
                    continue; // while (!halted)
                }
                    
                // will always be true, due to semantics of blockForAvailableThreads...

                List!(OperableTrigger) triggers;
                long now = DateTimeHelper.currentTimeMillis();
                clearSignaledSchedulingChange();
                try {
                    triggers = qsRsrcs.getJobStore().acquireNextTriggers(
                                    now + idleWaitTime, 
                                    min(availThreadCount, qsRsrcs.getMaxBatchSize()), 
                                    qsRsrcs.getBatchTimeWindow()
                                );

                    acquiresFailed = 0;
                    // version(HUNT_QUARTZ_DEBUG) 
                    {
                    int n = triggers is null ? 0 : triggers.size();
                        // info("batch acquisition of " ~  std.conv.to!string(n) ~ " triggers");
                    // } else {
                        if (n > 0) {
                            info("batch acquisition of " ~ std.conv.to!string(n) ~ 
                                " triggers, thread: " ~ this.name() );
                        }
                    }
                } catch (JobPersistenceException jpe) {
                    if (acquiresFailed == 0) {
                        qs.notifySchedulerListenersError(
                            "An error occurred while scanning for the next triggers to fire.", jpe);
                    }
                    if (acquiresFailed < int.max)
                        acquiresFailed++;
                    continue;
                } catch (RuntimeException e) {
                    if (acquiresFailed == 0) {
                        error("quartzSchedulerThreadLoop: RuntimeException "
                                ~ e.msg, e);
                    }
                    if (acquiresFailed < int.max)
                        acquiresFailed++;
                    continue;
                }

                if (triggers !is null && !triggers.isEmpty()) {

                    now = DateTimeHelper.currentTimeMillis();
                    LocalDateTime dt = triggers.get(0).getNextFireTime();
                    if(dt is null) {
                        warning("getNextFireTime is null");
                        continue;
                    }

                    long triggerTime = dt.toEpochMilli();
                    long timeUntilTrigger = triggerTime - now;
                    while(timeUntilTrigger > 2) {
                        sigLock.lock();
                        {
                            if (halted) {
                                sigLock.unlock();
                                break;
                            }
                            if (!isCandidateNewTimeEarlierWithinReason(triggerTime, false)) {
                                try {
                                    // we could have blocked a long while
                                    // on 'synchronize', so we must recompute
                                    now = DateTimeHelper.currentTimeMillis();
                                    timeUntilTrigger = triggerTime - now;
                                    if(timeUntilTrigger >= 1)
                                        sigCondition.wait(msecs(timeUntilTrigger));
                                } catch (InterruptedException ignore) {
                                }
                            }
                        }
                        sigLock.unlock();

                        if(releaseIfScheduleChangedSignificantly(triggers, triggerTime)) {
                            break;
                        }
                        now = DateTimeHelper.currentTimeMillis();
                        timeUntilTrigger = triggerTime - now;
                    }

                    // this happens if releaseIfScheduleChangedSignificantly decided to release triggers
                    if(triggers.isEmpty())
                        continue;

                    // set triggers to 'executing'
                    List!(TriggerFiredResult) bndles = new ArrayList!(TriggerFiredResult)();

                    bool goAhead = true;
                        goAhead = !AtomicHelper.load(halted);


                    if(goAhead) {
                        try {
                            List!(TriggerFiredResult) res = qsRsrcs.getJobStore().triggersFired(triggers);
                            if(res !is null)
                                bndles = res;
                        } catch (SchedulerException se) {
                            qs.notifySchedulerListenersError(
                                    "An error occurred while firing triggers '"
                                            ~ triggers.toString() ~ "'", se);
                            //QTZ-179 : a problem occurred interacting with the triggers from the db
                            //we release them and loop again
                            for (int i = 0; i < triggers.size(); i++) {
                                qsRsrcs.getJobStore().releaseAcquiredTrigger(triggers.get(i));
                            }
                            continue;
                        }

                    }

                    for (int i = 0; i < bndles.size(); i++) {
                        TriggerFiredResult result =  bndles.get(i);
                        TriggerFiredBundle bndle =  result.getTriggerFiredBundle();
                        RuntimeException exception = cast(RuntimeException)result.getException();

                        if (exception !is null) {
                            error("RuntimeException while firing trigger " ~ (cast(Object)triggers.get(i)).toString(), exception.msg);
                            qsRsrcs.getJobStore().releaseAcquiredTrigger(triggers.get(i));
                            continue;
                        }

                        // it's possible to get 'null' if the triggers was paused,
                        // blocked, or other similar occurrences that prevent it being
                        // fired at this time...  or if the scheduler was shutdown (halted)
                        if (bndle is null) {
                            qsRsrcs.getJobStore().releaseAcquiredTrigger(triggers.get(i));
                            continue;
                        }

                        JobRunShell shell = null;
                        try {
                            shell = qsRsrcs.getJobRunShellFactory().createJobRunShell(bndle);
                            // shell = new JobRunShell(scheduler, bndle);
                            shell.initialize(qs);
                        } catch (SchedulerException se) {
                            qsRsrcs.getJobStore().triggeredJobComplete(triggers.get(i), 
                                bndle.getJobDetail(), 
                                CompletedExecutionInstruction.SET_ALL_JOB_TRIGGERS_ERROR);
                            continue;
                        }

                        if (qsRsrcs.getThreadPool().runInThread(shell) == false) {
                            // this case should never happen, as it is indicative of the
                            // scheduler being shutdown or a bug in the thread pool or
                            // a thread pool being used concurrently - which the docs
                            // say not to do...
                            error("ThreadPool.runInThread() return false!");
                            qsRsrcs.getJobStore()
                                .triggeredJobComplete(triggers.get(i), 
                                                    bndle.getJobDetail(), 
                                                    CompletedExecutionInstruction.SET_ALL_JOB_TRIGGERS_ERROR);
                        }
                    }

                    continue; // while (!halted)
                }

                now = DateTimeHelper.currentTimeMillis();
                long waitTime = now + getRandomizedIdleWaitTime();
                long timeUntilContinue = waitTime - now;
                sigLock.lock();
                if(!halted) {
                    // QTZ-336 A job might have been completed in the mean time and we might have
                    // missed the scheduled changed signal by not waiting for the notify() yet
                    // Check that before waiting for too long in case this very job needs to be
                    // scheduled very soon
                    try {
                        if (!isScheduleChanged()) {
                            sigCondition.wait(msecs(timeUntilContinue));
                        }
                    } catch (InterruptedException ignore) {
                    }
                }
                sigLock.unlock();

            } catch(RuntimeException re) {
                error("Runtime error occurred in main trigger firing loop.", re);
            }
        } // while (!halted)

        // drop references to scheduler stuff to aid garbage collection...
        qs = null;
        qsRsrcs = null;
    }

    private enum long MIN_DELAY = 20;
    private enum long MAX_DELAY = 600000;

    private static long computeDelayForRepeatedErrors(JobStore jobStore, int acquiresFailed) {
        long delay;
        try {
            delay = jobStore.getAcquireRetryDelay(acquiresFailed);
        } catch (Exception ignored) {
            // we're trying to be useful in case of error states, not cause
            // additional errors..
            delay = 100;
        }


        // sanity check per getAcquireRetryDelay specification
        if (delay < MIN_DELAY)
            delay = MIN_DELAY;
        if (delay > MAX_DELAY)
            delay = MAX_DELAY;

        return delay;
    }

    private bool releaseIfScheduleChangedSignificantly(
            List!(OperableTrigger) triggers, long triggerTime) {
        if (isCandidateNewTimeEarlierWithinReason(triggerTime, true)) {
            // above call does a clearSignaledSchedulingChange()
            foreach(OperableTrigger trigger ; triggers) {
                qsRsrcs.getJobStore().releaseAcquiredTrigger(trigger);
            }
            triggers.clear();
            return true;
        }
        return false;
    }

    private bool isCandidateNewTimeEarlierWithinReason(long oldTime, bool clearSignal) {

        // So here's the deal: We know due to being signaled that 'the schedule'
        // has changed.  We may know (if getSignaledNextFireTime() != 0) the
        // new earliest fire time.  We may not (in which case we will assume
        // that the new time is earlier than the trigger we have acquired).
        // In either case, we only want to abandon our acquired trigger and
        // go looking for a new one if "it's worth it".  It's only worth it if
        // the time cost incurred to abandon the trigger and acquire a new one
        // is less than the time until the currently acquired trigger will fire,
        // otherwise we're just "thrashing" the job store (e.g. database).
        //
        // So the question becomes when is it "worth it"?  This will depend on
        // the job store implementation (and of course the particular database
        // or whatever behind it).  Ideally we would depend on the job store
        // implementation to tell us the amount of time in which it "thinks"
        // it can abandon the acquired trigger and acquire a new one.  However
        // we have no current facility for having it tell us that, so we make
        // a somewhat educated but arbitrary guess ;-).

        synchronized(sigLock) {

            if (!isScheduleChanged())
                return false;

            bool earlier = false;

            if(getSignaledNextFireTime() == 0)
                earlier = true;
            else if(getSignaledNextFireTime() < oldTime )
                earlier = true;

            if(earlier) {
                // so the new time is considered earlier, but is it enough earlier?
                long diff = oldTime - DateTimeHelper.currentTimeMillis();
                if(diff < (qsRsrcs.getJobStore().supportsPersistence() ? 70L : 7L))
                    earlier = false;
            }

            if(clearSignal) {
                clearSignaledSchedulingChange();
            }

            return earlier;
        }
    }

} // end of QuartzSchedulerThread
