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

module hunt.quartz.impl.jdbcjobstore.SimpleSemaphore;

import java.sql.Connection;
import java.util.HashSet;

import hunt.logging;


/**
 * Internal in-memory lock handler for providing thread/resource locking in 
 * order to protect resources from being altered by multiple threads at the 
 * same time.
 * 
 * @author jhouse
 */
class SimpleSemaphore : Semaphore {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    ThreadLocal!(HashSet!(string)) lockOwners = new ThreadLocal!(HashSet!(string))();

    HashSet!(string) locks = new HashSet!(string)();


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */


    private HashSet!(string) getThreadLocks() {
        HashSet!(string) threadLocks = lockOwners.get();
        if (threadLocks is null) {
            threadLocks = new HashSet!(string)();
            lockOwners.set(threadLocks);
        }
        return threadLocks;
    }

    /**
     * Grants a lock on the identified resource to the calling thread (blocking
     * until it is available).
     * 
     * @return true if the lock was obtained.
     */
    synchronized bool obtainLock(Connection conn, string lockName) {

        lockName = lockName.intern();

        if(log.isDebugEnabled()) {
            log.debug(
                "Lock '" ~ lockName ~ "' is desired by: "
                        + Thread.getThis().name());
        }

        if (!isLockOwner(lockName)) {
            if(log.isDebugEnabled()) {
                log.debug(
                    "Lock '" ~ lockName ~ "' is being obtained: "
                            + Thread.getThis().name());
            }
            while (locks.contains(lockName)) {
                try {
                    this.wait();
                } catch (InterruptedException ie) {
                    if(log.isDebugEnabled()) {
                        log.debug(
                            "Lock '" ~ lockName ~ "' was not obtained by: "
                                    + Thread.getThis().name());
                    }
                }
            }

            if(log.isDebugEnabled()) {
                log.debug(
                    "Lock '" ~ lockName ~ "' given to: "
                            + Thread.getThis().name());
            }
            getThreadLocks().add(lockName);
            locks.add(lockName);
        } else if(log.isDebugEnabled()) {
            log.debug(
                "Lock '" ~ lockName ~ "' already owned by: "
                        + Thread.getThis().name()
                        ~ " -- but not owner!",
                new Exception("stack-trace of wrongful returner"));
        }

        return true;
    }

    /**
     * Release the lock on the identified resource if it is held by the calling
     * thread.
     */
    synchronized void releaseLock(string lockName) {

        lockName = lockName.intern();

        if (isLockOwner(lockName)) {
            version(HUNT_DEBUG) {
                trace(
                    "Lock '" ~ lockName ~ "' retuned by: "
                            ~ Thread.getThis().name());
            }
            getThreadLocks().remove(lockName);
            locks.remove(lockName);
            this.notifyAll();
        } else {
            version(HUNT_DEBUG) {
                trace(
                "Lock '" ~ lockName ~ "' attempt to retun by: "
                        ~ Thread.getThis().name()
                        ~ " -- but not owner!",
                new Exception("stack-trace of wrongful returner"));
            }
        }
    }

    /**
     * Determine whether the calling thread owns a lock on the identified
     * resource.
     */
    synchronized bool isLockOwner(string lockName) {

        lockName = lockName.intern();

        return getThreadLocks().contains(lockName);
    }

    /**
     * This Semaphore implementation does not use the database.
     */
    bool requiresConnection() {
        return false;
    }
}
