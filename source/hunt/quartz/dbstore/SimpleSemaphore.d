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

module hunt.quartz.dbstore.SimpleSemaphore;

import hunt.quartz.dbstore.Semaphore;

// import java.sql.Connection;
import hunt.collection.HashSet;
import hunt.concurrency.thread;
import hunt.logging.ConsoleLogger;

import core.sync.mutex;
import core.sync.condition;

import hunt.entity.EntityManager;
alias Connection = EntityManager;

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

    static HashSet!(string) lockOwners; // = new ThreadLocal!(HashSet!(string))();

    HashSet!(string) locks;
    private Mutex _locker;
    private Condition _lockerCondition;

    this() {
        _locker = new Mutex;
        _lockerCondition = new Condition(_locker);
        locks = new HashSet!(string)();
    }


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */


    private HashSet!(string) getThreadLocks() {
        HashSet!(string) threadLocks = lockOwners;
        if (threadLocks is null) {
            threadLocks = new HashSet!(string)();
            lockOwners = threadLocks;
        }
        return threadLocks;
    }

    /**
     * Grants a lock on the identified resource to the calling thread (blocking
     * until it is available).
     * 
     * @return true if the lock was obtained.
     */
    bool obtainLock(Connection conn, string lockName) {

        _locker.lock();
        scope(exit) {
            _locker.unlock();
        }

        version(HUNT_DEBUG) {
            trace("Lock '" ~ lockName ~ "' is desired by: "
                        ~ ThreadEx.getThis().name());
        }

        if (!isLockOwner(lockName)) {
            version(HUNT_DEBUG) {
                trace("Lock '" ~ lockName ~ "' is being obtained: "
                            ~ ThreadEx.getThis().name());
            }
            while (locks.contains(lockName)) {
                try {
                    _lockerCondition.wait();
                } catch (InterruptedException ie) {
                    version(HUNT_DEBUG) {
                        trace("Lock '" ~ lockName ~ "' was not obtained by: "
                                    ~ ThreadEx.getThis().name());
                    }
                }
            }

            version(HUNT_DEBUG) {
                trace("Lock '" ~ lockName ~ "' given to: "
                            ~ ThreadEx.getThis().name());
            }
            getThreadLocks().add(lockName);
            locks.add(lockName);
        } else version(HUNT_DEBUG) {
            trace("Lock '" ~ lockName ~ "' already owned by: "
                        ~ ThreadEx.getThis().name()
                        ~ " -- but not owner!",
                new Exception("stack-trace of wrongful returner"));
        }

        return true;
    }

    /**
     * Release the lock on the identified resource if it is held by the calling
     * thread.
     */
    void releaseLock(string lockName) {

        // lockName = lockName.intern();
        _locker.lock();
        scope(exit) {
            _locker.unlock();
        }

        if (isLockOwner(lockName)) {
            version(HUNT_DEBUG) {
                trace("Lock '" ~ lockName ~ "' retuned by: "
                            ~ ThreadEx.getThis().name());
            }
            getThreadLocks().remove(lockName);
            locks.remove(lockName);
            _lockerCondition.notifyAll();
        } else {
            version(HUNT_DEBUG) {
                trace(
                "Lock '" ~ lockName ~ "' attempt to retun by: "
                        ~ ThreadEx.getThis().name()
                        ~ " -- but not owner!",
                new Exception("stack-trace of wrongful returner"));
            }
        }
    }

    /**
     * Determine whether the calling thread owns a lock on the identified
     * resource.
     */
    bool isLockOwner(string lockName) {
        _locker.lock();
        scope(exit) {
            _locker.unlock();
        }

        // lockName = lockName.intern();

        return getThreadLocks().contains(lockName);
    }

    /**
     * This Semaphore implementation does not use the database.
     */
    bool requiresConnection() {
        return false;
    }
}
