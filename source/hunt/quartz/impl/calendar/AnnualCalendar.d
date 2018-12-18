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

import hunt.container.ArrayList;
import hunt.container.Collections;
import hunt.container.Iterator;
import hunt.time.util.Calendar;
import hunt.util.Comparator;
import std.datetime : TimeZone;

import hunt.quartz.Calendar;

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
class AnnualCalendar : BaseCalendar, hunt.quartz.Calendar {


    private ArrayList!(hunt.time.util.Calendar) excludeDays;

    // true, if excludeDays is sorted
    private bool dataSorted = false;

    this() {
    }

    this(Calendar baseCalendar) {
        super(baseCalendar);
    }

    this(TimeZone timeZone) {
        super(timeZone);
    }

    this(Calendar baseCalendar, TimeZone timeZone) {
        super(baseCalendar, timeZone);
    }

    private void initialize() {
        excludeDays = new ArrayList!(hunt.time.util.Calendar)();
    }

    // override
    // Object clone() {
    //     AnnualCalendar clone = (AnnualCalendar) super.clone();
    //     clone.excludeDays = new ArrayList!(hunt.time.util.Calendar)(excludeDays);
    //     return clone;
    // }

    /**
     * <p>
     * Get the array which defines the exclude-value of each day of month
     * </p>
     */
    ArrayList!(hunt.time.util.Calendar) getDaysExcluded() {
        return excludeDays;
    }

    /**
     * <p>
     * Return true, if day is defined to be exluded.
     * </p>
     */
    bool isDayExcluded(hunt.time.util.Calendar day) {

        if (day is null) {
            throw new IllegalArgumentException("Parameter day must not be null");
        }

         // Check baseCalendar first
        if (!super.isTimeIncluded(day.getTime().getTime())) {
         return true;
        } 
        
        int dmonth = day.get(hunt.time.util.Calendar.MONTH);
        int dday = day.get(hunt.time.util.Calendar.DAY_OF_MONTH);

        if (dataSorted == false) {
            Collections.sort(excludeDays, new CalendarComparator());
            dataSorted = true;
        }

        Iterator!(hunt.time.util.Calendar) iter = excludeDays.iterator();
        while (iter.hasNext()) {
            hunt.time.util.Calendar cl = (hunt.time.util.Calendar) iter.next();

            // remember, the list is sorted
            if (dmonth < cl.get(hunt.time.util.Calendar.MONTH)) {
                return false;
            }

            if (dday != cl.get(hunt.time.util.Calendar.DAY_OF_MONTH)) {
                continue;
            }

            if (dmonth != cl.get(hunt.time.util.Calendar.MONTH)) {
                continue;
            }

            return true;
        }

        return false;
    }

    /**
     * <p>
     * Redefine the list of days excluded. The ArrayList 
     * should contain <code>hunt.time.util.Calendar</code> objects. 
     * </p>
     */
    void setDaysExcluded(ArrayList!(hunt.time.util.Calendar) days) {
        if (days is null) {
            excludeDays = new ArrayList!(hunt.time.util.Calendar)();
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
    void setDayExcluded(hunt.time.util.Calendar day, bool exclude) {
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
    void removeExcludedDay(hunt.time.util.Calendar day) {
        removeExcludedDay(day, false);
    }
    
    private void removeExcludedDay(hunt.time.util.Calendar day, bool isChecked) {
        if (! isChecked &&
            ! isDayExcluded(day)) {
            return;
        }
        
        // Fast way, see if exact day object was already in list
        if (this.excludeDays.remove(day)) {
            return;
        }
        
        int dmonth = day.get(hunt.time.util.Calendar.MONTH);
        int dday = day.get(hunt.time.util.Calendar.DAY_OF_MONTH);
        
        // Since there is no guarantee that the given day is in the arraylist with the exact same year
        // search for the object based on month and day of month in the list and remove it
        Iterator!(hunt.time.util.Calendar) iter = excludeDays.iterator();
        while (iter.hasNext()) {
            hunt.time.util.Calendar cl = (hunt.time.util.Calendar) iter.next();

            if (dmonth != cl.get(hunt.time.util.Calendar.MONTH)) {
                continue;
            }

            if (dday != cl.get(hunt.time.util.Calendar.DAY_OF_MONTH)) {
                continue;
            }

            day = cl;
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

        hunt.time.util.Calendar day = createJavaCalendar(timeStamp);

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
        hunt.time.util.Calendar day = getStartOfDayJavaCalendar(timeStamp);
        if (isDayExcluded(day) == false) { 
            return timeStamp; // return the original value
        }

        while (isDayExcluded(day) == true) {
            day.add(hunt.time.util.Calendar.DATE, 1);
        }

        return day.getTime().getTime();
    }
}

class CalendarComparator : Comparator!(hunt.time.util.Calendar), Serializable {
  
    
    CalendarComparator() {
    }


    int compare(hunt.time.util.Calendar c1, hunt.time.util.Calendar c2) {
        
        int month1 = c1.get(hunt.time.util.Calendar.MONTH);
        int month2 = c2.get(hunt.time.util.Calendar.MONTH);
        
        int day1 = c1.get(hunt.time.util.Calendar.DAY_OF_MONTH);
        int day2 = c2.get(hunt.time.util.Calendar.DAY_OF_MONTH);
        
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
