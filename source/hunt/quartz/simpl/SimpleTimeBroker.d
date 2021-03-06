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

module hunt.quartz.simpl.SimpleTimeBroker;

import std.datetime;

import hunt.quartz.Exceptions;
import hunt.quartz.spi.TimeBroker;

/**
 * <p>
 * The interface to be implemented by classes that want to provide a mechanism
 * by which the <code>{@link hunt.quartz.core.QuartzScheduler}</code> can
 * reliably determine the current time.
 * </p>
 * 
 * <p>
 * In general, the default implementation of this interface (<code>{@link hunt.quartz.simpl.SimpleTimeBroker}</code>-
 * which simply uses <code>System.getCurrentTimeMillis()</code> )is
 * sufficient. However situations may exist where this default scheme is
 * lacking in its robustsness - especially when Quartz is used in a clustered
 * configuration. For example, if one or more of the machines in the cluster
 * has a system time that varies by more than a few seconds from the clocks on
 * the other systems in the cluster, scheduling confusion will result.
 * </p>
 * 
 * @see hunt.quartz.core.QuartzScheduler
 * 
 * @author James House
 */
// 
// class SimpleTimeBroker : TimeBroker {

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Interface.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     /**
//      * <p>
//      * Get the current time, simply using <code>new LocalDateTime()</code>.
//      * </p>
//      */
//     LocalDateTime getCurrentTime() {
//         return new LocalDateTime();
//     }

//     void initialize() {
//         // do nothing...
//     }

//     void shutdown() {
//         // do nothing...
//     }

// }
