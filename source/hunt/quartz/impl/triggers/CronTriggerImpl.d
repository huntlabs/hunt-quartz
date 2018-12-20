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

module hunt.quartz.impl.triggers.CronTriggerImpl;

import hunt.quartz.impl.triggers.AbstractTrigger;
import hunt.quartz.impl.triggers.CoreTrigger;

import hunt.quartz.Calendar;
import hunt.quartz.CronExpression;
import hunt.quartz.CronScheduleBuilder;
import hunt.quartz.CronTrigger;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.exception;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.Scheduler;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerUtils;

import hunt.lang.exception;
import hunt.time.util.Calendar;

import std.datetime;

/**
 * <p>
 * A concrete <code>{@link Trigger}</code> that is used to fire a <code>{@link hunt.quartz.JobDetail}</code>
 * at given moments in time, defined with Unix 'cron-like' definitions.
 * </p>
 * 
 * 
 * @author Sharada Jambula, James House
 * @author Contributions from Mads Henderson
 */
class CronTriggerImpl : AbstractTrigger!(CronTrigger), CronTrigger, CoreTrigger {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Required for serialization support. Introduced in Quartz 1.6.1 to 
     * maintain compatibility after the introduction of hasAdditionalProperties
     * method. 
     * 
     * @see java.io.Serializable
     */

    protected enum int YEAR_TO_GIVEUP_SCHEDULING_AT = CronExpression.MAX_YEAR;
    
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private CronExpression cronEx = null;
    private Date startTime;// = null;
    private Date endTime;// = null;
    private Date nextFireTime;// = null;
    private Date previousFireTime;// = null;
    private TimeZone timeZone = null;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a <code>CronTrigger</code> with no settings.
     * </p>
     * 
     * <p>
     * The start-time will also be set to the current time, and the time zone
     * will be set the the system's default time zone.
     * </p>
     */
    this() {
        super();
        setStartTime(new Date());
        setTimeZone(TimeZone.getDefault());
    }

    // /**
    //  * <p>
    //  * Create a <code>CronTrigger</code> with the given name and default group.
    //  * </p>
    //  * 
    //  * <p>
    //  * The start-time will also be set to the current time, and the time zone
    //  * will be set the the system's default time zone.
    //  * </p>
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name) {
    //     this(name, null);
    // }
    
    // /**
    //  * <p>
    //  * Create a <code>CronTrigger</code> with the given name and group.
    //  * </p>
    //  * 
    //  * <p>
    //  * The start-time will also be set to the current time, and the time zone
    //  * will be set the the system's default time zone.
    //  * </p>
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name, string group) {
    //     super(name, group);
    //     setStartTime(new Date());
    //     setTimeZone(TimeZone.getDefault());
    // }

    // /**
    //  * <p>
    //  * Create a <code>CronTrigger</code> with the given name, group and
    //  * expression.
    //  * </p>
    //  * 
    //  * <p>
    //  * The start-time will also be set to the current time, and the time zone
    //  * will be set the the system's default time zone.
    //  * </p>
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name, string group, string cronExpression) {
        
    //     super(name, group);

    //     setCronExpression(cronExpression);

    //     setStartTime(new Date());
    //     setTimeZone(TimeZone.getDefault());
    // }
    
    // /**
    //  * <p>
    //  * Create a <code>CronTrigger</code> with the given name and group, and
    //  * associated with the identified <code>{@link hunt.quartz.JobDetail}</code>.
    //  * </p>
    //  * 
    //  * <p>
    //  * The start-time will also be set to the current time, and the time zone
    //  * will be set the the system's default time zone.
    //  * </p>
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name, string group, string jobName,
    //         string jobGroup) {
    //     super(name, group, jobName, jobGroup);
    //     setStartTime(new Date());
    //     setTimeZone(TimeZone.getDefault());
    // }

    // /**
    //  * <p>
    //  * Create a <code>CronTrigger</code> with the given name and group,
    //  * associated with the identified <code>{@link hunt.quartz.JobDetail}</code>,
    //  * and with the given "cron" expression.
    //  * </p>
    //  * 
    //  * <p>
    //  * The start-time will also be set to the current time, and the time zone
    //  * will be set the the system's default time zone.
    //  * </p>
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name, string group, string jobName,
    //         string jobGroup, string cronExpression) {
    //     this(name, group, jobName, jobGroup, null, null, cronExpression,
    //             TimeZone.getDefault());
    // }

    // /**
    //  * <p>
    //  * Create a <code>CronTrigger</code> with the given name and group,
    //  * associated with the identified <code>{@link hunt.quartz.JobDetail}</code>,
    //  * and with the given "cron" expression resolved with respect to the <code>TimeZone</code>.
    //  * </p>
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name, string group, string jobName,
    //         string jobGroup, string cronExpression, TimeZone timeZone) {
    //     this(name, group, jobName, jobGroup, null, null, cronExpression,
    //             timeZone);
    // }

    // /**
    //  * <p>
    //  * Create a <code>CronTrigger</code> that will occur at the given time,
    //  * until the given end time.
    //  * </p>
    //  * 
    //  * <p>
    //  * If null, the start-time will also be set to the current time, the time
    //  * zone will be set the the system's default.
    //  * </p>
    //  * 
    //  * @param startTime
    //  *          A <code>Date</code> set to the time for the <code>Trigger</code>
    //  *          to fire.
    //  * @param endTime
    //  *          A <code>Date</code> set to the time for the <code>Trigger</code>
    //  *          to quit repeat firing.
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name, string group, string jobName,
    //         string jobGroup, Date startTime, Date endTime, string cronExpression) {
    //     super(name, group, jobName, jobGroup);

    //     setCronExpression(cronExpression);

    //     if (startTime is null) {
    //         startTime = new Date();
    //     }
    //     setStartTime(startTime);
    //     if (endTime !is null) {
    //         setEndTime(endTime);
    //     }
    //     setTimeZone(TimeZone.getDefault());

    // }

    // /**
    //  * <p>
    //  * Create a <code>CronTrigger</code> with fire time dictated by the
    //  * <code>cronExpression</code> resolved with respect to the specified
    //  * <code>timeZone</code> occurring from the <code>startTime</code> until
    //  * the given <code>endTime</code>.
    //  * </p>
    //  * 
    //  * <p>
    //  * If null, the start-time will also be set to the current time. If null,
    //  * the time zone will be set to the system's default.
    //  * </p>
    //  * 
    //  * @param name
    //  *          of the <code>Trigger</code>
    //  * @param group
    //  *          of the <code>Trigger</code>
    //  * @param jobName
    //  *          name of the <code>{@link hunt.quartz.JobDetail}</code>
    //  *          executed on firetime
    //  * @param jobGroup
    //  *          group of the <code>{@link hunt.quartz.JobDetail}</code>
    //  *          executed on firetime
    //  * @param startTime
    //  *          A <code>Date</code> set to the earliest time for the <code>Trigger</code>
    //  *          to start firing.
    //  * @param endTime
    //  *          A <code>Date</code> set to the time for the <code>Trigger</code>
    //  *          to quit repeat firing.
    //  * @param cronExpression
    //  *          A cron expression dictating the firing sequence of the <code>Trigger</code>
    //  * @param timeZone
    //  *          Specifies for which time zone the <code>cronExpression</code>
    //  *          should be interpreted, i.e. the expression 0 0 10 * * ?, is
    //  *          resolved to 10:00 am in this time zone.
    //  * @throws ParseException
    //  *           if the <code>cronExpression</code> is invalid.
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name, string group, string jobName,
    //         string jobGroup, Date startTime, Date endTime,
    //         string cronExpression, TimeZone timeZone) {
    //     super(name, group, jobName, jobGroup);

    //     setCronExpression(cronExpression);

    //     if (startTime is null) {
    //         startTime = new Date();
    //     }
    //     setStartTime(startTime);
    //     if (endTime !is null) {
    //         setEndTime(endTime);
    //     }
    //     if (timeZone is null) {
    //         setTimeZone(TimeZone.getDefault());
    //     } else {
    //         setTimeZone(timeZone);
    //     }
    // }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */
    
    // override
    // Object clone() {
    //     CronTriggerImpl copy = (CronTriggerImpl) super.clone();
    //     if (cronEx !is null) {
    //         copy.setCronExpression(new CronExpression(cronEx));
    //     }
    //     return copy;
    // }

    void setCronExpression(string cronExpression) {
        TimeZone origTz = getTimeZone();
        this.cronEx = new CronExpression(cronExpression);
        this.cronEx.setTimeZone(origTz);
    }

    /* (non-Javadoc)
     * @see hunt.quartz.CronTriggerI#getCronExpression()
     */
    string getCronExpression() {
        return cronEx is null ? null : cronEx.getCronExpression();
    }

    /**
     * Set the CronExpression to the given one.  The TimeZone on the passed-in
     * CronExpression over-rides any that was already set on the Trigger.
     */
    void setCronExpression(CronExpression cronExpression) {
        this.cronEx = cronExpression;
        this.timeZone = cronExpression.getTimeZone();
    }
    
    /**
     * <p>
     * Get the time at which the <code>CronTrigger</code> should occur.
     * </p>
     */
    override
    Date getStartTime() {
        return this.startTime;
    }

    override
    void setStartTime(Date startTime) {
        if (startTime is null) {
            throw new IllegalArgumentException("Start time cannot be null");
        }

        Date eTime = getEndTime();
        if (eTime !is null && eTime.before(startTime)) {
            throw new IllegalArgumentException(
                "End time cannot be before start time");
        }
        
        // round off millisecond...
        // Note timeZone is not needed here as parameter for
        // Calendar.getInstance(),
        // since time zone is implicit when using a Date in the setTime method.
        Calendar cl = Calendar.getInstance();
        cl.setTime(startTime);
        cl.set(Calendar.MILLISECOND, 0);

        this.startTime = cl.getTime();
    }

    /**
     * <p>
     * Get the time at which the <code>CronTrigger</code> should quit
     * repeating - even if repeastCount isn't yet satisfied.
     * </p>
     * 
     * @see #getFinalFireTime()
     */
    override
    Date getEndTime() {
        return this.endTime;
    }

    override
    void setEndTime(Date endTime) {
        Date sTime = getStartTime();
        if (sTime !is null && endTime !is null && sTime.after(endTime)) {
            throw new IllegalArgumentException(
                    "End time cannot be before start time");
        }

        this.endTime = endTime;
    }

    /**
     * <p>
     * Returns the next time at which the <code>Trigger</code> is scheduled to fire. If
     * the trigger will not fire again, <code>null</code> will be returned.  Note that
     * the time returned can possibly be in the past, if the time that was computed
     * for the trigger to next fire has already arrived, but the scheduler has not yet
     * been able to fire the trigger (which would likely be due to lack of resources
     * e.g. threads).
     * </p>
     *
     * <p>The value returned is not guaranteed to be valid until after the <code>Trigger</code>
     * has been added to the scheduler.
     * </p>
     *
     * @see TriggerUtils#computeFireTimesBetween(hunt.quartz.spi.OperableTrigger, QuartzCalendar, java.util.Date, java.util.Date)
     */
    override
    Date getNextFireTime() {
        return this.nextFireTime;
    }

    /**
     * <p>
     * Returns the previous time at which the <code>CronTrigger</code> 
     * fired. If the trigger has not yet fired, <code>null</code> will be
     * returned.
     */
    override
    Date getPreviousFireTime() {
        return this.previousFireTime;
    }

    /**
     * <p>
     * Sets the next time at which the <code>CronTrigger</code> will fire.
     * <b>This method should not be invoked by client code.</b>
     * </p>
     */
    void setNextFireTime(Date nextFireTime) {
        this.nextFireTime = nextFireTime;
    }

    /**
     * <p>
     * Set the previous time at which the <code>CronTrigger</code> fired.
     * </p>
     * 
     * <p>
     * <b>This method should not be invoked by client code.</b>
     * </p>
     */
    void setPreviousFireTime(Date previousFireTime) {
        this.previousFireTime = previousFireTime;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.CronTriggerI#getTimeZone()
     */
    TimeZone getTimeZone() {
        
        if(cronEx !is null) {
            return cronEx.getTimeZone();
        }
        
        if (timeZone is null) {
            timeZone = TimeZone.getDefault();
        }
        return timeZone;
    }

    /**
     * <p>
     * Sets the time zone for which the <code>cronExpression</code> of this
     * <code>CronTrigger</code> will be resolved.
     * </p>
     * 
     * <p>If {@link #setCronExpression(CronExpression)} is called after this
     * method, the TimeZon setting on the CronExpression will "win".  However
     * if {@link #setCronExpression(string)} is called after this method, the
     * time zone applied by this method will remain in effect, since the 
     * string cron expression does not carry a time zone!
     */
    void setTimeZone(TimeZone timeZone) {
        if(cronEx !is null) {
            cronEx.setTimeZone(timeZone);
        }
        this.timeZone = timeZone;
    }

    /**
     * <p>
     * Returns the next time at which the <code>CronTrigger</code> will fire,
     * after the given time. If the trigger will not fire after the given time,
     * <code>null</code> will be returned.
     * </p>
     * 
     * <p>
     * Note that the date returned is NOT validated against the related
     * QuartzCalendar (if any)
     * </p>
     */
    override
    Date getFireTimeAfter(Date afterTime) {
        if (afterTime is null) {
            afterTime = new Date();
        }

        if (getStartTime().after(afterTime)) {
            afterTime = new Date(getStartTime().getTime() - 1000);
        }

        if (getEndTime() !is null && (afterTime.compareTo(getEndTime()) >= 0)) {
            return null;
        }
        
        Date pot = getTimeAfter(afterTime);
        if (getEndTime() !is null && pot !is null && pot.after(getEndTime())) {
            return null;
        }

        return pot;
    }

    /**
     * <p>
     * NOT YET IMPLEMENTED: Returns the final time at which the 
     * <code>CronTrigger</code> will fire.
     * </p>
     * 
     * <p>
     * Note that the return time *may* be in the past. and the date returned is
     * not validated against hunt.quartz.calendar
     * </p>
     */
    override
    Date getFinalFireTime() {
        Date resultTime;
        if (getEndTime() !is null) {
            resultTime = getTimeBefore(new Date(getEndTime().getTime() + 1000));
        } else {
            resultTime = (cronEx is null) ? null : cronEx.getFinalFireTime();
        }
        
        if ((resultTime !is null) && (getStartTime() !is null) && (resultTime.before(getStartTime()))) {
            return null;
        } 
        
        return resultTime;
    }

    /**
     * <p>
     * Determines whether or not the <code>CronTrigger</code> will occur
     * again.
     * </p>
     */
    override
    bool mayFireAgain() {
        return (getNextFireTime() !is null);
    }

    override
    protected bool validateMisfireInstruction(int misfireInstruction) {
        return misfireInstruction >= MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY && misfireInstruction <= MISFIRE_INSTRUCTION_DO_NOTHING;
    }

    /**
     * <p>
     * Updates the <code>CronTrigger</code>'s state based on the
     * MISFIRE_INSTRUCTION_XXX that was selected when the <code>CronTrigger</code>
     * was created.
     * </p>
     * 
     * <p>
     * If the misfire instruction is set to MISFIRE_INSTRUCTION_SMART_POLICY,
     * then the following scheme will be used: <br>
     * <ul>
     * <li>The instruction will be interpreted as <code>MISFIRE_INSTRUCTION_FIRE_ONCE_NOW</code>
     * </ul>
     * </p>
     */
    override
    void updateAfterMisfire(QuartzCalendar cal) {
        int instr = getMisfireInstruction();

        if(instr == Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY)
            return;

        if (instr == MISFIRE_INSTRUCTION_SMART_POLICY) {
            instr = MISFIRE_INSTRUCTION_FIRE_ONCE_NOW;
        }

        if (instr == MISFIRE_INSTRUCTION_DO_NOTHING) {
            Date newFireTime = getFireTimeAfter(new Date());
            while (newFireTime !is null && cal !is null
                    && !cal.isTimeIncluded(newFireTime.getTime())) {
                newFireTime = getFireTimeAfter(newFireTime);
            }
            setNextFireTime(newFireTime);
        } else if (instr == MISFIRE_INSTRUCTION_FIRE_ONCE_NOW) {
            setNextFireTime(new Date());
        }
    }

    /**
     * <p>
     * Determines whether the date and (optionally) time of the given Calendar 
     * instance falls on a scheduled fire-time of this trigger.
     * </p>
     * 
     * <p>
     * Equivalent to calling <code>willFireOn(cal, false)</code>.
     * </p>
     * 
     * @param test the date to compare
     * 
     * @see #willFireOn(Calendar, bool)
     */
    bool willFireOn(HuntCalendar test) {
        return willFireOn(test, false);
    }
    
    /**
     * <p>
     * Determines whether the date and (optionally) time of the given Calendar 
     * instance falls on a scheduled fire-time of this trigger.
     * </p>
     * 
     * <p>
     * Note that the value returned is NOT validated against the related
     * QuartzCalendar (if any)
     * </p>
     * 
     * @param test the date to compare
     * @param dayOnly if set to true, the method will only determine if the
     * trigger will fire during the day represented by the given Calendar
     * (hours, minutes and seconds will be ignored).
     * @see #willFireOn(Calendar)
     */
    bool willFireOn(HuntCalendar test, bool dayOnly) {

        test = cast(HuntCalendar) test.clone();
        
        test.set(HuntCalendar.MILLISECOND, 0); // don't compare millis.
        
        if(dayOnly) {
            test.set(HuntCalendar.HOUR_OF_DAY, 0); 
            test.set(HuntCalendar.MINUTE, 0); 
            test.set(HuntCalendar.SECOND, 0); 
        }
        
        Date testTime = test.getTime();
        
        Date fta = getFireTimeAfter(new Date(test.getTime().getTime() - 1000));
        
        if(fta is null)
            return false;

        HuntCalendar p = HuntCalendar.getInstance(test.getTimeZone());
        p.setTime(fta);
        
        int year = p.get(HuntCalendar.YEAR);
        int month = p.get(HuntCalendar.MONTH);
        int day = p.get(HuntCalendar.DATE);
        
        if(dayOnly) {
            return (year == test.get(HuntCalendar.YEAR) 
                    && month == test.get(HuntCalendar.MONTH) 
                    && day == test.get(HuntCalendar.DATE));
        }
        
        while(fta.before(testTime)) {
            fta = getFireTimeAfter(fta);
        }

        return fta== testTime;
    }

    /**
     * <p>
     * Called when the <code>{@link Scheduler}</code> has decided to 'fire'
     * the trigger (execute the associated <code>Job</code>), in order to
     * give the <code>Trigger</code> a chance to update itself for its next
     * triggering (if any).
     * </p>
     * 
     * @see #executionComplete(JobExecutionContext, JobExecutionException)
     */
    override
    void triggered(QuartzCalendar calendar) {
        previousFireTime = nextFireTime;
        nextFireTime = getFireTimeAfter(nextFireTime);

        while (nextFireTime !is null && calendar !is null
                && !calendar.isTimeIncluded(nextFireTime.getTime())) {
            nextFireTime = getFireTimeAfter(nextFireTime);
        }
    }

    /**
     *  
     * @see AbstractTrigger#updateWithNewCalendar(QuartzCalendar, long)
     */
    override
    void updateWithNewCalendar(QuartzCalendar calendar, long misfireThreshold)
    {
        nextFireTime = getFireTimeAfter(previousFireTime);
        
        if (nextFireTime is null || calendar is null) {
            return;
        }
        
        Date now = new Date();
        while (nextFireTime !is null && !calendar.isTimeIncluded(nextFireTime.getTime())) {

            nextFireTime = getFireTimeAfter(nextFireTime);

            if(nextFireTime is null)
                break;
            
            //avoid infinite loop
            // Use gregorian only because the constant is based on Gregorian
            HuntCalendar c = new java.util.GregorianCalendar(); 
            c.setTime(nextFireTime);
            if (c.get(HuntCalendar.YEAR) > YEAR_TO_GIVEUP_SCHEDULING_AT) {
                nextFireTime = null;
            }
            
            if(nextFireTime !is null && nextFireTime.before(now)) {
                long diff = now.getTime() - nextFireTime.getTime();
                if(diff >= misfireThreshold) {
                    nextFireTime = getFireTimeAfter(nextFireTime);
                }
            }
        }
    }

    /**
     * <p>
     * Called by the scheduler at the time a <code>Trigger</code> is first
     * added to the scheduler, in order to have the <code>Trigger</code>
     * compute its first fire time, based on any associated calendar.
     * </p>
     * 
     * <p>
     * After this method has been called, <code>getNextFireTime()</code>
     * should return a valid answer.
     * </p>
     * 
     * @return the first time at which the <code>Trigger</code> will be fired
     *         by the scheduler, which is also the same value <code>getNextFireTime()</code>
     *         will return (until after the first firing of the <code>Trigger</code>).
     *         </p>
     */
    override
    Date computeFirstFireTime(QuartzCalendar calendar) {
        nextFireTime = getFireTimeAfter(new Date(getStartTime().getTime() - 1000));

        while (nextFireTime !is null && calendar !is null
                && !calendar.isTimeIncluded(nextFireTime.getTime())) {
            nextFireTime = getFireTimeAfter(nextFireTime);
        }

        return nextFireTime;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.CronTriggerI#getExpressionSummary()
     */
    string getExpressionSummary() {
        return cronEx is null ? null : cronEx.getExpressionSummary();
    }

    /**
     * Used by extensions of CronTrigger to imply that there are additional 
     * properties, specifically so that extensions can choose whether to be 
     * stored as a serialized blob, or as a flattened CronTrigger table. 
     */
    bool hasAdditionalProperties() { 
        return false;
    }
    /**
     * Get a {@link ScheduleBuilder} that is configured to produce a 
     * schedule identical to this trigger's schedule.
     * 
     * @see #getTriggerBuilder()
     */
    override
    ScheduleBuilder!(CronTrigger) getScheduleBuilder() {
        
        CronScheduleBuilder cb = CronScheduleBuilder.cronSchedule(getCronExpression())
                .inTimeZone(getTimeZone());
            
        switch(getMisfireInstruction()) {
            case MISFIRE_INSTRUCTION_DO_NOTHING : cb.withMisfireHandlingInstructionDoNothing();
            break;
            case MISFIRE_INSTRUCTION_FIRE_ONCE_NOW : cb.withMisfireHandlingInstructionFireAndProceed();
            break;
        }
        
        return cb;
    }
    
    ////////////////////////////////////////////////////////////////////////////
    //
    // Computation Functions
    //
    ////////////////////////////////////////////////////////////////////////////

    protected Date getTimeAfter(Date afterTime) {
        return (cronEx is null) ? null : cronEx.getTimeAfter(afterTime);
    }

    /**
     * NOT YET IMPLEMENTED: Returns the time before the given time
     * that this <code>CronTrigger</code> will fire.
     */ 
    protected Date getTimeBefore(Date eTime) {
        return (cronEx is null) ? null : cronEx.getTimeBefore(eTime);
    }

    
}

