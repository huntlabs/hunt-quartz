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

module hunt.quartz.TriggerBuilder;

import hunt.quartz.JobDetail;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobKey;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.SimpleScheduleBuilder;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;

import hunt.quartz.spi.MutableTrigger;
import hunt.quartz.utils.Key;

import hunt.Boolean;
import hunt.Double;
import hunt.Float;
import hunt.Integer;
import hunt.Long;
import hunt.Exceptions;
import hunt.time.LocalDateTime;

import std.datetime;

class TriggerBuilderHelper {

    /**
     * Create a new TriggerBuilder with which to define a 
     * specification for a Trigger.
     * 
     * @return the new TriggerBuilder
     */
    static TriggerBuilder!(T) newTrigger(T)() if(is(T : Trigger)) {
        return new TriggerBuilder!(T)();
    }
}

/**
 * <code>TriggerBuilder</code> is used to instantiate {@link Trigger}s.
 * 
 * <p>The builder will always try to keep itself in a valid state, with 
 * reasonable defaults set for calling build() at any point.  For instance
 * if you do not invoke <i>withSchedule(..)</i> method, a default schedule
 * of firing once immediately will be used.  As another example, if you
 * do not invoked <i>withIdentity(..)</i> a trigger name will be generated
 * for you.</p>
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
 * @see JobBuilder
 * @see ScheduleBuilder
 * @see DateBuilder 
 * @see Trigger
 */
class TriggerBuilder(T) if(is(T : Trigger)) {

    private TriggerKey key;
    private string description;
    private LocalDateTime startTime; // = new LocalDateTime();
    private LocalDateTime endTime;
    private int priority = Trigger.DEFAULT_PRIORITY;
    private string calendarName;
    private JobKey jobKey;
    private JobDataMap jobDataMap;
    
    private ScheduleBuilder scheduleBuilder = null; // !(Trigger)
    
    private this() {
        jobDataMap = new JobDataMap();
    }
    
    /**
     * Produce the <code>Trigger</code>.
     * 
     * @return a Trigger that meets the specifications of the builder.
     */
    // 
    T build() {

        if(scheduleBuilder is null)
            scheduleBuilder = SimpleScheduleBuilder.simpleSchedule();
        MutableTrigger trig = scheduleBuilder.build();
        
        trig.setCalendarName(calendarName);
        trig.setDescription(description);
        trig.setStartTime(startTime);
        trig.setEndTime(endTime);
        if(key is null)
            key = new TriggerKey(IKey.createUniqueName(null), null);
        trig.setKey(key); 
        if(jobKey !is null)
            trig.setJobKey(jobKey);
        trig.setPriority(priority);
        
        if(!jobDataMap.isEmpty())
            trig.setJobDataMap(jobDataMap);
        
        return cast(T) trig;
    }

    /**
     * Use a <code>TriggerKey</code> with the given name and default group to
     * identify the Trigger.
     * 
     * <p>If none of the 'withIdentity' methods are set on the TriggerBuilder,
     * then a random, unique TriggerKey will be generated.</p>
     * 
     * @param name the name element for the Trigger's TriggerKey
     * @return the updated TriggerBuilder
     * @see TriggerKey
     * @see Trigger#getKey()
     */
    TriggerBuilder!(T) withIdentity(string name) {
        key = new TriggerKey(name, null);
        return this;
    }  
    
    /**
     * Use a TriggerKey with the given name and group to
     * identify the Trigger.
     * 
     * <p>If none of the 'withIdentity' methods are set on the TriggerBuilder,
     * then a random, unique TriggerKey will be generated.</p>
     * 
     * @param name the name element for the Trigger's TriggerKey
     * @param group the group element for the Trigger's TriggerKey
     * @return the updated TriggerBuilder
     * @see TriggerKey
     * @see Trigger#getKey()
     */
    TriggerBuilder!(T) withIdentity(string name, string group) {
        key = new TriggerKey(name, group);
        return this;
    }
    
    /**
     * Use the given TriggerKey to identify the Trigger.  
     * 
     * <p>If none of the 'withIdentity' methods are set on the TriggerBuilder,
     * then a random, unique TriggerKey will be generated.</p>
     * 
     * @param triggerKey the TriggerKey for the Trigger to be built
     * @return the updated TriggerBuilder
     * @see TriggerKey
     * @see Trigger#getKey()
     */
    TriggerBuilder!(T) withIdentity(TriggerKey triggerKey) {
        this.key = triggerKey;
        return this;
    }

    /**
     * Set the given (human-meaningful) description of the Trigger.
     * 
     * @param triggerDescription the description for the Trigger
     * @return the updated TriggerBuilder
     * @see Trigger#getDescription()
     */
    TriggerBuilder!(T) withDescription(string triggerDescription) {
        this.description = triggerDescription;
        return this;
    }
    
    /**
     * Set the Trigger's priority.  When more than one Trigger have the same
     * fire time, the scheduler will fire the one with the highest priority
     * first.
     * 
     * @param triggerPriority the priority for the Trigger
     * @return the updated TriggerBuilder
     * @see Trigger#DEFAULT_PRIORITY
     * @see Trigger#getPriority()
     */
    TriggerBuilder!(T) withPriority(int triggerPriority) {
        this.priority = triggerPriority;
        return this;
    }

    /**
     * Set the name of the {@link Calendar} that should be applied to this
     * Trigger's schedule.
     * 
     * @param calName the name of the Calendar to reference.
     * @return the updated TriggerBuilder
     * @see Calendar
     * @see Trigger#getCalendarName()
     */
    TriggerBuilder!(T) modifiedByCalendar(string calName) {
        this.calendarName = calName;
        return this;
    }
    
    /**
     * Set the time the Trigger should start at - the trigger may or may
     * not fire at this time - depending upon the schedule configured for
     * the Trigger.  However the Trigger will NOT fire before this time,
     * regardless of the Trigger's schedule.
     *  
     * @param triggerStartTime the start time for the Trigger.
     * @return the updated TriggerBuilder
     * @see Trigger#getStartTime()
     * @see DateBuilder
     */
    TriggerBuilder!(T) startAt(LocalDateTime triggerStartTime) {
        this.startTime = triggerStartTime;
        return this;
    }
    
    /**
     * Set the time the Trigger should start at to the current moment - 
     * the trigger may or may not fire at this time - depending upon the 
     * schedule configured for the Trigger.  
     * 
     * @return the updated TriggerBuilder
     * @see Trigger#getStartTime()
     */
    TriggerBuilder!(T) startNow() {
        this.startTime = LocalDateTime.now();
        return this;
    }

    /**
     * Set the time at which the Trigger will no longer fire - even if it's
     * schedule has remaining repeats.    
     *  
     * @param triggerEndTime the end time for the Trigger.  If null, the end time is indefinite.
     * @return the updated TriggerBuilder
     * @see Trigger#getEndTime()
     * @see DateBuilder
     */
    TriggerBuilder!(T) endAt(LocalDateTime triggerEndTime) {
        this.endTime = triggerEndTime;
        return this;
    }

    /**
     * Set the {@link ScheduleBuilder} that will be used to define the 
     * Trigger's schedule.
     * 
     * <p>The particular <code>SchedulerBuilder</code> used will dictate
     * the concrete type of Trigger that is produced by the TriggerBuilder.</p>
     * 
     * @param schedBuilder the SchedulerBuilder to use.
     * @return the updated TriggerBuilder
     * @see ScheduleBuilder
     * @see SimpleScheduleBuilder
     * @see CronScheduleBuilder
     * @see CalendarIntervalScheduleBuilder
     */
    // 
    TriggerBuilder!(T) withSchedule(ScheduleBuilder schedBuilder)  { // if(is(SBT : T))
        this.scheduleBuilder = schedBuilder;
        return this;
    }

    /**
     * Set the identity of the Job which should be fired by the produced 
     * Trigger.
     * 
     * @param keyOfJobToFire the identity of the Job to fire.
     * @return the updated TriggerBuilder
     * @see Trigger#getJobKey()
     */
    TriggerBuilder!(T) forJob(JobKey keyOfJobToFire) {
        this.jobKey = keyOfJobToFire;
        return this;
    }
    
    /**
     * Set the identity of the Job which should be fired by the produced 
     * Trigger - a <code>JobKey</code> will be produced with the given
     * name and default group.
     * 
     * @param jobName the name of the job (in default group) to fire. 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobKey()
     */
    TriggerBuilder!(T) forJob(string jobName) {
        this.jobKey = new JobKey(jobName, null);
        return this;
    }
    
    /**
     * Set the identity of the Job which should be fired by the produced 
     * Trigger - a <code>JobKey</code> will be produced with the given
     * name and group.
     * 
     * @param jobName the name of the job to fire. 
     * @param jobGroup the group of the job to fire. 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobKey()
     */
    TriggerBuilder!(T) forJob(string jobName, string jobGroup) {
        this.jobKey = new JobKey(jobName, jobGroup);
        return this;
    }
    
    /**
     * Set the identity of the Job which should be fired by the produced 
     * Trigger, by extracting the JobKey from the given job.
     * 
     * @param jobDetail the Job to fire.
     * @return the updated TriggerBuilder
     * @see Trigger#getJobKey()
     */
    TriggerBuilder!(T) forJob(JobDetail jobDetail) {
        JobKey k = jobDetail.getKey();
        if(k.getName() is null)
            throw new IllegalArgumentException("The given job has not yet had a name assigned to it.");
        this.jobKey = k;
        return this;
    }

    /**
     * Add the given key-value pair to the Trigger's {@link JobDataMap}.
     * 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobDataMap()
     */
    TriggerBuilder!(T) usingJobData(string dataKey, string value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the Trigger's {@link JobDataMap}.
     * 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobDataMap()
     */
    TriggerBuilder!(T) usingJobData(string dataKey, Integer value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the Trigger's {@link JobDataMap}.
     * 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobDataMap()
     */
    TriggerBuilder!(T) usingJobData(string dataKey, Long value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the Trigger's {@link JobDataMap}.
     * 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobDataMap()
     */
    TriggerBuilder!(T) usingJobData(string dataKey, Float value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the Trigger's {@link JobDataMap}.
     * 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobDataMap()
     */
    TriggerBuilder!(T) usingJobData(string dataKey, Double value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the Trigger's {@link JobDataMap}.
     * 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobDataMap()
     */
    TriggerBuilder!(T) usingJobData(string dataKey, Boolean value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Set the Trigger's {@link JobDataMap}, adding any values to it
     * that were already set on this TriggerBuilder using any of the
     * other 'usingJobData' methods. 
     * 
     * @return the updated TriggerBuilder
     * @see Trigger#getJobDataMap()
     */
    TriggerBuilder!(T) usingJobData(JobDataMap newJobDataMap) {
        // add any existing data to this new map
        foreach(string dataKey; jobDataMap.byKey()) {
            newJobDataMap.put(dataKey, jobDataMap.get(dataKey));
        }
        jobDataMap = newJobDataMap; // set new map as the map to use
        return this;
    }
    
}
