
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

module hunt.quartz.impl.triggers.SimpleTriggerImpl;

import hunt.quartz.impl.triggers.AbstractTrigger;
import hunt.quartz.impl.triggers.CoreTrigger;

import hunt.quartz.Calendar;
import hunt.quartz.CronTrigger;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.Exceptions;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.Scheduler;
import hunt.quartz.Exceptions;
import hunt.quartz.SimpleScheduleBuilder;
import hunt.quartz.SimpleTrigger;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerBuilder;
import hunt.quartz.TriggerUtils;

import hunt.Exceptions;
import hunt.time.Duration;
import hunt.time.LocalTime;
import hunt.time.LocalDateTime;
import hunt.time.ZoneOffset;
import hunt.util.Serialize;
import hunt.util.ObjectUtils;

import hunt.logging.ConsoleLogger;

import witchcraft;

/**
 * <p>
 * A concrete <code>{@link Trigger}</code> that is used to fire a <code>{@link hunt.quartz.JobDetail}</code>
 * at a given moment in time, and optionally repeated at a specified interval.
 * </p>
 * 
 * @see Trigger
 * @see CronTrigger
 * @see TriggerUtils
 * 
 * @author James House
 * @author contributions by Lieven Govaerts of Ebitec Nv, Belgium.
 */
class SimpleTriggerImpl : AbstractTrigger!(SimpleTrigger), SimpleTrigger, CoreTrigger {

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

    // private enum int YEAR_TO_GIVEUP_SCHEDULING_AT = hunt.time.util.Calendar.getInstance().get(hunt.time.util.Calendar.YEAR) + 100;
    private enum int YEAR_TO_GIVEUP_SCHEDULING_AT = 2018 + 100;    
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */
    
    private LocalDateTime startTime; // = null;

    private LocalDateTime endTime; // = null;

    private LocalDateTime nextFireTime; // = null;

    private LocalDateTime previousFireTime; // = null;

    private int repeatCount = 0;

    private long repeatInterval = 0;

    private int timesTriggered = 0;

    private bool complete = false;
    
    mixin Witchcraft;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a <code>SimpleTrigger</code> with no settings.
     * </p>
     */
    this() {
        super();
    }

    // /**
    //  * <p>
    //  * Create a <code>SimpleTrigger</code> that will occur immediately, and
    //  * not repeat.
    //  * </p>
    //  * 
    //  * @deprecated use a TriggerBuilder instead
    //  */
    // deprecated("")
    // this(string name) {
    //     this(name, (string)null);
    // }
    
    /**
     * <p>
     * Create a <code>SimpleTrigger</code> that will occur immediately, and
     * not repeat.
     * </p>
     * 
     * @deprecated use a TriggerBuilder instead
     */
    // deprecated("")
    this(string name, string group) {
        this(name, group, LocalDateTime.now(), null, 0, 0);
    }

    /**
     * <p>
     * Create a <code>SimpleTrigger</code> that will occur immediately, and
     * repeat at the the given interval the given number of times.
     * </p>
     * 
     * @deprecated use a TriggerBuilder instead
     */
    // deprecated("")
    this(string name, int repeatCount, long repeatInterval) {
        this(name, null, repeatCount, repeatInterval);
    }

    /**
     * <p>
     * Create a <code>SimpleTrigger</code> that will occur immediately, and
     * repeat at the the given interval the given number of times.
     * </p>
     * 
     * @deprecated use a TriggerBuilder instead
     */
    // deprecated("")
    this(string name, string group, int repeatCount,
            long repeatInterval) {
        this(name, group, LocalDateTime.now(), null, repeatCount, repeatInterval);
    }

    /**
     * <p>
     * Create a <code>SimpleTrigger</code> that will occur at the given time,
     * and not repeat.
     * </p>
     * 
     * @deprecated use a TriggerBuilder instead
     */
    // deprecated("")
    this(string name, LocalDateTime startTime) {
        this(name, null, startTime);
    }

    /**
     * <p>
     * Create a <code>SimpleTrigger</code> that will occur at the given time,
     * and not repeat.
     * </p>
     * 
     * @deprecated use a TriggerBuilder instead
     */
    // deprecated("")
    this(string name, string group, LocalDateTime startTime) {
        this(name, group, startTime, null, 0, 0);
    }
    
    /**
     * <p>
     * Create a <code>SimpleTrigger</code> that will occur at the given time,
     * and repeat at the the given interval the given number of times, or until
     * the given end time.
     * </p>
     * 
     * @param startTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to fire.
     * @param endTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to quit repeat firing.
     * @param repeatCount
     *          The number of times for the <code>Trigger</code> to repeat
     *          firing, use {@link #REPEAT_INDEFINITELY} for unlimited times.
     * @param repeatInterval
     *          The number of milliseconds to pause between the repeat firing.
     * 
     * @deprecated use a TriggerBuilder instead
     */
    // deprecated("")
    this(string name, LocalDateTime startTime,
            LocalDateTime endTime, int repeatCount, long repeatInterval) {
        this(name, null, startTime, endTime, repeatCount, repeatInterval);
    }
    
    /**
     * <p>
     * Create a <code>SimpleTrigger</code> that will occur at the given time,
     * and repeat at the the given interval the given number of times, or until
     * the given end time.
     * </p>
     * 
     * @param startTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to fire.
     * @param endTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to quit repeat firing.
     * @param repeatCount
     *          The number of times for the <code>Trigger</code> to repeat
     *          firing, use {@link #REPEAT_INDEFINITELY} for unlimited times.
     * @param repeatInterval
     *          The number of milliseconds to pause between the repeat firing.
     * 
     * @deprecated use a TriggerBuilder instead
     */
    // deprecated("")
    this(string name, string group, LocalDateTime startTime,
            LocalDateTime endTime, int repeatCount, long repeatInterval) {
        super(name, group);

        setStartTime(startTime);
        setEndTime(endTime);
        setRepeatCount(repeatCount);
        setRepeatInterval(repeatInterval);
    }

    /**
     * <p>
     * Create a <code>SimpleTrigger</code> that will occur at the given time,
     * fire the identified <code>Job</code> and repeat at the the given
     * interval the given number of times, or until the given end time.
     * </p>
     * 
     * @param startTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to fire.
     * @param endTime
     *          A <code>LocalDateTime</code> set to the time for the <code>Trigger</code>
     *          to quit repeat firing.
     * @param repeatCount
     *          The number of times for the <code>Trigger</code> to repeat
     *          firing, use {@link #REPEAT_INDEFINITELY}for unlimitted times.
     * @param repeatInterval
     *          The number of milliseconds to pause between the repeat firing.
     * 
     * @deprecated use a TriggerBuilder instead
     */
    // deprecated("")
    this(string name, string group, string jobName,
            string jobGroup, LocalDateTime startTime, LocalDateTime endTime, int repeatCount,
            long repeatInterval) {
        super(name, group, jobName, jobGroup);

        setStartTime(startTime);
        setEndTime(endTime);
        setRepeatCount(repeatCount);
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
     * Get the time at which the <code>SimpleTrigger</code> should occur.
     * </p>
     */
    override
    LocalDateTime getStartTime() {
        return startTime;
    }

    /**
     * <p>
     * Set the time at which the <code>SimpleTrigger</code> should occur.
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
        if (eTime !is null && startTime !is null && eTime.isBefore(startTime)) {
            throw new IllegalArgumentException(
                "End time cannot be before start time");    
        }

        this.startTime = startTime;
    }

    /**
     * <p>
     * Get the time at which the <code>SimpleTrigger</code> should quit
     * repeating - even if repeastCount isn't yet satisfied.
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
     * Set the time at which the <code>SimpleTrigger</code> should quit
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
     * @see hunt.quartz.SimpleTriggerI#getRepeatCount()
     */
    int getRepeatCount() {
        return repeatCount;
    }

    /**
     * <p>
     * Set the the number of time the <code>SimpleTrigger</code> should
     * repeat, after which it will be automatically deleted.
     * </p>
     * 
     * @see #REPEAT_INDEFINITELY
     * @exception IllegalArgumentException
     *              if repeatCount is < 0
     */
    void setRepeatCount(int repeatCount) {
        if (repeatCount < 0 && repeatCount != REPEAT_INDEFINITELY) {
            throw new IllegalArgumentException(
                    "Repeat count must be >= 0, use the "
                            ~ "constant REPEAT_INDEFINITELY for infinite.");
        }

        this.repeatCount = repeatCount;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.SimpleTriggerI#getRepeatInterval()
     */
    long getRepeatInterval() {
        return repeatInterval;
    }

    /**
     * <p>
     * Set the the time interval (in milliseconds) at which the <code>SimpleTrigger</code>
     * should repeat.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if repeatInterval is <= 0
     */
    void setRepeatInterval(long repeatInterval) {
        if (repeatInterval < 0) {
            throw new IllegalArgumentException(
                    "Repeat interval must be >= 0");
        }

        this.repeatInterval = repeatInterval;
    }

    /**
     * <p>
     * Get the number of times the <code>SimpleTrigger</code> has already
     * fired.
     * </p>
     */
    int getTimesTriggered() {
        return timesTriggered;
    }

    /**
     * <p>
     * Set the number of times the <code>SimpleTrigger</code> has already
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

        if (misfireInstruction > MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_EXISTING_COUNT) {
            return false;
        }

        return true;
    }

    /**
     * <p>
     * Updates the <code>SimpleTrigger</code>'s state based on the
     * MISFIRE_INSTRUCTION_XXX that was selected when the <code>SimpleTrigger</code>
     * was created.
     * </p>
     * 
     * <p>
     * If the misfire instruction is set to MISFIRE_INSTRUCTION_SMART_POLICY,
     * then the following scheme will be used: <br>
     * <ul>
     * <li>If the Repeat Count is <code>0</code>, then the instruction will
     * be interpreted as <code>MISFIRE_INSTRUCTION_FIRE_NOW</code>.</li>
     * <li>If the Repeat Count is <code>REPEAT_INDEFINITELY</code>, then
     * the instruction will be interpreted as <code>MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT</code>.
     * <b>WARNING:</b> using MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT 
     * with a trigger that has a non-null end-time may cause the trigger to 
     * never fire again if the end-time arrived during the misfire time span. 
     * </li>
     * <li>If the Repeat Count is <code>&gt; 0</code>, then the instruction
     * will be interpreted as <code>MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_EXISTING_REPEAT_COUNT</code>.
     * </li>
     * </ul>
     * </p>
     */
    override
    void updateAfterMisfire(Calendar cal) {
        int instr = getMisfireInstruction();
        
        if(instr == Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY)
            return;
        
        if (instr == Trigger.MISFIRE_INSTRUCTION_SMART_POLICY) {
            if (getRepeatCount() == 0) {
                instr = MISFIRE_INSTRUCTION_FIRE_NOW;
            } else if (getRepeatCount() == REPEAT_INDEFINITELY) {
                instr = MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT;
            } else {
                // if (getRepeatCount() > 0)
                instr = MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_EXISTING_REPEAT_COUNT;
            }
        } else if (instr == MISFIRE_INSTRUCTION_FIRE_NOW && getRepeatCount() != 0) {
            instr = MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_REMAINING_REPEAT_COUNT;
        }

        if (instr == MISFIRE_INSTRUCTION_FIRE_NOW) {
            setNextFireTime(LocalDateTime.now());
        } else if (instr == MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_EXISTING_COUNT) {
            LocalDateTime newFireTime = getFireTimeAfter(LocalDateTime.now());
            while (newFireTime !is null && cal !is null
                    && !cal.isTimeIncluded(newFireTime.toEpochMilli())) {
                newFireTime = getFireTimeAfter(newFireTime);

                if(newFireTime is null)
                    break;
                
                //avoid infinite loop
                if (nextFireTime.getYear() > YEAR_TO_GIVEUP_SCHEDULING_AT) {
                    newFireTime = null;
                }
            }
            setNextFireTime(newFireTime);
        } else if (instr == MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT) {
            LocalDateTime newFireTime = getFireTimeAfter(LocalDateTime.now());
            while (newFireTime !is null && cal !is null
                    && !cal.isTimeIncluded(newFireTime.toEpochMilli())) {
                newFireTime = getFireTimeAfter(newFireTime);

                if(newFireTime is null)
                    break;
                
                //avoid infinite loop
                if (newFireTime.getYear() > YEAR_TO_GIVEUP_SCHEDULING_AT) {
                    newFireTime = null;
                }
            }
            if (newFireTime !is null) {
                int timesMissed = computeNumTimesFiredBetween(nextFireTime,
                        newFireTime);
                setTimesTriggered(getTimesTriggered() + timesMissed);
            }

            setNextFireTime(newFireTime);
        } else if (instr == MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_EXISTING_REPEAT_COUNT) {
            LocalDateTime newFireTime = LocalDateTime.now();
            if (repeatCount != 0 && repeatCount != REPEAT_INDEFINITELY) {
                setRepeatCount(getRepeatCount() - getTimesTriggered());
                setTimesTriggered(0);
            }
            
            if (getEndTime() !is null && getEndTime().isBefore(newFireTime)) {
                setNextFireTime(null); // We are past the end time
            } else {
                setStartTime(newFireTime);
                setNextFireTime(newFireTime);
            } 
        } else if (instr == MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_REMAINING_REPEAT_COUNT) {
            LocalDateTime newFireTime = LocalDateTime.now();

            int timesMissed = computeNumTimesFiredBetween(nextFireTime,
                    newFireTime);

            if (repeatCount != 0 && repeatCount != REPEAT_INDEFINITELY) {
                int remainingCount = getRepeatCount()
                        - (getTimesTriggered() + timesMissed);
                if (remainingCount <= 0) { 
                    remainingCount = 0;
                }
                setRepeatCount(remainingCount);
                setTimesTriggered(0);
            }

            if (getEndTime() !is null && getEndTime().isBefore(newFireTime)) {
                setNextFireTime(null); // We are past the end time
            } else {
                setStartTime(newFireTime);
                setNextFireTime(newFireTime);
            } 
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
    void triggered(Calendar calendar) {
        timesTriggered++;
        previousFireTime = nextFireTime;
        nextFireTime = getFireTimeAfter(nextFireTime);

        while (nextFireTime !is null && calendar !is null
                && !calendar.isTimeIncluded(nextFireTime.toEpochMilli())) {
            
            nextFireTime = getFireTimeAfter(nextFireTime);

            if(nextFireTime is null)
                break;
            
            //avoid infinite loop
            if (nextFireTime.getYear() > YEAR_TO_GIVEUP_SCHEDULING_AT) {
                nextFireTime = null;
            }
        }

        // version(HUNT_DEBUG) tracef("nextFireTime is null: %s", nextFireTime is null);
    }

    /**
     * @see hunt.quartz.impl.triggers.AbstractTrigger#updateWithNewCalendar(hunt.quartz.Calendar, long)
     */
    override
    void updateWithNewCalendar(Calendar calendar, long misfireThreshold)
    {
        nextFireTime = getFireTimeAfter(previousFireTime);

        if (nextFireTime is null || calendar is null) {
            version(HUNT_DEBUG) tracef("nextFireTime is null: %s", nextFireTime is null);
            return;
        }
        
        LocalDateTime now = LocalDateTime.now();
        while (nextFireTime !is null && !calendar.isTimeIncluded(nextFireTime.toEpochMilli())) {

            nextFireTime = getFireTimeAfter(nextFireTime);

            if(nextFireTime is null)
                break;
            
            //avoid infinite loop
            if (nextFireTime.getYear() > YEAR_TO_GIVEUP_SCHEDULING_AT) {
                nextFireTime = null;
            }

            if(nextFireTime !is null && nextFireTime.isBefore(now)) {
                long diff = now.toEpochMilli() - nextFireTime.toEpochMilli();
                if(diff >= misfireThreshold) {
                    nextFireTime = getFireTimeAfter(nextFireTime);
                }
            }
        }

        version(HUNT_DEBUG) tracef("nextFireTime is null: %s", nextFireTime is null);
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
    LocalDateTime computeFirstFireTime(Calendar calendar) {
        nextFireTime = getStartTime();
        
        version(HUNT_DEBUG) {
            scope(exit) {
                tracef("nextFireTime is null: %s", nextFireTime is null);
            }
        }

        while (nextFireTime !is null && calendar !is null
                && !calendar.isTimeIncluded(nextFireTime.toEpochMilli())) {
            nextFireTime = getFireTimeAfter(nextFireTime);
            
            if(nextFireTime is null)
                break;
            
            //avoid infinite loop
            if (nextFireTime.getYear() > YEAR_TO_GIVEUP_SCHEDULING_AT) {
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
     *
     * @see TriggerUtils#computeFireTimesBetween(hunt.quartz.spi.OperableTrigger, hunt.quartz.Calendar, java.util.LocalDateTime, java.util.LocalDateTime)
     */
    override
    LocalDateTime getNextFireTime() {
        return nextFireTime;
    }

    /**
     * <p>
     * Returns the previous time at which the <code>SimpleTrigger</code> 
     * fired. If the trigger has not yet fired, <code>null</code> will be
     * returned.
     */
    override
    LocalDateTime getPreviousFireTime() {
        return previousFireTime;
    }

    /**
     * <p>
     * Set the next time at which the <code>SimpleTrigger</code> should fire.
     * </p>
     * 
     * <p>
     * <b>This method should not be invoked by client code.</b>
     * </p>
     */
    void setNextFireTime(LocalDateTime nextFireTime) {
        this.nextFireTime = nextFireTime;        
        version(HUNT_QUARTZ_DEBUG_MORE) tracef("nextFireTime is null: %s", nextFireTime is null);
        
    }

    /**
     * <p>
     * Set the previous time at which the <code>SimpleTrigger</code> fired.
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
     * Returns the next time at which the <code>SimpleTrigger</code> will
     * fire, after the given time. If the trigger will not fire after the given
     * time, <code>null</code> will be returned.
     * </p>
     */
    override
    LocalDateTime getFireTimeAfter(LocalDateTime afterTime) {
        if (complete) {
            return null;
        }

        if ((timesTriggered > repeatCount)
                && (repeatCount != REPEAT_INDEFINITELY)) {
            return null;
        }

        if (afterTime is null) {
            afterTime = LocalDateTime.now();
        }

        if (repeatCount == 0 && afterTime.opCmp(getStartTime()) >= 0) {
            return null;
        }

        LocalDateTime endMillis = (getEndTime() is null) ? LocalDateTime.MAX : getEndTime();
        // LocalDateTime endMillis = getEndTime();

        if (endMillis <= afterTime) {
            return null;
        }

        if (afterTime < getStartTime()) {
            return getStartTime();
        }

        // long startMillis = getStartTime().toEpochMilli();
        // long afterMillis = afterTime.toEpochMilli();

        // long numberOfTimesExecuted = ((afterMillis - startMillis) / repeatInterval) + 1;
        Duration dur = Duration.between(getStartTime(), afterTime);        
        long numberOfTimesExecuted = (dur.toMillis() / repeatInterval) + 1;
        version(HUNT_QUARTZ_DEBUG_MORE) {
            tracef("sec: %d, nano: %d , mi:%d", dur.getSeconds, dur.getNano, dur.toMillis());
            tracef("numberOfTimesExecuted: %d, repeatCount: %d", numberOfTimesExecuted, repeatCount);
        }

        if ((numberOfTimesExecuted > repeatCount) && 
            (repeatCount != REPEAT_INDEFINITELY)) {
            return null;
        }

        LocalDateTime time =  getStartTime().plusNanos(numberOfTimesExecuted * 
            repeatInterval * LocalTime.NANOS_PER_MILLI);

        if (endMillis <= time) {
            return null;
        }

        return time;
    }

    /**
     * <p>
     * Returns the last time at which the <code>SimpleTrigger</code> will
     * fire, before the given time. If the trigger will not fire before the
     * given time, <code>null</code> will be returned.
     * </p>
     */
    LocalDateTime getFireTimeBefore(LocalDateTime end) {
        if (end < getStartTime()) {
            return null;
        }

        int numFires = computeNumTimesFiredBetween(getStartTime(), end);

        return getStartTime().plusNanos(numFires * repeatInterval * LocalTime.NANOS_PER_MILLI);
    }

    int computeNumTimesFiredBetween(LocalDateTime start, LocalDateTime end) {

        if(repeatInterval < 1) {
            return 0;
        }
        
        long time = end.toEpochMilli() - start.toEpochMilli();

        return cast(int) (time / repeatInterval);
    }

    /**
     * <p>
     * Returns the final time at which the <code>SimpleTrigger</code> will
     * fire, if repeatCount is REPEAT_INDEFINITELY, null will be returned.
     * </p>
     * 
     * <p>
     * Note that the return time may be in the past.
     * </p>
     */
    override
    LocalDateTime getFinalFireTime() {
        if (repeatCount == 0) {
            return startTime;
        }

        if (repeatCount == REPEAT_INDEFINITELY) {
            return (getEndTime() is null) ? null : getFireTimeBefore(getEndTime()); 
        }

        LocalDateTime lastTrigger = startTime.plusMilliseconds((repeatCount * repeatInterval));

        if ((getEndTime() is null) || (lastTrigger < getEndTime())) { 
            return lastTrigger;
        } else {
            return getFireTimeBefore(getEndTime());
        }
    }

    /**
     * <p>
     * Determines whether or not the <code>SimpleTrigger</code> will occur
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

        if (repeatCount != 0 && repeatInterval < 1) {
            throw new SchedulerException("Repeat Interval cannot be zero.");
        }
    }

    /**
     * Used by extensions of SimpleTrigger to imply that there are additional 
     * properties, specifically so that extensions can choose whether to be 
     * stored as a serialized blob, or as a flattened SimpleTrigger table. 
     */
    bool hasAdditionalProperties() {
        return false;
    }

    override 
    TriggerBuilder!(SimpleTrigger) getTriggerBuilder() {
        return super.getTriggerBuilder();
    }

    /**
     * Get a {@link ScheduleBuilder} that is configured to produce a 
     * schedule identical to this trigger's schedule.
     * 
     * @see #getTriggerBuilder()
     */
    override
    ScheduleBuilder getScheduleBuilder() { // !(SimpleTrigger)
        
        SimpleScheduleBuilder sb = SimpleScheduleBuilder.simpleSchedule()
        .withIntervalInMilliseconds(getRepeatInterval())
        .withRepeatCount(getRepeatCount());
        
        switch(getMisfireInstruction()) {
            case MISFIRE_INSTRUCTION_FIRE_NOW : sb.withMisfireHandlingInstructionFireNow();
            break;

            case MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_EXISTING_COUNT : sb.withMisfireHandlingInstructionNextWithExistingCount();
            break;

            case MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT : sb.withMisfireHandlingInstructionNextWithRemainingCount();
            break;

            case MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_EXISTING_REPEAT_COUNT : sb.withMisfireHandlingInstructionNowWithExistingCount();
            break;

            case MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_REMAINING_REPEAT_COUNT : sb.withMisfireHandlingInstructionNowWithRemainingCount();
            break;

            default:
                assert(false);
        }
        
        return sb;
    }

    mixin CloneMemberTemplate!(typeof(this));   

    mixin SerializationMember!(typeof(this));

}
