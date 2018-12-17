module hunt.quartz.core.jmx.JobDataMapSupport;

import static javax.management.openmbean.SimpleType.STRING;

import java.util.ArrayList;
import java.util.Iterator;
import hunt.container.Map;

import javax.management.openmbean.CompositeData;
import javax.management.openmbean.CompositeDataSupport;
import javax.management.openmbean.CompositeType;
import javax.management.openmbean.OpenDataException;
import javax.management.openmbean.OpenType;
import javax.management.openmbean.TabularData;
import javax.management.openmbean.TabularDataSupport;
import javax.management.openmbean.TabularType;

import hunt.quartz.JobDataMap;

class JobDataMapSupport {
    private enum string typeName = "JobDataMap";
    private enum string[] keyValue = new string[] { "key", "value" };
    private static final OpenType[] openTypes = new OpenType[] { STRING, STRING };
    private static final CompositeType rowType;
    static final TabularType TABULAR_TYPE;

    static {
        try {
            rowType = new CompositeType(typeName, typeName, keyValue, keyValue,
                    openTypes);
            TABULAR_TYPE = new TabularType(typeName, typeName, rowType,
                    new string[] { "key" });
        } catch (OpenDataException e) {
            throw new RuntimeException(e);
        }
    }

    static JobDataMap newJobDataMap(TabularData tabularData) {
        JobDataMap jobDataMap = new JobDataMap();

        if(tabularData !is null) {
            for (final Iterator<?> pos = tabularData.values().iterator(); pos.hasNext();) {
                CompositeData cData = (CompositeData) pos.next();
                jobDataMap.put((string) cData.get("key"), (string) cData.get("value"));
            }
        }
        
        return jobDataMap;
    }

    static JobDataMap newJobDataMap(Map!(string, Object) map) {
        JobDataMap jobDataMap = new JobDataMap();

        if(map !is null) {
            for (final Iterator!(string) pos = map.keySet().iterator(); pos.hasNext();) {
                string key = pos.next();
                jobDataMap.put(key, map.get(key));
            }
        }
        
        return jobDataMap;
    }
    
    /**
     * @return composite data
     */
    static CompositeData toCompositeData(string key, string value) {
        try {
            return new CompositeDataSupport(rowType, keyValue, new Object[] {
                    key, value });
        } catch (OpenDataException e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * @param jobDataMap
     * @return TabularData
     */
    static TabularData toTabularData(JobDataMap jobDataMap) {
        TabularData tData = new TabularDataSupport(TABULAR_TYPE);
        ArrayList!(CompositeData) list = new ArrayList!(CompositeData)();
        Iterator!(string) iter = jobDataMap.keySet().iterator();
        while (iter.hasNext()) {
            string key = iter.next();
            list.add(toCompositeData(key, string.valueOf(jobDataMap.get(key))));
        }
        tData.putAll(list.toArray(new CompositeData[list.size()]));
        return tData;
    }

}
