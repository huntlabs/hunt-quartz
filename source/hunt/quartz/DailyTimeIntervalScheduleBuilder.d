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
module hunt.quartz.DailyTimeIntervalScheduleBuilder;

import hunt.quartz.CalendarIntervalTrigger;
import hunt.quartz.DailyTimeIntervalTrigger;
import hunt.quartz.DateBuilder : IntervalUnit;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.TimeOfDay;
import hunt.quartz.Trigger;
import hunt.quartz.impl.triggers.DailyTimeIntervalTriggerImpl;
import hunt.quartz.spi.MutableTrigger;

import hunt.collection.Collections;
import hunt.collection.HashSet;
import hunt.collection.Set;
import hunt.Exceptions;
// import hunt.time.util.Calendar;
import hunt.time.LocalDateTime;
import hunt.time.DayOfWeek;
import hunt.time.ZoneOffset;

import std.conv;
// import std.datetime;

/**
 * A {@link ScheduleBuilder} implementation that build schedule for DailyTimeIntervalTrigger.
 * 
 * <p>This builder provide an extra convenient method for you to set the trigger's endTimeOfDay. You may
 * use either endingDailyAt() or endingDailyAfterCount() to set the value. The later will auto calculate
 * your endTimeOfDay by using the interval, intervalUnit and startTimeOfDay to perform the calculation.
 *  
 * <p>When using endingDailyAfterCount(), you should note that it is used to calculating endTimeOfDay. So
 * if your startTime on the first day is already pass by a time that would not add up to the count you
 * expected, until the next day comes. Remember that DailyTimeIntervalTrigger will use startTimeOfDay
 * and endTimeOfDay as fresh per each day!
 *  
 * <p>Quartz provides a builder-style API for constructing scheduling-related
 * entities via a Domain-Specific Language (DSL).  The DSL can best be
 * utilized through the usage of static imports of the methods on the classes
 * <code>TriggerBuilder</code>, <code>JobBuilder</code>, 
 * <code>DateBuilder</code>, <code>JobKey</code>, <code>TriggerKey</code> 
 * and the various <code>ScheduleBuilder</code> implementations.</p>
 * 
 * <p>Client code can then use the DSL to write code such as this:</p>
 * <pre>
 *         JobDetail job = newJob(MyJob.class)
 *             .withIdentity("myJob")
 *             .build();
 *             
 *         Trigger trigger = newTrigger() 
 *             .withIdentity(triggerKey("myTrigger", "myTriggerGroup"))
 *             .withSchedule(onDaysOfTheWeek(MONDAY, THURSDAY))
 *             .startAt(futureDate(10, MINUTES))
 *             .build();
 *         
 *         scheduler.scheduleJob(job, trigger);
 * <pre>
 *   
 * @since 2.1.0
 * 
 * @author James House
 * @author Zemian Deng <saltnlight5@gmail.com>
 */
class DailyTimeIntervalScheduleBuilder : ScheduleBuilder { // !(DailyTimeIntervalTrigger)

    private int interval = 1;
    private IntervalUnit intervalUnit = IntervalUnit.MINUTE;
    private Set!(int) daysOfWeek;
    private TimeOfDay startTimeOfDay;
    private TimeOfDay endTimeOfDay;
    private int repeatCount = DailyTimeIntervalTrigger.REPEAT_INDEFINITELY;

    private int misfireInstruction = CalendarIntervalTrigger.MISFIRE_INSTRUCTION_SMART_POLICY;
    
    /**
     * A set of all days of the week.
     * 
     * The set contains all values between {@link hunt.time.util.Calendar#SUNDAY} and {@link hunt.time.util.Calendar#SATURDAY} 
     * (the integers from 1 through 7). 
     */
    __gshared Set!(int) ALL_DAYS_OF_THE_WEEK;
    
    /** 
     * A set of the business days of the week (for locales similar to the USA).
     * 
     * The set contains all values between {@link hunt.time.util.Calendar#MONDAY} and {@link hunt.time.util.Calendar#FRIDAY} 
     * (the integers from 2 through 6). 
     */
    __gshared Set!(int) MONDAY_THROUGH_FRIDAY;
    
    /**
     * A set of the weekend days of the week (for locales similar to the USA).
     * 
     * The set contains {@link hunt.time.util.Calendar#SATURDAY} and {@link hunt.time.util.Calendar#SUNDAY} 
     */
    __gshared Set!(int) SATURDAY_AND_SUNDAY;
    
    shared static this() {
        Set!(int) t = new HashSet!(int)(7);
        foreach(DayOfWeek we;  DayOfWeek.values())
            t.add(we.getValue());
        ALL_DAYS_OF_THE_WEEK = t; // Collections.unmodifiableSet(t);
        
        t = new HashSet!(int)(5);
        for(int i=DayOfWeek.MONDAY.getValue(); i <= DayOfWeek.FRIDAY.getValue(); i++)
            t.add(i);
        MONDAY_THROUGH_FRIDAY =t; //  Collections.unmodifiableSet(t);
        
        t = new HashSet!(int)(2);
        t.add(DayOfWeek.SUNDAY.getValue());
        t.add(DayOfWeek.SATURDAY.getValue());
        SATURDAY_AND_SUNDAY =t; //  Collections.unmodifiableSet(t);
    }
    
    protected this() {

    }
    
    /**
     * Create a DailyTimeIntervalScheduleBuilder.
     * 
     * @return the new DailyTimeIntervalScheduleBuilder
     */
    static DailyTimeIntervalScheduleBuilder dailyTimeIntervalSchedule() {
        return new DailyTimeIntervalScheduleBuilder();
    }
    
    /**
     * Build the actual Trigger -- NOT intended to be invoked by end users,
     * but will rather be invoked by a TriggerBuilder which this 
     * ScheduleBuilder is given to.
     * 
     * @see TriggerBuilder#withSchedule(ScheduleBuilder)
     */
    override
    MutableTrigger build() {

        DailyTimeIntervalTriggerImpl st = new DailyTimeIntervalTriggerImpl();
        st.setRepeatInterval(interval);
        st.setRepeatIntervalUnit(intervalUnit);
        st.setMisfireInstruction(misfireInstruction);
        st.setRepeatCount(repeatCount);
        
        if(daysOfWeek !is null)
            st.setDaysOfWeek(daysOfWeek);
        else
            st.setDaysOfWeek(ALL_DAYS_OF_THE_WEEK);

        if(startTimeOfDay !is null)
            st.setStartTimeOfDay(startTimeOfDay);
        else
            st.setStartTimeOfDay(TimeOfDay.hourAndMinuteOfDay(0, 0));

        if(endTimeOfDay !is null)
            st.setEndTimeOfDay(endTimeOfDay);
        else
            st.setEndTimeOfDay(TimeOfDay.hourMinuteAndSecondOfDay(23, 59, 59));
        
        return st;
    }

    /**
     * Specify the time unit and interval for the Trigger to be produced.
     * 
     * @param timeInterval the interval at which the trigger should repeat.
     * @param unit the time unit (IntervalUnit) of the interval. The only intervals that are valid for this type of 
     * trigger are {@link IntervalUnit#SECOND}, {@link IntervalUnit#MINUTE}, and {@link IntervalUnit#HOUR}.
     * @return the updated DailyTimeIntervalScheduleBuilder
     * @see DailyTimeIntervalTrigger#getRepeatInterval()
     * @see DailyTimeIntervalTrigger#getRepeatIntervalUnit()
     */
    DailyTimeIntervalScheduleBuilder withInterval(int timeInterval, IntervalUnit unit) {
        if ((unit != IntervalUnit.SECOND || 
                unit == IntervalUnit.MINUTE || unit== IntervalUnit.HOUR))
            throw new IllegalArgumentException("Invalid repeat IntervalUnit (must be SECOND, MINUTE or HOUR).");
        validateInterval(timeInterval);
        this.interval = timeInterval;
        this.intervalUnit = unit;
        return this;
    }

    /**
     * Specify an interval in the IntervalUnit.SECOND that the produced 
     * Trigger will repeat at.
     * 
     * @param intervalInSeconds the number of seconds at which the trigger should repeat.
     * @return the updated DailyTimeIntervalScheduleBuilder
     * @see DailyTimeIntervalTrigger#getRepeatInterval()
     * @see DailyTimeIntervalTrigger#getRepeatIntervalUnit()
     */
    DailyTimeIntervalScheduleBuilder withIntervalInSeconds(int intervalInSeconds) {
        withInterval(intervalInSeconds, IntervalUnit.SECOND);
        return this;
    }
    
    /**
     * Specify an interval in the IntervalUnit.MINUTE that the produced 
     * Trigger will repeat at.
     * 
     * @param intervalInMinutes the number of minutes at which the trigger should repeat.
     * @return the updated CalendarIntervalScheduleBuilder
     * @see DailyTimeIntervalTrigger#getRepeatInterval()
     * @see DailyTimeIntervalTrigger#getRepeatIntervalUnit()
     */
    DailyTimeIntervalScheduleBuilder withIntervalInMinutes(int intervalInMinutes) {
        withInterval(intervalInMinutes, IntervalUnit.MINUTE);
        return this;
    }

    /**
     * Specify an interval in the IntervalUnit.HOUR that the produced 
     * Trigger will repeat at.
     * 
     * @param intervalInHours the number of hours at which the trigger should repeat.
     * @return the updated DailyTimeIntervalScheduleBuilder
     * @see DailyTimeIntervalTrigger#getRepeatInterval()
     * @see DailyTimeIntervalTrigger#getRepeatIntervalUnit()
     */
    DailyTimeIntervalScheduleBuilder withIntervalInHours(int intervalInHours) {
        withInterval(intervalInHours, IntervalUnit.HOUR);
        return this;
    }

    /**
     * Set the trigger to fire on the given days of the week.
     * 
     * @param onDaysOfWeek a Set containing the integers representing the days of the week, per the values 1-7 as defined by 
     * {@link hunt.time.util.Calendar#SUNDAY} - {@link hunt.time.util.Calendar#SATURDAY}. 
     * @return the updated DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder onDaysOfTheWeek(Set!(int) onDaysOfWeek) {
        if(onDaysOfWeek is null || onDaysOfWeek.size() == 0)
            throw new IllegalArgumentException("Days of week must be an non-empty set.");
        foreach(int day ; onDaysOfWeek)
            if (!ALL_DAYS_OF_THE_WEEK.contains(day))
                throw new IllegalArgumentException("Invalid value for day of week: " ~ day.to!string());
                
        this.daysOfWeek = onDaysOfWeek;
        return this;
    }

    /**
     * Set the trigger to fire on the given days of the week.
     * 
     * @param onDaysOfWeek a variable length list of Integers representing the days of the week, per the values 1-7 as 
     * defined by {@link hunt.time.util.Calendar#SUNDAY} - {@link hunt.time.util.Calendar#SATURDAY}. 
     * @return the updated DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder onDaysOfTheWeek(int[] onDaysOfWeek... ) {
        Set!(int) daysAsSet = new HashSet!(int)(12);
        daysAsSet.addAll(onDaysOfWeek);
        // Collections.addAll(daysAsSet, onDaysOfWeek);
        return onDaysOfTheWeek(daysAsSet);
    }
    
    /**
     * Set the trigger to fire on the days from Monday through Friday.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder onMondayThroughFriday() {
        this.daysOfWeek = MONDAY_THROUGH_FRIDAY;
        return this;
    }

    /**
     * Set the trigger to fire on the days Saturday and Sunday.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder onSaturdayAndSunday() {
        this.daysOfWeek = SATURDAY_AND_SUNDAY;
        return this;
    }

    /**
     * Set the trigger to fire on all days of the week.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder onEveryDay() {
        this.daysOfWeek = ALL_DAYS_OF_THE_WEEK;
        return this;
    }

    /**
     * Set the trigger to begin firing each day at the given time.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder startingDailyAt(TimeOfDay timeOfDay) {
        if(timeOfDay is null)
            throw new IllegalArgumentException("Start time of day cannot be null!");
        
        this.startTimeOfDay = timeOfDay;
        return this;
    }

    /**
     * Set the startTimeOfDay for this trigger to end firing each day at the given time.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder endingDailyAt(TimeOfDay timeOfDay) {        
        this.endTimeOfDay = timeOfDay;
        return this;
    }

    /**
     * Calculate and set the endTimeOfDay using count, interval and starTimeOfDay. This means
     * that these must be set before this method is call.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder endingDailyAfterCount(int count) {
        if(count <=0)
            throw new IllegalArgumentException("Ending daily after count must be a positive number!");
        
        if(startTimeOfDay is null)
            throw new IllegalArgumentException("You must set the startDailyAt()" ~ 
                " before calling this endingDailyAfterCount()!");
        
        LocalDateTime today = LocalDateTime.now();
        LocalDateTime startTimeOfDayDate = startTimeOfDay.getTimeOfDayForDate(today);
        LocalDateTime maxEndTimeOfDayDate = TimeOfDay.hourMinuteAndSecondOfDay(23, 59, 59).getTimeOfDayForDate(today);
        long remainingMillisInDay = maxEndTimeOfDayDate.toEpochMilli() - 
            startTimeOfDayDate.toEpochMilli();
        long intervalInMillis;
        if (intervalUnit == IntervalUnit.SECOND)
            intervalInMillis = interval * 1000L;
        else if (intervalUnit == IntervalUnit.MINUTE)
                intervalInMillis = interval * 1000L * 60;
        else if (intervalUnit == IntervalUnit.HOUR)
            intervalInMillis = interval * 1000L * 60 * 24;
        else
            throw new IllegalArgumentException("The IntervalUnit: " ~ intervalUnit.to!string() ~ 
                " is invalid for this trigger."); 
        
        if (remainingMillisInDay - intervalInMillis <= 0)
            throw new IllegalArgumentException("The startTimeOfDay is too late with given Interval and IntervalUnit values.");
        
        long maxNumOfCount = (remainingMillisInDay / intervalInMillis);
        if (count > maxNumOfCount)
            throw new IllegalArgumentException("The given count " ~ count.to!string() ~ 
                " is too large! The max you can set is " ~ maxNumOfCount.to!string());
        
        long incrementInMillis = (count - 1) * intervalInMillis;
        LocalDateTime endTimeOfDayDate = startTimeOfDayDate.plusNanos(incrementInMillis * 1000_000);
        
        long diffInMillis = endTimeOfDayDate.toEpochMilli() - 
            maxEndTimeOfDayDate.toEpochMilli();

        if (diffInMillis > 0)
            throw new IllegalArgumentException("The given count " ~ count.to!string() ~ 
                " is too large! The max you can set is " ~ maxNumOfCount.to!string());
        
        int hour = endTimeOfDayDate.getHour();
        int minute = endTimeOfDayDate.getMinute();
        int second = endTimeOfDayDate.getSecond();
        
        endTimeOfDay = TimeOfDay.hourMinuteAndSecondOfDay(hour, minute, second);
        return this;
    }

    /**
     * If the Trigger misfires, use the 
     * {@link Trigger#MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY} instruction.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     * @see Trigger#MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY
     */
    DailyTimeIntervalScheduleBuilder withMisfireHandlingInstructionIgnoreMisfires() {
        misfireInstruction = Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY;
        return this;
    }
    
    /**
     * If the Trigger misfires, use the 
     * {@link DailyTimeIntervalTrigger#MISFIRE_INSTRUCTION_DO_NOTHING} instruction.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     * @see DailyTimeIntervalTrigger#MISFIRE_INSTRUCTION_DO_NOTHING
     */
    DailyTimeIntervalScheduleBuilder withMisfireHandlingInstructionDoNothing() {
        misfireInstruction = DailyTimeIntervalTrigger.MISFIRE_INSTRUCTION_DO_NOTHING;
        return this;
    }

    /**
     * If the Trigger misfires, use the 
     * {@link DailyTimeIntervalTrigger#MISFIRE_INSTRUCTION_FIRE_ONCE_NOW} instruction.
     * 
     * @return the updated DailyTimeIntervalScheduleBuilder
     * @see DailyTimeIntervalTrigger#MISFIRE_INSTRUCTION_FIRE_ONCE_NOW
     */
    DailyTimeIntervalScheduleBuilder withMisfireHandlingInstructionFireAndProceed() {
        misfireInstruction = CalendarIntervalTrigger.MISFIRE_INSTRUCTION_FIRE_ONCE_NOW;
        return this;
    }
    
    /**
     * Set number of times for interval to repeat.
     * 
     * <p>Note: if you want total count = 1 (at start time) + repeatCount</p>
     * 
     * @return the new DailyTimeIntervalScheduleBuilder
     */
    DailyTimeIntervalScheduleBuilder withRepeatCount(int repeatCount) {
        this.repeatCount = repeatCount;
        return this;
    }

    private void validateInterval(int timeInterval) {
        if(timeInterval <= 0)
            throw new IllegalArgumentException("Interval must be a positive value.");
    }
}
