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

module hunt.quartz.CronExpression;

import hunt.util.Locale;
import hunt.time.DayOfWeek;
import hunt.time.Duration;
import hunt.time.LocalDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneRegion;
import hunt.time.ZoneOffset;
import hunt.util.Common;

import hunt.collection;
import hunt.Exceptions;
import hunt.String;
import hunt.text;
import hunt.logging.ConsoleLogger;

import std.conv;
import std.range;
import std.regex;
import std.string;


/**
 * Provides a parser and evaluator for unix-like cron expressions. Cron 
 * expressions provide the ability to specify complex time combinations such as
 * &quot;At 8:00am every Monday through Friday&quot; or &quot;At 1:30am every 
 * last Friday of the month&quot;. 
 * <P>
 * Cron expressions are comprised of 6 required fields and one optional field
 * separated by white space. The fields respectively are described as follows:
 * 
 * <table cellspacing="8">
 * <tr>
 * <th align="left">Field Name</th>
 * <th align="left">&nbsp;</th>
 * <th align="left">Allowed Values</th>
 * <th align="left">&nbsp;</th>
 * <th align="left">Allowed Special Characters</th>
 * </tr>
 * <tr>
 * <td align="left"><code>Seconds</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>0-59</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>, - * /</code></td>
 * </tr>
 * <tr>
 * <td align="left"><code>Minutes</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>0-59</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>, - * /</code></td>
 * </tr>
 * <tr>
 * <td align="left"><code>Hours</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>0-23</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>, - * /</code></td>
 * </tr>
 * <tr>
 * <td align="left"><code>Day-of-month</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>1-31</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>, - * ? / L W</code></td>
 * </tr>
 * <tr>
 * <td align="left"><code>Month</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>0-11 or JAN-DEC</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>, - * /</code></td>
 * </tr>
 * <tr>
 * <td align="left"><code>Day-of-Week</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>1-7 or SUN-SAT</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>, - * ? / L #</code></td>
 * </tr>
 * <tr>
 * <td align="left"><code>Year (Optional)</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>empty, 1970-2199</code></td>
 * <td align="left">&nbsp;</th>
 * <td align="left"><code>, - * /</code></td>
 * </tr>
 * </table>
 * <P>
 * The '*' character is used to specify all values. For example, &quot;*&quot; 
 * in the minute field means &quot;every minute&quot;.
 * <P>
 * The '?' character is allowed for the day-of-month and day-of-week fields. It
 * is used to specify 'no specific value'. This is useful when you need to
 * specify something in one of the two fields, but not the other.
 * <P>
 * The '-' character is used to specify ranges For example &quot;10-12&quot; in
 * the hour field means &quot;the hours 10, 11 and 12&quot;.
 * <P>
 * The ',' character is used to specify additional values. For example
 * &quot;MON,WED,FRI&quot; in the day-of-week field means &quot;the days Monday,
 * Wednesday, and Friday&quot;.
 * <P>
 * The '/' character is used to specify increments. For example &quot;0/15&quot;
 * in the seconds field means &quot;the seconds 0, 15, 30, and 45&quot;. And 
 * &quot;5/15&quot; in the seconds field means &quot;the seconds 5, 20, 35, and
 * 50&quot;.  Specifying '*' before the  '/' is equivalent to specifying 0 is
 * the value to start with. Essentially, for each field in the expression, there
 * is a set of numbers that can be turned on or off. For seconds and minutes, 
 * the numbers range from 0 to 59. For hours 0 to 23, for days of the month 0 to
 * 31, and for months 0 to 11 (JAN to DEC). The &quot;/&quot; character simply helps you turn
 * on every &quot;nth&quot; value in the given set. Thus &quot;7/6&quot; in the
 * month field only turns on month &quot;7&quot;, it does NOT mean every 6th 
 * month, please note that subtlety.  
 * <P>
 * The 'L' character is allowed for the day-of-month and day-of-week fields.
 * This character is short-hand for &quot;last&quot;, but it has different 
 * meaning in each of the two fields. For example, the value &quot;L&quot; in 
 * the day-of-month field means &quot;the last day of the month&quot; - day 31 
 * for January, day 28 for February on non-leap years. If used in the 
 * day-of-week field by itself, it simply means &quot;7&quot; or 
 * &quot;SAT&quot;. But if used in the day-of-week field after another value, it
 * means &quot;the last xxx day of the month&quot; - for example &quot;6L&quot;
 * means &quot;the last friday of the month&quot;. You can also specify an offset 
 * from the last day of the month, such as "L-3" which would mean the third-to-last 
 * day of the calendar month. <i>When using the 'L' option, it is important not to 
 * specify lists, or ranges of values, as you'll get confusing/unexpected results.</i>
 * <P>
 * The 'W' character is allowed for the day-of-month field.  This character 
 * is used to specify the weekday (Monday-Friday) nearest the given day.  As an 
 * example, if you were to specify &quot;15W&quot; as the value for the 
 * day-of-month field, the meaning is: &quot;the nearest weekday to the 15th of
 * the month&quot;. So if the 15th is a Saturday, the trigger will fire on 
 * Friday the 14th. If the 15th is a Sunday, the trigger will fire on Monday the
 * 16th. If the 15th is a Tuesday, then it will fire on Tuesday the 15th. 
 * However if you specify &quot;1W&quot; as the value for day-of-month, and the
 * 1st is a Saturday, the trigger will fire on Monday the 3rd, as it will not 
 * 'jump' over the boundary of a month's days.  The 'W' character can only be 
 * specified when the day-of-month is a single day, not a range or list of days.
 * <P>
 * The 'L' and 'W' characters can also be combined for the day-of-month 
 * expression to yield 'LW', which translates to &quot;last weekday of the 
 * month&quot;.
 * <P>
 * The '#' character is allowed for the day-of-week field. This character is
 * used to specify &quot;the nth&quot; XXX day of the month. For example, the 
 * value of &quot;6#3&quot; in the day-of-week field means the third Friday of 
 * the month (day 6 = Friday and &quot;#3&quot; = the 3rd one in the month). 
 * Other examples: &quot;2#1&quot; = the first Monday of the month and 
 * &quot;4#5&quot; = the fifth Wednesday of the month. Note that if you specify
 * &quot;#5&quot; and there is not 5 of the given day-of-week in the month, then
 * no firing will occur that month.  If the '#' character is used, there can
 * only be one expression in the day-of-week field (&quot;3#1,6#3&quot; is 
 * not valid, since there are two expressions).
 * <P>
 * <!--The 'C' character is allowed for the day-of-month and day-of-week fields.
 * This character is short-hand for "calendar". This means values are
 * calculated against the associated calendar, if any. If no calendar is
 * associated, then it is equivalent to having an all-inclusive calendar. A
 * value of "5C" in the day-of-month field means "the first day included by the
 * calendar on or after the 5th". A value of "1C" in the day-of-week field
 * means "the first day included by the calendar on or after Sunday".-->
 * <P>
 * The legal characters and the names of months and days of the week are not
 * case sensitive.
 * 
 * <p>
 * <b>NOTES:</b>
 * <ul>
 * <li>Support for specifying both a day-of-week and a day-of-month value is
 * not complete (you'll need to use the '?' character in one of these fields).
 * </li>
 * <li>Overflowing ranges is supported - that is, having a larger number on 
 * the left hand side than the right. You might do 22-2 to catch 10 o'clock 
 * at night until 2 o'clock in the morning, or you might have NOV-FEB. It is 
 * very important to note that overuse of overflowing ranges creates ranges 
 * that don't make sense and no effort has been made to determine which 
 * interpretation CronExpression chooses. An example would be 
 * "0 0 14-6 ? * FRI-MON". </li>
 * </ul>
 * </p>
 * 
 * 
 * @author Sharada Jambula, James House
 * @author Contributions from Mads Henderson
 * @author Refactoring from CronTrigger to CronExpression by Aaron Craven
 */
final class CronExpression  { // : Cloneable Serializable,
    
    protected enum int SECOND = 0;
    protected enum int MINUTE = 1;
    protected enum int HOUR = 2;
    protected enum int DAY_OF_MONTH = 3;
    protected enum int MONTH = 4;
    protected enum int DAY_OF_WEEK = 5;
    protected enum int YEAR = 6;
    protected enum int ALL_SPEC_INT = 99; // '*'
    protected enum int NO_SPEC_INT = 98; // '?'
    protected enum int ALL_SPEC = ALL_SPEC_INT;
    protected enum int NO_SPEC = NO_SPEC_INT;
    
    protected __gshared Map!(string, int) monthMap;
    protected __gshared Map!(string, int) dayMap;

    shared static this() {
        monthMap = new HashMap!(string, int)(20);
        dayMap = new HashMap!(string, int)(60);

        monthMap.put("JAN", 0);
        monthMap.put("FEB", 1);
        monthMap.put("MAR", 2);
        monthMap.put("APR", 3);
        monthMap.put("MAY", 4);
        monthMap.put("JUN", 5);
        monthMap.put("JUL", 6);
        monthMap.put("AUG", 7);
        monthMap.put("SEP", 8);
        monthMap.put("OCT", 9);
        monthMap.put("NOV", 10);
        monthMap.put("DEC", 11);

        dayMap.put("SUN", 1);
        dayMap.put("MON", 2);
        dayMap.put("TUE", 3);
        dayMap.put("WED", 4);
        dayMap.put("THU", 5);
        dayMap.put("FRI", 6);
        dayMap.put("SAT", 7);
    }

    private string cronExpression;
    private ZoneId timeZone = null;
    protected TreeSet!(int) seconds;
    protected TreeSet!(int) minutes;
    protected TreeSet!(int) hours;
    protected TreeSet!(int) daysOfMonth;
    protected TreeSet!(int) months;
    protected TreeSet!(int) daysOfWeek;
    protected TreeSet!(int) years;

    protected bool lastdayOfWeek = false;
    protected int nthdayOfWeek = 0;
    protected bool lastdayOfMonth = false;
    protected bool nearestWeekday = false;
    protected int lastdayOffset = 0;
    protected bool expressionParsed = false;
    
    enum int MAX_YEAR = 2018 +  100; // Calendar.getInstance().get(Calendar.YEAR) + 

    /**
     * Constructs a new <CODE>CronExpression</CODE> based on the specified 
     * parameter.
     * 
     * @param cronExpression string representation of the cron expression the
     *                       new object should represent
     * @throws java.text.ParseException
     *         if the string expression cannot be parsed into a valid 
     *         <CODE>CronExpression</CODE>
     */
    this(string cronExpression) {
        if (cronExpression is null) {
            throw new IllegalArgumentException("cronExpression cannot be null");
        }
        
        this.cronExpression = cronExpression.toUpper();
        
        buildExpression(this.cronExpression);
    }
    
    /**
     * Constructs a new {@code CronExpression} as a copy of an existing
     * instance.
     * 
     * @param expression
     *            The existing cron expression to be copied
     */
    this(CronExpression expression) {
        /*
         * We don't call the other constructor here since we need to swallow the
         * ParseException. We also elide some of the sanity checking as it is
         * not logically trippable.
         */
        this.cronExpression = expression.getCronExpression();
        try {
            buildExpression(cronExpression);
        } catch (ParseException ex) {
            version(HUNT_QUARTZ_DEBUG) warning(ex);
            throw new Error("Building error: " ~ ex.msg);
        }
        if (expression.getTimeZone() !is null) {
            // setTimeZone(cast(TimeZone) expression.getTimeZone().clone());
            setTimeZone(cast(ZoneId) expression.getTimeZone());
        }
    }

    /**
     * Indicates whether the given date satisfies the cron expression. Note that
     * milliseconds are ignored, so two Dates falling on different milliseconds
     * of the same second will always have the same result here.
     * 
     * @param date the date to evaluate
     * @return a bool indicating whether the given date satisfies the cron
     *         expression
     */
    bool isSatisfiedBy(LocalDateTime date) {
        LocalDateTime originalDate = date;
        date = date.plusSeconds(-1);
        LocalDateTime timeAfter = getTimeAfter(date);

        return ((timeAfter !is null) && (timeAfter == originalDate));
    }
    
    /**
     * Returns the next date/time <I>after</I> the given date/time which
     * satisfies the cron expression.
     * 
     * @param date the date/time at which to begin the search for the next valid
     *             date/time
     * @return the next valid date/time
     */
    LocalDateTime getNextValidTimeAfter(LocalDateTime date) {
        return getTimeAfter(date);
    }
    
    /**
     * Returns the next date/time <I>after</I> the given date/time which does
     * <I>not</I> satisfy the expression
     * 
     * @param date the date/time at which to begin the search for the next 
     *             invalid date/time
     * @return the next valid date/time
     */
    LocalDateTime getNextInvalidTimeAfter(LocalDateTime date) {
        long difference = 1000;
        
        //move back to the nearest second so differences will be accurate
        // Calendar adjustCal = Calendar.getInstance(getTimeZone());
        // adjustCal.setTime(date);
        // adjustCal.set(Calendar.MILLISECOND, 0);
        LocalDateTime lastDate = date;
        
        LocalDateTime newDate;
        
        //FUTURE_TODO: (QUARTZ-481) IMPROVE THIS! The following is a BAD solution to this problem. Performance will be very bad here, depending on the cron expression. It is, however A solution.
        
        //keep getting the next included time until it's farther than one second
        // apart. At that point, lastDate is the last valid fire time. We return
        // the second immediately following it.
        while (difference == 1) {
            newDate = getTimeAfter(lastDate);
            if(newDate is null)
                break;
            
		    Duration du = Duration.between(lastDate, newDate);
            if (du.toSeconds() == 1) {
                lastDate = newDate;
            }
        }
        return lastDate.plusSeconds(1).withNano(0);
    }
    
    /**
     * Returns the time zone for which this <code>CronExpression</code> 
     * will be resolved.
     */
    ZoneId getTimeZone() {
        if (timeZone is null) {
            timeZone = ZoneRegion.systemDefault();
        }

        return timeZone;
    }

    /**
     * Sets the time zone for which  this <code>CronExpression</code> 
     * will be resolved.
     */
    void setTimeZone(ZoneId timeZone) {
        this.timeZone = timeZone;
    }
    
    /**
     * Returns the string representation of the <CODE>CronExpression</CODE>
     * 
     * @return a string representation of the <CODE>CronExpression</CODE>
     */
    override
    string toString() {
        return cronExpression;
    }

    /**
     * Indicates whether the specified cron expression can be parsed into a 
     * valid cron expression
     * 
     * @param cronExpression the expression to evaluate
     * @return a bool indicating whether the given expression is a valid cron
     *         expression
     */
    static bool isValidExpression(string cronExpression) {
        
        try {
            new CronExpression(cronExpression);
        } catch (ParseException pe) {
            return false;
        }
        
        return true;
    }

    static void validateExpression(string cronExpression) {
        
        new CronExpression(cronExpression);
    }
    
    
    ////////////////////////////////////////////////////////////////////////////
    //
    // Expression Parsing Functions
    //
    ////////////////////////////////////////////////////////////////////////////

    protected void buildExpression(string expression) {
        expressionParsed = true;

        try {

            if (seconds is null) {
                seconds = new TreeSet!(int)();
            }
            if (minutes is null) {
                minutes = new TreeSet!(int)();
            }
            if (hours is null) {
                hours = new TreeSet!(int)();
            }
            if (daysOfMonth is null) {
                daysOfMonth = new TreeSet!(int)();
            }
            if (months is null) {
                months = new TreeSet!(int)();
            }
            if (daysOfWeek is null) {
                daysOfWeek = new TreeSet!(int)();
            }
            if (years is null) {
                years = new TreeSet!(int)();
            }

            int exprOn = SECOND;
            version (HUNT_QUARTZ_DEBUG) tracef(expression);

            StringTokenizer exprsTok = new StringTokenizer(expression, " \t", false);
                
            while (exprsTok.hasMoreTokens() && exprOn <= YEAR) {
                string expr = exprsTok.nextToken().strip();
                // version (HUNT_QUARTZ_DEBUG) tracef(expr);

                // throw an exception if L is used with other days of the month
                if(exprOn == DAY_OF_MONTH && expr.indexOf('L') != -1 && expr.length > 1 && expr.contains(",")) {
                    throw new ParseException("Support for specifying 'L' and 'LW' with other days of the month is not implemented");
                }
                // throw an exception if L is used with other days of the week
                if(exprOn == DAY_OF_WEEK && expr.indexOf('L') != -1 && expr.length > 1  && expr.contains(",")) {
                    throw new ParseException("Support for specifying 'L' with other days of the week is not implemented");
                }
                if(exprOn == DAY_OF_WEEK && expr.indexOf('#') != -1 && expr.indexOf('#', expr.indexOf('#') +1) != -1) {
                    throw new ParseException("Support for specifying multiple \"nth\" days is not implemented.");
                }
                
                StringTokenizer vTok = new StringTokenizer(expr, ",");
                while (vTok.hasMoreTokens()) {
                    string v = vTok.nextToken();
                    storeExpressionVals(0, v, exprOn);
                }

                exprOn++;
            }

            if (exprOn <= DAY_OF_WEEK) {
                throw new ParseException("Unexpected end of expression.",
                            cast(int)expression.length);
            }

            if (exprOn <= YEAR) {
                storeExpressionVals(0, "*", YEAR);
            }

            TreeSet!(int) dow = getSet(DAY_OF_WEEK);
            TreeSet!(int) dom = getSet(DAY_OF_MONTH);

            // Copying the logic from the UnsupportedOperationException below
            bool dayOfMSpec = !dom.contains(NO_SPEC);
            bool dayOfWSpec = !dow.contains(NO_SPEC);
            
            // version (HUNT_QUARTZ_DEBUG) {
            //     tracef("dayOfMSpec: %d, exprOn: %d", dow.size(), exprOn);
            //     tracef("dayOfMSpec: %s, dayOfWSpec: %s", dayOfMSpec, dayOfWSpec);
            // }

            if (!dayOfMSpec || dayOfWSpec) {
                if (!dayOfWSpec || dayOfMSpec) {
                    throw new ParseException(
                            "Support for specifying both a day-of-week AND a day-of-month parameter is not implemented.", 0);
                }
            }
        } catch (ParseException pe) {
            throw pe;
        } catch (Exception e) {
            throw new ParseException("Illegal cron expression format ("
                    ~ e.msg ~ ")", 0);
        }
    }

    protected int storeExpressionVals(int pos, string s, int type) {
        int incr = 0;
        int i = skipWhiteSpace(pos, s);
        if (i >= s.length) {
            return i;
        }
        char c = s[i];
        auto pattern = ctRegex!("^L-[0-9]*[W]?");
        if ((c >= 'A') && (c <= 'Z') && (!s.equals("L")) && 
            (!s.equals("LW")) && (matchFirst(s, pattern).empty)) {
            string sub = s.substring(i, i + 3);
            int sval = -1;
            int eval = -1;
            if (type == MONTH) {
                sval = getMonthNumber(sub) + 1;
                if (sval <= 0) {
                    throw new ParseException("Invalid Month value: '" ~ sub ~ "'", i);
                }
                if (s.length > i + 3) {
                    c = s[i + 3];
                    if (c == '-') {
                        i += 4;
                        sub = s.substring(i, i + 3);
                        eval = getMonthNumber(sub) + 1;
                        if (eval <= 0) {
                            throw new ParseException("Invalid Month value: '" ~ sub ~ "'", i);
                        }
                    }
                }
            } else if (type == DAY_OF_WEEK) {
                sval = getDayOfWeekNumber(sub);
                if (sval < 0) {
                    throw new ParseException("Invalid Day-of-Week value: '"
                                ~ sub ~ "'", i);
                }
                if (s.length > i + 3) {
                    c = s[i + 3];
                    if (c == '-') {
                        i += 4;
                        sub = s.substring(i, i + 3);
                        eval = getDayOfWeekNumber(sub);
                        if (eval < 0) {
                            throw new ParseException(
                                    "Invalid Day-of-Week value: '" ~ sub
                                        ~ "'", i);
                        }
                    } else if (c == '#') {
                        try {
                            i += 4;
                            nthdayOfWeek = to!int(s.substring(i));
                            if (nthdayOfWeek < 1 || nthdayOfWeek > 5) {
                                throw new Exception("Out of range for a week.");
                            }
                        } catch (Exception e) {
                            throw new ParseException(
                                    "A numeric value between 1 and 5 must follow the '#' option",
                                    i);
                        }
                    } else if (c == 'L') {
                        lastdayOfWeek = true;
                        i++;
                    }
                }

            } else {
                throw new ParseException("Illegal characters for this position: '" ~ sub ~ "'", i);
            }

            if (eval != -1) {
                incr = 1;
            }

            addToSet(sval, eval, incr, type);
            return (i + 3);
        }

        if (c == '?') {
            i++;
            if ((i + 1) < s.length 
                    && (s[i] != ' ' && s[i + 1] != '\t')) {
                throw new ParseException("Illegal character after '?': "
                            ~ s[i].to!string(), i);
            }
            if (type != DAY_OF_WEEK && type != DAY_OF_MONTH) {
                throw new ParseException(
                            "'?' can only be specified for Day-of-Month or Day-of-Week.",
                            i);
            }
            if (type == DAY_OF_WEEK && !lastdayOfMonth) {
                int val = daysOfMonth.last();
                if (val == NO_SPEC_INT) {
                    throw new ParseException(
                                "'?' can only be specified for Day-of-Month -OR- Day-of-Week.",
                                i);
                }
            }

            addToSet(NO_SPEC_INT, -1, 0, type);
            return i;
        }

        if (c == '*' || c == '/') {
            if (c == '*' && (i + 1) >= s.length) {
                addToSet(ALL_SPEC_INT, -1, incr, type);
                return i + 1;
            } else if (c == '/'
                    && ((i + 1) >= s.length || s[i + 1] == ' ' || s[i + 1] == '\t')) { 
                throw new ParseException("'/' must be followed by an integer.", i);
            } else if (c == '*') {
                i++;
            }
            c = s[i];
            if (c == '/') { // is an increment specified?
                i++;
                if (i >= s.length) {
                    throw new ParseException("Unexpected end of string.", i);
                }

                incr = getNumericValue(s, i);

                i++;
                if (incr > 10) {
                    i++;
                }
                checkIncrementRange(incr, type, i);
            } else {
                incr = 1;
            }

            addToSet(ALL_SPEC_INT, -1, incr, type);
            return i;
        } else if (c == 'L') {
            i++;
            if (type == DAY_OF_MONTH) {
                lastdayOfMonth = true;
            }
            if (type == DAY_OF_WEEK) {
                addToSet(7, 7, 0, type);
            }
            if(type == DAY_OF_MONTH && s.length > i) {
                c = s[i];
                if(c == '-') {
                    ValueSet vs = getValue(0, s, i+1);
                    lastdayOffset = vs.value;
                    if(lastdayOffset > 30)
                        throw new ParseException("Offset from last day must be <= 30", i+1);
                    i = vs.pos;
                }                        
                if(s.length > i) {
                    c = s[i];
                    if(c == 'W') {
                        nearestWeekday = true;
                        i++;
                    }
                }
            }
            return i;
        } else if (c >= '0' && c <= '9') {
            int val = to!int(to!string(c));
            i++;
            if (i >= s.length) {
                addToSet(val, -1, -1, type);
            } else {
                c = s[i];
                if (c >= '0' && c <= '9') {
                    ValueSet vs = getValue(val, s, i);
                    val = vs.value;
                    i = vs.pos;
                }
                i = checkNext(i, s, val, type);
                return i;
            }
        } else {
            throw new ParseException("Unexpected character: " ~ c, i);
        }

        return i;
    }

    private void checkIncrementRange(int incr, int type, int idxPos) {
        if (incr > 59 && (type == SECOND || type == MINUTE)) {
            throw new ParseException("Increment > 60 : " ~ incr.to!string(), idxPos);
        } else if (incr > 23 && (type == HOUR)) {
            throw new ParseException("Increment > 24 : " ~ incr.to!string(), idxPos);
        } else if (incr > 31 && (type == DAY_OF_MONTH)) {
            throw new ParseException("Increment > 31 : " ~ incr.to!string(), idxPos);
        } else if (incr > 7 && (type == DAY_OF_WEEK)) {
            throw new ParseException("Increment > 7 : " ~ incr.to!string(), idxPos);
        } else if (incr > 12 && (type == MONTH)) {
            throw new ParseException("Increment > 12 : " ~ incr.to!string(), idxPos);
        }
    }

    protected int checkNext(int pos, string s, int val, int type) {
        
        int end = -1;
        int i = pos;

        if (i >= s.length) {
            addToSet(val, end, -1, type);
            return i;
        }

        char c = s[pos];

        if (c == 'L') {
            if (type == DAY_OF_WEEK) {
                if(val < 1 || val > 7)
                    throw new ParseException("Day-of-Week values must be between 1 and 7", -1);
                lastdayOfWeek = true;
            } else {
                throw new ParseException("'L' option is not valid here. (pos=" ~ i.to!string() ~ ")", i);
            }
            TreeSet!(int) set = getSet(type);
            set.add(val);
            i++;
            return i;
        }
        
        if (c == 'W') {
            if (type == DAY_OF_MONTH) {
                nearestWeekday = true;
            } else {
                throw new ParseException("'W' option is not valid here. (pos=" ~ i.to!string() ~ ")", i);
            }
            if(val > 31)
                throw new ParseException("The 'W' option does not make sense with values larger than 31 (max number of days in a month)", i); 
            TreeSet!(int) set = getSet(type);
            set.add(val);
            i++;
            return i;
        }

        if (c == '#') {
            if (type != DAY_OF_WEEK) {
                throw new ParseException("'#' option is not valid here. (pos=" ~ i.to!string() ~ ")", i);
            }
            i++;
            try {
                nthdayOfWeek = to!int(s.substring(i));
                if (nthdayOfWeek < 1 || nthdayOfWeek > 5) {
                    throw new Exception("");
                }
            } catch (Exception e) {
                throw new ParseException(
                        "A numeric value between 1 and 5 must follow the '#' option",
                        i);
            }

            TreeSet!(int) set = getSet(type);
            set.add(val);
            i++;
            return i;
        }

        if (c == '-') {
            i++;
            c = s[i];
            int v = to!int(c);
            end = v;
            i++;
            if (i >= s.length) {
                addToSet(val, end, 1, type);
                return i;
            }
            c = s[i];
            if (c >= '0' && c <= '9') {
                ValueSet vs = getValue(v, s, i);
                end = vs.value;
                i = vs.pos;
            }
            if (i < s.length && ((c = s[i]) == '/')) {
                i++;
                c = s[i];
                int v2 = to!int(to!string(c));
                i++;
                if (i >= s.length) {
                    addToSet(val, end, v2, type);
                    return i;
                }
                c = s[i];
                if (c >= '0' && c <= '9') {
                    ValueSet vs = getValue(v2, s, i);
                    int v3 = vs.value;
                    addToSet(val, end, v3, type);
                    i = vs.pos;
                    return i;
                } else {
                    addToSet(val, end, v2, type);
                    return i;
                }
            } else {
                addToSet(val, end, 1, type);
                return i;
            }
        }

        if (c == '/') {
            if ((i + 1) >= s.length || s[i + 1] == ' ' || s[i + 1] == '\t') {
                throw new ParseException("'/' must be followed by an integer.", i);
            }

            i++;
            c = s[i];
            int v2 = to!int(to!string(c));
            i++;
            if (i >= s.length) {
                checkIncrementRange(v2, type, i);
                addToSet(val, end, v2, type);
                return i;
            }
            c = s[i];
            if (c >= '0' && c <= '9') {
                ValueSet vs = getValue(v2, s, i);
                int v3 = vs.value;
                checkIncrementRange(v3, type, i);
                addToSet(val, end, v3, type);
                i = vs.pos;
                return i;
            } else {
                throw new ParseException("Unexpected character '" ~ c ~ "' after '/'", i);
            }
        }

        addToSet(val, end, 0, type);
        i++;
        return i;
    }

    string getCronExpression() {
        return cronExpression;
    }
    
    string getExpressionSummary() {
        StringBuilder buf = new StringBuilder();

        buf.append("seconds: ");
        buf.append(getExpressionSetSummary(seconds));
        buf.append("\n");
        buf.append("minutes: ");
        buf.append(getExpressionSetSummary(minutes));
        buf.append("\n");
        buf.append("hours: ");
        buf.append(getExpressionSetSummary(hours));
        buf.append("\n");
        buf.append("daysOfMonth: ");
        buf.append(getExpressionSetSummary(daysOfMonth));
        buf.append("\n");
        buf.append("months: ");
        buf.append(getExpressionSetSummary(months));
        buf.append("\n");
        buf.append("daysOfWeek: ");
        buf.append(getExpressionSetSummary(daysOfWeek));
        buf.append("\n");
        buf.append("lastdayOfWeek: ");
        buf.append(lastdayOfWeek);
        buf.append("\n");
        buf.append("nearestWeekday: ");
        buf.append(nearestWeekday);
        buf.append("\n");
        buf.append("NthDayOfWeek: ");
        buf.append(nthdayOfWeek);
        buf.append("\n");
        buf.append("lastdayOfMonth: ");
        buf.append(lastdayOfMonth);
        buf.append("\n");
        buf.append("years: ");
        buf.append(getExpressionSetSummary(years));
        buf.append("\n");

        return buf.toString();
    }

    protected string getExpressionSetSummary(Set!(int) set) {

        if (set.contains(NO_SPEC)) {
            return "?";
        }
        if (set.contains(ALL_SPEC)) {
            return "*";
        }

        StringBuilder buf = new StringBuilder();

        bool first = true;
        foreach(int iVal; set) {
            string val = iVal.to!string();
            if (!first) {
                buf.append(",");
            }
            buf.append(val);
            first = false;
        }

        return buf.toString();
    }

    protected string getExpressionSetSummary(ArrayList!(int) list) {

        if (list.contains(NO_SPEC)) {
            return "?";
        }
        if (list.contains(ALL_SPEC)) {
            return "*";
        }

        StringBuilder buf = new StringBuilder();

        bool first = true;
        foreach(int iVal; list) {
            string val = iVal.to!string();
            if (!first) {
                buf.append(",");
            }
            buf.append(val);
            first = false;
        }

        return buf.toString();
    }

    protected int skipWhiteSpace(int i, string s) {
        for (; i < s.length && (s[i] == ' ' || s[i] == '\t'); i++) {
        }

        return i;
    }

    protected int findNextWhiteSpace(int i, string s) {
        for (; i < s.length && (s[i] != ' ' || s[i] != '\t'); i++) {
        }

        return i;
    }

    protected void addToSet(int val, int end, int incr, int type) {
        
        TreeSet!(int) set = getSet(type);

        if (type == SECOND || type == MINUTE) {
            if ((val < 0 || val > 59 || end > 59) && (val != ALL_SPEC_INT)) {
                throw new ParseException(
                        "Minute and Second values must be between 0 and 59",
                        -1);
            }
        } else if (type == HOUR) {
            if ((val < 0 || val > 23 || end > 23) && (val != ALL_SPEC_INT)) {
                throw new ParseException(
                        "Hour values must be between 0 and 23", -1);
            }
        } else if (type == DAY_OF_MONTH) {
            if ((val < 1 || val > 31 || end > 31) && (val != ALL_SPEC_INT) 
                    && (val != NO_SPEC_INT)) {
                throw new ParseException(
                        "Day of month values must be between 1 and 31", -1);
            }
        } else if (type == MONTH) {
            if ((val < 1 || val > 12 || end > 12) && (val != ALL_SPEC_INT)) {
                throw new ParseException(
                        "Month values must be between 1 and 12", -1);
            }
        } else if (type == DAY_OF_WEEK) {
            if ((val == 0 || val > 7 || end > 7) && (val != ALL_SPEC_INT)
                    && (val != NO_SPEC_INT)) {
                throw new ParseException(
                        "Day-of-Week values must be between 1 and 7", -1);
            }
        }

        if ((incr == 0 || incr == -1) && val != ALL_SPEC_INT) {
            if (val != -1) {
                set.add(val);
            } else {
                set.add(NO_SPEC);
            }
            
            return;
        }

        int startAt = val;
        int stopAt = end;

        if (val == ALL_SPEC_INT && incr <= 0) {
            incr = 1;
            set.add(ALL_SPEC); // put in a marker, but also fill values
        }

        if (type == SECOND || type == MINUTE) {
            if (stopAt == -1) {
                stopAt = 59;
            }
            if (startAt == -1 || startAt == ALL_SPEC_INT) {
                startAt = 0;
            }
        } else if (type == HOUR) {
            if (stopAt == -1) {
                stopAt = 23;
            }
            if (startAt == -1 || startAt == ALL_SPEC_INT) {
                startAt = 0;
            }
        } else if (type == DAY_OF_MONTH) {
            if (stopAt == -1) {
                stopAt = 31;
            }
            if (startAt == -1 || startAt == ALL_SPEC_INT) {
                startAt = 1;
            }
        } else if (type == MONTH) {
            if (stopAt == -1) {
                stopAt = 12;
            }
            if (startAt == -1 || startAt == ALL_SPEC_INT) {
                startAt = 1;
            }
        } else if (type == DAY_OF_WEEK) {
            if (stopAt == -1) {
                stopAt = 7;
            }
            if (startAt == -1 || startAt == ALL_SPEC_INT) {
                startAt = 1;
            }
        } else if (type == YEAR) {
            if (stopAt == -1) {
                stopAt = MAX_YEAR;
            }
            if (startAt == -1 || startAt == ALL_SPEC_INT) {
                startAt = 1970;
            }
        }

        // if the end of the range is before the start, then we need to overflow into 
        // the next day, month etc. This is done by adding the maximum amount for that 
        // type, and using modulus max to determine the value being added.
        int max = -1;
        if (stopAt < startAt) {
            switch (type) {
              case       SECOND : max = 60; break;
              case       MINUTE : max = 60; break;
              case         HOUR : max = 24; break;
              case        MONTH : max = 12; break;
              case  DAY_OF_WEEK : max = 7;  break;
              case DAY_OF_MONTH : max = 31; break;
              case         YEAR : throw new IllegalArgumentException("Start year must be less than stop year");
              default           : throw new IllegalArgumentException("Unexpected type encountered");
            }
            stopAt += max;
        }

        for (int i = startAt; i <= stopAt; i += incr) {
            if (max == -1) {
                // ie: there's no max to overflow over
                set.add(i);
            } else {
                // take the modulus to get the real value
                int i2 = i % max;

                // 1-indexed ranges should not include 0, and should include their max
                if (i2 == 0 && (type == MONTH || type == DAY_OF_WEEK || type == DAY_OF_MONTH) ) {
                    i2 = max;
                }

                set.add(i2);
            }
        }
    }

    TreeSet!(int) getSet(int type) {
        switch (type) {
            case SECOND:
                return seconds;
            case MINUTE:
                return minutes;
            case HOUR:
                return hours;
            case DAY_OF_MONTH:
                return daysOfMonth;
            case MONTH:
                return months;
            case DAY_OF_WEEK:
                return daysOfWeek;
            case YEAR:
                return years;
            default:
                return null;
        }
    }

    protected ValueSet getValue(int v, string s, int i) {
        char c = s[i];
        StringBuilder s1 = new StringBuilder(to!string(v));
        while (c >= '0' && c <= '9') {
            s1.append(c);
            i++;
            if (i >= s.length) {
                break;
            }
            c = s[i];
        }
        ValueSet val = new ValueSet();
        
        val.pos = (i < s.length) ? i : i + 1;
        val.value = to!int(s1.toString());
        return val;
    }

    protected int getNumericValue(string s, int i) {
        int endOfVal = findNextWhiteSpace(i, s);
        string val = s.substring(i, endOfVal);
        return to!int(val);
    }

    protected int getMonthNumber(string s) {
        if(monthMap.containsKey(s))
            return monthMap.get(s);
        else
            return -1;
    }

    protected int getDayOfWeekNumber(string s) {
        if(dayMap.containsKey(s))
            return dayMap.get(s);
        else 
            return -1;
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // Computation Functions
    //
    ////////////////////////////////////////////////////////////////////////////

    LocalDateTime getTimeAfter(LocalDateTime afterTime) {
        // FIXME: Needing refactor or cleanup -@zxp at 12/21/2018, 5:31:32 PM
        // 
        afterTime = afterTime.plusSeconds(1);

        bool gotOne = false;
        // loop until we've computed the next time, or we've past the endTime
        while (!gotOne) {
            if(afterTime.getYear() > 2999) { // prevent endless loop...
                return null;
            }
            // tracef("loop start: %s", afterTime.toString());

            SortedSet!(int) st = null;
            int t = 0;

            int sec = afterTime.getSecond();
            int min = afterTime.getMinute();

            // get second.................................................
            st = seconds.tailSet(sec);
            if (st !is null && st.size() != 0) {
                sec = st.first();
            } else {
                sec = seconds.first();
                afterTime = afterTime.plusMinutes(1);
            }
            afterTime = afterTime.withSecond(sec);

            min = afterTime.getMinute();
            int hr = afterTime.getHour();
            t = -1;

            // get minute.................................................
            st = minutes.tailSet(min);
            if (st !is null && st.size() != 0) {
                t = min;
                min = st.first();
            } else {
                min = minutes.first();
                // hr++;
                afterTime = afterTime.plusHours(1);
            }

            // version (HUNT_QUARTZ_DEBUG) tracef("t:%d, min:%d", t, min);
            if (min != t) {
                // afterTime = LocalDateTime.of(afterTime.getYear(), afterTime.getMonthValue(), 
                //     afterTime.getDayOfMonth(), hr, min, 0);
                afterTime = afterTime.withMinute(min).withSecond(0);
                continue;
            }
            afterTime = afterTime.withMinute(min);

            hr = afterTime.getHour();
            int day = afterTime.getDayOfMonth();
            t = -1;

            // get hour...................................................
            st = hours.tailSet(hr);
            if (st !is null && st.size() != 0) {
                t = hr;
                hr = st.first();
            } else {
                hr = hours.first();
                // day++;
                afterTime = afterTime.plusDays(1);
            }

            // version (HUNT_QUARTZ_DEBUG) tracef("hr:%d, t:%d", hr, t);

            if (hr != t) {
                afterTime = afterTime.withHour(hr).withMinute(0).withSecond(0);
                continue;
            }
            afterTime = afterTime.withHour(hr);

            int afterTimeYear = afterTime.getYear();
            day = afterTime.getDayOfMonth();
            int mon = afterTime.getMonthValue();

            t = -1;
            int tmon = mon;
            
            // get day...................................................
            bool dayOfMSpec = !daysOfMonth.contains(NO_SPEC);
            bool dayOfWSpec = !daysOfWeek.contains(NO_SPEC);
            if (dayOfMSpec && !dayOfWSpec) { // get day by day of month rule
                st = daysOfMonth.tailSet(day);
                if (lastdayOfMonth) {
                    if(!nearestWeekday) {
                        t = day;
                        day = getLastDayOfMonth(mon, afterTimeYear);
                        day -= lastdayOffset;
                        if(t > day) {
                            mon++;
                            if(mon > 12) { 
                                mon = 1;
                                tmon = 3333; // ensure test of mon != tmon further below fails
                                afterTime.plusYears(1);
                                afterTimeYear = afterTime.getYear(); 
                            }
                            day = 1;
                        }
                    } else {
                        t = day;
                        day = getLastDayOfMonth(mon, afterTimeYear);
                        day -= lastdayOffset;
                        
                        LocalDateTime tTime = LocalDateTime.of(afterTimeYear, mon, day, 0, 0, 0);
                        
                        int ldom = getLastDayOfMonth(mon, afterTimeYear);
                        int dow = tTime.getDayOfWeek().getValue();

                        if(dow == DayOfWeek.SATURDAY.getValue() && day == 1) {
                            day += 2;
                        } else if(dow == DayOfWeek.SATURDAY.getValue()) {
                            day -= 1;
                        } else if(dow == DayOfWeek.SUNDAY.getValue() && day == ldom) { 
                            day -= 2;
                        } else if(dow == DayOfWeek.SUNDAY.getValue()) { 
                            day += 1;
                        }

                        LocalDateTime nTime = LocalDateTime.of(afterTimeYear, mon, day, hr, min, sec); 

                        if(nTime.isBefore(afterTime)) {
                            day = 1;
                            mon++;
                        }
                    }
                } else if(nearestWeekday) {
                    t = day;
                    day = daysOfMonth.first();

                    LocalDateTime tTime = LocalDateTime.of(afterTimeYear, mon, day, 0, 0, 0);
                    
                    int ldom = getLastDayOfMonth(mon, afterTimeYear);
                    int dow = tTime.getDayOfWeek().getValue();

                    if(dow == DayOfWeek.SATURDAY.getValue() && day == 1) {
                        day += 2;
                    } else if(dow == DayOfWeek.SATURDAY.getValue()) {
                        day -= 1;
                    } else if(dow == DayOfWeek.SUNDAY.getValue() && day == ldom) { 
                        day -= 2;
                    } else if(dow == DayOfWeek.SUNDAY.getValue()) { 
                        day += 1;
                    }

                    LocalDateTime nTime = LocalDateTime.of(afterTimeYear, mon, day, hr, min, sec);
                    if(nTime.isBefore(afterTime)) {
                        day = daysOfMonth.first();
                        mon++;
                    }
                } else if (st !is null && st.size() != 0) {
                    t = day;
                    day = st.first();
                    // make sure we don't over-run a short month, such as february
                    int lastDay = getLastDayOfMonth(mon, afterTime.getYear());
                    if (day > lastDay) {
                        day = daysOfMonth.first();
                        mon++;
                    }
                } else {
                    day = daysOfMonth.first();
                    mon++;
                }
                
                // version (HUNT_QUARTZ_DEBUG) tracef("day:%d, t:%d, mon:%d, tmon:%d", day, t, mon, tmon);

                if (day != t || mon != tmon) {
                    afterTime = LocalDateTime.of(afterTimeYear, mon, day, 0, 0, 0);
                    continue;
                }
            } else if (dayOfWSpec && !dayOfMSpec) { // get day by day of week rule

                // int afterTimeYear = afterTime.getYear();
                if (lastdayOfWeek) { // are we looking for the last XXX day of
                    // the month?
                    int dow = daysOfWeek.first(); // desired
                    // d-o-w
                    int cDow = afterTime.getDayOfWeek().getValue(); // current d-o-w
                    int daysToAdd = 0;
                    if (cDow < dow) {
                        daysToAdd = dow - cDow;
                    }
                    if (cDow > dow) {
                        daysToAdd = dow + (7 - cDow);
                    }

                    int lDay = getLastDayOfMonth(mon, afterTimeYear);

                    if (day + daysToAdd > lDay) { // did we already miss the
                        // last one?
                        afterTime = LocalDateTime.of(afterTimeYear, mon, 1, 0, 0, 0);
                        continue;
                    }

                    // find date of last occurrence of this day in this month...
                    while ((day + daysToAdd + 7) <= lDay) {
                        daysToAdd += 7;
                    }

                    day += daysToAdd;

                    if (daysToAdd > 0) {
                        afterTime = LocalDateTime.of(afterTimeYear, mon, day, 0, 0, 0);
                        continue;
                    }

                } else if (nthdayOfWeek != 0) {
                    // are we looking for the Nth XXX day in the month?
                    int dow = daysOfWeek.first(); // desired
                    // d-o-w
                    int cDow = afterTime.getDayOfWeek().getValue(); // current d-o-w
                    int daysToAdd = 0;
                    if (cDow < dow) {
                        daysToAdd = dow - cDow;
                    } else if (cDow > dow) {
                        daysToAdd = dow + (7 - cDow);
                    }

                    bool dayShifted = false;
                    if (daysToAdd > 0) {
                        dayShifted = true;
                    }

                    day += daysToAdd;
                    int weekOfMonth = day / 7;
                    if (day % 7 > 0) {
                        weekOfMonth++;
                    }

                    daysToAdd = (nthdayOfWeek - weekOfMonth) * 7;
                    day += daysToAdd;
                    if (daysToAdd < 0
                            || day > getLastDayOfMonth(mon, afterTimeYear)) {
                        
                        afterTime = LocalDateTime.of(afterTimeYear, mon, 1, 0, 0, 0);
                        continue;
                    } else if (daysToAdd > 0 || dayShifted) {
                        afterTime = LocalDateTime.of(afterTimeYear, mon, day, 0, 0, 0);
                        continue;
                    }
                } else {
                    int cDow = afterTime.getDayOfWeek().getValue(); //  cl.get(Calendar.DAY_OF_WEEK); // current d-o-w
                    int dow = daysOfWeek.first(); // desired
                    // d-o-w
                    st = daysOfWeek.tailSet(cDow);
                    if (st !is null && st.size() > 0) {
                        dow = st.first();
                    }

                    int daysToAdd = 0;
                    if (cDow < dow) {
                        daysToAdd = dow - cDow;
                    }
                    if (cDow > dow) {
                        daysToAdd = dow + (7 - cDow);
                    }

                    int lDay = getLastDayOfMonth(mon, afterTime.getYear());

                    if (day + daysToAdd > lDay) { // will we pass the end of
                        // the month?
                        afterTime = LocalDateTime.of(afterTime.getYear(), mon, 1, 0, 0, 0);
                        continue;
                    } else if (daysToAdd > 0) { // are we swithing days?
                        afterTime = LocalDateTime.of(afterTime.getYear(), mon, day + daysToAdd, 0, 0, 0);
                        continue;
                    }
                }
            } else { // dayOfWSpec && !dayOfMSpec
                throw new UnsupportedOperationException(
                        "Support for specifying both a day-of-week AND a day-of-month parameter is not implemented.");
            }

            afterTime = afterTime.withDayOfMonth(day);

            mon = afterTime.getMonthValue();
            int year = afterTime.getYear();
            t = -1;

            // test for expressions that never generate a valid fire date,
            // but keep looping...
            if (year > MAX_YEAR) {
                return null;
            }

            // get month...................................................
            st = months.tailSet(mon);
            if (st !is null && st.size() != 0) {
                t = mon;
                mon = st.first();
            } else {
                mon = months.first();
                year++;
            }
            if (mon != t) {
                afterTime = LocalDateTime.of(year, mon, 1, 0, 0, 0);
                continue;
            }
            afterTime = afterTime.withMonth(mon);

            year = afterTime.getYear();
            t = -1;

            // get year...................................................
            st = years.tailSet(year);
            if (st !is null && st.size() != 0) {
                t = year;
                year = st.first();
            } else {
                return null; // ran out of years...
            }

            if (year != t) {
                afterTime = LocalDateTime.of(year, 1, 1, 0, 0, 0);
                continue;
            }
            afterTime = afterTime.withYear(year);
            gotOne = true;
        } // while( !done )

        // info("loop end: ", afterTime.toString());

        return afterTime; 
    }


    /**
     * Advance the calendar to the particular hour paying particular attention
     * to daylight saving problems.
     * 
     * @param cal the calendar to operate on
     * @param hour the hour to set
     */
    // protected void setCalendarHour(Calendar cal, int hour) {
    //     cal.set(hunt.time.util.Calendar.HOUR_OF_DAY, hour);
    //     if (cal.get(hunt.time.util.Calendar.HOUR_OF_DAY) != hour && hour != 24) {
    //         cal.set(hunt.time.util.Calendar.HOUR_OF_DAY, hour + 1);
    //     }
    // }

    /**
     * NOT YET IMPLEMENTED: Returns the time before the given time
     * that the <code>CronExpression</code> matches.
     */ 
    LocalDateTime getTimeBefore(LocalDateTime endTime) { 
        // FUTURE_TODO: implement QUARTZ-423
        return null;
    }

    /**
     * NOT YET IMPLEMENTED: Returns the final time that the 
     * <code>CronExpression</code> will match.
     */
    LocalDateTime getFinalFireTime() {
        // FUTURE_TODO: implement QUARTZ-423
        return null;
    }
    
    protected bool isLeapYear(int year) {
        return ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0));
    }

    protected int getLastDayOfMonth(int monthNum, int year) {

        switch (monthNum) {
            case 1:
                return 31;
            case 2:
                return (isLeapYear(year)) ? 29 : 28;
            case 3:
                return 31;
            case 4:
                return 30;
            case 5:
                return 31;
            case 6:
                return 30;
            case 7:
                return 31;
            case 8:
                return 31;
            case 9:
                return 30;
            case 10:
                return 31;
            case 11:
                return 30;
            case 12:
                return 31;
            default:
                throw new IllegalArgumentException("Illegal month number: "
                        ~ monthNum.to!string());
        }
    }
    

    // private void readObject(java.io.ObjectInputStream stream) {
        
    //     stream.defaultReadObject();
    //     try {
    //         buildExpression(cronExpression);
    //     } catch (Exception ignore) {
    //     } // never happens
    // }    
    
    // override
    // deprecated("")
    // Object clone() {
    //     return new CronExpression(this);
    // }
}

class ValueSet {
    int value;

    int pos;
}
