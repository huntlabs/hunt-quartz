module hunt.quartz.impl.calendar.DailyCalendar;

import hunt.quartz.impl.calendar.BaseCalendar;
import hunt.quartz.Calendar;

// import java.text.NumberFormat;
import hunt.collection.ArrayList;
import hunt.collection.StringBuffer;
import hunt.Exceptions;
import hunt.text.StringTokenizer;
// import hunt.time.util.Calendar;
import hunt.time.LocalTime;
import hunt.time.LocalDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;

import std.conv;
import std.format;

/**
 * This implementation of the Calendar excludes (or includes - see below) a 
 * specified time range each day. For example, you could use this calendar to 
 * exclude business hours (8AM - 5PM) every day. Each <CODE>DailyCalendar</CODE>
 * only allows a single time range to be specified, and that time range may not
 * cross daily boundaries (i.e. you cannot specify a time range from 8PM - 5AM).
 * If the property <CODE>invertTimeRange</CODE> is <CODE>false</CODE> (default), 
 * the time range defines a range of times in which triggers are not allowed to
 * fire. If <CODE>invertTimeRange</CODE> is <CODE>true</CODE>, the time range
 * is inverted &ndash; that is, all times <I>outside</I> the defined time range
 * are excluded.
 * <P>
 * Note when using <CODE>DailyCalendar</CODE>, it behaves on the same principals
 * as, for example, {@link hunt.quartz.impl.calendar.WeeklyCalendar 
 * WeeklyCalendar}. <CODE>WeeklyCalendar</CODE> defines a set of days that are
 * excluded <I>every week</I>. Likewise, <CODE>DailyCalendar</CODE> defines a 
 * set of times that are excluded <I>every day</I>.
 * 
 * @author Mike Funk, Aaron Craven
 */
class DailyCalendar : BaseCalendar {
    
    private enum string invalidHourOfDay = "Invalid hour of day: ";
    private enum string invalidMinute = "Invalid minute: ";
    private enum string invalidSecond = "Invalid second: ";
    private enum string invalidMillis = "Invalid millis: ";
    private enum string invalidTimeRange = "Invalid time range: ";
    private enum string separator = " - ";
    private enum long oneMillis = 1;
    private enum string colon = ":";

    private int rangeStartingHourOfDay;
    private int rangeStartingMinute;
    private int rangeStartingSecond;
    private int rangeStartingMillis;
    private int rangeEndingHourOfDay;
    private int rangeEndingMinute;
    private int rangeEndingSecond;
    private int rangeEndingMillis;
    
    private bool invertTimeRange = false;

    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified strings and no <CODE>baseCalendar</CODE>. 
     * <CODE>rangeStartingTime</CODE> and <CODE>rangeEndingTime</CODE>
     * must be in the format &quot;HH:MM[:SS[:mmm]]&quot; where:
     * <UL><LI>HH is the hour of the specified time. The hour should be
     *         specified using military (24-hour) time and must be in the range
     *         0 to 23.</LI>
     *     <LI>MM is the minute of the specified time and must be in the range
     *         0 to 59.</LI>
     *     <LI>SS is the second of the specified time and must be in the range
     *         0 to 59.</LI>
     *     <LI>mmm is the millisecond of the specified time and must be in the
     *         range 0 to 999.</LI>
     *     <LI>items enclosed in brackets ('[', ']') are optional.</LI>
     *     <LI>The time range starting time must be before the time range ending
     *         time. Note this means that a time range may not cross daily 
     *         boundaries (10PM - 2AM)</LI>  
     * </UL>
     * 
     * <p>
     * <b>Note:</b> This <CODE>DailyCalendar</CODE> will use the 
     * <code>{@link ZoneId#getDefault()}</code> time zone unless an explicit 
     * time zone is set via <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code>
     * </p>
     *  
     * @param rangeStartingTime a string representing the starting time for the
     *                          time range
     * @param rangeEndingTime   a string representing the ending time for the
     *                          the time range
     */
    this(string rangeStartingTime,
                         string rangeEndingTime) {
        super();
        setTimeRange(rangeStartingTime, rangeEndingTime);
    }

    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified strings and the specified <CODE>baseCalendar</CODE>. 
     * <CODE>rangeStartingTime</CODE> and <CODE>rangeEndingTime</CODE>
     * must be in the format &quot;HH:MM[:SS[:mmm]]&quot; where:
     * <UL><LI>HH is the hour of the specified time. The hour should be
     *         specified using military (24-hour) time and must be in the range
     *         0 to 23.</LI>
     *     <LI>MM is the minute of the specified time and must be in the range
     *         0 to 59.</LI>
     *     <LI>SS is the second of the specified time and must be in the range
     *         0 to 59.</LI>
     *     <LI>mmm is the millisecond of the specified time and must be in the
     *         range 0 to 999.</LI>
     *     <LI>items enclosed in brackets ('[', ']') are optional.</LI>
     *     <LI>The time range starting time must be before the time range ending
     *         time. Note this means that a time range may not cross daily 
     *         boundaries (10PM - 2AM)</LI>  
     * </UL>
     * 
     * <p>
     * <b>Note:</b> This <CODE>DailyCalendar</CODE> will use the 
     * <code>{@link ZoneId#getDefault()}</code> time zone unless an explicit 
     * time zone is set via <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code>
     * </p>
     * 
     * @param baseCalendar      the base calendar for this calendar instance
     *                          &ndash; see {@link BaseCalendar} for more
     *                          information on base calendar functionality
     * @param rangeStartingTime a string representing the starting time for the
     *                          time range
     * @param rangeEndingTime   a string representing the ending time for the
     *                          time range
     */
    this(QuartzCalendar baseCalendar,
                         string rangeStartingTime,
                         string rangeEndingTime) {
        super(baseCalendar);
        setTimeRange(rangeStartingTime, rangeEndingTime);
    }

    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified values and no <CODE>baseCalendar</CODE>. Values are subject to
     * the following validations:
     * <UL><LI>Hours must be in the range 0-23 and are expressed using military
     *         (24-hour) time.</LI>
     *     <LI>Minutes must be in the range 0-59</LI>
     *     <LI>Seconds must be in the range 0-59</LI>
     *     <LI>Milliseconds must be in the range 0-999</LI>
     *     <LI>The time range starting time must be before the time range ending
     *         time. Note this means that a time range may not cross daily 
     *         boundaries (10PM - 2AM)</LI>  
     * </UL>
     * 
     * <p>
     * <b>Note:</b> This <CODE>DailyCalendar</CODE> will use the 
     * <code>{@link ZoneId#getDefault()}</code> time zone unless an explicit 
     * time zone is set via <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code>
     * </p>
     * 
     * @param rangeStartingHourOfDay the hour of the start of the time range
     * @param rangeStartingMinute    the minute of the start of the time range
     * @param rangeStartingSecond    the second of the start of the time range
     * @param rangeStartingMillis    the millisecond of the start of the time 
     *                               range
     * @param rangeEndingHourOfDay   the hour of the end of the time range
     * @param rangeEndingMinute      the minute of the end of the time range
     * @param rangeEndingSecond      the second of the end of the time range
     * @param rangeEndingMillis      the millisecond of the start of the time 
     *                               range
     */
    this(int rangeStartingHourOfDay,
                         int rangeStartingMinute,
                         int rangeStartingSecond,
                         int rangeStartingMillis,
                         int rangeEndingHourOfDay,
                         int rangeEndingMinute,
                         int rangeEndingSecond,
                         int rangeEndingMillis) {
        super();
        setTimeRange(rangeStartingHourOfDay,
                     rangeStartingMinute,
                     rangeStartingSecond,
                     rangeStartingMillis,
                     rangeEndingHourOfDay,
                     rangeEndingMinute,
                     rangeEndingSecond,
                     rangeEndingMillis);
    }
    
    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified values and the specified <CODE>baseCalendar</CODE>. Values are
     * subject to the following validations:
     * <UL><LI>Hours must be in the range 0-23 and are expressed using military
     *         (24-hour) time.</LI>
     *     <LI>Minutes must be in the range 0-59</LI>
     *     <LI>Seconds must be in the range 0-59</LI>
     *     <LI>Milliseconds must be in the range 0-999</LI>
     *     <LI>The time range starting time must be before the time range ending
     *         time. Note this means that a time range may not cross daily
     *         boundaries (10PM - 2AM)</LI>  
     * </UL> 
     * 
     * <p>
     * <b>Note:</b> This <CODE>DailyCalendar</CODE> will use the 
     * <code>{@link ZoneId#getDefault()}</code> time zone unless an explicit 
     * time zone is set via <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code>
     * </p>
     * 
     * @param baseCalendar              the base calendar for this calendar
     *                                  instance &ndash; see 
     *                                  {@link BaseCalendar} for more 
     *                                  information on base calendar 
     *                                  functionality
     * @param rangeStartingHourOfDay the hour of the start of the time range
     * @param rangeStartingMinute    the minute of the start of the time range
     * @param rangeStartingSecond    the second of the start of the time range
     * @param rangeStartingMillis    the millisecond of the start of the time 
     *                               range
     * @param rangeEndingHourOfDay   the hour of the end of the time range
     * @param rangeEndingMinute      the minute of the end of the time range
     * @param rangeEndingSecond      the second of the end of the time range
     * @param rangeEndingMillis      the millisecond of the start of the time 
     *                               range
     */
    this(QuartzCalendar baseCalendar,
                         int rangeStartingHourOfDay,
                         int rangeStartingMinute,
                         int rangeStartingSecond,
                         int rangeStartingMillis,
                         int rangeEndingHourOfDay,
                         int rangeEndingMinute,
                         int rangeEndingSecond,
                         int rangeEndingMillis) {
        super(baseCalendar);
        setTimeRange(rangeStartingHourOfDay,
                     rangeStartingMinute,
                     rangeStartingSecond,
                     rangeStartingMillis,
                     rangeEndingHourOfDay,
                     rangeEndingMinute,
                     rangeEndingSecond,
                     rangeEndingMillis);
    }

    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified <CODE>hunt.time.util.Calendar</CODE>s and no 
     * <CODE>baseCalendar</CODE>. The Calendars are subject to the following
     * considerations:
     * <UL><LI>Only the time-of-day fields of the specified Calendars will be
     *         used (the date fields will be ignored)</LI>
     *     <LI>The starting time must be before the ending time of the defined
     *         time range. Note this means that a time range may not cross
     *         daily boundaries (10PM - 2AM). <I>(because only time fields are
     *         are used, it is possible for two Calendars to represent a valid
     *         time range and 
     *         <CODE>rangeStartingCalendar.isAfter(rangeEndingCalendar) == 
     *         true</CODE>)</I></LI>  
     * </UL> 
     * 
     * <p>
     * <b>Note:</b> This <CODE>DailyCalendar</CODE> will use the 
     * <code>{@link ZoneId#getDefault()}</code> time zone unless an explicit 
     * time zone is set via <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code>
     * </p>
     * 
     * @param rangeStartingCalendar a hunt.time.util.Calendar representing the 
     *                              starting time for the time range
     * @param rangeEndingCalendar   a hunt.time.util.Calendar representing the ending
     *                              time for the time range
     */
    this(LocalDateTime rangeStartingCalendar, LocalDateTime rangeEndingCalendar) {
        super();
        setTimeRange(rangeStartingCalendar, rangeEndingCalendar);
    }

    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified <CODE>hunt.time.util.Calendar</CODE>s and the specified 
     * <CODE>baseCalendar</CODE>. The Calendars are subject to the following
     * considerations:
     * <UL><LI>Only the time-of-day fields of the specified Calendars will be
     *         used (the date fields will be ignored)</LI>
     *     <LI>The starting time must be before the ending time of the defined
     *         time range. Note this means that a time range may not cross
     *         daily boundaries (10PM - 2AM). <I>(because only time fields are
     *         are used, it is possible for two Calendars to represent a valid
     *         time range and 
     *         <CODE>rangeStartingCalendar.isAfter(rangeEndingCalendar) == 
     *         true</CODE>)</I></LI>  
     * </UL> 
     * 
     * <p>
     * <b>Note:</b> This <CODE>DailyCalendar</CODE> will use the 
     * <code>{@link ZoneId#getDefault()}</code> time zone unless an explicit 
     * time zone is set via <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code>
     * </p>
     * 
     * @param baseCalendar          the base calendar for this calendar instance
     *                              &ndash; see {@link BaseCalendar} for more 
     *                              information on base calendar functionality
     * @param rangeStartingCalendar a hunt.time.util.Calendar representing the 
     *                              starting time for the time range
     * @param rangeEndingCalendar   a hunt.time.util.Calendar representing the ending
     *                              time for the time range
     */
    this(QuartzCalendar baseCalendar,
                         LocalDateTime rangeStartingCalendar,
                         LocalDateTime rangeEndingCalendar) {
        super(baseCalendar);
        setTimeRange(rangeStartingCalendar, rangeEndingCalendar);
    }

    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified values and no <CODE>baseCalendar</CODE>. The values are 
     * subject to the following considerations:
     * <UL><LI>Only the time-of-day portion of the specified values will be
     *         used</LI>
     *     <LI>The starting time must be before the ending time of the defined
     *         time range. Note this means that a time range may not cross
     *         daily boundaries (10PM - 2AM). <I>(because only time value are
     *         are used, it is possible for the two values to represent a valid
     *         time range and <CODE>rangeStartingTime &gt; 
     *         rangeEndingTime</CODE>)</I></LI>  
     * </UL> 
     * 
     * <p>
     * <b>Note:</b> This <CODE>DailyCalendar</CODE> will use the 
     * <code>{@link ZoneId#getDefault()}</code> time zone unless an explicit 
     * time zone is set via <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code>.
     * You should use <code>{@link #DailyCalendar(QuartzCalendar, std.datetime : ZoneId, long, long)}</code>
     * if you don't want the given <code>rangeStartingTimeInMillis</code> and
     * <code>rangeEndingTimeInMillis</code> to be evaluated in the default 
     * time zone.
     * </p>
     * 
     * @param rangeStartingTimeInMillis a long representing the starting time 
     *                                  for the time range
     * @param rangeEndingTimeInMillis   a long representing the ending time for
     *                                  the time range
     */
    this(long rangeStartingTimeInMillis,
                         long rangeEndingTimeInMillis) {
        super();
        setTimeRange(rangeStartingTimeInMillis, 
                     rangeEndingTimeInMillis);
    }

    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified values and the specified <CODE>baseCalendar</CODE>. The values
     * are subject to the following considerations:
     * <UL><LI>Only the time-of-day portion of the specified values will be
     *         used</LI>
     *     <LI>The starting time must be before the ending time of the defined
     *         time range. Note this means that a time range may not cross
     *         daily boundaries (10PM - 2AM). <I>(because only time value are
     *         are used, it is possible for the two values to represent a valid
     *         time range and <CODE>rangeStartingTime &gt; 
     *         rangeEndingTime</CODE>)</I></LI>  
     * </UL> 
     * 
     * <p>
     * <b>Note:</b> This <CODE>DailyCalendar</CODE> will use the 
     * <code>{@link ZoneId#getDefault()}</code> time zone unless an explicit 
     * time zone is set via <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code>.
     * You should use <code>{@link #DailyCalendar(QuartzCalendar, std.datetime : ZoneId, long, long)} </code>
     * if you don't want the given <code>rangeStartingTimeInMillis</code> and
     * <code>rangeEndingTimeInMillis</code> to be evaluated in the default 
     * time zone.
     * </p>
     * 
     * @param baseCalendar              the base calendar for this calendar
     *                                  instance &ndash; see {@link 
     *                                  BaseCalendar} for more information on 
     *                                  base calendar functionality
     * @param rangeStartingTimeInMillis a long representing the starting time 
     *                                  for the time range
     * @param rangeEndingTimeInMillis   a long representing the ending time for
     *                                  the time range
     */
    this(QuartzCalendar baseCalendar,
                         long rangeStartingTimeInMillis,
                         long rangeEndingTimeInMillis) {
        super(baseCalendar);
        setTimeRange(rangeStartingTimeInMillis,
                     rangeEndingTimeInMillis);
    }
    
    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified values and no <CODE>baseCalendar</CODE>. The values are 
     * subject to the following considerations:
     * <UL><LI>Only the time-of-day portion of the specified values will be
     *         used</LI>
     *     <LI>The starting time must be before the ending time of the defined
     *         time range. Note this means that a time range may not cross
     *         daily boundaries (10PM - 2AM). <I>(because only time value are
     *         are used, it is possible for the two values to represent a valid
     *         time range and <CODE>rangeStartingTime &gt; 
     *         rangeEndingTime</CODE>)</I></LI>  
     * </UL> 
     * 
     * @param timeZone                  the time zone for of the 
     *                                  <code>DailyCalendar</code> which will 
     *                                  also be used to resolve the given 
     *                                  start/end times.                                 
     * @param rangeStartingTimeInMillis a long representing the starting time 
     *                                  for the time range
     * @param rangeEndingTimeInMillis   a long representing the ending time for
     *                                  the time range
     */
    this(ZoneId timeZone,
                         long rangeStartingTimeInMillis,
                         long rangeEndingTimeInMillis) {
        super(timeZone);
        setTimeRange(rangeStartingTimeInMillis, 
                     rangeEndingTimeInMillis);
    }

    /**
     * Create a <CODE>DailyCalendar</CODE> with a time range defined by the
     * specified values and the specified <CODE>baseCalendar</CODE>. The values
     * are subject to the following considerations:
     * <UL><LI>Only the time-of-day portion of the specified values will be
     *         used</LI>
     *     <LI>The starting time must be before the ending time of the defined
     *         time range. Note this means that a time range may not cross
     *         daily boundaries (10PM - 2AM). <I>(because only time value are
     *         are used, it is possible for the two values to represent a valid
     *         time range and <CODE>rangeStartingTime &gt; 
     *         rangeEndingTime</CODE>)</I></LI>  
     * </UL> 
     * 
     * @param baseCalendar              the base calendar for this calendar
     *                                  instance &ndash; see {@link 
     *                                  BaseCalendar} for more information on 
     *                                  base calendar functionality
     * @param timeZone                  the time zone for of the 
     *                                  <code>DailyCalendar</code> which will 
     *                                  also be used to resolve the given 
     *                                  start/end times.                                 
     * @param rangeStartingTimeInMillis a long representing the starting time 
     *                                  for the time range
     * @param rangeEndingTimeInMillis   a long representing the ending time for
     *                                  the time range
     */
    this(QuartzCalendar baseCalendar,
                         ZoneId timeZone,
                         long rangeStartingTimeInMillis,
                         long rangeEndingTimeInMillis) {
        super(baseCalendar, timeZone);
        setTimeRange(rangeStartingTimeInMillis,
                     rangeEndingTimeInMillis);
    }

    // override
    // Object clone() {
    //     DailyCalendar clone = cast(DailyCalendar) super.clone();
    //     return clone;
    // }
    
    /**
     * Determines whether the given time (in milliseconds) is 'included' by the
     * <CODE>BaseCalendar</CODE>
     * 
     * @param timeInMillis the date/time to test
     * @return a bool indicating whether the specified time is 'included' by
     *         the <CODE>BaseCalendar</CODE>
     */
    override
    bool isTimeIncluded(long timeInMillis) {        
        if ((getBaseCalendar() !is null) && 
                (getBaseCalendar().isTimeIncluded(timeInMillis) == false)) {
            return false;
        }
        
        long startOfDayInMillis = getStartOfDayJavaCalendar(timeInMillis).toInstant(ZoneOffset.UTC).toEpochMilli();
        long endOfDayInMillis = getEndOfDayJavaCalendar(timeInMillis).toInstant(ZoneOffset.UTC).toEpochMilli();
        long timeRangeStartingTimeInMillis = 
            getTimeRangeStartingTimeInMillis(timeInMillis);
        long timeRangeEndingTimeInMillis = 
            getTimeRangeEndingTimeInMillis(timeInMillis);
        if (!invertTimeRange) {
            return 
                ((timeInMillis > startOfDayInMillis && 
                    timeInMillis < timeRangeStartingTimeInMillis) ||
                (timeInMillis > timeRangeEndingTimeInMillis && 
                    timeInMillis < endOfDayInMillis));
        } else {
            return ((timeInMillis >= timeRangeStartingTimeInMillis) &&
                    (timeInMillis <= timeRangeEndingTimeInMillis));
        }
    }

    /**
     * Determines the next time included by the <CODE>DailyCalendar</CODE>
     * after the specified time.
     * 
     * @param timeInMillis the initial date/time after which to find an 
     *                     included time
     * @return the time in milliseconds representing the next time included
     *         after the specified time.
     */
    override
    long getNextIncludedTime(long timeInMillis) {
        long nextIncludedTime = timeInMillis + oneMillis;
        
        while (!isTimeIncluded(nextIncludedTime)) {
            if (!invertTimeRange) {
                //If the time is in a range excluded by this calendar, we can
                // move to the end of the excluded time range and continue 
                // testing from there. Otherwise, if nextIncludedTime is 
                // excluded by the baseCalendar, ask it the next time it 
                // includes and begin testing from there. Failing this, add one
                // millisecond and continue testing.
                if ((nextIncludedTime >= 
                        getTimeRangeStartingTimeInMillis(nextIncludedTime)) && 
                    (nextIncludedTime <= 
                        getTimeRangeEndingTimeInMillis(nextIncludedTime))) {
                    
                    nextIncludedTime = 
                        getTimeRangeEndingTimeInMillis(nextIncludedTime) + 
                            oneMillis;
                } else if ((getBaseCalendar() !is null) && 
                        (!getBaseCalendar().isTimeIncluded(nextIncludedTime))){
                    nextIncludedTime = 
                        getBaseCalendar().getNextIncludedTime(nextIncludedTime);
                } else {
                    nextIncludedTime++;
                }
            } else {
                //If the time is in a range excluded by this calendar, we can
                // move to the end of the excluded time range and continue 
                // testing from there. Otherwise, if nextIncludedTime is 
                // excluded by the baseCalendar, ask it the next time it 
                // includes and begin testing from there. Failing this, add one
                // millisecond and continue testing.
                if (nextIncludedTime < 
                        getTimeRangeStartingTimeInMillis(nextIncludedTime)) {
                    nextIncludedTime = 
                        getTimeRangeStartingTimeInMillis(nextIncludedTime);
                } else if (nextIncludedTime > 
                        getTimeRangeEndingTimeInMillis(nextIncludedTime)) {
                    //(move to start of next day)
                    nextIncludedTime = getEndOfDayJavaCalendar(nextIncludedTime).toInstant(ZoneOffset.UTC).toEpochMilli();
                    nextIncludedTime++; 
                } else if ((getBaseCalendar() !is null) && 
                        (!getBaseCalendar().isTimeIncluded(nextIncludedTime))){
                    nextIncludedTime = 
                        getBaseCalendar().getNextIncludedTime(nextIncludedTime);
                } else {
                    nextIncludedTime++;
                }
            }
        }
        
        return nextIncludedTime;
    }

    /**
     * Returns the start time of the time range (in milliseconds) of the day 
     * specified in <CODE>timeInMillis</CODE>
     * 
     * @param timeInMillis a time containing the desired date for the starting
     *                     time of the time range.
     * @return a date/time (in milliseconds) representing the start time of the
     *         time range for the specified date.
     */
    long getTimeRangeStartingTimeInMillis(long timeInMillis) {
        LocalDateTime rangeStartingTime = createJavaCalendar(timeInMillis);
        rangeStartingTime = LocalDateTime.of(rangeStartingTime.getYear(), rangeStartingTime.getMonthValue(), 
            rangeStartingTime.getDayOfMonth(), rangeStartingHourOfDay, rangeStartingMinute, 
            rangeStartingSecond, cast(int)(rangeStartingMillis * LocalTime.NANOS_PER_MILLI));
        return rangeStartingTime.toInstant(ZoneOffset.UTC).toEpochMilli();
    }

    /**
     * Returns the end time of the time range (in milliseconds) of the day
     * specified in <CODE>timeInMillis</CODE>
     * 
     * @param timeInMillis a time containing the desired date for the ending
     *                     time of the time range.
     * @return a date/time (in milliseconds) representing the end time of the
     *         time range for the specified date.
     */
    long getTimeRangeEndingTimeInMillis(long timeInMillis) {
        LocalDateTime rangeEndingTime = createJavaCalendar(timeInMillis);
        rangeEndingTime = LocalDateTime.of(rangeEndingTime.getYear(), rangeEndingTime.getMonthValue(), 
            rangeEndingTime.getDayOfMonth(), rangeEndingHourOfDay, rangeEndingMinute, 
            rangeEndingSecond, cast(int)(rangeEndingMillis * LocalTime.NANOS_PER_MILLI));
        return rangeEndingTime.toInstant(ZoneOffset.UTC).toEpochMilli();
    }

    /**
     * Indicates whether the time range represents an inverted time range (see
     * class description).
     * 
     * @return a bool indicating whether the time range is inverted
     */
    bool getInvertTimeRange() {
        return invertTimeRange;
    }
    
    /**
     * Indicates whether the time range represents an inverted time range (see
     * class description).
     * 
     * @param flag the new value for the <CODE>invertTimeRange</CODE> flag.
     */
    void setInvertTimeRange(bool flag) {
        this.invertTimeRange = flag;
    }
    
    /**
     * Returns a string representing the properties of the 
     * <CODE>DailyCalendar</CODE>
     * 
     * @return the properteis of the DailyCalendar in a string format
     */
    override
    string toString() {
        // NumberFormat numberFormatter = NumberFormat.getNumberInstance();
        // numberFormatter.setMaximumFractionDigits(0);
        // numberFormatter.setMinimumIntegerDigits(2);
        StringBuffer buffer = new StringBuffer();
        buffer.append("base calendar: [");
        if (getBaseCalendar() !is null) {
            buffer.append((cast(Object)getBaseCalendar()).toString());
        } else {
            buffer.append("null");
        }
        buffer.append("], time range: '");
        buffer.append(format("%02d", rangeStartingHourOfDay));
        buffer.append(":");
        buffer.append(format("%02d", rangeStartingMinute));
        buffer.append(":");
        buffer.append(format("%02d", rangeStartingSecond));
        buffer.append(":");
        buffer.append(format("%03d", rangeStartingMillis));
        buffer.append(" - ");
        buffer.append(format("%02d", rangeEndingHourOfDay));
        buffer.append(":");
        buffer.append(format("%02d", rangeEndingMinute));
        buffer.append(":");
        buffer.append(format("%02d", rangeEndingSecond));
        buffer.append(":");
        buffer.append(format("%03d", rangeEndingMillis));
        buffer.append("', inverted: " ~ invertTimeRange ~ "]");
        return buffer.toString();
    }
    
    /**
     * Helper method to split the given string by the given delimiter.
     */
    private string[] split(string str, string delim) {
        ArrayList!(string) result = new ArrayList!(string)();
        
        StringTokenizer stringTokenizer = new StringTokenizer(str, delim);
        while (stringTokenizer.hasMoreTokens()) {
            result.add(stringTokenizer.nextToken());
        }
        
        return result.toArray();
    }
    
    /**
     * Sets the time range for the <CODE>DailyCalendar</CODE> to the times 
     * represented in the specified Strings. 
     * 
     * @param rangeStartingTimeString a string representing the start time of 
     *                                the time range
     * @param rangeEndingTimeString   a string representing the end time of the
     *                                excluded time range
     */
    void setTimeRange(string rangeStartingTimeString,
                              string rangeEndingTimeString) {
        string[] rangeStartingTime;
        int rStartingHourOfDay;
        int rStartingMinute;
        int rStartingSecond;
        int rStartingMillis;
        
        string[] rEndingTime;
        int rEndingHourOfDay;
        int rEndingMinute;
        int rEndingSecond;
        int rEndingMillis;
        
        rangeStartingTime = split(rangeStartingTimeString, colon);
        
        if ((rangeStartingTime.length < 2) || (rangeStartingTime.length > 4)) {
            throw new IllegalArgumentException("Invalid time string '" ~ 
                    rangeStartingTimeString ~ "'");
        }
        
        rStartingHourOfDay = to!int(rangeStartingTime[0]);
        rStartingMinute = to!int(rangeStartingTime[1]);
        if (rangeStartingTime.length > 2) {
            rStartingSecond = to!int(rangeStartingTime[2]);
        } else {
            rStartingSecond = 0;
        }
        if (rangeStartingTime.length == 4) {
            rStartingMillis = to!int(rangeStartingTime[3]);
        } else {
            rStartingMillis = 0;
        }
        
        rEndingTime = split(rangeEndingTimeString, colon);

        if ((rEndingTime.length < 2) || (rEndingTime.length > 4)) {
            throw new IllegalArgumentException("Invalid time string '" ~ 
                    rangeEndingTimeString ~ "'");
        }
        
        rEndingHourOfDay = to!int(rEndingTime[0]);
        rEndingMinute = to!int(rEndingTime[1]);
        if (rEndingTime.length > 2) {
            rEndingSecond = to!int(rEndingTime[2]);
        } else {
            rEndingSecond = 0;
        }
        if (rEndingTime.length == 4) {
            rEndingMillis = to!int(rEndingTime[3]);
        } else {
            rEndingMillis = 0;
        }
        
        setTimeRange(rStartingHourOfDay,
                     rStartingMinute,
                     rStartingSecond,
                     rStartingMillis,
                     rEndingHourOfDay,
                     rEndingMinute,
                     rEndingSecond,
                     rEndingMillis);
    }

    /**
     * Sets the time range for the <CODE>DailyCalendar</CODE> to the times
     * represented in the specified values.  
     * 
     * @param rangeStartingHourOfDay the hour of the start of the time range
     * @param rangeStartingMinute    the minute of the start of the time range
     * @param rangeStartingSecond    the second of the start of the time range
     * @param rangeStartingMillis    the millisecond of the start of the time
     *                               range
     * @param rangeEndingHourOfDay   the hour of the end of the time range
     * @param rangeEndingMinute      the minute of the end of the time range
     * @param rangeEndingSecond      the second of the end of the time range
     * @param rangeEndingMillis      the millisecond of the start of the time 
     *                               range
     */
    void setTimeRange(int rangeStartingHourOfDay,
                              int rangeStartingMinute,
                              int rangeStartingSecond,
                              int rangeStartingMillis,
                              int rangeEndingHourOfDay,
                              int rangeEndingMinute,
                              int rangeEndingSecond,
                              int rangeEndingMillis) {
        validate(rangeStartingHourOfDay,
                 rangeStartingMinute,
                 rangeStartingSecond,
                 rangeStartingMillis);
        
        validate(rangeEndingHourOfDay,
                 rangeEndingMinute,
                 rangeEndingSecond,
                 rangeEndingMillis);
        
        LocalDateTime startCal = createJavaCalendar();
        startCal = LocalDateTime.of(startCal.getYear(), startCal.getMonthValue(), startCal.getDayOfMonth(),
            rangeStartingHourOfDay, rangeStartingMinute, rangeStartingSecond, 
            rangeStartingMillis * cast(int) LocalTime.NANOS_PER_MILLI);
            
        LocalDateTime endCal = createJavaCalendar();
        endCal = LocalDateTime.of(endCal.getYear(), endCal.getMonthValue(), endCal.getDayOfMonth(),
            rangeEndingHourOfDay, rangeEndingMinute, rangeEndingSecond, 
            rangeEndingMillis * cast(int) LocalTime.NANOS_PER_MILLI);
        
        if (!startCal.isBefore(endCal)) {
            throw new IllegalArgumentException(invalidTimeRange.to!string() ~
                    rangeStartingHourOfDay.to!string() ~ ":" ~
                    rangeStartingMinute.to!string() ~ ":" ~
                    rangeStartingSecond.to!string() ~ ":" ~
                    rangeStartingMillis.to!string() ~ separator ~
                    rangeEndingHourOfDay.to!string() ~ ":" ~
                    rangeEndingMinute.to!string() ~ ":" ~
                    rangeEndingSecond.to!string() ~ ":" ~
                    rangeEndingMillis.to!string());
        }
        
        this.rangeStartingHourOfDay = rangeStartingHourOfDay;
        this.rangeStartingMinute = rangeStartingMinute;
        this.rangeStartingSecond = rangeStartingSecond;
        this.rangeStartingMillis = rangeStartingMillis;
        this.rangeEndingHourOfDay = rangeEndingHourOfDay;
        this.rangeEndingMinute = rangeEndingMinute;
        this.rangeEndingSecond = rangeEndingSecond;
        this.rangeEndingMillis = rangeEndingMillis;
    }
    
    /**
     * Sets the time range for the <CODE>DailyCalendar</CODE> to the times
     * represented in the specified <CODE>hunt.time.util.Calendar</CODE>s. 
     * 
     * @param rangeStartingCalendar a Calendar containing the start time for
     *                              the <CODE>DailyCalendar</CODE>
     * @param rangeEndingCalendar   a Calendar containing the end time for
     *                              the <CODE>DailyCalendar</CODE>
     */
    void setTimeRange(LocalDateTime rangeStartingCalendar,
                              LocalDateTime rangeEndingCalendar) {
        setTimeRange(
                rangeStartingCalendar.getHour(),
                rangeStartingCalendar.getMinute(),
                rangeStartingCalendar.getSecond(),
                rangeStartingCalendar.getNano()/cast(int)LocalTime.NANOS_PER_MILLI,
                rangeEndingCalendar.getHour(),
                rangeEndingCalendar.getMinute(),
                rangeEndingCalendar.getSecond(),
                rangeEndingCalendar.getNano()/cast(int)LocalTime.NANOS_PER_MILLI);
    }
    
    /**
     * Sets the time range for the <CODE>DailyCalendar</CODE> to the times
     * represented in the specified values. 
     * 
     * @param rangeStartingTime the starting time (in milliseconds) for the
     *                          time range
     * @param rangeEndingTime   the ending time (in milliseconds) for the time
     *                          range
     */
    void setTimeRange(long rangeStartingTime, 
                              long rangeEndingTime) {
        setTimeRange(
            createJavaCalendar(rangeStartingTime), 
            createJavaCalendar(rangeEndingTime));
    }
    
    /**
     * Checks the specified values for validity as a set of time values.
     * 
     * @param hourOfDay the hour of the time to check (in military (24-hour)
     *                  time)
     * @param minute    the minute of the time to check
     * @param second    the second of the time to check
     * @param millis    the millisecond of the time to check
     */
    private void validate(int hourOfDay, int minute, int second, int millis) {
        if (hourOfDay < 0 || hourOfDay > 23) {
            throw new IllegalArgumentException(invalidHourOfDay ~ hourOfDay.to!string());
        }
        if (minute < 0 || minute > 59) {
            throw new IllegalArgumentException(invalidMinute ~ minute.to!string());
        }
        if (second < 0 || second > 59) {
            throw new IllegalArgumentException(invalidSecond ~ second.to!string());
        }
        if (millis < 0 || millis > 999) {
            throw new IllegalArgumentException(invalidMillis ~ millis.to!string());
        }
    }
}