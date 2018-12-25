
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

module hunt.quartz.impl.JobExecutionContextImpl;


import hunt.quartz.Calendar;
import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.Scheduler;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.spi.OperableTrigger;
import hunt.quartz.spi.TriggerFiredBundle;

import hunt.container.HashMap;
import hunt.lang.exception;
import hunt.time.LocalDateTime;

// import std.datetime;
import std.conv;


class JobExecutionContextImpl : JobExecutionContext {

    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private Scheduler scheduler;

    private Trigger trigger;

    private JobDetail jobDetail;
    
    private JobDataMap jobDataMap;

    private Job job;
    
    private Calendar calendar;

    private bool recovering = false;

    private int numRefires = 0;

    private LocalDateTime fireTime;

    private LocalDateTime scheduledFireTime;

    private LocalDateTime prevFireTime;

    private LocalDateTime nextFireTime;
    
    private long jobRunTime = -1;
    
    private Object result;
    
    private HashMap!(Object, Object) data;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a JobExcecutionContext with the given context data.
     * </p>
     */
    this(Scheduler scheduler,
            TriggerFiredBundle firedBundle, Job job) {
        data = new HashMap!(Object, Object)();
        this.scheduler = scheduler;
        this.trigger = firedBundle.getTrigger();
        this.calendar = firedBundle.getCalendar();
        this.jobDetail = firedBundle.getJobDetail();
        this.job = job;
        this.recovering = firedBundle.isRecovering();
        this.fireTime = firedBundle.getFireTime();
        this.scheduledFireTime = firedBundle.getScheduledFireTime();
        this.prevFireTime = firedBundle.getPrevFireTime();
        this.nextFireTime = firedBundle.getNextFireTime();
        
        this.jobDataMap = new JobDataMap();
        this.jobDataMap.putAll(jobDetail.getJobDataMap());
        this.jobDataMap.putAll(trigger.getJobDataMap());
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * {@inheritDoc}
     */
    Scheduler getScheduler() {
        return scheduler;
    }

    /**
     * {@inheritDoc}
     */
    Trigger getTrigger() {
        return trigger;
    }

    /**
     * {@inheritDoc}
     */
    Calendar getCalendar() {
        return calendar;
    }

    /**
     * {@inheritDoc}
     */
    bool isRecovering() {
        return recovering;
    }

    TriggerKey getRecoveringTriggerKey() {
        if (isRecovering()) {
            return new TriggerKey(jobDataMap.getString(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_GROUP),
                                  jobDataMap.getString(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_NAME));
        } else {
            throw new IllegalStateException("Not a recovering job");
        }
    }
    
    void incrementRefireCount() {
        numRefires++;
    }

    /**
     * {@inheritDoc}
     */
    int getRefireCount() {
        return numRefires;
    }

    /**
     * {@inheritDoc}
     */
    JobDataMap getMergedJobDataMap() {
        return jobDataMap;
    }

    /**
     * {@inheritDoc}
     */
    JobDetail getJobDetail() {
        return jobDetail;
    }

    /**
     * {@inheritDoc}
     */
    Job getJobInstance() {
        return job;
    }

    /**
     * {@inheritDoc}
     */
    LocalDateTime getFireTime() {
        return fireTime;
    }

    /**
     * {@inheritDoc}
     */
    LocalDateTime getScheduledFireTime() {
        return scheduledFireTime;
    }

    /**
     * {@inheritDoc}
     */
    LocalDateTime getPreviousFireTime() {
        return prevFireTime;
    }

    /**
     * {@inheritDoc}
     */
    LocalDateTime getNextFireTime() {
        return nextFireTime;
    }

    override
    string toString() {
        return "JobExecutionContext:" ~ " trigger: '"
                ~ getTrigger().getKey().toString() ~ " job: "
                ~ getJobDetail().getKey().toString() ~ " fireTime: '" ~ getFireTime().toString()
                ~ " scheduledFireTime: " ~ getScheduledFireTime().toString()
                ~ " previousFireTime: '" ~ getPreviousFireTime().toString()
                ~ " nextFireTime: " ~ getNextFireTime().toString() ~ " isRecovering: "
                ~ isRecovering().to!string() ~ " refireCount: " ~ getRefireCount().to!string();
    }

    /**
     * {@inheritDoc}
     */
    Object getResult() {
        return result;
    }
    
    /**
     * {@inheritDoc}
     */
    void setResult(Object result) {
        this.result = result;
    }
    
    /**
     * {@inheritDoc}
     */
    long getJobRunTime() {
        return jobRunTime;
    }
    
    /**
     * @param jobRunTime The jobRunTime to set.
     */
    void setJobRunTime(long jobRunTime) {
        this.jobRunTime = jobRunTime;
    }

    /**
     * {@inheritDoc}
     */
    void put(Object key, Object value) {
        data.put(key, value);
    }
    
    /**
     * {@inheritDoc}
     */
    Object get(Object key) {
        return data.get(key);
    }

    /**
     * {@inheritDoc}
     */
    string getFireInstanceId() {
        return (cast(OperableTrigger)trigger).getFireInstanceId();
    }
}
