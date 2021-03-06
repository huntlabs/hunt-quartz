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

module hunt.quartz.impl.calendar.AnnualCalendar;

import hunt.quartz.impl.calendar.BaseCalendar;
import hunt.quartz.Calendar;

import hunt.collection.ArrayList;
import hunt.collection.Collections;
import hunt.collection.Iterator;
import hunt.Exceptions;
import hunt.time.Instant;
import hunt.time.LocalDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.util.Comparator;

/**
 * <p>
 * This implementation of the Calendar excludes a set of days of the year. You
 * may use it to exclude bank holidays which are on the same date every year.
 * </p>
 * 
 * @see hunt.quartz.Calendar
 * @see hunt.quartz.impl.calendar.BaseCalendar
 * 
 * @author Juergen Donnerstag
 */
class AnnualCalendar : BaseCalendar {


    private ArrayList!(LocalDateTime) excludeDays;

    // true, if excludeDays is sorted
    private bool dataSorted = false;

    this() {
        initialize();
    }

    this(QuartzCalendar baseCalendar) {
        initialize();
        super(baseCalendar);
    }

    this(ZoneId timeZone) {
        initialize();
        super(timeZone);
    }

    this(QuartzCalendar baseCalendar, ZoneId timeZone) {
        initialize();
        super(baseCalendar, timeZone);
    }

    private void initialize() {
        excludeDays = new ArrayList!(LocalDateTime)();
    }

    override
    Object clone() {
        AnnualCalendar clone = cast(AnnualCalendar) super.clone();
        clone.excludeDays = new ArrayList!(LocalDateTime)(excludeDays);
        return clone;
    }

    /**
     * <p>
     * Get the array which defines the exclude-value of each day of month
     * </p>
     */
    ArrayList!(LocalDateTime) getDaysExcluded() {
        return excludeDays;
    }

    /**
     * <p>
     * Return true, if day is defined to be exluded.
     * </p>
     */
    bool isDayExcluded(LocalDateTime day) {

        if (day is null) {
            throw new IllegalArgumentException("Parameter day must not be null");
        }

         // Check baseCalendar first
        if (!super.isTimeIncluded(day.toEpochMilli())) {
         return true;
        } 
        
        int dmonth = day.getMonthValue();
        int dday = day.getDayOfMonth();


    // TODO: Tasks pending completion -@zxp at 12/24/2018, 6:40:42 PM
    // 
        if (dataSorted == false) {
            // Collections.sort(excludeDays, new CalendarComparator());
            excludeDays.sort(new CalendarComparator());
            dataSorted = true;
        }

        foreach(LocalDateTime ldt; excludeDays) {
            // remember, the list is sorted
            if (dmonth < ldt.getMonthValue()) {
                return false;
            }

            if (dday != ldt.getDayOfMonth()) {
                continue;
            }

            if (dmonth != ldt.getMonthValue()) {
                continue;
            }

            return true;
        }

        return false;
    }

    /**
     * <p>
     * Redefine the list of days excluded. The ArrayList 
     * should contain <code>LocalDateTime</code> objects. 
     * </p>
     */
    void setDaysExcluded(ArrayList!(LocalDateTime) days) {
        if (days is null) {
            excludeDays = new ArrayList!(LocalDateTime)();
        } else {
            excludeDays = days;
        }

        dataSorted = false;
    }

    /**
     * <p>
     * Redefine a certain day to be excluded (true) or included (false).
     * </p>
     */
    void setDayExcluded(LocalDateTime day, bool exclude) {
        if (exclude) {
            if (isDayExcluded(day)) {
                return;
            }

            excludeDays.add(day);
            dataSorted = false;
        } else {
            if (!isDayExcluded(day)) {
                return;
            }

            removeExcludedDay(day, true);
        }
    }

    /**
     * Remove the given day from the list of excluded days
     *  
     * @param day the day to exclude
     */
    void removeExcludedDay(LocalDateTime day) {
        removeExcludedDay(day, false);
    }
    
    private void removeExcludedDay(LocalDateTime day, bool isChecked) {
        if (! isChecked &&
            ! isDayExcluded(day)) {
            return;
        }
        
        // Fast way, see if exact day object was already in list
        if (this.excludeDays.remove(day)) {
            return;
        }
        
        int dmonth = day.getMonthValue();
        int dday = day.getDayOfMonth();
        
        // Since there is no guarantee that the given day is in the arraylist with the exact same year
        // search for the object based on month and day of month in the list and remove it
        foreach(LocalDateTime ldt; excludeDays) {

            if (dmonth != ldt.getMonthValue()) {
                continue;
            }

            if (dday != ldt.getDayOfMonth()) {
                continue;
            }

            day = ldt;
            break;
        }
        
        this.excludeDays.remove(day);
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
        // Test the base calendar first. Only if the base calendar not already
        // excludes the time/date, continue evaluating this calendar instance.
        if (super.isTimeIncluded(timeStamp) == false) { return false; }

        LocalDateTime day = createJavaCalendar(timeStamp);

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
        // Call base calendar implementation first
        long baseTime = super.getNextIncludedTime(timeStamp);
        if ((baseTime > 0) && (baseTime > timeStamp)) {
            timeStamp = baseTime;
        }

        // Get timestamp for 00:00:00
        LocalDateTime day = getStartOfDayJavaCalendar(timeStamp);
        if (isDayExcluded(day) == false) { 
            return timeStamp; // return the original value
        }

        while (isDayExcluded(day) == true) {
            day.plusDays(1);
        }

        return day.toEpochMilli();
    }
}


/**
*/
class CalendarComparator : Comparator!(LocalDateTime) { // hunt.text.
  
    
    this() {
    }


    int compare(LocalDateTime c1, LocalDateTime c2) nothrow {
        
        int month1 = c1.getMonthValue();
        int month2 = c2.getMonthValue();
        
        int day1 = c1.getDayOfMonth();
        int day2 = c2.getDayOfMonth();
        
        if (month1 < month2) {
            return -1;
        }
        if (month1 > month2) {
            return 1; 
        }
        if (day1 < day2) {
            return -1;
        }
        if (day1 > day2) {
            return 1;
        }
        return 0;
      }
}
