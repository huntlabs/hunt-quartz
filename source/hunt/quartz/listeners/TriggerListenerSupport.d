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
module hunt.quartz.listeners.TriggerListenerSupport;

import hunt.logging;

import hunt.quartz.TriggerListener;
import hunt.quartz.Trigger;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.Trigger.CompletedExecutionInstruction;

/**
 * A helpful abstract base class for implementors of 
 * <code>{@link hunt.quartz.TriggerListener}</code>.
 * 
 * <p>
 * The methods in this class are empty so you only need to override the  
 * subset for the <code>{@link hunt.quartz.TriggerListener}</code> events
 * you care about.
 * </p>
 * 
 * <p>
 * You are required to implement <code>{@link hunt.quartz.TriggerListener#getName()}</code> 
 * to return the unique name of your <code>TriggerListener</code>.  
 * </p>
 * 
 * @see hunt.quartz.TriggerListener
 */
abstract class TriggerListenerSupport : TriggerListener {

    /**
     * Get the <code>{@link org.slf4j.Logger}</code> for this
     * class's category.  This should be used by subclasses for logging.
     */

    void triggerFired(Trigger trigger, JobExecutionContext context) {
    }

    bool vetoJobExecution(Trigger trigger, JobExecutionContext context) {
        return false;
    }

    void triggerMisfired(Trigger trigger) {
    }

    void triggerComplete(
        Trigger trigger,
        JobExecutionContext context,
        CompletedExecutionInstruction triggerInstructionCode) {
    }
}
