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

module hunt.quartz.impl.calendar.BaseCalendar;

import hunt.quartz.Calendar;

import hunt.io.common;
import hunt.lang.common;
// import hunt.time.util.Calendar;
import hunt.time.ZoneId;

import std.datetime;

/**
 * <p>
 * This implementation of the Calendar may be used (you don't have to) as a
 * base class for more sophisticated one's. It merely implements the base
 * functionality required by each Calendar.
 * </p>
 *
 * <p>
 * Regarded as base functionality is the treatment of base calendars. Base
 * calendar allow you to chain (stack) as much calendars as you may need. For
 * example to exclude weekends you may use WeeklyCalendar. In order to exclude
 * holidays as well you may define a WeeklyCalendar instance to be the base
 * calendar for HolidayCalendar instance.
 * </p>
 *
 * @see hunt.quartz.Calendar
 *
 * @author Juergen Donnerstag
 * @author James House
 */
class BaseCalendar : QuartzCalendar, Serializable, Cloneable {


    // <p>A optional base calendar.</p>
    private QuartzCalendar baseCalendar;

    private string description;

    private ZoneId timeZone;

    this() {
    }

    this(QuartzCalendar baseCalendar) {
        setBaseCalendar(baseCalendar);
    }

    /**
     * @param timeZone The time zone to use for this Calendar, <code>null</code>
     * if <code>{@link ZoneId#getDefault()}</code> should be used
     */
    this(ZoneId timeZone) {
        setTimeZone(timeZone);
    }

    /**
     * @param timeZone The time zone to use for this Calendar, <code>null</code>
     * if <code>{@link ZoneId#getDefault()}</code> should be used
     */
    this(QuartzCalendar baseCalendar, ZoneId timeZone) {
        setBaseCalendar(baseCalendar);
        setTimeZone(timeZone);
    }

    // override
    // Object clone()  {
    //     try {
    //         BaseCalendar clone = (BaseCalendar) super.clone();
    //         if (getBaseCalendar() !is null) {
    //             clone.baseCalendar = (Calendar) getBaseCalendar().clone();
    //         }
    //         if(getTimeZone() !is null)
    //             clone.timeZone = (ZoneId) getTimeZone().clone();
    //         return clone;
    //     } catch (CloneNotSupportedException ex) {
    //         throw new IncompatibleClassChangeError("Not Cloneable.");
    //     }
    // }

    /**
     * <p>
     * Set a new base calendar or remove the existing one
     * </p>
     */
    void setBaseCalendar(QuartzCalendar baseCalendar) {
        this.baseCalendar = baseCalendar;
    }

    /**
     * <p>
     * Get the base calendar. Will be null, if not set.
     * </p>
     */
    QuartzCalendar getBaseCalendar() {
        return this.baseCalendar;
    }

    /**
     * <p>
     * Return the description given to the <code>Calendar</code> instance by
     * its creator (if any).
     * </p>
     *
     * @return null if no description was set.
     */
    string getDescription() {
        return description;
    }

    /**
     * <p>
     * Set a description for the <code>Calendar</code> instance - may be
     * useful for remembering/displaying the purpose of the calendar, though
     * the description has no meaning to Quartz.
     * </p>
     */
    void setDescription(string description) {
        this.description = description;
    }

    /**
     * Returns the time zone for which this <code>Calendar</code> will be
     * resolved.
     *
     * @return This Calendar's timezone, <code>null</code> if Calendar should
     * use the <code>{@link ZoneId#getDefault()}</code>
     */
    ZoneId getTimeZone() {
        return timeZone;
    }

    /**
     * Sets the time zone for which this <code>Calendar</code> will be resolved.
     *
     * @param timeZone The time zone to use for this Calendar, <code>null</code>
     * if <code>{@link ZoneId#getDefault()}</code> should be used
     */
    void setTimeZone(ZoneId timeZone) {
        this.timeZone = timeZone;
    }

    /**
     * <p>
     * Check if date/time represented by timeStamp is included. If included
     * return true. The implementation of BaseCalendar simply calls the base
     * calendars isTimeIncluded() method if base calendar is set.
     * </p>
     *
     * @see hunt.quartz.Calendar#isTimeIncluded(long)
     */
    bool isTimeIncluded(long timeStamp) {

        if (timeStamp <= 0) {
            throw new IllegalArgumentException(
                    "timeStamp must be greater 0");
        }

        if (baseCalendar !is null) {
            if (baseCalendar.isTimeIncluded(timeStamp) == false) { return false; }
        }

        return true;
    }

    /**
     * <p>
     * Determine the next time (in milliseconds) that is 'included' by the
     * Calendar after the given time. Return the original value if timeStamp is
     * included. Return 0 if all days are excluded.
     * </p>
     *
     * @see hunt.quartz.Calendar#getNextIncludedTime(long)
     */
    long getNextIncludedTime(long timeStamp) {

        if (timeStamp <= 0) {
            throw new IllegalArgumentException(
                    "timeStamp must be greater 0");
        }

        if (baseCalendar !is null) {
            return baseCalendar.getNextIncludedTime(timeStamp);
        }

        return timeStamp;
    }

    /**
     * Build a <code>{@link LocalDateTime}</code> for the given timeStamp.
     * The new Calendar will use the <code>BaseCalendar</code> time zone if it
     * is not <code>null</code>.
     */
    protected LocalDateTime createJavaCalendar(long timeStamp) {
        LocalDateTime calendar = createJavaCalendar();
        calendar.setTime(new LocalDateTime(timeStamp));
        return calendar;
    }

    /**
     * Build a <code>{@link LocalDateTime}</code> with the current time.
     * The new Calendar will use the <code>BaseCalendar</code> time zone if
     * it is not <code>null</code>.
     */
    protected LocalDateTime createJavaCalendar() {
        return
            (getTimeZone() is null) ?
                LocalDateTime.getInstance() :
                LocalDateTime.getInstance(getTimeZone());
    }

    /**
     * Returns the start of the given day as a <code>{@link LocalDateTime}</code>.
     * This calculation will take the <code>BaseCalendar</code>
     * time zone into account if it is not <code>null</code>.
     *
     * @param timeInMillis A time containing the desired date for the
     *                     start-of-day time
     * @return A <code>{@link LocalDateTime}</code> set to the start of
     *         the given day.
     */
    protected LocalDateTime getStartOfDayJavaCalendar(long timeInMillis) {
        LocalDateTime startOfDay = createJavaCalendar(timeInMillis);
        startOfDay.set(LocalDateTime.HOUR_OF_DAY, 0);
        startOfDay.set(LocalDateTime.MINUTE, 0);
        startOfDay.set(LocalDateTime.SECOND, 0);
        startOfDay.set(LocalDateTime.MILLISECOND, 0);
        return startOfDay;
    }

    /**
     * Returns the end of the given day <code>{@link LocalDateTime}</code>.
     * This calculation will take the <code>BaseCalendar</code>
     * time zone into account if it is not <code>null</code>.
     *
     * @param timeInMillis a time containing the desired date for the
     *                     end-of-day time.
     * @return A <code>{@link LocalDateTime}</code> set to the end of
     *         the given day.
     */
    protected LocalDateTime getEndOfDayJavaCalendar(long timeInMillis) {
        LocalDateTime endOfDay = createJavaCalendar(timeInMillis);
        endOfDay.set(LocalDateTime.HOUR_OF_DAY, 23);
        endOfDay.set(LocalDateTime.MINUTE, 59);
        endOfDay.set(LocalDateTime.SECOND, 59);
        endOfDay.set(LocalDateTime.MILLISECOND, 999);
        return endOfDay;
    }
}
