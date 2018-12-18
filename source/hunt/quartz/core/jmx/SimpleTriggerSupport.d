module hunt.quartz.core.jmx.SimpleTriggerSupport;

// import static javax.management.openmbean.SimpleType.INTEGER;
// import static javax.management.openmbean.SimpleType.LONG;

// import hunt.lang.exception;
// import java.util.ArrayList;
// import java.util.Arrays;
// import java.util.List;
// import hunt.container.Map;

// import javax.management.openmbean.CompositeData;
// import javax.management.openmbean.CompositeDataSupport;
// import javax.management.openmbean.CompositeType;
// import javax.management.openmbean.OpenDataException;
// import javax.management.openmbean.OpenType;
// import javax.management.openmbean.TabularData;
// import javax.management.openmbean.TabularDataSupport;
// import javax.management.openmbean.TabularType;

// import hunt.quartz.SimpleTrigger;
// import hunt.quartz.impl.triggers.SimpleTriggerImpl;
// import hunt.quartz.spi.OperableTrigger;

// class SimpleTriggerSupport {
//     private enum string COMPOSITE_TYPE_NAME = "SimpleTrigger";
//     private enum string COMPOSITE_TYPE_DESCRIPTION = "SimpleTrigger Details";
//     private enum string[] ITEM_NAMES = new string[] { "repeatCount", "repeatInterval", "timesTriggered" };
//     private enum string[] ITEM_DESCRIPTIONS = new string[] { "repeatCount", "repeatInterval", "timesTriggered" };
//     private static final OpenType[] ITEM_TYPES = new OpenType[] { INTEGER, LONG, INTEGER };
//     private static final CompositeType COMPOSITE_TYPE;
//     private enum string TABULAR_TYPE_NAME = "SimpleTrigger collection";
//     private enum string TABULAR_TYPE_DESCRIPTION = "SimpleTrigger collection";
//     private static final TabularType TABULAR_TYPE;

//     static {
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
    
//     static CompositeData toCompositeData(SimpleTrigger trigger) {
//         try {
//             return new CompositeDataSupport(COMPOSITE_TYPE, ITEM_NAMES,
//                     new Object[] {
//                             trigger.getRepeatCount(),
//                             trigger.getRepeatInterval(),
//                             trigger.getTimesTriggered(),
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

//     static TabularData toTabularData(List<? extends SimpleTrigger> triggers) {
//         TabularData tData = new TabularDataSupport(TABULAR_TYPE);
//         if (triggers !is null) {
//             ArrayList!(CompositeData) list = new ArrayList!(CompositeData)();
//             for (SimpleTrigger trigger : triggers) {
//                 list.add(toCompositeData(trigger));
//             }
//             tData.putAll(list.toArray(new CompositeData[list.size()]));
//         }
//         return tData;
//     }
    
//     static OperableTrigger newTrigger(CompositeData cData) {
//         SimpleTriggerImpl result = new SimpleTriggerImpl();
//         result.setRepeatCount(((Integer) cData.get("repeatCount")).intValue());
//         result.setRepeatInterval(((Long) cData.get("repeatInterval")).longValue());
//         result.setTimesTriggered(((Integer) cData.get("timesTriggered")).intValue());
//         TriggerSupport.initializeTrigger(result, cData);
//         return result;
//     }

//     static OperableTrigger newTrigger(Map!(string, Object) attrMap) {
//         SimpleTriggerImpl result = new SimpleTriggerImpl();
//         if(attrMap.containsKey("repeatCount")) {
//             result.setRepeatCount(((Integer) attrMap.get("repeatCount")).intValue());
//         }
//         if(attrMap.containsKey("repeatInterval")) {
//             result.setRepeatInterval(((Long) attrMap.get("repeatInterval")).longValue());
//         }
//         if(attrMap.containsKey("timesTriggered")) {
//             result.setTimesTriggered(((Integer) attrMap.get("timesTriggered")).intValue());
//         }
//         TriggerSupport.initializeTrigger(result, attrMap);
//         return result;
//     }
// }
