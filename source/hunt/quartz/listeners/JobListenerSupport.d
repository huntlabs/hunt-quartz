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
module hunt.quartz.listeners.JobListenerSupport;

import hunt.logging;

import hunt.quartz.JobListener;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.exception;

/**
 * A helpful abstract base class for implementors of 
 * <code>{@link hunt.quartz.JobListener}</code>.
 * 
 * <p>
 * The methods in this class are empty so you only need to override the  
 * subset for the <code>{@link hunt.quartz.JobListener}</code> events
 * you care about.
 * </p>
 * 
 * <p>
 * You are required to implement <code>{@link hunt.quartz.JobListener#getName()}</code> 
 * to return the unique name of your <code>JobListener</code>.  
 * </p>
 * 
 * @see hunt.quartz.JobListener
 */
abstract class JobListenerSupport : JobListener {

    /**
     * Get the <code>{@link org.slf4j.Logger}</code> for this
     * class's category.  This should be used by subclasses for logging.
     */

    void jobToBeExecuted(JobExecutionContext context) {
    }

    void jobExecutionVetoed(JobExecutionContext context) {
    }

    void jobWasExecuted(JobExecutionContext context, JobExecutionException jobException) {
    }
}
