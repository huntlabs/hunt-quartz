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
module hunt.quartz.impl.jdbcjobstore.DBSemaphore;

import java.sql.Connection;
import java.util.HashSet;

import hunt.logging;


/**
 * Base class for database based lock handlers for providing thread/resource locking 
 * in order to protect resources from being altered by multiple threads at the 
 * same time.
 */
abstract class DBSemaphore : Semaphore, Constants,
    StdJDBCConstants, TablePrefixAware {


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    ThreadLocal!(HashSet!(string)) lockOwners = new ThreadLocal!(HashSet!(string))();

    private string sql;
    private string insertSql;

    private string tablePrefix;
    
    private string schedName;

    private string expandedSQL;
    private string expandedInsertSQL;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    DBSemaphore(string tablePrefix, string schedName, string defaultSQL, string defaultInsertSQL) {
        this.tablePrefix = tablePrefix;
        this.schedName = schedName;
        setSQL(defaultSQL);
        setInsertSQL(defaultInsertSQL);
    }

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
     * Execute the SQL that will lock the proper database row.
     */
    protected abstract void executeSQL(Connection conn, string lockName, string theExpandedSQL, string theExpandedInsertSQL);
    
    /**
     * Grants a lock on the identified resource to the calling thread (blocking
     * until it is available).
     * 
     * @return true if the lock was obtained.
     */
    bool obtainLock(Connection conn, string lockName) {

        if(log.isDebugEnabled()) {
            log.debug(
                "Lock '" ~ lockName ~ "' is desired by: "
                        + Thread.getThis().name());
        }
        if (!isLockOwner(lockName)) {

            executeSQL(conn, lockName, expandedSQL, expandedInsertSQL);
            
            if(log.isDebugEnabled()) {
                log.debug(
                    "Lock '" ~ lockName ~ "' given to: "
                            + Thread.getThis().name());
            }
            getThreadLocks().add(lockName);
            //getThreadLocksObtainer().put(lockName, new
            // Exception("Obtainer..."));
        } else if(log.isDebugEnabled()) {
            log.debug(
                "Lock '" ~ lockName ~ "' Is already owned by: "
                        + Thread.getThis().name());
        }

        return true;
    }

       
    /**
     * Release the lock on the identified resource if it is held by the calling
     * thread.
     */
    void releaseLock(string lockName) {

        if (isLockOwner(lockName)) {
            version(HUNT_DEBUG) {
                trace(
                    "Lock '" ~ lockName ~ "' returned by: "
                            + Thread.getThis().name());
            }
            getThreadLocks().remove(lockName);
            //getThreadLocksObtainer().remove(lockName);
        } else version(HUNT_DEBUG) {
            warning(
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
    bool isLockOwner(string lockName) {
        return getThreadLocks().contains(lockName);
    }

    /**
     * This Semaphore implementation does use the database.
     */
    bool requiresConnection() {
        return true;
    }

    protected string getSQL() {
        return sql;
    }

    protected void setSQL(string sql) {
        if ((sql !is null) && (sql.trim().length() != 0)) {
            this.sql = sql.trim();
        }
        
        setExpandedSQL();
    }

    protected void setInsertSQL(string insertSql) {
        if ((insertSql !is null) && (insertSql.trim().length() != 0)) {
            this.insertSql = insertSql.trim();
        }
        
        setExpandedSQL();
    }

    private void setExpandedSQL() {
        if (getTablePrefix() !is null && getSchedName() !is null && sql !is null && insertSql !is null) {
            expandedSQL = Util.rtp(this.sql, getTablePrefix(), getSchedulerNameLiteral());
            expandedInsertSQL = Util.rtp(this.insertSql, getTablePrefix(), getSchedulerNameLiteral());
        }
    }
    
    private string schedNameLiteral = null;
    protected string getSchedulerNameLiteral() {
        if(schedNameLiteral is null)
            schedNameLiteral = "'" ~ schedName ~ "'";
        return schedNameLiteral;
    }

    string getSchedName() {
        return schedName;
    }

    void setSchedName(string schedName) {
        this.schedName = schedName;
        
        setExpandedSQL();
    }
    
    protected string getTablePrefix() {
        return tablePrefix;
    }

    void setTablePrefix(string tablePrefix) {
        this.tablePrefix = tablePrefix;
        
        setExpandedSQL();
    }
}
