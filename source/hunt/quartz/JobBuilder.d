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

module hunt.quartz.JobBuilder;

import hunt.quartz.Job;
import hunt.quartz.JobDetail;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobKey;

import hunt.quartz.impl.JobDetailImpl;
import hunt.quartz.utils.Key;

import hunt.Boolean;
import hunt.Double;
import hunt.Float;
import hunt.Integer;
import hunt.Long;

/**
 * <code>JobBuilder</code> is used to instantiate {@link JobDetail}s.
 * 
 * <p>The builder will always try to keep itself in a valid state, with 
 * reasonable defaults set for calling build() at any point.  For instance
 * if you do not invoke <i>withIdentity(..)</i> a job name will be generated
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
 * @see TriggerBuilder
 * @see DateBuilder 
 * @see JobDetail
 */
class JobBuilder {

    private JobKey key;
    private string description;
    private TypeInfo_Class jobClass;
    private bool durability;
    private bool shouldRecover;
    
    private JobDataMap jobDataMap;
    
    protected this() {
        jobDataMap = new JobDataMap();
    }
    
    /**
     * Create a JobBuilder with which to define a <code>JobDetail</code>.
     * 
     * @return a new JobBuilder
     */
    static JobBuilder newJob() {
        return new JobBuilder();
    }
    
    /**
     * Create a JobBuilder with which to define a <code>JobDetail</code>,
     * and set the class name of the <code>Job</code> to be executed.
     * 
     * @return a new JobBuilder
     */
    static JobBuilder newJob(TypeInfo_Class jobClass) {
        JobBuilder b = new JobBuilder();
        b.ofType(jobClass);
        return b;
    }

    static JobBuilder newJob(T)() if(is(T : Job)) {
        JobBuilder b = new JobBuilder();
        b.ofType(typeid(T));
        return b;
    }

    /**
     * Produce the <code>JobDetail</code> instance defined by this 
     * <code>JobBuilder</code>.
     * 
     * @return the defined JobDetail.
     */
    JobDetail build() {

        JobDetailImpl job = new JobDetailImpl();
        
        job.setJobClass(jobClass);
        job.setDescription(description);
        if(key is null)
            key = new JobKey(IKey.createUniqueName(null), null);
        job.setKey(key); 
        job.setDurability(durability);
        job.setRequestsRecovery(shouldRecover);
        
        
        if(!jobDataMap.isEmpty())
            job.setJobDataMap(jobDataMap);
        
        return job;
    }
    
    /**
     * Use a <code>JobKey</code> with the given name and default group to
     * identify the JobDetail.
     * 
     * <p>If none of the 'withIdentity' methods are set on the JobBuilder,
     * then a random, unique JobKey will be generated.</p>
     * 
     * @param name the name element for the Job's JobKey
     * @return the updated JobBuilder
     * @see JobKey
     * @see JobDetail#getKey()
     */
    JobBuilder withIdentity(string name) {
        key = new JobKey(name, null);
        return this;
    }  
    
    /**
     * Use a <code>JobKey</code> with the given name and group to
     * identify the JobDetail.
     * 
     * <p>If none of the 'withIdentity' methods are set on the JobBuilder,
     * then a random, unique JobKey will be generated.</p>
     * 
     * @param name the name element for the Job's JobKey
     * @param group the group element for the Job's JobKey
     * @return the updated JobBuilder
     * @see JobKey
     * @see JobDetail#getKey()
     */
    JobBuilder withIdentity(string name, string group) {
        key = new JobKey(name, group);
        return this;
    }
    
    /**
     * Use a <code>JobKey</code> to identify the JobDetail.
     * 
     * <p>If none of the 'withIdentity' methods are set on the JobBuilder,
     * then a random, unique JobKey will be generated.</p>
     * 
     * @param jobKey the Job's JobKey
     * @return the updated JobBuilder
     * @see JobKey
     * @see JobDetail#getKey()
     */
    JobBuilder withIdentity(JobKey jobKey) {
        this.key = jobKey;
        return this;
    }
    
    /**
     * Set the given (human-meaningful) description of the Job.
     * 
     * @param jobDescription the description for the Job
     * @return the updated JobBuilder
     * @see JobDetail#getDescription()
     */
    JobBuilder withDescription(string jobDescription) {
        this.description = jobDescription;
        return this;
    }
    
    /**
     * Set the class which will be instantiated and executed when a
     * Trigger fires that is associated with this JobDetail.
     * 
     * @param jobClazz a class implementing the Job interface.
     * @return the updated JobBuilder
     * @see JobDetail#getJobClass()
     */
    JobBuilder ofType(TypeInfo_Class jobClazz) {
        this.jobClass = jobClazz;
        return this;
    }

    JobBuilder ofType(T)() if(is(T : Job)) {
        this.jobClass = typeid(T);
        return this;
    }

    /**
     * Instructs the <code>Scheduler</code> whether or not the <code>Job</code>
     * should be re-executed if a 'recovery' or 'fail-over' situation is
     * encountered.
     * 
     * <p>
     * If not explicitly set, the default value is <code>false</code>.
     * </p>
     * 
     * @return the updated JobBuilder
     * @see JobDetail#requestsRecovery()
     */
    JobBuilder requestRecovery() {
        this.shouldRecover = true;
        return this;
    }

    /**
     * Instructs the <code>Scheduler</code> whether or not the <code>Job</code>
     * should be re-executed if a 'recovery' or 'fail-over' situation is
     * encountered.
     * 
     * <p>
     * If not explicitly set, the default value is <code>false</code>.
     * </p>
     * 
     * @param jobShouldRecover the desired setting
     * @return the updated JobBuilder
     */
    JobBuilder requestRecovery(bool jobShouldRecover) {
        this.shouldRecover = jobShouldRecover;
        return this;
    }

    /**
     * Whether or not the <code>Job</code> should remain stored after it is
     * orphaned (no <code>{@link Trigger}s</code> point to it).
     * 
     * <p>
     * If not explicitly set, the default value is <code>false</code> 
     * - this method sets the value to <code>true</code>.
     * </p>
     * 
     * @return the updated JobBuilder
     * @see JobDetail#isDurable()
     */
    JobBuilder storeDurably() {
        this.durability = true;
        return this;
    }
    
    /**
     * Whether or not the <code>Job</code> should remain stored after it is
     * orphaned (no <code>{@link Trigger}s</code> point to it).
     * 
     * <p>
     * If not explicitly set, the default value is <code>false</code>.
     * </p>
     * 
     * @param jobDurability the value to set for the durability property.
     * @return the updated JobBuilder
     * @see JobDetail#isDurable()
     */
    JobBuilder storeDurably(bool jobDurability) {
        this.durability = jobDurability;
        return this;
    }
    
    /**
     * Add the given key-value pair to the JobDetail's {@link JobDataMap}.
     * 
     * @return the updated JobBuilder
     * @see JobDetail#getJobDataMap()
     */
    JobBuilder usingJobData(string dataKey, string value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the JobDetail's {@link JobDataMap}.
     * 
     * @return the updated JobBuilder
     * @see JobDetail#getJobDataMap()
     */
    JobBuilder usingJobData(string dataKey, Integer value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the JobDetail's {@link JobDataMap}.
     * 
     * @return the updated JobBuilder
     * @see JobDetail#getJobDataMap()
     */
    JobBuilder usingJobData(string dataKey, Long value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the JobDetail's {@link JobDataMap}.
     * 
     * @return the updated JobBuilder
     * @see JobDetail#getJobDataMap()
     */
    JobBuilder usingJobData(string dataKey, Float value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the JobDetail's {@link JobDataMap}.
     * 
     * @return the updated JobBuilder
     * @see JobDetail#getJobDataMap()
     */
    JobBuilder usingJobData(string dataKey, Double value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add the given key-value pair to the JobDetail's {@link JobDataMap}.
     * 
     * @return the updated JobBuilder
     * @see JobDetail#getJobDataMap()
     */
    JobBuilder usingJobData(string dataKey, Boolean value) {
        jobDataMap.put(dataKey, value);
        return this;
    }
    
    /**
     * Add all the data from the given {@link JobDataMap} to the
     * {@code JobDetail}'s {@code JobDataMap}.
     * 
     * @return the updated JobBuilder
     * @see JobDetail#getJobDataMap()
     */
    JobBuilder usingJobData(JobDataMap newJobDataMap) {
        jobDataMap.putAll(newJobDataMap);
        return this;
    }

    /**
     * Replace the {@code JobDetail}'s {@link JobDataMap} with the
     * given {@code JobDataMap}.
     * 
     * @return the updated JobBuilder
     * @see JobDetail#getJobDataMap() 
     */
    JobBuilder setJobData(JobDataMap newJobDataMap) {
        jobDataMap = newJobDataMap;
        return this;
    }
}
