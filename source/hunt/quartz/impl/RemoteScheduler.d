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

module hunt.quartz.impl.RemoteScheduler;

import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import std.datetime;
import java.util.List;
import hunt.container.Map;
import hunt.comtainer.Set;

import hunt.quartz.Calendar;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobKey;
import hunt.quartz.ListenerManager;
import hunt.quartz.Scheduler;
import hunt.quartz.SchedulerContext;
import hunt.quartz.SchedulerException;
import hunt.quartz.SchedulerMetaData;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.UnableToInterruptJobException;
import hunt.quartz.Trigger.TriggerState;
import hunt.quartz.core.RemotableQuartzScheduler;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.spi.JobFactory;

/**
 * <p>
 * An implementation of the <code>Scheduler</code> interface that remotely
 * proxies all method calls to the equivalent call on a given <code>QuartzScheduler</code>
 * instance, via RMI.
 * </p>
 * 
 * @see hunt.quartz.Scheduler
 * @see hunt.quartz.core.QuartzScheduler
 * 
 * @author James House
 */
class RemoteScheduler implements Scheduler {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private RemotableQuartzScheduler rsched;

    private string schedId;

    private string rmiHost;

    private int rmiPort;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Construct a <code>RemoteScheduler</code> instance to proxy the given
     * <code>RemoteableQuartzScheduler</code> instance, and with the given
     * <code>SchedulingContext</code>.
     * </p>
     */
    RemoteScheduler(string schedId, string host, int port) {
        this.schedId = schedId;
        this.rmiHost = host;
        this.rmiPort = port;
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    protected RemotableQuartzScheduler getRemoteScheduler()
        throws SchedulerException {
        if (rsched !is null) {
            return rsched;
        }

        try {
            Registry registry = LocateRegistry.getRegistry(rmiHost, rmiPort);

            rsched = (RemotableQuartzScheduler) registry.lookup(schedId);

        } catch (Exception e) {
            SchedulerException initException = new SchedulerException(
                    "Could not get handle to remote scheduler: "
                            + e.getMessage(), e);
            throw initException;
        }

        return rsched;
    }

    protected SchedulerException invalidateHandleCreateException(string msg,
            Exception cause) {
        rsched = null;
        SchedulerException ex = new SchedulerException(msg, cause);
        return ex;
    }

    /**
     * <p>
     * Returns the name of the <code>Scheduler</code>.
     * </p>
     */
    string getSchedulerName() throws SchedulerException {
        try {
            return getRemoteScheduler().getSchedulerName();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Returns the instance Id of the <code>Scheduler</code>.
     * </p>
     */
    string getSchedulerInstanceId() throws SchedulerException {
        try {
            return getRemoteScheduler().getSchedulerInstanceId();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    SchedulerMetaData getMetaData() throws SchedulerException {
        try {
            RemotableQuartzScheduler sched = getRemoteScheduler();
            return new SchedulerMetaData(getSchedulerName(),
                    getSchedulerInstanceId(), getClass(), true, isStarted(), 
                    isInStandbyMode(), isShutdown(), sched.runningSince(), 
                    sched.numJobsExecuted(), sched.getJobStoreClass(), 
                    sched.supportsPersistence(), sched.isClustered(), sched.getThreadPoolClass(), 
                    sched.getThreadPoolSize(), sched.getVersion());

        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }

    }

    /**
     * <p>
     * Returns the <code>SchedulerContext</code> of the <code>Scheduler</code>.
     * </p>
     */
    SchedulerContext getContext() throws SchedulerException {
        try {
            return getRemoteScheduler().getSchedulerContext();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
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
    void start() throws SchedulerException {
        try {
            getRemoteScheduler().start();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void startDelayed(int seconds) throws SchedulerException {
        try {
            getRemoteScheduler().startDelayed(seconds);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void standby() throws SchedulerException {
        try {
            getRemoteScheduler().standby();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
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
    bool isStarted() throws SchedulerException {
        try {
            return (getRemoteScheduler().runningSince() !is null);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }   
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool isInStandbyMode() throws SchedulerException {
        try {
            return getRemoteScheduler().isInStandbyMode();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void shutdown() throws SchedulerException {
        try {
            string schedulerName = getSchedulerName();
            
            getRemoteScheduler().shutdown();
            
            SchedulerRepository.getInstance().remove(schedulerName);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void shutdown(bool waitForJobsToComplete)
        throws SchedulerException {
        try {
            string schedulerName = getSchedulerName();
            
            getRemoteScheduler().shutdown(waitForJobsToComplete);

            SchedulerRepository.getInstance().remove(schedulerName);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool isShutdown() throws SchedulerException {
        try {
            return getRemoteScheduler().isShutdown();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(JobExecutionContext) getCurrentlyExecutingJobs() throws SchedulerException {
        try {
            return getRemoteScheduler().getCurrentlyExecutingJobs();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
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
    Date scheduleJob(JobDetail jobDetail, Trigger trigger)
        throws SchedulerException {
        try {
            return getRemoteScheduler().scheduleJob(jobDetail,
                    trigger);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Date scheduleJob(Trigger trigger) throws SchedulerException {
        try {
            return getRemoteScheduler().scheduleJob(trigger);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void addJob(JobDetail jobDetail, bool replace)
        throws SchedulerException {
        try {
            getRemoteScheduler().addJob(jobDetail, replace);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    void addJob(JobDetail jobDetail, bool replace, bool storeNonDurableWhileAwaitingScheduling)
            throws SchedulerException {
        try {
            getRemoteScheduler().addJob(jobDetail, replace, storeNonDurableWhileAwaitingScheduling);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    bool deleteJobs(List!(JobKey) jobKeys) throws SchedulerException {
        try {
            return getRemoteScheduler().deleteJobs(jobKeys);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    void scheduleJobs(Map<JobDetail, Set<? extends Trigger>> triggersAndJobs, bool replace) throws SchedulerException {
            try {
                getRemoteScheduler().scheduleJobs(triggersAndJobs, replace);
            } catch (RemoteException re) {
                throw invalidateHandleCreateException(
                        "Error communicating with remote scheduler.", re);
            }
    }
    
    void scheduleJob(JobDetail jobDetail, Set<? extends Trigger> triggersForJob, bool replace) throws SchedulerException {
        try {
            getRemoteScheduler().scheduleJob(jobDetail, triggersForJob, replace);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    bool unscheduleJobs(List!(TriggerKey) triggerKeys)
            throws SchedulerException {
        try {
            return getRemoteScheduler().unscheduleJobs(triggerKeys);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool deleteJob(JobKey jobKey)
        throws SchedulerException {
        try {
            return getRemoteScheduler()
                    .deleteJob(jobKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool unscheduleJob(TriggerKey triggerKey)
        throws SchedulerException {
        try {
            return getRemoteScheduler().unscheduleJob(triggerKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Date rescheduleJob(TriggerKey triggerKey,
            Trigger newTrigger) throws SchedulerException {
        try {
            return getRemoteScheduler().rescheduleJob(triggerKey,
                    newTrigger);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }
    
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void triggerJob(JobKey jobKey)
        throws SchedulerException {
        triggerJob(jobKey, null);
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void triggerJob(JobKey jobKey, JobDataMap data)
        throws SchedulerException {
        try {
            getRemoteScheduler().triggerJob(jobKey, data);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseTrigger(TriggerKey triggerKey)
        throws SchedulerException {
        try {
            getRemoteScheduler()
                    .pauseTrigger(triggerKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseTriggers(GroupMatcher!(TriggerKey) matcher) throws SchedulerException {
        try {
            getRemoteScheduler().pauseTriggers(matcher);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseJob(JobKey jobKey)
        throws SchedulerException {
        try {
            getRemoteScheduler().pauseJob(jobKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseJobs(GroupMatcher!(JobKey) matcher) throws SchedulerException {
        try {
            getRemoteScheduler().pauseJobs(matcher);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeTrigger(TriggerKey triggerKey)
        throws SchedulerException {
        try {
            getRemoteScheduler().resumeTrigger(triggerKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeTriggers(GroupMatcher!(TriggerKey) matcher) throws SchedulerException {
        try {
            getRemoteScheduler().resumeTriggers(matcher);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeJob(JobKey jobKey)
        throws SchedulerException {
        try {
            getRemoteScheduler().resumeJob(jobKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeJobs(GroupMatcher!(JobKey) matcher) throws SchedulerException {
        try {
            getRemoteScheduler().resumeJobs(matcher);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void pauseAll() throws SchedulerException {
        try {
            getRemoteScheduler().pauseAll();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resumeAll() throws SchedulerException {
        try {
            getRemoteScheduler().resumeAll();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(string) getJobGroupNames() throws SchedulerException {
        try {
            return getRemoteScheduler().getJobGroupNames();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Set!(JobKey) getJobKeys(GroupMatcher!(JobKey) matcher) throws SchedulerException {
        try {
            return getRemoteScheduler().getJobKeys(matcher);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List<? extends Trigger> getTriggersOfJob(JobKey jobKey)
        throws SchedulerException {
        try {
            return getRemoteScheduler().getTriggersOfJob(jobKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(string) getTriggerGroupNames() throws SchedulerException {
        try {
            return getRemoteScheduler().getTriggerGroupNames();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Set!(TriggerKey) getTriggerKeys(GroupMatcher!(TriggerKey) matcher) throws SchedulerException {
        try {
            return getRemoteScheduler().getTriggerKeys(matcher);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    JobDetail getJobDetail(JobKey jobKey)
        throws SchedulerException {
        try {
            return getRemoteScheduler().getJobDetail(jobKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool checkExists(JobKey jobKey) throws SchedulerException {
        try {
            return getRemoteScheduler().checkExists(jobKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }
   
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool checkExists(TriggerKey triggerKey) throws SchedulerException {
        try {
            return getRemoteScheduler().checkExists(triggerKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }
  
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void clear() throws SchedulerException {
        try {
            getRemoteScheduler().clear();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Trigger getTrigger(TriggerKey triggerKey)
        throws SchedulerException {
        try {
            return getRemoteScheduler().getTrigger(triggerKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    TriggerState getTriggerState(TriggerKey triggerKey)
        throws SchedulerException {
        try {
            return getRemoteScheduler().getTriggerState(triggerKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void resetTriggerFromErrorState(TriggerKey triggerKey)
            throws SchedulerException {
        try {
            getRemoteScheduler().resetTriggerFromErrorState(triggerKey);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }




    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void addCalendar(string calName, Calendar calendar, bool replace, bool updateTriggers)
        throws SchedulerException {
        try {
            getRemoteScheduler().addCalendar(calName, calendar,
                    replace, updateTriggers);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool deleteCalendar(string calName) throws SchedulerException {
        try {
            return getRemoteScheduler().deleteCalendar(calName);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Calendar getCalendar(string calName) throws SchedulerException {
        try {
            return getRemoteScheduler().getCalendar(calName);
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    List!(string) getCalendarNames() throws SchedulerException {
        try {
            return getRemoteScheduler().getCalendarNames();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }

    /** 
     * @see hunt.quartz.Scheduler#getPausedTriggerGroups()
     */
    Set!(string) getPausedTriggerGroups() throws SchedulerException {
        try {
            return getRemoteScheduler().getPausedTriggerGroups();
        } catch (RemoteException re) {
            throw invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re);
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Other Methods
    ///
    ///////////////////////////////////////////////////////////////////////////


    ListenerManager getListenerManager() throws SchedulerException {
        throw new SchedulerException(
            "Operation not supported for remote schedulers.");
    }

    /**
     * @see hunt.quartz.Scheduler#interrupt(JobKey)
     */
    bool interrupt(JobKey jobKey) throws UnableToInterruptJobException  {
        try {
            return getRemoteScheduler().interrupt(jobKey);
        } catch (RemoteException re) {
            throw new UnableToInterruptJobException(invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re));
        } catch (SchedulerException se) {
            throw new UnableToInterruptJobException(se);
        }
    }

    bool interrupt(string fireInstanceId) throws UnableToInterruptJobException {
        try {
            return getRemoteScheduler().interrupt(fireInstanceId);
        } catch (RemoteException re) {
            throw new UnableToInterruptJobException(invalidateHandleCreateException(
                    "Error communicating with remote scheduler.", re));
        } catch (SchedulerException se) {
            throw new UnableToInterruptJobException(se);
        }
    }

    /**
     * @see hunt.quartz.Scheduler#setJobFactory(hunt.quartz.spi.JobFactory)
     */
    void setJobFactory(JobFactory factory) throws SchedulerException {
        throw new SchedulerException(
                "Operation not supported for remote schedulers.");
    }

}
