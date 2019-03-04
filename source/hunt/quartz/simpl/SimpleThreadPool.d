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

module hunt.quartz.simpl.SimpleThreadPool;

import hunt.quartz.exception;
import hunt.quartz.spi.ThreadPool;

import hunt.concurrency.thread;
import hunt.collection.Iterator;
import hunt.collection.LinkedList;
import hunt.collection.List;
import hunt.util.Common;
import hunt.Exceptions;
import hunt.logging;

import core.atomic;
import core.sync.condition;
import core.sync.mutex;
import core.thread;
import core.time;
import std.conv;


/**
 * <p>
 * This is class is a simple implementation of a thread pool, based on the
 * <code>{@link hunt.quartz.spi.ThreadPool}</code> interface.
 * </p>
 * 
 * <p>
 * <CODE>Runnable</CODE> objects are sent to the pool with the <code>{@link #runInThread(Runnable)}</code>
 * method, which blocks until a <code>Thread</code> becomes available.
 * </p>
 * 
 * <p>
 * The pool has a fixed number of <code>Thread</code>s, and does not grow or
 * shrink based on demand.
 * </p>
 * 
 * @author James House
 * @author Juergen Donnerstag
 */
class SimpleThreadPool : ThreadPool {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private int count = -1;

    private int prio; // = Thread.PRIORITY_DEFAULT;

    private bool isShutdown = false;
    private bool handoffPending = false;

    private bool inheritLoader = false;

    private bool inheritGroup = true;

    private bool makeThreadsDaemons = false;

    private ThreadGroupEx threadGroup;

    private Mutex nextRunnableLock; // = new Object();
    private Condition nextRunnableCondition; // = new Object();

    private List!(WorkerThread) workers;
    private LinkedList!(WorkerThread) availWorkers; // = new LinkedList!(WorkerThread)();
    private LinkedList!(WorkerThread) busyWorkers; // = new LinkedList!(WorkerThread)();

    private string threadNamePrefix;

    
    private string schedulerInstanceName;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a new (unconfigured) <code>SimpleThreadPool</code>.
     * </p>
     * 
     * @see #setThreadCount(int)
     * @see #setThreadPriority(int)
     */
    this() {
        initializeMembers();
    }

    /**
     * <p>
     * Create a new <code>SimpleThreadPool</code> with the specified number
     * of <code>Thread</code> s that have the given priority.
     * </p>
     * 
     * @param threadCount
     *          the number of worker <code>Threads</code> in the pool, must
     *          be > 0.
     * @param threadPriority
     *          the thread priority for the worker threads.
     * 
     * @see java.lang.Thread
     */
    this(int threadCount, int threadPriority) {
        initializeMembers();
        setThreadCount(threadCount);
        setThreadPriority(threadPriority);
    }

    private void initializeMembers() {
        nextRunnableLock = new Mutex();
        nextRunnableCondition = new Condition(nextRunnableLock);
        availWorkers = new LinkedList!(WorkerThread)();
        busyWorkers = new LinkedList!(WorkerThread)();
        prio = Thread.PRIORITY_DEFAULT;
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */


    int getPoolSize() {
        return getThreadCount();
    }

    /**
     * <p>
     * Set the number of worker threads in the pool - has no effect after
     * <code>initialize()</code> has been called.
     * </p>
     */
    void setThreadCount(int count) {
        this.count = count;
    }

    /**
     * <p>
     * Get the number of worker threads in the pool.
     * </p>
     */
    int getThreadCount() {
        return count;
    }

    /**
     * <p>
     * Set the thread priority of worker threads in the pool - has no effect
     * after <code>initialize()</code> has been called.
     * </p>
     */
    void setThreadPriority(int prio) {
        this.prio = prio;
    }

    /**
     * <p>
     * Get the thread priority of worker threads in the pool.
     * </p>
     */
    int getThreadPriority() {
        return prio;
    }

    void setThreadNamePrefix(string prfx) {
        this.threadNamePrefix = prfx;
    }

    string getThreadNamePrefix() {
        return threadNamePrefix;
    }

    /**
     * @return Returns the
     *         threadsInheritContextClassLoaderOfInitializingThread.
     */
    bool isThreadsInheritContextClassLoaderOfInitializingThread() {
        return inheritLoader;
    }

    /**
     * @param inheritLoader
     *          The threadsInheritContextClassLoaderOfInitializingThread to
     *          set.
     */
    void setThreadsInheritContextClassLoaderOfInitializingThread(
            bool inheritLoader) {
        this.inheritLoader = inheritLoader;
    }

    bool isThreadsInheritGroupOfInitializingThread() {
        return inheritGroup;
    }

    void setThreadsInheritGroupOfInitializingThread(
            bool inheritGroup) {
        this.inheritGroup = inheritGroup;
    }


    /**
     * @return Returns the value of makeThreadsDaemons.
     */
    bool isMakeThreadsDaemons() {
        return makeThreadsDaemons;
    }

    /**
     * @param makeThreadsDaemons
     *          The value of makeThreadsDaemons to set.
     */
    void setMakeThreadsDaemons(bool makeThreadsDaemons) {
        this.makeThreadsDaemons = makeThreadsDaemons;
    }
    
    void setInstanceId(string schedInstId) {
    }

    void setInstanceName(string schedName) {
        schedulerInstanceName = schedName;
    }

    void initialize() {

        if(workers !is null && workers.size() > 0) // already initialized...
            return;
        
        if (count <= 0) {
            throw new SchedulerConfigException(
                    "Thread count must be > 0");
        }
        if (prio <= 0 || prio > 9) {
            throw new SchedulerConfigException(
                    "Thread priority must be > 0 and <= 9");
        }

        if(isThreadsInheritGroupOfInitializingThread()) {
            threadGroup = ThreadEx.currentThread().getThreadGroup();
        } else {
            // follow the threadGroup tree to the root thread group.
            threadGroup = ThreadEx.currentThread().getThreadGroup();
            ThreadGroupEx parent = threadGroup;
            while ( parent.getName() != ("main") ) {
                threadGroup = parent;
                parent = threadGroup.getParent();
            }
            threadGroup = new ThreadGroupEx(parent, schedulerInstanceName ~ "-SimpleThreadPool");
            if (isMakeThreadsDaemons()) {
                threadGroup.setDaemon(true);
            }
        }


        if (isThreadsInheritContextClassLoaderOfInitializingThread()) {
            info("Job execution threads will use class loader of thread: "
                            ~ Thread.getThis().name);
        }

        // create the worker threads and start them
        foreach(WorkerThread wt; createWorkerThreads(count).iterator()) {
            wt.start();
            availWorkers.add(wt);
        }
    }

    protected List!(WorkerThread) createWorkerThreads(int createCount) {
        workers = new LinkedList!(WorkerThread)();
        for (int i = 1; i<= createCount; ++i) {
            string threadPrefix = getThreadNamePrefix();
            if (threadPrefix is null) {
                threadPrefix = schedulerInstanceName ~ "_Worker";
            }
            WorkerThread wt = new WorkerThread(this, threadGroup,
                threadPrefix ~ "-" ~ i.to!string(),
                getThreadPriority(),
                isMakeThreadsDaemons());
            if (isThreadsInheritContextClassLoaderOfInitializingThread()) {
                implementationMissing(false);
                // wt.setContextClassLoader(Thread.getThis()
                //         .getContextClassLoader());
            }
            workers.add(wt);
        }

        return workers;
    }

    /**
     * <p>
     * Terminate any worker threads in this thread group.
     * </p>
     * 
     * <p>
     * Jobs currently in progress will complete.
     * </p>
     */
    void shutdown() {
        shutdown(true);
    }

    /**
     * <p>
     * Terminate any worker threads in this thread group.
     * </p>
     * 
     * <p>
     * Jobs currently in progress will complete.
     * </p>
     */
    void shutdown(bool waitForJobsToComplete) {
        nextRunnableLock.lock();
        scope(exit) nextRunnableLock.unlock();
            trace("Shutting down threadpool...");

            isShutdown = true;

            if(workers is null) // case where the pool wasn't even initialize()ed
                return;

            // signal each worker thread to shut down
            foreach(WorkerThread wt; workers.iterator()) {
                wt.shutdown();
                availWorkers.remove(wt);
            }

            // Give waiting (wait(1000)) worker threads a chance to shut down.
            // Active worker threads will shut down after finishing their
            // current job.
            nextRunnableCondition.notifyAll();

            if (waitForJobsToComplete == true) {

                bool interrupted = false;
                try {
                    // wait for hand-off in runInThread to complete...
                    while(handoffPending) {
                        try {
                            nextRunnableCondition.wait(msecs(100));
                        } catch(InterruptedException _) {
                            interrupted = true;
                        }
                    }

                    // Wait until all worker threads are shut down
                    while (busyWorkers.size() > 0) {
                        WorkerThread wt = cast(WorkerThread) busyWorkers.getFirst();
                        try {
                            trace("Waiting for thread " ~ wt.name
                                            ~ " to shut down");

                            // note: with waiting infinite time the
                            // application may appear to 'hang'.
                            nextRunnableCondition.wait(seconds(2));
                        } catch (InterruptedException _) {
                            interrupted = true;
                        }
                    }

                    foreach(WorkerThread wt; workers.iterator()) {
                        try {
                            wt.join();
                            // workerThreads.remove();
                            workers.remove(wt);
                        } catch (InterruptedException _) {
                            interrupted = true;
                        }
                    }
                } finally {
                    if (interrupted) {
                        ThreadEx.currentThread().interrupt();
                    }
                }

                trace("No executing jobs remaining, all threads stopped.");
            }
            trace("Shutdown of threadpool complete.");
    }

    /**
     * <p>
     * Run the given <code>Runnable</code> object in the next available
     * <code>Thread</code>. If while waiting the thread pool is asked to
     * shut down, the Runnable is executed immediately within a new additional
     * thread.
     * </p>
     * 
     * @param runnable
     *          the <code>Runnable</code> to be added.
     */
    bool runInThread(Runnable runnable) {
        if (runnable is null) {
            return false;
        }

        nextRunnableLock.lock();
        scope(exit) nextRunnableLock.unlock();


        handoffPending = true;

        // Wait until a worker thread is available
        while ((availWorkers.size() < 1) && !isShutdown) {
            try {
                nextRunnableCondition.wait(msecs(500));
            } catch (InterruptedException ignore) {
            }
        }

        if (!isShutdown) {
            WorkerThread wt = cast(WorkerThread)availWorkers.removeFirst();
            busyWorkers.add(wt);
            wt.run(runnable);
        } else {
            // If the thread pool is going down, execute the Runnable
            // within a new additional worker thread (no thread from the pool).
            WorkerThread wt = new WorkerThread(this, threadGroup,
                    "WorkerThread-LastJob", prio, isMakeThreadsDaemons(), runnable);
            busyWorkers.add(wt);
            workers.add(wt);
            wt.start();
        }
        nextRunnableCondition.notifyAll();
        handoffPending = false;

        return true;
    }

    int blockForAvailableThreads() {
        
        nextRunnableLock.lock();
        scope(exit) nextRunnableLock.unlock();

        while((availWorkers.size() < 1 || handoffPending) && !isShutdown) {
            try {
                nextRunnableCondition.wait(500.msecs());
            } catch (InterruptedException ignore) {
            }
        }

        return availWorkers.size();
    }

    protected void makeAvailable(WorkerThread wt) {
        nextRunnableLock.lock();
        scope(exit) nextRunnableLock.unlock();
        if(!isShutdown) {
            availWorkers.add(wt);
        }
        busyWorkers.remove(wt);
        nextRunnableCondition.notifyAll();
    }

    protected void clearFromBusyWorkersList(WorkerThread wt) {
        
        nextRunnableLock.lock();
        scope(exit) nextRunnableLock.unlock();
        busyWorkers.remove(wt);
        nextRunnableCondition.notifyAll();
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * WorkerThread Class.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * A Worker loops, waiting to execute tasks.
     * </p>
     */
    class WorkerThread : ThreadEx {

        private Mutex lock;
        private Condition lockCondition;

        // A flag that signals the WorkerThread to terminate.
        private shared bool _run;

        private SimpleThreadPool tp;

        private Runnable runnable = null;
        
        private bool runOnce = false;

        /**
         * <p>
         * Create a worker thread and start it. Waiting for the next Runnable,
         * executing it, and waiting for the next Runnable, until the shutdown
         * flag is set.
         * </p>
         */
        this(SimpleThreadPool tp, ThreadGroupEx threadGroup, string name,
                     int prio, bool isDaemon) {

            this(tp, threadGroup, name, prio, isDaemon, null);
        }

        /**
         * <p>
         * Create a worker thread, start it, execute the runnable and terminate
         * the thread (one time execution).
         * </p>
         */
        this(SimpleThreadPool tp, ThreadGroupEx threadGroup, string name,
                     int prio, bool isDaemon, Runnable runnable) {
            
            lock = new Mutex();
            lockCondition = new Condition(lock);
            super(threadGroup, name);
            this.tp = tp;
            this.runnable = runnable;
            if(runnable !is null)
                runOnce = true;
            this.priority = prio;
            this.isDaemon = isDaemon;
        }

        /**
         * <p>
         * Signal the thread that it should terminate.
         * </p>
         */
        void shutdown() {
            _run = false;
        }

        void run(Runnable newRunnable) {
            lock.lock();
            scope(exit) lock.unlock();
            if(runnable !is null) {
                throw new IllegalStateException("Already running a Runnable!");
            }

            runnable = newRunnable;
            lockCondition.notifyAll();
        }

        /**
         * <p>
         * Loop, executing targets as they are received.
         * </p>
         */
        override
        void run() {
            bool ran = false;
            
            while (_run) {
                try {
                    lock.lock(); 
                    while (runnable is null && _run) {
                        lockCondition.wait(msecs(500));
                    }

                    if (runnable !is null) {
                        ran = true;
                        runnable.run();
                    }
                    lock.unlock();
                } catch (InterruptedException unblock) {
                    // do nothing (loop will terminate if shutdown() was called
                    try {
                        error("Worker thread was interrupt()'ed.", unblock);
                    } catch(Exception e) {
                        // ignore to help with a tomcat glitch
                    }
                } catch (Throwable exceptionInRunnable) {
                    try {
                        error("Error while executing the Runnable: ",
                            exceptionInRunnable);
                    } catch(Exception e) {
                        // ignore to help with a tomcat glitch
                    }
                } finally {
                    synchronized(lock) {
                        runnable = null;
                    }
                    // repair the thread in case the runnable mucked it up...
                    if(this.priority != tp.getThreadPriority()) {
                        this.priority = tp.getThreadPriority();
                    }

                    if (runOnce) {
                        atomicStore(_run, false);
                        clearFromBusyWorkersList(this);
                    } else if(ran) {
                        ran = false;
                        makeAvailable(this);
                    }

                }
            }

            //version(HUNT_DEBUG)
            try {
                trace("WorkerThread is shut down.");
            } catch(Exception e) {
                // ignore to help with a tomcat glitch
            }
        }
    }
}
