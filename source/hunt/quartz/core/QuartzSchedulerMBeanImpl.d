module hunt.quartz.core.QuartzSchedulerMBeanImpl;

// import static hunt.quartz.JobKey.jobKey;
// import static hunt.quartz.TriggerKey.triggerKey;

// import java.beans.BeanInfo;
// import java.beans.IntrospectionException;
// import java.beans.Introspector;
// import java.beans.MethodDescriptor;
// import java.lang.reflect.Field;
// import java.lang.reflect.Method;
// import hunt.lang.exception;
// import hunt.container.ArrayList;
// import std.datetime;
// import hunt.container.HashMap;
// import hunt.container.List;
// import hunt.container.Map;
// import hunt.comtainer.Set;
// import java.util.concurrent.atomic.AtomicLong;

// import javax.management.ListenerNotFoundException;
// import javax.management.MBeanNotificationInfo;
// import javax.management.NotCompliantMBeanException;
// import javax.management.Notification;
// import javax.management.NotificationBroadcasterSupport;
// import javax.management.NotificationEmitter;
// import javax.management.NotificationFilter;
// import javax.management.NotificationListener;
// import javax.management.StandardMBean;
// import javax.management.openmbean.CompositeData;
// import javax.management.openmbean.TabularData;

// import hunt.quartz.JobDataMap;
// import hunt.quartz.JobDetail;
// import hunt.quartz.JobExecutionContext;
// import hunt.quartz.JobExecutionException;
// import hunt.quartz.JobKey;
// import hunt.quartz.JobListener;
// import hunt.quartz.SchedulerException;
// import hunt.quartz.SchedulerListener;
// import hunt.quartz.Trigger;
// import hunt.quartz.Trigger.TriggerState;
// import hunt.quartz.TriggerKey;
// import hunt.quartz.core.jmx.JobDetailSupport;
// import hunt.quartz.core.jmx.JobExecutionContextSupport;
// import hunt.quartz.core.jmx.QuartzSchedulerMBean;
// import hunt.quartz.core.jmx.TriggerSupport;
// import hunt.quartz.impl.matchers.GroupMatcher;
// import hunt.quartz.impl.triggers.AbstractTrigger;
// import hunt.quartz.spi.OperableTrigger;

// class QuartzSchedulerMBeanImpl : StandardMBean implements
//         NotificationEmitter, QuartzSchedulerMBean, JobListener,
//         SchedulerListener {
//     private static final MBeanNotificationInfo[] NOTIFICATION_INFO;

//     private final QuartzScheduler scheduler;
//     private bool sampledStatisticsEnabled;
//     private SampledStatistics sampledStatistics;

//     private final static SampledStatistics NULL_SAMPLED_STATISTICS = new NullSampledStatisticsImpl();

//     static {
//         final string[] notifTypes = new string[] { SCHEDULER_STARTED,
//                 SCHEDULER_PAUSED, SCHEDULER_SHUTDOWN, };
//         final string name = Notification.class.getName();
//         final string description = "QuartzScheduler JMX Event";
//         NOTIFICATION_INFO = new MBeanNotificationInfo[] { new MBeanNotificationInfo(
//                 notifTypes, name, description), };
//     }

//     /**
//      * emitter
//      */
//     protected final Emitter emitter = new Emitter();

//     /**
//      * sequenceNumber
//      */
//     protected final AtomicLong sequenceNumber = new AtomicLong();

//     /**
//      * QuartzSchedulerMBeanImpl
//      * 
//      * @throws NotCompliantMBeanException
//      */
//     protected QuartzSchedulerMBeanImpl(QuartzScheduler scheduler) {
//         super(QuartzSchedulerMBean.class);
//         this.scheduler = scheduler;
//         this.scheduler.addInternalJobListener(this);
//         this.scheduler.addInternalSchedulerListener(this);
//         this.sampledStatistics = NULL_SAMPLED_STATISTICS;
//         this.sampledStatisticsEnabled = false;
//     }

//     TabularData getCurrentlyExecutingJobs() {
//         try {
//             List!(JobExecutionContext) currentlyExecutingJobs = scheduler.getCurrentlyExecutingJobs();
//             return JobExecutionContextSupport.toTabularData(currentlyExecutingJobs);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     TabularData getAllJobDetails() {
//         try {
//             List!(JobDetail) detailList = new ArrayList!(JobDetail)();
//             for (string jobGroupName : scheduler.getJobGroupNames()) {
//                 for (JobKey jobKey : scheduler.getJobKeys(GroupMatcher.jobGroupEquals(jobGroupName))) {
//                     detailList.add(scheduler.getJobDetail(jobKey));
//                 }
//             }
//             return JobDetailSupport.toTabularData(detailList.toArray(new JobDetail[detailList.size()]));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     List!(CompositeData) getAllTriggers() {
//         try {
//             List!(Trigger) triggerList = new ArrayList!(Trigger)();
//             for (string triggerGroupName : scheduler.getTriggerGroupNames()) {
//                 for (TriggerKey triggerKey : scheduler.getTriggerKeys(GroupMatcher.triggerGroupEquals(triggerGroupName))) {
//                     triggerList.add(scheduler.getTrigger(triggerKey));
//                 }
//             }
//             return TriggerSupport.toCompositeList(triggerList);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void addJob(CompositeData jobDetail, bool replace) {
//         try {
//             scheduler.addJob(JobDetailSupport.newJobDetail(jobDetail), replace);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     private static void invokeSetter(Object target, string attribute, Object value) {
//         string setterName = "set" ~ Character.toUpperCase(attribute.charAt(0)) + attribute.substring(1);
//         TypeInfo_Class[] argTypes = {value.getClass()};
//         Method setter = findMethod(target.getClass(), setterName, argTypes);
//         if(setter !is null) {
//             setter.invoke(target, value);
//         } else {
//             throw new Exception("Unable to find setter for attribute '" ~ attribute
//                     ~ "' and value '" ~ value ~ "'");
//         }
//     }
    
//     private static TypeInfo_Class getWrapperIfPrimitive(TypeInfo_Class c) {
//         TypeInfo_Class result = c;
//         try {
//             Field f = c.getField("TYPE");
//             f.setAccessible(true);
//             result = (TypeInfo_Class) f.get(null);
//         } catch (Exception e) {
//             /**/
//         }
//         return result;
//     }
    
//     private static Method findMethod(TypeInfo_Class targetType, string methodName,
//             TypeInfo_Class[] argTypes) {
//         BeanInfo beanInfo = Introspector.getBeanInfo(targetType);
//         if (beanInfo !is null) {
//             for(MethodDescriptor methodDesc: beanInfo.getMethodDescriptors()) {
//                 Method method = methodDesc.getMethod();
//                 TypeInfo_Class[] parameterTypes = method.getParameterTypes();
//                 if (methodName== method.getName() && argTypes.length == parameterTypes.length) {
//                     bool matchedArgTypes = true;
//                     for (int i = 0; i < argTypes.length; i++) { 
//                         if (getWrapperIfPrimitive(argTypes[i]) != parameterTypes[i]) {
//                             matchedArgTypes = false;
//                             break;
//                         }
//                     }
//                     if (matchedArgTypes) {
//                         return method;
//                     }
//                 }
//             }
//         }
//         return null;
//     }
    
//     void scheduleBasicJob(Map!(string, Object) jobDetailInfo,
//             Map!(string, Object) triggerInfo) {
//         try {
//             JobDetail jobDetail = JobDetailSupport.newJobDetail(jobDetailInfo);
//             OperableTrigger trigger = TriggerSupport.newTrigger(triggerInfo);
//             scheduler.deleteJob(jobDetail.getKey());
//             scheduler.scheduleJob(jobDetail, trigger);
//         } catch (ParseException pe) {
//             throw pe;
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void scheduleJob(Map!(string, Object) abstractJobInfo,
//             Map!(string, Object) abstractTriggerInfo) {
//         try {
//             string triggerClassName = (string) abstractTriggerInfo.remove("triggerClass");
//             if(triggerClassName is null) {
//                 throw new IllegalArgumentException("No triggerClass specified");
//             }
//             TypeInfo_Class triggerClass = Class.forName(triggerClassName);
//             Trigger trigger = (Trigger) triggerClass.newInstance();
            
//             string jobDetailClassName = (string) abstractJobInfo.remove("jobDetailClass");
//             if(jobDetailClassName is null) {
//                 throw new IllegalArgumentException("No jobDetailClass specified");
//             }
//             TypeInfo_Class jobDetailClass = Class.forName(jobDetailClassName);
//             JobDetail jobDetail = (JobDetail) jobDetailClass.newInstance();
            
//             string jobClassName = (string) abstractJobInfo.remove("jobClass");
//             if(jobClassName is null) {
//                 throw new IllegalArgumentException("No jobClass specified");
//             }
//             TypeInfo_Class jobClass = Class.forName(jobClassName);
//             abstractJobInfo.put("jobClass", jobClass);
            
//             for(Map.Entry!(string, Object) entry : abstractTriggerInfo.entrySet()) {
//                 string key = entry.getKey();
//                 Object value = entry.getValue();
//                 if("jobDataMap"== key) {
//                     value = new JobDataMap((Map<?, ?>)value);
//                 }
//                 invokeSetter(trigger, key, value);
//             }
            
//             for(Map.Entry!(string, Object) entry : abstractJobInfo.entrySet()) {
//                 string key = entry.getKey();
//                 Object value = entry.getValue();
//                 if("jobDataMap"== key) {
//                     value = new JobDataMap((Map<?, ?>)value);
//                 }
//                 invokeSetter(jobDetail, key, value);
//             }
    
//             AbstractTrigger<?> at = (AbstractTrigger<?>)trigger;
//             at.setKey(new TriggerKey(at.getName(), at.getGroup()));
            
//             Date startDate = at.getStartTime();
//             if(startDate is null || startDate.before(new Date())) {
//                 at.setStartTime(new Date());
//             }
            
//             scheduler.deleteJob(jobDetail.getKey());
//             scheduler.scheduleJob(jobDetail, trigger);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }
    
//     void scheduleJob(string jobName, string jobGroup,
//             Map!(string, Object) abstractTriggerInfo) {
//         try {
//             JobKey jobKey = new JobKey(jobName, jobGroup);
//             JobDetail jobDetail = scheduler.getJobDetail(jobKey);
//             if(jobDetail is null) {
//                 throw new IllegalArgumentException("No such job '" ~ jobKey ~ "'");
//             }
            
//             string triggerClassName = (string) abstractTriggerInfo.remove("triggerClass");
//             if(triggerClassName is null) {
//                 throw new IllegalArgumentException("No triggerClass specified");
//             }
//             TypeInfo_Class triggerClass = Class.forName(triggerClassName);
//             Trigger trigger = (Trigger) triggerClass.newInstance();
            
//             for(Map.Entry!(string, Object) entry : abstractTriggerInfo.entrySet()) {
//                 string key = entry.getKey();
//                 Object value = entry.getValue();
//                 if("jobDataMap"== key) {
//                     value = new JobDataMap((Map<?, ?>)value);
//                 }
//                 invokeSetter(trigger, key, value);
//             }
            
//             AbstractTrigger<?> at = (AbstractTrigger<?>)trigger;
//             at.setKey(new TriggerKey(at.getName(), at.getGroup()));
            
//             Date startDate = at.getStartTime();
//             if(startDate is null || startDate.before(new Date())) {
//                 at.setStartTime(new Date());
//             }
            
//             scheduler.scheduleJob(trigger);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }
    
//     void addJob(Map!(string, Object) abstractJobInfo,    bool replace) {
//         try {
//             string jobDetailClassName = (string) abstractJobInfo.remove("jobDetailClass");
//             if(jobDetailClassName is null) {
//                 throw new IllegalArgumentException("No jobDetailClass specified");
//             }
//             TypeInfo_Class jobDetailClass = Class.forName(jobDetailClassName);
//             JobDetail jobDetail = (JobDetail) jobDetailClass.newInstance();
            
//             string jobClassName = (string) abstractJobInfo.remove("jobClass");
//             if(jobClassName is null) {
//                 throw new IllegalArgumentException("No jobClass specified");
//             }
//             TypeInfo_Class jobClass = Class.forName(jobClassName);
//             abstractJobInfo.put("jobClass", jobClass);
            
//             for(Map.Entry!(string, Object) entry : abstractJobInfo.entrySet()) {
//                 string key = entry.getKey();
//                 Object value = entry.getValue();
//                 if("jobDataMap"== key) {
//                     value = new JobDataMap((Map<?, ?>)value);
//                 }
//                 invokeSetter(jobDetail, key, value);
//             }
    
//             scheduler.addJob(jobDetail, replace);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }
    
//     private Exception newPlainException(Exception e) {
//         string type = e.getClass().getName();
//         if(type.startsWith("java.") || type.startsWith("javax.")) {
//             return e;
//         } else {
//             Exception result = new Exception(e.getMessage());
//             result.setStackTrace(e.getStackTrace());
//             return result;
//         }
//     }
    
//     void deleteCalendar(string calendarName) {
//         try {
//             scheduler.deleteCalendar(calendarName);
//         } catch(Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     bool deleteJob(string jobName, string jobGroupName) {
//         try {
//             return scheduler.deleteJob(jobKey(jobName, jobGroupName));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     List!(string) getCalendarNames() {
//         try {
//             return scheduler.getCalendarNames();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     CompositeData getJobDetail(string jobName, string jobGroupName) {
//         try {
//             JobDetail jobDetail = scheduler.getJobDetail(jobKey(jobName, jobGroupName));
//             return JobDetailSupport.toCompositeData(jobDetail);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     List!(string) getJobGroupNames() {
//         try {
//             return scheduler.getJobGroupNames();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     List!(string) getJobNames(string groupName) {
//         try {
//             List!(string) jobNames = new ArrayList!(string)();
//             for(JobKey key: scheduler.getJobKeys(GroupMatcher.jobGroupEquals(groupName))) {
//                 jobNames.add(key.getName());
//             }
//             return jobNames;
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     string getJobStoreClassName() {
//         return scheduler.getJobStoreClass().getName();
//     }

//     Set!(string) getPausedTriggerGroups() {
//         try {
//             return scheduler.getPausedTriggerGroups();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     CompositeData getTrigger(string name, string groupName) {
//         try {
//             Trigger trigger = scheduler.getTrigger(triggerKey(name, groupName));
//             return TriggerSupport.toCompositeData(trigger);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     List!(string) getTriggerGroupNames() {
//         try {
//             return scheduler.getTriggerGroupNames();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     List!(string) getTriggerNames(string groupName) {
//         try {
//             List!(string) triggerNames = new ArrayList!(string)();
//             for(TriggerKey key: scheduler.getTriggerKeys(GroupMatcher.triggerGroupEquals(groupName))) {
//                 triggerNames.add(key.getName());
//             }
//             return triggerNames;
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     string getTriggerState(string triggerName, string triggerGroupName) {
//         try {
//             TriggerKey triggerKey = triggerKey(triggerName, triggerGroupName);
//             TriggerState ts = scheduler.getTriggerState(triggerKey);
//             return ts.name();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     List!(CompositeData) getTriggersOfJob(string jobName, string jobGroupName) {
//         try {
//             JobKey jobKey = jobKey(jobName, jobGroupName);
//             return TriggerSupport.toCompositeList(scheduler.getTriggersOfJob(jobKey));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     bool interruptJob(string jobName, string jobGroupName) {
//         try {
//             return scheduler.interrupt(jobKey(jobName, jobGroupName));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     bool interruptJob(string fireInstanceId) {
//         try {
//             return scheduler.interrupt(fireInstanceId);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     Date scheduleJob(string jobName, string jobGroup,
//             string triggerName, string triggerGroup) {
//         try {
//             JobKey jobKey = jobKey(jobName, jobGroup);
//             JobDetail jobDetail = scheduler.getJobDetail(jobKey);
//             if (jobDetail is null) {
//                 throw new IllegalArgumentException("No such job: " ~ jobKey);
//             }
//             TriggerKey triggerKey = triggerKey(triggerName, triggerGroup);
//             Trigger trigger = scheduler.getTrigger(triggerKey);
//             if (trigger is null) {
//                 throw new IllegalArgumentException("No such trigger: " ~ triggerKey);
//             }
//             return scheduler.scheduleJob(jobDetail, trigger);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     bool unscheduleJob(string triggerName, string triggerGroup) {
//         try {
//             return scheduler.unscheduleJob(triggerKey(triggerName, triggerGroup));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//    void clear() {
//        try {
//            scheduler.clear();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     string getVersion() {
//         return scheduler.getVersion();
//     }

//     bool isShutdown() {
//         return scheduler.isShutdown();
//     }

//     bool isStarted() {
//         return scheduler.isStarted();
//     }

//     void start() {
//         try {
//             scheduler.start();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void shutdown() {
//         scheduler.shutdown();
//     }

//     void standby() {
//         scheduler.standby();
//     }

//     bool isStandbyMode() {
//         return scheduler.isInStandbyMode();
//     }

//     string getSchedulerName() {
//         return scheduler.getSchedulerName();
//     }

//     string getSchedulerInstanceId() {
//         return scheduler.getSchedulerInstanceId();
//     }

//     string getThreadPoolClassName() {
//         return scheduler.getThreadPoolClass().getName();
//     }

//     int getThreadPoolSize() {
//         return scheduler.getThreadPoolSize();
//     }

//     void pauseJob(string jobName, string jobGroup) {
//         try {
//             scheduler.pauseJob(jobKey(jobName, jobGroup));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void pauseJobs(GroupMatcher!(JobKey) matcher) {
//         try {
//             scheduler.pauseJobs(matcher);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }
    
//     void pauseJobGroup(string jobGroup) {
//         pauseJobs(GroupMatcher.<JobKey>groupEquals(jobGroup));
//     }

//     void pauseJobsStartingWith(string jobGroupPrefix) {
//         pauseJobs(GroupMatcher.<JobKey>groupStartsWith(jobGroupPrefix));
//     }

//     void pauseJobsEndingWith(string jobGroupSuffix) {
//         pauseJobs(GroupMatcher.<JobKey>groupEndsWith(jobGroupSuffix));
//     }

//     void pauseJobsContaining(string jobGroupToken) {
//         pauseJobs(GroupMatcher.<JobKey>groupContains(jobGroupToken));
//     }

//     void pauseJobsAll() {
//         pauseJobs(GroupMatcher.anyJobGroup());
//     }

//     void pauseAllTriggers() {
//         try {
//             scheduler.pauseAll();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     private void pauseTriggers(GroupMatcher!(TriggerKey) matcher) {
//         try {
//             scheduler.pauseTriggers(matcher);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }
    
//     void pauseTriggerGroup(string triggerGroup) {
//         pauseTriggers(GroupMatcher.<TriggerKey>groupEquals(triggerGroup));
//     }

//     void pauseTriggersStartingWith(string triggerGroupPrefix) {
//         pauseTriggers(GroupMatcher.<TriggerKey>groupStartsWith(triggerGroupPrefix));
//     }

//     void pauseTriggersEndingWith(string triggerGroupSuffix) {
//         pauseTriggers(GroupMatcher.<TriggerKey>groupEndsWith(triggerGroupSuffix));
//     }

//     void pauseTriggersContaining(string triggerGroupToken) {
//         pauseTriggers(GroupMatcher.<TriggerKey>groupContains(triggerGroupToken));
//     }

//     void pauseTriggersAll() {
//         pauseTriggers(GroupMatcher.anyTriggerGroup());
//     }

//     void pauseTrigger(string triggerName, string triggerGroup) {
//         try {
//             scheduler.pauseTrigger(triggerKey(triggerName, triggerGroup));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void resumeAllTriggers() {
//         try {
//             scheduler.resumeAll();
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void resumeJob(string jobName, string jobGroup) {
//         try {
//             scheduler.resumeJob(jobKey(jobName, jobGroup));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void resumeJobs(GroupMatcher!(JobKey) matcher) {
//         try {
//             scheduler.resumeJobs(matcher);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void resumeJobGroup(string jobGroup) {
//         resumeJobs(GroupMatcher.<JobKey>groupEquals(jobGroup));
//     }

//     void resumeJobsStartingWith(string jobGroupPrefix) {
//         resumeJobs(GroupMatcher.<JobKey>groupStartsWith(jobGroupPrefix));
//     }

//     void resumeJobsEndingWith(string jobGroupSuffix) {
//         resumeJobs(GroupMatcher.<JobKey>groupEndsWith(jobGroupSuffix));
//     }

//     void resumeJobsContaining(string jobGroupToken) {
//         resumeJobs(GroupMatcher.<JobKey>groupContains(jobGroupToken));
//     }

//     void resumeJobsAll() {
//         resumeJobs(GroupMatcher.anyJobGroup());
//     }

//     void resumeTrigger(string triggerName, string triggerGroup) {
//         try {
//             scheduler.resumeTrigger(triggerKey(triggerName, triggerGroup));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     private void resumeTriggers(GroupMatcher!(TriggerKey) matcher) {
//         try {
//             scheduler.resumeTriggers(matcher);
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }
    
//     void resumeTriggerGroup(string triggerGroup) {
//         resumeTriggers(GroupMatcher.<TriggerKey>groupEquals(triggerGroup));
//     }

//     void resumeTriggersStartingWith(string triggerGroupPrefix) {
//         resumeTriggers(GroupMatcher.<TriggerKey>groupStartsWith(triggerGroupPrefix));
//     }

//     void resumeTriggersEndingWith(string triggerGroupSuffix) {
//         resumeTriggers(GroupMatcher.<TriggerKey>groupEndsWith(triggerGroupSuffix));
//     }

//     void resumeTriggersContaining(string triggerGroupToken) {
//         resumeTriggers(GroupMatcher.<TriggerKey>groupContains(triggerGroupToken));
//     }

//     void resumeTriggersAll() {
//         resumeTriggers(GroupMatcher.anyTriggerGroup());
//     }

//     void triggerJob(string jobName, string jobGroup, Map!(string, string) jobDataMap) {
//         try {
//             scheduler.triggerJob(jobKey(jobName, jobGroup), new JobDataMap(jobDataMap));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }

//     void triggerJob(CompositeData trigger) {
//         try {
//             scheduler.triggerJob(TriggerSupport.newTrigger(trigger));
//         } catch (Exception e) {
//             throw newPlainException(e);
//         }
//     }
    
//     // ScheduleListener

//     void jobAdded(JobDetail jobDetail) {
//         sendNotification(JOB_ADDED, JobDetailSupport.toCompositeData(jobDetail));
//     }

//     void jobDeleted(JobKey jobKey) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("jobName", jobKey.getName());
//         map.put("jobGroup", jobKey.getGroup());
//         sendNotification(JOB_DELETED, map);
//     }

//     void jobScheduled(Trigger trigger) {
//         sendNotification(JOB_SCHEDULED, TriggerSupport.toCompositeData(trigger));
//     }

//     void jobUnscheduled(TriggerKey triggerKey) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("triggerName", triggerKey.getName());
//         map.put("triggerGroup", triggerKey.getGroup());
//         sendNotification(JOB_UNSCHEDULED, map);
//     }
    
//     void schedulingDataCleared() {
//         sendNotification(SCHEDULING_DATA_CLEARED);
//     }
    
//     void jobPaused(JobKey jobKey) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("jobName", jobKey.getName());
//         map.put("jobGroup", jobKey.getGroup());
//         sendNotification(JOBS_PAUSED, map);
//     }

//     void jobsPaused(string jobGroup) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("jobName", null);
//         map.put("jobGroup", jobGroup);
//         sendNotification(JOBS_PAUSED, map);
//     }
    
//     void jobsResumed(string jobGroup) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("jobName", null);
//         map.put("jobGroup", jobGroup);
//         sendNotification(JOBS_RESUMED, map);
//     }

//     void jobResumed(JobKey jobKey) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("jobName", jobKey.getName());
//         map.put("jobGroup", jobKey.getGroup());
//         sendNotification(JOBS_RESUMED, map);
//     }
    
//     void schedulerError(string msg, SchedulerException cause) {
//         sendNotification(SCHEDULER_ERROR, cause.getMessage());
//     }

//     void schedulerStarted() {
//         sendNotification(SCHEDULER_STARTED);
//     }
    
//     //not doing anything, just like schedulerShuttingdown
//     void schedulerStarting() {
//     }

//     void schedulerInStandbyMode() {
//         sendNotification(SCHEDULER_PAUSED);
//     }

//     void schedulerShutdown() {
//         scheduler.removeInternalSchedulerListener(this);
//         scheduler.removeInternalJobListener(getName());

//         sendNotification(SCHEDULER_SHUTDOWN);
//     }

//     void schedulerShuttingdown() {
//     }

//     void triggerFinalized(Trigger trigger) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("triggerName", trigger.getKey().getName());
//         map.put("triggerGroup", trigger.getKey().getGroup());
//         sendNotification(TRIGGER_FINALIZED, map);
//     }

//     void triggersPaused(string triggerGroup) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("triggerName", null);
//         map.put("triggerGroup", triggerGroup);
//         sendNotification(TRIGGERS_PAUSED, map);
//     }

//     void triggerPaused(TriggerKey triggerKey) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         if(triggerKey !is null) {
//             map.put("triggerName", triggerKey.getName());
//             map.put("triggerGroup", triggerKey.getGroup());
//         }
//         sendNotification(TRIGGERS_PAUSED, map);
//     }

//     void triggersResumed(string triggerGroup) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         map.put("triggerName", null);
//         map.put("triggerGroup", triggerGroup);
//         sendNotification(TRIGGERS_RESUMED, map);
//     }

//     void triggerResumed(TriggerKey triggerKey) {
//         Map!(string, string) map = new HashMap!(string, string)();
//         if(triggerKey !is null) {
//             map.put("triggerName", triggerKey.getName());
//             map.put("triggerGroup", triggerKey.getGroup());
//         }
//         sendNotification(TRIGGERS_RESUMED, map);
//     }
    
//     // JobListener

//     string getName() {
//         return "QuartzSchedulerMBeanImpl.listener";
//     }

//     void jobExecutionVetoed(JobExecutionContext context) {
//         try {
//             sendNotification(JOB_EXECUTION_VETOED, JobExecutionContextSupport
//                     .toCompositeData(context));
//         } catch (Exception e) {
//             throw new RuntimeException(newPlainException(e));
//         }
//     }

//     void jobToBeExecuted(JobExecutionContext context) {
//         try {
//             sendNotification(JOB_TO_BE_EXECUTED, JobExecutionContextSupport
//                     .toCompositeData(context));
//         } catch (Exception e) {
//             throw new RuntimeException(newPlainException(e));
//         }
//     }

//     void jobWasExecuted(JobExecutionContext context,
//             JobExecutionException jobException) {
//         try {
//             sendNotification(JOB_WAS_EXECUTED, JobExecutionContextSupport
//                     .toCompositeData(context));
//         } catch (Exception e) {
//             throw new RuntimeException(newPlainException(e));
//         }
//     }

//     // NotificationBroadcaster

//     /**
//      * sendNotification
//      * 
//      * @param eventType
//      */
//     void sendNotification(string eventType) {
//         sendNotification(eventType, null, null);
//     }

//     /**
//      * sendNotification
//      * 
//      * @param eventType
//      * @param data
//      */
//     void sendNotification(string eventType, Object data) {
//         sendNotification(eventType, data, null);
//     }

//     /**
//      * sendNotification
//      * 
//      * @param eventType
//      * @param data
//      * @param msg
//      */
//     void sendNotification(string eventType, Object data, string msg) {
//         Notification notif = new Notification(eventType, this, sequenceNumber
//                 .incrementAndGet(), DateTimeHelper.currentTimeMillis(), msg);
//         if (data !is null) {
//             notif.setUserData(data);
//         }
//         emitter.sendNotification(notif);
//     }

//     /**
//      * @author gkeim
//      */
//     private class Emitter : NotificationBroadcasterSupport {
//         /**
//          * @see javax.management.NotificationBroadcasterSupport#getNotificationInfo()
//          */
//         override
//         MBeanNotificationInfo[] getNotificationInfo() {
//             return QuartzSchedulerMBeanImpl.this.getNotificationInfo();
//         }
//     }

//     /**
//      * @see javax.management.NotificationBroadcaster#addNotificationListener(javax.management.NotificationListener,
//      *      javax.management.NotificationFilter, java.lang.Object)
//      */
//     void addNotificationListener(NotificationListener notif,
//             NotificationFilter filter, Object callBack) {
//         emitter.addNotificationListener(notif, filter, callBack);
//     }

//     /**
//      * @see javax.management.NotificationBroadcaster#getNotificationInfo()
//      */
//     MBeanNotificationInfo[] getNotificationInfo() {
//         return NOTIFICATION_INFO;
//     }

//     /**
//      * @see javax.management.NotificationBroadcaster#removeNotificationListener(javax.management.NotificationListener)
//      */
//     void removeNotificationListener(NotificationListener listener) {
//         emitter.removeNotificationListener(listener);
//     }

//     /**
//      * @see javax.management.NotificationEmitter#removeNotificationListener(javax.management.NotificationListener,
//      *      javax.management.NotificationFilter, java.lang.Object)
//      */
//     void removeNotificationListener(NotificationListener notif,
//             NotificationFilter filter, Object callBack) {
//         emitter.removeNotificationListener(notif, filter, callBack);
//     }

//     synchronized bool isSampledStatisticsEnabled() {
//         return sampledStatisticsEnabled;
//     }

//     void setSampledStatisticsEnabled(bool enabled) {
//         if (enabled != this.sampledStatisticsEnabled) {
//             this.sampledStatisticsEnabled = enabled;
//             if(enabled) {
//                 this.sampledStatistics = new SampledStatisticsImpl(scheduler);
//             }
//             else {
//                  this.sampledStatistics.shutdown(); 
//                  this.sampledStatistics = NULL_SAMPLED_STATISTICS;
//             }
//             sendNotification(SAMPLED_STATISTICS_ENABLED, Boolean.valueOf(enabled));
//         }
//     }

//     long getJobsCompletedMostRecentSample() {
//         return this.sampledStatistics.getJobsCompletedMostRecentSample();
//     }

//     long getJobsExecutedMostRecentSample() {
//         return this.sampledStatistics.getJobsExecutingMostRecentSample();
//     }

//     long getJobsScheduledMostRecentSample() {
//         return this.sampledStatistics.getJobsScheduledMostRecentSample();
//     }

//     Map!(string, Long) getPerformanceMetrics() {
//         Map!(string, Long) result = new HashMap!(string, Long)();
//         result.put("JobsCompleted", Long
//                 .valueOf(getJobsCompletedMostRecentSample()));
//         result.put("JobsExecuted", Long
//                 .valueOf(getJobsExecutedMostRecentSample()));
//         result.put("JobsScheduled", Long
//                 .valueOf(getJobsScheduledMostRecentSample()));
//         return result;
//     }
// }
