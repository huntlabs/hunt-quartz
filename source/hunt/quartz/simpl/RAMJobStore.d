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

module hunt.quartz.simpl.RAMJobStore;

import hunt.quartz.Calendar;
import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobKey;
import hunt.quartz.exception;
import hunt.quartz.ObjectAlreadyExistsException;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.impl.JobDetailImpl;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.impl.matchers.StringMatcher;
import hunt.quartz.impl.matchers.EverythingMatcher;
import hunt.quartz.spi.ClassLoadHelper;
import hunt.quartz.spi.JobStore;
import hunt.quartz.spi.OperableTrigger;
import hunt.quartz.spi.SchedulerSignaler;
import hunt.quartz.spi.TriggerFiredBundle;
import hunt.quartz.spi.TriggerFiredResult;

import hunt.collection;
import hunt.Exceptions;
import hunt.logging;
import hunt.text;
import hunt.time.LocalDateTime;
import hunt.util.Comparator;
import hunt.util.DateTime;

import core.atomic;
import std.algorithm;
import std.conv;
// import std.datetime;



/**
 * <p>
 * This class implements a <code>{@link hunt.quartz.spi.JobStore}</code> that
 * utilizes RAM as its storage device.
 * </p>
 * 
 * <p>
 * As you should know, the ramification of this is that access is extrememly
 * fast, but the data is completely - therefore this <code>JobStore</code>
 * should not be used if true persistence between program shutdowns is
 * required.
 * </p>
 * 
 * @author James House
 * @author Sharada Jambula
 * @author Eric Mueller
 */
class RAMJobStore : JobStore {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    protected HashMap!(JobKey, JobWrapper) jobsByKey;

    protected HashMap!(TriggerKey, TriggerWrapper) triggersByKey;
    
    protected HashMap!(string, HashMap!(JobKey, JobWrapper)) jobsByGroup;

    protected HashMap!(string, HashMap!(TriggerKey, TriggerWrapper)) triggersByGroup;

    protected TreeSet!(TriggerWrapper) timeTriggers;

    protected HashMap!(string, Calendar) calendarsByName;

    protected Map!(JobKey, List!(TriggerWrapper)) triggersByJob;

    protected Object lock;

    protected HashSet!(string) pausedTriggerGroups;

    protected HashSet!(string) pausedJobGroups;

    protected HashSet!(JobKey) blockedJobs;
    
    protected long misfireThreshold = 5000;

    protected SchedulerSignaler signaler;


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a new <code>RAMJobStore</code>.
     * </p>
     */
    this() {
        jobsByKey = new HashMap!(JobKey, JobWrapper)(1000);
        triggersByKey = new HashMap!(TriggerKey, TriggerWrapper)(1000);
        jobsByGroup = new HashMap!(string, HashMap!(JobKey, JobWrapper))(25);
        triggersByGroup = new HashMap!(string, HashMap!(TriggerKey, TriggerWrapper))(25);
        timeTriggers = new TreeSet!(TriggerWrapper)(new TriggerWrapperComparator());
        calendarsByName = new HashMap!(string, Calendar)(25);
        triggersByJob = new HashMap!(JobKey, List!(TriggerWrapper))(1000);
        lock = new Object();
        pausedTriggerGroups = new HashSet!(string)();
        pausedJobGroups = new HashSet!(string)();
        blockedJobs = new HashSet!(JobKey)();
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */


    /**
     * <p>
     * Called by the QuartzScheduler before the <code>JobStore</code> is
     * used, in order to give the it a chance to initialize.
     * </p>
     */
    void initialize(ClassLoadHelper loadHelper, SchedulerSignaler schedSignaler) {

        this.signaler = schedSignaler;

        info("RAMJobStore initialized.");
    }

    void schedulerStarted() {
        // nothing to do
    }

    void schedulerPaused() {
        // nothing to do
    }
    
    void schedulerResumed() {
        // nothing to do
    }
    
    long getMisfireThreshold() {
        return misfireThreshold;
    }

    /**
     * The number of milliseconds by which a trigger must have missed its
     * next-fire-time, in order for it to be considered "misfired" and thus
     * have its misfire instruction applied.
     * 
     * @param misfireThreshold the new misfire threshold
     */
    
    void setMisfireThreshold(long misfireThreshold) {
        if (misfireThreshold < 1) {
            throw new IllegalArgumentException("Misfire threshold must be larger than 0");
        }
        this.misfireThreshold = misfireThreshold;
    }

    /**
     * <p>
     * Called by the QuartzScheduler to inform the <code>JobStore</code> that
     * it should free up all of it's resources because the scheduler is
     * shutting down.
     * </p>
     */
    void shutdown() {
    }

    bool supportsPersistence() {
        return false;
    }

    /**
     * Clear (delete!) all scheduling data - all {@link Job}s, {@link Trigger}s
     * {@link Calendar}s.
     * 
     * @throws JobPersistenceException
     */
    void clearAllSchedulingData() {

        synchronized (lock) {
            // unschedule jobs (delete triggers)
            List!(string) lst = getTriggerGroupNames();
            foreach(string group; lst) {
                Set!(TriggerKey) keys = getTriggerKeys(GroupMatcherHelper.triggerGroupEquals(group));
                foreach(TriggerKey key; keys) {
                    removeTrigger(key);
                }
            }
            // delete jobs
            lst = getJobGroupNames();
            foreach(string group; lst) {
                Set!(JobKey) keys = getJobKeys(GroupMatcherHelper.jobGroupEquals(group));
                foreach(JobKey key; keys) {
                    removeJob(key);
                }
            }
            // delete calendars
            lst = getCalendarNames();
            foreach(string name; lst) {
                removeCalendar(name);
            }
        }
    }
    
    /**
     * <p>
     * Store the given <code>{@link hunt.quartz.JobDetail}</code> and <code>{@link hunt.quartz.Trigger}</code>.
     * </p>
     * 
     * @param newJob
     *          The <code>JobDetail</code> to be stored.
     * @param newTrigger
     *          The <code>Trigger</code> to be stored.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Job</code> with the same name/group already
     *           exists.
     */
    void storeJobAndTrigger(JobDetail newJob,
            OperableTrigger newTrigger) {
        storeJob(newJob, false);
        storeTrigger(newTrigger, false);
    }

    /**
     * <p>
     * Store the given <code>{@link hunt.quartz.Job}</code>.
     * </p>
     * 
     * @param newJob
     *          The <code>Job</code> to be stored.
     * @param replaceExisting
     *          If <code>true</code>, any <code>Job</code> existing in the
     *          <code>JobStore</code> with the same name & group should be
     *          over-written.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Job</code> with the same name/group already
     *           exists, and replaceExisting is set to false.
     */
    void storeJob(JobDetail newJob, bool replaceExisting) {
        JobWrapper jw = new JobWrapper(cast(JobDetail)newJob.clone());

        bool repl = false;

        synchronized (lock) {
            if (jobsByKey.get(jw.key) !is null) {
                if (!replaceExisting) {
                    throw new ObjectAlreadyExistsException(newJob);
                }
                repl = true;
            }

            if (!repl) {
                // get job group
                HashMap!(JobKey, JobWrapper) grpMap = jobsByGroup.get(newJob.getKey().getGroup());
                if (grpMap is null) {
                    grpMap = new HashMap!(JobKey, JobWrapper)(100);
                    jobsByGroup.put(newJob.getKey().getGroup(), grpMap);
                }
                // add to jobs by group
                grpMap.put(newJob.getKey(), jw);
                // add to jobs by FQN map
                jobsByKey.put(jw.key, jw);
            } else {
                // update job detail
                JobWrapper orig = jobsByKey.get(jw.key);
                orig.jobDetail = jw.jobDetail; // already cloned
            }
        }
    }

    /**
     * <p>
     * Remove (delete) the <code>{@link hunt.quartz.Job}</code> with the given
     * name, and any <code>{@link hunt.quartz.Trigger}</code> s that reference
     * it.
     * </p>
     *
     * @return <code>true</code> if a <code>Job</code> with the given name &
     *         group was found and removed from the store.
     */
    bool removeJob(JobKey jobKey) {

        bool found = false;

        synchronized (lock) {
            List!(Trigger) triggersOfJob = getTriggersForJob(jobKey);
            foreach(Trigger trig; triggersOfJob) {
                this.removeTrigger(trig.getKey());
                found = true;
            }
            
            found = (jobsByKey.remove(jobKey) !is null) | found;
            if (found) {

                HashMap!(JobKey, JobWrapper) grpMap = jobsByGroup.get(jobKey.getGroup());
                if (grpMap !is null) {
                    grpMap.remove(jobKey);
                    if (grpMap.size() == 0) {
                        jobsByGroup.remove(jobKey.getGroup());
                    }
                }
            }
        }

        return found;
    }

    bool removeJobs(List!(JobKey) jobKeys) {
        bool allFound = true;

        synchronized (lock) {
            foreach(JobKey key; jobKeys)
                allFound = removeJob(key) && allFound;
        }

        return allFound;
    }

    bool removeTriggers(List!(TriggerKey) triggerKeys) {
        bool allFound = true;

        synchronized (lock) {
            foreach(TriggerKey key; triggerKeys)
                allFound = removeTrigger(key) && allFound;
        }

        return allFound;
    }

    void storeJobsAndTriggers(
            Map!(JobDetail, Set!(Trigger)) triggersAndJobs, bool replace) {

        synchronized (lock) {
            // make sure there are no collisions...
            if(!replace) {
                foreach(JobDetail key, Set!(Trigger) value; triggersAndJobs) {
                    if(checkExists(key.getKey()))
                        throw new ObjectAlreadyExistsException(key);
                    foreach(Trigger trigger; value) {
                        if(checkExists(trigger.getKey()))
                            throw new ObjectAlreadyExistsException(trigger);
                    }
                }
            }
            // do bulk add...
            foreach(JobDetail key, Set!(Trigger) value; triggersAndJobs)  {
                storeJob(key, true);
                foreach(Trigger trigger; value) {
                    storeTrigger(cast(OperableTrigger) trigger, true);
                }
            }
        }
        
    }

    /**
     * <p>
     * Store the given <code>{@link hunt.quartz.Trigger}</code>.
     * </p>
     *
     * @param newTrigger
     *          The <code>Trigger</code> to be stored.
     * @param replaceExisting
     *          If <code>true</code>, any <code>Trigger</code> existing in
     *          the <code>JobStore</code> with the same name & group should
     *          be over-written.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Trigger</code> with the same name/group already
     *           exists, and replaceExisting is set to false.
     *
     * @see #pauseTriggers(hunt.quartz.impl.matchers.GroupMatcher)
     */
    void storeTrigger(OperableTrigger newTrigger, bool replaceExisting) {
        TriggerWrapper tw = new TriggerWrapper(cast(OperableTrigger)newTrigger.clone());

        synchronized (lock) {
            if (triggersByKey.get(tw.key) !is null) {
                if (!replaceExisting) {
                    throw new ObjectAlreadyExistsException(newTrigger);
                }
    
                removeTrigger(newTrigger.getKey(), false);
            }
    
            if (retrieveJob(newTrigger.getJobKey()) is null) {
                throw new JobPersistenceException("The job ("
                        ~ newTrigger.getJobKey().toString()
                        ~ ") referenced by the trigger does not exist.");
            }

            // add to triggers by job
            List!(TriggerWrapper) jobList = triggersByJob.get(tw.jobKey);
            if(jobList is null) {
                jobList = new ArrayList!(TriggerWrapper)(1);
                triggersByJob.put(tw.jobKey, jobList);
            }
            jobList.add(tw);
            
            // add to triggers by group
            HashMap!(TriggerKey, TriggerWrapper) grpMap = triggersByGroup.get(newTrigger.getKey().getGroup());
            if (grpMap is null) {
                grpMap = new HashMap!(TriggerKey, TriggerWrapper)(100);
                triggersByGroup.put(newTrigger.getKey().getGroup(), grpMap);
            }
            grpMap.put(newTrigger.getKey(), tw);
            // add to triggers by FQN map
            triggersByKey.put(tw.key, tw);

            if (pausedTriggerGroups.contains(newTrigger.getKey().getGroup())
                    || pausedJobGroups.contains(newTrigger.getJobKey().getGroup())) {
                tw.state = TriggerWrapper.STATE_PAUSED;
                if (blockedJobs.contains(tw.jobKey)) {
                    tw.state = TriggerWrapper.STATE_PAUSED_BLOCKED;
                }
            } else if (blockedJobs.contains(tw.jobKey)) {
                tw.state = TriggerWrapper.STATE_BLOCKED;
            } else {
                timeTriggers.add(tw);
            }
        }
    }

    /**
     * <p>
     * Remove (delete) the <code>{@link hunt.quartz.Trigger}</code> with the
     * given name.
     * </p>
     *
     * @return <code>true</code> if a <code>Trigger</code> with the given
     *         name & group was found and removed from the store.
     */
    bool removeTrigger(TriggerKey triggerKey) {
        return removeTrigger(triggerKey, true);
    }
    
    private bool removeTrigger(TriggerKey key, bool removeOrphanedJob) {

        bool found;

        synchronized (lock) {
            // remove from triggers by FQN map
            TriggerWrapper tw = triggersByKey.remove(key);
            found = tw !is null;
            if (found) {
                // remove from triggers by group
                HashMap!(TriggerKey, TriggerWrapper) grpMap = triggersByGroup.get(key.getGroup());
                if (grpMap !is null) {
                    grpMap.remove(key);
                    if (grpMap.size() == 0) {
                        triggersByGroup.remove(key.getGroup());
                    }
                }
                //remove from triggers by job
                List!(TriggerWrapper) jobList = triggersByJob.get(tw.jobKey);
                if(jobList !is null) {
                    jobList.remove(tw);
                    if(jobList.isEmpty()) {
                        triggersByJob.remove(tw.jobKey);
                    }
                }
               
                timeTriggers.remove(tw);

                if (removeOrphanedJob) {
                    JobWrapper jw = jobsByKey.get(tw.jobKey);
                    List!(Trigger) trigs = getTriggersForJob(tw.jobKey);
                    if ((trigs is null || trigs.size() == 0) && !jw.jobDetail.isDurable()) {
                        if (removeJob(jw.key)) {
                            signaler.notifySchedulerListenersJobDeleted(jw.key);
                        }
                    }
                }
            }
        }

        return found;
    }


    /**
     * @see hunt.quartz.spi.JobStore#replaceTrigger(TriggerKey triggerKey, OperableTrigger newTrigger)
     */
    bool replaceTrigger(TriggerKey triggerKey, OperableTrigger newTrigger) {

        bool found;

        synchronized (lock) {
            // remove from triggers by FQN map
            TriggerWrapper tw = triggersByKey.remove(triggerKey);
            found = (tw !is null);

            if (found) {

                if (tw.getTrigger().getJobKey() != newTrigger.getJobKey()) {
                    throw new JobPersistenceException("New trigger is not related to the same job as the old trigger.");
                }

                // remove from triggers by group
                HashMap!(TriggerKey, TriggerWrapper) grpMap = triggersByGroup.get(triggerKey.getGroup());
                if (grpMap !is null) {
                    grpMap.remove(triggerKey);
                    if (grpMap.size() == 0) {
                        triggersByGroup.remove(triggerKey.getGroup());
                    }
                }
                
                //remove from triggers by job
                List!(TriggerWrapper) jobList = triggersByJob.get(tw.jobKey);
                if(jobList !is null) {
                    jobList.remove(tw);
                    if(jobList.isEmpty()) {
                        triggersByJob.remove(tw.jobKey);
                    }
                }
                
                timeTriggers.remove(tw);

                try {
                    storeTrigger(newTrigger, false);
                } catch(JobPersistenceException jpe) {
                    storeTrigger(tw.getTrigger(), false); // put previous trigger back...
                    throw jpe;
                }
            }
        }

        return found;
    }

    /**
     * <p>
     * Retrieve the <code>{@link hunt.quartz.JobDetail}</code> for the given
     * <code>{@link hunt.quartz.Job}</code>.
     * </p>
     *
     * @return The desired <code>Job</code>, or null if there is no match.
     */
    JobDetail retrieveJob(JobKey jobKey) {
        synchronized(lock) {
            JobWrapper jw = jobsByKey.get(jobKey);
            return (jw !is null) ? cast(JobDetail)jw.jobDetail : null; // .clone()
        }
    }

    /**
     * <p>
     * Retrieve the given <code>{@link hunt.quartz.Trigger}</code>.
     * </p>
     *
     * @return The desired <code>Trigger</code>, or null if there is no
     *         match.
     */
    OperableTrigger retrieveTrigger(TriggerKey triggerKey) {
        synchronized(lock) {
            TriggerWrapper tw = triggersByKey.get(triggerKey);
    
            return (tw !is null) ? cast(OperableTrigger)tw.getTrigger() : null; // .clone()
        }
    }
    
    /**
     * Determine whether a {@link Job} with the given identifier already 
     * exists within the scheduler.
     * 
     * @param jobKey the identifier to check for
     * @return true if a Job exists with the given identifier
     * @throws JobPersistenceException
     */
    bool checkExists(JobKey jobKey) {
        synchronized(lock) {
            JobWrapper jw = jobsByKey.get(jobKey);
            return (jw !is null);
        }
    }
    
    /**
     * Determine whether a {@link Trigger} with the given identifier already 
     * exists within the scheduler.
     * 
     * @param triggerKey the identifier to check for
     * @return true if a Trigger exists with the given identifier
     * @throws JobPersistenceException
     */
    bool checkExists(TriggerKey triggerKey) {
        synchronized(lock) {
            TriggerWrapper tw = triggersByKey.get(triggerKey);
    
            return (tw !is null);
        }
    }
 
    /**
     * <p>
     * Get the current state of the identified <code>{@link Trigger}</code>.
     * </p>
     *
     * @see TriggerState#NORMAL
     * @see TriggerState#PAUSED
     * @see TriggerState#COMPLETE
     * @see TriggerState#ERROR
     * @see TriggerState#BLOCKED
     * @see TriggerState#NONE
     */
    TriggerState getTriggerState(TriggerKey triggerKey) {
        synchronized(lock) {
            TriggerWrapper tw = triggersByKey.get(triggerKey);
            
            if (tw is null) {
                return TriggerState.NONE;
            }
    
            if (tw.state == TriggerWrapper.STATE_COMPLETE) {
                return TriggerState.COMPLETE;
            }
    
            if (tw.state == TriggerWrapper.STATE_PAUSED) {
                return TriggerState.PAUSED;
            }
    
            if (tw.state == TriggerWrapper.STATE_PAUSED_BLOCKED) {
                return TriggerState.PAUSED;
            }
    
            if (tw.state == TriggerWrapper.STATE_BLOCKED) {
                return TriggerState.BLOCKED;
            }
    
            if (tw.state == TriggerWrapper.STATE_ERROR) {
                return TriggerState.ERROR;
            }
    
            return TriggerState.NORMAL;
        }
    }

    /**
     * Reset the current state of the identified <code>{@link Trigger}</code>
     * from {@link TriggerState#ERROR} to {@link TriggerState#NORMAL} or
     * {@link TriggerState#PAUSED} as appropriate.
     *
     * <p>Only affects triggers that are in ERROR state - if identified trigger is not
     * in that state then the result is a no-op.</p>
     *
     * <p>The result will be the trigger returning to the normal, waiting to
     * be fired state, unless the trigger's group has been paused, in which
     * case it will go into the PAUSED state.</p>
     */
    void resetTriggerFromErrorState(TriggerKey triggerKey) {

        synchronized (lock) {

            TriggerWrapper tw = triggersByKey.get(triggerKey);
            // does the trigger exist?
            if (tw is null || tw.trigger is null) {
                return;
            }
            // is the trigger in error state?
            if (tw.state != TriggerWrapper.STATE_ERROR) {
                return;
            }

            if(pausedTriggerGroups.contains(triggerKey.getGroup())) {
                tw.state = TriggerWrapper.STATE_PAUSED;
            }
            else {
                tw.state = TriggerWrapper.STATE_WAITING;
                timeTriggers.add(tw);
            }
        }
    }

    /**
     * <p>
     * Store the given <code>{@link hunt.quartz.Calendar}</code>.
     * </p>
     *
     * @param calendar
     *          The <code>Calendar</code> to be stored.
     * @param replaceExisting
     *          If <code>true</code>, any <code>Calendar</code> existing
     *          in the <code>JobStore</code> with the same name & group
     *          should be over-written.
     * @param updateTriggers
     *          If <code>true</code>, any <code>Trigger</code>s existing
     *          in the <code>JobStore</code> that reference an existing
     *          Calendar with the same name with have their next fire time
     *          re-computed with the new <code>Calendar</code>.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Calendar</code> with the same name already
     *           exists, and replaceExisting is set to false.
     */
    void storeCalendar(string name,
            Calendar calendar, bool replaceExisting, bool updateTriggers) {

        calendar = cast(Calendar) calendar.clone();
        
        synchronized (lock) {
    
            Calendar obj = calendarsByName.get(name);
    
            if (obj !is null && !replaceExisting) {
                throw new ObjectAlreadyExistsException(
                    "Calendar with name '" ~ name ~ "' already exists.");
            } else if (obj !is null) {
                calendarsByName.remove(name);
            }
    
            calendarsByName.put(name, calendar);
    
            if(obj !is null && updateTriggers) {
                foreach (TriggerWrapper tw ; getTriggerWrappersForCalendar(name)) {
                    OperableTrigger trig = tw.getTrigger();
                    bool removed = timeTriggers.remove(tw);

                    trig.updateWithNewCalendar(calendar, getMisfireThreshold());

                    if (removed) {
                        timeTriggers.add(tw);
                    }
                }
            }
        }
    }

    /**
     * <p>
     * Remove (delete) the <code>{@link hunt.quartz.Calendar}</code> with the
     * given name.
     * </p>
     *
     * <p>
     * If removal of the <code>Calendar</code> would result in
     * <code>Trigger</code>s pointing to non-existent calendars, then a
     * <code>JobPersistenceException</code> will be thrown.</p>
     *       *
     * @param calName The name of the <code>Calendar</code> to be removed.
     * @return <code>true</code> if a <code>Calendar</code> with the given name
     * was found and removed from the store.
     */
    bool removeCalendar(string calName) {
        int numRefs = 0;

        synchronized (lock) {
            foreach (TriggerWrapper trigger ; triggersByKey.values()) {
                OperableTrigger trigg = trigger.trigger;
                if (trigg.getCalendarName() !is null
                        && trigg.getCalendarName()== calName) {
                    numRefs++;
                }
            }
        }

        if (numRefs > 0) {
            throw new JobPersistenceException(
                    "Calender cannot be removed if it referenced by a Trigger!");
        }

        return (calendarsByName.remove(calName) !is null);
    }

    /**
     * <p>
     * Retrieve the given <code>{@link hunt.quartz.Trigger}</code>.
     * </p>
     *
     * @param calName
     *          The name of the <code>Calendar</code> to be retrieved.
     * @return The desired <code>Calendar</code>, or null if there is no
     *         match.
     */
    Calendar retrieveCalendar(string calName) {
        synchronized (lock) {
            Calendar cal = calendarsByName.get(calName);
            if(cal !is null)
                return cast(Calendar) cal.clone();
            return null;
        }
    }

    /**
     * <p>
     * Get the number of <code>{@link hunt.quartz.JobDetail}</code> s that are
     * stored in the <code>JobsStore</code>.
     * </p>
     */
    int getNumberOfJobs() {
        synchronized (lock) {
            return jobsByKey.size();
        }
    }

    /**
     * <p>
     * Get the number of <code>{@link hunt.quartz.Trigger}</code> s that are
     * stored in the <code>JobsStore</code>.
     * </p>
     */
    int getNumberOfTriggers() {
        synchronized (lock) {
            return triggersByKey.size();
        }
    }

    /**
     * <p>
     * Get the number of <code>{@link hunt.quartz.Calendar}</code> s that are
     * stored in the <code>JobsStore</code>.
     * </p>
     */
    int getNumberOfCalendars() {
        synchronized (lock) {
            return calendarsByName.size();
        }
    }

    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Job}</code> s that
     * match the given groupMatcher.
     * </p>
     */
    Set!(JobKey) getJobKeys(GroupMatcher!(JobKey) matcher) {
        Set!(JobKey) outList = null;
        synchronized (lock) {

            StringOperatorName operator = matcher.getCompareWithOperator();
            string compareToValue = matcher.getCompareToValue();

            if(operator == StringOperatorName.EQUALS) {
                HashMap!(JobKey, JobWrapper) grpMap = jobsByGroup.get(compareToValue);
                if (grpMap !is null) {
                    outList = new HashSet!(JobKey)();

                    foreach (JobWrapper jw ; grpMap.values()) {

                        if (jw !is null) {
                            outList.add(jw.jobDetail.getKey());
                        }
                    }
                }
            } else {
                foreach (string key, HashMap!(JobKey, JobWrapper) value ; jobsByGroup) {
                    if(operator.evaluate(key, compareToValue) && value !is null) {
                        if(outList is null) {
                            outList = new HashSet!(JobKey)();
                        }
                        foreach (JobWrapper jobWrapper ; value.values()) {
                            if(jobWrapper !is null) {
                                outList.add(jobWrapper.jobDetail.getKey());
                            }
                        }
                    }
                }
            }
        }

        return outList is null ? Collections.emptySet!(JobKey)() : outList;
    }

    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Calendar}</code> s
     * in the <code>JobStore</code>.
     * </p>
     *
     * <p>
     * If there are no Calendars in the given group name, the result should be
     * a zero-length array (not <code>null</code>).
     * </p>
     */
    List!(string) getCalendarNames() {
        synchronized(lock) {
            return new LinkedList!(string)(calendarsByName.keySet());
        }
    }

    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Trigger}</code> s
     * that match the given groupMatcher.
     * </p>
     */
    Set!(TriggerKey) getTriggerKeys(GroupMatcher!(TriggerKey) matcher) {
        Set!(TriggerKey) outList = null;
        synchronized (lock) {

            StringOperatorName operator = matcher.getCompareWithOperator();
            string compareToValue = matcher.getCompareToValue();

            if(operator == StringOperatorName.EQUALS) {
                HashMap!(TriggerKey, TriggerWrapper) grpMap = triggersByGroup.get(compareToValue);
                if (grpMap !is null) {
                    outList = new HashSet!(TriggerKey)();

                    foreach (TriggerWrapper tw ; grpMap.values()) {

                        if (tw !is null) {
                            outList.add(tw.trigger.getKey());
                        }
                    }
                }
            } else {
                foreach (string key, HashMap!(TriggerKey, TriggerWrapper) value ; triggersByGroup) {
                    if(operator.evaluate(key, compareToValue) && value !is null) {
                        if(outList is null) {
                            outList = new HashSet!(TriggerKey)();
                        }
                        foreach (TriggerWrapper triggerWrapper ; value.values()) {
                            if(triggerWrapper !is null) {
                                outList.add(triggerWrapper.trigger.getKey());
                            }
                        }
                    }
                }
            }
        }

        return outList is null ? Collections.emptySet!(TriggerKey)() : outList;
    }

    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Job}</code>
     * groups.
     * </p>
     */
    List!(string) getJobGroupNames() {
        List!(string) outList;

        synchronized (lock) {
            outList = new LinkedList!(string)(jobsByGroup.keySet());
        }

        return outList;
    }

    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Trigger}</code>
     * groups.
     * </p>
     */
    List!(string) getTriggerGroupNames() {
        LinkedList!(string) outList;

        synchronized (lock) {
            outList = new LinkedList!(string)(triggersByGroup.keySet());
        }

        return outList;
    }

    /**
     * <p>
     * Get all of the Triggers that are associated to the given Job.
     * </p>
     *
     * <p>
     * If there are no matches, a zero-length array should be returned.
     * </p>
     */
    List!(Trigger) getTriggersForJob(JobKey jobKey) {
        ArrayList!(Trigger) trigList = new ArrayList!(Trigger)();

        synchronized (lock) {
            List!(TriggerWrapper) jobList = triggersByJob.get(jobKey);
            if(jobList !is null) {
                foreach(TriggerWrapper tw ; jobList) {
                    trigList.add(cast(Trigger) tw.trigger.clone());
                }
            }
        }

        return trigList;
    }

    protected ArrayList!(TriggerWrapper) getTriggerWrappersForJob(JobKey jobKey) {
        ArrayList!(TriggerWrapper) trigList = new ArrayList!(TriggerWrapper)();

        synchronized (lock) {
            List!(TriggerWrapper) jobList = triggersByJob.get(jobKey);
            if(jobList !is null) {
                foreach(TriggerWrapper trigger ; jobList) {
                    trigList.add(trigger);
                }
            }
        }

        return trigList;
    }

    protected ArrayList!(TriggerWrapper) getTriggerWrappersForCalendar(string calName) {
        ArrayList!(TriggerWrapper) trigList = new ArrayList!(TriggerWrapper)();

        synchronized (lock) {
            foreach(TriggerWrapper tw ; triggersByKey.values()) {
                string tcalName = tw.getTrigger().getCalendarName();
                if (tcalName !is null && tcalName== calName) {
                    trigList.add(tw);
                }
            }
        }

        return trigList;
    }

    /**
     * <p>
     * Pause the <code>{@link Trigger}</code> with the given name.
     * </p>
     *
     */
    void pauseTrigger(TriggerKey triggerKey) {

        synchronized (lock) {
            TriggerWrapper tw = triggersByKey.get(triggerKey);
    
            // does the trigger exist?
            if (tw is null || tw.trigger is null) {
                return;
            }
    
            // if the trigger is "complete" pausing it does not make sense...
            if (tw.state == TriggerWrapper.STATE_COMPLETE) {
                return;
            }

            if(tw.state == TriggerWrapper.STATE_BLOCKED) {
                tw.state = TriggerWrapper.STATE_PAUSED_BLOCKED;
            } else {
                tw.state = TriggerWrapper.STATE_PAUSED;
            }

            timeTriggers.remove(tw);
        }
    }

    /**
     * <p>
     * Pause all of the known <code>{@link Trigger}s</code> matching.
     * </p>
     *
     * <p>
     * The JobStore should "remember" the groups paused, and impose the
     * pause on any new triggers that are added to one of these groups while the group is
     * paused.
     * </p>
     *
     */
    List!(string) pauseTriggers(GroupMatcher!(TriggerKey) matcher) {

        List!(string) pausedGroups;
        synchronized (lock) {
            pausedGroups = new LinkedList!(string)();

            StringOperatorName operator = matcher.getCompareWithOperator();
            if(operator == StringOperatorName.EQUALS) {
                if(pausedTriggerGroups.add(matcher.getCompareToValue())) {
                        pausedGroups.add(matcher.getCompareToValue());
                }
            } else {
                foreach(string group ; triggersByGroup.keySet()) {
                        if(operator.evaluate(group, matcher.getCompareToValue())) {
                            if(pausedTriggerGroups.add(matcher.getCompareToValue())) {
                                pausedGroups.add(group);
                            }
                        }
                }
            }
            

            foreach(string pausedGroup ; pausedGroups) {
                Set!(TriggerKey) keys = getTriggerKeys(GroupMatcherHelper.triggerGroupEquals(pausedGroup));

                foreach(TriggerKey key; keys) {
                    pauseTrigger(key);
                }
            }
        }

        return pausedGroups;
    }

    /**
     * <p>
     * Pause the <code>{@link hunt.quartz.JobDetail}</code> with the given
     * name - by pausing all of its current <code>Trigger</code>s.
     * </p>
     *
     */
    void pauseJob(JobKey jobKey) {
        synchronized (lock) {
            List!(Trigger) triggersOfJob = getTriggersForJob(jobKey);
            foreach(Trigger trigger; triggersOfJob) {
                pauseTrigger(trigger.getKey());
            }
        }
    }

    /**
     * <p>
     * Pause all of the <code>{@link hunt.quartz.JobDetail}s</code> in the
     * given group - by pausing all of their <code>Trigger</code>s.
     * </p>
     *
     *
     * <p>
     * The JobStore should "remember" that the group is paused, and impose the
     * pause on any new jobs that are added to the group while the group is
     * paused.
     * </p>
     */
    List!(string) pauseJobs(GroupMatcher!(JobKey) matcher) {
        List!(string) pausedGroups = new LinkedList!(string)();
        synchronized (lock) {

            StringOperatorName operator = matcher.getCompareWithOperator();
            if(operator == StringOperatorName.EQUALS) {
                if (pausedJobGroups.add(matcher.getCompareToValue())) {
                        pausedGroups.add(matcher.getCompareToValue());
                }
            } else {
                foreach (string group ; jobsByGroup.keySet()) {
                    if(operator.evaluate(group, matcher.getCompareToValue())) {
                        if (pausedJobGroups.add(group)) {
                            pausedGroups.add(group);
                        }
                    }
                }
            }

            foreach(string groupName ; pausedGroups) {
                foreach (JobKey jobKey; getJobKeys(GroupMatcherHelper.jobGroupEquals(groupName))) {
                    List!(Trigger) triggersOfJob = getTriggersForJob(jobKey);
                    foreach(Trigger trigger; triggersOfJob) {
                        pauseTrigger(trigger.getKey());
                    }
                }
            }
        }

        return pausedGroups;
    }

    /**
     * <p>
     * Resume (un-pause) the <code>{@link Trigger}</code> with the given
     * key.
     * </p>
     *
     * <p>
     * If the <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     *
     */
    void resumeTrigger(TriggerKey triggerKey) {

        synchronized (lock) {
            TriggerWrapper tw = triggersByKey.get(triggerKey);
    
            // does the trigger exist?
            if (tw is null || tw.trigger is null) {
                return;
            }
    
            OperableTrigger trig = tw.getTrigger();
    
            // if the trigger is not paused resuming it does not make sense...
            if (tw.state != TriggerWrapper.STATE_PAUSED &&
                    tw.state != TriggerWrapper.STATE_PAUSED_BLOCKED) {
                return;
            }

            if(blockedJobs.contains( trig.getJobKey() )) {
                tw.state = TriggerWrapper.STATE_BLOCKED;
            } else {
                tw.state = TriggerWrapper.STATE_WAITING;
            }

            applyMisfire(tw);

            if (tw.state == TriggerWrapper.STATE_WAITING) {
                timeTriggers.add(tw);
            }
        }
    }

    /**
     * <p>
     * Resume (un-pause) all of the <code>{@link Trigger}s</code> in the
     * given group.
     * </p>
     *
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     *
     */
    List!(string) resumeTriggers(GroupMatcher!(TriggerKey) matcher) {
        Set!(string) groups = new HashSet!(string)();

        synchronized (lock) {
            Set!(TriggerKey) keys = getTriggerKeys(matcher);

            foreach(TriggerKey triggerKey; keys) {
                groups.add(triggerKey.getGroup());
                if(triggersByKey.get(triggerKey) !is null) {
                    string jobGroup = triggersByKey.get(triggerKey).jobKey.getGroup();
                    if(pausedJobGroups.contains(jobGroup)) {
                        continue;
                    }
                }
                resumeTrigger(triggerKey);
            }

            // Find all matching paused trigger groups, and then remove them.
            StringOperatorName operator = matcher.getCompareWithOperator();
            LinkedList!(string) pausedGroups = new LinkedList!(string)();
            string matcherGroup = matcher.getCompareToValue();
            if(operator == StringOperatorName.EQUALS) {
                if(pausedTriggerGroups.contains(matcherGroup)) {
                    pausedGroups.add(matcher.getCompareToValue());
                }

            } else {
                foreach(string group ; pausedTriggerGroups) {
                    if(operator.evaluate(group, matcherGroup)) {
                        pausedGroups.add(group);
                    }
                }
            }
            
            foreach(string pausedGroup ; pausedGroups) {
                pausedTriggerGroups.remove(pausedGroup);
            }
        }

        return new ArrayList!(string)(groups);
    }

    /**
     * <p>
     * Resume (un-pause) the <code>{@link hunt.quartz.JobDetail}</code> with
     * the given name.
     * </p>
     *
     * <p>
     * If any of the <code>Job</code>'s!(code)Trigger</code> s missed one
     * or more fire-times, then the <code>Trigger</code>'s misfire
     * instruction will be applied.
     * </p>
     *
     */
    void resumeJob(JobKey jobKey) {

        synchronized (lock) {
            List!(Trigger) triggersOfJob = getTriggersForJob(jobKey);
            foreach(Trigger trigger; triggersOfJob) {
                resumeTrigger(trigger.getKey());
            }
        }
    }

    /**
     * <p>
     * Resume (un-pause) all of the <code>{@link hunt.quartz.JobDetail}s</code>
     * in the given group.
     * </p>
     *
     * <p>
     * If any of the <code>Job</code> s had <code>Trigger</code> s that
     * missed one or more fire-times, then the <code>Trigger</code>'s
     * misfire instruction will be applied.
     * </p>
     *
     */
    Collection!(string) resumeJobs(GroupMatcher!(JobKey) matcher) {
        Set!(string) resumedGroups = new HashSet!(string)();
        synchronized (lock) {
            Set!(JobKey) keys = getJobKeys(matcher);

            foreach(string pausedJobGroup ; pausedJobGroups) {
                if(matcher.getCompareWithOperator().evaluate(pausedJobGroup, matcher.getCompareToValue())) {
                    resumedGroups.add(pausedJobGroup);
                }
            }

            foreach(string resumedGroup ; resumedGroups) {
                pausedJobGroups.remove(resumedGroup);
            }

            foreach(JobKey key; keys) {
                List!(Trigger) triggersOfJob = getTriggersForJob(key);
                foreach(Trigger trigger; triggersOfJob) {
                    resumeTrigger(trigger.getKey());
                }
            }
        }
        return resumedGroups;
    }

    /**
     * <p>
     * Pause all triggers - equivalent of calling <code>pauseTriggerGroup(group)</code>
     * on every group.
     * </p>
     *
     * <p>
     * When <code>resumeAll()</code> is called (to un-pause), trigger misfire
     * instructions WILL be applied.
     * </p>
     *
     * @see #resumeAll()
     * @see #pauseTrigger(hunt.quartz.TriggerKey)
     * @see #pauseTriggers(hunt.quartz.impl.matchers.GroupMatcher)
     */
    void pauseAll() {

        synchronized (lock) {
            List!(string) names = getTriggerGroupNames();

            foreach(string name; names) {
                pauseTriggers(GroupMatcherHelper.triggerGroupEquals(name));
            }
        }
    }

    /**
     * <p>
     * Resume (un-pause) all triggers - equivalent of calling <code>resumeTriggerGroup(group)</code>
     * on every group.
     * </p>
     *
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     *
     * @see #pauseAll()
     */
    void resumeAll() {

        synchronized (lock) {
            pausedJobGroups.clear();
            resumeTriggers(GroupMatcherHelper.anyTriggerGroup());
        }
    }

    protected bool applyMisfire(TriggerWrapper tw) {

        LocalDateTime misfireTime = LocalDateTime.now(); // DateTimeHelper.currentTimeMillis();
        if (getMisfireThreshold() > 0) {
            misfireTime = misfireTime.minusMilliseconds(getMisfireThreshold());
        }

        LocalDateTime tnft = tw.trigger.getNextFireTime();
        if (tnft is null || tnft > misfireTime 
                || tw.trigger.getMisfireInstruction() == Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY) { 
            return false; 
        }

        Calendar cal = null;
        if (tw.trigger.getCalendarName() !is null) {
            cal = retrieveCalendar(tw.trigger.getCalendarName());
        }

        signaler.notifyTriggerListenersMisfired(cast(OperableTrigger)tw.trigger.clone());

        tw.trigger.updateAfterMisfire(cal);

        if (tw.trigger.getNextFireTime() is null) {
            tw.state = TriggerWrapper.STATE_COMPLETE;
            signaler.notifySchedulerListenersFinalized(tw.trigger);
            synchronized (lock) {
                timeTriggers.remove(tw);
            }
        } else if (tnft== tw.trigger.getNextFireTime()) {
            return false;
        }

        return true;
    }

    private shared static long ftrCtr; // = new AtomicLong(DateTimeHelper.currentTimeMillis());

    shared static this() {
        ftrCtr = DateTimeHelper.currentTimeMillis();
    }

    protected string getFiredTriggerRecordId() {
        long f = atomicOp!("+=")(ftrCtr, 1);
        return to!string(f);
    }

    /**
     * <p>
     * Get a handle to the next trigger to be fired, and mark it as 'reserved'
     * by the calling scheduler.
     * </p>
     *
     * @see #releaseAcquiredTrigger(OperableTrigger)
     */
    List!(OperableTrigger) acquireNextTriggers(long noLaterThan, int maxCount, long timeWindow) {
        synchronized (lock) {
            List!(OperableTrigger) result = new ArrayList!(OperableTrigger)();
            Set!(JobKey) acquiredJobKeysForNoConcurrentExec = new HashSet!(JobKey)();
            Set!(TriggerWrapper) excludedTriggers = new HashSet!(TriggerWrapper)();
            long batchEnd = noLaterThan;
            
            // return empty list if store has no triggers.
            if (timeTriggers.size() == 0)
                return result;
            
            while (true) {
                TriggerWrapper tw;

                try {
                    tw = timeTriggers.first();
                    if (tw is null)
                        break;
                    timeTriggers.remove(tw);
                } catch (NoSuchElementException nsee) {
                    break;
                }

                if (tw.trigger.getNextFireTime() is null) {
                    continue;
                }

                if (applyMisfire(tw)) {
                    if (tw.trigger.getNextFireTime() !is null) {
                        timeTriggers.add(tw);
                    }
                    continue;
                }

                if (tw.getTrigger().getNextFireTime().toEpochMilli() > batchEnd) {
                    timeTriggers.add(tw);
                    break;
                }
                
                // If trigger's job is set as @DisallowConcurrentExecution, and it has already been added to result, then
                // put it back into the timeTriggers set and continue to search for next trigger.
                JobKey jobKey = tw.trigger.getJobKey();
                JobDetail job = jobsByKey.get(tw.trigger.getJobKey()).jobDetail;
                if (job.isConcurrentExectionDisallowed()) {
                    if (acquiredJobKeysForNoConcurrentExec.contains(jobKey)) {
                        excludedTriggers.add(tw);
                        continue; // go to next trigger in store.
                    } else {
                        acquiredJobKeysForNoConcurrentExec.add(jobKey);
                    }
                }

                tw.state = TriggerWrapper.STATE_ACQUIRED;
                tw.trigger.setFireInstanceId(getFiredTriggerRecordId());
                OperableTrigger trig = cast(OperableTrigger) tw.trigger.clone();
                if (result.isEmpty()) {
                    batchEnd = max(tw.trigger.getNextFireTime().toEpochMilli(), 
                        DateTimeHelper.currentTimeMillis()) + timeWindow;
                }
                result.add(trig);
                if (result.size() == maxCount)
                    break;
            }

            // If we did excluded triggers to prevent ACQUIRE state due to DisallowConcurrentExecution, we need to add them back to store.
            if (excludedTriggers.size() > 0)
                timeTriggers.addAll(excludedTriggers);
            return result;
        }
    }

    /**
     * <p>
     * Inform the <code>JobStore</code> that the scheduler no longer plans to
     * fire the given <code>Trigger</code>, that it had previously acquired
     * (reserved).
     * </p>
     */
    void releaseAcquiredTrigger(OperableTrigger trigger) {
        synchronized (lock) {
            TriggerWrapper tw = triggersByKey.get(trigger.getKey());
            if (tw !is null && tw.state == TriggerWrapper.STATE_ACQUIRED) {
                tw.state = TriggerWrapper.STATE_WAITING;
                timeTriggers.add(tw);
            }
        }
    }

    /**
     * <p>
     * Inform the <code>JobStore</code> that the scheduler is now firing the
     * given <code>Trigger</code> (executing its associated <code>Job</code>),
     * that it had previously acquired (reserved).
     * </p>
     */
    List!(TriggerFiredResult) triggersFired(List!(OperableTrigger) firedTriggers) {

        synchronized (lock) {
            List!(TriggerFiredResult) results = new ArrayList!(TriggerFiredResult)();

            foreach(OperableTrigger trigger ; firedTriggers) {
                TriggerWrapper tw = triggersByKey.get(trigger.getKey());
                // was the trigger deleted since being acquired?
                if (tw is null || tw.trigger is null) {
                    continue;
                }
                // was the trigger completed, paused, blocked, etc. since being acquired?
                if (tw.state != TriggerWrapper.STATE_ACQUIRED) {
                    continue;
                }

                Calendar cal = null;
                if (tw.trigger.getCalendarName() !is null) {
                    cal = retrieveCalendar(tw.trigger.getCalendarName());
                    if(cal is null)
                        continue;
                }
                LocalDateTime prevFireTime = trigger.getPreviousFireTime();
                // in case trigger was replaced between acquiring and firing
                timeTriggers.remove(tw);
                // call triggered on our copy, and the scheduler's copy
                tw.trigger.triggered(cal);
                trigger.triggered(cal);
                //tw.state = TriggerWrapper.STATE_EXECUTING;
                tw.state = TriggerWrapper.STATE_WAITING;

                TriggerFiredBundle bndle = new TriggerFiredBundle(retrieveJob(
                        tw.jobKey), trigger, cal,
                        false, LocalDateTime.now(), trigger.getPreviousFireTime(), prevFireTime,
                        trigger.getNextFireTime());

                JobDetail job = bndle.getJobDetail();

                if (job.isConcurrentExectionDisallowed()) {
                    ArrayList!(TriggerWrapper) trigs = getTriggerWrappersForJob(job.getKey());
                    foreach(TriggerWrapper ttw ; trigs) {
                        if (ttw.state == TriggerWrapper.STATE_WAITING) {
                            ttw.state = TriggerWrapper.STATE_BLOCKED;
                        }
                        if (ttw.state == TriggerWrapper.STATE_PAUSED) {
                            ttw.state = TriggerWrapper.STATE_PAUSED_BLOCKED;
                        }
                        timeTriggers.remove(ttw);
                    }
                    blockedJobs.add(job.getKey());
                } else if (tw.trigger.getNextFireTime() !is null) {
                    synchronized (lock) {
                        timeTriggers.add(tw);
                    }
                }

                results.add(new TriggerFiredResult(bndle));
            }
            return results;
        }
    }

    /**
     * <p>
     * Inform the <code>JobStore</code> that the scheduler has completed the
     * firing of the given <code>Trigger</code> (and the execution its
     * associated <code>Job</code>), and that the <code>{@link hunt.quartz.JobDataMap}</code>
     * in the given <code>JobDetail</code> should be updated if the <code>Job</code>
     * is stateful.
     * </p>
     */
    void triggeredJobComplete(OperableTrigger trigger,
            JobDetail jobDetail, CompletedExecutionInstruction triggerInstCode) {

        synchronized (lock) {

            JobWrapper jw = jobsByKey.get(jobDetail.getKey());
            TriggerWrapper tw = triggersByKey.get(trigger.getKey());

            // It's possible that the job is null if:
            //   1- it was deleted during execution
            //   2- RAMJobStore is being used only for jobs / triggers
            //      from the JDBC job store
            if (jw !is null) {
                JobDetail jd = jw.jobDetail;

                if (jd.isPersistJobDataAfterExecution()) {
                    JobDataMap newData = jobDetail.getJobDataMap();
                    if (newData !is null) {
                        newData = cast(JobDataMap)newData.clone();
                        newData.clearDirtyFlag();
                    }
                    jd = jd.getJobBuilder().setJobData(newData).build();
                    jw.jobDetail = jd;
                }
                if (jd.isConcurrentExectionDisallowed()) {
                    blockedJobs.remove(jd.getKey());
                    ArrayList!(TriggerWrapper) trigs = getTriggerWrappersForJob(jd.getKey());
                    foreach(TriggerWrapper ttw ; trigs) {
                        if (ttw.state == TriggerWrapper.STATE_BLOCKED) {
                            ttw.state = TriggerWrapper.STATE_WAITING;
                            timeTriggers.add(ttw);
                        }
                        if (ttw.state == TriggerWrapper.STATE_PAUSED_BLOCKED) {
                            ttw.state = TriggerWrapper.STATE_PAUSED;
                        }
                    }
                    signaler.signalSchedulingChange(0L);
                }
            } else { // even if it was deleted, there may be cleanup to do
                blockedJobs.remove(jobDetail.getKey());
            }
    
            // check for trigger deleted during execution...
            if (tw !is null) {
                if (triggerInstCode == CompletedExecutionInstruction.DELETE_TRIGGER) {
                    
                    if(trigger.getNextFireTime() is null) {
                        // double check for possible reschedule within job 
                        // execution, which would cancel the need to delete...
                        if(tw.getTrigger().getNextFireTime() is null) {
                            removeTrigger(trigger.getKey());
                        }
                    } else {
                        removeTrigger(trigger.getKey());
                        signaler.signalSchedulingChange(0L);
                    }
                } else if (triggerInstCode == CompletedExecutionInstruction.SET_TRIGGER_COMPLETE) {
                    tw.state = TriggerWrapper.STATE_COMPLETE;
                    timeTriggers.remove(tw);
                    signaler.signalSchedulingChange(0L);
                } else if(triggerInstCode == CompletedExecutionInstruction.SET_TRIGGER_ERROR) {
                    info("Trigger " ~ trigger.getKey().toString() ~ " set to ERROR state.");
                    tw.state = TriggerWrapper.STATE_ERROR;
                    signaler.signalSchedulingChange(0L);
                } else if (triggerInstCode == CompletedExecutionInstruction.SET_ALL_JOB_TRIGGERS_ERROR) {
                    info("All triggers of Job " 
                            ~ trigger.getJobKey().toString() ~ " set to ERROR state.");
                    setAllTriggersOfJobToState(trigger.getJobKey(), TriggerWrapper.STATE_ERROR);
                    signaler.signalSchedulingChange(0L);
                } else if (triggerInstCode == CompletedExecutionInstruction.SET_ALL_JOB_TRIGGERS_COMPLETE) {
                    setAllTriggersOfJobToState(trigger.getJobKey(), TriggerWrapper.STATE_COMPLETE);
                    signaler.signalSchedulingChange(0L);
                }
            }
        }
    }

    override
    long getAcquireRetryDelay(int failureCount) {
        return 20;
    }

    protected void setAllTriggersOfJobToState(JobKey jobKey, int state) {
        ArrayList!(TriggerWrapper) tws = getTriggerWrappersForJob(jobKey);
        foreach(TriggerWrapper tw ; tws) {
            tw.state = state;
            if (state != TriggerWrapper.STATE_WAITING) {
                timeTriggers.remove(tw);
            }
        }
    }
    
    
    protected string peekTriggers() {

        StringBuilder str = new StringBuilder();
        synchronized (lock) {
            foreach (TriggerWrapper triggerWrapper ; triggersByKey.values()) {
                str.append(triggerWrapper.trigger.getKey().getName());
                str.append("/");
            }
        }
        str.append(" | ");

        synchronized (lock) {
            foreach(TriggerWrapper timeTrigger ; timeTriggers) {
                str.append(timeTrigger.trigger.getKey().getName());
                str.append("->");
            }
        }

        return str.toString();
    }

    /** 
     * @see hunt.quartz.spi.JobStore#getPausedTriggerGroups()
     */
    Set!(string) getPausedTriggerGroups() {
        HashSet!(string) set = new HashSet!(string)();
        
        set.addAll(pausedTriggerGroups);
        
        return set;
    }

    void setInstanceId(string schedInstId) {
        //
    }

    void setInstanceName(string schedName) {
        //
    }

    void setThreadPoolSize(int poolSize) {
        //
    }

    long getEstimatedTimeToReleaseAndAcquireTrigger() {
        return 5;
    }

    bool isClustered() {
        return false;
    }

}

/*******************************************************************************
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * Helper Classes. * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 */

class TriggerWrapperComparator : Comparator!(TriggerWrapper) { // , java.io.Serializable
  

    TriggerTimeComparator ttc;

    this() {
        ttc = new TriggerTimeComparator();
    }
    
    int compare(TriggerWrapper trig1, TriggerWrapper trig2) {
        return ttc.compare(trig1.trigger, trig2.trigger);
    }

    override
    bool opEquals(Object obj) {
        TriggerWrapperComparator c = cast(TriggerWrapperComparator)obj;
        return c !is null;
    }

    override
    size_t toHash() @trusted nothrow {
        return super.toHash();
    }
}

class JobWrapper {

    JobKey key;

    JobDetail jobDetail;

    this(JobDetail jobDetail) {
        this.jobDetail = jobDetail;
        key = jobDetail.getKey();
    }

    override
    bool opEquals(Object obj) {
        JobWrapper jw = cast(JobWrapper) obj;
        if (jw !is null) {
            if (jw.key == this.key) {
                return true;
            }
        }

        return false;
    }
    
    override
    size_t toHash() @trusted nothrow {
        return key.toHash(); 
    }
}

class TriggerWrapper {

    TriggerKey key;

    JobKey jobKey;

    OperableTrigger trigger;

    int state = STATE_WAITING;

    enum int STATE_WAITING = 0;

    enum int STATE_ACQUIRED = 1;

    
    enum int STATE_EXECUTING = 2;

    enum int STATE_COMPLETE = 3;

    enum int STATE_PAUSED = 4;

    enum int STATE_BLOCKED = 5;

    enum int STATE_PAUSED_BLOCKED = 6;

    enum int STATE_ERROR = 7;
    
    this(OperableTrigger trigger) {
        if(trigger is null)
            throw new IllegalArgumentException("Trigger cannot be null!");
        this.trigger = trigger;
        key = trigger.getKey();
        this.jobKey = trigger.getJobKey();
    }

    override
    bool opEquals(Object obj) {
        TriggerWrapper tw = cast(TriggerWrapper) obj;
        if (tw !is null) {
            if (tw.key == this.key) {
                return true;
            }
        }

        return false;
    }

    override
    size_t toHash() @trusted nothrow {
        return key.toHash(); 
    }

    
    OperableTrigger getTrigger() {
        return this.trigger;
    }
}
