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

module hunt.quartz.impl.SchedulerRepository;

import hunt.container.Collection;
import hunt.container.HashMap;

import hunt.quartz.Scheduler;
import hunt.quartz.exception;

/**
 * <p>
 * Holds references to Scheduler instances - ensuring uniqueness, and
 * preventing garbage collection, and allowing 'global' lookups - all within a
 * ClassLoader space.
 * </p>
 * 
 * @author James House
 */
class SchedulerRepository {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private HashMap!(string, Scheduler) schedulers;

    private static SchedulerRepository inst;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private this() {
        schedulers = new HashMap!(string, Scheduler)();
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    static synchronized SchedulerRepository getInstance() {
        if (inst is null) {
            inst = new SchedulerRepository();
        }

        return inst;
    }

    synchronized void bind(Scheduler sched) {

        if (cast(Scheduler) schedulers.get(sched.getSchedulerName()) !is null) {
            throw new SchedulerException("Scheduler with name '"
                    + sched.getSchedulerName() ~ "' already exists.");
        }

        schedulers.put(sched.getSchedulerName(), sched);
    }

    synchronized bool remove(string schedName) {
        return (schedulers.remove(schedName) !is null);
    }

    synchronized Scheduler lookup(string schedName) {
        return schedulers.get(schedName);
    }

    synchronized Collection!(Scheduler) lookupAll() {
        return java.container.Collections
                .unmodifiableCollection(schedulers.values());
    }

}