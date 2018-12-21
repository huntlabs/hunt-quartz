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

module hunt.quartz.DateBuilder;

import hunt.time.util.Calendar;
// import std.datetime;
import hunt.time.util.Locale;
import hunt.time.LocalDateTime;

import std.conv;
import std.datetime;

/**
 * <code>DateBuilder</code> is used to conveniently create 
 * <code>java.util.LocalDateTime</code> instances that meet particular criteria.
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
 *             .withSchedule(simpleSchedule()
 *                 .withIntervalInHours(1)
 *                 .repeatForever())
 *             .startAt(futureDate(10, MINUTES))
 *             .build();
 *         
 *         scheduler.scheduleJob(job, trigger);
 * <pre>
 *  
 * @see TriggerBuilder
 * @see JobBuilder 
 */
class DateBuilder {
    
    enum int SUNDAY = 1;

    enum int MONDAY = 2;

    enum int TUESDAY = 3;

    enum int WEDNESDAY = 4;

    enum int THURSDAY = 5;

    enum int FRIDAY = 6;

    enum int SATURDAY = 7;
    
    enum int JANUARY = 1;
    
    enum int FEBRUARY = 2;

    enum int MARCH = 3;

    enum int APRIL = 4;

    enum int MAY = 5;

    enum int JUNE = 6;

    enum int JULY = 7;

    enum int AUGUST = 8;

    enum int SEPTEMBER = 9;

    enum int OCTOBER = 10;

    enum int NOVEMBER = 11;

    enum int DECEMBER = 12;

    enum long MILLISECONDS_IN_MINUTE = 60 * 1000;

    enum long MILLISECONDS_IN_HOUR = 60 * 60 * 1000;

    enum long SECONDS_IN_MOST_DAYS = 24 * 60 * 60;

    enum long MILLISECONDS_IN_DAY = SECONDS_IN_MOST_DAYS * 1000;
    
    private int month;
    private int day;
    private int year;
    private int hour;
    private int minute;
    private int second;
    private TimeZone tz;
    private Locale lc;
    
    /**
     * Create a DateBuilder, with initial settings for the current date and time in the system default timezone.
     */
    private this() {
        Calendar cal = Calendar.getInstance();
        
        month = cal.get(Calendar.MONTH) + 1;
        day = cal.get(Calendar.DAY_OF_MONTH);
        year = cal.get(Calendar.YEAR);
        hour = cal.get(Calendar.HOUR_OF_DAY);
        minute = cal.get(Calendar.MINUTE);
        second = cal.get(Calendar.SECOND);
    }

    /**
     * Create a DateBuilder, with initial settings for the current date and time in the given timezone.
     */
    private this(TimeZone tz) {
        Calendar cal = Calendar.getInstance(tz);
        
        this.tz = tz;
        month = cal.get(Calendar.MONTH) + 1;
        day = cal.get(Calendar.DAY_OF_MONTH);
        year = cal.get(Calendar.YEAR);
        hour = cal.get(Calendar.HOUR_OF_DAY);
        minute = cal.get(Calendar.MINUTE);
        second = cal.get(Calendar.SECOND);
    }

    /**
     * Create a DateBuilder, with initial settings for the current date and time in the given locale.
     */
    private this(Locale lc) {
        Calendar cal = Calendar.getInstance(lc);
        
        this.lc = lc;
        month = cal.get(Calendar.MONTH) + 1;
        day = cal.get(Calendar.DAY_OF_MONTH);
        year = cal.get(Calendar.YEAR);
        hour = cal.get(Calendar.HOUR_OF_DAY);
        minute = cal.get(Calendar.MINUTE);
        second = cal.get(Calendar.SECOND);
    }

    /**
     * Create a DateBuilder, with initial settings for the current date and time in the given timezone and locale.
     */
    private this(TimeZone tz, Locale lc) {
        Calendar cal = Calendar.getInstance(tz, lc);
        
        this.tz = tz;
        this.lc = lc;
        month = cal.get(Calendar.MONTH) + 1;
        day = cal.get(Calendar.DAY_OF_MONTH);
        year = cal.get(Calendar.YEAR);
        hour = cal.get(Calendar.HOUR_OF_DAY);
        minute = cal.get(Calendar.MINUTE);
        second = cal.get(Calendar.SECOND);
    }

    /**
     * Create a DateBuilder, with initial settings for the current date and time in the system default timezone.
     */
    static DateBuilder newDate() {
        return new DateBuilder();
    }

    /**
     * Create a DateBuilder, with initial settings for the current date and time in the given timezone.
     */
    static DateBuilder newDateInTimezone(TimeZone tz) {
        return new DateBuilder(tz);
    }

    /**
     * Create a DateBuilder, with initial settings for the current date and time in the given locale.
     */
    static DateBuilder newDateInLocale(Locale lc) {
        return new DateBuilder(lc);
    }

    /**
     * Create a DateBuilder, with initial settings for the current date and time in the given timezone and locale.
     */
    static DateBuilder newDateInTimeZoneAndLocale(TimeZone tz, Locale lc) {
        return new DateBuilder(tz, lc);
    }

    /**
     * Build the LocalDateTime defined by this builder instance. 
     */
    LocalDateTime build() {
        Calendar cal;

        if(tz !is null && lc !is null)
            cal = Calendar.getInstance(tz, lc);
        else if(tz !is null)
            cal = Calendar.getInstance(tz);
        else if(lc !is null)
            cal = Calendar.getInstance(lc);
        else 
          cal = Calendar.getInstance();
        
        cal.set(Calendar.YEAR, year);
        cal.set(Calendar.MONTH, month - 1);
        cal.set(Calendar.DAY_OF_MONTH, day);
        cal.set(Calendar.HOUR_OF_DAY, hour);
        cal.set(Calendar.MINUTE, minute);
        cal.set(Calendar.SECOND, second);
        cal.set(Calendar.MILLISECOND, 0);
        
        return cal.getTime();
    }
    
    /**
     * Set the hour (0-23) for the LocalDateTime that will be built by this builder.
     */
    DateBuilder atHourOfDay(int atHour) {
        validateHour(atHour);
        
        this.hour = atHour;
        return this;
    }

    /**
     * Set the minute (0-59) for the LocalDateTime that will be built by this builder.
     */
    DateBuilder atMinute(int atMinute) {
        validateMinute(atMinute);
        
        this.minute = atMinute;
        return this;
    }

    /**
     * Set the second (0-59) for the LocalDateTime that will be built by this builder, and truncate the milliseconds to 000.
     */
    DateBuilder atSecond(int atSecond) {
        validateSecond(atSecond);
        
        this.second = atSecond;
        return this;
    }

    DateBuilder atHourMinuteAndSecond(int atHour, int atMinute, int atSecond) {
        validateHour(atHour);
        validateMinute(atMinute);
        validateSecond(atSecond);
        
        this.hour = atHour;
        this.second = atSecond;
        this.minute = atMinute;
        return this;
    }
    
    /**
     * Set the day of month (1-31) for the LocalDateTime that will be built by this builder.
     */
    DateBuilder onDay(int onDay) {
        validateDayOfMonth(onDay);
        
        this.day = onDay;
        return this;
    }

    /**
     * Set the month (1-12) for the LocalDateTime that will be built by this builder.
     */
    DateBuilder inMonth(int inMonth) {
        validateMonth(inMonth);
        
        this.month = inMonth;
        return this;
    }
    
    DateBuilder inMonthOnDay(int inMonth, int onDay) {
        validateMonth(inMonth);
        validateDayOfMonth(onDay);
        
        this.month = inMonth;
        this.day = onDay;
        return this;
    }

    /**
     * Set the year for the LocalDateTime that will be built by this builder.
     */
    DateBuilder inYear(int inYear) {
        validateYear(inYear);
        
        this.year = inYear;
        return this;
    }

    /**
     * Set the TimeZone for the LocalDateTime that will be built by this builder (if "null", system default will be used)
     */
    DateBuilder inTimeZone(TimeZone timezone) {
        this.tz = timezone;
        return this;
    }

    /**
     * Set the Locale for the LocalDateTime that will be built by this builder (if "null", system default will be used)
     */
    DateBuilder inLocale(Locale locale) {
        this.lc = locale;
        return this;
    }

    static LocalDateTime futureDate(int interval, IntervalUnit unit) {
        
        Calendar c = Calendar.getInstance();
        c.setTime(new LocalDateTime());
        c.setLenient(true);
        
        c.add(translate(unit), interval);

        return c.getTime();
    }
    

    private static int translate(IntervalUnit unit) {
        switch(unit) {
            case DAY : return Calendar.DAY_OF_YEAR;
            case HOUR : return Calendar.HOUR_OF_DAY;
            case MINUTE : return Calendar.MINUTE;
            case MONTH : return Calendar.MONTH;
            case SECOND : return Calendar.SECOND;
            case MILLISECOND : return Calendar.MILLISECOND;
            case WEEK : return Calendar.WEEK_OF_YEAR;
            case YEAR : return Calendar.YEAR;
            default : throw new IllegalArgumentException("Unknown IntervalUnit");
        }
    }

    /**
     * <p>
     * Get a <code>LocalDateTime</code> object that represents the given time, on
     * tomorrow's date.
     * </p>
     * 
     * @param second
     *          The value (0-59) to give the seconds field of the date
     * @param minute
     *          The value (0-59) to give the minutes field of the date
     * @param hour
     *          The value (0-23) to give the hours field of the date
     * @return the new date
     */
    static LocalDateTime tomorrowAt(int hour, int minute, int second) {
        validateSecond(second);
        validateMinute(minute);
        validateHour(hour);

        LocalDateTime date = new LocalDateTime();

        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.setLenient(true);

        // advance one day
        c.add(Calendar.DAY_OF_YEAR, 1);
        
        c.set(Calendar.HOUR_OF_DAY, hour);
        c.set(Calendar.MINUTE, minute);
        c.set(Calendar.SECOND, second);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }

    /**
     * <p>
     * Get a <code>LocalDateTime</code> object that represents the given time, on
     * today's date (equivalent to {@link #dateOf(int, int, int)}).
     * </p>
     * 
     * @param second
     *          The value (0-59) to give the seconds field of the date
     * @param minute
     *          The value (0-59) to give the minutes field of the date
     * @param hour
     *          The value (0-23) to give the hours field of the date
     * @return the new date
     */
    static LocalDateTime todayAt(int hour, int minute, int second) {
        return dateOf(hour, minute, second);
    }
    
    /**
     * <p>
     * Get a <code>LocalDateTime</code> object that represents the given time, on
     * today's date  (equivalent to {@link #todayAt(int, int, int)}).
     * </p>
     * 
     * @param second
     *          The value (0-59) to give the seconds field of the date
     * @param minute
     *          The value (0-59) to give the minutes field of the date
     * @param hour
     *          The value (0-23) to give the hours field of the date
     * @return the new date
     */
    static LocalDateTime dateOf(int hour, int minute, int second) {
        validateSecond(second);
        validateMinute(minute);
        validateHour(hour);

        LocalDateTime date = new LocalDateTime();

        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.setLenient(true);

        c.set(Calendar.HOUR_OF_DAY, hour);
        c.set(Calendar.MINUTE, minute);
        c.set(Calendar.SECOND, second);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }

    /**
     * <p>
     * Get a <code>LocalDateTime</code> object that represents the given time, on the
     * given date.
     * </p>
     * 
     * @param second
     *          The value (0-59) to give the seconds field of the date
     * @param minute
     *          The value (0-59) to give the minutes field of the date
     * @param hour
     *          The value (0-23) to give the hours field of the date
     * @param dayOfMonth
     *          The value (1-31) to give the day of month field of the date
     * @param month
     *          The value (1-12) to give the month field of the date
     * @return the new date
     */
    static LocalDateTime dateOf(int hour, int minute, int second,
            int dayOfMonth, int month) {
        validateSecond(second);
        validateMinute(minute);
        validateHour(hour);
        validateDayOfMonth(dayOfMonth);
        validateMonth(month);

        LocalDateTime date = new LocalDateTime();

        Calendar c = Calendar.getInstance();
        c.setTime(date);

        c.set(Calendar.MONTH, month - 1);
        c.set(Calendar.DAY_OF_MONTH, dayOfMonth);
        c.set(Calendar.HOUR_OF_DAY, hour);
        c.set(Calendar.MINUTE, minute);
        c.set(Calendar.SECOND, second);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }

    /**
     * <p>
     * Get a <code>LocalDateTime</code> object that represents the given time, on the
     * given date.
     * </p>
     * 
     * @param second
     *          The value (0-59) to give the seconds field of the date
     * @param minute
     *          The value (0-59) to give the minutes field of the date
     * @param hour
     *          The value (0-23) to give the hours field of the date
     * @param dayOfMonth
     *          The value (1-31) to give the day of month field of the date
     * @param month
     *          The value (1-12) to give the month field of the date
     * @param year
     *          The value (1970-2099) to give the year field of the date
     * @return the new date
     */
    static LocalDateTime dateOf(int hour, int minute, int second,
            int dayOfMonth, int month, int year) {
        validateSecond(second);
        validateMinute(minute);
        validateHour(hour);
        validateDayOfMonth(dayOfMonth);
        validateMonth(month);
        validateYear(year);

        LocalDateTime date = new LocalDateTime();

        Calendar c = Calendar.getInstance();
        c.setTime(date);

        c.set(Calendar.YEAR, year);
        c.set(Calendar.MONTH, month - 1);
        c.set(Calendar.DAY_OF_MONTH, dayOfMonth);
        c.set(Calendar.HOUR_OF_DAY, hour);
        c.set(Calendar.MINUTE, minute);
        c.set(Calendar.SECOND, second);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }


    /**
     * <p>
     * Returns a date that is rounded to the next even hour after the current time.
     * </p>
     * 
     * <p>
     * For example a current time of 08:13:54 would result in a date
     * with the time of 09:00:00. If the date's time is in the 23rd hour, the
     * date's 'day' will be promoted, and the time will be set to 00:00:00.
     * </p>
     * 
     * @return the new rounded date
     */
    static LocalDateTime evenHourDateAfterNow() {
        return evenHourDate(null);
    }
    /**
     * <p>
     * Returns a date that is rounded to the next even hour above the given
     * date.
     * </p>
     * 
     * <p>
     * For example an input date with a time of 08:13:54 would result in a date
     * with the time of 09:00:00. If the date's time is in the 23rd hour, the
     * date's 'day' will be promoted, and the time will be set to 00:00:00.
     * </p>
     * 
     * @param date
     *          the LocalDateTime to round, if <code>null</code> the current time will
     *          be used
     * @return the new rounded date
     */
    static LocalDateTime evenHourDate(LocalDateTime date) {
        if (date is null) {
            date = new LocalDateTime();
        }

        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.setLenient(true);

        c.set(Calendar.HOUR_OF_DAY, c.get(Calendar.HOUR_OF_DAY) + 1);
        c.set(Calendar.MINUTE, 0);
        c.set(Calendar.SECOND, 0);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }

    /**
     * <p>
     * Returns a date that is rounded to the previous even hour below the given
     * date.
     * </p>
     * 
     * <p>
     * For example an input date with a time of 08:13:54 would result in a date
     * with the time of 08:00:00.
     * </p>
     * 
     * @param date
     *          the LocalDateTime to round, if <code>null</code> the current time will
     *          be used
     * @return the new rounded date
     */
    static LocalDateTime evenHourDateBefore(LocalDateTime date) {
        if (date is null) {
            date = new LocalDateTime();
        }

        Calendar c = Calendar.getInstance();
        c.setTime(date);

        c.set(Calendar.MINUTE, 0);
        c.set(Calendar.SECOND, 0);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }

    /**
     * <p>
     * Returns a date that is rounded to the next even minute after the current time.
     * </p>
     * 
     * <p>
     * For example a current time of 08:13:54 would result in a date
     * with the time of 08:14:00. If the date's time is in the 59th minute,
     * then the hour (and possibly the day) will be promoted.
     * </p>
     * 
     * @return the new rounded date
     */
    static LocalDateTime evenMinuteDateAfterNow() {
        return evenMinuteDate(null);
    }
    
    /**
     * <p>
     * Returns a date that is rounded to the next even minute above the given
     * date.
     * </p>
     * 
     * <p>
     * For example an input date with a time of 08:13:54 would result in a date
     * with the time of 08:14:00. If the date's time is in the 59th minute,
     * then the hour (and possibly the day) will be promoted.
     * </p>
     * 
     * @param date
     *          the LocalDateTime to round, if <code>null</code> the current time will
     *          be used
     * @return the new rounded date
     */
    static LocalDateTime evenMinuteDate(LocalDateTime date) {
        if (date is null) {
            date = new LocalDateTime();
        }

        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.setLenient(true);

        c.set(Calendar.MINUTE, c.get(Calendar.MINUTE) + 1);
        c.set(Calendar.SECOND, 0);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }

    /**
     * <p>
     * Returns a date that is rounded to the previous even minute below the 
     * given date.
     * </p>
     * 
     * <p>
     * For example an input date with a time of 08:13:54 would result in a date
     * with the time of 08:13:00.
     * </p>
     * 
     * @param date
     *          the LocalDateTime to round, if <code>null</code> the current time will
     *          be used
     * @return the new rounded date
     */
    static LocalDateTime evenMinuteDateBefore(LocalDateTime date) {
        if (date is null) {
            date = new LocalDateTime();
        }

        Calendar c = Calendar.getInstance();
        c.setTime(date);

        c.set(Calendar.SECOND, 0);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }

    /**
     * <p>
     * Returns a date that is rounded to the next even second after the current time.
     * </p>
     * 
     * @return the new rounded date
     */
    static LocalDateTime evenSecondDateAfterNow() {
        return evenSecondDate(null);
    }
    /**
     * <p>
     * Returns a date that is rounded to the next even second above the given
     * date.
     * </p>
     * 
     * @param date
     *          the LocalDateTime to round, if <code>null</code> the current time will
     *          be used
     * @return the new rounded date
     */
    static LocalDateTime evenSecondDate(LocalDateTime date) {
        if (date is null) {
            date = new LocalDateTime();
        }

        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.setLenient(true);

        c.set(Calendar.SECOND, c.get(Calendar.SECOND) + 1);
        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }

    /**
     * <p>
     * Returns a date that is rounded to the previous even second below the
     * given date.
     * </p>
     * 
     * <p>
     * For example an input date with a time of 08:13:54.341 would result in a
     * date with the time of 08:13:54.000.
     * </p>
     * 
     * @param date
     *          the LocalDateTime to round, if <code>null</code> the current time will
     *          be used
     * @return the new rounded date
     */
    static LocalDateTime evenSecondDateBefore(LocalDateTime date) {
        if (date is null) {
            date = new LocalDateTime();
        }

        Calendar c = Calendar.getInstance();
        c.setTime(date);

        c.set(Calendar.MILLISECOND, 0);

        return c.getTime();
    }
    
    /**
     * <p>
     * Returns a date that is rounded to the next even multiple of the given
     * minute.
     * </p>
     * 
     * <p>
     * For example an input date with a time of 08:13:54, and an input
     * minute-base of 5 would result in a date with the time of 08:15:00. The
     * same input date with an input minute-base of 10 would result in a date
     * with the time of 08:20:00. But a date with the time 08:53:31 and an
     * input minute-base of 45 would result in 09:00:00, because the even-hour
     * is the next 'base' for 45-minute intervals.
     * </p>
     * 
     * <p>
     * More examples: <table>
     * <tr>
     * <th>Input Time</th>
     * <th>Minute-Base</th>
     * <th>Result Time</th>
     * </tr>
     * <tr>
     * <td>11:16:41</td>
     * <td>20</td>
     * <td>11:20:00</td>
     * </tr>
     * <tr>
     * <td>11:36:41</td>
     * <td>20</td>
     * <td>11:40:00</td>
     * </tr>
     * <tr>
     * <td>11:46:41</td>
     * <td>20</td>
     * <td>12:00:00</td>
     * </tr>
     * <tr>
     * <td>11:26:41</td>
     * <td>30</td>
     * <td>11:30:00</td>
     * </tr>
     * <tr>
     * <td>11:36:41</td>
     * <td>30</td>
     * <td>12:00:00</td>
     * </tr>
     * <td>11:16:41</td>
     * <td>17</td>
     * <td>11:17:00</td>
     * </tr>
     * </tr>
     * <td>11:17:41</td>
     * <td>17</td>
     * <td>11:34:00</td>
     * </tr>
     * </tr>
     * <td>11:52:41</td>
     * <td>17</td>
     * <td>12:00:00</td>
     * </tr>
     * </tr>
     * <td>11:52:41</td>
     * <td>5</td>
     * <td>11:55:00</td>
     * </tr>
     * </tr>
     * <td>11:57:41</td>
     * <td>5</td>
     * <td>12:00:00</td>
     * </tr>
     * </tr>
     * <td>11:17:41</td>
     * <td>0</td>
     * <td>12:00:00</td>
     * </tr>
     * </tr>
     * <td>11:17:41</td>
     * <td>1</td>
     * <td>11:08:00</td>
     * </tr>
     * </table>
     * </p>
     * 
     * @param date
     *          the LocalDateTime to round, if <code>null</code> the current time will
     *          be used
     * @param minuteBase
     *          the base-minute to set the time on
     * @return the new rounded date
     * 
     * @see #nextGivenSecondDate(LocalDateTime, int)
     */
    static LocalDateTime nextGivenMinuteDate(LocalDateTime date, int minuteBase) {
        if (minuteBase < 0 || minuteBase > 59) {
            throw new IllegalArgumentException(
                    "minuteBase must be >=0 and <= 59");
        }

        if (date is null) {
            date = new LocalDateTime();
        }

        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.setLenient(true);

        if (minuteBase == 0) {
            c.set(Calendar.HOUR_OF_DAY, c.get(Calendar.HOUR_OF_DAY) + 1);
            c.set(Calendar.MINUTE, 0);
            c.set(Calendar.SECOND, 0);
            c.set(Calendar.MILLISECOND, 0);

            return c.getTime();
        }

        int minute = c.get(Calendar.MINUTE);

        int arItr = minute / minuteBase;

        int nextMinuteOccurance = minuteBase * (arItr + 1);

        if (nextMinuteOccurance < 60) {
            c.set(Calendar.MINUTE, nextMinuteOccurance);
            c.set(Calendar.SECOND, 0);
            c.set(Calendar.MILLISECOND, 0);

            return c.getTime();
        } else {
            c.set(Calendar.HOUR_OF_DAY, c.get(Calendar.HOUR_OF_DAY) + 1);
            c.set(Calendar.MINUTE, 0);
            c.set(Calendar.SECOND, 0);
            c.set(Calendar.MILLISECOND, 0);

            return c.getTime();
        }
    }
    
    /**
     * <p>
     * Returns a date that is rounded to the next even multiple of the given
     * minute.
     * </p>
     * 
     * <p>
     * The rules for calculating the second are the same as those for
     * calculating the minute in the method 
     * <code>getNextGivenMinuteDate(..)<code>.
     * </p>
     *
     * @param date the LocalDateTime to round, if <code>null</code> the current time will
     * be used
     * @param secondBase the base-second to set the time on
     * @return the new rounded date
     * 
     * @see #nextGivenMinuteDate(LocalDateTime, int)
     */
    static LocalDateTime nextGivenSecondDate(LocalDateTime date, int secondBase) {
        if (secondBase < 0 || secondBase > 59) {
            throw new IllegalArgumentException(
                    "secondBase must be >=0 and <= 59");
        }

        if (date is null) {
            date = new LocalDateTime();
        }

        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.setLenient(true);

        if (secondBase == 0) {
            c.set(Calendar.MINUTE, c.get(Calendar.MINUTE) + 1);
            c.set(Calendar.SECOND, 0);
            c.set(Calendar.MILLISECOND, 0);

            return c.getTime();
        }

        int second = c.get(Calendar.SECOND);

        int arItr = second / secondBase;

        int nextSecondOccurance = secondBase * (arItr + 1);

        if (nextSecondOccurance < 60) {
            c.set(Calendar.SECOND, nextSecondOccurance);
            c.set(Calendar.MILLISECOND, 0);

            return c.getTime();
        } else {
            c.set(Calendar.MINUTE, c.get(Calendar.MINUTE) + 1);
            c.set(Calendar.SECOND, 0);
            c.set(Calendar.MILLISECOND, 0);

            return c.getTime();
        }
    }

    /**
     * Translate a date & time from a users time zone to the another
     * (probably server) time zone to assist in creating a simple trigger with 
     * the right date & time.
     * 
     * @param date the date to translate
     * @param src the original time-zone
     * @param dest the destination time-zone
     * @return the translated date
     */
    static LocalDateTime translateTime(LocalDateTime date, TimeZone src, TimeZone dest) {

        LocalDateTime newDate = new LocalDateTime();

        int offset = (dest.getOffset(date.getTime()) - src.getOffset(date.getTime()));

        newDate.setTime(date.getTime() - offset);

        return newDate;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    static void validateDayOfWeek(int dayOfWeek) {
        if (dayOfWeek < SUNDAY || dayOfWeek > SATURDAY) {
            throw new IllegalArgumentException("Invalid day of week.");
        }
    }

    static void validateHour(int hour) {
        if (hour < 0 || hour > 23) {
            throw new IllegalArgumentException(
                    "Invalid hour (must be >= 0 and <= 23).");
        }
    }

    static void validateMinute(int minute) {
        if (minute < 0 || minute > 59) {
            throw new IllegalArgumentException(
                    "Invalid minute (must be >= 0 and <= 59).");
        }
    }

    static void validateSecond(int second) {
        if (second < 0 || second > 59) {
            throw new IllegalArgumentException(
                    "Invalid second (must be >= 0 and <= 59).");
        }
    }

    static void validateDayOfMonth(int day) {
        if (day < 1 || day > 31) {
            throw new IllegalArgumentException("Invalid day of month.");
        }
    }

    static void validateMonth(int month) {
        if (month < 1 || month > 12) {
            throw new IllegalArgumentException(
                    "Invalid month (must be >= 1 and <= 12.");
        }
    }

    // private enum int MAX_YEAR = Calendar.getInstance().get(Calendar.YEAR) + 100;
    private enum int MAX_YEAR = 2018 + 100;
    static void validateYear(int year) {
        if (year < 0 || year > MAX_YEAR) {
            throw new IllegalArgumentException(
                    "Invalid year (must be >= 0 and <= " ~ MAX_YEAR.to!string());
        }
    }

}

enum IntervalUnit { MILLISECOND, SECOND, MINUTE, HOUR, DAY, WEEK, MONTH, YEAR }
