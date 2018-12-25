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

module hunt.quartz.impl.calendar.HolidayCalendar;

import hunt.quartz.impl.calendar.BaseCalendar;
import hunt.quartz.Calendar;

import hunt.container.Collections;
import hunt.container.SortedSet;
import hunt.container.TreeSet;

import hunt.time.LocalDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
// import std.datetime;

/**
 * <p>
 * This implementation of the Calendar stores a list of holidays (full days
 * that are excluded from scheduling).
 * </p>
 * 
 * <p>
 * The implementation DOES take the year into consideration, so if you want to
 * exclude July 4th for the next 10 years, you need to add 10 entries to the
 * exclude list.
 * </p>
 * 
 * @author Sharada Jambula
 * @author Juergen Donnerstag
 */
class HolidayCalendar : BaseCalendar, Calendar {
    
    // A sorted set to store the holidays
    private TreeSet!(LocalDateTime) dates;

    this() {
    }

    this(Calendar baseCalendar) {
        super(baseCalendar);
    }

    this(ZoneId timeZone) {
        super(timeZone);
    }

    this(Calendar baseCalendar, ZoneId timeZone) {
        super(baseCalendar, timeZone);
    }

    private void initialize() {
        dates = new TreeSet!(LocalDateTime)();
    }

    // override
    // Object clone() {
    //     HolidayCalendar clone = (HolidayCalendar) super.clone();
    //     clone.dates = new TreeSet!(LocalDateTime)(dates);
    //     return clone;
    // }
    
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
        if (super.isTimeIncluded(timeStamp) == false) {
            return false;
        }

        LocalDateTime lookFor = getStartOfDayJavaCalendar(timeStamp);

        return !(dates.contains(lookFor));
    }

    /**
     * <p>
     * Determine the next time (in milliseconds) that is 'included' by the
     * Calendar after the given time.
     * </p>
     * 
     * <p>
     * Note that this Calendar is only has full-day precision.
     * </p>
     */
    override
    long getNextIncludedTime(long timeStamp) {

        // Call base calendar implementation first
        long baseTime = super.getNextIncludedTime(timeStamp);
        if ((baseTime > 0) && (baseTime > timeStamp)) {
            timeStamp = baseTime;
        }

        // Get timestamp for 00:00:00
        LocalDateTime day = getStartOfDayJavaCalendar(timeStamp);
        while (isTimeIncluded(day.toInstant(ZoneOffset.UTC).toEpochMilli()) == false) {
            day = day.plusDays(1);
        }

        return day.toInstant(ZoneOffset.UTC).toEpochMilli();
    }

    /**
     * <p>
     * Add the given LocalDateTime to the list of excluded days. Only the month, day and
     * year of the returned dates are significant.
     * </p>
     */
    void addExcludedDate(LocalDateTime excludedDate) {
        LocalDateTime date = getStartOfDayJavaCalendar(excludedDate);
        /*
         * System.err.println( "HolidayCalendar.add(): date=" ~
         * excludedDate.toLocaleString());
         */
        this.dates.add(date);
    }

    void removeExcludedDate(LocalDateTime dateToRemove) {
        LocalDateTime date = getStartOfDayJavaCalendar(dateToRemove);
        dates.remove(date);
    }

    /**
     * <p>
     * Returns a <code>SortedSet</code> of Dates representing the excluded
     * days. Only the month, day and year of the returned dates are
     * significant.
     * </p>
     */
    SortedSet!(LocalDateTime) getExcludedDates() {
        return (dates); // Collections.unmodifiableSortedSet
    }
}
