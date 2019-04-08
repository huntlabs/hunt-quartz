/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module hunt.quartz.dbstore.CalendarIntervalTriggerPersistenceDelegate;

import hunt.quartz.dbstore.SimplePropertiesTriggerPersistenceDelegateSupport;
import hunt.quartz.dbstore.SimplePropertiesTriggerProperties;
import hunt.quartz.dbstore.StdSqlConstants;
import hunt.quartz.dbstore.TableConstants;
import hunt.quartz.dbstore.TriggerPersistenceDelegate;

import hunt.quartz.CalendarIntervalScheduleBuilder;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.DateBuilder;
import hunt.quartz.impl.triggers.CalendarIntervalTriggerImpl;
import hunt.quartz.spi.OperableTrigger;

import hunt.Exceptions;
import hunt.time.ZoneId;
import hunt.time.ZoneRegion;

import std.array;
import std.conv;

class CalendarIntervalTriggerPersistenceDelegate : SimplePropertiesTriggerPersistenceDelegateSupport {

    bool canHandleTriggerType(OperableTrigger trigger) {
        CalendarIntervalTriggerImpl s = cast(CalendarIntervalTriggerImpl)trigger;
        if(s !is null) {
            return !s.hasAdditionalProperties();
        }
        return false;
    }

    string getHandledTriggerTypeDiscriminator() {
        return TableConstants.TTYPE_CAL_INT;
    }

    override
    protected SimplePropertiesTriggerProperties getTriggerProperties(OperableTrigger trigger) {
        CalendarIntervalTriggerImpl calTrig = cast(CalendarIntervalTriggerImpl)trigger;
        SimplePropertiesTriggerProperties props = new SimplePropertiesTriggerProperties();
        
        props.setInt1(calTrig.getRepeatInterval());
        props.setString1(calTrig.getRepeatIntervalUnit().to!string());
        props.setInt2(calTrig.getTimesTriggered());
        props.setString2(calTrig.getTimeZone().getId());
        props.setBoolean1(calTrig.isPreserveHourOfDayAcrossDaylightSavings());
        props.setBoolean2(calTrig.isSkipDayIfHourDoesNotExist());
        
        return props;
    }

    override
    protected TriggerPropertyBundle getTriggerPropertyBundle(SimplePropertiesTriggerProperties props) {

        ZoneId tz = null; // if we use null, that's ok as system default tz will be used
        string tzId = props.getString2();
        if(!tzId.empty) // there could be null entries from previously released versions
            tz = ZoneRegion.of(tzId);
        
        ScheduleBuilder sb = CalendarIntervalScheduleBuilder.calendarIntervalSchedule()
            .withInterval(props.getInt1(), to!(IntervalUnit)(props.getString1()))
            .inTimeZone(tz)
            .preserveHourOfDayAcrossDaylightSavings(props.isBoolean1())
            .skipDayIfHourDoesNotExist(props.isBoolean2());
        
        int timesTriggered = props.getInt2();
        import hunt.Integer;
        
        string[] statePropertyNames = ["timesTriggered" ];
        Object[] statePropertyValues = [ Integer.valueOf(timesTriggered) ];

        return new TriggerPropertyBundle(sb, statePropertyNames, statePropertyValues);
    }
}
