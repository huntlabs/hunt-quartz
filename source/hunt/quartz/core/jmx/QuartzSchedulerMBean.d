module hunt.quartz.core.jmx.QuartzSchedulerMBean;

// import std.datetime;
// import hunt.container.List;
// import hunt.container.Map;
// import hunt.container.Set;

// import javax.management.openmbean.CompositeData;
// import javax.management.openmbean.TabularData;

// interface QuartzSchedulerMBean {
//     enum string SCHEDULER_STARTED = "schedulerStarted";
//     enum string SCHEDULER_PAUSED = "schedulerPaused";
//     enum string SCHEDULER_SHUTDOWN = "schedulerShutdown";
//     enum string SCHEDULER_ERROR = "schedulerError";

//     enum string JOB_ADDED = "jobAdded";
//     enum string JOB_DELETED = "jobDeleted";
//     enum string JOB_SCHEDULED = "jobScheduled";
//     enum string JOB_UNSCHEDULED = "jobUnscheduled";
    
//     enum string JOBS_PAUSED = "jobsPaused";
//     enum string JOBS_RESUMED = "jobsResumed";

//     enum string JOB_EXECUTION_VETOED = "jobExecutionVetoed";
//     enum string JOB_TO_BE_EXECUTED = "jobToBeExecuted";
//     enum string JOB_WAS_EXECUTED = "jobWasExecuted";

//     enum string TRIGGER_FINALIZED = "triggerFinalized";

//     enum string TRIGGERS_PAUSED = "triggersPaused";
//     enum string TRIGGERS_RESUMED = "triggersResumed";

//     enum string SCHEDULING_DATA_CLEARED = "schedulingDataCleared";

//     enum string SAMPLED_STATISTICS_ENABLED = "sampledStatisticsEnabled";
//     enum string SAMPLED_STATISTICS_RESET = "sampledStatisticsReset";

//     string getSchedulerName();

//     string getSchedulerInstanceId();

//     bool isStandbyMode();

//     bool isShutdown();

//     string getVersion();

//     string getJobStoreClassName();

//     string getThreadPoolClassName();

//     int getThreadPoolSize();

//     long getJobsScheduledMostRecentSample();

//     long getJobsExecutedMostRecentSample();

//     long getJobsCompletedMostRecentSample();

//     Map!(string, Long) getPerformanceMetrics();

//     /**
//      * @return TabularData of CompositeData:JobExecutionContext
//      * @throws Exception
//      */
//     TabularData getCurrentlyExecutingJobs();

//     /**
//      * @return TabularData of CompositeData:JobDetail
//      * @throws Exception
//      * @see JobDetailSupport
//      */
//     TabularData getAllJobDetails();

//     /**
//      * @return List of CompositeData:[CronTrigger|SimpleTrigger]
//      * @throws Exception
//      * @see TriggerSupport
//      */
//     List!(CompositeData) getAllTriggers();

//     List!(string) getJobGroupNames();

//     List!(string) getJobNames(string groupName);

//     /**
//      * @return CompositeData:JobDetail
//      * @throws Exception
//      * @see JobDetailSupport
//      */
//     CompositeData getJobDetail(string jobName, string jobGroupName);

//     bool isStarted();

//     void start();

//     void shutdown();

//     void standby();

//     void clear();
    
//     /**
//      * Schedule an existing job with an existing trigger.
//      * 
//      * @param jobName
//      * @param jobGroup
//      * @param triggerName
//      * @param triggerGroup
//      * @return date of nextFireTime
//      * @throws Exception
//      */
//     LocalDateTime scheduleJob(string jobName, string jobGroup,
//             string triggerName, string triggerGroup);

//     /**
//      * Schedules a job using the given Cron/Simple triggerInfo.
//      * 
//      * The triggerInfo and jobDetailInfo must contain well-known attribute values.
//      *     TriggerInfo attributes: name, group, description, calendarName, priority,
//      *       CronExpression | (startTime, endTime, repeatCount, repeatInterval) 
//      *     JobDetailInfo attributes: name, group, description, jobClass, jobDataMap, durability,
//      *       shouldRecover
//      */
//     void scheduleBasicJob(Map!(string, Object) jobDetailInfo, Map!(string, Object) triggerInfo);

//     /**
//      * Schedules an arbitrary job described by abstractJobInfo using a trigger specified by abstractTriggerInfo.
//      * 
//      * AbtractTriggerInfo and AbstractJobInfo must contain the following string attributes.
//      *     AbstractTriggerInfo: triggerClass, the fully-qualified class name of a concrete Trigger type
//      *     AbstractJobInfo: jobDetailClass, the fully-qualified class name of a concrete JobDetail type
//      *
//      * If the Trigger and JobDetail can be successfully instantiated, the remaining attributes will be
//      * reflectively applied to those instances. The remaining attributes are limited to the types:
//      *   Integer, Double, Float, string, Boolean, LocalDateTime, Character, Map!(string, Object).
//      * Maps are further limited to containing values from the same set of types, less Map itself.
//      * 
//      * @throws Exception 
//      */
//     void scheduleJob(Map!(string, Object) abstractJobInfo,
//             Map!(string, Object) abstractTriggerInfo);
    
//     /**
//      * Schedules the specified job using a trigger described by abstractTriggerInfo, which must contain the
//      * fully-qualified trigger class name under the key "triggerClass."  That trigger type must contain a
//      * no-arg constructor and have public access. Other attributes are applied reflectively and are limited
//      * to the types:
//      *   Integer, Double, Float, string, Boolean, LocalDateTime, Character, Map!(string, Object).
//      * Maps are limited to containing values from the same set of types, less Map itself.
//      * 
//      * @param jobName
//      * @param jobGroup
//      * @param abstractTriggerInfo
//      * @throws Exception
//      */
//     void scheduleJob(string jobName, string jobGroup,
//             Map!(string, Object) abstractTriggerInfo);
    
//     bool unscheduleJob(string triggerName, string triggerGroup);

//     bool interruptJob(string jobName, string jobGroupName);

//     bool interruptJob(string fireInstanceId);
    
//     void triggerJob(string jobName, string jobGroupName,
//             Map!(string, string) jobDataMap);

//     bool deleteJob(string jobName, string jobGroupName);

//     void addJob(CompositeData jobDetail, bool replace);

//     /**
//      * Adds a durable job described by abstractJobInfo, which must contain the fully-qualified JobDetail
//      * class name under the key "jobDetailClass."  That JobDetail type must contain a no-arg constructor
//      * and have public access. Other attributes are applied reflectively and are limited
//      * to the types:
//      *   Integer, Double, Float, string, Boolean, LocalDateTime, Character, Map!(string, Object).
//      * Maps are limited to containing values from the same set of types, less Map itself.
//      * 
//      * @param abstractJobInfo map of attributes defining job
//      * @param replace whether or not to replace a pre-existing job with the same key
//      * @throws Exception
//      */
//     void addJob(Map!(string, Object) abstractJobInfo, bool replace);

//     void pauseJobGroup(string jobGroup);

//     /**
//      * Pause all jobs whose group starts with jobGroupPrefix
//      * @throws Exception
//      */
//     void pauseJobsStartingWith(string jobGroupPrefix);

//     /**
//      * Pause all jobs whose group ends with jobGroupSuffix
//      */
//     void pauseJobsEndingWith(string jobGroupSuffix);

//     /**
//      * Pause all jobs whose group contains jobGroupToken
//      */
//     void pauseJobsContaining(string jobGroupToken);

//     /**
//      * Pause all jobs whose group is anything
//      */
//     void pauseJobsAll();

//     /**
//      * Resume all jobs in the given group
//      */
//     void resumeJobGroup(string jobGroup);

//     /**
//      * Resume all jobs whose group starts with jobGroupPrefix
//      */
//     void resumeJobsStartingWith(string jobGroupPrefix);

//     /**
//      * Resume all jobs whose group ends with jobGroupSuffix
//      */
//     void resumeJobsEndingWith(string jobGroupSuffix);

//     /**
//      * Resume all jobs whose group contains jobGroupToken
//      */
//     void resumeJobsContaining(string jobGroupToken);

//     /**
//      * Resume all jobs whose group is anything
//      */
//     void resumeJobsAll();

//     void pauseJob(string jobName, string groupName);

//     void resumeJob(string jobName, string jobGroupName);

//     List!(string) getTriggerGroupNames();

//     List!(string) getTriggerNames(string triggerGroupName);

//     CompositeData getTrigger(string triggerName, string triggerGroupName);

//     string getTriggerState(string triggerName, string triggerGroupName);

//     /**
//      * @return List of CompositeData:[CronTrigger|SimpleTrigger] for the specified job.
//      * @see TriggerSupport
//      */
//     List!(CompositeData) getTriggersOfJob(string jobName, string jobGroupName);

//     Set!(string) getPausedTriggerGroups();

//     void pauseAllTriggers();

//     void resumeAllTriggers();

//     void pauseTriggerGroup(string triggerGroup);

//     /**
//      * Pause all triggers whose group starts with triggerGroupPrefix
//      */
//     void pauseTriggersStartingWith(string triggerGroupPrefix);

//     /**
//      * Pause all triggers whose group ends with triggerGroupSuffix
//      */
//     void pauseTriggersEndingWith(string suffix);

//     /**
//      * Pause all triggers whose group contains triggerGroupToken
//      */
//     void pauseTriggersContaining(string triggerGroupToken);

//     /**
//      * Pause all triggers whose group is anything
//      */
//     void pauseTriggersAll();

//     void resumeTriggerGroup(string triggerGroup);

//     /**
//      * Resume all triggers whose group starts with triggerGroupPrefix
//      */
//     void resumeTriggersStartingWith(string triggerGroupPrefix);

//     /**
//      * Resume all triggers whose group ends with triggerGroupSuffix
//      */
//     void resumeTriggersEndingWith(string triggerGroupSuffix);

//     /**
//      * Resume all triggers whose group contains triggerGroupToken
//      */
//     void resumeTriggersContaining(string triggerGroupToken);

//     /**
//      * Resume all triggers whose group is anything
//      */
//     void resumeTriggersAll();

//     void pauseTrigger(string triggerName, string triggerGroupName);

//     void resumeTrigger(string triggerName, string triggerGroupName);

//     List!(string) getCalendarNames();

//     void deleteCalendar(string name);

//     void setSampledStatisticsEnabled(bool enabled);

//     bool isSampledStatisticsEnabled();
// }
