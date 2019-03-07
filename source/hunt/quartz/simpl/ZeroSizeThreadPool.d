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

module hunt.quartz.simpl.ZeroSizeThreadPool;

import hunt.Exceptions;
import hunt.logging;
import hunt.util.Common;

import hunt.quartz.exception;
import hunt.quartz.spi.ThreadPool;

/**
 * <p>
 * This is class is a simple implementation of a zero size thread pool, based on the
 * <code>{@link hunt.quartz.spi.ThreadPool}</code> interface.
 * </p>
 * 
 * <p>
 * The pool has zero <code>Thread</code>s and does not grow or shrink based on demand.
 * Which means it is obviously not useful for most scenarios.  When it may be useful
 * is to prevent creating any worker threads at all - which may be desirable for
 * the sole purpose of preserving system resources in the case where the scheduler
 * instance only exists in order to schedule jobs, but which will never execute
 * jobs (e.g. will never have start() called on it).
 * </p>
 * 
 * <p>
 * </p>
 * 
 * @author Wayne Fay
 */
class ZeroSizeThreadPool : ThreadPool {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a new <code>ZeroSizeThreadPool</code>.
     * </p>
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


    int getPoolSize() {
        return 0;
    }

    void initialize() {
    }

    void shutdown() {
        shutdown(true);
    }

    void shutdown(bool waitForJobsToComplete) {
        trace("shutdown complete");
    }

    bool runInThread(Runnable runnable) {
        throw new UnsupportedOperationException("This ThreadPool should not be used on Scheduler instances that are start()ed.");
    }

    int blockForAvailableThreads() {
        throw new UnsupportedOperationException("This ThreadPool should not be used on Scheduler instances that are start()ed.");
    }

    void setInstanceId(string schedInstId) {
    }

    void setInstanceName(string schedName) {
    }

    void setThreadCount(int count) {

    }
    
    void setThreadPriority(int prio) {

    }

    int getThreadPriority() {
        return 0;
    }

}
