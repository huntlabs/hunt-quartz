
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

module hunt.quartz.core.SchedulerSignalerImpl;

import hunt.quartz.core.QuartzScheduler;
import hunt.quartz.core.QuartzSchedulerThread;

import hunt.quartz.JobKey;
import hunt.quartz.exception;
import hunt.quartz.Trigger;
import hunt.quartz.spi.SchedulerSignaler;

import hunt.logging;

/**
 * An interface to be used by <code>JobStore</code> instances in order to
 * communicate signals back to the <code>QuartzScheduler</code>.
 * 
 * @author jhouse
 */
class SchedulerSignalerImpl : SchedulerSignaler {

    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    protected QuartzScheduler sched;
    protected QuartzSchedulerThread schedThread;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    this(QuartzScheduler sched, QuartzSchedulerThread schedThread) {
        this.sched = sched;
        this.schedThread = schedThread;
        
        trace("Initialized Scheduler Signaller of type: " ~ typeid(this).name);
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    void notifyTriggerListenersMisfired(Trigger trigger) {
        try {
            sched.notifyTriggerListenersMisfired(trigger);
        } catch (SchedulerException se) {
            sched.error("Error notifying listeners of trigger misfire.", se);
            sched.notifySchedulerListenersError(
                    "Error notifying listeners of trigger misfire.", se);
        }
    }

    void notifySchedulerListenersFinalized(Trigger trigger) {
        sched.notifySchedulerListenersFinalized(trigger);
    }

    void signalSchedulingChange(long candidateNewNextFireTime) {
        schedThread.signalSchedulingChange(candidateNewNextFireTime);
    }

    void notifySchedulerListenersJobDeleted(JobKey jobKey) {
        sched.notifySchedulerListenersJobDeleted(jobKey);
    }

    void notifySchedulerListenersError(string string, SchedulerException jpe) {
        sched.notifySchedulerListenersError(string, jpe);
    }
}
