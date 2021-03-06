module hunt.quartz.core.jmx.CronTriggerSupport;

// import static javax.management.openmbean.SimpleType.STRING;

// import hunt.Exceptions;
// import hunt.collection.ArrayList;
// import java.util.Arrays;
// import hunt.collection.List;
// import hunt.collection.Map;
// import std.datetime : TimeZone;

// // import javax.management.openmbean.CompositeData;
// // import javax.management.openmbean.CompositeDataSupport;
// // import javax.management.openmbean.CompositeType;
// // import javax.management.openmbean.OpenDataException;
// // import javax.management.openmbean.OpenType;
// // import javax.management.openmbean.TabularData;
// // import javax.management.openmbean.TabularDataSupport;
// // import javax.management.openmbean.TabularType;

// import hunt.quartz.CronTrigger;
// import hunt.quartz.impl.triggers.CronTriggerImpl;
// import hunt.quartz.spi.OperableTrigger;

// class CronTriggerSupport {
//     private enum string COMPOSITE_TYPE_NAME = "CronTrigger";
//     private enum string COMPOSITE_TYPE_DESCRIPTION = "CronTrigger Details";
//     private enum string[] ITEM_NAMES = ["expression", "timeZone"];
//     private enum string[] ITEM_DESCRIPTIONS = ["expression", "timeZone"];
//     private enum OpenType[] ITEM_TYPES = [STRING, STRING];
//     private __gshared CompositeType COMPOSITE_TYPE;
//     private enum string TABULAR_TYPE_NAME = "CronTrigger collection";
//     private enum string TABULAR_TYPE_DESCRIPTION = "CronTrigger collection";
//     private __gshared TabularType TABULAR_TYPE;

//     shared static this() {
//         try {
//             COMPOSITE_TYPE = new CompositeType(COMPOSITE_TYPE_NAME,
//                     COMPOSITE_TYPE_DESCRIPTION, getItemNames(), getItemDescriptions(),
//                     getItemTypes());
//             TABULAR_TYPE = new TabularType(TABULAR_TYPE_NAME,
//                     TABULAR_TYPE_DESCRIPTION, COMPOSITE_TYPE, getItemNames());
//         } catch (OpenDataException e) {
//             throw new RuntimeException(e);
//         }
//     }
    
//     static string[] getItemNames() {
//         List!(string) l = new ArrayList!(string)(Arrays.asList(ITEM_NAMES));
//         l.addAll(Arrays.asList(TriggerSupport.getItemNames()));
//         return l.toArray(new string[l.size()]);
//     }

//     static string[] getItemDescriptions() {
//         List!(string) l = new ArrayList!(string)(Arrays.asList(ITEM_DESCRIPTIONS));
//         l.addAll(Arrays.asList(TriggerSupport.getItemDescriptions()));
//         return l.toArray(new string[l.size()]);
//     }
    
//     static OpenType[] getItemTypes() {
//         List!(OpenType) l = new ArrayList!(OpenType)(Arrays.asList(ITEM_TYPES));
//         l.addAll(Arrays.asList(TriggerSupport.getItemTypes()));
//         return l.toArray(new OpenType[l.size()]);
//     }
    
//     static CompositeData toCompositeData(CronTrigger trigger) {
//         try {
//             return new CompositeDataSupport(COMPOSITE_TYPE, ITEM_NAMES,
//                     new Object[] {
//                             trigger.getCronExpression(),
//                             trigger.getTimeZone(),
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

//     static TabularData toTabularData(List<? extends CronTrigger> triggers) {
//         TabularData tData = new TabularDataSupport(TABULAR_TYPE);
//         if (triggers !is null) {
//             ArrayList!(CompositeData) list = new ArrayList!(CompositeData)();
//             foreach(CronTrigger trigger ; triggers) {
//                 list.add(toCompositeData(trigger));
//             }
//             tData.putAll(list.toArray(new CompositeData[list.size()]));
//         }
//         return tData;
//     }
    
//     static OperableTrigger newTrigger(CompositeData cData) {
//         CronTriggerImpl result = new CronTriggerImpl();
//         result.setCronExpression((string) cData.get("cronExpression"));
//         if(cData.containsKey("timeZone")) {
//             result.setTimeZone(TimeZone.getTimeZone((string)cData.get("timeZone")));
//         }
//         TriggerSupport.initializeTrigger(result, cData);
//         return result;
//     }

//     static OperableTrigger newTrigger(Map!(string, Object) attrMap) {
//         CronTriggerImpl result = new CronTriggerImpl();
//         result.setCronExpression((string) attrMap.get("cronExpression"));
//         if(attrMap.containsKey("timeZone")) {
//             result.setTimeZone(TimeZone.getTimeZone((string)attrMap.get("timeZone")));
//         }
//         TriggerSupport.initializeTrigger(result, attrMap);
//         return result;
//     }
// }
