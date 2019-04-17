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

module hunt.quartz.impl.StdScheduler;

import hunt.quartz.impl.matchers.GroupMatcher;

import hunt.quartz.Calendar;
import hunt.quartz.core.QuartzScheduler;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobKey;
import hunt.quartz.ListenerManager;
import hunt.quartz.Scheduler;
import hunt.quartz.SchedulerContext;
import hunt.quartz.Exceptions;
import hunt.quartz.SchedulerMetaData;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.spi.JobFactory;
import hunt.quartz.spi.OperableTrigger;

import hunt.collection.List;
import hunt.collection.Map;
import hunt.collection.Set;
import hunt.time.LocalDateTime;

// import std.datetime;
/**
 * <p>
 * An implementation of the <code>Scheduler</code> interface that directly
 * proxies all method calls to the equivalent call on a given <code>QuartzScheduler</code>
 * instance.
 * </p>
 * 
 * @see hunt.quartz.Scheduler
 * @see hunt.quartz.core.QuartzScheduler
 *
 * @author James House
 */
class StdScheduler : Scheduler {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private QuartzScheduler sched;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Construct a <code>StdScheduler</code> instance to proxy the given
     * <code>QuartzScheduler</code> instance, and with the given <code>SchedulingContext</code>.
     * </p>
     */
    this(QuartzScheduler sched) {
        this.sched = sched;
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
     * Returns the name of the <code>Scheduler</code>.
     * </p>
     */
    string getSchedulerName() {
        return sched.getSchedulerName();
    }

    /**
     * <p>
     * Returns the instance Id of the <code>Scheduler</code>.
     * </p>
     */
    string getSchedulerInstanceId() {
        return sched.getSchedulerInstanceId();
    }

    SchedulerMetaData getMetaData() {
        return new SchedulerMetaData(getSchedulerName(),
                getSchedulerInstanceId(), typeid(this), false, isStarted(), 
                isInStandbyMode(), isShutdown(), sched.runningSince(), 
                sched.numJobsExecuted(), sched.getJobStoreClass(), 
                sched.supportsPersistence(), sched.isClustered(), sched.getThreadPoolClass(), 
                sched.getThreadPoolSize(), sched.getVersion());

    }

    /**
     * <p>
     * Returns the <code>SchedulerContext</code> of the <code>Scheduler</code>.
     * </p>
     */
    SchedulerContext getContext() {
        return sched.getSchedulerContext();
    }

    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Schedululer State Management Methods
    ///
    ///////////////////////////////////////////////////////////////////////////

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void start() {
        sched.start();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void startDelayed(int seconds) {
        sched.startDelayed(seconds);
    }


    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void standby() {
        sched.standby();
    }
    
    /**
     * Whether the scheduler has been started.  
     * 
     * <p>
     * Note: This only reflects whether <code>{@link #start()}</code> has ever
     * been called on this Scheduler, so it will return <code>true</code> even 
     * if the <code>Scheduler</code> is currently in standby mode or has been 
     * since shutdown.
     * </p>
     * 
     * @see #start()
     * @see #isShutdown()
     * @see #isInStandbyMode()
     */    
    bool isStarted() {
        return (sched.runningSince() !is null);
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool isInStandbyMode() {
        return sched.isInStandbyMode();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void shutdown() {
        sched.shutdown();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void shutdown(bool waitForJobsToComplete) {
        sched.shutdown(waitForJobsToComplete);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool isShutdown() {
        return sched.isShutdown();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(JobExecutionContext) getCurrentlyExecutingJobs() {
        return sched.getCurrentlyExecutingJobs();
    }

    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Scheduling-related Methods
    ///
    ///////////////////////////////////////////////////////////////////////////

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void clear() {
        sched.clear();
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    LocalDateTime scheduleJob(JobDetail jobDetail, Trigger trigger) {
        return sched.scheduleJob(jobDetail, trigger);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    LocalDateTime scheduleJob(Trigger trigger) {
        return sched.scheduleJob(trigger);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void addJob(JobDetail jobDetail, bool replace) {
        sched.addJob(jobDetail, replace);
    }

    void addJob(JobDetail jobDetail, bool replace, bool storeNonDurableWhileAwaitingScheduling) {
        sched.addJob(jobDetail, replace, storeNonDurableWhileAwaitingScheduling);
    }


    bool deleteJobs(List!(JobKey) jobKeys) {
        return sched.deleteJobs(jobKeys);
    }

    void scheduleJobs(Map!(JobDetail, Set!(Trigger)) triggersAndJobs, bool replace) {
        sched.scheduleJobs(triggersAndJobs, replace);
    }

    void scheduleJob(JobDetail jobDetail, Set!(Trigger) triggersForJob, bool replace) {
        sched.scheduleJob(jobDetail,  triggersForJob, replace);
    }
    
    bool unscheduleJobs(List!(TriggerKey) triggerKeys) {
        return sched.unscheduleJobs(triggerKeys);
    }    
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool deleteJob(JobKey jobKey) {
        return sched.deleteJob(jobKey);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool unscheduleJob(TriggerKey triggerKey) {
        return sched.unscheduleJob(triggerKey);
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    LocalDateTime rescheduleJob(TriggerKey triggerKey,
            Trigger newTrigger) {
        return sched.rescheduleJob(triggerKey, newTrigger);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void triggerJob(JobKey jobKey) {
        triggerJob(jobKey, null);
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void triggerJob(JobKey jobKey, JobDataMap data) {
        sched.triggerJob(jobKey, data);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseTrigger(TriggerKey triggerKey) {
        sched.pauseTrigger(triggerKey);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseTriggers(GroupMatcher!(TriggerKey) matcher) {
        sched.pauseTriggers(matcher);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseJob(JobKey jobKey) {
        sched.pauseJob(jobKey);
    }

    /** 
     * @see hunt.quartz.Scheduler#getPausedTriggerGroups()
     */
    Set!(string) getPausedTriggerGroups() {
        return sched.getPausedTriggerGroups();
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseJobs(GroupMatcher!(JobKey) matcher) {
        sched.pauseJobs(matcher);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeTrigger(TriggerKey triggerKey) {
        sched.resumeTrigger(triggerKey);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeTriggers(GroupMatcher!(TriggerKey) matcher) {
        sched.resumeTriggers(matcher);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeJob(JobKey jobKey) {
        sched.resumeJob(jobKey);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeJobs(GroupMatcher!(JobKey) matcher) {
        sched.resumeJobs(matcher);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseAll() {
        sched.pauseAll();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeAll() {
        sched.resumeAll();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(string) getJobGroupNames() {
        return sched.getJobGroupNames();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(OperableTrigger) getTriggersOfJob(JobKey jobKey) {
        return sched.getTriggersOfJob(jobKey);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Set!(JobKey) getJobKeys(GroupMatcher!(JobKey) matcher) {
        return sched.getJobKeys(matcher);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(string) getTriggerGroupNames() {
        return sched.getTriggerGroupNames();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Set!(TriggerKey) getTriggerKeys(GroupMatcher!(TriggerKey) matcher) {
        return sched.getTriggerKeys(matcher);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    JobDetail getJobDetail(JobKey jobKey) {
        return sched.getJobDetail(jobKey);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Trigger getTrigger(TriggerKey triggerKey) {
        return sched.getTrigger(triggerKey);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    TriggerState getTriggerState(TriggerKey triggerKey) {
        return sched.getTriggerState(triggerKey);
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
     *
     * @see Trigger.TriggerState
     */
    void resetTriggerFromErrorState(TriggerKey triggerKey) {
        sched.resetTriggerFromErrorState(triggerKey);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void addCalendar(string calName, Calendar calendar, bool replace, bool updateTriggers) {
        sched.addCalendar(calName, calendar, replace, updateTriggers);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool deleteCalendar(string calName) {
        return sched.deleteCalendar(calName);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Calendar getCalendar(string calName) {
        return sched.getCalendar(calName);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(string) getCalendarNames() {
        return sched.getCalendarNames();
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool checkExists(JobKey jobKey) {
        return sched.checkExists(jobKey);
    }
    
   
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool checkExists(TriggerKey triggerKey) {
        return sched.checkExists(triggerKey);
    }

    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Other Methods
    ///
    ///////////////////////////////////////////////////////////////////////////

    

    /**
     * @see hunt.quartz.Scheduler#setJobFactory(hunt.quartz.spi.JobFactory)
     */
    void setJobFactory(JobFactory factory) {
        sched.setJobFactory(factory);
    }

    /**
     * @see hunt.quartz.Scheduler#getListenerManager()
     */
    ListenerManager getListenerManager() {
        return sched.getListenerManager();
    }

    bool interrupt(JobKey jobKey) {
        return sched.interrupt(jobKey);
    }

    bool interrupt(string fireInstanceId) {
        return sched.interrupt(fireInstanceId);
    }

  
}
