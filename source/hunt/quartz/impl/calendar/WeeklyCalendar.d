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

module hunt.quartz.impl.calendar.WeeklyCalendar;

import std.datetime : TimeZone;

import hunt.quartz.Calendar;

/**
 * <p>
 * This implementation of the Calendar excludes a set of days of the week. You
 * may use it to exclude weekends for example. But you may define any day of
 * the week.  By default it excludes SATURDAY and SUNDAY.
 * </p>
 *
 * @see hunt.quartz.Calendar
 * @see hunt.quartz.impl.calendar.BaseCalendar
 *
 * @author Juergen Donnerstag
 */
class WeeklyCalendar : BaseCalendar, Calendar {

    // An array to store the week days which are to be excluded.
    // hunt.time.util.Calendar.MONDAY etc. are used as index.
    private bool[] excludeDays = new bool[8];

    // Will be set to true, if all week days are excluded
    private bool excludeAll = false;

    this() {
        this(null, null);
    }

    this(Calendar baseCalendar) {
        this(baseCalendar, null);
    }

    this(TimeZone timeZone) {
        super(null, timeZone);
    }

    this(Calendar baseCalendar, TimeZone timeZone) {
        super(baseCalendar, timeZone);

        excludeDays[hunt.time.util.Calendar.SUNDAY] = true;
        excludeDays[hunt.time.util.Calendar.SATURDAY] = true;
        excludeAll = areAllDaysExcluded();
    }

    override
    Object clone() {
        WeeklyCalendar clone = (WeeklyCalendar) super.clone();
        clone.excludeDays = excludeDays.clone();
        return clone;
    }

    /**
     * <p>
     * Get the array with the week days
     * </p>
     */
    bool[] getDaysExcluded() {
        return excludeDays;
    }

    /**
     * <p>
     * Return true, if wday (see Calendar.get()) is defined to be exluded. E. g.
     * saturday and sunday.
     * </p>
     */
    bool isDayExcluded(int wday) {
        return excludeDays[wday];
    }

    /**
     * <p>
     * Redefine the array of days excluded. The array must of size greater or
     * equal 8. hunt.time.util.Calendar's constants like MONDAY should be used as
     * index. A value of true is regarded as: exclude it.
     * </p>
     */
    void setDaysExcluded(bool[] weekDays) {
        if (weekDays is null) {
            return;
        }

        excludeDays = weekDays;
        excludeAll = areAllDaysExcluded();
    }

    /**
     * <p>
     * Redefine a certain day of the week to be excluded (true) or included
     * (false). Use hunt.time.util.Calendar's constants like MONDAY to determine the
     * wday.
     * </p>
     */
    void setDayExcluded(int wday, bool exclude) {
        excludeDays[wday] = exclude;
        excludeAll = areAllDaysExcluded();
    }

    /**
     * <p>
     * Check if all week days are excluded. That is no day is included.
     * </p>
     *
     * @return bool
     */
    bool areAllDaysExcluded() {
        return
            isDayExcluded(hunt.time.util.Calendar.SUNDAY) &&
            isDayExcluded(hunt.time.util.Calendar.MONDAY) &&
            isDayExcluded(hunt.time.util.Calendar.TUESDAY) &&
            isDayExcluded(hunt.time.util.Calendar.WEDNESDAY) &&
            isDayExcluded(hunt.time.util.Calendar.THURSDAY) &&
            isDayExcluded(hunt.time.util.Calendar.FRIDAY) &&
            isDayExcluded(hunt.time.util.Calendar.SATURDAY);
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

        hunt.time.util.Calendar cl = createJavaCalendar(timeStamp);
        int wday = cl.get(hunt.time.util.Calendar.DAY_OF_WEEK);

        return !(isDayExcluded(wday));
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
        hunt.time.util.Calendar cl = getStartOfDayJavaCalendar(timeStamp);
        int wday = cl.get(hunt.time.util.Calendar.DAY_OF_WEEK);

        if (!isDayExcluded(wday)) {
            return timeStamp; // return the original value
        }

        while (isDayExcluded(wday) == true) {
            cl.add(hunt.time.util.Calendar.DATE, 1);
            wday = cl.get(hunt.time.util.Calendar.DAY_OF_WEEK);
        }

        return cl.getTime().getTime();
    }
}
