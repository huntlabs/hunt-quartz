module hunt.quartz.impl.calendar.CronCalendar;

import hunt.quartz.impl.calendar.BaseCalendar;
import hunt.quartz.Calendar;
import hunt.quartz.CronExpression;

import hunt.collection.StringBuffer;
import hunt.Exceptions;
import hunt.time.Instant;
import hunt.time.LocalDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;

/**
 * This implementation of the Calendar excludes the set of times expressed by a
 * given {@link hunt.quartz.CronExpression CronExpression}. For example, you 
 * could use this calendar to exclude all but business hours (8AM - 5PM) every 
 * day using the expression &quot;* * 0-7,18-23 ? * *&quot;. 
 * <P>
 * It is important to remember that the cron expression here describes a set of
 * times to be <I>excluded</I> from firing. Whereas the cron expression in 
 * {@link hunt.quartz.CronTrigger CronTrigger} describes a set of times that can
 * be <I>included</I> for firing. Thus, if a <CODE>CronTrigger</CODE> has a 
 * given cron expression and is associated with a <CODE>CronCalendar</CODE> with
 * the <I>same</I> expression, the calendar will exclude all the times the 
 * trigger includes, and they will cancel each other out. 
 * 
 * @author Aaron Craven
 */
class CronCalendar : BaseCalendar {

    CronExpression cronExpression;

    /**
     * Create a <CODE>CronCalendar</CODE> with the given cron expression and no
     * <CODE>baseCalendar</CODE>.
     *  
     * @param expression a string representation of the desired cron expression
     */
    this(string expression) {
        this(null, expression, null);
    }

    /**
     * Create a <CODE>CronCalendar</CODE> with the given cron expression and 
     * <CODE>baseCalendar</CODE>. 
     * 
     * @param baseCalendar the base calendar for this calendar instance &ndash;
     *                     see {@link BaseCalendar} for more information on base
     *                     calendar functionality
     * @param expression   a string representation of the desired cron expression
     */
    this(Calendar baseCalendar,
            string expression) {
        this(baseCalendar, expression, null);
    }

    /**
     * Create a <CODE>CronCalendar</CODE> with the given cron exprssion, 
     * <CODE>baseCalendar</CODE>, and <code>ZoneId</code>. 
     * 
     * @param baseCalendar the base calendar for this calendar instance &ndash;
     *                     see {@link BaseCalendar} for more information on base
     *                     calendar functionality
     * @param expression   a string representation of the desired cron expression
     * @param timeZone
     *          Specifies for which time zone the <code>expression</code>
     *          should be interpreted, i.e. the expression 0 0 10 * * ?, is
     *          resolved to 10:00 am in this time zone.  If 
     *          <code>timeZone</code> is <code>null</code> then 
     *          <code>ZoneId.getDefault()</code> will be used.
     */
    this(Calendar baseCalendar,
            string expression, ZoneId timeZone) {
        super(baseCalendar);
        this.cronExpression = new CronExpression(expression);
        this.cronExpression.setTimeZone(timeZone);
    }
    
    override
    Object clone() {
        CronCalendar clone = cast(CronCalendar) super.clone();
        clone.cronExpression = new CronExpression(cronExpression);
        return clone;
    }

    /**
     * Returns the time zone for which the <code>CronExpression</code> of
     * this <code>CronCalendar</code> will be resolved.
     * <p>
     * Overrides <code>{@link BaseCalendar#getTimeZone()}</code> to
     * defer to its <code>CronExpression</code>.
     * </p>
     */
    override
    ZoneId getTimeZone() {
        return cronExpression.getTimeZone();
    }

    /**
     * Sets the time zone for which the <code>CronExpression</code> of this
     * <code>CronCalendar</code> will be resolved.  If <code>timeZone</code> 
     * is <code>null</code> then <code>ZoneId.getDefault()</code> will be 
     * used.
     * <p>
     * Overrides <code>{@link BaseCalendar#setTimeZone(ZoneId)}</code> to
     * defer to its <code>CronExpression</code>.
     * </p>
     */
    override
    void setTimeZone(ZoneId timeZone) {
        cronExpression.setTimeZone(timeZone);
    }
    
    /**
     * Determines whether the given time (in milliseconds) is 'included' by the
     * <CODE>BaseCalendar</CODE>
     * 
     * @param timeInMillis the date/time to test
     * @return a bool indicating whether the specified time is 'included' by
     *         the <CODE>CronCalendar</CODE>
     */
    override
    bool isTimeIncluded(long timeInMillis) {        
        if ((getBaseCalendar() !is null) && 
                (getBaseCalendar().isTimeIncluded(timeInMillis) == false)) {
            return false;
        }

        LocalDateTime ldt = LocalDateTime.ofInstant(Instant.ofEpochMilli(timeInMillis), getTimeZone());
        
        return (!(cronExpression.isSatisfiedBy(ldt)));
    }

    /**
     * Determines the next time included by the <CODE>CronCalendar</CODE>
     * after the specified time.
     * 
     * @param timeInMillis the initial date/time after which to find an 
     *                     included time
     * @return the time in milliseconds representing the next time included
     *         after the specified time.
     */
    override
    long getNextIncludedTime(long timeInMillis) {
        long nextIncludedTime = timeInMillis + 1; //plus on millisecond
        
        while (!isTimeIncluded(nextIncludedTime)) {

            //If the time is in a range excluded by this calendar, we can
            // move to the end of the excluded time range and continue testing
            // from there. Otherwise, if nextIncludedTime is excluded by the
            // baseCalendar, ask it the next time it includes and begin testing
            // from there. Failing this, add one millisecond and continue
            // testing.

            LocalDateTime ldt = LocalDateTime.ofInstant(Instant.ofEpochMilli(nextIncludedTime), getTimeZone());
            if (cronExpression.isSatisfiedBy(ldt)) {
                nextIncludedTime = cronExpression.getNextInvalidTimeAfter(ldt).toEpochMilli();
            } else if ((getBaseCalendar() !is null) && 
                    (!getBaseCalendar().isTimeIncluded(nextIncludedTime))){
                nextIncludedTime = 
                    getBaseCalendar().getNextIncludedTime(nextIncludedTime);
            } else {
                nextIncludedTime++;
            }
        }
        
        return nextIncludedTime;
    }

    /**
     * Returns a string representing the properties of the 
     * <CODE>CronCalendar</CODE>
     * 
     * @return the properteis of the CronCalendar in a string format
     */
    override
    string toString() {
        StringBuffer buffer = new StringBuffer();
        buffer.append("base calendar: [");
        if (getBaseCalendar() !is null) {
            buffer.append((cast(Object)getBaseCalendar()).toString());
        } else {
            buffer.append("null");
        }
        buffer.append("], excluded cron expression: '");
        buffer.append(cronExpression.toString());
        buffer.append("'");
        return buffer.toString();
    }
    
    /**
     * Returns the object representation of the cron expression that defines the
     * dates and times this calendar excludes.
     * 
     * @return the cron expression
     * @see hunt.quartz.CronExpression
     */
    CronExpression getCronExpression() {
        return cronExpression;
    }
    
    /**
     * Sets the cron expression for the calendar to a new value
     * 
     * @param expression the new string value to build a cron expression from
     * @throws ParseException
     *         if the string expression cannot be parsed
     */
    void setCronExpression(string expression) {
        CronExpression newExp = new CronExpression(expression);
        
        this.cronExpression = newExp;
    }

    /**
     * Sets the cron expression for the calendar to a new value
     * 
     * @param expression the new cron expression
     */
    void setCronExpression(CronExpression expression) {
        if (expression is null) {
            throw new IllegalArgumentException("expression cannot be null");
        }
        
        this.cronExpression = expression;
    }
}