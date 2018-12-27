
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

module hunt.quartz.ee.jta.JTAJobRunShellFactory;

import hunt.quartz.Scheduler;
import hunt.quartz.exception;
import hunt.quartz.exception;
import hunt.quartz.core.JobRunShell;
import hunt.quartz.core.JobRunShellFactory;
import hunt.quartz.spi.TriggerFiredBundle;

import hunt.lang.exception;

/**
 * <p>
 * Responsible for creating the instances of <code>{@link hunt.quartz.ee.jta.JTAJobRunShell}</code>
 * to be used within the <class>{@link hunt.quartz.core.QuartzScheduler}
 * </code> instance.
 * </p>
 * 
 * <p>
 * This implementation does not re-use any objects, it simply makes a new
 * JTAJobRunShell each time <code>borrowJobRunShell()</code> is called.
 * </p>
 * 
 * @author James House
 */
class JTAJobRunShellFactory : JobRunShellFactory {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private Scheduler scheduler;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    this() {
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
     * Initialize the factory, providing a handle to the <code>Scheduler</code>
     * that should be made available within the <code>JobRunShell</code> and
     * the <code>JobExecutionContext</code> s within it, and a handle to the
     * <code>SchedulingContext</code> that the shell will use in its own
     * operations with the <code>JobStore</code>.
     * </p>
     */
    void initialize(Scheduler sched) {
        this.scheduler = sched;
    }

    /**
     * <p>
     * Called by the <class>{@link hunt.quartz.core.QuartzSchedulerThread}
     * </code> to obtain instances of <code>
     * {@link hunt.quartz.core.JobRunShell}</code>.
     * </p>
     */
    JobRunShell createJobRunShell(TriggerFiredBundle bundle) {
        // return new JTAJobRunShell(scheduler, bundle);
        implementationMissing(false);
        return null;
    }



}