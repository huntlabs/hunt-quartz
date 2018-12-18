module hunt.quartz.core.jmx.JobExecutionContextSupport;

// import static javax.management.openmbean.SimpleType.BOOLEAN;
// import static javax.management.openmbean.SimpleType.DATE;
// import static javax.management.openmbean.SimpleType.INTEGER;
// import static javax.management.openmbean.SimpleType.LONG;
// import static javax.management.openmbean.SimpleType.STRING;

// import hunt.container.ArrayList;
// import hunt.container.List;

// import javax.management.openmbean.CompositeData;
// import javax.management.openmbean.CompositeDataSupport;
// import javax.management.openmbean.CompositeType;
// import javax.management.openmbean.OpenDataException;
// import javax.management.openmbean.OpenType;
// import javax.management.openmbean.TabularData;
// import javax.management.openmbean.TabularDataSupport;
// import javax.management.openmbean.TabularType;

// import hunt.quartz.JobExecutionContext;
// import hunt.quartz.SchedulerException;

// class JobExecutionContextSupport {
//     private enum string COMPOSITE_TYPE_NAME = "JobExecutionContext";
//     private enum string COMPOSITE_TYPE_DESCRIPTION = "Job Execution Instance Details";
//     private enum string[] ITEM_NAMES = new string[] { "schedulerName",
//             "triggerName", "triggerGroup", "jobName", "jobGroup", "jobDataMap",
//             "calendarName", "recovering", "refireCount", "fireTime",
//             "scheduledFireTime", "previousFireTime", "nextFireTime",
//             "jobRunTime", "fireInstanceId" };
//     private enum string[] ITEM_DESCRIPTIONS = new string[] {
//             "schedulerName", "triggerName", "triggerGroup", "jobName",
//             "jobGroup", "jobDataMap", "calendarName", "recovering",
//             "refireCount", "fireTime", "scheduledFireTime", "previousFireTime",
//             "nextFireTime", "jobRunTime", "fireInstanceId" };
//     private static final OpenType[] ITEM_TYPES = new OpenType[] { STRING,
//             STRING, STRING, STRING, STRING, JobDataMapSupport.TABULAR_TYPE,
//             STRING, BOOLEAN, INTEGER, DATE, DATE, DATE, DATE, LONG, STRING };
//     private static final CompositeType COMPOSITE_TYPE;
//     private enum string TABULAR_TYPE_NAME = "JobExecutionContextArray";
//     private enum string TABULAR_TYPE_DESCRIPTION = "Array of composite JobExecutionContext";
//     private enum string[] INDEX_NAMES = new string[] { "schedulerName",
//             "triggerName", "triggerGroup", "jobName", "jobGroup", "fireTime" };
//     private static final TabularType TABULAR_TYPE;

//     static {
//         try {
//             COMPOSITE_TYPE = new CompositeType(COMPOSITE_TYPE_NAME,
//                     COMPOSITE_TYPE_DESCRIPTION, ITEM_NAMES, ITEM_DESCRIPTIONS,
//                     ITEM_TYPES);
//             TABULAR_TYPE = new TabularType(TABULAR_TYPE_NAME,
//                     TABULAR_TYPE_DESCRIPTION, COMPOSITE_TYPE, INDEX_NAMES);
//         } catch (OpenDataException e) {
//             throw new RuntimeException(e);
//         }
//     }

//     /**
//      * @return composite data
//      */
//     static CompositeData toCompositeData(JobExecutionContext jec)
// {
//         try {
//             return new CompositeDataSupport(COMPOSITE_TYPE, ITEM_NAMES,
//                     new Object[] {
//                             jec.getScheduler().getSchedulerName(),
//                             jec.getTrigger().getKey().getName(),
//                             jec.getTrigger().getKey().getGroup(),
//                             jec.getJobDetail().getKey().getName(),
//                             jec.getJobDetail().getKey().getGroup(),
//                             JobDataMapSupport.toTabularData(jec
//                                     .getMergedJobDataMap()),
//                             jec.getTrigger().getCalendarName(),
//                             jec.isRecovering(),
//                             jec.getRefireCount(),
//                             jec.getFireTime(), jec.getScheduledFireTime(),
//                             jec.getPreviousFireTime(), jec.getNextFireTime(),
//                             jec.getJobRunTime(),
//                             jec.getFireInstanceId() });
//         } catch (OpenDataException e) {
//             throw new RuntimeException(e);
//         }
//     }

//     /**
//      * @return array of region statistics
//      */
//     static TabularData toTabularData(
//             final List!(JobExecutionContext) executingJobs)
// {
//         List!(CompositeData) list = new ArrayList!(CompositeData)();
//         foreach(JobExecutionContext executingJob ; executingJobs) {
//             list.add(toCompositeData(executingJob));
//         }
//         TabularData td = new TabularDataSupport(TABULAR_TYPE);
//         td.putAll(list.toArray(new CompositeData[list.size()]));
//         return td;
//     }
// }
