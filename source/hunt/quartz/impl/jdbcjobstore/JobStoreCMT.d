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


module hunt.quartz.impl.jdbcjobstore.JobStoreCMT;

import java.sql.Connection;
import java.sql.SQLException;

import hunt.quartz.JobPersistenceException;
import hunt.quartz.SchedulerConfigException;
import hunt.quartz.spi.ClassLoadHelper;
import hunt.quartz.spi.SchedulerSignaler;
import hunt.quartz.utils.DBConnectionManager;

/**
 * <p>
 * <code>JobStoreCMT</code> is meant to be used in an application-server
 * environment that provides container-managed-transactions. No commit /
 * rollback will be1 handled by this class.
 * </p>
 * 
 * <p>
 * If you need commit / rollback, use <code>{@link
 * hunt.quartz.impl.jdbcjobstore.JobStoreTX}</code>
 * instead.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 * @author James House
 * @author Srinivas Venkatarangaiah
 *  
 */
class JobStoreCMT : JobStoreSupport {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    protected string nonManagedTxDsName;

    // Great name huh?
    protected bool dontSetNonManagedTXConnectionAutoCommitFalse = false;

    
    protected bool setTxIsolationLevelReadCommitted = false;
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Set the name of the <code>DataSource</code> that should be used for
     * performing database functions.
     * </p>
     */
    void setNonManagedTXDataSource(string nonManagedTxDsName) {
        this.nonManagedTxDsName = nonManagedTxDsName;
    }

    /**
     * <p>
     * Get the name of the <code>DataSource</code> that should be used for
     * performing database functions.
     * </p>
     */
    string getNonManagedTXDataSource() {
        return nonManagedTxDsName;
    }

    bool isDontSetNonManagedTXConnectionAutoCommitFalse() {
        return dontSetNonManagedTXConnectionAutoCommitFalse;
    }

    /**
     * Don't call set autocommit(false) on connections obtained from the
     * DataSource. This can be helpfull in a few situations, such as if you
     * have a driver that complains if it is called when it is already off.
     * 
     * @param b
     */
    void setDontSetNonManagedTXConnectionAutoCommitFalse(bool b) {
        dontSetNonManagedTXConnectionAutoCommitFalse = b;
    }


    bool isTxIsolationLevelReadCommitted() {
        return setTxIsolationLevelReadCommitted;
    }

    /**
     * Set the transaction isolation level of DB connections to sequential.
     * 
     * @param b
     */
    void setTxIsolationLevelReadCommitted(bool b) {
        setTxIsolationLevelReadCommitted = b;
    }
    

    override
    void initialize(ClassLoadHelper loadHelper,
            SchedulerSignaler signaler) {

        if (nonManagedTxDsName is null) {
            throw new SchedulerConfigException(
                "Non-ManagedTX DataSource name not set!  " ~
                "If your 'hunt.quartz.jobStore.dataSource' is XA, then set " ~ 
                "'hunt.quartz.jobStore.nonManagedTXDataSource' to a non-XA "+ 
                "datasource (for the same DB).  " ~ 
                "Otherwise, you can set them to be the same.");
        }

        if (getLockHandler() is null) {
            // If the user hasn't specified an explicit lock handler, 
            // then we *must* use DB locks with CMT...
            setUseDBLocks(true);
        }

        super.initialize(loadHelper, signaler);

        info("JobStoreCMT initialized.");
    }
    
    override
    void shutdown() {

        super.shutdown();
        
        try {
            DBConnectionManager.getInstance().shutdown(getNonManagedTXDataSource());
        } catch (SQLException sqle) {
            warning("Database connection shutdown unsuccessful.", sqle);
        }
    }

    override
    protected Connection getNonManagedTXConnection() {
        Connection conn = null;
        try {
            conn = DBConnectionManager.getInstance().getConnection(
                    getNonManagedTXDataSource());
        } catch (SQLException sqle) {
            throw new JobPersistenceException(
                "Failed to obtain DB connection from data source '"
                        + getNonManagedTXDataSource() ~ "': "
                        + sqle.toString(), sqle);
        } catch (Throwable e) {
            throw new JobPersistenceException(
                "Failed to obtain DB connection from data source '"
                        + getNonManagedTXDataSource() ~ "': "
                        + e.toString(), e);
        }

        if (conn is null) { 
            throw new JobPersistenceException(
                "Could not get connection from DataSource '"
                        + getNonManagedTXDataSource() ~ "'"); 
        }

        // Protect connection attributes we might change.
        conn = getAttributeRestoringConnection(conn);
        
        // Set any connection connection attributes we are to override.
        try {
            if (!isDontSetNonManagedTXConnectionAutoCommitFalse()) {
                conn.setAutoCommit(false);
            }
            
            if (isTxIsolationLevelReadCommitted()) {
                conn.setTransactionIsolation(Connection.TRANSACTION_READ_COMMITTED);
            }
        } catch (SQLException sqle) {
            warning("Failed to override connection auto commit/transaction isolation.", sqle);
        } catch (Throwable e) {
            try { conn.close(); } catch(Throwable tt) {}
            
            throw new JobPersistenceException(
                "Failure setting up connection.", e);
        }
        
        return conn;
    }
    
    /**
     * Execute the given callback having optionally acquired the given lock.  
     * Because CMT assumes that the connection is already part of a managed
     * transaction, it does not attempt to commit or rollback the 
     * enclosing transaction.
     * 
     * @param lockName The name of the lock to acquire, for example 
     * "TRIGGER_ACCESS".  If null, then no lock is acquired, but the
     * txCallback is still executed in a transaction.
     * 
     * @see JobStoreSupport#executeInNonManagedTXLock(string, TransactionCallback)
     * @see JobStoreTX#executeInLock(string, TransactionCallback)
     * @see JobStoreSupport#getNonManagedTXConnection()
     * @see JobStoreSupport#getConnection()
     */
    override
    protected Object executeInLock(
            string lockName, 
            TransactionCallback txCallback) {
        bool transOwner = false;
        Connection conn = null;
        try {
            if (lockName !is null) {
                // If we aren't using db locks, then delay getting DB connection 
                // until after acquiring the lock since it isn't needed.
                if (getLockHandler().requiresConnection()) {
                    conn = getConnection();
                }
                
                transOwner = getLockHandler().obtainLock(conn, lockName);
            }

            if (conn is null) {
                conn = getConnection();
            }

            return txCallback.execute(conn);
        } finally {
            try {
                releaseLock(lockName, transOwner);
            } finally {
                cleanupConnection(conn);
            }
        }
    }
}

// EOF
