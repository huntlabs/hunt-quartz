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

module hunt.quartz.spi.TriggerFiredBundle;

import std.datetime;

import hunt.quartz.Calendar;
import hunt.quartz.JobDetail;
import hunt.quartz.spi.OperableTrigger;

/**
 * <p>
 * A simple class (structure) used for returning execution-time data from the
 * JobStore to the <code>QuartzSchedulerThread</code>.
 * </p>
 * 
 * @see hunt.quartz.core.QuartzSchedulerThread
 * 
 * @author James House
 */
class TriggerFiredBundle {
  

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private JobDetail job;

    private OperableTrigger trigger;

    private Calendar cal;

    private bool jobIsRecovering;

    private LocalDateTime fireTime;

    private LocalDateTime scheduledFireTime;

    private LocalDateTime prevFireTime;

    private LocalDateTime nextFireTime;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    this(JobDetail job, OperableTrigger trigger, Calendar cal,
            bool jobIsRecovering, LocalDateTime fireTime, LocalDateTime scheduledFireTime,
            LocalDateTime prevFireTime, LocalDateTime nextFireTime) {
        this.job = job;
        this.trigger = trigger;
        this.cal = cal;
        this.jobIsRecovering = jobIsRecovering;
        this.fireTime = fireTime;
        this.scheduledFireTime = scheduledFireTime;
        this.prevFireTime = prevFireTime;
        this.nextFireTime = nextFireTime;
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    JobDetail getJobDetail() {
        return job;
    }

    OperableTrigger getTrigger() {
        return trigger;
    }

    Calendar getCalendar() {
        return cal;
    }

    bool isRecovering() {
        return jobIsRecovering;
    }

    /**
     * @return Returns the fireTime.
     */
    LocalDateTime getFireTime() {
        return fireTime;
    }

    /**
     * @return Returns the nextFireTime.
     */
    LocalDateTime getNextFireTime() {
        return nextFireTime;
    }

    /**
     * @return Returns the prevFireTime.
     */
    LocalDateTime getPrevFireTime() {
        return prevFireTime;
    }

    /**
     * @return Returns the scheduledFireTime.
     */
    LocalDateTime getScheduledFireTime() {
        return scheduledFireTime;
    }

}