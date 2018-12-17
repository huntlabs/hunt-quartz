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
module hunt.quartz.impl.RemoteMBeanScheduler;

import hunt.lang.exception;
import java.container.Collections;
import std.datetime;
import java.util.HashSet;
import java.util.List;
import hunt.container.Map;
import hunt.comtainer.Set;

import javax.management.Attribute;
import javax.management.AttributeList;
import javax.management.MalformedObjectNameException;
import javax.management.ObjectName;
import javax.management.openmbean.CompositeData;

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
import hunt.quartz.core.jmx.JobDetailSupport;
import hunt.quartz.core.jmx.TriggerSupport;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.impl.matchers.StringMatcher;
import hunt.quartz.spi.JobFactory;

/**
 * <p>
 * An implementation of the <code>Scheduler</code> interface that remotely
 * proxies all method calls to the equivalent call on a given <code>QuartzScheduler</code>
 * instance, via JMX.
 * </p>
 * 
 * <p>
 * A user must create a subclass to implement the actual connection to the remote 
 * MBeanServer using their application specific connector.
 * </p>
 * @see hunt.quartz.Scheduler
 * @see hunt.quartz.core.QuartzScheduler
 */
abstract class RemoteMBeanScheduler implements Scheduler {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private ObjectName schedulerObjectName;
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    RemoteMBeanScheduler() { 
    }
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Properties.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */
    
    /**
     * Get the name under which the Scheduler MBean is registered on the
     * remote MBean server.
     */
    protected ObjectName getSchedulerObjectName() {
        return schedulerObjectName;
    }

    /**
     * Set the name under which the Scheduler MBean is registered on the
     * remote MBean server.
     */
    void setSchedulerObjectName(string schedulerObjectName)  throws SchedulerException {
        try {
            this.schedulerObjectName = new ObjectName(schedulerObjectName);
        } catch (MalformedObjectNameException e) {
            throw new SchedulerException("Failed to parse Scheduler MBean name: " ~ schedulerObjectName, e);
        }
    }

    /**
     * Set the name under which the Scheduler MBean is registered on the
     * remote MBean server.
     */
    void setSchedulerObjectName(ObjectName schedulerObjectName)  throws SchedulerException {
        this.schedulerObjectName = schedulerObjectName;
    }

    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Abstract methods.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Initialize this RemoteMBeanScheduler instance, connecting to the
     * remote MBean server.
     */
    abstract void initialize();

    /**
     * Get the given attribute of the remote Scheduler MBean.
     */
    protected abstract Object getAttribute(
            string attribute);
        
    /**
     * Get the given attributes of the remote Scheduler MBean.
     */
    protected abstract AttributeList getAttributes(string[] attributes);
    
    /**
     * Invoke the given operation on the remote Scheduler MBean.
     */
    protected abstract Object invoke(
        string operationName,
        Object[] params,
        string[] signature);
        

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
    string getSchedulerName() throws SchedulerException {
        return (string)getAttribute("SchedulerName");
    }

    /**
     * <p>
     * Returns the instance Id of the <code>Scheduler</code>.
     * </p>
     */
    string getSchedulerInstanceId() throws SchedulerException {
        return (string)getAttribute("SchedulerInstanceId");
    }

    SchedulerMetaData getMetaData() throws SchedulerException {
        AttributeList attributeList =
            getAttributes(
                new string[] {
                    "SchedulerName",
                    "SchedulerInstanceId",
                    "StandbyMode",
                    "Shutdown",
                    "JobStoreClassName",
                    "ThreadPoolClassName",
                    "ThreadPoolSize",
                    "Version",
                    "PerformanceMetrics"
                });

        try {
            return new SchedulerMetaData(
                    (string)getAttribute(attributeList, 0).getValue(),
                    (string)getAttribute(attributeList, 1).getValue(),
                    getClass(), true, false,
                    (Boolean)getAttribute(attributeList, 2).getValue(),
                    (Boolean)getAttribute(attributeList, 3).getValue(),
                    null,
                    Integer.parseInt(((Map)getAttribute(attributeList, 8).getValue()).get("JobsExecuted").toString()),
                    Class.forName((string)getAttribute(attributeList, 4).getValue()),
                    false,
                    false,
                    Class.forName((string)getAttribute(attributeList, 5).getValue()),
                    (Integer)getAttribute(attributeList, 6).getValue(),
                    (string)getAttribute(attributeList, 7).getValue());
        } catch (ClassNotFoundException e) {
            throw new SchedulerException(e);
        }
    }

    private Attribute getAttribute(AttributeList attributeList, int index) {
        return (Attribute)attributeList.get(index);
    }

    /**
     * <p>
     * Returns the <code>SchedulerContext</code> of the <code>Scheduler</code>.
     * </p>
     */
    SchedulerContext getContext() throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
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
        invoke("start", new Object[] {}, new string[] {});
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void startDelayed(int seconds) throws SchedulerException {
        invoke("startDelayed", new Object[] {seconds}, new string[] {int.class.getName()});
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void standby() throws SchedulerException {
        invoke("standby", new Object[] {}, new string[] {});
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
        return (Boolean) getAttribute("Started");
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool isInStandbyMode() throws SchedulerException {
        return (Boolean)getAttribute("StandbyMode");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void shutdown() throws SchedulerException {
        // Have to get the scheduler name before we actually call shutdown.
        string schedulerName = getSchedulerName();
        
        invoke("shutdown", new Object[] {}, new string[] {});
        SchedulerRepository.getInstance().remove(schedulerName);
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    void shutdown(bool waitForJobsToComplete) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool isShutdown() throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(JobExecutionContext) getCurrentlyExecutingJobs() throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Scheduling-related Methods
    ///
    ///////////////////////////////////////////////////////////////////////////

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    Date scheduleJob(JobDetail jobDetail, Trigger trigger)
        throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    Date scheduleJob(Trigger trigger) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void addJob(JobDetail jobDetail, bool replace)
        throws SchedulerException {
        invoke(
            "addJob", 
            new Object[] { JobDetailSupport.toCompositeData(jobDetail), replace },
            new string[] { CompositeData.class.getName(), bool.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void addJob(JobDetail jobDetail, bool replace, bool storeNonDurableWhileAwaitingScheduling)
            throws SchedulerException {
        invoke(
                "addJob",
                new Object[] { JobDetailSupport.toCompositeData(jobDetail), replace , storeNonDurableWhileAwaitingScheduling},
                new string[] { CompositeData.class.getName(), bool.class.getName(), bool.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    bool deleteJob(JobKey jobKey)
        throws SchedulerException {
        return (Boolean)invoke(
                "deleteJob",
                new Object[] { jobKey.getName(), jobKey.getGroup() },
                new string[] { string.class.getName(), string.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    bool unscheduleJob(TriggerKey triggerKey)
        throws SchedulerException {
        return (Boolean)invoke(
                "unscheduleJob",
                new Object[] { triggerKey.getName(), triggerKey.getGroup() },
                new string[] { string.class.getName(), string.class.getName() });
    }


    bool deleteJobs(List!(JobKey) jobKeys) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    void scheduleJobs(Map<JobDetail, Set<? extends Trigger>> triggersAndJobs, bool replace) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    void scheduleJob(JobDetail jobDetail, Set<? extends Trigger> triggersForJob, bool replace) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    bool unscheduleJobs(List!(TriggerKey) triggerKeys) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    Date rescheduleJob(TriggerKey triggerKey,
            Trigger newTrigger) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }
    
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void triggerJob(JobKey jobKey) throws SchedulerException {
        triggerJob(jobKey, null);
    }
    
    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void triggerJob(JobKey jobKey, JobDataMap data) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void pauseTrigger(TriggerKey triggerKey) throws SchedulerException {
        invoke(
            "pauseTrigger", 
            new Object[] { triggerKey.getName(), triggerKey.getGroup() },
            new string[] { string.class.getName(), string.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void pauseTriggers(GroupMatcher!(TriggerKey) matcher) throws SchedulerException {
        string operation = null;
        switch (matcher.getCompareWithOperator()) {
            case EQUALS:
                operation = "pauseTriggerGroup";
                break;
            case CONTAINS:
                operation = "pauseTriggersContaining";
                break;
            case STARTS_WITH:
                operation = "pauseTriggersStartingWith";
                break;
            case ENDS_WITH:
                operation = "pauseTriggersEndingWith";
            case ANYTHING:
                operation = "pauseTriggersAll";
        }

        if (operation !is null) {
            invoke(
                    operation,
                    new Object[] { matcher.getCompareToValue() },
                    new string[] { string.class.getName() });
        } else {
            throw new SchedulerException("Unsupported GroupMatcher kind for pausing triggers: " ~ matcher.getCompareWithOperator());
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void pauseJob(JobKey jobKey) throws SchedulerException {
        invoke(
            "pauseJob", 
            new Object[] { jobKey.getName(), jobKey.getGroup() },
            new string[] { string.class.getName(), string.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void pauseJobs(GroupMatcher!(JobKey) matcher) throws SchedulerException {
        string operation = null;
        switch (matcher.getCompareWithOperator()) {
            case EQUALS:
                operation = "pauseJobGroup";
                break;
            case STARTS_WITH:
                operation = "pauseJobsStartingWith";
                break;
            case ENDS_WITH:
                operation = "pauseJobsEndingWith";
                break;
            case CONTAINS:
                operation = "pauseJobsContaining";
            case ANYTHING:
                operation = "pauseJobsAll";
        }

        invoke(
                operation,
                new Object[] { matcher.getCompareToValue() },
                new string[] { string.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void resumeTrigger(TriggerKey triggerKey)
        throws SchedulerException {
        invoke(
            "resumeTrigger", 
            new Object[] { triggerKey.getName(), triggerKey.getGroup() },
            new string[] { string.class.getName(), string.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void resumeTriggers(GroupMatcher!(TriggerKey) matcher) throws SchedulerException {
        string operation = null;
        switch (matcher.getCompareWithOperator()) {
            case EQUALS:
                operation = "resumeTriggerGroup";
                break;
            case CONTAINS:
                operation = "resumeTriggersContaining";
                break;
            case STARTS_WITH:
                operation = "resumeTriggersStartingWith";
                break;
            case ENDS_WITH:
                operation = "resumeTriggersEndingWith";
            case ANYTHING:
                operation = "resumeTriggersAll";
        }

        if (operation !is null) {
            invoke(
                    operation,
                    new Object[] { matcher.getCompareToValue() },
                    new string[] { string.class.getName() });
        } else {
            throw new SchedulerException("Unsupported GroupMatcher kind for resuming triggers: " ~ matcher.getCompareWithOperator());
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void resumeJob(JobKey jobKey)
        throws SchedulerException {
        invoke(
            "resumeJob", 
            new Object[] { jobKey.getName(), jobKey.getGroup() },
            new string[] { string.class.getName(), string.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void resumeJobs(GroupMatcher!(JobKey) matcher) throws SchedulerException {
        string operation = null;
        switch (matcher.getCompareWithOperator()) {
            case EQUALS:
                operation = "resumeJobGroup";
                break;
            case STARTS_WITH:
                operation = "resumeJobsStartingWith";
                break;
            case ENDS_WITH:
                operation = "resumeJobsEndingWith";
                break;
            case CONTAINS:
                operation = "resumeJobsContaining";
            case ANYTHING:
                operation = "resumeJobsAll";
        }

        invoke(
                operation,
                new Object[] { matcher.getCompareToValue() },
                new string[] { string.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void pauseAll() throws SchedulerException {
        invoke(
            "pauseAllTriggers",
            new Object[] { }, 
            new string[] { });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void resumeAll() throws SchedulerException {
        invoke(
            "resumeAllTriggers",
            new Object[] { }, 
            new string[] { });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(string) getJobGroupNames() throws SchedulerException {
        return (List!(string))getAttribute("JobGroupNames");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    @SuppressWarnings("unchecked")
    Set!(JobKey) getJobKeys(GroupMatcher!(JobKey) matcher) throws SchedulerException {
        if (matcher.getCompareWithOperator()== StringMatcher.StringOperatorName.EQUALS) {
            List!(JobKey) keys = (List!(JobKey))invoke(
                    "getJobNames",
                    new Object[] { matcher.getCompareToValue() },
                    new string[] { string.class.getName() });

            return new HashSet!(JobKey)(keys);
        } else {
            throw new SchedulerException("Only equals matcher are supported for looking up JobKeys");
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(Trigger) getTriggersOfJob(JobKey jobKey) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(string) getTriggerGroupNames() throws SchedulerException {
        return (List!(string))getAttribute("TriggerGroupNames");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    @SuppressWarnings("unchecked")
    Set!(TriggerKey) getTriggerKeys(GroupMatcher!(TriggerKey) matcher) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    JobDetail getJobDetail(JobKey jobKey) throws SchedulerException {
        try {
            return JobDetailSupport.newJobDetail((CompositeData)invoke(
                    "getJobDetail",
                    new Object[] { jobKey.getName(), jobKey.getGroup() },
                    new string[] { string.class.getName(), string.class.getName() }));
        } catch (ClassNotFoundException e) {
            throw new SchedulerException("Unable to resolve job class", e);
        }
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    Trigger getTrigger(TriggerKey triggerKey) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool checkExists(JobKey jobKey) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    bool checkExists(TriggerKey triggerKey) throws SchedulerException {
        return (Boolean)invoke(
                "checkExists", 
                new Object[] { triggerKey }, 
                new string[] { TriggerKey.class.getName() });
    }
    
    void clear() throws SchedulerException {
        invoke(
                "clear", 
                new Object[] {  }, 
                new string[] {  });
    }


    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    TriggerState getTriggerState(TriggerKey triggerKey)
        throws SchedulerException {
        return TriggerState.valueOf((string)invoke(
                "getTriggerState",
                new Object[] { triggerKey.getName(), triggerKey.getGroup() },
                new string[] { string.class.getName(), string.class.getName() }));
    }


    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void resetTriggerFromErrorState(TriggerKey triggerKey)
            throws SchedulerException {
        invoke(
            "resetTriggerFromErrorState",
            new Object[] { triggerKey.getName(), triggerKey.getGroup() },
            new string[] { string.class.getName(), string.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    void addCalendar(string calName, Calendar calendar, bool replace, bool updateTriggers)
        throws SchedulerException {
        invoke(
            "addCalendar", 
            new Object[] { calName, calendar, replace, updateTriggers },
            new string[] { string.class.getName(), 
                    Calendar.class.getName(), bool.class.getName(), bool.class.getName() });
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    bool deleteCalendar(string calName) throws SchedulerException {
        invoke("deleteCalendar",
                new Object[] { calName },
                new string[] { string.class.getName() });
        return true;
    }

    /**
     * <p>
     * Calls th0e equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    Calendar getCalendar(string calName) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>,
     * passing the <code>SchedulingContext</code> associated with this
     * instance.
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(string) getCalendarNames() throws SchedulerException {
        return (List!(string))getAttribute("CalendarNames");
    }

    /**
     * @see hunt.quartz.Scheduler#getPausedTriggerGroups()
     */
    @SuppressWarnings("unchecked")
    Set!(string) getPausedTriggerGroups() throws SchedulerException {
        return (Set!(string))getAttribute("PausedTriggerGroups");
    }

    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Other Methods
    ///
    ///////////////////////////////////////////////////////////////////////////

    /**
     * <p>
     * Calls the equivalent method on the 'proxied' <code>QuartzScheduler</code>.
     * </p>
     */
    ListenerManager getListenerManager() throws SchedulerException {
        throw new SchedulerException(
                "Operation not supported for remote schedulers.");
    }

    /**
     * @see hunt.quartz.Scheduler#interrupt(JobKey)
     */
    bool interrupt(JobKey jobKey) throws UnableToInterruptJobException  {
        try {
            return (Boolean)invoke(
                    "interruptJob",
                    new Object[] { jobKey.getName(), jobKey.getGroup() },
                    new string[] { string.class.getName(), string.class.getName() });
        } catch (SchedulerException se) {
            throw new UnableToInterruptJobException(se);
        }
    }



    bool interrupt(string fireInstanceId) throws UnableToInterruptJobException {
        try {
            return (Boolean)invoke(
                    "interruptJob",
                    new Object[] { fireInstanceId },
                    new string[] { string.class.getName() });
        } catch (SchedulerException se) {
            throw new UnableToInterruptJobException(se);
        }
    }
    
    /**
     * @see hunt.quartz.Scheduler#setJobFactory(hunt.quartz.spi.JobFactory)
     */
    void setJobFactory(JobFactory factory) throws SchedulerException {
        throw new SchedulerException("Operation not supported for remote schedulers.");
    }
    
}
