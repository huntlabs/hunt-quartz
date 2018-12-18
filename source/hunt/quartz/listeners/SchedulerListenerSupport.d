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
 */
module hunt.quartz.listeners.SchedulerListenerSupport;

import hunt.quartz.JobDetail;
import hunt.quartz.JobKey;
import hunt.quartz.SchedulerException;
import hunt.quartz.SchedulerListener;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;
import hunt.logging;


/**
 * A helpful abstract base class for implementors of 
 * <code>{@link hunt.quartz.SchedulerListener}</code>.
 * 
 * <p>
 * The methods in this class are empty so you only need to override the  
 * subset for the <code>{@link hunt.quartz.SchedulerListener}</code> events
 * you care about.
 * </p>
 * 
 * @see hunt.quartz.SchedulerListener
 */
abstract class SchedulerListenerSupport : SchedulerListener {

    /**
     * Get the <code>{@link org.slf4j.Logger}</code> for this
     * class's category.  This should be used by subclasses for logging.
     */

    void jobAdded(JobDetail jobDetail) {
    }

    void jobDeleted(JobKey jobKey) {
    }

    void jobPaused(JobKey jobKey) {
    }

    void jobResumed(JobKey jobKey) {
    }

    void jobScheduled(Trigger trigger) {
    }

    void jobsPaused(string jobGroup) {
    }

    void jobsResumed(string jobGroup) {
    }

    void jobUnscheduled(TriggerKey triggerKey) {
    }

    void schedulerError(string msg, SchedulerException cause) {
    }

    void schedulerInStandbyMode() {
    }

    void schedulerShutdown() {
    }

    void schedulerShuttingdown() {
    }

    void schedulerStarted() {
    }

    void schedulerStarting() {
    }

    void triggerFinalized(Trigger trigger) {
    }

    void triggerPaused(TriggerKey triggerKey) {
    }

    void triggerResumed(TriggerKey triggerKey) {
    }

    void triggersPaused(string triggerGroup) {
    }

    void triggersResumed(string triggerGroup) {
    }
    
    void schedulingDataCleared() {
    }

}
