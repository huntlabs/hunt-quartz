
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

module hunt.quartz.impl.triggers.AbstractTrigger;

import hunt.quartz.Calendar;
import hunt.quartz.CronTrigger;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.Exceptions;
import hunt.quartz.JobKey;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.Scheduler;
import hunt.quartz.Exceptions;
import hunt.quartz.SimpleTrigger;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerBuilder;
import hunt.quartz.TriggerKey;
import hunt.quartz.TriggerUtils;
import hunt.quartz.spi.OperableTrigger;

import hunt.Exceptions;
import hunt.time.LocalDateTime;
import hunt.util.ObjectUtils;
import hunt.util.Serialize;

import std.array;
import std.conv;
import std.datetime;

import witchcraft;


/**
 * <p>
 * The base abstract class to be extended by all <code>Trigger</code>s.
 * </p>
 * 
 * <p>
 * <code>Triggers</code> s have a name and group associated with them, which
 * should uniquely identify them within a single <code>{@link Scheduler}</code>.
 * </p>
 * 
 * <p>
 * <code>Trigger</code>s are the 'mechanism' by which <code>Job</code> s
 * are scheduled. Many <code>Trigger</code> s can point to the same <code>Job</code>,
 * but a single <code>Trigger</code> can only point to one <code>Job</code>.
 * </p>
 * 
 * <p>
 * Triggers can 'send' parameters/data to <code>Job</code>s by placing contents
 * into the <code>JobDataMap</code> on the <code>Trigger</code>.
 * </p>
 *
 * @author James House
 * @author Sharada Jambula
 */
abstract class AbstractTrigger(T) : OperableTrigger if(is(T : Trigger)) {


    /*
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    *
    * Data members.
    *
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */

    private string name;

    private string group = Scheduler.DEFAULT_GROUP;

    private string jobName;

    private string jobGroup = Scheduler.DEFAULT_GROUP;

    private string description;

    private JobDataMap jobDataMap;

    
    private bool volatility = false; // still here for serialization backward compatibility

    private string calendarName = null;

    private string fireInstanceId = null;

    private int misfireInstruction = MISFIRE_INSTRUCTION_SMART_POLICY;

    private int priority = DEFAULT_PRIORITY;

    private TriggerKey key = null;

    // mixin Witchcraft;

    /*
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    *
    * Constructors.
    *
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */



    /**
     * <p>
     * Create a <code>Trigger</code> with no specified name, group, or <code>{@link hunt.quartz.JobDetail}</code>.
     * </p>
     * 
     * <p>
     * Note that the {@link #setName(string)},{@link #setGroup(string)}and
     * the {@link #setJobName(string)}and {@link #setJobGroup(string)}methods
     * must be called before the <code>Trigger</code> can be placed into a
     * {@link Scheduler}.
     * </p>
     */
    this() {
        // do nothing...
    }

    /**
     * <p>
     * Create a <code>Trigger</code> with the given name, and default group.
     * </p>
     * 
     * <p>
     * Note that the {@link #setJobName(string)}and
     * {@link #setJobGroup(string)}methods must be called before the <code>Trigger</code>
     * can be placed into a {@link Scheduler}.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty, or the group is an empty string.
     */
    this(string name) {
        setName(name);
        setGroup(null);
    }
    
    /**
     * <p>
     * Create a <code>Trigger</code> with the given name, and group.
     * </p>
     * 
     * <p>
     * Note that the {@link #setJobName(string)}and
     * {@link #setJobGroup(string)}methods must be called before the <code>Trigger</code>
     * can be placed into a {@link Scheduler}.
     * </p>
     * 
     * @param group if <code>null</code>, Scheduler.DEFAULT_GROUP will be used.
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty, or the group is an empty string.
     */
    this(string name, string group) {
        setName(name);
        setGroup(group);
    }

    /**
     * <p>
     * Create a <code>Trigger</code> with the given name, and group.
     * </p>
     * 
     * @param group if <code>null</code>, Scheduler.DEFAULT_GROUP will be used.
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty, or the group is an empty string.
     */
    this(string name, string group, string jobName, string jobGroup) {
        setName(name);
        setGroup(group);
        setJobName(jobName);
        setJobGroup(jobGroup);
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
     * Get the name of this <code>Trigger</code>.
     * </p>
     */
    string getName() {
        return name;
    }

    /**
     * <p>
     * Set the name of this <code>Trigger</code>.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty.
     */
    void setName(string name) {
        if (name.empty()) {
            throw new IllegalArgumentException("Trigger name cannot be null or empty.");
        }

        this.name = name;
        this.key = null;
    }

    /**
     * <p>
     * Get the group of this <code>Trigger</code>.
     * </p>
     */
    string getGroup() {
        return group;
    }

    /**
     * <p>
     * Set the name of this <code>Trigger</code>. 
     * </p>
     * 
     * @param group if <code>null</code>, Scheduler.DEFAULT_GROUP will be used.
     * 
     * @exception IllegalArgumentException
     *              if group is an empty string.
     */
    void setGroup(string group) {
        if (group.empty()) {
            throw new IllegalArgumentException(
                    "Group name cannot be an empty string.");
        }

        if(group is null) {
            group = Scheduler.DEFAULT_GROUP;
        }

        this.group = group;
        this.key = null;
    }

    void setKey(TriggerKey key) {
        setName(key.getName());
        setGroup(key.getGroup());
        this.key = key;
    }

    /**
     * <p>
     * Get the name of the associated <code>{@link hunt.quartz.JobDetail}</code>.
     * </p>
     */
    string getJobName() {
        return jobName;
    }

    /**
     * <p>
     * Set the name of the associated <code>{@link hunt.quartz.JobDetail}</code>.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if jobName is null or empty.
     */
    void setJobName(string jobName) {
        if (jobName.empty()) {
            throw new IllegalArgumentException("Job name cannot be null or empty.");
        }

        this.jobName = jobName;
    }

    /**
     * <p>
     * Get the name of the associated <code>{@link hunt.quartz.JobDetail}</code>'s
     * group.
     * </p>
     */
    string getJobGroup() {
        return jobGroup;
    }

    /**
     * <p>
     * Set the name of the associated <code>{@link hunt.quartz.JobDetail}</code>'s
     * group.
     * </p>
     * 
     * @param jobGroup if <code>null</code>, Scheduler.DEFAULT_GROUP will be used.
     * 
     * @exception IllegalArgumentException
     *              if group is an empty string.
     */
    void setJobGroup(string jobGroup) {
        if (jobGroup.empty()) {
            throw new IllegalArgumentException(
                    "Group name cannot be null or empty.");
        }

        if(jobGroup is null) {
            jobGroup = Scheduler.DEFAULT_GROUP;
        }

        this.jobGroup = jobGroup;
    }

    void setJobKey(JobKey key) {
        setJobName(key.getName());
        setJobGroup(key.getGroup());
    }


    /**
     * <p>
     * Returns the 'full name' of the <code>Trigger</code> in the format
     * "group.name".
     * </p>
     */
    string getFullName() {
        return group ~ "." ~ name;
    }

    TriggerKey getKey() {
        if(key is null) {
            if(getName() is null)
                return null;
            key = new TriggerKey(getName(), getGroup());
        }

        return key;
    }

    JobKey getJobKey() {
        if(getJobName() is null)
            return null;

        return new JobKey(getJobName(), getJobGroup());
    }

    /**
     * <p>
     * Returns the 'full name' of the <code>Job</code> that the <code>Trigger</code>
     * points to, in the format "group.name".
     * </p>
     */
    string getFullJobName() {
        return jobGroup ~ "." ~ jobName;
    }

    /**
     * <p>
     * Return the description given to the <code>Trigger</code> instance by
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
     * Set a description for the <code>Trigger</code> instance - may be
     * useful for remembering/displaying the purpose of the trigger, though the
     * description has no meaning to Quartz.
     * </p>
     */
    void setDescription(string description) {
        this.description = description;
    }

    /**
     * <p>
     * Associate the <code>{@link Calendar}</code> with the given name with
     * this Trigger.
     * </p>
     * 
     * @param calendarName
     *          use <code>null</code> to dis-associate a Calendar.
     */
    void setCalendarName(string calendarName) {
        this.calendarName = calendarName;
    }

    /**
     * <p>
     * Get the name of the <code>{@link Calendar}</code> associated with this
     * Trigger.
     * </p>
     * 
     * @return <code>null</code> if there is no associated Calendar.
     */
    string getCalendarName() {
        return calendarName;
    }

    /**
     * <p>
     * Get the <code>JobDataMap</code> that is associated with the 
     * <code>Trigger</code>.
     * </p>
     * 
     * <p>
     * Changes made to this map during job execution are not re-persisted, and
     * in fact typically result in an <code>IllegalStateException</code>.
     * </p>
     */
    JobDataMap getJobDataMap() {
        if (jobDataMap is null) {
            jobDataMap = new JobDataMap();
        }
        return jobDataMap;
    }


    /**
     * <p>
     * Set the <code>JobDataMap</code> to be associated with the 
     * <code>Trigger</code>.
     * </p>
     */
    void setJobDataMap(JobDataMap jobDataMap) {
        this.jobDataMap = jobDataMap;
    }

    /**
     * The priority of a <code>Trigger</code> acts as a tiebreaker such that if 
     * two <code>Trigger</code>s have the same scheduled fire time, then the
     * one with the higher priority will get first access to a worker
     * thread.
     * 
     * <p>
     * If not explicitly set, the default value is <code>5</code>.
     * </p>
     * 
     * @see #DEFAULT_PRIORITY
     */
    int getPriority() {
        return priority;
    }


    /**
     * The priority of a <code>Trigger</code> acts as a tie breaker such that if 
     * two <code>Trigger</code>s have the same scheduled fire time, then Quartz
     * will do its best to give the one with the higher priority first access 
     * to a worker thread.
     * 
     * <p>
     * If not explicitly set, the default value is <code>5</code>.
     * </p>
     * 
     * @see #DEFAULT_PRIORITY
     */
    void setPriority(int priority) {
        this.priority = priority;
    }

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * Called when the <code>{@link Scheduler}</code> has decided to 'fire'
     * the trigger (execute the associated <code>Job</code>), in order to
     * give the <code>Trigger</code> a chance to update itself for its next
     * triggering (if any).
     * </p>
     * 
     * @see #executionComplete(JobExecutionContext, JobExecutionException)
     */
    abstract void triggered(Calendar calendar);

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
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
    abstract LocalDateTime computeFirstFireTime(Calendar calendar);

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * Called after the <code>{@link Scheduler}</code> has executed the
     * <code>{@link hunt.quartz.JobDetail}</code> associated with the <code>Trigger</code>
     * in order to get the final instruction code from the trigger.
     * </p>
     * 
     * @param context
     *          is the <code>JobExecutionContext</code> that was used by the
     *          <code>Job</code>'s!(code)execute(xx)</code> method.
     * @param result
     *          is the <code>JobExecutionException</code> thrown by the
     *          <code>Job</code>, if any (may be null).
     * @return one of the CompletedExecutionInstruction constants.
     * 
     * @see hunt.quartz.Trigger.CompletedExecutionInstruction
     * @see #triggered(Calendar)
     */
    CompletedExecutionInstruction executionComplete(JobExecutionContext context,
                                          JobExecutionException result)
    {
        if (result !is null && result.refireImmediately()) {
            return CompletedExecutionInstruction.RE_EXECUTE_JOB;
        }
    
        if (result !is null && result.unscheduleFiringTrigger()) {
            return CompletedExecutionInstruction.SET_TRIGGER_COMPLETE;
        }
    
        if (result !is null && result.unscheduleAllTriggers()) {
            return CompletedExecutionInstruction.SET_ALL_JOB_TRIGGERS_COMPLETE;
        }
    
        if (!mayFireAgain()) {
            return CompletedExecutionInstruction.DELETE_TRIGGER;
        }
    
        return CompletedExecutionInstruction.NOOP;
    }
    
    /**
     * <p>
     * Used by the <code>{@link Scheduler}</code> to determine whether or not
     * it is possible for this <code>Trigger</code> to fire again.
     * </p>
     * 
     * <p>
     * If the returned value is <code>false</code> then the <code>Scheduler</code>
     * may remove the <code>Trigger</code> from the <code>{@link hunt.quartz.spi.JobStore}</code>.
     * </p>
     */
    abstract bool mayFireAgain();

    /**
     * <p>
     * Get the time at which the <code>Trigger</code> should occur.
     * </p>
     */
    abstract LocalDateTime getStartTime();

    /**
     * <p>
     * The time at which the trigger's scheduling should start.  May or may not
     * be the first actual fire time of the trigger, depending upon the type of
     * trigger and the settings of the other properties of the trigger.  However
     * the first actual first time will not be before this date.
     * </p>
     * <p>
     * Setting a value in the past may cause a new trigger to compute a first
     * fire time that is in the past, which may cause an immediate misfire
     * of the trigger.
     * </p>
     */
    abstract void setStartTime(LocalDateTime startTime);

    /**
     * <p>
     * Set the time at which the <code>Trigger</code> should quit repeating -
     * regardless of any remaining repeats (based on the trigger's particular 
     * repeat settings). 
     * </p>
     * 
     * @see TriggerUtils#computeEndTimeToAllowParticularNumberOfFirings(hunt.quartz.spi.OperableTrigger, hunt.quartz.Calendar, int)
     */ 
    abstract void setEndTime(LocalDateTime endTime);

    /**
     * <p>
     * Get the time at which the <code>Trigger</code> should quit repeating -
     * regardless of any remaining repeats (based on the trigger's particular 
     * repeat settings). 
     * </p>
     * 
     * @see #getFinalFireTime()
     */
    abstract LocalDateTime getEndTime();

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
    abstract LocalDateTime getNextFireTime();

    /**
     * <p>
     * Returns the previous time at which the <code>Trigger</code> fired.
     * If the trigger has not yet fired, <code>null</code> will be returned.
     */
    abstract LocalDateTime getPreviousFireTime();

    /**
     * <p>
     * Returns the next time at which the <code>Trigger</code> will fire,
     * after the given time. If the trigger will not fire after the given time,
     * <code>null</code> will be returned.
     * </p>
     */
    abstract LocalDateTime getFireTimeAfter(LocalDateTime afterTime);

    /**
     * <p>
     * Returns the last time at which the <code>Trigger</code> will fire, if
     * the Trigger will repeat indefinitely, null will be returned.
     * </p>
     * 
     * <p>
     * Note that the return time *may* be in the past.
     * </p>
     */
    abstract LocalDateTime getFinalFireTime();

    /**
     * <p>
     * Set the instruction the <code>Scheduler</code> should be given for
     * handling misfire situations for this <code>Trigger</code>- the
     * concrete <code>Trigger</code> type that you are using will have
     * defined a set of additional <code>MISFIRE_INSTRUCTION_XXX</code>
     * constants that may be passed to this method.
     * </p>
     * 
     * <p>
     * If not explicitly set, the default value is <code>MISFIRE_INSTRUCTION_SMART_POLICY</code>.
     * </p>
     * 
     * @see #MISFIRE_INSTRUCTION_SMART_POLICY
     * @see #updateAfterMisfire(Calendar)
     * @see SimpleTrigger
     * @see CronTrigger
     */
    void setMisfireInstruction(int misfireInstruction) {
        if (!validateMisfireInstruction(misfireInstruction)) {
            throw new IllegalArgumentException(
                        "The misfire instruction code is invalid for this type of trigger.");
        }
        this.misfireInstruction = misfireInstruction;
    }

    protected abstract bool validateMisfireInstruction(int candidateMisfireInstruction);

    /**
     * <p>
     * Get the instruction the <code>Scheduler</code> should be given for
     * handling misfire situations for this <code>Trigger</code>- the
     * concrete <code>Trigger</code> type that you are using will have
     * defined a set of additional <code>MISFIRE_INSTRUCTION_XXX</code>
     * constants that may be passed to this method.
     * </p>
     * 
     * <p>
     * If not explicitly set, the default value is <code>MISFIRE_INSTRUCTION_SMART_POLICY</code>.
     * </p>
     * 
     * @see #MISFIRE_INSTRUCTION_SMART_POLICY
     * @see #updateAfterMisfire(Calendar)
     * @see SimpleTrigger
     * @see CronTrigger
     */
    int getMisfireInstruction() {
        return misfireInstruction;
    }

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * To be implemented by the concrete classes that extend this class.
     * </p>
     * 
     * <p>
     * The implementation should update the <code>Trigger</code>'s state
     * based on the MISFIRE_INSTRUCTION_XXX that was selected when the <code>Trigger</code>
     * was created.
     * </p>
     */
    abstract void updateAfterMisfire(Calendar cal);

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * To be implemented by the concrete class.
     * </p>
     * 
     * <p>
     * The implementation should update the <code>Trigger</code>'s state
     * based on the given new version of the associated <code>Calendar</code>
     * (the state should be updated so that it's next fire time is appropriate
     * given the Calendar's new settings). 
     * </p>
     * 
     * @param cal the modifying calendar
     */
    abstract void updateWithNewCalendar(Calendar cal, long misfireThreshold);

    /**
     * <p>
     * Validates whether the properties of the <code>JobDetail</code> are
     * valid for submission into a <code>Scheduler</code>.
     * 
     * @throws IllegalStateException
     *           if a required property (such as Name, Group, Class) is not
     *           set.
     */
    void validate() {
        if (name is null) {
            throw new SchedulerException("Trigger's name cannot be null");
        }

        if (group is null) {
            throw new SchedulerException("Trigger's group cannot be null");
        }

        if (jobName is null) {
            throw new SchedulerException(
                        "Trigger's related Job's name cannot be null");
        }

        if (jobGroup is null) {
            throw new SchedulerException(
                        "Trigger's related Job's group cannot be null");
        }
    }

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * Usable by <code>{@link hunt.quartz.spi.JobStore}</code>
     * implementations, in order to facilitate 'recognizing' instances of fired
     * <code>Trigger</code> s as their jobs complete execution.
     * </p>
     * 
     *  
     */
    void setFireInstanceId(string id) {
        this.fireInstanceId = id;
    }

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     */
    string getFireInstanceId() {
        return fireInstanceId;
    }

    /**
     * <p>
     * Return a simple string representation of this object.
     * </p>
     */
    override
    string toString() {
        import std.format;
        string str = format("Trigger '%s':  triggerClass: '%s calendar: '%s'" ~
                " misfireInstruction: %s nextFireTime: %s", 
                getFullName(), typeid(this).name, getCalendarName(), getMisfireInstruction(), getNextFireTime());
        return str;
    }

    /**
     * <p>
     * Compare the next fire time of this <code>Trigger</code> to that of
     * another by comparing their keys, or in other words, sorts them
     * according to the natural (i.e. alphabetical) order of their keys.
     * </p>
     */
    int opCmp(Trigger other) {

        if(other.getKey() is null && getKey() is null)
            return 0;
        if(other.getKey() is null)
            return -1;
        if(getKey() is null)
            return 1;
        
        return getKey().opCmp(other.getKey());
    }

    /**
     * Trigger equality is based upon the equality of the TriggerKey.
     * 
     * @return true if the key of this Trigger equals that of the given Trigger.
     */
    override
    bool opEquals(Object o) {
        Trigger other = cast(Trigger)o;
        if(other is null)
            return false;

        return !(other.getKey() is null || getKey() is null) && getKey()== other.getKey();

    }


    override
    size_t toHash() @trusted nothrow {
        TriggerKey key;
        try {
            key = getKey();
        } catch(Exception) {
        }
        if(key is null)
            return super.toHash();
        
        return key.toHash();
    }

    mixin CloneMemberTemplate!(typeof(this), TopLevel.yes, (typeof(this) from, typeof(this) to) {

        // Shallow copy the jobDataMap.  Note that this means that if a user
        // modifies a value object in this map from the cloned Trigger
        // they will also be modifying this Trigger. 
        if (from.jobDataMap !is null) {
            to.jobDataMap = cast(JobDataMap) from.jobDataMap.clone();
        }
    });    
    
    TriggerBuilder!(T) getTriggerBuilder() {
        return newTrigger!T()
            .forJob(getJobKey())
            .modifiedByCalendar(getCalendarName())
            .usingJobData(getJobDataMap())
            .withDescription(getDescription())
            .endAt(getEndTime())
            .withIdentity(getKey())
            .withPriority(getPriority())
            .startAt(getStartTime())
            .withSchedule(getScheduleBuilder());
    }

    abstract ScheduleBuilder getScheduleBuilder(); // !(T)


    mixin SerializationMember!(typeof(this));
}
