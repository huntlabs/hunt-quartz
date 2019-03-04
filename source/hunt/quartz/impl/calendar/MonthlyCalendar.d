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

module hunt.quartz.impl.calendar.MonthlyCalendar;

import hunt.quartz.impl.calendar.BaseCalendar;
import hunt.quartz.Calendar;

// import std.datetime : ZoneId;
import hunt.Exceptions;
import hunt.time.LocalDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;

import std.conv;

/**
 * <p>
 * This implementation of the Calendar excludes a set of days of the month. You
 * may use it to exclude every first day of each month for example. But you may define
 * any day of a month.
 * </p>
 *
 * @see hunt.quartz.Calendar
 * @see hunt.quartz.impl.calendar.BaseCalendar
 *
 * @author Juergen Donnerstag
 */
class MonthlyCalendar : BaseCalendar {


    private enum int MAX_DAYS_IN_MONTH = 31;

    // An array to store a months days which are to be excluded.
    // hunt.time.util.Calendar.get( ) as index.
    private bool[MAX_DAYS_IN_MONTH] excludeDays;

    // Will be set to true, if all week days are excluded
    private bool excludeAll = false;

    this() {
        this(null, null);
    }

    this(Calendar baseCalendar) {
        this(baseCalendar, null);
    }

    this(ZoneId timeZone) {
        this(null, timeZone);
    }

    this(Calendar baseCalendar, ZoneId timeZone) {
        super(baseCalendar, timeZone);

        // all days are included by default
        excludeAll = areAllDaysExcluded();
    }

    // override
    // Object clone() {
    //     MonthlyCalendar clone = (MonthlyCalendar) super.clone();
    //     clone.excludeDays = excludeDays.clone();
    //     return clone;
    // }

    /**
     * <p>
     * Get the array which defines the exclude-value of each day of month.
     * Only the first 31 elements of the array are relevant, with the 0 index
     * element representing the first day of the month.
     * </p>
     */
    bool[] getDaysExcluded() {
        return excludeDays;
    }

    /**
     * <p>
     * Return true, if day is defined to be excluded.
     * </p>
     *
     * @param day The day of the month (from 1 to 31) to check.
     */
    bool isDayExcluded(int day) {
        if ((day < 1) || (day > MAX_DAYS_IN_MONTH)) {
            throw new IllegalArgumentException(
                "The day parameter must be in the range of 1 to " ~ MAX_DAYS_IN_MONTH.to!string());
        }

        return excludeDays[day - 1];
    }

    /**
     * <p>
     * Redefine the array of days excluded. The array must non-null and of size
     * greater or equal to 31. The 0 index element represents the first day of
     * the month.
     * </p>
     */
    void setDaysExcluded(bool[] days) {
        if (days is null) {
            throw new IllegalArgumentException("The days parameter cannot be null.");
        }

        if (days.length < MAX_DAYS_IN_MONTH) {
            throw new IllegalArgumentException(
                "The days parameter must have a length of at least " ~ MAX_DAYS_IN_MONTH.to!string() ~ " elements.");
        }

        excludeDays = days;
        excludeAll = areAllDaysExcluded();
    }

    /**
     * <p>
     * Redefine a certain day of the month to be excluded (true) or included
     * (false).
     * </p>
     *
     * @param day The day of the month (from 1 to 31) to set.
     */
    void setDayExcluded(int day, bool exclude) {
        if ((day < 1) || (day > MAX_DAYS_IN_MONTH)) {
            throw new IllegalArgumentException(
                "The day parameter must be in the range of 1 to " ~ MAX_DAYS_IN_MONTH.to!string());
        }

        excludeDays[day - 1] = exclude;
        excludeAll = areAllDaysExcluded();
    }

    /**
     * <p>
     * Check if all days are excluded. That is no day is included.
     * </p>
     */
    bool areAllDaysExcluded() {
        for (int i = 1; i <= MAX_DAYS_IN_MONTH; i++) {
            if (isDayExcluded(i) == false) {
                return false;
            }
        }

        return true;
    }

    /**
     * <p>
     * Determine whether the given time (in milliseconds) is 'included' by the
     * Calendar.
     * </p>
     *
     * <p>
     * Note that this Calendar is only has full-day precision.
     * </p>
     */
    override
    bool isTimeIncluded(long timeStamp) {
        if (excludeAll == true) {
            return false;
        }

        // Test the base calendar first. Only if the base calendar not already
        // excludes the time/date, continue evaluating this calendar instance.
        if (super.isTimeIncluded(timeStamp) == false) { return false; }

        LocalDateTime cl = createJavaCalendar(timeStamp);
        int day =  cl.getDayOfMonth();

        return !(isDayExcluded(day));
    }

    /**
     * <p>
     * Determine the next time (in milliseconds) that is 'included' by the
     * Calendar after the given time. Return the original value if timeStamp is
     * included. Return 0 if all days are excluded.
     * </p>
     *
     * <p>
     * Note that this Calendar is only has full-day precision.
     * </p>
     */
    override
    long getNextIncludedTime(long timeStamp) {
        if (excludeAll == true) {
            return 0;
        }

        // Call base calendar implementation first
        long baseTime = super.getNextIncludedTime(timeStamp);
        if ((baseTime > 0) && (baseTime > timeStamp)) {
            timeStamp = baseTime;
        }

        // Get timestamp for 00:00:00
        LocalDateTime cl = getStartOfDayJavaCalendar(timeStamp);
        int day = cl.getDayOfMonth();

        if (!isDayExcluded(day)) {
            return timeStamp; // return the original value
        }

        while (isDayExcluded(day) == true) {
            cl = cl.plusDays(1);
            day = cl.getDayOfMonth();
        }

        return cl.toInstant(ZoneOffset.UTC).toEpochMilli();
    }
}
