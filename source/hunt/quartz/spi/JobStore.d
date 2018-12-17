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

module hunt.quartz.spi.JobStore;

import java.container.Collection;
import java.util.List;
import hunt.container.Map;
import hunt.comtainer.Set;

import hunt.quartz.Calendar;
import hunt.quartz.Job;
import hunt.quartz.JobDetail;
import hunt.quartz.JobKey;
import hunt.quartz.JobPersistenceException;
import hunt.quartz.ObjectAlreadyExistsException;
import hunt.quartz.SchedulerConfigException;
import hunt.quartz.SchedulerException;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.Trigger.CompletedExecutionInstruction;
import hunt.quartz.Trigger.TriggerState;
import hunt.quartz.impl.matchers.GroupMatcher;

/**
 * <p>
 * The interface to be implemented by classes that want to provide a <code>{@link hunt.quartz.Job}</code>
 * and <code>{@link hunt.quartz.Trigger}</code> storage mechanism for the
 * <code>{@link hunt.quartz.core.QuartzScheduler}</code>'s use.
 * </p>
 *
 * <p>
 * Storage of <code>Job</code> s and <code>Trigger</code> s should be keyed
 * on the combination of their name and group for uniqueness.
 * </p>
 *
 * @see hunt.quartz.core.QuartzScheduler
 * @see hunt.quartz.Trigger
 * @see hunt.quartz.Job
 * @see hunt.quartz.JobDetail
 * @see hunt.quartz.JobDataMap
 * @see hunt.quartz.Calendar
 *
 * @author James House
 * @author Eric Mueller
 */
interface JobStore {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Interface.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Called by the QuartzScheduler before the <code>JobStore</code> is
     * used, in order to give the it a chance to initialize.
     */
    void initialize(ClassLoadHelper loadHelper, SchedulerSignaler signaler);

    /**
     * Called by the QuartzScheduler to inform the <code>JobStore</code> that
     * the scheduler has started.
     */
    void schedulerStarted();

    /**
     * Called by the QuartzScheduler to inform the <code>JobStore</code> that
     * the scheduler has been paused.
     */
    void schedulerPaused();

    /**
     * Called by the QuartzScheduler to inform the <code>JobStore</code> that
     * the scheduler has resumed after being paused.
     */
    void schedulerResumed();

    /**
     * Called by the QuartzScheduler to inform the <code>JobStore</code> that
     * it should free up all of it's resources because the scheduler is
     * shutting down.
     */
    void shutdown();

    bool supportsPersistence();
    
    /**
     * How long (in milliseconds) the <code>JobStore</code> implementation 
     * estimates that it will take to release a trigger and acquire a new one. 
     */
    long getEstimatedTimeToReleaseAndAcquireTrigger();
    
    /**
     * Whether or not the <code>JobStore</code> implementation is clustered.
     */
    bool isClustered();

    /////////////////////////////////////////////////////////////////////////////
    //
    // Job & Trigger Storage methods
    //
    /////////////////////////////////////////////////////////////////////////////

    /**
     * Store the given <code>{@link hunt.quartz.JobDetail}</code> and <code>{@link hunt.quartz.Trigger}</code>.
     *
     * @param newJob
     *          The <code>JobDetail</code> to be stored.
     * @param newTrigger
     *          The <code>Trigger</code> to be stored.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Job</code> with the same name/group already
     *           exists.
     */
    void storeJobAndTrigger(JobDetail newJob, OperableTrigger newTrigger);

    /**
     * Store the given <code>{@link hunt.quartz.JobDetail}</code>.
     *
     * @param newJob
     *          The <code>JobDetail</code> to be stored.
     * @param replaceExisting
     *          If <code>true</code>, any <code>Job</code> existing in the
     *          <code>JobStore</code> with the same name & group should be
     *          over-written.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Job</code> with the same name/group already
     *           exists, and replaceExisting is set to false.
     */
    void storeJob(JobDetail newJob, bool replaceExisting);

    void storeJobsAndTriggers(Map<JobDetail, Set<? extends Trigger>> triggersAndJobs, bool replace);

    /**
     * Remove (delete) the <code>{@link hunt.quartz.Job}</code> with the given
     * key, and any <code>{@link hunt.quartz.Trigger}</code> s that reference
     * it.
     *
     * <p>
     * If removal of the <code>Job</code> results in an empty group, the
     * group should be removed from the <code>JobStore</code>'s list of
     * known group names.
     * </p>
     *
     * @return <code>true</code> if a <code>Job</code> with the given name &
     *         group was found and removed from the store.
     */
    bool removeJob(JobKey jobKey);
    
    bool removeJobs(List!(JobKey) jobKeys);
    
    /**
     * Retrieve the <code>{@link hunt.quartz.JobDetail}</code> for the given
     * <code>{@link hunt.quartz.Job}</code>.
     *
     * @return The desired <code>Job</code>, or null if there is no match.
     */
    JobDetail retrieveJob(JobKey jobKey);

    /**
     * Store the given <code>{@link hunt.quartz.Trigger}</code>.
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
    void storeTrigger(OperableTrigger newTrigger, bool replaceExisting);

    /**
     * Remove (delete) the <code>{@link hunt.quartz.Trigger}</code> with the
     * given key.
     *
     * <p>
     * If removal of the <code>Trigger</code> results in an empty group, the
     * group should be removed from the <code>JobStore</code>'s list of
     * known group names.
     * </p>
     *
     * <p>
     * If removal of the <code>Trigger</code> results in an 'orphaned' <code>Job</code>
     * that is not 'durable', then the <code>Job</code> should be deleted
     * also.
     * </p>
     *
     * @return <code>true</code> if a <code>Trigger</code> with the given
     *         name & group was found and removed from the store.
     */
    bool removeTrigger(TriggerKey triggerKey);

    bool removeTriggers(List!(TriggerKey) triggerKeys);

    /**
     * Remove (delete) the <code>{@link hunt.quartz.Trigger}</code> with the
     * given key, and store the new given one - which must be associated
     * with the same job.
     * 
     * @param newTrigger
     *          The new <code>Trigger</code> to be stored.
     *
     * @return <code>true</code> if a <code>Trigger</code> with the given
     *         name & group was found and removed from the store.
     */
    bool replaceTrigger(TriggerKey triggerKey, OperableTrigger newTrigger);

    /**
     * Retrieve the given <code>{@link hunt.quartz.Trigger}</code>.
     *
     * @return The desired <code>Trigger</code>, or null if there is no
     *         match.
     */
    OperableTrigger retrieveTrigger(TriggerKey triggerKey);

    
    /**
     * Determine whether a {@link Job} with the given identifier already 
     * exists within the scheduler.
     * 
     * @param jobKey the identifier to check for
     * @return true if a Job exists with the given identifier
     * @throws SchedulerException 
     */
    bool checkExists(JobKey jobKey); 
   
    /**
     * Determine whether a {@link Trigger} with the given identifier already 
     * exists within the scheduler.
     * 
     * @param triggerKey the identifier to check for
     * @return true if a Trigger exists with the given identifier
     * @throws SchedulerException 
     */
    bool checkExists(TriggerKey triggerKey);
 
    /**
     * Clear (delete!) all scheduling data - all {@link Job}s, {@link Trigger}s
     * {@link Calendar}s.
     * 
     * @throws JobPersistenceException
     */
    void clearAllSchedulingData();
    
    /**
     * Store the given <code>{@link hunt.quartz.Calendar}</code>.
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
    void storeCalendar(string name, Calendar calendar, bool replaceExisting, bool updateTriggers);

    /**
     * Remove (delete) the <code>{@link hunt.quartz.Calendar}</code> with the
     * given name.
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
    bool removeCalendar(string calName);

    /**
     * Retrieve the given <code>{@link hunt.quartz.Trigger}</code>.
     *
     * @param calName
     *          The name of the <code>Calendar</code> to be retrieved.
     * @return The desired <code>Calendar</code>, or null if there is no
     *         match.
     */
    Calendar retrieveCalendar(string calName);

    /////////////////////////////////////////////////////////////////////////////
    //
    // Informational methods
    //
    /////////////////////////////////////////////////////////////////////////////

    /**
     * Get the number of <code>{@link hunt.quartz.Job}</code> s that are
     * stored in the <code>JobsStore</code>.
     */
    int getNumberOfJobs();

    /**
     * Get the number of <code>{@link hunt.quartz.Trigger}</code> s that are
     * stored in the <code>JobsStore</code>.
     */
    int getNumberOfTriggers();

    /**
     * Get the number of <code>{@link hunt.quartz.Calendar}</code> s that are
     * stored in the <code>JobsStore</code>.
     */
    int getNumberOfCalendars();

    /**
     * Get the keys of all of the <code>{@link hunt.quartz.Job}</code> s that
     * have the given group name.
     *
     * <p>
     * If there are no jobs in the given group name, the result should be 
     * an empty collection (not <code>null</code>).
     * </p>
     */
    Set!(JobKey) getJobKeys(GroupMatcher!(JobKey) matcher);

    /**
     * Get the names of all of the <code>{@link hunt.quartz.Trigger}</code> s
     * that have the given group name.
     *
     * <p>
     * If there are no triggers in the given group name, the result should be a
     * zero-length array (not <code>null</code>).
     * </p>
     */
    Set!(TriggerKey) getTriggerKeys(GroupMatcher!(TriggerKey) matcher);

    /**
     * Get the names of all of the <code>{@link hunt.quartz.Job}</code>
     * groups.
     *
     * <p>
     * If there are no known group names, the result should be a zero-length
     * array (not <code>null</code>).
     * </p>
     */
    List!(string) getJobGroupNames();

    /**
     * Get the names of all of the <code>{@link hunt.quartz.Trigger}</code>
     * groups.
     *
     * <p>
     * If there are no known group names, the result should be a zero-length
     * array (not <code>null</code>).
     * </p>
     */
    List!(string) getTriggerGroupNames();

    /**
     * Get the names of all of the <code>{@link hunt.quartz.Calendar}</code> s
     * in the <code>JobStore</code>.
     *
     * <p>
     * If there are no Calendars in the given group name, the result should be
     * a zero-length array (not <code>null</code>).
     * </p>
     */
    List!(string) getCalendarNames();

    /**
     * Get all of the Triggers that are associated to the given Job.
     *
     * <p>
     * If there are no matches, a zero-length array should be returned.
     * </p>
     */
    List!(OperableTrigger) getTriggersForJob(JobKey jobKey);

    /**
     * Get the current state of the identified <code>{@link Trigger}</code>.
     *
     * @see Trigger.TriggerState
     */
    TriggerState getTriggerState(TriggerKey triggerKey);

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
    void resetTriggerFromErrorState(TriggerKey triggerKey);


    /////////////////////////////////////////////////////////////////////////////
    //
    // Trigger State manipulation methods
    //
    /////////////////////////////////////////////////////////////////////////////

    /**
     * Pause the <code>{@link hunt.quartz.Trigger}</code> with the given key.
     *
     * @see #resumeTrigger(TriggerKey)
     */
    void pauseTrigger(TriggerKey triggerKey);

    /**
     * Pause all of the <code>{@link hunt.quartz.Trigger}s</code> in the
     * given group.
     *
     *
     * <p>
     * The JobStore should "remember" that the group is paused, and impose the
     * pause on any new triggers that are added to the group while the group is
     * paused.
     * </p>
     *
     * @see #resumeTriggers(GroupMatcher)
     */
    Collection!(string) pauseTriggers(GroupMatcher!(TriggerKey) matcher);

    /**
     * Pause the <code>{@link hunt.quartz.Job}</code> with the given name - by
     * pausing all of its current <code>Trigger</code>s.
     *
     * @see #resumeJob(JobKey)
     */
    void pauseJob(JobKey jobKey);

    /**
     * Pause all of the <code>{@link hunt.quartz.Job}s</code> in the given
     * group - by pausing all of their <code>Trigger</code>s.
     *
     * <p>
     * The JobStore should "remember" that the group is paused, and impose the
     * pause on any new jobs that are added to the group while the group is
     * paused.
     * </p>
     *
     * @see #resumeJobs(GroupMatcher)
     */
    Collection!(string) pauseJobs(GroupMatcher!(JobKey) groupMatcher);

    /**
     * Resume (un-pause) the <code>{@link hunt.quartz.Trigger}</code> with the
     * given key.
     *
     * <p>
     * If the <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     *
     * @see #pauseTrigger(TriggerKey)
     */
    void resumeTrigger(TriggerKey triggerKey);

    /**
     * Resume (un-pause) all of the <code>{@link hunt.quartz.Trigger}s</code>
     * in the given group.
     *
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     *
     * @see #pauseTriggers(GroupMatcher)
     */
    Collection!(string) resumeTriggers(GroupMatcher!(TriggerKey) matcher);

    Set!(string) getPausedTriggerGroups();

    /**
     * Resume (un-pause) the <code>{@link hunt.quartz.Job}</code> with the
     * given key.
     *
     * <p>
     * If any of the <code>Job</code>'s!(code)Trigger</code> s missed one
     * or more fire-times, then the <code>Trigger</code>'s misfire
     * instruction will be applied.
     * </p>
     *
     * @see #pauseJob(JobKey)
     */
    void resumeJob(JobKey jobKey);

    /**
     * Resume (un-pause) all of the <code>{@link hunt.quartz.Job}s</code> in
     * the given group.
     *
     * <p>
     * If any of the <code>Job</code> s had <code>Trigger</code> s that
     * missed one or more fire-times, then the <code>Trigger</code>'s
     * misfire instruction will be applied.
     * </p>
     *
     * @see #pauseJobs(GroupMatcher)
     */
    Collection!(string) resumeJobs(GroupMatcher!(JobKey) matcher);

    /**
     * Pause all triggers - equivalent of calling <code>pauseTriggerGroup(group)</code>
     * on every group.
     *
     * <p>
     * When <code>resumeAll()</code> is called (to un-pause), trigger misfire
     * instructions WILL be applied.
     * </p>
     *
     * @see #resumeAll()
     * @see #pauseTriggers(GroupMatcher)
     */
    void pauseAll();

    /**
     * Resume (un-pause) all triggers - equivalent of calling <code>resumeTriggerGroup(group)</code>
     * on every group.
     *
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     *
     * @see #pauseAll()
     */
    void resumeAll();

    /////////////////////////////////////////////////////////////////////////////
    //
    // Trigger-Firing methods
    //
    /////////////////////////////////////////////////////////////////////////////

    /**
     * Get a handle to the next trigger to be fired, and mark it as 'reserved'
     * by the calling scheduler.
     *
     * @param noLaterThan If > 0, the JobStore should only return a Trigger
     * that will fire no later than the time represented in this value as
     * milliseconds.
     * @see #releaseAcquiredTrigger(OperableTrigger)
     */
    List!(OperableTrigger) acquireNextTriggers(long noLaterThan, int maxCount, long timeWindow);

    /**
     * Inform the <code>JobStore</code> that the scheduler no longer plans to
     * fire the given <code>Trigger</code>, that it had previously acquired
     * (reserved).
     */
    void releaseAcquiredTrigger(OperableTrigger trigger);

    /**
     * Inform the <code>JobStore</code> that the scheduler is now firing the
     * given <code>Trigger</code> (executing its associated <code>Job</code>),
     * that it had previously acquired (reserved).
     *
     * @return may return null if all the triggers or their calendars no longer exist, or
     *         if the trigger was not successfully put into the 'executing'
     *         state.  Preference is to return an empty list if none of the triggers
     *         could be fired.
     */
    List!(TriggerFiredResult) triggersFired(List!(OperableTrigger) triggers);

    /**
     * Inform the <code>JobStore</code> that the scheduler has completed the
     * firing of the given <code>Trigger</code> (and the execution of its
     * associated <code>Job</code> completed, threw an exception, or was vetoed),
     * and that the <code>{@link hunt.quartz.JobDataMap}</code>
     * in the given <code>JobDetail</code> should be updated if the <code>Job</code>
     * is stateful.
     */
    void triggeredJobComplete(OperableTrigger trigger, JobDetail jobDetail, CompletedExecutionInstruction triggerInstCode);

    /**
     * Inform the <code>JobStore</code> of the Scheduler instance's Id,
     * prior to initialize being invoked.
     *
     * @since 1.7
     */
    void setInstanceId(string schedInstId);

    /**
     * Inform the <code>JobStore</code> of the Scheduler instance's name,
     * prior to initialize being invoked.
     *
     * @since 1.7
     */
    void setInstanceName(string schedName);

    /**
     * Tells the JobStore the pool size used to execute jobs
     * @param poolSize amount of threads allocated for job execution
     * @since 2.0
     */
    void setThreadPoolSize(int poolSize);

    /**
     * Get the amount of time (in ms) to wait when accessing this job store
     * repeatedly fails.
     *
     * Called by the executor thread(s) when calls to
     * {@link #acquireNextTriggers} fail more than once in succession, and the
     * thread thus wants to wait a bit before trying again, to not consume
     * 100% CPU, write huge amounts of errors into logs, etc. in cases like
     * the DB being offline/restarting.
     *
     * The delay returned by implementations should be between 20 and
     * 600000 milliseconds.
     *
     * @param failureCount the number of successive failures seen so far
     * @return the time (in milliseconds) to wait before trying again
     */
    long getAcquireRetryDelay(int failureCount);
}
