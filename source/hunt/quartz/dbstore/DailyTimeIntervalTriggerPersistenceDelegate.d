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
module hunt.quartz.dbstore.DailyTimeIntervalTriggerPersistenceDelegate;

import hunt.collection.HashSet;
import hunt.collection.Iterator;
import hunt.comtainer.Set;

import hunt.quartz.DailyTimeIntervalScheduleBuilder;
import hunt.quartz.DailyTimeIntervalTrigger;
import hunt.quartz.TimeOfDay;
import hunt.quartz.DateBuilder.IntervalUnit;
import hunt.quartz.impl.triggers.DailyTimeIntervalTriggerImpl;
import hunt.quartz.spi.OperableTrigger;

/**
 * Persist a DailyTimeIntervalTrigger by converting internal fields to and from
 * SimplePropertiesTriggerProperties.
 * 
 * @see DailyTimeIntervalScheduleBuilder
 * @see DailyTimeIntervalTrigger
 * 
 * @since 2.1.0
 * 
 * @author Zemian Deng <saltnlight5@gmail.com>
 */
class DailyTimeIntervalTriggerPersistenceDelegate : SimplePropertiesTriggerPersistenceDelegateSupport {

    bool canHandleTriggerType(OperableTrigger trigger) {
        DailyTimeIntervalTriggerImpl s = cast(DailyTimeIntervalTriggerImpl)trigger;
        if(s !is null) {
            return !s.hasAdditionalProperties();
        }
        return false;
    }

    string getHandledTriggerTypeDiscriminator() {
        return TTYPE_DAILY_TIME_INT;
    }

    override
    protected SimplePropertiesTriggerProperties getTriggerProperties(OperableTrigger trigger) {
        DailyTimeIntervalTriggerImpl dailyTrigger = cast(DailyTimeIntervalTriggerImpl)trigger;
        SimplePropertiesTriggerProperties props = new SimplePropertiesTriggerProperties();
        
        props.setInt1(dailyTrigger.getRepeatInterval());
        props.setString1(dailyTrigger.getRepeatIntervalUnit().name());
        props.setInt2(dailyTrigger.getTimesTriggered());
        
        Set!(Integer) days = dailyTrigger.getDaysOfWeek();
        string daysStr = join(days, ",");
        props.setString2(daysStr);

        StringBuilder timeOfDayBuffer = new StringBuilder();
        TimeOfDay startTimeOfDay = dailyTrigger.getStartTimeOfDay();
        if (startTimeOfDay !is null) {
            timeOfDayBuffer.append(startTimeOfDay.getHour()).append(",");
            timeOfDayBuffer.append(startTimeOfDay.getMinute()).append(",");
            timeOfDayBuffer.append(startTimeOfDay.getSecond()).append(",");
        } else {
            timeOfDayBuffer.append(",,,");
        }
        TimeOfDay endTimeOfDay = dailyTrigger.getEndTimeOfDay();
        if (endTimeOfDay !is null) {
            timeOfDayBuffer.append(endTimeOfDay.getHour()).append(",");
            timeOfDayBuffer.append(endTimeOfDay.getMinute()).append(",");
            timeOfDayBuffer.append(endTimeOfDay.getSecond());
        } else {
            timeOfDayBuffer.append(",,,");
        }
        props.setString3(timeOfDayBuffer.toString());
        
        props.setLong1(dailyTrigger.getRepeatCount());
        
        return props;
    }

    private string join(Set!(Integer) days, string sep) {
        StringBuilder sb = new StringBuilder();
        if (days is null || days.size() <= 0)
            return "";
        
        Iterator!(Integer) itr = days.iterator();
        sb.append(itr.next());
        while(itr.hasNext()) {
            sb.append(sep).append(itr.next());
        }
        return sb.toString();
    }

    override
    protected TriggerPropertyBundle getTriggerPropertyBundle(SimplePropertiesTriggerProperties props) {
        int repeatCount = cast(int)props.getLong1();
        int interval = props.getInt1();
        string intervalUnitStr = props.getString1();
        string daysOfWeekStr = props.getString2();
        string timeOfDayStr = props.getString3();

        IntervalUnit intervalUnit = IntervalUnit.valueOf(intervalUnitStr);
        DailyTimeIntervalScheduleBuilder scheduleBuilder = DailyTimeIntervalScheduleBuilder
                .dailyTimeIntervalSchedule()
                .withInterval(interval, intervalUnit)
                .withRepeatCount(repeatCount);
                
        if (daysOfWeekStr !is null) {
            Set!(Integer) daysOfWeek = new HashSet!(Integer)();
            string[] nums = daysOfWeekStr.split(",");
            if (nums.length > 0) {
                foreach(string num ; nums) {
                    daysOfWeek.add(Integer.parseInt(num));
                }
                scheduleBuilder.onDaysOfTheWeek(daysOfWeek);
            }
        } else {
            scheduleBuilder.onDaysOfTheWeek(DailyTimeIntervalScheduleBuilder.ALL_DAYS_OF_THE_WEEK);
        }
        
        if (timeOfDayStr !is null) {
            string[] nums = timeOfDayStr.split(",");
            TimeOfDay startTimeOfDay;
            if (nums.length >= 3) {
                int hour = Integer.parseInt(nums[0]);
                int min = Integer.parseInt(nums[1]);
                int sec = Integer.parseInt(nums[2]);
                startTimeOfDay = new TimeOfDay(hour, min, sec);
            } else {
                startTimeOfDay = TimeOfDay.hourMinuteAndSecondOfDay(0, 0, 0);
            }
            scheduleBuilder.startingDailyAt(startTimeOfDay);

            TimeOfDay endTimeOfDay;
            if (nums.length >= 6) {
                int hour = Integer.parseInt(nums[3]);
                int min = Integer.parseInt(nums[4]);
                int sec = Integer.parseInt(nums[5]);
                endTimeOfDay = new TimeOfDay(hour, min, sec);
            } else {
                endTimeOfDay = TimeOfDay.hourMinuteAndSecondOfDay(23, 59, 59);
            }
            scheduleBuilder.endingDailyAt(endTimeOfDay);
        } else {
            scheduleBuilder.startingDailyAt(TimeOfDay.hourMinuteAndSecondOfDay(0, 0, 0));
            scheduleBuilder.endingDailyAt(TimeOfDay.hourMinuteAndSecondOfDay(23, 59, 59));
        }
        
        int timesTriggered = props.getInt2();
        string[] statePropertyNames = { "timesTriggered" };
        Object[] statePropertyValues = { timesTriggered };

        return new TriggerPropertyBundle(scheduleBuilder, statePropertyNames, statePropertyValues);
    }
}
