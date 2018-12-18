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
module hunt.quartz.impl.jdbcjobstore.JTANonClusteredSemaphore;

import java.sql.Connection;
import java.util.HashSet;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.transaction.Synchronization;
import javax.transaction.SystemException;
import javax.transaction.Transaction;
import javax.transaction.TransactionManager;

import hunt.logging;


/**
 * Provides in memory thread/resource locking that is JTA 
 * <code>{@link javax.transaction.Transaction}</code> aware.  
 * It is most appropriate for use when using 
 * <code>{@link hunt.quartz.impl.jdbcjobstore.JobStoreCMT}</code> without clustering.
 * 
 * <p>
 * This <code>Semaphore</code> implementation is <b>not</b> Quartz cluster safe.  
 * </p>
 *  
 * <p>
 * When a lock is obtained/released but there is no active JTA 
 * <code>{@link javax.transaction.Transaction}</code>, then this <code>Semaphore</code> operates
 * just like <code>{@link hunt.quartz.impl.jdbcjobstore.SimpleSemaphore}</code>. 
 * </p>
 * 
 * <p>
 * By default, this class looks for the <code>{@link javax.transaction.TransactionManager}</code>
 * in JNDI under name "java:TransactionManager".  If this is not where your Application Server 
 * registers it, you can modify the JNDI lookup location using the 
 * "transactionManagerJNDIName" property.
 * </p>
 *
 * <p>
 * <b>IMPORTANT:</b>  This Semaphore implementation is currently experimental.  
 * It has been tested a limited amount on JBoss 4.0.3SP1.  If you do choose to 
 * use it, any feedback would be most appreciated! 
 * </p>
 * 
 * @see hunt.quartz.impl.jdbcjobstore.SimpleSemaphore
 */
class JTANonClusteredSemaphore : Semaphore {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    enum string DEFAULT_TRANSACTION_MANANGER_LOCATION = "java:TransactionManager";

    ThreadLocal!(HashSet!(string)) lockOwners = new ThreadLocal!(HashSet!(string))();

    HashSet!(string) locks = new HashSet!(string)();


    private string transactionManagerJNDIName = DEFAULT_TRANSACTION_MANANGER_LOCATION;
    
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */


    void setTransactionManagerJNDIName(string transactionManagerJNDIName) {
        this.transactionManagerJNDIName = transactionManagerJNDIName;
    }
    
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

        if (!isLockOwner(conn, lockName)) {
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

            // If we are in a transaction, register a callback to actually release
            // the lock when the transaction completes
            Transaction t = getTransaction();
            if (t !is null) {
                try {
                    t.registerSynchronization(new SemaphoreSynchronization(lockName));
                } catch (Exception e) {
                    throw new LockException("Failed to register semaphore with Transaction.", e);
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
     * Helper method to get the current <code>{@link javax.transaction.Transaction}</code>
     * from the <code>{@link javax.transaction.TransactionManager}</code> in JNDI.
     * 
     * @return The current <code>{@link javax.transaction.Transaction}</code>, null if
     * not currently in a transaction.
     */
    protected Transaction getTransaction() throws LockException{
        InitialContext ic = null; 
        try {
            ic = new InitialContext(); 
            TransactionManager tm = (TransactionManager)ic.lookup(transactionManagerJNDIName);
            
            return tm.getTransaction();
        } catch (SystemException e) {
            throw new LockException("Failed to get Transaction from TransactionManager", e);
        } catch (NamingException e) {
            throw new LockException("Failed to find TransactionManager in JNDI under name: " ~ transactionManagerJNDIName, e);
        } finally {
            if (ic !is null) {
                try {
                    ic.close();
                } catch (NamingException ignored) {
                }
            }
        }
    }
    
    /**
     * Release the lock on the identified resource if it is held by the calling
     * thread, unless currently in a JTA transaction.
     */
    synchronized void releaseLock(string lockName) {
        releaseLock(lockName, false);
    }
    
    /**
     * Release the lock on the identified resource if it is held by the calling
     * thread, unless currently in a JTA transaction.
     * 
     * @param fromSynchronization True if this method is being invoked from
     *      <code>{@link Synchronization}</code> notified of the enclosing 
     *      transaction having completed.
     * 
     * @throws LockException Thrown if there was a problem accessing the JTA 
     *      <code>Transaction</code>.  Only relevant if <code>fromSynchronization</code>
     *      is false.
     */
    protected synchronized void releaseLock(
        string lockName, bool fromSynchronization) {
        lockName = lockName.intern();

        if (isLockOwner(null, lockName)) {
            
            if (fromSynchronization == false) {
                Transaction t = getTransaction();
                if (t !is null) {
                    version(HUNT_DEBUG) {
                        trace(
                            "Lock '" ~ lockName ~ "' is in a JTA transaction.  " ~ 
                            "Return deferred by: " ~ Thread.getThis().name());
                    }
                    
                    // If we are still in a transaction, then we don't want to 
                    // actually release the lock.
                    return;
                }
            }
            
            version(HUNT_DEBUG) {
                trace(
                    "Lock '" ~ lockName ~ "' returned by: "
                            + Thread.getThis().name());
            }
            getThreadLocks().remove(lockName);
            locks.remove(lockName);
            this.notify();
        } else version(HUNT_DEBUG) {
            trace(
                "Lock '" ~ lockName ~ "' attempt to return by: "
                        + Thread.getThis().name()
                        ~ " -- but not owner!",
                new Exception("stack-trace of wrongful returner"));
        }
    }

    /**
     * Determine whether the calling thread owns a lock on the identified
     * resource.
     */
    synchronized bool isLockOwner(Connection conn, string lockName) {
        lockName = lockName.intern();

        return getThreadLocks().contains(lockName);
    }

    /**
     * This Semaphore implementation does not use the database.
     */
    bool requiresConnection() {
        return false;
    }

    /**
     * Helper class that is registered with the active 
     * <code>{@link javax.transaction.Transaction}</code> so that the lock
     * will be released when the transaction completes.
     */
    private class SemaphoreSynchronization : Synchronization {
        private string lockName;
        
        SemaphoreSynchronization(string lockName) {
            this.lockName = lockName;
        }
        
        void beforeCompletion() {
            // nothing to do...
        }
    
        void afterCompletion(int status) {
            try {
                releaseLock(lockName, true);
            } catch (LockException e) {
                // Ignore as can't be thrown with fromSynchronization set to true
            }
        }
    }
}
