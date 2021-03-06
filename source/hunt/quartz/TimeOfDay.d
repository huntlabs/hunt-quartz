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
module hunt.quartz.TimeOfDay;

import hunt.time.LocalDateTime;
import hunt.time.ZonedDateTime;
import hunt.time.ZoneId;

import hunt.Exceptions;
import std.format;
// import hunt.time.util.Calendar;
// import std.datetime;
// import std.datetime : ZoneId;

/**
 * Represents a time in hour, minute and second of any given day.
 * 
 * <p>The hour is in 24-hour convention, meaning values are from 0 to 23.</p> 
 * 
 * @see DailyTimeIntervalScheduleBuilder
 * 
 * @since 2.0.3
 * 
 * @author James House
 * @author Zemian Deng <saltnlight5@gmail.com>
 */
class TimeOfDay {

    private int hour;
    private int minute;
    private int second;
    
    /**
     * Create a TimeOfDay instance for the given hour, minute and second.
     * 
     * @param hour The hour of day, between 0 and 23.
     * @param minute The minute of the hour, between 0 and 59.
     * @param second The second of the minute, between 0 and 59.
     * @throws IllegalArgumentException if one or more of the input values is out of their valid range.
     */
    this(int hour, int minute, int second) {
        this.hour = hour;
        this.minute = minute;
        this.second = second;
        validate();
    }
    
    /**
     * Create a TimeOfDay instance for the given hour and minute (at the zero second of the minute).
     * 
     * @param hour The hour of day, between 0 and 23.
     * @param minute The minute of the hour, between 0 and 59.
     * @throws IllegalArgumentException if one or more of the input values is out of their valid range.
     */
    this(int hour, int minute) {
        this.hour = hour;
        this.minute = minute;
        this.second = 0;
        validate();
    }
    
    private void validate() {
        if(hour < 0 || hour > 23)
            throw new IllegalArgumentException("Hour must be from 0 to 23");
        if(minute < 0 || minute > 59)
            throw new IllegalArgumentException("Minute must be from 0 to 59");
        if(second < 0 || second > 59)
            throw new IllegalArgumentException("Second must be from 0 to 59");
    }

    /**
     * Create a TimeOfDay instance for the given hour, minute and second.
     * 
     * @param hour The hour of day, between 0 and 23.
     * @param minute The minute of the hour, between 0 and 59.
     * @param second The second of the minute, between 0 and 59.
     * @throws IllegalArgumentException if one or more of the input values is out of their valid range.
     */
    static TimeOfDay hourMinuteAndSecondOfDay(int hour, int minute, int second) {
        return new TimeOfDay(hour, minute, second);
    }

    /**
     * Create a TimeOfDay instance for the given hour and minute (at the zero second of the minute).
     * 
     * @param hour The hour of day, between 0 and 23.
     * @param minute The minute of the hour, between 0 and 59.
     * @throws IllegalArgumentException if one or more of the input values is out of their valid range.
     */
    static TimeOfDay hourAndMinuteOfDay(int hour, int minute) {
        return new TimeOfDay(hour, minute);
    }
    
    /**
     * The hour of the day (between 0 and 23).
     * 
     * @return The hour of the day (between 0 and 23).
     */
    int getHour() {
        return hour;
    }

    /**
     * The minute of the hour.
     * 
     * @return The minute of the hour (between 0 and 59).
     */
    int getMinute() {
        return minute;
    }

    /**
     * The second of the minute.
     * 
     * @return The second of the minute (between 0 and 59).
     */
    int getSecond() {
        return second;
    }

    /**
     * Determine with this time of day is before the given time of day.
     * 
     * @return true this time of day is before the given time of day.
     */
    bool before(TimeOfDay timeOfDay) {
        
        if(timeOfDay.hour > hour)
            return true;
        if(timeOfDay.hour < hour)
            return false;

        if(timeOfDay.minute > minute)
            return true;
        if(timeOfDay.minute < minute)
            return false;

        if(timeOfDay.second > second)
            return true;
        if(timeOfDay.second < second)
            return false;
        
        return false; // must be equal...
    }

    override
    bool opEquals(Object obj) {
        TimeOfDay other = cast(TimeOfDay)obj;
        if(other is null)
            return false;
        
        return (other.hour == hour && other.minute == minute && other.second == second);
    }

    override
    size_t toHash() @trusted nothrow {
        return (hour + 1) ^ (minute + 1) ^ (second + 1);
    }
    
    /** Return a date with time of day reset to this object values. The millisecond value will be zero. */
    LocalDateTime getTimeOfDayForDate(LocalDateTime dateTime) {
        if (dateTime is null)
            return null;
        return LocalDateTime.of(dateTime.getYear(), dateTime.getMonthValue(), 
            dateTime.getDayOfMonth(), hour, minute, second);
    }
    
    /**
     * Create a TimeOfDay from the given date, in the system default ZoneId.
     * 
     * @param dateTime The java.util.LocalDateTime from which to extract Hour, Minute and Second.
     */
    static TimeOfDay hourAndMinuteAndSecondFromDate(LocalDateTime dateTime) {
        return hourAndMinuteAndSecondFromDate(dateTime, null);
    }
    
    /**
     * Create a TimeOfDay from the given date, in the given ZoneId.
     * 
     * @param dateTime The java.util.LocalDateTime from which to extract Hour, Minute and Second.
     * @param tz The ZoneId from which relate Hour, Minute and Second for the given date.  If null, system default
     * ZoneId will be used.
     */
    static TimeOfDay hourAndMinuteAndSecondFromDate(LocalDateTime dateTime, ZoneId tz) {
        if (dateTime is null)
            return null;
        ZonedDateTime dt = dateTime.atZone(tz);
        return new TimeOfDay(dt.getHour(), dt.getMinute(), dt.getSecond());
    }
    
    /**
     * Create a TimeOfDay from the given date (at the zero-second), in the system default ZoneId.
     * 
     * @param dateTime The java.util.LocalDateTime from which to extract Hour and Minute.
     */
    static TimeOfDay hourAndMinuteFromDate(LocalDateTime dateTime) {
        return hourAndMinuteFromDate(dateTime, null);
    }
    
    /**
     * Create a TimeOfDay from the given date (at the zero-second), in the system default ZoneId.
     * 
     * @param dateTime The java.util.LocalDateTime from which to extract Hour and Minute.
     * @param tz The ZoneId from which relate Hour and Minute for the given date.  If null, system default
     * ZoneId will be used.
     */
    static TimeOfDay hourAndMinuteFromDate(LocalDateTime dateTime, ZoneId tz) {
        if (dateTime is null)
            return null;
        ZonedDateTime dt = dateTime.atZone(tz);
        return new TimeOfDay(dt.getHour(), dt.getMinute(), 0);
    }
    
    override
    string toString() {
        return format("TimeOfDay[%d:%d:%d]", hour, minute, second);
    }
}
