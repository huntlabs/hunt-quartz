module hunt.quartz.core.jmx.TriggerSupport;

// import static javax.management.openmbean.SimpleType.DATE;
// import static javax.management.openmbean.SimpleType.INTEGER;
// import static javax.management.openmbean.SimpleType.STRING;

// import hunt.Exceptions;
// import hunt.collection.ArrayList;
// import std.datetime;
// import hunt.collection.List;
// import hunt.collection.Map;

// import javax.management.openmbean.CompositeData;
// import javax.management.openmbean.CompositeDataSupport;
// import javax.management.openmbean.CompositeType;
// import javax.management.openmbean.OpenDataException;
// import javax.management.openmbean.OpenType;
// import javax.management.openmbean.TabularData;
// import javax.management.openmbean.TabularDataSupport;
// import javax.management.openmbean.TabularType;

// import hunt.quartz.JobKey;
// import hunt.quartz.Trigger;
// import hunt.quartz.TriggerKey;
// import hunt.quartz.spi.MutableTrigger;
// import hunt.quartz.spi.OperableTrigger;

// class TriggerSupport {
//     private enum string COMPOSITE_TYPE_NAME = "Trigger";
//     private enum string COMPOSITE_TYPE_DESCRIPTION = "Trigger Details";
//     private enum string[] ITEM_NAMES = new string[] { "name",
//       "group", "jobName", "jobGroup", "description", "jobDataMap",
//             "calendarName", "fireInstanceId", "misfireInstruction", "priority",
//             "startTime", "endTime", "nextFireTime", "previousFireTime", "finalFireTime" };
//     private enum string[] ITEM_DESCRIPTIONS = new string[] { "name",
//             "group", "jobName", "jobGroup", "description", "jobDataMap",
//             "calendarName", "fireInstanceId", "misfireInstruction", "priority",
//       "startTime", "endTime", "nextFireTime", "previousFireTime", "finalFireTime" };
//     private static final OpenType[] ITEM_TYPES = new OpenType[] { STRING,
//             STRING, STRING, STRING, STRING, JobDataMapSupport.TABULAR_TYPE,
//             STRING, STRING, INTEGER, INTEGER,
//       DATE, DATE, DATE, DATE, DATE };
//     private static final CompositeType COMPOSITE_TYPE;
//     private enum string TABULAR_TYPE_NAME = "Trigger collection";
//     private enum string TABULAR_TYPE_DESCRIPTION = "Trigger collection";
//     private enum string[] INDEX_NAMES = new string[] { "name", "group" };
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
    
//     static string[] getItemNames() {
//         return ITEM_NAMES;
//     }

//     static string[] getItemDescriptions() {
//         return ITEM_DESCRIPTIONS;
//     }
    
//     static OpenType[] getItemTypes() {
//         return ITEM_TYPES;
//     }
    
//     string[] getIndexNames() {
//         return INDEX_NAMES;
//     }
    
//     static CompositeData toCompositeData(Trigger trigger) {
//         try {
//             return new CompositeDataSupport(COMPOSITE_TYPE, ITEM_NAMES,
//                     new Object[] {
//                             trigger.getKey().getName(),
//                             trigger.getKey().getGroup(),
//                             trigger.getJobKey().getName(),
//                             trigger.getJobKey().getGroup(),
//                             trigger.getDescription(),
//                             JobDataMapSupport.toTabularData(trigger
//                                     .getJobDataMap()),
//                             trigger.getCalendarName(),
//                             ((OperableTrigger)trigger).getFireInstanceId(),
//                             trigger.getMisfireInstruction(),
//                             trigger.getPriority(), trigger.getStartTime(),
//                             trigger.getEndTime(), trigger.getNextFireTime(),
//                             trigger.getPreviousFireTime(),
//                             trigger.getFinalFireTime() });
//         } catch (OpenDataException e) {
//             throw new RuntimeException(e);
//         }
//     }

//     static TabularData toTabularData(List!(Trigger) triggers) {
//         TabularData tData = new TabularDataSupport(TABULAR_TYPE);
//         if (triggers !is null) {
//             ArrayList!(CompositeData) list = new ArrayList!(CompositeData)();
//             foreach(Trigger trigger ; triggers) {
//                 list.add(toCompositeData(trigger));
//             }
//             tData.putAll(list.toArray(new CompositeData[list.size()]));
//         }
//         return tData;
//     }
    
//     static List!(CompositeData) toCompositeList(List!(Trigger) triggers) {
//         List!(CompositeData) result = new ArrayList!(CompositeData)();
//         foreach(Trigger trigger ; triggers) {
//             CompositeData cData = TriggerSupport.toCompositeData(trigger);
//             if(cData !is null) {
//                 result.add(cData);
//             }
//         }
//         return result;
//     }
    
//     static void initializeTrigger(MutableTrigger trigger, CompositeData cData) {
//         trigger.setDescription((string) cData.get("description"));
//         trigger.setCalendarName((string) cData.get("calendarName"));
//         if(cData.containsKey("priority")) {
//             trigger.setPriority(((Integer)cData.get("priority")).intValue());
//         }
//         if(cData.containsKey("jobDataMap")) {
//             trigger.setJobDataMap(JobDataMapSupport.newJobDataMap((TabularData)cData.get("jobDataMap")));
//         }
//         LocalDateTime startTime;
//         if(cData.containsKey("startTime")) {
//             startTime = (LocalDateTime) cData.get("startTime");
//         } else {
//             startTime = new LocalDateTime();
//         }
//         trigger.setStartTime(startTime);
//         trigger.setEndTime((LocalDateTime) cData.get("endTime"));
//         if(cData.containsKey("misfireInstruction")) {
//             trigger.setMisfireInstruction(((Integer)cData.get("misfireInstruction")).intValue());
//         }
//         trigger.setKey(new TriggerKey((string) cData.get("name"), (string) cData.get("group")));
//         trigger.setJobKey(new JobKey((string) cData.get("jobName"), (string) cData.get("jobGroup")));
//     }
    
//     static void initializeTrigger(MutableTrigger trigger, Map!(string, Object) attrMap) {
//         trigger.setDescription((string) attrMap.get("description"));
//         trigger.setCalendarName((string) attrMap.get("calendarName"));
//         if(attrMap.containsKey("priority")) {
//             trigger.setPriority(((Integer)attrMap.get("priority")).intValue());
//         }
//         if(attrMap.containsKey("jobDataMap")) {
//              // cast as expected.
//             Map!(string, Object) mapTyped = (Map!(string, Object))attrMap.get("jobDataMap");
//             trigger.setJobDataMap(JobDataMapSupport.newJobDataMap(mapTyped));
//         }
//         LocalDateTime startTime;
//         if(attrMap.containsKey("startTime")) {
//             startTime = (LocalDateTime) attrMap.get("startTime");
//         } else {
//             startTime = new LocalDateTime();
//         }
//         trigger.setStartTime(startTime);
//         if(attrMap.containsKey("endTime")) {
//             trigger.setEndTime((LocalDateTime) attrMap.get("endTime"));
//         }
//         if(attrMap.containsKey("misfireInstruction")) {
//             trigger.setMisfireInstruction(((Integer)attrMap.get("misfireInstruction")).intValue());
//         }
//         trigger.setKey(new TriggerKey((string) attrMap.get("name"), (string) attrMap.get("group")));
//         trigger.setJobKey(new JobKey((string) attrMap.get("jobName"), (string) attrMap.get("jobGroup")));
//     }
    
//     static OperableTrigger newTrigger(CompositeData cData) {
//         OperableTrigger result = null;
//         if(cData.containsKey("cronExpression")) {
//             result = CronTriggerSupport.newTrigger(cData);
//         } else {
//             result = SimpleTriggerSupport.newTrigger(cData);
//         }
//         return result;
//     }
    
//     static OperableTrigger newTrigger(Map!(string, Object) attrMap) {
//         OperableTrigger result = null;
//         if(attrMap.containsKey("cronExpression")) {
//             result = CronTriggerSupport.newTrigger(attrMap);
//         } else {
//             result = SimpleTriggerSupport.newTrigger(attrMap);
//         }
//         return result;
//     }
    
// }
