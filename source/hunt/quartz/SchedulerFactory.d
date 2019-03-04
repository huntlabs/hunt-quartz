
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

module hunt.quartz.SchedulerFactory;

import hunt.quartz.Scheduler;

import hunt.collection.Collection;

/**
 * Provides a mechanism for obtaining client-usable handles to <code>Scheduler</code>
 * instances.
 * 
 * @see Scheduler
 * @see hunt.quartz.impl.StdSchedulerFactory
 * 
 * @author James House
 */
interface SchedulerFactory {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Returns a client-usable handle to a <code>Scheduler</code>.
     * </p>
     * 
     * @throws SchedulerException
     *           if there is a problem with the underlying <code>Scheduler</code>.
     */
    Scheduler getScheduler();

    /**
     * <p>
     * Returns a handle to the Scheduler with the given name, if it exists.
     * </p>
     */
    Scheduler getScheduler(string schedName);

    /**
     * <p>
     * Returns handles to all known Schedulers (made by any SchedulerFactory
     * within this jvm.).
     * </p>
     */
    Collection!(Scheduler) getAllSchedulers();

}
