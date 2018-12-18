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

module hunt.quartz.impl.jdbcjobstore.JobStoreSupport;

import java.io.IOException;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Proxy;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import std.datetime;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import hunt.container.Map;
import hunt.comtainer.Set;

import hunt.quartz.Calendar;
import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobKey;
import hunt.quartz.JobPersistenceException;
import hunt.quartz.ObjectAlreadyExistsException;
import hunt.quartz.Scheduler;
import hunt.quartz.SchedulerConfigException;
import hunt.quartz.SchedulerException;
import hunt.quartz.SimpleTrigger;
import hunt.quartz.Trigger;
import hunt.quartz.Trigger.CompletedExecutionInstruction;
import hunt.quartz.Trigger.TriggerState;
import hunt.quartz.TriggerKey;
import hunt.quartz.impl.DefaultThreadExecutor;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.impl.matchers.StringMatcher;
import hunt.quartz.impl.matchers.StringMatcher.StringOperatorName;
import hunt.quartz.impl.triggers.SimpleTriggerImpl;
import hunt.quartz.spi.ClassLoadHelper;
import hunt.quartz.spi.JobStore;
import hunt.quartz.spi.OperableTrigger;
import hunt.quartz.spi.SchedulerSignaler;
import hunt.quartz.spi.ThreadExecutor;
import hunt.quartz.spi.TriggerFiredBundle;
import hunt.quartz.spi.TriggerFiredResult;
import hunt.quartz.utils.DBConnectionManager;

import hunt.lang.exception;
import hunt.logging;

import std.conv;


/**
 * <p>
 * Contains base functionality for JDBC-based JobStore implementations.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 * @author James House
 */
abstract class JobStoreSupport : JobStore, Constants {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    protected enum string LOCK_TRIGGER_ACCESS = "TRIGGER_ACCESS";

    protected enum string LOCK_STATE_ACCESS = "STATE_ACCESS";

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    protected string dsName;

    protected string tablePrefix = DEFAULT_TABLE_PREFIX;

    protected bool useProperties = false;

    protected string instanceId;

    protected string instanceName;
    
    protected string delegateClassName;

    protected string delegateInitString;
    
    protected Class<? extends DriverDelegate> delegateClass = StdJDBCDelegate.class;

    protected HashMap!(string, Calendar) calendarCache = new HashMap!(string, Calendar)();

    private DriverDelegate delegate;

    private long misfireThreshold = 60000L; // one minute

    private bool dontSetAutoCommitFalse = false;

    private bool isClustered = false;

    private bool useDBLocks = false;
    
    private bool lockOnInsert = true;

    private Semaphore lockHandler = null; // set in initialize() method...

    private string selectWithLockSQL = null;

    private long clusterCheckinInterval = 7500L;

    private ClusterManager clusterManagementThread = null;

    private MisfireHandler misfireHandler = null;

    private ClassLoadHelper classLoadHelper;

    private SchedulerSignaler schedSignaler;

    protected int maxToRecoverAtATime = 20;
    
    private bool setTxIsolationLevelSequential = false;
    
    private bool acquireTriggersWithinLock = false;
    
    private long dbRetryInterval = 15000L; // 15 secs
    
    private bool makeThreadsDaemons = false;

    private bool threadsInheritInitializersClassLoadContext = false;
    private ClassLoader initializersLoader = null;
    
    private bool doubleCheckLockMisfireHandler = true;
    
    
    private ThreadExecutor threadExecutor = new DefaultThreadExecutor();
    
    private bool schedulerRunning = false;
    private bool shutdown = false;
    
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
    void setDataSource(string dsName) {
        this.dsName = dsName;
    }

    /**
     * <p>
     * Get the name of the <code>DataSource</code> that should be used for
     * performing database functions.
     * </p>
     */
    string getDataSource() {
        return dsName;
    }

    /**
     * <p>
     * Set the prefix that should be pre-pended to all table names.
     * </p>
     */
    void setTablePrefix(string prefix) {
        if (prefix is null) {
            prefix = "";
        }

        this.tablePrefix = prefix;
    }

    /**
     * <p>
     * Get the prefix that should be pre-pended to all table names.
     * </p>
     */
    string getTablePrefix() {
        return tablePrefix;
    }

    /**
     * <p>
     * Set whether string-only properties will be handled in JobDataMaps.
     * </p>
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setUseProperties(string useProp) {
        if (useProp is null) {
            useProp = "false";
        }

        this.useProperties = Boolean.valueOf(useProp);
    }

    /**
     * <p>
     * Get whether string-only properties will be handled in JobDataMaps.
     * </p>
     */
    bool canUseProperties() {
        return useProperties;
    }

    /**
     * <p>
     * Set the instance Id of the Scheduler (must be unique within a cluster).
     * </p>
     */
    void setInstanceId(string instanceId) {
        this.instanceId = instanceId;
    }

    /**
     * <p>
     * Get the instance Id of the Scheduler (must be unique within a cluster).
     * </p>
     */
    string getInstanceId() {

        return instanceId;
    }

    /**
     * Set the instance name of the Scheduler (must be unique within this server instance).
     */
    void setInstanceName(string instanceName) {
        this.instanceName = instanceName;
    }

    void setThreadPoolSize(final int poolSize) {
        //
    }
    
    void setThreadExecutor(ThreadExecutor threadExecutor) {
        this.threadExecutor = threadExecutor;
    }
    
    ThreadExecutor getThreadExecutor() {
        return threadExecutor;
    }
    

    /**
     * Get the instance name of the Scheduler (must be unique within this server instance).
     */
    string getInstanceName() {

        return instanceName;
    }

    long getEstimatedTimeToReleaseAndAcquireTrigger() {
        return 70;
    }

    /**
     * <p>
     * Set whether this instance is part of a cluster.
     * </p>
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setIsClustered(bool isClustered) {
        this.isClustered = isClustered;
    }

    /**
     * <p>
     * Get whether this instance is part of a cluster.
     * </p>
     */
    bool isClustered() {
        return isClustered;
    }

    /**
     * <p>
     * Get the frequency (in milliseconds) at which this instance "checks-in"
     * with the other instances of the cluster. -- Affects the rate of
     * detecting failed instances.
     * </p>
     */
    long getClusterCheckinInterval() {
        return clusterCheckinInterval;
    }

    /**
     * <p>
     * Set the frequency (in milliseconds) at which this instance "checks-in"
     * with the other instances of the cluster. -- Affects the rate of
     * detecting failed instances.
     * </p>
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setClusterCheckinInterval(long l) {
        clusterCheckinInterval = l;
    }

    /**
     * <p>
     * Get the maximum number of misfired triggers that the misfire handling
     * thread will try to recover at one time (within one transaction).  The
     * default is 20.
     * </p>
     */
    int getMaxMisfiresToHandleAtATime() {
        return maxToRecoverAtATime;
    }

    /**
     * <p>
     * Set the maximum number of misfired triggers that the misfire handling
     * thread will try to recover at one time (within one transaction).  The
     * default is 20.
     * </p>
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setMaxMisfiresToHandleAtATime(int maxToRecoverAtATime) {
        this.maxToRecoverAtATime = maxToRecoverAtATime;
    }

    /**
     * @return Returns the dbRetryInterval.
     */
    long getDbRetryInterval() {
        return dbRetryInterval;
    }
    /**
     * @param dbRetryInterval The dbRetryInterval to set.
     */
    void setDbRetryInterval(long dbRetryInterval) {
        this.dbRetryInterval = dbRetryInterval;
    }
    
    /**
     * <p>
     * Set whether this instance should use database-based thread
     * synchronization.
     * </p>
     */
    void setUseDBLocks(bool useDBLocks) {
        this.useDBLocks = useDBLocks;
    }

    /**
     * <p>
     * Get whether this instance should use database-based thread
     * synchronization.
     * </p>
     */
    bool getUseDBLocks() {
        return useDBLocks;
    }

    bool isLockOnInsert() {
        return lockOnInsert;
    }
    
    /**
     * Whether or not to obtain locks when inserting new jobs/triggers.  
     * <p>
     * Defaults to <code>true</code>, which is safest. Some databases (such as 
     * MS SQLServer) seem to require this to avoid deadlocks under high load,
     * while others seem to do fine without.  Settings this to false means
     * isolation guarantees between job scheduling and trigger acquisition are
     * entirely enforced by the database.  Depending on the database and it's
     * configuration this may cause unusual scheduling behaviors.
     * 
     * <p>Setting this property to <code>false</code> will provide a 
     * significant performance increase during the addition of new jobs 
     * and triggers.</p>
     * 
     * @param lockOnInsert whether locking should be used when inserting new jobs/triggers
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setLockOnInsert(bool lockOnInsert) {
        this.lockOnInsert = lockOnInsert;
    }
    
    long getMisfireThreshold() {
        return misfireThreshold;
    }

    /**
     * The the number of milliseconds by which a trigger must have missed its
     * next-fire-time, in order for it to be considered "misfired" and thus
     * have its misfire instruction applied.
     * 
     * @param misfireThreshold the misfire threshold to use, in millis
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setMisfireThreshold(long misfireThreshold) {
        if (misfireThreshold < 1) {
            throw new IllegalArgumentException(
                    "Misfirethreshold must be larger than 0");
        }
        this.misfireThreshold = misfireThreshold;
    }

    bool isDontSetAutoCommitFalse() {
        return dontSetAutoCommitFalse;
    }

    /**
     * Don't call set autocommit(false) on connections obtained from the
     * DataSource. This can be helpful in a few situations, such as if you
     * have a driver that complains if it is called when it is already off.
     * 
     * @param b whether or not autocommit should be set to false on db connections
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setDontSetAutoCommitFalse(bool b) {
        dontSetAutoCommitFalse = b;
    }

    bool isTxIsolationLevelSerializable() {
        return setTxIsolationLevelSequential;
    }

    /**
     * Set the transaction isolation level of DB connections to sequential.
     * 
     * @param b whether isolation level should be set to sequential.
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setTxIsolationLevelSerializable(bool b) {
        setTxIsolationLevelSequential = b;
    }

    /**
     * Whether or not the query and update to acquire a Trigger for firing
     * should be performed after obtaining an explicit DB lock (to avoid 
     * possible race conditions on the trigger's db row).  This is the
     * behavior prior to Quartz 1.6.3, but is considered unnecessary for most
     * databases (due to the nature of the SQL update that is performed), 
     * and therefore a superfluous performance hit.     
     */
    bool isAcquireTriggersWithinLock() {
        return acquireTriggersWithinLock;
    }

    /**
     * Whether or not the query and update to acquire a Trigger for firing
     * should be performed after obtaining an explicit DB lock.  This is the
     * behavior prior to Quartz 1.6.3, but is considered unnecessary for most
     * databases, and therefore a superfluous performance hit.     
     * 
     * However, if batch acquisition is used, it is important for this behavior
     * to be used for all dbs.
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setAcquireTriggersWithinLock(bool acquireTriggersWithinLock) {
        this.acquireTriggersWithinLock = acquireTriggersWithinLock;
    }

    
    /**
     * <p>
     * Set the JDBC driver delegate class.
     * </p>
     * 
     * @param delegateClassName
     *          the delegate class name
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setDriverDelegateClass(string delegateClassName) {
        synchronized(this) {
            this.delegateClassName = delegateClassName;
        }
    }

    /**
     * <p>
     * Get the JDBC driver delegate class name.
     * </p>
     * 
     * @return the delegate class name
     */
    string getDriverDelegateClass() {
        return delegateClassName;
    }

    /**
     * <p>
     * Set the JDBC driver delegate's initialization string.
     * </p>
     * 
     * @param delegateInitString
     *          the delegate init string
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setDriverDelegateInitString(string delegateInitString) {
        this.delegateInitString = delegateInitString;
    }

    /**
     * <p>
     * Get the JDBC driver delegate's initialization string.
     * </p>
     * 
     * @return the delegate init string
     */
    string getDriverDelegateInitString() {
        return delegateInitString;
    }

    string getSelectWithLockSQL() {
        return selectWithLockSQL;
    }

    /**
     * <p>
     * set the SQL statement to use to select and lock a row in the "locks"
     * table.
     * </p>
     * 
     * @see StdRowLockSemaphore
     */
    void setSelectWithLockSQL(string string) {
        selectWithLockSQL = string;
    }

    protected ClassLoadHelper getClassLoadHelper() {
        return classLoadHelper;
    }

    /**
     * Get whether the threads spawned by this JobStore should be
     * marked as daemon.  Possible threads include the <code>MisfireHandler</code> 
     * and the <code>ClusterManager</code>.
     * 
     * @see Thread#setDaemon(bool)
     */
    bool getMakeThreadsDaemons() {
        return makeThreadsDaemons;
    }

    /**
     * Set whether the threads spawned by this JobStore should be
     * marked as daemon.  Possible threads include the <code>MisfireHandler</code> 
     * and the <code>ClusterManager</code>.
     *
     * @see Thread#setDaemon(bool)
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setMakeThreadsDaemons(bool makeThreadsDaemons) {
        this.makeThreadsDaemons = makeThreadsDaemons;
    }
    
    /**
     * Get whether to set the class load context of spawned threads to that
     * of the initializing thread.
     */
    bool isThreadsInheritInitializersClassLoadContext() {
        return threadsInheritInitializersClassLoadContext;
    }

    /**
     * Set whether to set the class load context of spawned threads to that
     * of the initializing thread.
     */
    void setThreadsInheritInitializersClassLoadContext(
            bool threadsInheritInitializersClassLoadContext) {
        this.threadsInheritInitializersClassLoadContext = threadsInheritInitializersClassLoadContext;
    }

    /**
     * Get whether to check to see if there are Triggers that have misfired
     * before actually acquiring the lock to recover them.  This should be 
     * set to false if the majority of the time, there are are misfired
     * Triggers.
     */
    bool getDoubleCheckLockMisfireHandler() {
        return doubleCheckLockMisfireHandler;
    }

    /**
     * Set whether to check to see if there are Triggers that have misfired
     * before actually acquiring the lock to recover them.  This should be 
     * set to false if the majority of the time, there are are misfired
     * Triggers.
     */
    @SuppressWarnings("UnusedDeclaration") /* called reflectively */
    void setDoubleCheckLockMisfireHandler(
            bool doubleCheckLockMisfireHandler) {
        this.doubleCheckLockMisfireHandler = doubleCheckLockMisfireHandler;
    }

    override
    long getAcquireRetryDelay(int failureCount) {
        return dbRetryInterval;
    }

    //---------------------------------------------------------------------------
    // interface methods
    //---------------------------------------------------------------------------


    /**
     * <p>
     * Called by the QuartzScheduler before the <code>JobStore</code> is
     * used, in order to give it a chance to initialize.
     * </p>
     */
    void initialize(ClassLoadHelper loadHelper,
            SchedulerSignaler signaler) {

        if (dsName is null) { 
            throw new SchedulerConfigException("DataSource name not set."); 
        }

        classLoadHelper = loadHelper;
        if(isThreadsInheritInitializersClassLoadContext()) {
            log.info("JDBCJobStore threads will inherit ContextClassLoader of thread: " ~ Thread.getThis().name());
            initializersLoader = Thread.getThis().getContextClassLoader();
        }
        
        this.schedSignaler = signaler;

        // If the user hasn't specified an explicit lock handler, then 
        // choose one based on CMT/Clustered/UseDBLocks.
        if (getLockHandler() is null) {
            
            // If the user hasn't specified an explicit lock handler, 
            // then we *must* use DB locks with clustering
            if (isClustered()) {
                setUseDBLocks(true);
            }
            
            if (getUseDBLocks()) {
                if(getDriverDelegateClass() !is null && getDriverDelegateClass()== MSSQLDelegate.class.getName()) {
                    if(getSelectWithLockSQL() is null) {
                        string msSqlDflt = "SELECT * FROM {0}LOCKS WITH (UPDLOCK,ROWLOCK) WHERE " ~ COL_SCHEDULER_NAME ~ " = {1} AND LOCK_NAME = ?";
                        info("Detected usage of MSSQLDelegate class - defaulting 'selectWithLockSQL' to '" ~ msSqlDflt ~ "'.");
                        setSelectWithLockSQL(msSqlDflt);
                    }
                }
                info("Using db table-based data access locking (synchronization).");
                setLockHandler(new StdRowLockSemaphore(getTablePrefix(), getInstanceName(), getSelectWithLockSQL()));
            } else {
                info(
                    "Using thread monitor-based data access locking (synchronization).");
                setLockHandler(new SimpleSemaphore());
            }
        }

    }
   
    /**
     * @see hunt.quartz.spi.JobStore#schedulerStarted()
     */
    void schedulerStarted() {

        if (isClustered()) {
            clusterManagementThread = new ClusterManager();
            if(initializersLoader !is null)
                clusterManagementThread.setContextClassLoader(initializersLoader);
            clusterManagementThread.initialize();
        } else {
            try {
                recoverJobs();
            } catch (SchedulerException se) {
                throw new SchedulerConfigException(
                        "Failure occured during job recovery.", se);
            }
        }

        misfireHandler = new MisfireHandler();
        if(initializersLoader !is null)
            misfireHandler.setContextClassLoader(initializersLoader);
        misfireHandler.initialize();
        schedulerRunning = true;
        
        trace("JobStore background threads started (as scheduler was started).");
    }
    
    void schedulerPaused() {
        schedulerRunning = false;
    }
    
    void schedulerResumed() {
        schedulerRunning = true;
    }
    
    /**
     * <p>
     * Called by the QuartzScheduler to inform the <code>JobStore</code> that
     * it should free up all of it's resources because the scheduler is
     * shutting down.
     * </p>
     */
    void shutdown() {
        shutdown = true;
        
        if (misfireHandler !is null) {
            misfireHandler.shutdown();
            try {
                misfireHandler.join();
            } catch (InterruptedException ignore) {
            }
        }

        if (clusterManagementThread !is null) {
            clusterManagementThread.shutdown();
            try {
                clusterManagementThread.join();
            } catch (InterruptedException ignore) {
            }
        }

        try {
            DBConnectionManager.getInstance().shutdown(getDataSource());
        } catch (SQLException sqle) {
            warning("Database connection shutdown unsuccessful.", sqle);
        }        
        
        trace("JobStore background threads shutdown.");
    }

    bool supportsPersistence() {
        return true;
    }

    //---------------------------------------------------------------------------
    // helper methods for subclasses
    //---------------------------------------------------------------------------

    protected abstract Connection getNonManagedTXConnection();

    /**
     * Wrap the given <code>Connection</code> in a Proxy such that attributes 
     * that might be set will be restored before the connection is closed 
     * (and potentially restored to a pool).
     */
    protected Connection getAttributeRestoringConnection(Connection conn) {
        return (Connection)Proxy.newProxyInstance(
                Thread.getThis().getContextClassLoader(),
                new Class[] { Connection.class },
                new AttributeRestoringConnectionInvocationHandler(conn));
    }
    
    protected Connection getConnection() {
        Connection conn;
        try {
            conn = DBConnectionManager.getInstance().getConnection(
                    getDataSource());
        } catch (SQLException sqle) {
            throw new JobPersistenceException(
                    "Failed to obtain DB connection from data source '"
                    + getDataSource() ~ "': " ~ sqle.toString(), sqle);
        } catch (Throwable e) {
            throw new JobPersistenceException(
                    "Failed to obtain DB connection from data source '"
                    + getDataSource() ~ "': " ~ e.toString(), e);
        }

        if (conn is null) { 
            throw new JobPersistenceException(
                "Could not get connection from DataSource '"
                + getDataSource() ~ "'"); 
        }

        // Protect connection attributes we might change.
        conn = getAttributeRestoringConnection(conn);

        // Set any connection connection attributes we are to override.
        try {
            if (!isDontSetAutoCommitFalse()) {
                conn.setAutoCommit(false);
            }

            if(isTxIsolationLevelSerializable()) {
                conn.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
            }
        } catch (SQLException sqle) {
            warning("Failed to override connection auto commit/transaction isolation.", sqle);
        } catch (Throwable e) {
            try { conn.close(); } catch(Throwable ignored) {}
            
            throw new JobPersistenceException(
                "Failure setting up connection.", e);
        }
    
        return conn;
    }

    protected void releaseLock(string lockName, bool doIt) {
        if (doIt) {
            try {
                getLockHandler().releaseLock(lockName);
            } catch (LockException le) {
                error("Error returning lock: " ~ le.getMessage(), le);
            }
        }
    }

    /**
     * Recover any failed or misfired jobs and clean up the data store as
     * appropriate.
     * 
     * @throws JobPersistenceException if jobs could not be recovered
     */
    protected void recoverJobs() {
        executeInNonManagedTXLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    recoverJobs(conn);
                }
            }, null);
    }
    
    /**
     * <p>
     * Will recover any failed or misfired jobs and clean up the data store as
     * appropriate.
     * </p>
     * 
     * @throws JobPersistenceException
     *           if jobs could not be recovered
     */
    protected void recoverJobs(Connection conn) {
        try {
            // update inconsistent job states
            int rows = getDelegate().updateTriggerStatesFromOtherStates(conn,
                    STATE_WAITING, STATE_ACQUIRED, STATE_BLOCKED);

            rows += getDelegate().updateTriggerStatesFromOtherStates(conn,
                        STATE_PAUSED, STATE_PAUSED_BLOCKED, STATE_PAUSED_BLOCKED);
            
            info(
                    "Freed " ~ rows
                            ~ " triggers from 'acquired' / 'blocked' state.");

            // clean up misfired jobs
            recoverMisfiredJobs(conn, true);
            
            // recover jobs marked for recovery that were not fully executed
            List!(OperableTrigger) recoveringJobTriggers = getDelegate()
                    .selectTriggersForRecoveringJobs(conn);
            info("Recovering " ~ recoveringJobTriggers.size().to!string()
                    ~ " jobs that were in-progress at the time of the last shut-down.");

            for (OperableTrigger recoveringJobTrigger: recoveringJobTriggers) {
                if (jobExists(conn, recoveringJobTrigger.getJobKey())) {
                    recoveringJobTrigger.computeFirstFireTime(null);
                    storeTrigger(conn, recoveringJobTrigger, null, false,
                            STATE_WAITING, false, true);
                }
            }
            info("Recovery complete.");

            // remove lingering 'complete' triggers...
            List!(TriggerKey) cts = getDelegate().selectTriggersInState(conn, STATE_COMPLETE);
            foreach(TriggerKey ct; cts) {
                removeTrigger(conn, ct);
            }
            info(
                "Removed " ~ cts.size() ~ " 'complete' triggers.");
            
            // clean up any fired trigger entries
            int n = getDelegate().deleteFiredTriggers(conn);
            info("Removed " ~ n ~ " stale fired job entries.");
        } catch (JobPersistenceException e) {
            throw e;
        } catch (Exception e) {
            throw new JobPersistenceException("Couldn't recover jobs: "
                    ~ e.msg, e);
        }
    }

    protected long getMisfireTime() {
        long misfireTime = DateTimeHelper.currentTimeMillis();
        if (getMisfireThreshold() > 0) {
            misfireTime -= getMisfireThreshold();
        }

        return (misfireTime > 0) ? misfireTime : 0;
    }

    /**
     * Helper class for returning the composite result of trying
     * to recover misfired jobs.
     */
    protected static class RecoverMisfiredJobsResult {
        static final RecoverMisfiredJobsResult NO_OP =
            new RecoverMisfiredJobsResult(false, 0, Long.MAX_VALUE);
        
        private bool _hasMoreMisfiredTriggers;
        private int _processedMisfiredTriggerCount;
        private long _earliestNewTime;
        
        RecoverMisfiredJobsResult(
            bool hasMoreMisfiredTriggers, int processedMisfiredTriggerCount, long earliestNewTime) {
            _hasMoreMisfiredTriggers = hasMoreMisfiredTriggers;
            _processedMisfiredTriggerCount = processedMisfiredTriggerCount;
            _earliestNewTime = earliestNewTime;
        }
        
        bool hasMoreMisfiredTriggers() {
            return _hasMoreMisfiredTriggers;
        }
        int getProcessedMisfiredTriggerCount() {
            return _processedMisfiredTriggerCount;
        } 
        long getEarliestNewTime() {
            return _earliestNewTime;
        } 
    }
    
    protected RecoverMisfiredJobsResult recoverMisfiredJobs(
        Connection conn, bool recovering) {

        // If recovering, we want to handle all of the misfired
        // triggers right away.
        int maxMisfiresToHandleAtATime = 
            (recovering) ? -1 : getMaxMisfiresToHandleAtATime();
        
        List!(TriggerKey) misfiredTriggers = new LinkedList!(TriggerKey)();
        long earliestNewTime = Long.MAX_VALUE;
        // We must still look for the MISFIRED state in case triggers were left 
        // in this state when upgrading to this version that does not support it. 
        bool hasMoreMisfiredTriggers =
            getDelegate().hasMisfiredTriggersInState(
                conn, STATE_WAITING, getMisfireTime(), 
                maxMisfiresToHandleAtATime, misfiredTriggers);

        if (hasMoreMisfiredTriggers) {
            info(
                "Handling the first " ~ misfiredTriggers.size() +
                " triggers that missed their scheduled fire-time.  " ~
                "More misfired triggers remain to be processed.");
        } else if (misfiredTriggers.size() > 0) { 
            info(
                "Handling " ~ misfiredTriggers.size() + 
                " trigger(s) that missed their scheduled fire-time.");
        } else {
            trace(
                "Found 0 triggers that missed their scheduled fire-time.");
            return RecoverMisfiredJobsResult.NO_OP; 
        }

        for (TriggerKey triggerKey: misfiredTriggers) {
            
            OperableTrigger trig = 
                retrieveTrigger(conn, triggerKey);

            if (trig is null) {
                continue;
            }

            doUpdateOfMisfiredTrigger(conn, trig, false, STATE_WAITING, recovering);

            if(trig.getNextFireTime() !is null && trig.getNextFireTime().getTime() < earliestNewTime)
                earliestNewTime = trig.getNextFireTime().getTime();
        }

        return new RecoverMisfiredJobsResult(
                hasMoreMisfiredTriggers, misfiredTriggers.size(), earliestNewTime);
    }

    protected bool updateMisfiredTrigger(Connection conn,
            TriggerKey triggerKey, string newStateIfNotComplete, bool forceState) {
        try {

            OperableTrigger trig = retrieveTrigger(conn, triggerKey);

            long misfireTime = DateTimeHelper.currentTimeMillis();
            if (getMisfireThreshold() > 0) {
                misfireTime -= getMisfireThreshold();
            }

            if (trig.getNextFireTime().getTime() > misfireTime) {
                return false;
            }

            doUpdateOfMisfiredTrigger(conn, trig, forceState, newStateIfNotComplete, false);

            return true;

        } catch (Exception e) {
            throw new JobPersistenceException(
                    "Couldn't update misfired trigger '" ~ triggerKey ~ "': " ~ e.getMessage(), e);
        }
    }

    private void doUpdateOfMisfiredTrigger(Connection conn, OperableTrigger trig, bool forceState, string newStateIfNotComplete, bool recovering) {
        Calendar cal = null;
        if (trig.getCalendarName() !is null) {
            cal = retrieveCalendar(conn, trig.getCalendarName());
        }

        schedSignaler.notifyTriggerListenersMisfired(trig);

        trig.updateAfterMisfire(cal);

        if (trig.getNextFireTime() is null) {
            storeTrigger(conn, trig,
                null, true, STATE_COMPLETE, forceState, recovering);
            schedSignaler.notifySchedulerListenersFinalized(trig);
        } else {
            storeTrigger(conn, trig, null, true, newStateIfNotComplete,
                    forceState, recovering);
        }
    }

    /**
     * <p>
     * Store the given <code>{@link hunt.quartz.JobDetail}</code> and <code>{@link hunt.quartz.Trigger}</code>.
     * </p>
     * 
     * @param newJob
     *          The <code>JobDetail</code> to be stored.
     * @param newTrigger
     *          The <code>Trigger</code> to be stored.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Job</code> with the same name/group already
     *           exists.
     */
    void storeJobAndTrigger(final JobDetail newJob,
            final OperableTrigger newTrigger) {
        executeInLock(
            (isLockOnInsert()) ? LOCK_TRIGGER_ACCESS : null,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    storeJob(conn, newJob, false);
                    storeTrigger(conn, newTrigger, newJob, false,
                            Constants.STATE_WAITING, false, false);
                }
            });
    }
    
    /**
     * <p>
     * Store the given <code>{@link hunt.quartz.JobDetail}</code>.
     * </p>
     * 
     * @param newJob
     *          The <code>JobDetail</code> to be stored.
     * @param replaceExisting
     *          If <code>true</code>, any <code>Job</code> existing in the
     *          <code>JobStore</code> with the same name & group should be
     *          over-written.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Job</code> with the same name/group already
     *           exists, and replaceExisting is set to false.
     */
    void storeJob(final JobDetail newJob,
        final bool replaceExisting) {
        executeInLock(
            (isLockOnInsert() || replaceExisting) ? LOCK_TRIGGER_ACCESS : null,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    storeJob(conn, newJob, replaceExisting);
                }
            });
    }
    
    /**
     * <p>
     * Insert or update a job.
     * </p>
     */
    protected void storeJob(Connection conn, 
            JobDetail newJob, bool replaceExisting) {

        bool existingJob = jobExists(conn, newJob.getKey());
        try {
            if (existingJob) {
                if (!replaceExisting) { 
                    throw new ObjectAlreadyExistsException(newJob); 
                }
                getDelegate().updateJobDetail(conn, newJob);
            } else {
                getDelegate().insertJobDetail(conn, newJob);
            }
        } catch (IOException e) {
            throw new JobPersistenceException("Couldn't store job: "
                    ~ e.msg, e);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't store job: "
                    ~ e.msg, e);
        }
    }

    /**
     * <p>
     * Check existence of a given job.
     * </p>
     */
    protected bool jobExists(Connection conn, JobKey jobKey) {
        try {
            return getDelegate().jobExists(conn, jobKey);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't determine job existence (" ~ jobKey ~ "): " ~ e.getMessage(), e);
        }
    }


    /**
     * <p>
     * Store the given <code>{@link hunt.quartz.Trigger}</code>.
     * </p>
     * 
     * @param newTrigger
     *          The <code>Trigger</code> to be stored.
     * @param replaceExisting
     *          If <code>true</code>, any <code>Trigger</code> existing in
     *          the <code>JobStore</code> with the same name & group should
     *          be over-written.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Trigger</code> with the same name/group already
     *           exists, and replaceExisting is set to false.
     */
    void storeTrigger(final OperableTrigger newTrigger,
        final bool replaceExisting) {
        executeInLock(
            (isLockOnInsert() || replaceExisting) ? LOCK_TRIGGER_ACCESS : null,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    storeTrigger(conn, newTrigger, null, replaceExisting,
                        STATE_WAITING, false, false);
                }
            });
    }
    
    /**
     * <p>
     * Insert or update a trigger.
     * </p>
     */
    @SuppressWarnings("ConstantConditions")
    protected void storeTrigger(Connection conn,
            OperableTrigger newTrigger, JobDetail job, bool replaceExisting, string state,
            bool forceState, bool recovering) {

        bool existingTrigger = triggerExists(conn, newTrigger.getKey());

        if ((existingTrigger) && (!replaceExisting)) { 
            throw new ObjectAlreadyExistsException(newTrigger); 
        }
        
        try {

            bool shouldBepaused;

            if (!forceState) {
                shouldBepaused = getDelegate().isTriggerGroupPaused(
                        conn, newTrigger.getKey().getGroup());

                if(!shouldBepaused) {
                    shouldBepaused = getDelegate().isTriggerGroupPaused(conn,
                            ALL_GROUPS_PAUSED);

                    if (shouldBepaused) {
                        getDelegate().insertPausedTriggerGroup(conn, newTrigger.getKey().getGroup());
                    }
                }

                if (shouldBepaused && (state== STATE_WAITING || state== STATE_ACQUIRED)) {
                    state = STATE_PAUSED;
                }
            }

            if(job is null) {
                job = retrieveJob(conn, newTrigger.getJobKey());
            }
            if (job is null) {
                throw new JobPersistenceException("The job ("
                        + newTrigger.getJobKey()
                        ~ ") referenced by the trigger does not exist.");
            }

            if (job.isConcurrentExectionDisallowed() && !recovering) { 
                state = checkBlockedState(conn, job.getKey(), state);
            }
            
            if (existingTrigger) {
                getDelegate().updateTrigger(conn, newTrigger, state, job);
            } else {
                getDelegate().insertTrigger(conn, newTrigger, state, job);
            }
        } catch (Exception e) {
            throw new JobPersistenceException("Couldn't store trigger '" ~ newTrigger.getKey() ~ "' for '" 
                    + newTrigger.getJobKey() ~ "' job:" ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Check existence of a given trigger.
     * </p>
     */
    protected bool triggerExists(Connection conn, TriggerKey key) {
        try {
            return getDelegate().triggerExists(conn, key);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't determine trigger existence (" ~ key ~ "): " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Remove (delete) the <code>{@link hunt.quartz.Job}</code> with the given
     * name, and any <code>{@link hunt.quartz.Trigger}</code> s that reference
     * it.
     * </p>
     * 
     * <p>
     * If removal of the <code>Job</code> results in an empty group, the
     * group should be removed from the <code>JobStore</code>'s list of
     * known group names.
     * </p>
     * 
     * @return <code>true</code> if a <code>Job</code> with the given name &
     *         group was found and removed from the store.
     */
    bool removeJob(final JobKey jobKey) {
        return (Boolean) executeInLock(
                LOCK_TRIGGER_ACCESS,
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return removeJob(conn, jobKey) ?
                                Boolean.TRUE : Boolean.FALSE;
                    }
                });
    }
    
    protected bool removeJob(Connection conn, final JobKey jobKey) {

        try {
            List!(TriggerKey) jobTriggers = getDelegate().selectTriggerKeysForJob(conn, jobKey);
            for (TriggerKey jobTrigger: jobTriggers) {
                deleteTriggerAndChildren(conn, jobTrigger);
            }

            return deleteJobAndChildren(conn, jobKey);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't remove job: "
                    ~ e.msg, e);
        }
    }

    bool removeJobs(final List!(JobKey) jobKeys) {

        return (Boolean) executeInLock(
                LOCK_TRIGGER_ACCESS,
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        bool allFound = true;

                        // FUTURE_TODO: make this more efficient with a true bulk operation...
                        for (JobKey jobKey : jobKeys)
                            allFound = removeJob(conn, jobKey) && allFound;

                        return allFound ? Boolean.TRUE : Boolean.FALSE;
                    }
                });
    }
        
    bool removeTriggers(final List!(TriggerKey) triggerKeys) {
        return (Boolean) executeInLock(
                LOCK_TRIGGER_ACCESS,
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        bool allFound = true;

                        // FUTURE_TODO: make this more efficient with a true bulk operation...
                        for (TriggerKey triggerKey : triggerKeys)
                            allFound = removeTrigger(conn, triggerKey) && allFound;

                        return allFound ? Boolean.TRUE : Boolean.FALSE;
                    }
                });
    }
        
    void storeJobsAndTriggers(
            final Map<JobDetail, Set<? extends Trigger>> triggersAndJobs, final bool replace) {

        executeInLock(
                (isLockOnInsert() || replace) ? LOCK_TRIGGER_ACCESS : null,
                new VoidTransactionCallback() {
                    void executeVoid(Connection conn) {
                        
                        // FUTURE_TODO: make this more efficient with a true bulk operation...
                        for(JobDetail job: triggersAndJobs.keySet()) {
                            storeJob(conn, job, replace);
                            for(Trigger trigger: triggersAndJobs.get(job)) {
                                storeTrigger(conn, (OperableTrigger) trigger, job, replace,
                                        Constants.STATE_WAITING, false, false);
                            }
                        }
                    }
                });
    }    
    
    /**
     * Delete a job and its listeners.
     * 
     * @see #removeJob(java.sql.Connection, hunt.quartz.JobKey)
     * @see #removeTrigger(Connection, TriggerKey)
     */
    private bool deleteJobAndChildren(Connection conn, JobKey key) {

        return (getDelegate().deleteJobDetail(conn, key) > 0);
    }
    
    /**
     * Delete a trigger, its listeners, and its Simple/Cron/BLOB sub-table entry.
     * 
     * @see #removeJob(java.sql.Connection, hunt.quartz.JobKey)
     * @see #removeTrigger(Connection, TriggerKey)
     * @see #replaceTrigger(Connection, TriggerKey, OperableTrigger)
     */
    private bool deleteTriggerAndChildren(Connection conn, TriggerKey key) {

        return (getDelegate().deleteTrigger(conn, key) > 0);
    }
    
    /**
     * <p>
     * Retrieve the <code>{@link hunt.quartz.JobDetail}</code> for the given
     * <code>{@link hunt.quartz.Job}</code>.
     * </p>
     * 
     * @return The desired <code>Job</code>, or null if there is no match.
     */
    JobDetail retrieveJob(final JobKey jobKey) {
        return (JobDetail)executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return retrieveJob(conn, jobKey);
                }
            });
    }
    
    protected JobDetail retrieveJob(Connection conn, JobKey key) {
        try {

            return getDelegate().selectJobDetail(conn, key,
                    getClassLoadHelper());
        } catch (ClassNotFoundException e) {
            throw new JobPersistenceException(
                    "Couldn't retrieve job because a required class was not found: "
                            ~ e.msg, e);
        } catch (IOException e) {
            throw new JobPersistenceException(
                    "Couldn't retrieve job because the BLOB couldn't be deserialized: "
                            ~ e.msg, e);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't retrieve job: "
                    ~ e.msg, e);
        }
    }

    /**
     * <p>
     * Remove (delete) the <code>{@link hunt.quartz.Trigger}</code> with the
     * given name.
     * </p>
     * 
     * <p>
     * If removal of the <code>Trigger</code> results in an empty group, the
     * group should be removed from the <code>JobStore</code>'s list of
     * known group names.
     * </p>
     * 
     * <p>
     * If removal of the <code>Trigger</code> results in an 'orphaned' <code>Job</code>
     * that is not 'durable', then the <code>Job</code> should be deleted
     * also.
     * </p>
     * 
     * @return <code>true</code> if a <code>Trigger</code> with the given
     *         name & group was found and removed from the store.
     */
    bool removeTrigger(final TriggerKey triggerKey) {
        return (Boolean) executeInLock(
                LOCK_TRIGGER_ACCESS,
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return removeTrigger(conn, triggerKey) ?
                                Boolean.TRUE : Boolean.FALSE;
                    }
                });
    }
    
    protected bool removeTrigger(Connection conn, TriggerKey key) {
        bool removedTrigger;
        try {
            // this must be called before we delete the trigger, obviously
            JobDetail job = getDelegate().selectJobForTrigger(conn,
                    getClassLoadHelper(), key, false);

            removedTrigger = 
                deleteTriggerAndChildren(conn, key);

            if (null != job && !job.isDurable()) {
                int numTriggers = getDelegate().selectNumTriggersForJob(conn,
                        job.getKey());
                if (numTriggers == 0) {
                    // Don't call removeJob() because we don't want to check for
                    // triggers again.
                    deleteJobAndChildren(conn, job.getKey());
                }
            }
        } catch (ClassNotFoundException e) {
            throw new JobPersistenceException("Couldn't remove trigger: "
                    ~ e.msg, e);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't remove trigger: "
                    ~ e.msg, e);
        }

        return removedTrigger;
    }

    /** 
     * @see hunt.quartz.spi.JobStore#replaceTrigger(TriggerKey, OperableTrigger)
     */
    bool replaceTrigger(final TriggerKey triggerKey, 
            final OperableTrigger newTrigger) {
        return (Boolean) executeInLock(
                LOCK_TRIGGER_ACCESS,
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return replaceTrigger(conn, triggerKey, newTrigger) ?
                                Boolean.TRUE : Boolean.FALSE;
                    }
                });
    }
    
    protected bool replaceTrigger(Connection conn, 
            TriggerKey key, OperableTrigger newTrigger) {
        try {
            // this must be called before we delete the trigger, obviously
            JobDetail job = getDelegate().selectJobForTrigger(conn,
                    getClassLoadHelper(), key);

            if (job is null) {
                return false;
            }
            
            if (!newTrigger.getJobKey()== job.getKey()) {
                throw new JobPersistenceException("New trigger is not related to the same job as the old trigger.");
            }
            
            bool removedTrigger = 
                deleteTriggerAndChildren(conn, key);
            
            storeTrigger(conn, newTrigger, job, false, STATE_WAITING, false, false);

            return removedTrigger;
        } catch (ClassNotFoundException e) {
            throw new JobPersistenceException("Couldn't remove trigger: "
                    ~ e.msg, e);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't remove trigger: "
                    ~ e.msg, e);
        }
    }

    /**
     * <p>
     * Retrieve the given <code>{@link hunt.quartz.Trigger}</code>.
     * </p>
     * 
     * @return The desired <code>Trigger</code>, or null if there is no
     *         match.
     */
    OperableTrigger retrieveTrigger(final TriggerKey triggerKey) {
        return (OperableTrigger)executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return retrieveTrigger(conn, triggerKey);
                }
            });
    }
    
    protected OperableTrigger retrieveTrigger(Connection conn, TriggerKey key) {
        try {

            return getDelegate().selectTrigger(conn, key);
        } catch (Exception e) {
            throw new JobPersistenceException("Couldn't retrieve trigger: "
                    ~ e.msg, e);
        }
    }

    /**
     * <p>
     * Get the current state of the identified <code>{@link Trigger}</code>.
     * </p>
     * 
     * @see TriggerState#NORMAL
     * @see TriggerState#PAUSED
     * @see TriggerState#COMPLETE
     * @see TriggerState#ERROR
     * @see TriggerState#NONE
     */
    TriggerState getTriggerState(final TriggerKey triggerKey) {
        return (TriggerState)executeWithoutLock( // no locks necessary for read...
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return getTriggerState(conn, triggerKey);
                    }
                });
    }
    
    TriggerState getTriggerState(Connection conn, TriggerKey key) {
        try {
            string ts = getDelegate().selectTriggerState(conn, key);

            if (ts is null) {
                return TriggerState.NONE;
            }

            if (ts== STATE_DELETED) {
                return TriggerState.NONE;
            }

            if (ts== STATE_COMPLETE) {
                return TriggerState.COMPLETE;
            }

            if (ts== STATE_PAUSED) {
                return TriggerState.PAUSED;
            }

            if (ts== STATE_PAUSED_BLOCKED) {
                return TriggerState.PAUSED;
            }

            if (ts== STATE_ERROR) {
                return TriggerState.ERROR;
            }

            if (ts== STATE_BLOCKED) {
                return TriggerState.BLOCKED;
            }

            return TriggerState.NORMAL;

        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't determine state of trigger (" ~ key ~ "): " ~ e.getMessage(), e);
        }
    }

    /**
     * Reset the current state of the identified <code>{@link Trigger}</code>
     * from {@link TriggerState#ERROR} to {@link TriggerState#NORMAL} or
     * {@link TriggerState#PAUSED} as appropriate.
     *
     * <p>Only affects triggers that are in ERROR state - if identified trigger is not
     * in that state then the result is a no-op.</p>
     *
     * <p>The result will be the trigger returning to the normal, waiting to
     * be fired state, unless the trigger's group has been paused, in which
     * case it will go into the PAUSED state.</p>
     */
    void resetTriggerFromErrorState(final TriggerKey triggerKey) {
        executeInLock(
                LOCK_TRIGGER_ACCESS,
                new VoidTransactionCallback() {
                    void executeVoid(Connection conn) {
                        resetTriggerFromErrorState(conn, triggerKey);
                    }
                });
    }

    void resetTriggerFromErrorState(Connection conn, final TriggerKey triggerKey) {

        try {
            string newState = STATE_WAITING;

            if(getDelegate().isTriggerGroupPaused(conn, triggerKey.getGroup())) {
                newState = STATE_PAUSED;
            }

            getDelegate().updateTriggerStateFromOtherState(conn, triggerKey, newState, STATE_ERROR);

            info("Trigger " ~ triggerKey ~ " reset from ERROR state to: " ~ newState);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't reset from error state of trigger (" ~ triggerKey ~ "): " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Store the given <code>{@link hunt.quartz.Calendar}</code>.
     * </p>
     * 
     * @param calName
     *          The name of the calendar.
     * @param calendar
     *          The <code>Calendar</code> to be stored.
     * @param replaceExisting
     *          If <code>true</code>, any <code>Calendar</code> existing
     *          in the <code>JobStore</code> with the same name & group
     *          should be over-written.
     * @throws ObjectAlreadyExistsException
     *           if a <code>Calendar</code> with the same name already
     *           exists, and replaceExisting is set to false.
     */
    void storeCalendar(final string calName,
        final Calendar calendar, final bool replaceExisting, final bool updateTriggers) {
        executeInLock(
            (isLockOnInsert() || updateTriggers) ? LOCK_TRIGGER_ACCESS : null,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    storeCalendar(conn, calName, calendar, replaceExisting, updateTriggers);
                }
            });
    }
    
    protected void storeCalendar(Connection conn, 
            string calName, Calendar calendar, bool replaceExisting, bool updateTriggers) {
        try {
            bool existingCal = calendarExists(conn, calName);
            if (existingCal && !replaceExisting) { 
                throw new ObjectAlreadyExistsException(
                    "Calendar with name '" ~ calName ~ "' already exists."); 
            }

            if (existingCal) {
                if (getDelegate().updateCalendar(conn, calName, calendar) < 1) { 
                    throw new JobPersistenceException(
                        "Couldn't store calendar.  Update failed."); 
                }
                
                if(updateTriggers) {
                    List!(OperableTrigger) trigs = getDelegate().selectTriggersForCalendar(conn, calName);
                    
                    foreach(OperableTrigger trigger; trigs) {
                        trigger.updateWithNewCalendar(calendar, getMisfireThreshold());
                        storeTrigger(conn, trigger, null, true, STATE_WAITING, false, false);
                    }
                }
            } else {
                if (getDelegate().insertCalendar(conn, calName, calendar) < 1) { 
                    throw new JobPersistenceException(
                        "Couldn't store calendar.  Insert failed."); 
                }
            }

            if (!isClustered) {
                calendarCache.put(calName, calendar); // lazy-cache
            }

        } catch (IOException e) {
            throw new JobPersistenceException(
                    "Couldn't store calendar because the BLOB couldn't be serialized: "
                            ~ e.msg, e);
        } catch (ClassNotFoundException e) {
            throw new JobPersistenceException("Couldn't store calendar: "
                    ~ e.msg, e);
        }catch (SQLException e) {
            throw new JobPersistenceException("Couldn't store calendar: "
                    ~ e.msg, e);
        }
    }
    
    protected bool calendarExists(Connection conn, string calName) {
        try {
            return getDelegate().calendarExists(conn, calName);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't determine calendar existence (" ~ calName ~ "): "
                            ~ e.msg, e);
        }
    }

    /**
     * <p>
     * Remove (delete) the <code>{@link hunt.quartz.Calendar}</code> with the
     * given name.
     * </p>
     * 
     * <p>
     * If removal of the <code>Calendar</code> would result in
     * <code>Trigger</code>s pointing to non-existent calendars, then a
     * <code>JobPersistenceException</code> will be thrown.</p>
     *       *
     * @param calName The name of the <code>Calendar</code> to be removed.
     * @return <code>true</code> if a <code>Calendar</code> with the given name
     * was found and removed from the store.
     */
    bool removeCalendar(final string calName) {
        return (Boolean) executeInLock(
                LOCK_TRIGGER_ACCESS,
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return removeCalendar(conn, calName) ?
                                Boolean.TRUE : Boolean.FALSE;
                    }
                });
    }
    
    protected bool removeCalendar(Connection conn, 
            string calName) {
        try {
            if (getDelegate().calendarIsReferenced(conn, calName)) { 
                throw new JobPersistenceException(
                    "Calender cannot be removed if it referenced by a trigger!"); 
            }

            if (!isClustered) {
                calendarCache.remove(calName);
            }

            return (getDelegate().deleteCalendar(conn, calName) > 0);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't remove calendar: "
                    ~ e.msg, e);
        }
    }

    /**
     * <p>
     * Retrieve the given <code>{@link hunt.quartz.Trigger}</code>.
     * </p>
     * 
     * @param calName
     *          The name of the <code>Calendar</code> to be retrieved.
     * @return The desired <code>Calendar</code>, or null if there is no
     *         match.
     */
    Calendar retrieveCalendar(final string calName) {
        return (Calendar)executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return retrieveCalendar(conn, calName);
                }
            });
    }
    
    protected Calendar retrieveCalendar(Connection conn,
            string calName) {
        // all calendars are persistent, but we can lazy-cache them during run
        // time as long as we aren't running clustered.
        Calendar cal = (isClustered) ? null : calendarCache.get(calName);
        if (cal !is null) {
            return cal;
        }

        try {
            cal = getDelegate().selectCalendar(conn, calName);
            if (!isClustered) {
                calendarCache.put(calName, cal); // lazy-cache...
            }
            return cal;
        } catch (ClassNotFoundException e) {
            throw new JobPersistenceException(
                    "Couldn't retrieve calendar because a required class was not found: "
                            ~ e.msg, e);
        } catch (IOException e) {
            throw new JobPersistenceException(
                    "Couldn't retrieve calendar because the BLOB couldn't be deserialized: "
                            ~ e.msg, e);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't retrieve calendar: "
                    ~ e.msg, e);
        }
    }

    /**
     * <p>
     * Get the number of <code>{@link hunt.quartz.Job}</code> s that are
     * stored in the <code>JobStore</code>.
     * </p>
     */
    int getNumberOfJobs() {
        return (Integer) executeWithoutLock( // no locks necessary for read...
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return getNumberOfJobs(conn);
                    }
                });
    }
    
    protected int getNumberOfJobs(Connection conn) {
        try {
            return getDelegate().selectNumJobs(conn);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't obtain number of jobs: " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Get the number of <code>{@link hunt.quartz.Trigger}</code> s that are
     * stored in the <code>JobsStore</code>.
     * </p>
     */
    int getNumberOfTriggers() {
        return (Integer) executeWithoutLock( // no locks necessary for read...
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return getNumberOfTriggers(conn);
                    }
                });
    }
    
    protected int getNumberOfTriggers(Connection conn) {
        try {
            return getDelegate().selectNumTriggers(conn);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't obtain number of triggers: " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Get the number of <code>{@link hunt.quartz.Calendar}</code> s that are
     * stored in the <code>JobsStore</code>.
     * </p>
     */
    int getNumberOfCalendars() {
        return (Integer) executeWithoutLock( // no locks necessary for read...
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return getNumberOfCalendars(conn);
                    }
                });
    }
    
    protected int getNumberOfCalendars(Connection conn) {
        try {
            return getDelegate().selectNumCalendars(conn);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't obtain number of calendars: " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Job}</code> s that
     * matcher the given groupMatcher.
     * </p>
     * 
     * <p>
     * If there are no jobs in the given group name, the result should be an empty Set
     * </p>
     */
    @SuppressWarnings("unchecked")
    Set!(JobKey) getJobKeys(final GroupMatcher!(JobKey) matcher) {
        return (Set!(JobKey))executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return getJobNames(conn, matcher);
                }
            });
    }
    
    protected Set!(JobKey) getJobNames(Connection conn,
            GroupMatcher!(JobKey) matcher) {
        Set!(JobKey) jobNames;

        try {
            jobNames = getDelegate().selectJobsInGroup(conn, matcher);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't obtain job names: "
                    ~ e.msg, e);
        }

        return jobNames;
    }
    
    
    /**
     * Determine whether a {@link Job} with the given identifier already 
     * exists within the scheduler.
     * 
     * @param jobKey the identifier to check for
     * @return true if a Job exists with the given identifier
     * @throws JobPersistenceException
     */
    bool checkExists(final JobKey jobKey) {
        return (Boolean)executeWithoutLock( // no locks necessary for read...
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return checkExists(conn, jobKey);
                    }
                });
    }
   
    protected bool checkExists(Connection conn, JobKey jobKey) {
        try {
            return getDelegate().jobExists(conn, jobKey);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't check for existence of job: "
                    ~ e.msg, e);
        }
    }
    
    /**
     * Determine whether a {@link Trigger} with the given identifier already 
     * exists within the scheduler.
     * 
     * @param triggerKey the identifier to check for
     * @return true if a Trigger exists with the given identifier
     * @throws JobPersistenceException
     */
    bool checkExists(final TriggerKey triggerKey) {
        return (Boolean)executeWithoutLock( // no locks necessary for read...
                new TransactionCallback() {
                    Object execute(Connection conn) {
                        return checkExists(conn, triggerKey);
                    }
                });
    }
    
    protected bool checkExists(Connection conn, TriggerKey triggerKey) {
        try {
            return getDelegate().triggerExists(conn, triggerKey);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't check for existence of job: "
                    ~ e.msg, e);
        }
    }

    /**
     * Clear (delete!) all scheduling data - all {@link Job}s, {@link Trigger}s
     * {@link Calendar}s.
     * 
     * @throws JobPersistenceException
     */
    void clearAllSchedulingData() {
        executeInLock(
                LOCK_TRIGGER_ACCESS,
                new VoidTransactionCallback() {
                    void executeVoid(Connection conn) {
                        clearAllSchedulingData(conn);
                    }
                });
    }
    
    protected void clearAllSchedulingData(Connection conn) {
        try {
            getDelegate().clearData(conn);
        } catch (SQLException e) {
            throw new JobPersistenceException("Error clearing scheduling data: " ~ e.getMessage(), e);
        }
    }
    
    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Trigger}</code> s
     * that match the given group Matcher.
     * </p>
     * 
     * <p>
     * If there are no triggers in the given group name, the result should be a
     * an empty Set (not <code>null</code>).
     * </p>
     */
    @SuppressWarnings("unchecked")
    Set!(TriggerKey) getTriggerKeys(final GroupMatcher!(TriggerKey) matcher) {
        return (Set!(TriggerKey))executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return getTriggerNames(conn, matcher);
                }
            });
    }
    
    protected Set!(TriggerKey) getTriggerNames(Connection conn,
            GroupMatcher!(TriggerKey) matcher) {

        Set!(TriggerKey) trigNames;

        try {
            trigNames = getDelegate().selectTriggersInGroup(conn, matcher);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't obtain trigger names: "
                    ~ e.msg, e);
        }

        return trigNames;
    }


    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Job}</code>
     * groups.
     * </p>
     * 
     * <p>
     * If there are no known group names, the result should be a zero-length
     * array (not <code>null</code>).
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(string) getJobGroupNames() {
        return (List!(string))executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return getJobGroupNames(conn);
                }
            });
    }
    
    protected List!(string) getJobGroupNames(Connection conn) {

        List!(string) groupNames;

        try {
            groupNames = getDelegate().selectJobGroups(conn);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't obtain job groups: "
                    ~ e.msg, e);
        }

        return groupNames;
    }

    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Trigger}</code>
     * groups.
     * </p>
     * 
     * <p>
     * If there are no known group names, the result should be a zero-length
     * array (not <code>null</code>).
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(string) getTriggerGroupNames() {
        return (List!(string))executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return getTriggerGroupNames(conn);
                }
            });        
    }
    
    protected List!(string) getTriggerGroupNames(Connection conn) {

        List!(string) groupNames;

        try {
            groupNames = getDelegate().selectTriggerGroups(conn);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't obtain trigger groups: " ~ e.getMessage(), e);
        }

        return groupNames;
    }

    /**
     * <p>
     * Get the names of all of the <code>{@link hunt.quartz.Calendar}</code> s
     * in the <code>JobStore</code>.
     * </p>
     * 
     * <p>
     * If there are no Calendars in the given group name, the result should be
     * a zero-length array (not <code>null</code>).
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(string) getCalendarNames() {
        return (List!(string))executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return getCalendarNames(conn);
                }
            });      
    }
    
    protected List!(string) getCalendarNames(Connection conn) {
        try {
            return getDelegate().selectCalendars(conn);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't obtain trigger groups: " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Get all of the Triggers that are associated to the given Job.
     * </p>
     * 
     * <p>
     * If there are no matches, a zero-length array should be returned.
     * </p>
     */
    @SuppressWarnings("unchecked")
    List!(OperableTrigger) getTriggersForJob(final JobKey jobKey) {
        return (List!(OperableTrigger))executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return getTriggersForJob(conn, jobKey);
                }
            });
    }
    
    protected List!(OperableTrigger) getTriggersForJob(Connection conn,
            JobKey key) {
        List!(OperableTrigger) list;

        try {
            list = getDelegate()
                    .selectTriggersForJob(conn, key);
        } catch (Exception e) {
            throw new JobPersistenceException(
                    "Couldn't obtain triggers for job: " ~ e.getMessage(), e);
        }

        return list;
    }

    /**
     * <p>
     * Pause the <code>{@link hunt.quartz.Trigger}</code> with the given name.
     * </p>
     * 
     * @see #resumeTrigger(TriggerKey)
     */
    void pauseTrigger(final TriggerKey triggerKey) {
        executeInLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    pauseTrigger(conn, triggerKey);
                }
            });
    }
    
    /**
     * <p>
     * Pause the <code>{@link hunt.quartz.Trigger}</code> with the given name.
     * </p>
     * 
     * @see #resumeTrigger(Connection, TriggerKey)
     */
    void pauseTrigger(Connection conn, 
            TriggerKey triggerKey) {

        try {
            string oldState = getDelegate().selectTriggerState(conn,
                    triggerKey);

            if (oldState== STATE_WAITING
                    || oldState== STATE_ACQUIRED) {

                getDelegate().updateTriggerState(conn, triggerKey,
                        STATE_PAUSED);
            } else if (oldState== STATE_BLOCKED) {
                getDelegate().updateTriggerState(conn, triggerKey,
                        STATE_PAUSED_BLOCKED);
            }
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't pause trigger '"
                    + triggerKey ~ "': " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Pause the <code>{@link hunt.quartz.Job}</code> with the given name - by
     * pausing all of its current <code>Trigger</code>s.
     * </p>
     * 
     * @see #resumeJob(JobKey)
     */
    void pauseJob(final JobKey jobKey) {
        executeInLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    List!(OperableTrigger) triggers = getTriggersForJob(conn, jobKey);
                    for (OperableTrigger trigger: triggers) {
                        pauseTrigger(conn, trigger.getKey());
                    }
                }
            });
    }
    
    /**
     * <p>
     * Pause all of the <code>{@link hunt.quartz.Job}s</code> matching the given
     * groupMatcher - by pausing all of their <code>Trigger</code>s.
     * </p>
     * 
     * @see #resumeJobs(hunt.quartz.impl.matchers.GroupMatcher)
     */
    @SuppressWarnings("unchecked")
    Set!(string) pauseJobs(final GroupMatcher!(JobKey) matcher) {
        return (Set!(string)) executeInLock(
            LOCK_TRIGGER_ACCESS,
            new TransactionCallback() {
                Set!(string) execute(final Connection conn) {
                    Set!(string) groupNames = new HashSet!(string)();
                    Set!(JobKey) jobNames = getJobNames(conn, matcher);

                    for (JobKey jobKey : jobNames) {
                        List!(OperableTrigger) triggers = getTriggersForJob(conn, jobKey);
                        for (OperableTrigger trigger : triggers) {
                            pauseTrigger(conn, trigger.getKey());
                        }
                        groupNames.add(jobKey.getGroup());
                    }

                    return groupNames;
                }
            }
            );
    }
    
    /**
     * Determines if a Trigger for the given job should be blocked.  
     * State can only transition to STATE_PAUSED_BLOCKED/BLOCKED from 
     * PAUSED/STATE_WAITING respectively.
     * 
     * @return STATE_PAUSED_BLOCKED, BLOCKED, or the currentState. 
     */
    protected string checkBlockedState(
            Connection conn, JobKey jobKey, string currentState) {

        // State can only transition to BLOCKED from PAUSED or WAITING.
        if ((!currentState== STATE_WAITING) &&
            (!currentState== STATE_PAUSED)) {
            return currentState;
        }
        
        try {
            List!(FiredTriggerRecord) lst = getDelegate().selectFiredTriggerRecordsByJob(conn,
                    jobKey.getName(), jobKey.getGroup());

            if (lst.size() > 0) {
                FiredTriggerRecord rec = lst.get(0);
                if (rec.isJobDisallowsConcurrentExecution()) { // OLD_TODO: worry about failed/recovering/job  states?
                    return (STATE_PAUSED== currentState) ? STATE_PAUSED_BLOCKED : STATE_BLOCKED;
                }
            }

            return currentState;
        } catch (SQLException e) {
            throw new JobPersistenceException(
                "Couldn't determine if trigger should be in a blocked state '"
                    + jobKey ~ "': "
                    ~ e.msg, e);
        }

    }

    /**
     * <p>
     * Resume (un-pause) the <code>{@link hunt.quartz.Trigger}</code> with the
     * given name.
     * </p>
     * 
     * <p>
     * If the <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     * 
     * @see #pauseTrigger(TriggerKey)
     */
    void resumeTrigger(final TriggerKey triggerKey) {
        executeInLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    resumeTrigger(conn, triggerKey);
                }
            });
    }
    
    /**
     * <p>
     * Resume (un-pause) the <code>{@link hunt.quartz.Trigger}</code> with the
     * given name.
     * </p>
     * 
     * <p>
     * If the <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     * 
     * @see #pauseTrigger(Connection, TriggerKey)
     */
    void resumeTrigger(Connection conn, 
            TriggerKey key) {
        try {

            TriggerStatus status = getDelegate().selectTriggerStatus(conn,
                    key);

            if (status is null || status.getNextFireTime() is null) {
                return;
            }

            bool blocked = false;
            if(STATE_PAUSED_BLOCKED== status.getStatus()) {
                blocked = true;
            }

            string newState = checkBlockedState(conn, status.getJobKey(), STATE_WAITING);

            bool misfired = false;

            if (schedulerRunning && status.getNextFireTime().before(new Date())) {
                misfired = updateMisfiredTrigger(conn, key,
                    newState, true);
            }

            if(!misfired) {
                if(blocked) {
                    getDelegate().updateTriggerStateFromOtherState(conn,
                            key, newState, STATE_PAUSED_BLOCKED);
                } else {
                    getDelegate().updateTriggerStateFromOtherState(conn,
                            key, newState, STATE_PAUSED);
                }
            } 

        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't resume trigger '"
                    + key ~ "': " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Resume (un-pause) the <code>{@link hunt.quartz.Job}</code> with the
     * given name.
     * </p>
     * 
     * <p>
     * If any of the <code>Job</code>'s!(code)Trigger</code> s missed one
     * or more fire-times, then the <code>Trigger</code>'s misfire
     * instruction will be applied.
     * </p>
     * 
     * @see #pauseJob(JobKey)
     */
    void resumeJob(final JobKey jobKey) {
        executeInLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    List!(OperableTrigger) triggers = getTriggersForJob(conn, jobKey);
                    for (OperableTrigger trigger: triggers) {
                        resumeTrigger(conn, trigger.getKey());
                    }
                }
            });
    }
    
    /**
     * <p>
     * Resume (un-pause) all of the <code>{@link hunt.quartz.Job}s</code> in
     * the given group.
     * </p>
     * 
     * <p>
     * If any of the <code>Job</code> s had <code>Trigger</code> s that
     * missed one or more fire-times, then the <code>Trigger</code>'s
     * misfire instruction will be applied.
     * </p>
     * 
     * @see #pauseJobs(hunt.quartz.impl.matchers.GroupMatcher)
     */
    @SuppressWarnings("unchecked")
    Set!(string) resumeJobs(final GroupMatcher!(JobKey) matcher) {
        return (Set!(string)) executeInLock(
            LOCK_TRIGGER_ACCESS,
            new TransactionCallback() {
                Set!(string) execute(Connection conn) {
                    Set!(JobKey) jobKeys = getJobNames(conn, matcher);
                    Set!(string) groupNames = new HashSet!(string)();

                    for (JobKey jobKey: jobKeys) {
                        List!(OperableTrigger) triggers = getTriggersForJob(conn, jobKey);
                        for (OperableTrigger trigger: triggers) {
                            resumeTrigger(conn, trigger.getKey());
                        }
                        groupNames.add(jobKey.getGroup());
                    }
                    return groupNames;
                }
            });
    }
    
    /**
     * <p>
     * Pause all of the <code>{@link hunt.quartz.Trigger}s</code> matching the
     * given groupMatcher.
     * </p>
     * 
     * @see #resumeTriggerGroup(java.sql.Connection, hunt.quartz.impl.matchers.GroupMatcher)
     */
    @SuppressWarnings("unchecked")
    Set!(string) pauseTriggers(final GroupMatcher!(TriggerKey) matcher) {
        return (Set!(string)) executeInLock(
            LOCK_TRIGGER_ACCESS,
            new TransactionCallback() {
                Set!(string) execute(Connection conn) {
                    return pauseTriggerGroup(conn, matcher);
                }
            });
    }
    
    /**
     * <p>
     * Pause all of the <code>{@link hunt.quartz.Trigger}s</code> matching the
     * given groupMatcher.
     * </p>
     * 
     * @see #resumeTriggerGroup(java.sql.Connection, hunt.quartz.impl.matchers.GroupMatcher)
     */
    Set!(string) pauseTriggerGroup(Connection conn,
            GroupMatcher!(TriggerKey) matcher) {

        try {

            getDelegate().updateTriggerGroupStateFromOtherStates(
                    conn, matcher, STATE_PAUSED, STATE_ACQUIRED,
                    STATE_WAITING, STATE_WAITING);

            getDelegate().updateTriggerGroupStateFromOtherState(
                    conn, matcher, STATE_PAUSED_BLOCKED, STATE_BLOCKED);

            List!(string) groups = getDelegate().selectTriggerGroups(conn, matcher);
            
            // make sure to account for an exact group match for a group that doesn't yet exist
            StringMatcher.StringOperatorName operator = matcher.getCompareWithOperator();
            if (operator== StringOperatorName.EQUALS && !groups.contains(matcher.getCompareToValue())) {
              groups.add(matcher.getCompareToValue());
            }

            for (string group : groups) {
                if (!getDelegate().isTriggerGroupPaused(conn, group)) {
                    getDelegate().insertPausedTriggerGroup(conn, group);
                }
            }

            return new HashSet!(string)(groups);

        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't pause trigger group '"
                    + matcher ~ "': " ~ e.getMessage(), e);
        }
    }

    @SuppressWarnings("unchecked")
    Set!(string) getPausedTriggerGroups() {
        return (Set!(string))executeWithoutLock( // no locks necessary for read...
            new TransactionCallback() {
                Object execute(Connection conn) {
                    return getPausedTriggerGroups(conn);
                }
            });
    }    
    
    /**
     * <p>
     * Pause all of the <code>{@link hunt.quartz.Trigger}s</code> in the
     * given group.
     * </p>
     * 
     * @see #resumeTriggers(hunt.quartz.impl.matchers.GroupMatcher)
     */
    Set!(string) getPausedTriggerGroups(Connection conn) {

        try {
            return getDelegate().selectPausedTriggerGroups(conn);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't determine paused trigger groups: " ~ e.getMessage(), e);
        }
    }
    
    /**
     * <p>
     * Resume (un-pause) all of the <code>{@link hunt.quartz.Trigger}s</code>
     * matching the given groupMatcher.
     * </p>
     * 
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     * 
     * @see #pauseTriggers(hunt.quartz.impl.matchers.GroupMatcher)
     */
    @SuppressWarnings("unchecked")
    Set!(string) resumeTriggers(final GroupMatcher!(TriggerKey) matcher) {
        return (Set!(string)) executeInLock(
            LOCK_TRIGGER_ACCESS,
            new TransactionCallback() {
                Set!(string) execute(Connection conn) {
                    return resumeTriggerGroup(conn, matcher);
                }
            });

    }
    
    /**
     * <p>
     * Resume (un-pause) all of the <code>{@link hunt.quartz.Trigger}s</code>
     * matching the given groupMatcher.
     * </p>
     * 
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     * 
     * @see #pauseTriggers(hunt.quartz.impl.matchers.GroupMatcher)
     */
    Set!(string) resumeTriggerGroup(Connection conn,
            GroupMatcher!(TriggerKey) matcher) {

        try {

            getDelegate().deletePausedTriggerGroup(conn, matcher);
            HashSet!(string) groups = new HashSet!(string)();

            Set!(TriggerKey) keys = getDelegate().selectTriggersInGroup(conn,
                    matcher);

            for (TriggerKey key: keys) {
                resumeTrigger(conn, key);
                groups.add(key.getGroup());
            }

            return groups;

            // FUTURE_TODO: find an efficient way to resume triggers (better than the
            // above)... logic below is broken because of
            // findTriggersToBeBlocked()
            /*
             * int res =
             * getDelegate().updateTriggerGroupStateFromOtherState(conn,
             * groupName, STATE_WAITING, PAUSED);
             * 
             * if(res > 0) {
             * 
             * long misfireTime = DateTimeHelper.currentTimeMillis();
             * if(getMisfireThreshold() > 0) misfireTime -=
             * getMisfireThreshold();
             * 
             * Key[] misfires =
             * getDelegate().selectMisfiredTriggersInGroupInState(conn,
             * groupName, STATE_WAITING, misfireTime);
             * 
             * List blockedTriggers = findTriggersToBeBlocked(conn,
             * groupName);
             * 
             * Iterator itr = blockedTriggers.iterator(); while(itr.hasNext()) {
             * Key key = (Key)itr.next();
             * getDelegate().updateTriggerState(conn, key.getName(),
             * key.getGroup(), BLOCKED); }
             * 
             * for(int i=0; i < misfires.length; i++) {               string
             * newState = STATE_WAITING;
             * if(blockedTriggers.contains(misfires[i])) newState =
             * BLOCKED; updateMisfiredTrigger(conn,
             * misfires[i].getName(), misfires[i].getGroup(), newState, true); } }
             */

        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't pause trigger group '"
                    + matcher ~ "': " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Pause all triggers - equivalent of calling <code>pauseTriggerGroup(group)</code>
     * on every group.
     * </p>
     * 
     * <p>
     * When <code>resumeAll()</code> is called (to un-pause), trigger misfire
     * instructions WILL be applied.
     * </p>
     * 
     * @see #resumeAll()
     * @see #pauseTriggerGroup(java.sql.Connection, hunt.quartz.impl.matchers.GroupMatcher)
     */
    void pauseAll() {
        executeInLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    pauseAll(conn);
                }
            });
    }
    
    /**
     * <p>
     * Pause all triggers - equivalent of calling <code>pauseTriggerGroup(group)</code>
     * on every group.
     * </p>
     * 
     * <p>
     * When <code>resumeAll()</code> is called (to un-pause), trigger misfire
     * instructions WILL be applied.
     * </p>
     * 
     * @see #resumeAll(Connection)
     * @see #pauseTriggerGroup(java.sql.Connection, hunt.quartz.impl.matchers.GroupMatcher)
     */
    void pauseAll(Connection conn) {

        List!(string) names = getTriggerGroupNames(conn);

        for (string name: names) {
            pauseTriggerGroup(conn, GroupMatcher.triggerGroupEquals(name));
        }

        try {
            if (!getDelegate().isTriggerGroupPaused(conn, ALL_GROUPS_PAUSED)) {
                getDelegate().insertPausedTriggerGroup(conn, ALL_GROUPS_PAUSED);
            }

        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't pause all trigger groups: " ~ e.getMessage(), e);
        }

    }

    /**
     * <p>
     * Resume (un-pause) all triggers - equivalent of calling <code>resumeTriggerGroup(group)</code>
     * on every group.
     * </p>
     * 
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     * 
     * @see #pauseAll()
     */
    void resumeAll() {
        executeInLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    resumeAll(conn);
                }
            });
    }
    
    /**
     * protected
     * <p>
     * Resume (un-pause) all triggers - equivalent of calling <code>resumeTriggerGroup(group)</code>
     * on every group.
     * </p>
     * 
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     * 
     * @see #pauseAll(Connection)
     */
    void resumeAll(Connection conn) {

        List!(string) names = getTriggerGroupNames(conn);

        for (string name: names) {
            resumeTriggerGroup(conn, GroupMatcher.triggerGroupEquals(name));
        }

        try {
            getDelegate().deletePausedTriggerGroup(conn, ALL_GROUPS_PAUSED);
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't resume all trigger groups: " ~ e.getMessage(), e);
        }
    }

    private static long ftrCtr = DateTimeHelper.currentTimeMillis();

    protected synchronized string getFiredTriggerRecordId() {
        return getInstanceId() + ftrCtr++;
    }

    /**
     * <p>
     * Get a handle to the next N triggers to be fired, and mark them as 'reserved'
     * by the calling scheduler.
     * </p>
     * 
     * @see #releaseAcquiredTrigger(OperableTrigger)
     */
    @SuppressWarnings("unchecked")
    List!(OperableTrigger) acquireNextTriggers(final long noLaterThan, final int maxCount, final long timeWindow) {
        
        string lockName;
        if(isAcquireTriggersWithinLock() || maxCount > 1) { 
            lockName = LOCK_TRIGGER_ACCESS;
        } else {
            lockName = null;
        }
        return executeInNonManagedTXLock(lockName, 
                new TransactionCallback!(List!(OperableTrigger))() {
                    List!(OperableTrigger) execute(Connection conn) {
                        return acquireNextTrigger(conn, noLaterThan, maxCount, timeWindow);
                    }
                },
                new TransactionValidator!(List!(OperableTrigger))() {
                    Boolean validate(Connection conn, List!(OperableTrigger) result) {
                        try {
                            List!(FiredTriggerRecord) acquired = getDelegate().selectInstancesFiredTriggerRecords(conn, getInstanceId());
                            Set!(string) fireInstanceIds = new HashSet!(string)();
                            for (FiredTriggerRecord ft : acquired) {
                                fireInstanceIds.add(ft.getFireInstanceId());
                            }
                            for (OperableTrigger tr : result) {
                                if (fireInstanceIds.contains(tr.getFireInstanceId())) {
                                    return true;
                                }
                            }
                            return false;
                        } catch (SQLException e) {
                            throw new JobPersistenceException("error validating trigger acquisition", e);
                        }
                    }
                });
    }
    
    // FUTURE_TODO: this really ought to return something like a FiredTriggerBundle,
    // so that the fireInstanceId doesn't have to be on the trigger...
    protected List!(OperableTrigger) acquireNextTrigger(Connection conn, long noLaterThan, int maxCount, long timeWindow) {
        if (timeWindow < 0) {
          throw new IllegalArgumentException();
        }
        
        List!(OperableTrigger) acquiredTriggers = new ArrayList!(OperableTrigger)();
        Set!(JobKey) acquiredJobKeysForNoConcurrentExec = new HashSet!(JobKey)();
        final int MAX_DO_LOOP_RETRY = 3;
        int currentLoopCount = 0;
        do {
            currentLoopCount ++;
            try {
                List!(TriggerKey) keys = getDelegate().selectTriggerToAcquire(conn, noLaterThan + timeWindow, getMisfireTime(), maxCount);
                
                // No trigger is ready to fire yet.
                if (keys is null || keys.size() == 0)
                    return acquiredTriggers;

                long batchEnd = noLaterThan;

                foreach(TriggerKey triggerKey; keys) {
                    // If our trigger is no longer available, try a new one.
                    OperableTrigger nextTrigger = retrieveTrigger(conn, triggerKey);
                    if(nextTrigger is null) {
                        continue; // next trigger
                    }
                    
                    // If trigger's job is set as @DisallowConcurrentExecution, and it has already been added to result, then
                    // put it back into the timeTriggers set and continue to search for next trigger.
                    JobKey jobKey = nextTrigger.getJobKey();
                    JobDetail job;
                    try {
                        job = retrieveJob(conn, jobKey);
                    } catch (JobPersistenceException jpe) {
                        try {
                            error("Error retrieving job, setting trigger state to ERROR.", jpe);
                            getDelegate().updateTriggerState(conn, triggerKey, STATE_ERROR);
                        } catch (SQLException sqle) {
                            error("Unable to set trigger state to ERROR.", sqle);
                        }
                        continue;
                    }
                    
                    if (job.isConcurrentExectionDisallowed()) {
                        if (acquiredJobKeysForNoConcurrentExec.contains(jobKey)) {
                            continue; // next trigger
                        } else {
                            acquiredJobKeysForNoConcurrentExec.add(jobKey);
                        }
                    }
                    
                    if (nextTrigger.getNextFireTime().getTime() > batchEnd) {
                      break;
                    }
                    // We now have a acquired trigger, let's add to return list.
                    // If our trigger was no longer in the expected state, try a new one.
                    int rowsUpdated = getDelegate().updateTriggerStateFromOtherState(conn, triggerKey, STATE_ACQUIRED, STATE_WAITING);
                    if (rowsUpdated <= 0) {
                        continue; // next trigger
                    }
                    nextTrigger.setFireInstanceId(getFiredTriggerRecordId());
                    getDelegate().insertFiredTrigger(conn, nextTrigger, STATE_ACQUIRED, null);

                    if(acquiredTriggers.isEmpty()) {
                        batchEnd = Math.max(nextTrigger.getNextFireTime().getTime(), DateTimeHelper.currentTimeMillis()) + timeWindow;
                    }
                    acquiredTriggers.add(nextTrigger);
                }

                // if we didn't end up with any trigger to fire from that first
                // batch, try again for another batch. We allow with a max retry count.
                if(acquiredTriggers.size() == 0 && currentLoopCount < MAX_DO_LOOP_RETRY) {
                    continue;
                }
                
                // We are done with the while loop.
                break;
            } catch (Exception e) {
                throw new JobPersistenceException(
                          "Couldn't acquire next trigger: " ~ e.getMessage(), e);
            }
        } while (true);
        
        // Return the acquired trigger list
        return acquiredTriggers;
    }
    
    /**
     * <p>
     * Inform the <code>JobStore</code> that the scheduler no longer plans to
     * fire the given <code>Trigger</code>, that it had previously acquired
     * (reserved).
     * </p>
     */
    void releaseAcquiredTrigger(final OperableTrigger trigger) {
        retryExecuteInNonManagedTXLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    releaseAcquiredTrigger(conn, trigger);
                }
            });
    }
    
    protected void releaseAcquiredTrigger(Connection conn,
            OperableTrigger trigger) {
        try {
            getDelegate().updateTriggerStateFromOtherState(conn,
                    trigger.getKey(), STATE_WAITING, STATE_ACQUIRED);
            getDelegate().deleteFiredTrigger(conn, trigger.getFireInstanceId());
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't release acquired trigger: " ~ e.getMessage(), e);
        }
    }

    /**
     * <p>
     * Inform the <code>JobStore</code> that the scheduler is now firing the
     * given <code>Trigger</code> (executing its associated <code>Job</code>),
     * that it had previously acquired (reserved).
     * </p>
     * 
     * @return null if the trigger or its job or calendar no longer exist, or
     *         if the trigger was not successfully put into the 'executing'
     *         state.
     */
    @SuppressWarnings("unchecked")
    List!(TriggerFiredResult) triggersFired(final List!(OperableTrigger) triggers) {
        return executeInNonManagedTXLock(LOCK_TRIGGER_ACCESS,
                new TransactionCallback!(List!(TriggerFiredResult))() {
                    List!(TriggerFiredResult) execute(Connection conn) {
                        List!(TriggerFiredResult) results = new ArrayList!(TriggerFiredResult)();

                        TriggerFiredResult result;
                        for (OperableTrigger trigger : triggers) {
                            try {
                              TriggerFiredBundle bundle = triggerFired(conn, trigger);
                              result = new TriggerFiredResult(bundle);
                            } catch (JobPersistenceException jpe) {
                                result = new TriggerFiredResult(jpe);
                            } catch(RuntimeException re) {
                                result = new TriggerFiredResult(re);
                            }
                            results.add(result);
                        }

                        return results;
                    }
                },
                new TransactionValidator!(List!(TriggerFiredResult))() {
                    override
                    Boolean validate(Connection conn, List!(TriggerFiredResult) result) {
                        try {
                            List!(FiredTriggerRecord) acquired = getDelegate().selectInstancesFiredTriggerRecords(conn, getInstanceId());
                            Set!(string) executingTriggers = new HashSet!(string)();
                            for (FiredTriggerRecord ft : acquired) {
                                if (STATE_EXECUTING== ft.getFireInstanceState()) {
                                    executingTriggers.add(ft.getFireInstanceId());
                                }
                            }
                            for (TriggerFiredResult tr : result) {
                                if (tr.getTriggerFiredBundle() !is null && executingTriggers.contains(tr.getTriggerFiredBundle().getTrigger().getFireInstanceId())) {
                                    return true;
                                }
                            }
                            return false;
                        } catch (SQLException e) {
                            throw new JobPersistenceException("error validating trigger acquisition", e);
                        }
                    }
                });
    }

    protected TriggerFiredBundle triggerFired(Connection conn,
            OperableTrigger trigger) {
        JobDetail job;
        Calendar cal = null;

        // Make sure trigger wasn't deleted, paused, or completed...
        try { // if trigger was deleted, state will be STATE_DELETED
            string state = getDelegate().selectTriggerState(conn,
                    trigger.getKey());
            if (!state== STATE_ACQUIRED) {
                return null;
            }
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't select trigger state: "
                    ~ e.msg, e);
        }

        try {
            job = retrieveJob(conn, trigger.getJobKey());
            if (job is null) { return null; }
        } catch (JobPersistenceException jpe) {
            try {
                error("Error retrieving job, setting trigger state to ERROR.", jpe);
                getDelegate().updateTriggerState(conn, trigger.getKey(),
                        STATE_ERROR);
            } catch (SQLException sqle) {
                error("Unable to set trigger state to ERROR.", sqle);
            }
            throw jpe;
        }

        if (trigger.getCalendarName() !is null) {
            cal = retrieveCalendar(conn, trigger.getCalendarName());
            if (cal is null) { return null; }
        }

        try {
            getDelegate().updateFiredTrigger(conn, trigger, STATE_EXECUTING, job);
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't insert fired trigger: "
                    ~ e.msg, e);
        }

        Date prevFireTime = trigger.getPreviousFireTime();

        // call triggered - to update the trigger's next-fire-time state...
        trigger.triggered(cal);

        string state = STATE_WAITING;
        bool force = true;
        
        if (job.isConcurrentExectionDisallowed()) {
            state = STATE_BLOCKED;
            force = false;
            try {
                getDelegate().updateTriggerStatesForJobFromOtherState(conn, job.getKey(),
                        STATE_BLOCKED, STATE_WAITING);
                getDelegate().updateTriggerStatesForJobFromOtherState(conn, job.getKey(),
                        STATE_BLOCKED, STATE_ACQUIRED);
                getDelegate().updateTriggerStatesForJobFromOtherState(conn, job.getKey(),
                        STATE_PAUSED_BLOCKED, STATE_PAUSED);
            } catch (SQLException e) {
                throw new JobPersistenceException(
                        "Couldn't update states of blocked triggers: "
                                ~ e.msg, e);
            }
        } 
            
        if (trigger.getNextFireTime() is null) {
            state = STATE_COMPLETE;
            force = true;
        }

        storeTrigger(conn, trigger, job, true, state, force, false);

        job.getJobDataMap().clearDirtyFlag();

        return new TriggerFiredBundle(job, trigger, cal, trigger.getKey().getGroup()
                == Scheduler.DEFAULT_RECOVERY_GROUP, new Date(), trigger
                .getPreviousFireTime(), prevFireTime, trigger.getNextFireTime());
    }

    /**
     * <p>
     * Inform the <code>JobStore</code> that the scheduler has completed the
     * firing of the given <code>Trigger</code> (and the execution its
     * associated <code>Job</code>), and that the <code>{@link hunt.quartz.JobDataMap}</code>
     * in the given <code>JobDetail</code> should be updated if the <code>Job</code>
     * is stateful.
     * </p>
     */
    void triggeredJobComplete(final OperableTrigger trigger,
            final JobDetail jobDetail, final CompletedExecutionInstruction triggerInstCode) {
        retryExecuteInNonManagedTXLock(
            LOCK_TRIGGER_ACCESS,
            new VoidTransactionCallback() {
                void executeVoid(Connection conn) {
                    triggeredJobComplete(conn, trigger, jobDetail,triggerInstCode);
                }
            });    
    }
    
    protected void triggeredJobComplete(Connection conn,
            OperableTrigger trigger, JobDetail jobDetail,
            CompletedExecutionInstruction triggerInstCode) {
        try {
            if (triggerInstCode == CompletedExecutionInstruction.DELETE_TRIGGER) {
                if(trigger.getNextFireTime() is null) { 
                    // double check for possible reschedule within job 
                    // execution, which would cancel the need to delete...
                    TriggerStatus stat = getDelegate().selectTriggerStatus(
                            conn, trigger.getKey());
                    if(stat !is null && stat.getNextFireTime() is null) {
                        removeTrigger(conn, trigger.getKey());
                    }
                } else{
                    removeTrigger(conn, trigger.getKey());
                    signalSchedulingChangeOnTxCompletion(0L);
                }
            } else if (triggerInstCode == CompletedExecutionInstruction.SET_TRIGGER_COMPLETE) {
                getDelegate().updateTriggerState(conn, trigger.getKey(),
                        STATE_COMPLETE);
                signalSchedulingChangeOnTxCompletion(0L);
            } else if (triggerInstCode == CompletedExecutionInstruction.SET_TRIGGER_ERROR) {
                info("Trigger " ~ trigger.getKey() ~ " set to ERROR state.");
                getDelegate().updateTriggerState(conn, trigger.getKey(),
                        STATE_ERROR);
                signalSchedulingChangeOnTxCompletion(0L);
            } else if (triggerInstCode == CompletedExecutionInstruction.SET_ALL_JOB_TRIGGERS_COMPLETE) {
                getDelegate().updateTriggerStatesForJob(conn,
                        trigger.getJobKey(), STATE_COMPLETE);
                signalSchedulingChangeOnTxCompletion(0L);
            } else if (triggerInstCode == CompletedExecutionInstruction.SET_ALL_JOB_TRIGGERS_ERROR) {
                info("All triggers of Job " ~ 
                        trigger.getKey() ~ " set to ERROR state.");
                getDelegate().updateTriggerStatesForJob(conn,
                        trigger.getJobKey(), STATE_ERROR);
                signalSchedulingChangeOnTxCompletion(0L);
            }

            if (jobDetail.isConcurrentExectionDisallowed()) {
                getDelegate().updateTriggerStatesForJobFromOtherState(conn,
                        jobDetail.getKey(), STATE_WAITING,
                        STATE_BLOCKED);

                getDelegate().updateTriggerStatesForJobFromOtherState(conn,
                        jobDetail.getKey(), STATE_PAUSED,
                        STATE_PAUSED_BLOCKED);

                signalSchedulingChangeOnTxCompletion(0L);
            }
            if (jobDetail.isPersistJobDataAfterExecution()) {
                try {
                    if (jobDetail.getJobDataMap().isDirty()) {
                        getDelegate().updateJobData(conn, jobDetail);
                    }
                } catch (IOException e) {
                    throw new JobPersistenceException(
                            "Couldn't serialize job data: " ~ e.getMessage(), e);
                } catch (SQLException e) {
                    throw new JobPersistenceException(
                            "Couldn't update job data: " ~ e.getMessage(), e);
                }
            }
        } catch (SQLException e) {
            throw new JobPersistenceException(
                    "Couldn't update trigger state(s): " ~ e.getMessage(), e);
        }

        try {
            getDelegate().deleteFiredTrigger(conn, trigger.getFireInstanceId());
        } catch (SQLException e) {
            throw new JobPersistenceException("Couldn't delete fired trigger: "
                    ~ e.msg, e);
        }
    }

    /**
     * <P>
     * Get the driver delegate for DB operations.
     * </p>
     */
    protected DriverDelegate getDelegate() {
        implementationMissing(false);
        return null;
        // synchronized(this) {
        //     if(null == delegate) {
        //         try {
        //             if(delegateClassName !is null) {
        //                 delegateClass = getClassLoadHelper().loadClass(delegateClassName, DriverDelegate.class);
        //             }

        //             delegate = delegateClass.newInstance();
                    
        //             delegate.initialize(tablePrefix, instanceName, instanceId, getClassLoadHelper(), canUseProperties(), getDriverDelegateInitString());
                    
        //         } catch (InstantiationException e) {
        //             throw new NoSuchDelegateException("Couldn't create delegate: "
        //                     ~ e.msg, e);
        //         } catch (IllegalAccessException e) {
        //             throw new NoSuchDelegateException("Couldn't create delegate: "
        //                     ~ e.msg, e);
        //         } catch (ClassNotFoundException e) {
        //             throw new NoSuchDelegateException("Couldn't load delegate class: "
        //                     ~ e.msg, e);
        //         }
        //     }
        //     return delegate;
        // }
    }

    protected Semaphore getLockHandler() {
        return lockHandler;
    }

    void setLockHandler(Semaphore lockHandler) {
        this.lockHandler = lockHandler;
    }

    //---------------------------------------------------------------------------
    // Management methods
    //---------------------------------------------------------------------------

    protected RecoverMisfiredJobsResult doRecoverMisfires() {
        bool transOwner = false;
        Connection conn = getNonManagedTXConnection();
        try {
            RecoverMisfiredJobsResult result = RecoverMisfiredJobsResult.NO_OP;
            
            // Before we make the potentially expensive call to acquire the 
            // trigger lock, peek ahead to see if it is likely we would find
            // misfired triggers requiring recovery.
            int misfireCount = (getDoubleCheckLockMisfireHandler()) ?
                getDelegate().countMisfiredTriggersInState(
                    conn, STATE_WAITING, getMisfireTime()) : 
                Integer.MAX_VALUE;
            
            if (misfireCount == 0) {
                trace(
                    "Found 0 triggers that missed their scheduled fire-time.");
            } else {
                transOwner = getLockHandler().obtainLock(conn, LOCK_TRIGGER_ACCESS);
                
                result = recoverMisfiredJobs(conn, false);
            }
            
            commitConnection(conn);
            return result;
        } catch (JobPersistenceException e) {
            rollbackConnection(conn);
            throw e;
        } catch (SQLException e) {
            rollbackConnection(conn);
            throw new JobPersistenceException("Database error recovering from misfires.", e);
        } catch (RuntimeException e) {
            rollbackConnection(conn);
            throw new JobPersistenceException("Unexpected runtime exception: "
                    ~ e.msg, e);
        } finally {
            try {
                releaseLock(LOCK_TRIGGER_ACCESS, transOwner);
            } finally {
                cleanupConnection(conn);
            }
        }
    }

    protected ThreadLocal!(Long) sigChangeForTxCompletion = new ThreadLocal!(Long)();
    protected void signalSchedulingChangeOnTxCompletion(long candidateNewNextFireTime) {
        Long sigTime = sigChangeForTxCompletion.get();
        if(sigTime is null && candidateNewNextFireTime >= 0L)
            sigChangeForTxCompletion.set(candidateNewNextFireTime);
        else {
            if(sigTime is null || candidateNewNextFireTime < sigTime)
                sigChangeForTxCompletion.set(candidateNewNextFireTime);
        }
    }
    
    protected Long clearAndGetSignalSchedulingChangeOnTxCompletion() {
        Long t = sigChangeForTxCompletion.get();
        sigChangeForTxCompletion.set(null);
        return t;
    }

    protected void signalSchedulingChangeImmediately(long candidateNewNextFireTime) {
        schedSignaler.signalSchedulingChange(candidateNewNextFireTime);
    }

    //---------------------------------------------------------------------------
    // Cluster management methods
    //---------------------------------------------------------------------------

    protected bool firstCheckIn = true;

    protected long lastCheckin = DateTimeHelper.currentTimeMillis();
    
    protected bool doCheckin() {
        bool transOwner = false;
        bool transStateOwner = false;
        bool recovered = false;

        Connection conn = getNonManagedTXConnection();
        try {
            // Other than the first time, always checkin first to make sure there is 
            // work to be done before we acquire the lock (since that is expensive, 
            // and is almost never necessary).  This must be done in a separate
            // transaction to prevent a deadlock under recovery conditions.
            List!(SchedulerStateRecord) failedRecords = null;
            if (!firstCheckIn) {
                failedRecords = clusterCheckIn(conn);
                commitConnection(conn);
            }
            
            if (firstCheckIn || (failedRecords.size() > 0)) {
                getLockHandler().obtainLock(conn, LOCK_STATE_ACCESS);
                transStateOwner = true;
    
                // Now that we own the lock, make sure we still have work to do. 
                // The first time through, we also need to make sure we update/create our state record
                failedRecords = (firstCheckIn) ? clusterCheckIn(conn) : findFailedInstances(conn);
    
                if (failedRecords.size() > 0) {
                    getLockHandler().obtainLock(conn, LOCK_TRIGGER_ACCESS);
                    //getLockHandler().obtainLock(conn, LOCK_JOB_ACCESS);
                    transOwner = true;
    
                    clusterRecover(conn, failedRecords);
                    recovered = true;
                }
            }
            
            commitConnection(conn);
        } catch (JobPersistenceException e) {
            rollbackConnection(conn);
            throw e;
        } finally {
            try {
                releaseLock(LOCK_TRIGGER_ACCESS, transOwner);
            } finally {
                try {
                    releaseLock(LOCK_STATE_ACCESS, transStateOwner);
                } finally {
                    cleanupConnection(conn);
                }
            }
        }

        firstCheckIn = false;

        return recovered;
    }

    /**
     * Get a list of all scheduler instances in the cluster that may have failed.
     * This includes this scheduler if it is checking in for the first time.
     */
    protected List!(SchedulerStateRecord) findFailedInstances(Connection conn) {
        try {
            List!(SchedulerStateRecord) failedInstances = new LinkedList!(SchedulerStateRecord)();
            bool foundThisScheduler = false;
            long timeNow = DateTimeHelper.currentTimeMillis();
            
            List!(SchedulerStateRecord) states = getDelegate().selectSchedulerStateRecords(conn, null);

            foreach(SchedulerStateRecord rec; states) {
        
                // find own record...
                if (rec.getSchedulerInstanceId()== getInstanceId()) {
                    foundThisScheduler = true;
                    if (firstCheckIn) {
                        failedInstances.add(rec);
                    }
                } else {
                    // find failed instances...
                    if (calcFailedIfAfter(rec) < timeNow) {
                        failedInstances.add(rec);
                    }
                }
            }
            
            // The first time through, also check for orphaned fired triggers.
            if (firstCheckIn) {
                failedInstances.addAll(findOrphanedFailedInstances(conn, states));
            }
            
            // If not the first time but we didn't find our own instance, then
            // Someone must have done recovery for us.
            if ((!foundThisScheduler) && (!firstCheckIn)) {
                // FUTURE_TODO: revisit when handle self-failed-out impl'ed (see FUTURE_TODO in clusterCheckIn() below)
                warning(
                    "This scheduler instance (" ~ getInstanceId() ~ ") is still " ~ 
                    "active but was recovered by another instance in the cluster.  " ~
                    "This may cause inconsistent behavior.");
            }
            
            return failedInstances;
        } catch (Exception e) {
            lastCheckin = DateTimeHelper.currentTimeMillis();
            throw new JobPersistenceException("Failure identifying failed instances when checking-in: "
                    ~ e.msg, e);
        }
    }
    
    /**
     * Create dummy <code>SchedulerStateRecord</code> objects for fired triggers
     * that have no scheduler state record.  Checkin timestamp and interval are
     * left as zero on these dummy <code>SchedulerStateRecord</code> objects.
     * 
     * @param schedulerStateRecords List of all current <code>SchedulerStateRecords</code>
     */
    private List!(SchedulerStateRecord) findOrphanedFailedInstances(
            Connection conn, 
            List!(SchedulerStateRecord) schedulerStateRecords) {
        List!(SchedulerStateRecord) orphanedInstances = new ArrayList!(SchedulerStateRecord)();
        
        Set!(string) allFiredTriggerInstanceNames = getDelegate().selectFiredTriggerInstanceNames(conn);
        if (!allFiredTriggerInstanceNames.isEmpty()) {
            for (SchedulerStateRecord rec: schedulerStateRecords) {
                
                allFiredTriggerInstanceNames.remove(rec.getSchedulerInstanceId());
            }
            
            for (string inst: allFiredTriggerInstanceNames) {
                
                SchedulerStateRecord orphanedInstance = new SchedulerStateRecord();
                orphanedInstance.setSchedulerInstanceId(inst);
                
                orphanedInstances.add(orphanedInstance);
                
                warning(
                    "Found orphaned fired triggers for instance: " ~ orphanedInstance.getSchedulerInstanceId());
            }
        }
        
        return orphanedInstances;
    }
    
    protected long calcFailedIfAfter(SchedulerStateRecord rec) {
        return rec.getCheckinTimestamp() +
            Math.max(rec.getCheckinInterval(), 
                    (DateTimeHelper.currentTimeMillis() - lastCheckin)) +
            7500L;
    }
    
    protected List!(SchedulerStateRecord) clusterCheckIn(Connection conn) {

        List!(SchedulerStateRecord) failedInstances = findFailedInstances(conn);
        
        try {
            // FUTURE_TODO: handle self-failed-out

            // check in...
            lastCheckin = DateTimeHelper.currentTimeMillis();
            if(getDelegate().updateSchedulerState(conn, getInstanceId(), lastCheckin) == 0) {
                getDelegate().insertSchedulerState(conn, getInstanceId(),
                        lastCheckin, getClusterCheckinInterval());
            }
            
        } catch (Exception e) {
            throw new JobPersistenceException("Failure updating scheduler state when checking-in: "
                    ~ e.msg, e);
        }

        return failedInstances;
    }

    @SuppressWarnings("ConstantConditions")
    protected void clusterRecover(Connection conn, List!(SchedulerStateRecord) failedInstances) {

        if (failedInstances.size() > 0) {

            long recoverIds = DateTimeHelper.currentTimeMillis();

            logWarnIfNonZero(failedInstances.size(),
                    "ClusterManager: detected " ~ failedInstances.size()
                            ~ " failed or restarted instances.");
            try {
                for (SchedulerStateRecord rec : failedInstances) {
                    info(
                            "ClusterManager: Scanning for instance \""
                                    + rec.getSchedulerInstanceId()
                                    ~ "\"'s failed in-progress jobs.");

                    List!(FiredTriggerRecord) firedTriggerRecs = getDelegate()
                            .selectInstancesFiredTriggerRecords(conn,
                                    rec.getSchedulerInstanceId());

                    int acquiredCount = 0;
                    int recoveredCount = 0;
                    int otherCount = 0;

                    Set!(TriggerKey) triggerKeys = new HashSet!(TriggerKey)();

                    for (FiredTriggerRecord ftRec : firedTriggerRecs) {

                        TriggerKey tKey = ftRec.getTriggerKey();
                        JobKey jKey = ftRec.getJobKey();

                        triggerKeys.add(tKey);

                        // release blocked triggers..
                        if (ftRec.getFireInstanceState()== STATE_BLOCKED) {
                            getDelegate()
                                    .updateTriggerStatesForJobFromOtherState(
                                            conn, jKey,
                                            STATE_WAITING, STATE_BLOCKED);
                        } else if (ftRec.getFireInstanceState()== STATE_PAUSED_BLOCKED) {
                            getDelegate()
                                    .updateTriggerStatesForJobFromOtherState(
                                            conn, jKey,
                                            STATE_PAUSED, STATE_PAUSED_BLOCKED);
                        }

                        // release acquired triggers..
                        if (ftRec.getFireInstanceState()== STATE_ACQUIRED) {
                            getDelegate().updateTriggerStateFromOtherState(
                                    conn, tKey, STATE_WAITING,
                                    STATE_ACQUIRED);
                            acquiredCount++;
                        } else if (ftRec.isJobRequestsRecovery()) {
                            // handle jobs marked for recovery that were not fully
                            // executed..
                            if (jobExists(conn, jKey)) {
                                @SuppressWarnings("deprecation")
                                SimpleTriggerImpl rcvryTrig = new SimpleTriggerImpl(
                                        "recover_"
                                                + rec.getSchedulerInstanceId()
                                                ~ "_"
                                                + string.valueOf(recoverIds++),
                                        Scheduler.DEFAULT_RECOVERY_GROUP,
                                        new Date(ftRec.getScheduleTimestamp()));
                                rcvryTrig.setJobName(jKey.getName());
                                rcvryTrig.setJobGroup(jKey.getGroup());
                                rcvryTrig.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY);
                                rcvryTrig.setPriority(ftRec.getPriority());
                                JobDataMap jd = getDelegate().selectTriggerJobDataMap(conn, tKey.getName(), tKey.getGroup());
                                jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_NAME, tKey.getName());
                                jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_GROUP, tKey.getGroup());
                                jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_FIRETIME_IN_MILLISECONDS, string.valueOf(ftRec.getFireTimestamp()));
                                jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_SCHEDULED_FIRETIME_IN_MILLISECONDS, string.valueOf(ftRec.getScheduleTimestamp()));
                                rcvryTrig.setJobDataMap(jd);

                                rcvryTrig.computeFirstFireTime(null);
                                storeTrigger(conn, rcvryTrig, null, false,
                                        STATE_WAITING, false, true);
                                recoveredCount++;
                            } else {
                                warning("ClusterManager: failed job '"
                                                        ~ jKey.toString()
                                                        ~ "' no longer exists, cannot schedule recovery.");
                                otherCount++;
                            }
                        } else {
                            otherCount++;
                        }

                        // free up stateful job's triggers
                        if (ftRec.isJobDisallowsConcurrentExecution()) {
                            getDelegate()
                                    .updateTriggerStatesForJobFromOtherState(
                                            conn, jKey,
                                            STATE_WAITING, STATE_BLOCKED);
                            getDelegate()
                                    .updateTriggerStatesForJobFromOtherState(
                                            conn, jKey,
                                            STATE_PAUSED, STATE_PAUSED_BLOCKED);
                        }
                    }

                    getDelegate().deleteFiredTriggers(conn,
                            rec.getSchedulerInstanceId());

                    // Check if any of the fired triggers we just deleted were the last fired trigger
                    // records of a COMPLETE trigger.
                    int completeCount = 0;
                    for (TriggerKey triggerKey : triggerKeys) {

                        if (getDelegate().selectTriggerState(conn, triggerKey).
                                equals(STATE_COMPLETE)) {
                            List!(FiredTriggerRecord) firedTriggers =
                                    getDelegate().selectFiredTriggerRecords(conn, triggerKey.getName(), triggerKey.getGroup());
                            if (firedTriggers.isEmpty()) {

                                if (removeTrigger(conn, triggerKey)) {
                                    completeCount++;
                                }
                            }
                        }
                    }

                    logWarnIfNonZero(acquiredCount,
                            "ClusterManager: ......Freed " ~ acquiredCount
                                    ~ " acquired trigger(s).");
                    logWarnIfNonZero(completeCount,
                            "ClusterManager: ......Deleted " ~ completeCount
                                    ~ " complete triggers(s).");
                    logWarnIfNonZero(recoveredCount,
                            "ClusterManager: ......Scheduled " ~ recoveredCount
                                    ~ " recoverable job(s) for recovery.");
                    logWarnIfNonZero(otherCount,
                            "ClusterManager: ......Cleaned-up " ~ otherCount
                                    ~ " other failed job(s).");

                    if (!rec.getSchedulerInstanceId()== getInstanceId()) {
                        getDelegate().deleteSchedulerState(conn,
                                rec.getSchedulerInstanceId());
                    }
                }
            } catch (Throwable e) {
                throw new JobPersistenceException("Failure recovering jobs: "
                        ~ e.msg, e);
            }
        }
    }

    protected void logWarnIfNonZero(int val, string warning) {
        if (val > 0) {
            info(warning);
        } else {
            trace(warning);
        }
    }

    /**
     * <p>
     * Cleanup the given database connection.  This means restoring
     * any modified auto commit or transaction isolation connection
     * attributes, and then closing the underlying connection.
     * </p>
     * 
     * <p>
     * This is separate from closeConnection() because the Spring 
     * integration relies on being able to overload closeConnection() and
     * expects the same connection back that it originally returned
     * from the datasource. 
     * </p>
     * 
     * @see #closeConnection(Connection)
     */
    protected void cleanupConnection(Connection conn) {
        if (conn !is null) {
            if (conn instanceof Proxy) {
                Proxy connProxy = (Proxy)conn;
                
                InvocationHandler invocationHandler = 
                    Proxy.getInvocationHandler(connProxy);
                if (invocationHandler instanceof AttributeRestoringConnectionInvocationHandler) {
                    AttributeRestoringConnectionInvocationHandler connHandler =
                        (AttributeRestoringConnectionInvocationHandler)invocationHandler;
                        
                    connHandler.restoreOriginalAtributes();
                    closeConnection(connHandler.getWrappedConnection());
                    return;
                }
            }
            
            // Wan't a Proxy, or was a Proxy, but wasn't ours.
            closeConnection(conn);
        }
    }
    
    
    /**
     * Closes the supplied <code>Connection</code>.
     * <p>
     * Ignores a <code>null Connection</code>.  
     * Any exception thrown trying to close the <code>Connection</code> is
     * logged and ignored.  
     * </p>
     * 
     * @param conn The <code>Connection</code> to close (Optional).
     */
    protected void closeConnection(Connection conn) {
        if (conn !is null) {
            try {
                conn.close();
            } catch (SQLException e) {
                error("Failed to close Connection", e);
            } catch (Throwable e) {
                error(
                    "Unexpected exception closing Connection." ~
                    "  This is often due to a Connection being returned after or during shutdown.", e);
            }
        }
    }

    /**
     * Rollback the supplied connection.
     * 
     * <p>  
     * Logs any SQLException it gets trying to rollback, but will not propogate
     * the exception lest it mask the exception that caused the caller to 
     * need to rollback in the first place.
     * </p>
     *
     * @param conn (Optional)
     */
    protected void rollbackConnection(Connection conn) {
        if (conn !is null) {
            try {
                conn.rollback();
            } catch (SQLException e) {
                error(
                    "Couldn't rollback jdbc connection. "+e.getMessage(), e);
            }
        }
    }
    
    /**
     * Commit the supplied connection
     *
     * @param conn (Optional)
     * @throws JobPersistenceException thrown if a SQLException occurs when the
     * connection is committed
     */
    protected void commitConnection(Connection conn) {

        if (conn !is null) {
            try {
                conn.commit();
            } catch (SQLException e) {
                throw new JobPersistenceException(
                    "Couldn't commit jdbc connection. "+e.getMessage(), e);
            }
        }
    }
    
    /**
     * Implement this interface to provide the code to execute within
     * the a transaction template.  If no return value is required, execute
     * should just return null.
     * 
     * @see JobStoreSupport#executeInNonManagedTXLock(string, TransactionCallback, TransactionValidator)
     * @see JobStoreSupport#executeInLock(string, TransactionCallback)
     * @see JobStoreSupport#executeWithoutLock(TransactionCallback)
     */
    protected interface TransactionCallback!(T) {
        T execute(Connection conn);
    }

    protected interface TransactionValidator!(T) {
        Boolean validate(Connection conn, T result);
    }
    
    /**
     * Implement this interface to provide the code to execute within
     * the a transaction template that has no return value.
     * 
     * @see JobStoreSupport#executeInNonManagedTXLock(string, TransactionCallback, TransactionValidator)
     */
    protected abstract class VoidTransactionCallback : TransactionCallback!(Void) {
        final Void execute(Connection conn) {
            executeVoid(conn);
            return null;
        }
        
        abstract void executeVoid(Connection conn);
    }

    /**
     * Execute the given callback in a transaction. Depending on the JobStore, 
     * the surrounding transaction may be assumed to be already present 
     * (managed).  
     * 
     * <p>
     * This method just forwards to executeInLock() with a null lockName.
     * </p>
     * 
     * @see #executeInLock(string, TransactionCallback)
     */
    <T> T executeWithoutLock(
        TransactionCallback!(T) txCallback) {
        return executeInLock(null, txCallback);
    }

    /**
     * Execute the given callback having acquired the given lock.
     * Depending on the JobStore, the surrounding transaction may be 
     * assumed to be already present (managed).
     * 
     * @param lockName The name of the lock to acquire, for example
     * "TRIGGER_ACCESS".  If null, then no lock is acquired, but the
     * lockCallback is still executed in a transaction. 
     */
    protected abstract <T> T executeInLock(
        string lockName, 
        TransactionCallback!(T) txCallback);
    
    protected <T> T retryExecuteInNonManagedTXLock(string lockName, TransactionCallback!(T) txCallback) {
        for (int retry = 1; !shutdown; retry++) {
            try {
                return executeInNonManagedTXLock(lockName, txCallback, null);
            } catch (JobPersistenceException jpe) {
                if(retry % 4 == 0) {
                    schedSignaler.notifySchedulerListenersError("An error occurred while " ~ txCallback, jpe);
                }" ~
            } catch (RuntimeException e) {
                error("retryExecuteInNonManagedTXLock: RuntimeException " ~ e.getMessage(), e);
            }" ~
            try {
                Thread.sleep(getDbRetryInterval()); // retry every N seconds (the db connection must be failed)
            } catch (InterruptedException e) {
                throw new IllegalStateException("Received interrupted exception", e);
            }
        }
        throw new IllegalStateException("JobStore is shutdown - aborting retry");
    }
    
    /**
     * Execute the given callback having optionally acquired the given lock.
     * This uses the non-managed transaction connection.
     * 
     * @param lockName The name of the lock to acquire, for example
     * "TRIGGER_ACCESS".  If null, then no lock is acquired, but the
     * lockCallback is still executed in a non-managed transaction. 
     */
    protected <T> T executeInNonManagedTXLock(
            string lockName, 
            TransactionCallback!(T) txCallback, final TransactionValidator!(T) txValidator) {
        bool transOwner = false;
        Connection conn = null;
        try {
            if (lockName !is null) {
                // If we aren't using db locks, then delay getting DB connection 
                // until after acquiring the lock since it isn't needed.
                if (getLockHandler().requiresConnection()) {
                    conn = getNonManagedTXConnection();
                }
                
                transOwner = getLockHandler().obtainLock(conn, lockName);
            }
            
            if (conn is null) {
                conn = getNonManagedTXConnection();
            }
            
            final T result = txCallback.execute(conn);
            try {
                commitConnection(conn);
            } catch (JobPersistenceException e) {
                rollbackConnection(conn);
                if (txValidator is null || !retryExecuteInNonManagedTXLock(lockName, new TransactionCallback!(Boolean)() {
                    override
                    Boolean execute(Connection conn) {
                        return txValidator.validate(conn, result);
                    }
                })) {
                    throw e;
                }
            }

            Long sigTime = clearAndGetSignalSchedulingChangeOnTxCompletion();
            if(sigTime !is null && sigTime >= 0) {
                signalSchedulingChangeImmediately(sigTime);
            }
            
            return result;
        } catch (JobPersistenceException e) {
            rollbackConnection(conn);
            throw e;
        } catch (RuntimeException e) {
            rollbackConnection(conn);
            throw new JobPersistenceException("Unexpected runtime exception: "
                    ~ e.msg, e);
        } finally {
            try {
                releaseLock(lockName, transOwner);
            } finally {
                cleanupConnection(conn);
            }
        }
    }
    
    /////////////////////////////////////////////////////////////////////////////
    //
    // ClusterManager Thread
    //
    /////////////////////////////////////////////////////////////////////////////

    class ClusterManager : Thread {

        private bool shutdown = false;

        private int numFails = 0;
        
        ClusterManager() {
            this.setPriority(Thread.NORM_PRIORITY + 2);
            this.setName("QuartzScheduler_" ~ instanceName ~ "-" ~ instanceId ~ "_ClusterManager");
            this.setDaemon(getMakeThreadsD" ~ons());" ~
        }

        void initialize() {
            this.manage();

            ThreadExecutor executor = getThreadExecutor();
            executor.execute(ClusterManager.this);
        }

        void shutdown() {
            shutdown = true;
            this.interrupt();
        }

        private bool manage() {
            bool res = false;
            try {

                res = doCheckin();

                numFails = 0;
                trace("ClusterManager: Check-in complete.");
            } catch (Exception e) {
                if(numFails % 4 == 0) {
                    error(
                        "ClusterManager: Error managing cluster: "
                                ~ e.msg, e);
                }
                numFails++;
            }
            return res;
        }

        override
        void run() {
            while (!shutdown) {

                if (!shutdown) {
                    long timeToSleep = getClusterCheckinInterval();
                    long transpiredTime = (DateTimeHelper.currentTimeMillis() - lastCheckin);
                    timeToSleep = timeToSleep - transpiredTime;
                    if (timeToSleep <= 0) {
                        timeToSleep = 100L;
                    }

                    if(numFails > 0) {
                        timeToSleep = Math.max(getDbRetryInterval(), timeToSleep);
                    }
                    
                    try {
                        Thread.sleep(timeToSleep);
                    } catch (Exception ignore) {
                    }
                }

                if (!shutdown && this.manage()) {
                    signalSchedulingChangeImmediately(0L);
                }

            }//while !shutdown
        }
    }

    /////////////////////////////////////////////////////////////////////////////
    //
    // MisfireHandler Thread
    //
    /////////////////////////////////////////////////////////////////////////////

    class MisfireHandler : Thread {

        private bool shutdown = false;

        private int numFails = 0;
        

        MisfireHandler() {
            this.setName("QuartzScheduler_" ~ instanceName ~ "-" ~ instanceId ~ "_MisfireHandler");
            this.setDaemon(getMakeThreadsD" ~ons());" ~
        }

        void initialize() {
            ThreadExecutor executor = getThreadExecutor();
            executor.execute(MisfireHandler.this);
        }

        void shutdown() {
            shutdown = true;
            this.interrupt();
        }

        private RecoverMisfiredJobsResult manage() {
            try {
                trace("MisfireHandler: scanning for misfires...");

                RecoverMisfiredJobsResult res = doRecoverMisfires();
                numFails = 0;
                return res;
            } catch (Exception e) {
                if(numFails % 4 == 0) {
                    error(
                        "MisfireHandler: Error handling misfires: "
                                ~ e.msg, e);
                }
                numFails++;
            }
            return RecoverMisfiredJobsResult.NO_OP;
        }

        override
        void run() {
            
            while (!shutdown) {

                long sTime = DateTimeHelper.currentTimeMillis();

                RecoverMisfiredJobsResult recoverMisfiredJobsResult = manage();

                if (recoverMisfiredJobsResult.getProcessedMisfiredTriggerCount() > 0) {
                    signalSchedulingChangeImmediately(recoverMisfiredJobsResult.getEarliestNewTime());
                }

                if (!shutdown) {
                    long timeToSleep = 50l;  // At least a short pause to help balance threads
                    if (!recoverMisfiredJobsResult.hasMoreMisfiredTriggers()) {
                        timeToSleep = getMisfireThreshold() - (DateTimeHelper.currentTimeMillis() - sTime);
                        if (timeToSleep <= 0) {
                            timeToSleep = 50l;
                        }

                        if(numFails > 0) {
                            timeToSleep = Math.max(getDbRetryInterval(), timeToSleep);
                        }
                    }
                    
                    try {
                        Thread.sleep(timeToSleep);
                    } catch (Exception ignore) {
                    }
                }//while !shutdown
            }
        }
    }
}

// EOF
