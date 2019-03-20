
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

module hunt.quartz.impl.triggers.CalendarIntervalTriggerImpl;

import hunt.quartz.impl.triggers.AbstractTrigger;
import hunt.quartz.impl.triggers.CoreTrigger;

import hunt.quartz.Calendar;
import hunt.quartz.CalendarIntervalScheduleBuilder;
import hunt.quartz.CalendarIntervalTrigger;
import hunt.quartz.CronTrigger;
import hunt.quartz.DateBuilder : IntervalUnit;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.exception;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.Scheduler;
import hunt.quartz.exception;
import hunt.quartz.SimpleTrigger;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerBuilder;
import hunt.quartz.TriggerUtils;

import hunt.Exceptions;
// import hunt.time.util.Calendar;
import hunt.time.LocalTime;
import hunt.time.LocalDateTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.ZoneRegion;
// import std.datetime;

import std.conv;

/**
 * <p>A concrete <code>{@link Trigger}</code> that is used to fire a <code>{@link hunt.quartz.JobDetail}</code>
 * based upon repeating calendar time intervals.</p>
 * 
 * <p>The trigger will fire every N (see {@link #setRepeatInterval(int)} ) units of calendar time
 * (see {@link #setRepeatIntervalUnit(hunt.quartz.DateBuilder.IntervalUnit)}) as specified in the trigger's definition.
 * This trigger can achieve schedules that are not possible with {@link SimpleTrigger} (e.g 
 * because months are not a fixed number of seconds) or {@link CronTrigger} (e.g. because
 * "every 5 months" is not an even divisor of 12).</p>
 * 
 * <p>If you use an interval unit of <code>MONTH</code> then care should be taken when setting
 * a <code>startTime</code> value that is on a day near the end of the month.  For example,
 * if you choose a start time that occurs on January 31st, and have a trigger with unit
 * <code>MONTH</code> and interval <code>1</code>, then the next fire time will be February 28th, 
 * and the next time after that will be March 28th - and essentially each subsequent firing will 
 * occur on the 28th of the month, even if a 31st day exists.  If you want a trigger that always
 * fires on the last day of the month - regardless of the number of days in the month, 
 * you should use <code>CronTrigger</code>.</p> 
 * 
 * @see Trigger
 * @see CronTrigger
 * @see SimpleTrigger
 * @see TriggerUtils
 * 
 * @since 1.7
 * 
 * @author James House
 */
class CalendarIntervalTriggerImpl : AbstractTrigger!(CalendarIntervalTrigger), CalendarIntervalTrigger, CoreTrigger {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */
    
    private enum int YEAR_TO_GIVEUP_SCHEDULING_AT = 2018 + 100; 
    // LocalDateTime.getInstance().getYear() +

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */
    
    private LocalDateTime startTime;

    private LocalDateTime endTime;

    private LocalDateTime nextFireTime;

    private LocalDateTime previousFireTime;

    private  int repeatInterval = 0;
    
    private IntervalUnit repeatIntervalUnit = IntervalUnit.DAY;

    private ZoneId timeZone;

    private bool preserveHourOfDayAcrossDaylightSavings = false; // false is backward-compatible with behavior

    private bool skipDayIfHourDoesNotExist = false;

    private int timesTriggered = 0;

    private bool complete = false;
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a <code>DateIntervalTrigger</code> with no settings.
     * </p>
     */
    this() {
        // LocalDateTime.zero
        super();
    }

    /**
     * <p>
     * Create a <code>DateIntervalTrigger</code> that will occur immediately, and
     * repeat at the the given interval.
     * </p>
     */
    this(string name, IntervalUnit intervalUnit,  int repeatInterval) {
        this(name, null, intervalUnit, repeatInterval);
    }

    /**
     * <p>
     * Create a <code>DateIntervalTrigger</code> that will occur immediately, and
     * repeat at the the given interval.
     * </p>
     */
    this(string name, string group, IntervalUnit intervalUnit,
            int repeatInterval) {
        this(name, group, LocalDateTime.now(), null, intervalUnit, repeatInterval);
    }
    
    /**
     * <p>
     * Create a <code>DateIntervalTrigger</code> that will occur at the given time,
     * and repeat at the the given interval until the given end time.
     * </p>
     * 
     * @param startTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to fire.
     * @param endTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to quit repeat firing.
     * @param intervalUnit
     *          The repeat interval unit (minutes, days, months, etc).
     * @param repeatInterval
     *          The number of milliseconds to pause between the repeat firing.
     */
    this(string name, LocalDateTime startTime,
            LocalDateTime endTime, IntervalUnit intervalUnit,  int repeatInterval) {
        this(name, null, startTime, endTime, intervalUnit, repeatInterval);
    }
    
    /**
     * <p>
     * Create a <code>DateIntervalTrigger</code> that will occur at the given time,
     * and repeat at the the given interval until the given end time.
     * </p>
     * 
     * @param startTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to fire.
     * @param endTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to quit repeat firing.
     * @param intervalUnit
     *          The repeat interval unit (minutes, days, months, etc).
     * @param repeatInterval
     *          The number of milliseconds to pause between the repeat firing.
     */
    this(string name, string group, LocalDateTime startTime,
            LocalDateTime endTime, IntervalUnit intervalUnit,  int repeatInterval) {
        super(name, group);

        setStartTime(startTime);
        setEndTime(endTime);
        setRepeatIntervalUnit(intervalUnit);
        setRepeatInterval(repeatInterval);
    }

    /**
     * <p>
     * Create a <code>DateIntervalTrigger</code> that will occur at the given time,
     * fire the identified <code>Job</code> and repeat at the the given
     * interval until the given end time.
     * </p>
     * 
     * @param startTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to fire.
     * @param endTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to quit repeat firing.
     * @param intervalUnit
     *          The repeat interval unit (minutes, days, months, etc).
     * @param repeatInterval
     *          The number of milliseconds to pause between the repeat firing.
     */
    this(string name, string group, string jobName,
            string jobGroup, LocalDateTime startTime, LocalDateTime endTime,  
            IntervalUnit intervalUnit,  int repeatInterval) {
        super(name, group, jobName, jobGroup);

        setStartTime(startTime);
        setEndTime(endTime);
        setRepeatIntervalUnit(intervalUnit);
        setRepeatInterval(repeatInterval);
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Get the time at which the <code>DateIntervalTrigger</code> should occur.
     * </p>
     */
    override
    LocalDateTime getStartTime() {
        if(startTime is null)
            startTime = LocalDateTime.now();
        return startTime;
    }

    /**
     * <p>
     * Set the time at which the <code>DateIntervalTrigger</code> should occur.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if startTime is <code>null</code>.
     */
    override
    void setStartTime(LocalDateTime startTime) {
        if (startTime is null) {
            throw new IllegalArgumentException("Start time cannot be null");
        }

        LocalDateTime eTime = getEndTime();
        if (eTime !is null && eTime.isBefore(startTime)) {
            throw new IllegalArgumentException(
                "End time cannot be before start time");    
        }

        this.startTime = startTime;
    }

    /**
     * <p>
     * Get the time at which the <code>DateIntervalTrigger</code> should quit
     * repeating.
     * </p>
     * 
     * @see #getFinalFireTime()
     */
    override
    LocalDateTime getEndTime() {
        return endTime;
    }

    /**
     * <p>
     * Set the time at which the <code>DateIntervalTrigger</code> should quit
     * repeating (and be automatically deleted).
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if endTime is before start time.
     */
    override
    void setEndTime(LocalDateTime endTime) {
        LocalDateTime sTime = getStartTime();
        if (sTime !is null && endTime !is null && sTime.isAfter(endTime)) {
            throw new IllegalArgumentException(
                    "End time cannot be before start time");
        }

        this.endTime = endTime;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.DateIntervalTriggerI#getRepeatIntervalUnit()
     */
    IntervalUnit getRepeatIntervalUnit() {
        return repeatIntervalUnit;
    }

    /**
     * <p>Set the interval unit - the time unit on with the interval applies.</p>
     */
    void setRepeatIntervalUnit(IntervalUnit intervalUnit) {
        this.repeatIntervalUnit = intervalUnit;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.DateIntervalTriggerI#getRepeatInterval()
     */
    int getRepeatInterval() {
        return repeatInterval;
    }

    /**
     * <p>
     * set the the time interval that will be added to the <code>DateIntervalTrigger</code>'s
     * fire time (in the set repeat interval unit) in order to calculate the time of the 
     * next trigger repeat.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if repeatInterval is < 1
     */
    void setRepeatInterval( int repeatInterval) {
        if (repeatInterval < 0) {
            throw new IllegalArgumentException(
                    "Repeat interval must be >= 1");
        }

        this.repeatInterval = repeatInterval;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.CalendarIntervalTriggerI#getTimeZone()
     */
    ZoneId getTimeZone() {
        
        if (timeZone is null) {
            timeZone = ZoneRegion.systemDefault();
        }
        return timeZone;
    }

    /**
     * <p>
     * Sets the time zone within which time calculations related to this 
     * trigger will be performed.
     * </p>
     *
     * @param timeZone the desired ZoneId, or null for the system default.
     */
    void setTimeZone(ZoneId timeZone) {
        this.timeZone = timeZone;
    }
    
    /**
     * If intervals are a day or greater, this property (set to true) will 
     * cause the firing of the trigger to always occur at the same time of day,
     * (the time of day of the startTime) regardless of daylight saving time 
     * transitions.  Default value is false.
     * 
     * <p>
     * For example, without the property set, your trigger may have a start 
     * time of 9:00 am on March 1st, and a repeat interval of 2 days.  But 
     * after the daylight saving transition occurs, the trigger may start 
     * firing at 8:00 am every other day.
     * </p>
     * 
     * <p>
     * If however, the time of day does not exist on a given day to fire
     * (e.g. 2:00 am in the United States on the days of daylight saving
     * transition), the trigger will go ahead and fire one hour off on 
     * that day, and then resume the normal hour on other days.  If
     * you wish for the trigger to never fire at the "wrong" hour, then
     * you should set the property skipDayIfHourDoesNotExist.
     * </p>
     * 
     * @see #isSkipDayIfHourDoesNotExist()
     * @see #getStartTime()
     * @see #getTimeZone()
     */
    bool isPreserveHourOfDayAcrossDaylightSavings() {
        return preserveHourOfDayAcrossDaylightSavings;
    }

    void setPreserveHourOfDayAcrossDaylightSavings(bool preserveHourOfDayAcrossDaylightSavings) {
        this.preserveHourOfDayAcrossDaylightSavings = preserveHourOfDayAcrossDaylightSavings;
    }
    
    /**
     * If intervals are a day or greater, and 
     * preserveHourOfDayAcrossDaylightSavings property is set to true, and the
     * hour of the day does not exist on a given day for which the trigger 
     * would fire, the day will be skipped and the trigger advanced a second
     * interval if this property is set to true.  Defaults to false.
     * 
     * <p>
     * <b>CAUTION!</b>  If you enable this property, and your hour of day happens 
     * to be that of daylight savings transition (e.g. 2:00 am in the United 
     * States) and the trigger's interval would have had the trigger fire on
     * that day, then you may actually completely miss a firing on the day of 
     * transition if that hour of day does not exist on that day!  In such a 
     * case the next fire time of the trigger will be computed as double (if 
     * the interval is 2 days, then a span of 4 days between firings will 
     * occur).
     * </p>
     * 
     * @see #isPreserveHourOfDayAcrossDaylightSavings()
     */
    bool isSkipDayIfHourDoesNotExist() {
        return skipDayIfHourDoesNotExist;
    }

    void setSkipDayIfHourDoesNotExist(bool skipDayIfHourDoesNotExist) {
        this.skipDayIfHourDoesNotExist = skipDayIfHourDoesNotExist;
    }
    
    /* (non-Javadoc)
     * @see hunt.quartz.DateIntervalTriggerI#getTimesTriggered()
     */
    int getTimesTriggered() {
        return timesTriggered;
    }

    /**
     * <p>
     * Set the number of times the <code>DateIntervalTrigger</code> has already
     * fired.
     * </p>
     */
    void setTimesTriggered(int timesTriggered) {
        this.timesTriggered = timesTriggered;
    }

    override
    protected bool validateMisfireInstruction(int misfireInstruction) {
        if (misfireInstruction < MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY) {
            return false;
        }

        return misfireInstruction <= MISFIRE_INSTRUCTION_DO_NOTHING;
    }


    /**
     * <p>
     * Updates the <code>DateIntervalTrigger</code>'s state based on the
     * MISFIRE_INSTRUCTION_XXX that was selected when the <code>DateIntervalTrigger</code>
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
            LocalDateTime newFireTime = getFireTimeAfter(LocalDateTime.now());
            while (newFireTime !is null && cal !is null
                    && !cal.isTimeIncluded(newFireTime.toInstant(ZoneOffset.UTC).toEpochMilli())) {
                newFireTime = getFireTimeAfter(newFireTime);
            }
            setNextFireTime(newFireTime);
        } else if (instr == MISFIRE_INSTRUCTION_FIRE_ONCE_NOW) { 
            // fire once now...
            setNextFireTime(LocalDateTime.now());
            // the new fire time afterward will magically preserve the original  
            // time of day for firing for day/week/month interval triggers, 
            // because of the way getFireTimeAfter() works - in its always restarting
            // computation from the start time.
        }
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
        timesTriggered++;
        previousFireTime = nextFireTime;
        nextFireTime = getFireTimeAfter(nextFireTime);

        while (nextFireTime !is null && calendar !is null
                && !calendar.isTimeIncluded(nextFireTime.toInstant(ZoneOffset.UTC).toEpochMilli())) {
            
            nextFireTime = getFireTimeAfter(nextFireTime);

            if(nextFireTime is null)
                break;
            
            //avoid infinite loop
            if (nextFireTime.getYear() > YEAR_TO_GIVEUP_SCHEDULING_AT) {
                nextFireTime = null;
            }
        }
    }


    /**
     *  
     * @see hunt.quartz.spi.OperableTrigger#updateWithNewCalendar(QuartzCalendar, long)
     */
    override
    void updateWithNewCalendar(QuartzCalendar calendar, long misfireThreshold) {
        nextFireTime = getFireTimeAfter(previousFireTime);

        if (nextFireTime is null || calendar is null) {
            return;
        }
        
        LocalDateTime now = LocalDateTime.now();
        while (nextFireTime !is null && !calendar.isTimeIncluded(nextFireTime.toInstant(ZoneOffset.UTC).toEpochMilli())) {

            nextFireTime = getFireTimeAfter(nextFireTime);

            if(nextFireTime is null)
                break;
            
            //avoid infinite loop
            LocalDateTime c = nextFireTime;
            if (c.getYear() > YEAR_TO_GIVEUP_SCHEDULING_AT) {
                nextFireTime = null;
            }

            if(nextFireTime !is null && nextFireTime.isBefore(now)) {
                // long diff = now.getTime() - nextFireTime.getTime();
                LocalDateTime t = nextFireTime.plusNanos(misfireThreshold * LocalTime.NANOS_PER_MILLI);
                if(now.isAfter(t)) {
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
    LocalDateTime computeFirstFireTime(QuartzCalendar calendar) {
        nextFireTime = getStartTime();

        while (nextFireTime !is null && calendar !is null
                && !calendar.isTimeIncluded(nextFireTime.toInstant(ZoneOffset.UTC).toEpochMilli())) {
            
            nextFireTime = getFireTimeAfter(nextFireTime);
            
            if(nextFireTime is null)
                break;

            //avoid infinite loop
            LocalDateTime c = nextFireTime;
            if (c.getYear() > YEAR_TO_GIVEUP_SCHEDULING_AT) {
                return null;
            }
        }
        
        return nextFireTime;
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
     */
    override
    LocalDateTime getNextFireTime() {
        return nextFireTime;
    }

    /**
     * <p>
     * Returns the previous time at which the <code>DateIntervalTrigger</code> 
     * fired. If the trigger has not yet fired, <code>null</code> will be
     * returned.
     */
    override
    LocalDateTime getPreviousFireTime() {
        return previousFireTime;
    }

    /**
     * <p>
     * Set the next time at which the <code>DateIntervalTrigger</code> should fire.
     * </p>
     * 
     * <p>
     * <b>This method should not be invoked by client code.</b>
     * </p>
     */
    void setNextFireTime(LocalDateTime nextFireTime) {
        this.nextFireTime = nextFireTime;
    }

    /**
     * <p>
     * Set the previous time at which the <code>DateIntervalTrigger</code> fired.
     * </p>
     * 
     * <p>
     * <b>This method should not be invoked by client code.</b>
     * </p>
     */
    void setPreviousFireTime(LocalDateTime previousFireTime) {
        this.previousFireTime = previousFireTime;
    }

    /**
     * <p>
     * Returns the next time at which the <code>DateIntervalTrigger</code> will
     * fire, after the given time. If the trigger will not fire after the given
     * time, <code>null</code> will be returned.
     * </p>
     */
    override
    LocalDateTime getFireTimeAfter(LocalDateTime afterTime) {
        return getFireTimeAfter(afterTime, false);
    }
    
    protected LocalDateTime getFireTimeAfter(LocalDateTime afterTime, bool ignoreEndTime) {
        if (complete) {
            return null;
        }

        // increment afterTme by a second, so that we are 
        // comparing against a time after it!
        if (afterTime is null) {
            afterTime = LocalDateTime.now();
        }

        long startMillis = getStartTime().toInstant(ZoneOffset.UTC).toEpochMilli();
        long afterMillis = afterTime.toInstant(ZoneOffset.UTC).toEpochMilli();
        long endMillis = (getEndTime() is null) ? long.max : getEndTime().toInstant(ZoneOffset.UTC).toEpochMilli();

        if (!ignoreEndTime && (endMillis <= afterMillis)) {
            return null;
        }

        if (afterMillis < startMillis) {
            return afterTime;
        }

        
        long secondsAfterStart = 1 + (afterMillis - startMillis) / 1000L;

        LocalDateTime time = null;
        long repeatLong = getRepeatInterval();
        
        // Calendar aTime = Calendar.getInstance();
        // aTime.setTime(afterTime);

        // Calendar sTime = Calendar.getInstance();
        // if(timeZone !is null)
        //     sTime.setTimeZone(timeZone);
        // sTime.setTime(getStartTime());
        // sTime.setLenient(true);

        LocalDateTime sTime = getStartTime();
        
        if(getRepeatIntervalUnit() == IntervalUnit.SECOND) {
            long jumpCount = secondsAfterStart / repeatLong;
            if(secondsAfterStart % repeatLong != 0)
                jumpCount++;
            time = sTime.plusSeconds(getRepeatInterval() * cast(int)jumpCount);
        }
        else if(getRepeatIntervalUnit() == IntervalUnit.MINUTE) {
            long jumpCount = secondsAfterStart / (repeatLong * 60L);
            if(secondsAfterStart % (repeatLong * 60L) != 0)
                jumpCount++;
            time = sTime.plusMinutes(getRepeatInterval() * cast(int)jumpCount);
        }
        else if(getRepeatIntervalUnit() == IntervalUnit.HOUR) {
            long jumpCount = secondsAfterStart / (repeatLong * 60L * 60L);
            if(secondsAfterStart % (repeatLong * 60L * 60L) != 0)
                jumpCount++;
            time = sTime.plusHours(getRepeatInterval() * cast(int)jumpCount);
        }
        else { // intervals a day or greater ...

            int initialHourOfDay = sTime.getHour();
            
            if(getRepeatIntervalUnit() == IntervalUnit.DAY) {
                // sTime.setLenient(true);
                
                // Because intervals greater than an hour have an non-fixed number 
                // of seconds in them (due to daylight savings, variation number of 
                // days in each month, leap year, etc. ) we can't jump forward an
                // exact number of seconds to calculate the fire time as we can
                // with the second, minute and hour intervals.   But, rather
                // than slowly crawling our way there by iteratively adding the 
                // increment to the start time until we reach the "after time",
                // we can first make a big leap most of the way there...
                
                long jumpCount = secondsAfterStart / (repeatLong * 24L * 60L * 60L);
                // if we need to make a big jump, jump most of the way there, 
                // but not all the way because in some cases we may over-shoot or under-shoot
                if(jumpCount > 20) {
                    if(jumpCount < 50)
                        jumpCount = cast(long) (jumpCount * 0.80);
                    else if(jumpCount < 500)
                        jumpCount = cast(long) (jumpCount * 0.90);
                    else
                        jumpCount = cast(long) (jumpCount * 0.95);
                    sTime = sTime.plusDays(cast(int) (getRepeatInterval() * jumpCount));
                }
                
                // now baby-step the rest of the way there...
                while(!sTime.isAfter(afterTime) &&
                        (sTime.getYear() < YEAR_TO_GIVEUP_SCHEDULING_AT)) {  
                    sTime = sTime.plusDays(getRepeatInterval());
                }
                while(daylightSavingHourShiftOccurredAndAdvanceNeeded(sTime, initialHourOfDay, afterTime) &&
                        (sTime.getYear()< YEAR_TO_GIVEUP_SCHEDULING_AT)) {
                    sTime = sTime.plusDays(getRepeatInterval());
                }
                time = sTime;
            }
            else if(getRepeatIntervalUnit()== IntervalUnit.WEEK) {
                // sTime.setLenient(true);
    
                // Because intervals greater than an hour have an non-fixed number 
                // of seconds in them (due to daylight savings, variation number of 
                // days in each month, leap year, etc. ) we can't jump forward an
                // exact number of seconds to calculate the fire time as we can
                // with the second, minute and hour intervals.   But, rather
                // than slowly crawling our way there by iteratively adding the 
                // increment to the start time until we reach the "after time",
                // we can first make a big leap most of the way there...
                
                long jumpCount = secondsAfterStart / (repeatLong * 7L * 24L * 60L * 60L);
                // if we need to make a big jump, jump most of the way there, 
                // but not all the way because in some cases we may over-shoot or under-shoot
                if(jumpCount > 20) {
                    if(jumpCount < 50)
                        jumpCount = cast(long) (jumpCount * 0.80);
                    else if(jumpCount < 500)
                        jumpCount = cast(long) (jumpCount * 0.90);
                    else
                        jumpCount = cast(long) (jumpCount * 0.95);
                    // sTime.add(LocalDateTime.WEEK_OF_YEAR, cast(int) (getRepeatInterval() * jumpCount));
                    sTime = sTime.plusWeeks(cast(int) (getRepeatInterval() * jumpCount));
                }
                
                while(!sTime.isAfter(afterTime) &&
                        (sTime.getYear() < YEAR_TO_GIVEUP_SCHEDULING_AT)) {
                    sTime = sTime.plusWeeks(getRepeatInterval());
                }
                while(daylightSavingHourShiftOccurredAndAdvanceNeeded(sTime, initialHourOfDay, afterTime) &&
                        (sTime.getYear() < YEAR_TO_GIVEUP_SCHEDULING_AT)) {
                    sTime = sTime.plusWeeks(getRepeatInterval());
                }
                time = sTime;
            }
            else if(getRepeatIntervalUnit()== IntervalUnit.MONTH) {
                // sTime.setLenient(true);
    
                // because of the large variation in size of months, and 
                // because months are already large blocks of time, we will
                // just advance via brute-force iteration.
                
                while(!sTime.isAfter(afterTime) &&
                        (sTime.getYear() < YEAR_TO_GIVEUP_SCHEDULING_AT)) {            
                    sTime = sTime.plusMonths(getRepeatInterval());
                }
                while(daylightSavingHourShiftOccurredAndAdvanceNeeded(sTime, initialHourOfDay, afterTime) &&
                        (sTime.getYear() < YEAR_TO_GIVEUP_SCHEDULING_AT)) {
                    sTime = sTime.plusMonths(getRepeatInterval());
                }
                time = sTime;
            }
            else if(getRepeatIntervalUnit() == IntervalUnit.YEAR) {
    
                while(!sTime.isAfter(afterTime) &&
                        (sTime.getYear() < YEAR_TO_GIVEUP_SCHEDULING_AT)) {            
                    sTime = sTime.plusYears(getRepeatInterval());
                }
                while(daylightSavingHourShiftOccurredAndAdvanceNeeded(sTime, initialHourOfDay, afterTime) &&
                        (sTime.getYear() < YEAR_TO_GIVEUP_SCHEDULING_AT)) {
                    sTime = sTime.plusYears(getRepeatInterval());
                }
                time = sTime;
            }
        } // case of interval of a day or greater
        
        if (!ignoreEndTime && (endMillis <= time.toInstant(ZoneOffset.UTC).toEpochMilli())) {
            return null;
        }

        return time;
    }

    private bool daylightSavingHourShiftOccurredAndAdvanceNeeded(LocalDateTime newTime, int initialHourOfDay, LocalDateTime afterTime) {
        if(isPreserveHourOfDayAcrossDaylightSavings() && newTime.getHour() != initialHourOfDay) {
            newTime = newTime.withHour(initialHourOfDay);
            if (newTime.getHour() != initialHourOfDay) {
                return isSkipDayIfHourDoesNotExist();
            } else {
                return !newTime.isAfter(afterTime);
            }
        }
        return false;
    }
    
    /**
     * <p>
     * Returns the final time at which the <code>DateIntervalTrigger</code> will
     * fire, if there is no end time set, null will be returned.
     * </p>
     * 
     * <p>
     * Note that the return time may be in the past.
     * </p>
     */
    override
    LocalDateTime getFinalFireTime() {
        if (complete || getEndTime() is null) {
            return null;
        }

        // back up a second from end time
        LocalDateTime fTime = getEndTime().minusSeconds(1);
        // find the next fire time after that
        fTime = getFireTimeAfter(fTime, true);
        
        // the the trigger fires at the end time, that's it!
        if(fTime== getEndTime())
            return fTime;
        
        // otherwise we have to back up one interval from the fire time after the end time
        
        LocalDateTime lTime = fTime;
        
        if(getRepeatIntervalUnit() == IntervalUnit.SECOND) {
            lTime = lTime.minusSeconds(getRepeatInterval());
        }
        else if(getRepeatIntervalUnit() == IntervalUnit.MINUTE) {
            lTime = lTime.minusMinutes(getRepeatInterval());
        }
        else if(getRepeatIntervalUnit() == IntervalUnit.HOUR) {
            lTime = lTime.minusHours(getRepeatInterval());
        }
        else if(getRepeatIntervalUnit() == IntervalUnit.DAY) {
            lTime = lTime.minusDays(getRepeatInterval());
        }
        else if(getRepeatIntervalUnit() == IntervalUnit.WEEK) {
            lTime = lTime.minusWeeks(getRepeatInterval());
        }
        else if(getRepeatIntervalUnit() == IntervalUnit.MONTH) {
            lTime = lTime.minusMonths(getRepeatInterval());
        }
        else if(getRepeatIntervalUnit() == IntervalUnit.YEAR) {
            lTime = lTime.minusYears(getRepeatInterval());
        }

        return lTime;
    }

    /**
     * <p>
     * Determines whether or not the <code>DateIntervalTrigger</code> will occur
     * again.
     * </p>
     */
    override
    bool mayFireAgain() {
        return (getNextFireTime() !is null);
    }

    /**
     * <p>
     * Validates whether the properties of the <code>JobDetail</code> are
     * valid for submission into a <code>Scheduler</code>.
     * 
     * @throws IllegalStateException
     *           if a required property (such as Name, Group, Class) is not
     *           set.
     */
    override
    void validate() {
        super.validate();
        
        if (repeatInterval < 1) {
            throw new SchedulerException("Repeat Interval cannot be zero.");
        }
    }

    override TriggerBuilder!(CalendarIntervalTrigger) getTriggerBuilder() {
        return super.getTriggerBuilder();
    }

    /**
     * Get a {@link ScheduleBuilder} that is configured to produce a 
     * schedule identical to this trigger's schedule.
     * 
     * @see #getTriggerBuilder()
     */
    override
    ScheduleBuilder getScheduleBuilder() { // !(CalendarIntervalTrigger)
        
        CalendarIntervalScheduleBuilder cb = CalendarIntervalScheduleBuilder.calendarIntervalSchedule()
                .withInterval(getRepeatInterval(), getRepeatIntervalUnit());
            
        switch(getMisfireInstruction()) {
            case MISFIRE_INSTRUCTION_DO_NOTHING : cb.withMisfireHandlingInstructionDoNothing();
            break;

            case MISFIRE_INSTRUCTION_FIRE_ONCE_NOW : cb.withMisfireHandlingInstructionFireAndProceed();
            break;

            default:
                assert(false, "bad case: " ~ getMisfireInstruction().to!string());
        }
        
        return cb;
    }

    bool hasAdditionalProperties() {
        return false;
    }
}
