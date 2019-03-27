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

module hunt.quartz.dbstore.StdDbDelegate;

import hunt.quartz.dbstore.DriverDelegate;

// import static hunt.quartz.JobKey.jobKey;
// import static hunt.quartz.TriggerBuilder.newTrigger;
// import static hunt.quartz.TriggerKey.triggerKey;

// import java.io.ByteArrayInputStream;
// import java.io.ByteArrayOutputStream;
// import java.io.IOException;
// import hunt.io.common;
// import java.io.NotSerializableException;
// import java.io.ObjectInputStream;
// import java.io.ObjectOutputStream;
// import java.math.BigDecimal;
// import java.sql.Blob;
// import java.sql.Connection;
// import java.sql.PreparedStatement;
// import java.sql.ResultSet;
// import java.sql.SQLException;
// import java.sql.Statement;
// import std.datetime;

import hunt.collection.HashMap;
import hunt.collection.HashSet;
import hunt.collection.Iterator;
import hunt.collection.LinkedList;
import hunt.collection.List;
import hunt.collection.Map;
import hunt.collection.Set;

import hunt.quartz.dbstore.TableConstants;
import hunt.quartz.Calendar;
import hunt.quartz.exception;
import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobKey;
import hunt.quartz.Scheduler;
import hunt.quartz.SimpleTrigger;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerBuilder;
import hunt.quartz.TriggerKey;
import hunt.quartz.impl.JobDetailImpl;
// import hunt.quartz.impl.jdbcjobstore.TriggerPersistenceDelegate.TriggerPropertyBundle;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.impl.matchers.StringMatcher;
import hunt.quartz.impl.triggers.SimpleTriggerImpl;
// import hunt.quartz.spi.ClassLoadHelper;
import hunt.quartz.spi.OperableTrigger;
import hunt.logging;

/**
 * <p>
 * This is meant to be an abstract base class for most, if not all, <code>{@link hunt.quartz.impl.jdbcjobstore.DriverDelegate}</code>
 * implementations. Subclasses should override only those methods that need
 * special handling for the DBMS driver in question.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 * @author James House
 * @author Eric Mueller
 */
class StdDbDelegate : DriverDelegate {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    protected string tablePrefix = TableConstants.DEFAULT_TABLE_PREFIX;

    protected string instanceId;

    protected string schedName;

    protected bool useProperties;
    
    // protected ClassLoadHelper classLoadHelper;

    // protected List!(TriggerPersistenceDelegate) triggerPersistenceDelegates;

    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create new StdJDBCDelegate instance.
     * </p>
     */
    this() {
        // triggerPersistenceDelegates = new LinkedList!(TriggerPersistenceDelegate)();
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */
    
    /**
     * @param initString of the format: settingName=settingValue|otherSettingName=otherSettingValue|...
     * @throws NoSuchDelegateException 
     */
    void initialize(Logger logger, string tablePrefix, string schedName, string instanceId, 
        bool useProperties, string initString) { // ClassLoadHelper classLoadHelper,

        this.logger = logger;
        this.tablePrefix = tablePrefix;
        this.schedName = schedName;
        this.instanceId = instanceId;
        this.useProperties = useProperties;
        // this.classLoadHelper = classLoadHelper;
        addDefaultTriggerPersistenceDelegates();

        if(initString is null)
            return;

        string[] settings = initString.split("\\|");
        
        foreach(string setting; settings) {
            string[] parts = setting.split("=");
            string name = parts[0];
            if(parts.length == 1 || parts[1] is null || parts[1].equals(""))
                continue;

            if(name.equals("triggerPersistenceDelegateClasses")) {
                
                string[] trigDelegates = parts[1].split(",");
                
                foreach(string trigDelClassName; trigDelegates) {
                    try {
                        Class<?> trigDelClass = classLoadHelper.loadClass(trigDelClassName);
                        addTriggerPersistenceDelegate((TriggerPersistenceDelegate) trigDelClass.newInstance());
                    } catch (Exception e) {
                        throw new NoSuchDelegateException("Error instantiating TriggerPersistenceDelegate of type: " ~ trigDelClassName, e);
                    } 
                }
            }
            else
                throw new NoSuchDelegateException("Unknown setting: '" ~ name ~ "'");
        }
    }

    protected void addDefaultTriggerPersistenceDelegates() {
        addTriggerPersistenceDelegate(new SimpleTriggerPersistenceDelegate());
        addTriggerPersistenceDelegate(new CronTriggerPersistenceDelegate());
        addTriggerPersistenceDelegate(new CalendarIntervalTriggerPersistenceDelegate());
        addTriggerPersistenceDelegate(new DailyTimeIntervalTriggerPersistenceDelegate());
    }

    protected bool canUseProperties() {
        return useProperties;
    }
    
    void addTriggerPersistenceDelegate(TriggerPersistenceDelegate delegate) {
        logger.debug("Adding TriggerPersistenceDelegate of type: " ~ delegate.getClass().getCanonicalName());
        delegate.initialize(tablePrefix, schedName);
        this.triggerPersistenceDelegates.add(delegate);
    }
    
    TriggerPersistenceDelegate findTriggerPersistenceDelegate(OperableTrigger trigger)  {
        foreach(TriggerPersistenceDelegate delegate; triggerPersistenceDelegates) {
            if(delegate.canHandleTriggerType(trigger))
                return delegate;
        }
        
        return null;
    }

    TriggerPersistenceDelegate findTriggerPersistenceDelegate(string discriminator)  {
        foreach(TriggerPersistenceDelegate delegate; triggerPersistenceDelegates) {
            if(delegate.getHandledTriggerTypeDiscriminator()== discriminator)
                return delegate;
        }
        
        return null;
    }

    //---------------------------------------------------------------------------
    // startup / recovery
    //---------------------------------------------------------------------------

    /**
     * <p>
     * Insert the job detail record.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param newState
     *          the new state for the triggers
     * @param oldState1
     *          the first old state to update
     * @param oldState2
     *          the second old state to update
     * @return number of rows updated
     */
    int updateTriggerStatesFromOtherStates(Connection conn,
            string newState, string oldState1, string oldState2) {
        PreparedStatement ps = null;

        try {
            ps = conn
                    .prepareStatement(rtp(UPDATE_TRIGGER_STATES_FROM_OTHER_STATES));
            ps.setString(1, newState);
            ps.setString(2, oldState1);
            ps.setString(3, oldState2);
            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Get the names of all of the triggers that have misfired.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>{@link
     * hunt.quartz.utils.Key}</code> objects
     */
    List!(TriggerKey) selectMisfiredTriggers(Connection conn, long ts) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_MISFIRED_TRIGGERS));
            ps.setBigDecimal(1, new BigDecimal(string.valueOf(ts)));
            rs = ps.executeQuery();

            LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
            while (rs.next()) {
                string triggerName = rs.getString(COL_TRIGGER_NAME);
                string groupName = rs.getString(COL_TRIGGER_GROUP);
                list.add(triggerKey(triggerName, groupName));
            }
            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select all of the triggers in a given state.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param state
     *          the state the triggers must be in
     * @return an array of trigger <code>Key</code> s
     */
    List!(TriggerKey) selectTriggersInState(Connection conn, string state) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGERS_IN_STATE));
            ps.setString(1, state);
            rs = ps.executeQuery();

            LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
            while (rs.next()) {
                list.add(triggerKey(rs.getString(1), rs.getString(2)));
            }

            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    List!(TriggerKey) selectMisfiredTriggersInState(Connection conn, string state,
            long ts) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_MISFIRED_TRIGGERS_IN_STATE));
            ps.setBigDecimal(1, new BigDecimal(string.valueOf(ts)));
            ps.setString(2, state);
            rs = ps.executeQuery();

            LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
            while (rs.next()) {
                string triggerName = rs.getString(COL_TRIGGER_NAME);
                string groupName = rs.getString(COL_TRIGGER_GROUP);
                list.add(triggerKey(triggerName, groupName));
            }
            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Get the names of all of the triggers in the given state that have
     * misfired - according to the given timestamp.  No more than count will
     * be returned.
     * </p>
     * 
     * @param conn The DB Connection
     * @param count The most misfired triggers to return, negative for all
     * @param resultList Output parameter.  A List of 
     *      <code>{@link hunt.quartz.utils.Key}</code> objects.  Must not be null.
     *          
     * @return Whether there are more misfired triggers left to find beyond
     *         the given count.
     */
    bool hasMisfiredTriggersInState(Connection conn, string state1, 
        long ts, int count, List!(TriggerKey) resultList) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_HAS_MISFIRED_TRIGGERS_IN_STATE));
            ps.setBigDecimal(1, new BigDecimal(string.valueOf(ts)));
            ps.setString(2, state1);
            rs = ps.executeQuery();

            bool hasReachedLimit = false;
            while (rs.next() && (hasReachedLimit == false)) {
                if (resultList.size() == count) {
                    hasReachedLimit = true;
                } else {
                    string triggerName = rs.getString(COL_TRIGGER_NAME);
                    string groupName = rs.getString(COL_TRIGGER_GROUP);
                    resultList.add(triggerKey(triggerName, groupName));
                }
            }
            
            return hasReachedLimit;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }
    
    /**
     * <p>
     * Get the number of triggers in the given states that have
     * misfired - according to the given timestamp.
     * </p>
     * 
     * @param conn the DB Connection
     */
    int countMisfiredTriggersInState(
            Connection conn, string state1, long ts) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(COUNT_MISFIRED_TRIGGERS_IN_STATE));
            ps.setBigDecimal(1, new BigDecimal(string.valueOf(ts)));
            ps.setString(2, state1);
            rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt(1);
            }

            throw new SQLException("No misfired trigger count returned.");
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Get the names of all of the triggers in the given group and state that
     * have misfired.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>{@link
     * hunt.quartz.utils.Key}</code> objects
     */
    List!(TriggerKey) selectMisfiredTriggersInGroupInState(Connection conn,
            string groupName, string state, long ts) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn
                    .prepareStatement(rtp(SELECT_MISFIRED_TRIGGERS_IN_GROUP_IN_STATE));
            ps.setBigDecimal(1, new BigDecimal(string.valueOf(ts)));
            ps.setString(2, groupName);
            ps.setString(3, state);
            rs = ps.executeQuery();

            LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
            while (rs.next()) {
                string triggerName = rs.getString(COL_TRIGGER_NAME);
                list.add(triggerKey(triggerName, groupName));
            }
            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select all of the triggers for jobs that are requesting recovery. The
     * returned trigger objects will have unique "recoverXXX" trigger names and
     * will be in the <code>{@link
     * hunt.quartz.Scheduler}.DEFAULT_RECOVERY_GROUP</code>
     * trigger group.
     * </p>
     * 
     * <p>
     * In order to preserve the ordering of the triggers, the fire time will be
     * set from the <code>COL_FIRED_TIME</code> column in the <code>TABLE_FIRED_TRIGGERS</code>
     * table. The caller is responsible for calling <code>computeFirstFireTime</code>
     * on each returned trigger. It is also up to the caller to insert the
     * returned triggers to ensure that they are fired.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>{@link hunt.quartz.Trigger}</code> objects
     */
    List!(OperableTrigger) selectTriggersForRecoveringJobs(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn
                    .prepareStatement(rtp(SELECT_INSTANCES_RECOVERABLE_FIRED_TRIGGERS));
            ps.setString(1, instanceId);
            setBoolean(ps, 2, true);
            rs = ps.executeQuery();

            long dumId = DateTimeHelper.currentTimeMillis();
            LinkedList!(OperableTrigger) list = new LinkedList!(OperableTrigger)();
            while (rs.next()) {
                string jobName = rs.getString(COL_JOB_NAME);
                string jobGroup = rs.getString(COL_JOB_GROUP);
                string trigName = rs.getString(COL_TRIGGER_NAME);
                string trigGroup = rs.getString(COL_TRIGGER_GROUP);
                long firedTime = rs.getLong(COL_FIRED_TIME);
                long scheduledTime = rs.getLong(COL_SCHED_TIME);
                int priority = rs.getInt(COL_PRIORITY);
                
                SimpleTriggerImpl rcvryTrig = new SimpleTriggerImpl("recover_"
                        + instanceId ~ "_" ~ string.valueOf(dumId++),
                        Scheduler.DEFAULT_RECOVERY_GROUP, new Date(scheduledTime));
                rcvryTrig.setJobName(jobName);
                rcvryTrig.setJobGroup(jobGroup);
                rcvryTrig.setPriority(priority);
                rcvryTrig.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY);

                JobDataMap jd = selectTriggerJobDataMap(conn, trigName, trigGroup);
                jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_NAME, trigName);
                jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_GROUP, trigGroup);
                jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_FIRETIME_IN_MILLISECONDS, string.valueOf(firedTime));
                jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_SCHEDULED_FIRETIME_IN_MILLISECONDS, string.valueOf(scheduledTime));
                rcvryTrig.setJobDataMap(jd);
                
                list.add(rcvryTrig);
            }
            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Delete all fired triggers.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of rows deleted
     */
    int deleteFiredTriggers(Connection conn) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(DELETE_FIRED_TRIGGERS));

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    int deleteFiredTriggers(Connection conn, string theInstanceId) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(DELETE_INSTANCES_FIRED_TRIGGERS));
            ps.setString(1, theInstanceId);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    
    /**
     * Clear (delete!) all scheduling data - all {@link Job}s, {@link Trigger}s
     * {@link Calendar}s.
     * 
     * @throws JobPersistenceException
     */
    void clearData(Connection conn) {
        
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(DELETE_ALL_SIMPLE_TRIGGERS));
            ps.executeUpdate();
            ps.close();
            ps = conn.prepareStatement(rtp(DELETE_ALL_SIMPROP_TRIGGERS));
            ps.executeUpdate();
            ps.close();
            ps = conn.prepareStatement(rtp(DELETE_ALL_CRON_TRIGGERS));
            ps.executeUpdate();
            ps.close();
            ps = conn.prepareStatement(rtp(DELETE_ALL_BLOB_TRIGGERS));
            ps.executeUpdate();
            ps.close();
            ps = conn.prepareStatement(rtp(DELETE_ALL_TRIGGERS));
            ps.executeUpdate();
            ps.close();
            ps = conn.prepareStatement(rtp(DELETE_ALL_JOB_DETAILS));
            ps.executeUpdate();
            ps.close();
            ps = conn.prepareStatement(rtp(DELETE_ALL_CALENDARS));
            ps.executeUpdate();
            ps.close();
            ps = conn.prepareStatement(rtp(DELETE_ALL_PAUSED_TRIGGER_GRPS));
            ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }
 
    
    //---------------------------------------------------------------------------
    // jobs
    //---------------------------------------------------------------------------

    /**
     * <p>
     * Insert the job detail record.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param job
     *          the job to insert
     * @return number of rows inserted
     * @throws IOException
     *           if there were problems serializing the JobDataMap
     */
    int insertJobDetail(Connection conn, JobDetail job) {
        ByteArrayOutputStream baos = serializeJobData(job.getJobDataMap());

        PreparedStatement ps = null;

        int insertResult = 0;

        try {
            ps = conn.prepareStatement(rtp(INSERT_JOB_DETAIL));
            ps.setString(1, job.getKey().getName());
            ps.setString(2, job.getKey().getGroup());
            ps.setString(3, job.getDescription());
            ps.setString(4, job.getJobClass().getName());
            setBoolean(ps, 5, job.isDurable());
            setBoolean(ps, 6, job.isConcurrentExectionDisallowed());
            setBoolean(ps, 7, job.isPersistJobDataAfterExecution());
            setBoolean(ps, 8, job.requestsRecovery());
            setBytes(ps, 9, baos);

            insertResult = ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }

        return insertResult;
    }

    /**
     * <p>
     * Update the job detail record.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param job
     *          the job to update
     * @return number of rows updated
     * @throws IOException
     *           if there were problems serializing the JobDataMap
     */
    int updateJobDetail(Connection conn, JobDetail job) {
        ByteArrayOutputStream baos = serializeJobData(job.getJobDataMap());

        PreparedStatement ps = null;

        int insertResult = 0;

        try {
            ps = conn.prepareStatement(rtp(UPDATE_JOB_DETAIL));
            ps.setString(1, job.getDescription());
            ps.setString(2, job.getJobClass().getName());
            setBoolean(ps, 3, job.isDurable());
            setBoolean(ps, 4, job.isConcurrentExectionDisallowed());
            setBoolean(ps, 5, job.isPersistJobDataAfterExecution());
            setBoolean(ps, 6, job.requestsRecovery());
            setBytes(ps, 7, baos);
            ps.setString(8, job.getKey().getName());
            ps.setString(9, job.getKey().getGroup());

            insertResult = ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }

        return insertResult;
    }

    /**
     * <p>
     * Get the names of all of the triggers associated with the given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>{@link
     * hunt.quartz.utils.Key}</code> objects
     */
    List!(TriggerKey) selectTriggerKeysForJob(Connection conn, JobKey jobKey) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGERS_FOR_JOB));
            ps.setString(1, jobKey.getName());
            ps.setString(2, jobKey.getGroup());
            rs = ps.executeQuery();

            LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
            while (rs.next()) {
                string trigName = rs.getString(COL_TRIGGER_NAME);
                string trigGroup = rs.getString(COL_TRIGGER_GROUP);
                list.add(triggerKey(trigName, trigGroup));
            }
            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Delete the job detail record for the given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of rows deleted
     */
    int deleteJobDetail(Connection conn, JobKey jobKey) {
        PreparedStatement ps = null;

        try {
            if (logger.isDebugEnabled()) {
                logger.debug("Deleting job: " ~ jobKey);
            }
            ps = conn.prepareStatement(rtp(DELETE_JOB_DETAIL));
            ps.setString(1, jobKey.getName());
            ps.setString(2, jobKey.getGroup());
            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Check whether or not the given job is stateful.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return true if the job exists and is stateful, false otherwise
     */
    bool isJobNonConcurrent(Connection conn, JobKey jobKey) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_JOB_NONCONCURRENT));
            ps.setString(1, jobKey.getName());
            ps.setString(2, jobKey.getGroup());
            rs = ps.executeQuery();
            if (!rs.next()) { return false; }
            return getBoolean(rs, COL_IS_NONCONCURRENT);
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Check whether or not the given job exists.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return true if the job exists, false otherwise
     */
    bool jobExists(Connection conn, JobKey jobKey) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_JOB_EXISTENCE));
            ps.setString(1, jobKey.getName());
            ps.setString(2, jobKey.getGroup());
            rs = ps.executeQuery();
            if (rs.next()) {
                return true;
            } else {
                return false;
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }

    }

    /**
     * <p>
     * Update the job data map for the given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param job
     *          the job to update
     * @return the number of rows updated
     */
    int updateJobData(Connection conn, JobDetail job) {
        ByteArrayOutputStream baos = serializeJobData(job.getJobDataMap());

        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(UPDATE_JOB_DATA));
            setBytes(ps, 1, baos);
            ps.setString(2, job.getKey().getName());
            ps.setString(3, job.getKey().getGroup());

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select the JobDetail object for a given job name / group name.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the populated JobDetail object
     * @throws ClassNotFoundException
     *           if a class found during deserialization cannot be found or if
     *           the job class could not be found
     * @throws IOException
     *           if deserialization causes an error
     */
    JobDetail selectJobDetail(Connection conn, JobKey jobKey,
            ClassLoadHelper loadHelper) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_JOB_DETAIL));
            ps.setString(1, jobKey.getName());
            ps.setString(2, jobKey.getGroup());
            rs = ps.executeQuery();

            JobDetailImpl job = null;

            if (rs.next()) {
                job = new JobDetailImpl();

                job.setName(rs.getString(COL_JOB_NAME));
                job.setGroup(rs.getString(COL_JOB_GROUP));
                job.setDescription(rs.getString(COL_DESCRIPTION));
                job.setJobClass( loadHelper.loadClass(rs.getString(COL_JOB_CLASS), Job.class));
                job.setDurability(getBoolean(rs, COL_IS_DURABLE));
                job.setRequestsRecovery(getBoolean(rs, COL_REQUESTS_RECOVERY));

                Map<?, ?> map = null;
                if (canUseProperties()) {
                    map = getMapFromProperties(rs);
                } else {
                    map = (Map<?, ?>) getObjectFromBlob(rs, COL_JOB_DATAMAP);
                }

                if (null != map) {
                    job.setJobDataMap(new JobDataMap(map));
                }
            }

            return job;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * build Map from java.util.Properties encoding.
     */
    private Map<?, ?> getMapFromProperties(ResultSet rs) {
        Map<?, ?> map;
        InputStream is = (InputStream) getJobDataFromBlob(rs, COL_JOB_DATAMAP);
        if(is is null) {
            return null;
        }
        Properties properties = new Properties();
        if (is !is null) {
            try {
                properties.load(is);
            } finally {
                is.close();
            }
        }
        map = convertFromProperty(properties);
        return map;
    }

    /**
     * <p>
     * Select the total number of jobs stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the total number of jobs stored
     */
    int selectNumJobs(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            int count = 0;
            ps = conn.prepareStatement(rtp(SELECT_NUM_JOBS));
            rs = ps.executeQuery();

            if (rs.next()) {
                count = rs.getInt(1);
            }

            return count;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select all of the job group names that are stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>string</code> group names
     */
    List!(string) selectJobGroups(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_JOB_GROUPS));
            rs = ps.executeQuery();

            LinkedList!(string) list = new LinkedList!(string)();
            while (rs.next()) {
                list.add(rs.getString(1));
            }

            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select all of the jobs contained in a given group.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param matcher
     *          the groupMatcher to evaluate the jobs against
     * @return an array of <code>string</code> job names
     */
    Set!(JobKey) selectJobsInGroup(Connection conn, GroupMatcher!(JobKey) matcher) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            if(isMatcherEquals(matcher)) {
                ps = conn.prepareStatement(rtp(SELECT_JOBS_IN_GROUP));
                ps.setString(1, toSqlEqualsClause(matcher));
            }
            else {
                ps = conn.prepareStatement(rtp(SELECT_JOBS_IN_GROUP_LIKE));
                ps.setString(1, toSqlLikeClause(matcher));
            }
            rs = ps.executeQuery();

            LinkedList!(JobKey) list = new LinkedList!(JobKey)();
            while (rs.next()) {
                list.add(jobKey(rs.getString(1), rs.getString(2)));
            }

            return new HashSet!(JobKey)(list);
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    protected bool isMatcherEquals(final GroupMatcher<?> matcher) {
        return matcher.getCompareWithOperator()== StringMatcher.StringOperatorName.EQUALS;
    }

    protected string toSqlEqualsClause(final GroupMatcher<?> matcher) {
        return matcher.getCompareToValue();
    }

    protected string toSqlLikeClause(final GroupMatcher<?> matcher) {
        string groupName;
        switch(matcher.getCompareWithOperator()) {
            case EQUALS:
                groupName = matcher.getCompareToValue();
                break;
            case CONTAINS:
                groupName = "%" ~ matcher.getCompareToValue() ~ "%";
                break;
            case ENDS_WITH:
                groupName = "%" ~ matcher.getCompareToValue();
                break;
            case STARTS_WITH:
                groupName = matcher.getCompareToValue() ~ "%";
                break;
            case ANYTHING:
                groupName = "%";
                break;
            default:
                throw new UnsupportedOperationException("Don't know how to translate " ~ matcher.getCompareWithOperator() ~ " into SQL");
        }
        return groupName;
    }

    //---------------------------------------------------------------------------
    // triggers
    //---------------------------------------------------------------------------

    /**
     * <p>
     * Insert the base trigger data.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param trigger
     *          the trigger to insert
     * @param state
     *          the state that the trigger should be stored in
     * @return the number of rows inserted
     */
    int insertTrigger(Connection conn, OperableTrigger trigger, string state,
            JobDetail jobDetail) {

        ByteArrayOutputStream baos = null;
        if(trigger.getJobDataMap().size() > 0) {
            baos = serializeJobData(trigger.getJobDataMap());
        }
        
        PreparedStatement ps = null;

        int insertResult = 0;

        try {
            ps = conn.prepareStatement(rtp(INSERT_TRIGGER));
            ps.setString(1, trigger.getKey().getName());
            ps.setString(2, trigger.getKey().getGroup());
            ps.setString(3, trigger.getJobKey().getName());
            ps.setString(4, trigger.getJobKey().getGroup());
            ps.setString(5, trigger.getDescription());
            if(trigger.getNextFireTime() !is null)
                ps.setBigDecimal(6, new BigDecimal(string.valueOf(trigger
                        .getNextFireTime().getTime())));
            else
                ps.setBigDecimal(6, null);
            long prevFireTime = -1;
            if (trigger.getPreviousFireTime() !is null) {
                prevFireTime = trigger.getPreviousFireTime().getTime();
            }
            ps.setBigDecimal(7, new BigDecimal(string.valueOf(prevFireTime)));
            ps.setString(8, state);
            
            TriggerPersistenceDelegate tDel = findTriggerPersistenceDelegate(trigger);
            
            string type = TTYPE_BLOB;
            if(tDel !is null)
                type = tDel.getHandledTriggerTypeDiscriminator();
            ps.setString(9, type);
            
            ps.setBigDecimal(10, new BigDecimal(string.valueOf(trigger
                    .getStartTime().getTime())));
            long endTime = 0;
            if (trigger.getEndTime() !is null) {
                endTime = trigger.getEndTime().getTime();
            }
            ps.setBigDecimal(11, new BigDecimal(string.valueOf(endTime)));
            ps.setString(12, trigger.getCalendarName());
            ps.setInt(13, trigger.getMisfireInstruction());
            setBytes(ps, 14, baos);
            ps.setInt(15, trigger.getPriority());
            
            insertResult = ps.executeUpdate();
            
            if(tDel is null)
                insertBlobTrigger(conn, trigger);
            else
                tDel.insertExtendedTriggerProperties(conn, trigger, state, jobDetail);
            
        } finally {
            closeStatement(ps);
        }

        return insertResult;
    }

    /**
     * <p>
     * Insert the blob trigger data.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param trigger
     *          the trigger to insert
     * @return the number of rows inserted
     */
    int insertBlobTrigger(Connection conn, OperableTrigger trigger) {
        PreparedStatement ps = null;
        ByteArrayOutputStream os = null;

        try {
            // update the blob
            os = new ByteArrayOutputStream();
            ObjectOutputStream oos = new ObjectOutputStream(os);
            oos.writeObject(trigger);
            oos.close();

            byte[] buf = os.toByteArray();
            ByteArrayInputStream is = new ByteArrayInputStream(buf);

            ps = conn.prepareStatement(rtp(INSERT_BLOB_TRIGGER));
            ps.setString(1, trigger.getKey().getName());
            ps.setString(2, trigger.getKey().getGroup());
            ps.setBinaryStream(3, is, buf.length);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update the base trigger data.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param trigger
     *          the trigger to insert
     * @param state
     *          the state that the trigger should be stored in
     * @return the number of rows updated
     */
    int updateTrigger(Connection conn, OperableTrigger trigger, string state,
            JobDetail jobDetail) {

        // save some clock cycles by unnecessarily writing job data blob ...
        bool updateJobData = trigger.getJobDataMap().isDirty();
        ByteArrayOutputStream baos = null;
        if(updateJobData) {
            baos = serializeJobData(trigger.getJobDataMap());
        }
                
        PreparedStatement ps = null;

        int insertResult = 0;


        try {
            if(updateJobData) {
                ps = conn.prepareStatement(rtp(UPDATE_TRIGGER));
            } else {
                ps = conn.prepareStatement(rtp(UPDATE_TRIGGER_SKIP_DATA));
            }
                
            ps.setString(1, trigger.getJobKey().getName());
            ps.setString(2, trigger.getJobKey().getGroup());
            ps.setString(3, trigger.getDescription());
            long nextFireTime = -1;
            if (trigger.getNextFireTime() !is null) {
                nextFireTime = trigger.getNextFireTime().getTime();
            }
            ps.setBigDecimal(4, new BigDecimal(string.valueOf(nextFireTime)));
            long prevFireTime = -1;
            if (trigger.getPreviousFireTime() !is null) {
                prevFireTime = trigger.getPreviousFireTime().getTime();
            }
            ps.setBigDecimal(5, new BigDecimal(string.valueOf(prevFireTime)));
            ps.setString(6, state);
            
            TriggerPersistenceDelegate tDel = findTriggerPersistenceDelegate(trigger);
            
            string type = TTYPE_BLOB;
            if(tDel !is null)
                type = tDel.getHandledTriggerTypeDiscriminator();

            ps.setString(7, type);
            
            ps.setBigDecimal(8, new BigDecimal(string.valueOf(trigger
                    .getStartTime().getTime())));
            long endTime = 0;
            if (trigger.getEndTime() !is null) {
                endTime = trigger.getEndTime().getTime();
            }
            ps.setBigDecimal(9, new BigDecimal(string.valueOf(endTime)));
            ps.setString(10, trigger.getCalendarName());
            ps.setInt(11, trigger.getMisfireInstruction());
            ps.setInt(12, trigger.getPriority());

            if(updateJobData) {
                setBytes(ps, 13, baos);
                ps.setString(14, trigger.getKey().getName());
                ps.setString(15, trigger.getKey().getGroup());
            } else {
                ps.setString(13, trigger.getKey().getName());
                ps.setString(14, trigger.getKey().getGroup());
            }

            insertResult = ps.executeUpdate();
            
            if(tDel is null)
                updateBlobTrigger(conn, trigger);
            else
                tDel.updateExtendedTriggerProperties(conn, trigger, state, jobDetail);
            
        } finally {
            closeStatement(ps);
        }

        return insertResult;
    }

    /**
     * <p>
     * Update the blob trigger data.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param trigger
     *          the trigger to insert
     * @return the number of rows updated
     */
    int updateBlobTrigger(Connection conn, OperableTrigger trigger) {
        PreparedStatement ps = null;
        ByteArrayOutputStream os = null;

        try {
            // update the blob
            os = new ByteArrayOutputStream();
            ObjectOutputStream oos = new ObjectOutputStream(os);
            oos.writeObject(trigger);
            oos.close();

            byte[] buf = os.toByteArray();
            ByteArrayInputStream is = new ByteArrayInputStream(buf);

            ps = conn.prepareStatement(rtp(UPDATE_BLOB_TRIGGER));
            ps.setBinaryStream(1, is, buf.length);
            ps.setString(2, trigger.getKey().getName());
            ps.setString(3, trigger.getKey().getGroup());

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
            if (os !is null) {
                os.close();
            }
        }
    }

    /**
     * <p>
     * Check whether or not a trigger exists.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return true if the trigger exists, false otherwise
     */
    bool triggerExists(Connection conn, TriggerKey triggerKey) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGER_EXISTENCE));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());
            rs = ps.executeQuery();

            if (rs.next()) {
                return true;
            } else {
                return false;
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update the state for a given trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param state
     *          the new state for the trigger
     * @return the number of rows updated
     */
    int updateTriggerState(Connection conn, TriggerKey triggerKey,
            string state) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(UPDATE_TRIGGER_STATE));
            ps.setString(1, state);
            ps.setString(2, triggerKey.getName());
            ps.setString(3, triggerKey.getGroup());
            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update the given trigger to the given new state, if it is one of the
     * given old states.
     * </p>
     * 
     * @param conn
     *          the DB connection
     * @param newState
     *          the new state for the trigger
     * @param oldState1
     *          one of the old state the trigger must be in
     * @param oldState2
     *          one of the old state the trigger must be in
     * @param oldState3
     *          one of the old state the trigger must be in
     * @return int the number of rows updated
     * @throws SQLException
     */
    int updateTriggerStateFromOtherStates(Connection conn,
            TriggerKey triggerKey, string newState, string oldState1,
            string oldState2, string oldState3) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(UPDATE_TRIGGER_STATE_FROM_STATES));
            ps.setString(1, newState);
            ps.setString(2, triggerKey.getName());
            ps.setString(3, triggerKey.getGroup());
            ps.setString(4, oldState1);
            ps.setString(5, oldState2);
            ps.setString(6, oldState3);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update all triggers in the given group to the given new state, if they
     * are in one of the given old states.
     * </p>
     * 
     * @param conn
     *          the DB connection
     * @param matcher
     *          the groupMatcher to evaluate the triggers against
     * @param newState
     *          the new state for the trigger
     * @param oldState1
     *          one of the old state the trigger must be in
     * @param oldState2
     *          one of the old state the trigger must be in
     * @param oldState3
     *          one of the old state the trigger must be in
     * @return int the number of rows updated
     * @throws SQLException
     */
    int updateTriggerGroupStateFromOtherStates(Connection conn,
            GroupMatcher!(TriggerKey) matcher, string newState, string oldState1,
            string oldState2, string oldState3) {
        PreparedStatement ps = null;

        try {
            ps = conn
                    .prepareStatement(rtp(UPDATE_TRIGGER_GROUP_STATE_FROM_STATES));
            ps.setString(1, newState);
            ps.setString(2, toSqlLikeClause(matcher));
            ps.setString(3, oldState1);
            ps.setString(4, oldState2);
            ps.setString(5, oldState3);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update the given trigger to the given new state, if it is in the given
     * old state.
     * </p>
     * 
     * @param conn
     *          the DB connection
     * @param newState
     *          the new state for the trigger
     * @param oldState
     *          the old state the trigger must be in
     * @return int the number of rows updated
     * @throws SQLException
     */
    int updateTriggerStateFromOtherState(Connection conn,
            TriggerKey triggerKey, string newState, string oldState) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(UPDATE_TRIGGER_STATE_FROM_STATE));
            ps.setString(1, newState);
            ps.setString(2, triggerKey.getName());
            ps.setString(3, triggerKey.getGroup());
            ps.setString(4, oldState);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update all of the triggers of the given group to the given new state, if
     * they are in the given old state.
     * </p>
     * 
     * @param conn
     *          the DB connection
     * @param matcher
     *          the groupMatcher to evaluate the triggers against
     * @param newState
     *          the new state for the trigger group
     * @param oldState
     *          the old state the triggers must be in
     * @return int the number of rows updated
     * @throws SQLException
     */
    int updateTriggerGroupStateFromOtherState(Connection conn,
            GroupMatcher!(TriggerKey) matcher, string newState, string oldState) {
        PreparedStatement ps = null;

        try {
            ps = conn
                    .prepareStatement(rtp(UPDATE_TRIGGER_GROUP_STATE_FROM_STATE));
            ps.setString(1, newState);
            ps.setString(2, toSqlLikeClause(matcher));
            ps.setString(3, oldState);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update the states of all triggers associated with the given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param state
     *          the new state for the triggers
     * @return the number of rows updated
     */
    int updateTriggerStatesForJob(Connection conn, JobKey jobKey,
            string state) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(UPDATE_JOB_TRIGGER_STATES));
            ps.setString(1, state);
            ps.setString(2, jobKey.getName());
            ps.setString(3, jobKey.getGroup());

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    int updateTriggerStatesForJobFromOtherState(Connection conn,
            JobKey jobKey, string state, string oldState) {
        PreparedStatement ps = null;

        try {
            ps = conn
                    .prepareStatement(rtp(UPDATE_JOB_TRIGGER_STATES_FROM_OTHER_STATE));
            ps.setString(1, state);
            ps.setString(2, jobKey.getName());
            ps.setString(3, jobKey.getGroup());
            ps.setString(4, oldState);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Delete the cron trigger data for a trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of rows deleted
     */
    int deleteBlobTrigger(Connection conn, TriggerKey triggerKey) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(DELETE_BLOB_TRIGGER));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Delete the base trigger data for a trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of rows deleted
     */
    int deleteTrigger(Connection conn, TriggerKey triggerKey) {
        PreparedStatement ps = null;

        deleteTriggerExtension(conn, triggerKey);
        
        try {
            ps = conn.prepareStatement(rtp(DELETE_TRIGGER));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }
    
    protected void deleteTriggerExtension(Connection conn, TriggerKey triggerKey) {

        foreach(TriggerPersistenceDelegate tDel; triggerPersistenceDelegates) {
            if(tDel.deleteExtendedTriggerProperties(conn, triggerKey) > 0)
                return; // as soon as one affects a row, we're done.
        }
        
        deleteBlobTrigger(conn, triggerKey); 
    }

    /**
     * <p>
     * Select the number of triggers associated with a given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of triggers for the given job
     */
    int selectNumTriggersForJob(Connection conn, JobKey jobKey) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_NUM_TRIGGERS_FOR_JOB));
            ps.setString(1, jobKey.getName());
            ps.setString(2, jobKey.getGroup());
            rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getInt(1);
            } else {
                return 0;
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select the job to which the trigger is associated.
     * </p>
     *
     * @param conn
     *          the DB Connection
     * @return the <code>{@link hunt.quartz.JobDetail}</code> object
     *         associated with the given trigger
     * @throws SQLException
     * @throws ClassNotFoundException
     */
    JobDetail selectJobForTrigger(Connection conn, ClassLoadHelper loadHelper,
        TriggerKey triggerKey) {
        return selectJobForTrigger(conn, loadHelper, triggerKey, true);
    }

    /**
     * <p>
     * Select the job to which the trigger is associated. Allow option to load actual job class or not. When case of
     * remove, we do not need to load the class, which in many cases, it's no longer exists.
     *
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the <code>{@link hunt.quartz.JobDetail}</code> object
     *         associated with the given trigger
     * @throws SQLException
     * @throws ClassNotFoundException
     */
    JobDetail selectJobForTrigger(Connection conn, ClassLoadHelper loadHelper,
            TriggerKey triggerKey, bool loadJobClass) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_JOB_FOR_TRIGGER));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());
            rs = ps.executeQuery();

            if (rs.next()) {
                JobDetailImpl job = new JobDetailImpl();
                job.setName(rs.getString(1));
                job.setGroup(rs.getString(2));
                job.setDurability(getBoolean(rs, 3));
                if (loadJobClass)
                    job.setJobClass(loadHelper.loadClass(rs.getString(4), Job.class));
                job.setRequestsRecovery(getBoolean(rs, 5));
                
                return job;
            } else {
                if (logger.isDebugEnabled()) {
                    logger.debug("No job for trigger '" ~ triggerKey ~ "'.");
                }
                return null;
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select the triggers for a job
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>(@link hunt.quartz.Trigger)</code> objects
     *         associated with a given job.
     * @throws SQLException
     * @throws JobPersistenceException 
     */
    List!(OperableTrigger) selectTriggersForJob(Connection conn, JobKey jobKey) ClassNotFoundException,
            IOException, JobPersistenceException {

        LinkedList!(OperableTrigger) trigList = new LinkedList!(OperableTrigger)();
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGERS_FOR_JOB));
            ps.setString(1, jobKey.getName());
            ps.setString(2, jobKey.getGroup());
            rs = ps.executeQuery();

            while (rs.next()) {
                OperableTrigger t = selectTrigger(conn, triggerKey(rs.getString(COL_TRIGGER_NAME), rs.getString(COL_TRIGGER_GROUP)));
                if(t !is null) {
                    trigList.add(t);
                }
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }

        return trigList;
    }

    List!(OperableTrigger) selectTriggersForCalendar(Connection conn, string calName) {

        LinkedList!(OperableTrigger) trigList = new LinkedList!(OperableTrigger)();
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGERS_FOR_CALENDAR));
            ps.setString(1, calName);
            rs = ps.executeQuery();

            while (rs.next()) {
                trigList.add(selectTrigger(conn, triggerKey(rs.getString(COL_TRIGGER_NAME), rs.getString(COL_TRIGGER_GROUP))));
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }

        return trigList;
    }

    /**
     * <p>
     * Select a trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the <code>{@link hunt.quartz.Trigger}</code> object
     * @throws JobPersistenceException 
     */
    OperableTrigger selectTrigger(Connection conn, TriggerKey triggerKey) ClassNotFoundException,
            IOException, JobPersistenceException {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            OperableTrigger trigger = null;

            ps = conn.prepareStatement(rtp(SELECT_TRIGGER));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());
            rs = ps.executeQuery();

            if (rs.next()) {
                string jobName = rs.getString(COL_JOB_NAME);
                string jobGroup = rs.getString(COL_JOB_GROUP);
                string description = rs.getString(COL_DESCRIPTION);
                long nextFireTime = rs.getLong(COL_NEXT_FIRE_TIME);
                long prevFireTime = rs.getLong(COL_PREV_FIRE_TIME);
                string triggerType = rs.getString(COL_TRIGGER_TYPE);
                long startTime = rs.getLong(COL_START_TIME);
                long endTime = rs.getLong(COL_END_TIME);
                string calendarName = rs.getString(COL_CALENDAR_NAME);
                int misFireInstr = rs.getInt(COL_MISFIRE_INSTRUCTION);
                int priority = rs.getInt(COL_PRIORITY);

                Map<?, ?> map = null;
                if (canUseProperties()) {
                    map = getMapFromProperties(rs);
                } else {
                    map = (Map<?, ?>) getObjectFromBlob(rs, COL_JOB_DATAMAP);
                }
                
                Date nft = null;
                if (nextFireTime > 0) {
                    nft = new Date(nextFireTime);
                }

                Date pft = null;
                if (prevFireTime > 0) {
                    pft = new Date(prevFireTime);
                }
                Date startTimeD = new Date(startTime);
                Date endTimeD = null;
                if (endTime > 0) {
                    endTimeD = new Date(endTime);
                }

                if (triggerType== TTYPE_BLOB) {
                    rs.close(); rs = null;
                    ps.close(); ps = null;

                    ps = conn.prepareStatement(rtp(SELECT_BLOB_TRIGGER));
                    ps.setString(1, triggerKey.getName());
                    ps.setString(2, triggerKey.getGroup());
                    rs = ps.executeQuery();

                    if (rs.next()) {
                        trigger = (OperableTrigger) getObjectFromBlob(rs, COL_BLOB);
                    }
                }
                else {
                    TriggerPersistenceDelegate tDel = findTriggerPersistenceDelegate(triggerType);
                    
                    if(tDel is null)
                        throw new JobPersistenceException("No TriggerPersistenceDelegate for trigger discriminator type: " ~ triggerType);

                    TriggerPropertyBundle triggerProps = null;
                    try {
                        triggerProps = tDel.loadExtendedTriggerProperties(conn, triggerKey);
                    } catch (IllegalStateException isex) {
                        if (isTriggerStillPresent(ps)) {
                            throw isex;
                        } else {
                            // QTZ-386 Trigger has been deleted
                            return null;
                        }
                    }

                    TriggerBuilder<?> tb = newTrigger()
                        .withDescription(description)
                        .withPriority(priority)
                        .startAt(startTimeD)
                        .endAt(endTimeD)
                        .withIdentity(triggerKey)
                        .modifiedByCalendar(calendarName)
                        .withSchedule(triggerProps.getScheduleBuilder())
                        .forJob(jobKey(jobName, jobGroup));
    
                    if (null != map) {
                        tb.usingJobData(new JobDataMap(map));
                    }
    
                    trigger = (OperableTrigger) tb.build();
                    
                    trigger.setMisfireInstruction(misFireInstr);
                    trigger.setNextFireTime(nft);
                    trigger.setPreviousFireTime(pft);
                    
                    setTriggerStateProperties(trigger, triggerProps);
                }                
            }

            return trigger;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    private bool isTriggerStillPresent(PreparedStatement ps) {
        ResultSet rs = null;
        try {
            rs = ps.executeQuery();
            return rs.next();
        } finally {
            closeResultSet(rs);
        }
    }

    private void setTriggerStateProperties(OperableTrigger trigger, TriggerPropertyBundle props) {
        
        if(props.getStatePropertyNames() is null)
            return;
        
        Util.setBeanProps(trigger, props.getStatePropertyNames(), props.getStatePropertyValues());
    }

    /**
     * <p>
     * Select a trigger's JobDataMap.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param triggerName
     *          the name of the trigger
     * @param groupName
     *          the group containing the trigger
     * @return the <code>{@link hunt.quartz.JobDataMap}</code> of the Trigger,
     * never null, but possibly empty.
     */
    JobDataMap selectTriggerJobDataMap(Connection conn, string triggerName,
            string groupName) ClassNotFoundException,
            IOException {
        
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGER_DATA));
            ps.setString(1, triggerName);
            ps.setString(2, groupName);
            rs = ps.executeQuery();

            if (rs.next()) {

                Map<?, ?> map = null;
                if (canUseProperties()) { 
                    map = getMapFromProperties(rs);
                } else {
                    map = (Map<?, ?>) getObjectFromBlob(rs, COL_JOB_DATAMAP);
                }
                
                rs.close();
                ps.close();

                if (null != map) {
                    return new JobDataMap(map);
                }
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
        
        return new JobDataMap();
    }
            

    /**
     * <p>
     * Select a trigger' state value.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the <code>{@link hunt.quartz.Trigger}</code> object
     */
    string selectTriggerState(Connection conn, TriggerKey triggerKey) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            string state = null;

            ps = conn.prepareStatement(rtp(SELECT_TRIGGER_STATE));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());
            rs = ps.executeQuery();

            if (rs.next()) {
                state = rs.getString(COL_TRIGGER_STATE);
            } else {
                state = STATE_DELETED;
            }

            return state.intern();
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }

    }

    /**
     * <p>
     * Select a trigger' status (state & next fire time).
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return a <code>TriggerStatus</code> object, or null
     */
    TriggerStatus selectTriggerStatus(Connection conn,
            TriggerKey triggerKey) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            TriggerStatus status = null;

            ps = conn.prepareStatement(rtp(SELECT_TRIGGER_STATUS));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());
            rs = ps.executeQuery();

            if (rs.next()) {
                string state = rs.getString(COL_TRIGGER_STATE);
                long nextFireTime = rs.getLong(COL_NEXT_FIRE_TIME);
                string jobName = rs.getString(COL_JOB_NAME);
                string jobGroup = rs.getString(COL_JOB_GROUP);

                Date nft = null;
                if (nextFireTime > 0) {
                    nft = new Date(nextFireTime);
                }

                status = new TriggerStatus(state, nft);
                status.setKey(triggerKey);
                status.setJobKey(jobKey(jobName, jobGroup));
            }

            return status;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }

    }

    /**
     * <p>
     * Select the total number of triggers stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the total number of triggers stored
     */
    int selectNumTriggers(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            int count = 0;
            ps = conn.prepareStatement(rtp(SELECT_NUM_TRIGGERS));
            rs = ps.executeQuery();

            if (rs.next()) {
                count = rs.getInt(1);
            }

            return count;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select all of the trigger group names that are stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>string</code> group names
     */
    List!(string) selectTriggerGroups(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGER_GROUPS));
            rs = ps.executeQuery();

            LinkedList!(string) list = new LinkedList!(string)();
            while (rs.next()) {
                list.add(rs.getString(1));
            }

            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    List!(string) selectTriggerGroups(Connection conn, GroupMatcher!(TriggerKey) matcher) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGER_GROUPS_FILTERED));
            ps.setString(1, toSqlLikeClause(matcher));
            rs = ps.executeQuery();

            LinkedList!(string) list = new LinkedList!(string)();
            while (rs.next()) {
                list.add(rs.getString(1));
            }

            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select all of the triggers contained in a given group.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param matcher
     *          to evaluate against known triggers
     * @return a Set of <code>TriggerKey</code>s
     */
    Set!(TriggerKey) selectTriggersInGroup(Connection conn, GroupMatcher!(TriggerKey) matcher) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            if(isMatcherEquals(matcher)) {
                ps = conn.prepareStatement(rtp(SELECT_TRIGGERS_IN_GROUP));
                ps.setString(1, toSqlEqualsClause(matcher));
            }
            else {
                ps = conn.prepareStatement(rtp(SELECT_TRIGGERS_IN_GROUP_LIKE));
                ps.setString(1, toSqlLikeClause(matcher));
            }
            rs = ps.executeQuery();

            Set!(TriggerKey) keys = new HashSet!(TriggerKey)();
            while (rs.next()) {
                keys.add(triggerKey(rs.getString(1), rs.getString(2)));
            }

            return keys;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    int insertPausedTriggerGroup(Connection conn, string groupName) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(INSERT_PAUSED_TRIGGER_GROUP));
            ps.setString(1, groupName);
            int rows = ps.executeUpdate();

            return rows;
        } finally {
            closeStatement(ps);
        }
    }

    int deletePausedTriggerGroup(Connection conn, string groupName) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(DELETE_PAUSED_TRIGGER_GROUP));
            ps.setString(1, groupName);
            int rows = ps.executeUpdate();

            return rows;
        } finally {
            closeStatement(ps);
        }
    }

    int deletePausedTriggerGroup(Connection conn, GroupMatcher!(TriggerKey) matcher) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(DELETE_PAUSED_TRIGGER_GROUP));
            ps.setString(1, toSqlLikeClause(matcher));
            int rows = ps.executeUpdate();

            return rows;
        } finally {
            closeStatement(ps);
        }
    }

    int deleteAllPausedTriggerGroups(Connection conn) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(DELETE_PAUSED_TRIGGER_GROUPS));
            int rows = ps.executeUpdate();

            return rows;
        } finally {
            closeStatement(ps);
        }
    }

    bool isTriggerGroupPaused(Connection conn, string groupName) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_PAUSED_TRIGGER_GROUP));
            ps.setString(1, groupName);
            rs = ps.executeQuery();

            return rs.next();
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    bool isExistingTriggerGroup(Connection conn, string groupName) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_NUM_TRIGGERS_IN_GROUP));
            ps.setString(1, groupName);
            rs = ps.executeQuery();

            if (!rs.next()) {
                return false;
            }

            return (rs.getInt(1) > 0);
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    //---------------------------------------------------------------------------
    // calendars
    //---------------------------------------------------------------------------

    /**
     * <p>
     * Insert a new calendar.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param calendarName
     *          the name for the new calendar
     * @param calendar
     *          the calendar
     * @return the number of rows inserted
     * @throws IOException
     *           if there were problems serializing the calendar
     */
    int insertCalendar(Connection conn, string calendarName,
            Calendar calendar) {
        ByteArrayOutputStream baos = serializeObject(calendar);

        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(INSERT_CALENDAR));
            ps.setString(1, calendarName);
            setBytes(ps, 2, baos);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update a calendar.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param calendarName
     *          the name for the new calendar
     * @param calendar
     *          the calendar
     * @return the number of rows updated
     * @throws IOException
     *           if there were problems serializing the calendar
     */
    int updateCalendar(Connection conn, string calendarName,
            Calendar calendar) {
        ByteArrayOutputStream baos = serializeObject(calendar);

        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(UPDATE_CALENDAR));
            setBytes(ps, 1, baos);
            ps.setString(2, calendarName);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Check whether or not a calendar exists.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param calendarName
     *          the name of the calendar
     * @return true if the trigger exists, false otherwise
     */
    bool calendarExists(Connection conn, string calendarName) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_CALENDAR_EXISTENCE));
            ps.setString(1, calendarName);
            rs = ps.executeQuery();

            if (rs.next()) {
                return true;
            } else {
                return false;
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select a calendar.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param calendarName
     *          the name of the calendar
     * @return the Calendar
     * @throws ClassNotFoundException
     *           if a class found during deserialization cannot be found be
     *           found
     * @throws IOException
     *           if there were problems deserializing the calendar
     */
    Calendar selectCalendar(Connection conn, string calendarName) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            string selCal = rtp(SELECT_CALENDAR);
            ps = conn.prepareStatement(selCal);
            ps.setString(1, calendarName);
            rs = ps.executeQuery();

            Calendar cal = null;
            if (rs.next()) {
                cal = (Calendar) getObjectFromBlob(rs, COL_CALENDAR);
            }
            if (null == cal) {
                logger.warn("Couldn't find calendar with name '" ~ calendarName
                        ~ "'.");
            }
            return cal;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Check whether or not a calendar is referenced by any triggers.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param calendarName
     *          the name of the calendar
     * @return true if any triggers reference the calendar, false otherwise
     */
    bool calendarIsReferenced(Connection conn, string calendarName) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = conn.prepareStatement(rtp(SELECT_REFERENCED_CALENDAR));
            ps.setString(1, calendarName);
            rs = ps.executeQuery();

            if (rs.next()) {
                return true;
            } else {
                return false;
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Delete a calendar.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param calendarName
     *          the name of the trigger
     * @return the number of rows deleted
     */
    int deleteCalendar(Connection conn, string calendarName) {
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(rtp(DELETE_CALENDAR));
            ps.setString(1, calendarName);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select the total number of calendars stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the total number of calendars stored
     */
    int selectNumCalendars(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            int count = 0;
            ps = conn.prepareStatement(rtp(SELECT_NUM_CALENDARS));

            rs = ps.executeQuery();

            if (rs.next()) {
                count = rs.getInt(1);
            }

            return count;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select all of the stored calendars.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>string</code> calendar names
     */
    List!(string) selectCalendars(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_CALENDARS));
            rs = ps.executeQuery();

            LinkedList!(string) list = new LinkedList!(string)();
            while (rs.next()) {
                list.add(rs.getString(1));
            }

            return list;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    //---------------------------------------------------------------------------
    // trigger firing
    //---------------------------------------------------------------------------

    /**
     * <p>
     * Select the next time that a trigger will be fired.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the next fire time, or 0 if no trigger will be fired
     * 
     * @deprecated Does not account for misfires.
     */
    long selectNextFireTime(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = conn.prepareStatement(rtp(SELECT_NEXT_FIRE_TIME));
            ps.setString(1, STATE_WAITING);
            rs = ps.executeQuery();

            if (rs.next()) {
                return rs.getLong(ALIAS_COL_NEXT_FIRE_TIME);
            } else {
                return 0l;
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select the trigger that will be fired at the given fire time.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param fireTime
     *          the time that the trigger will be fired
     * @return a <code>{@link hunt.quartz.utils.Key}</code> representing the
     *         trigger that will be fired at the given fire time, or null if no
     *         trigger will be fired at that time
     */
    TriggerKey selectTriggerForFireTime(Connection conn, long fireTime) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = conn.prepareStatement(rtp(SELECT_TRIGGER_FOR_FIRE_TIME));
            ps.setString(1, STATE_WAITING);
            ps.setBigDecimal(2, new BigDecimal(string.valueOf(fireTime)));
            rs = ps.executeQuery();

            if (rs.next()) {
                return new TriggerKey(rs.getString(COL_TRIGGER_NAME), rs
                        .getString(COL_TRIGGER_GROUP));
            } else {
                return null;
            }
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }


    
    /**
     * <p>
     * Select the next trigger which will fire to fire between the two given timestamps 
     * in ascending order of fire time, and then descending by priority.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param noLaterThan
     *          highest value of <code>getNextFireTime()</code> of the triggers (exclusive)
     * @param noEarlierThan 
     *          highest value of <code>getNextFireTime()</code> of the triggers (inclusive)
     *          
     * @return A (never null, possibly empty) list of the identifiers (Key objects) of the next triggers to be fired.
     * 
     * @deprecated - This remained for compatibility reason. Use {@link #selectTriggerToAcquire(Connection, long, long, int)} instead. 
     */
    List!(TriggerKey) selectTriggerToAcquire(Connection conn, long noLaterThan, long noEarlierThan) {
        // This old API used to always return 1 trigger.
        return selectTriggerToAcquire(conn, noLaterThan, noEarlierThan, 1);
    }

    /**
     * <p>
     * Select the next trigger which will fire to fire between the two given timestamps 
     * in ascending order of fire time, and then descending by priority.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param noLaterThan
     *          highest value of <code>getNextFireTime()</code> of the triggers (exclusive)
     * @param noEarlierThan 
     *          highest value of <code>getNextFireTime()</code> of the triggers (inclusive)
     * @param maxCount 
     *          maximum number of trigger keys allow to acquired in the returning list.
     *          
     * @return A (never null, possibly empty) list of the identifiers (Key objects) of the next triggers to be fired.
     */
    List!(TriggerKey) selectTriggerToAcquire(Connection conn, long noLaterThan, long noEarlierThan, int maxCount) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        List!(TriggerKey) nextTriggers = new LinkedList!(TriggerKey)();
        try {
            ps = conn.prepareStatement(rtp(SELECT_NEXT_TRIGGER_TO_ACQUIRE));
            
            // Set max rows to retrieve
            if (maxCount < 1)
                maxCount = 1; // we want at least one trigger back.
            ps.setMaxRows(maxCount);
            
            // Try to give jdbc driver a hint to hopefully not pull over more than the few rows we actually need.
            // Note: in some jdbc drivers, such as MySQL, you must set maxRows before fetchSize, or you get exception!
            ps.setFetchSize(maxCount);
            
            ps.setString(1, STATE_WAITING);
            ps.setBigDecimal(2, new BigDecimal(string.valueOf(noLaterThan)));
            ps.setBigDecimal(3, new BigDecimal(string.valueOf(noEarlierThan)));
            rs = ps.executeQuery();
            
            while (rs.next() && nextTriggers.size() <= maxCount) {
                nextTriggers.add(triggerKey(
                        rs.getString(COL_TRIGGER_NAME),
                        rs.getString(COL_TRIGGER_GROUP)));
            }
            
            return nextTriggers;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }      
    }

    /**
     * <p>
     * Insert a fired trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param trigger
     *          the trigger
     * @param state
     *          the state that the trigger should be stored in
     * @return the number of rows inserted
     */
    int insertFiredTrigger(Connection conn, OperableTrigger trigger,
            string state, JobDetail job) {
        PreparedStatement ps = null;
        try {
            ps = conn.prepareStatement(rtp(INSERT_FIRED_TRIGGER));
            ps.setString(1, trigger.getFireInstanceId());
            ps.setString(2, trigger.getKey().getName());
            ps.setString(3, trigger.getKey().getGroup());
            ps.setString(4, instanceId);
            ps.setBigDecimal(5, new BigDecimal(string.valueOf(DateTimeHelper.currentTimeMillis())));
            ps.setBigDecimal(6, new BigDecimal(string.valueOf(trigger.getNextFireTime().getTime())));
            ps.setString(7, state);
            if (job !is null) {
                ps.setString(8, trigger.getJobKey().getName());
                ps.setString(9, trigger.getJobKey().getGroup());
                setBoolean(ps, 10, job.isConcurrentExectionDisallowed());
                setBoolean(ps, 11, job.requestsRecovery());
            } else {
                ps.setString(8, null);
                ps.setString(9, null);
                setBoolean(ps, 10, false);
                setBoolean(ps, 11, false);
            }
            ps.setInt(12, trigger.getPriority());

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Update a fired trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param trigger
     *          the trigger
     * @param state
     *          the state that the trigger should be stored in
     * @return the number of rows inserted
     */
    int updateFiredTrigger(Connection conn, OperableTrigger trigger,
            string state, JobDetail job) {
        PreparedStatement ps = null;
        try {
            ps = conn.prepareStatement(rtp(UPDATE_FIRED_TRIGGER));
            
            ps.setString(1, instanceId);

            ps.setBigDecimal(2, new BigDecimal(string.valueOf(DateTimeHelper.currentTimeMillis())));
            ps.setBigDecimal(3, new BigDecimal(string.valueOf(trigger.getNextFireTime().getTime())));
            ps.setString(4, state);

            if (job !is null) {
                ps.setString(5, trigger.getJobKey().getName());
                ps.setString(6, trigger.getJobKey().getGroup());
                setBoolean(ps, 7, job.isConcurrentExectionDisallowed());
                setBoolean(ps, 8, job.requestsRecovery());
            } else {
                ps.setString(5, null);
                ps.setString(6, null);
                setBoolean(ps, 7, false);
                setBoolean(ps, 8, false);
            }

            ps.setString(9, trigger.getFireInstanceId());


            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }
    
    /**
     * <p>
     * Select the states of all fired-trigger records for a given trigger, or
     * trigger group if trigger name is <code>null</code>.
     * </p>
     * 
     * @return a List of FiredTriggerRecord objects.
     */
    List!(FiredTriggerRecord) selectFiredTriggerRecords(Connection conn, string triggerName, string groupName) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            List!(FiredTriggerRecord) lst = new LinkedList!(FiredTriggerRecord)();

            if (triggerName !is null) {
                ps = conn.prepareStatement(rtp(SELECT_FIRED_TRIGGER));
                ps.setString(1, triggerName);
                ps.setString(2, groupName);
            } else {
                ps = conn.prepareStatement(rtp(SELECT_FIRED_TRIGGER_GROUP));
                ps.setString(1, groupName);
            }
            rs = ps.executeQuery();

            while (rs.next()) {
                FiredTriggerRecord rec = new FiredTriggerRecord();

                rec.setFireInstanceId(rs.getString(COL_ENTRY_ID));
                rec.setFireInstanceState(rs.getString(COL_ENTRY_STATE));
                rec.setFireTimestamp(rs.getLong(COL_FIRED_TIME));
                rec.setScheduleTimestamp(rs.getLong(COL_SCHED_TIME));
                rec.setPriority(rs.getInt(COL_PRIORITY));
                rec.setSchedulerInstanceId(rs.getString(COL_INSTANCE_NAME));
                rec.setTriggerKey(triggerKey(rs.getString(COL_TRIGGER_NAME), rs
                        .getString(COL_TRIGGER_GROUP)));
                if (!rec.getFireInstanceState()== STATE_ACQUIRED) {
                    rec.setJobDisallowsConcurrentExecution(getBoolean(rs, COL_IS_NONCONCURRENT));
                    rec.setJobRequestsRecovery(rs
                            .getBoolean(COL_REQUESTS_RECOVERY));
                    rec.setJobKey(jobKey(rs.getString(COL_JOB_NAME), rs
                            .getString(COL_JOB_GROUP)));
                }
                lst.add(rec);
            }

            return lst;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select the states of all fired-trigger records for a given job, or job
     * group if job name is <code>null</code>.
     * </p>
     * 
     * @return a List of FiredTriggerRecord objects.
     */
    List!(FiredTriggerRecord) selectFiredTriggerRecordsByJob(Connection conn, string jobName, string groupName) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            List!(FiredTriggerRecord) lst = new LinkedList!(FiredTriggerRecord)();

            if (jobName !is null) {
                ps = conn.prepareStatement(rtp(SELECT_FIRED_TRIGGERS_OF_JOB));
                ps.setString(1, jobName);
                ps.setString(2, groupName);
            } else {
                ps = conn
                        .prepareStatement(rtp(SELECT_FIRED_TRIGGERS_OF_JOB_GROUP));
                ps.setString(1, groupName);
            }
            rs = ps.executeQuery();

            while (rs.next()) {
                FiredTriggerRecord rec = new FiredTriggerRecord();

                rec.setFireInstanceId(rs.getString(COL_ENTRY_ID));
                rec.setFireInstanceState(rs.getString(COL_ENTRY_STATE));
                rec.setFireTimestamp(rs.getLong(COL_FIRED_TIME));
                rec.setScheduleTimestamp(rs.getLong(COL_SCHED_TIME));
                rec.setPriority(rs.getInt(COL_PRIORITY));
                rec.setSchedulerInstanceId(rs.getString(COL_INSTANCE_NAME));
                rec.setTriggerKey(triggerKey(rs.getString(COL_TRIGGER_NAME), rs
                        .getString(COL_TRIGGER_GROUP)));
                if (!rec.getFireInstanceState()== STATE_ACQUIRED) {
                    rec.setJobDisallowsConcurrentExecution(getBoolean(rs, COL_IS_NONCONCURRENT));
                    rec.setJobRequestsRecovery(rs
                            .getBoolean(COL_REQUESTS_RECOVERY));
                    rec.setJobKey(jobKey(rs.getString(COL_JOB_NAME), rs
                            .getString(COL_JOB_GROUP)));
                }
                lst.add(rec);
            }

            return lst;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }

    }

    List!(FiredTriggerRecord) selectInstancesFiredTriggerRecords(Connection conn,
            string instanceName) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            List!(FiredTriggerRecord) lst = new LinkedList!(FiredTriggerRecord)();

            ps = conn.prepareStatement(rtp(SELECT_INSTANCES_FIRED_TRIGGERS));
            ps.setString(1, instanceName);
            rs = ps.executeQuery();

            while (rs.next()) {
                FiredTriggerRecord rec = new FiredTriggerRecord();

                rec.setFireInstanceId(rs.getString(COL_ENTRY_ID));
                rec.setFireInstanceState(rs.getString(COL_ENTRY_STATE));
                rec.setFireTimestamp(rs.getLong(COL_FIRED_TIME));
                rec.setScheduleTimestamp(rs.getLong(COL_SCHED_TIME));
                rec.setSchedulerInstanceId(rs.getString(COL_INSTANCE_NAME));
                rec.setTriggerKey(triggerKey(rs.getString(COL_TRIGGER_NAME), rs
                        .getString(COL_TRIGGER_GROUP)));
                if (!rec.getFireInstanceState()== STATE_ACQUIRED) {
                    rec.setJobDisallowsConcurrentExecution(getBoolean(rs, COL_IS_NONCONCURRENT));
                    rec.setJobRequestsRecovery(rs
                            .getBoolean(COL_REQUESTS_RECOVERY));
                    rec.setJobKey(jobKey(rs.getString(COL_JOB_NAME), rs
                            .getString(COL_JOB_GROUP)));
                }
                rec.setPriority(rs.getInt(COL_PRIORITY));
                lst.add(rec);
            }

            return lst;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * <p>
     * Select the distinct instance names of all fired-trigger records.
     * </p>
     * 
     * <p>
     * This is useful when trying to identify orphaned fired triggers (a 
     * fired trigger without a scheduler state record.) 
     * </p>
     * 
     * @return a Set of string objects.
     */
    Set!(string) selectFiredTriggerInstanceNames(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            Set!(string) instanceNames = new HashSet!(string)();

            ps = conn.prepareStatement(rtp(SELECT_FIRED_TRIGGER_INSTANCE_NAMES));
            rs = ps.executeQuery();

            while (rs.next()) {
                instanceNames.add(rs.getString(COL_INSTANCE_NAME));
            }

            return instanceNames;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }
    
    /**
     * <p>
     * Delete a fired trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param entryId
     *          the fired trigger entry to delete
     * @return the number of rows deleted
     */
    int deleteFiredTrigger(Connection conn, string entryId) {
        PreparedStatement ps = null;
        try {
            ps = conn.prepareStatement(rtp(DELETE_FIRED_TRIGGER));
            ps.setString(1, entryId);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    int selectJobExecutionCount(Connection conn, JobKey jobKey) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            ps = conn.prepareStatement(rtp(SELECT_JOB_EXECUTION_COUNT));
            ps.setString(1, jobKey.getName());
            ps.setString(2, jobKey.getGroup());

            rs = ps.executeQuery();

            return (rs.next()) ? rs.getInt(1) : 0;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }
    
    int insertSchedulerState(Connection conn, string theInstanceId,
            long checkInTime, long interval) {
        PreparedStatement ps = null;
        try {
            ps = conn.prepareStatement(rtp(INSERT_SCHEDULER_STATE));
            ps.setString(1, theInstanceId);
            ps.setLong(2, checkInTime);
            ps.setLong(3, interval);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    int deleteSchedulerState(Connection conn, string theInstanceId) {
        PreparedStatement ps = null;
        try {
            ps = conn.prepareStatement(rtp(DELETE_SCHEDULER_STATE));
            ps.setString(1, theInstanceId);

            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }

    int updateSchedulerState(Connection conn, string theInstanceId, long checkInTime) {
        PreparedStatement ps = null;
        try {
            ps = conn.prepareStatement(rtp(UPDATE_SCHEDULER_STATE));
            ps.setLong(1, checkInTime);
            ps.setString(2, theInstanceId);
        
            return ps.executeUpdate();
        } finally {
            closeStatement(ps);
        }
    }
        
    List!(SchedulerStateRecord) selectSchedulerStateRecords(Connection conn, string theInstanceId) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            List!(SchedulerStateRecord) lst = new LinkedList!(SchedulerStateRecord)();

            if (theInstanceId !is null) {
                ps = conn.prepareStatement(rtp(SELECT_SCHEDULER_STATE));
                ps.setString(1, theInstanceId);
            } else {
                ps = conn.prepareStatement(rtp(SELECT_SCHEDULER_STATES));
            }
            rs = ps.executeQuery();

            while (rs.next()) {
                SchedulerStateRecord rec = new SchedulerStateRecord();

                rec.setSchedulerInstanceId(rs.getString(COL_INSTANCE_NAME));
                rec.setCheckinTimestamp(rs.getLong(COL_LAST_CHECKIN_TIME));
                rec.setCheckinInterval(rs.getLong(COL_CHECKIN_INTERVAL));

                lst.add(rec);
            }

            return lst;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }

    }

    //---------------------------------------------------------------------------
    // protected methods that can be overridden by subclasses
    //---------------------------------------------------------------------------

    /**
     * <p>
     * Replace the table prefix in a query by replacing any occurrences of
     * "{0}" with the table prefix.
     * </p>
     * 
     * @param query
     *          the unsubstitued query
     * @return the query, with proper table prefix substituted
     */
    protected final string rtp(string query) {
        return Util.rtp(query, tablePrefix, getSchedulerNameLiteral());
    }

    private string schedNameLiteral = null;
    protected string getSchedulerNameLiteral() {
        if(schedNameLiteral is null)
            schedNameLiteral = "'" ~ schedName ~ "'";
        return schedNameLiteral;
    }

    /**
     * <p>
     * Create a serialized <code>java.util.ByteArrayOutputStream</code>
     * version of an Object.
     * </p>
     * 
     * @param obj
     *          the object to serialize
     * @return the serialized ByteArrayOutputStream
     * @throws IOException
     *           if serialization causes an error
     */
    protected ByteArrayOutputStream serializeObject(Object obj) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        if (null != obj) {
            ObjectOutputStream out = new ObjectOutputStream(baos);
            out.writeObject(obj);
            out.flush();
        }
        return baos;
    }

    /**
     * <p>
     * Remove the transient data from and then create a serialized <code>java.util.ByteArrayOutputStream</code>
     * version of a <code>{@link hunt.quartz.JobDataMap}</code>.
     * </p>
     * 
     * @param data
     *          the JobDataMap to serialize
     * @return the serialized ByteArrayOutputStream
     * @throws IOException
     *           if serialization causes an error
     */
    protected ByteArrayOutputStream serializeJobData(JobDataMap data) {
        if (canUseProperties()) {
            return serializeProperties(data);
        }

        try {
            return serializeObject(data);
        } catch (NotSerializableException e) {
            throw new NotSerializableException(
                "Unable to serialize JobDataMap for insertion into " ~ 
                "database because the value of property '" ~ 
                getKeyOfNonSerializableValue(data) + 
                "' is not serializable: " ~ e.getMessage());
        }
    }

    /**
     * Find the key of the first non-serializable value in the given Map.
     * 
     * @return The key of the first non-serializable value in the given Map or 
     * null if all values are serializable.
     */
    protected Object getKeyOfNonSerializableValue(Map<?, ?> data) {
        for (Iterator<?> entryIter = data.entrySet().iterator(); entryIter.hasNext();) {
            Map.Entry<?, ?> entry = (Map.Entry<?, ?>)entryIter.next();
            
            ByteArrayOutputStream baos = null;
            try {
                baos = serializeObject(entry.getValue());
            } catch (IOException e) {
                return entry.getKey();
            } finally {
                if (baos !is null) {
                    try { baos.close(); } catch (IOException ignore) {}
                }
            }
        }
        
        // As long as it is true that the Map was not serializable, we should
        // not hit this case.
        return null;   
    }
    
    /**
     * serialize the java.util.Properties
     */
    private ByteArrayOutputStream serializeProperties(JobDataMap data) {
        ByteArrayOutputStream ba = new ByteArrayOutputStream();
        if (null != data) {
            Properties properties = convertToProperty(data.getWrappedMap());
            properties.store(ba, "");
        }

        return ba;
    }

    /**
     * convert the JobDataMap into a list of properties
     */
    protected Map<?, ?> convertFromProperty(Properties properties) {
        return new HashMap!(Object, Object)(properties);
    }

    /**
     * convert the JobDataMap into a list of properties
     */
    protected Properties convertToProperty(Map<?, ?> data) {
        Properties properties = new Properties();
        
        for (Iterator<?> entryIter = data.entrySet().iterator(); entryIter.hasNext();) {
            Map.Entry<?, ?> entry = (Map.Entry<?, ?>)entryIter.next();
            
            Object key = entry.getKey();
            Object val = (entry.getValue() is null) ? "" : entry.getValue();
            
            if(!(key instanceof string)) {
                throw new IOException("JobDataMap keys/values must be Strings " 
                        ~ "when the 'useProperties' property is set. " 
                        ~ " offending Key: " ~ key);
            }
            
            if(!(val instanceof string)) {
                throw new IOException("JobDataMap values must be Strings " 
                        ~ "when the 'useProperties' property is set. " 
                        ~ " Key of offending value: " ~ key);
            }
            
            properties.put(key, val);
        }
        
        return properties;
    }

    /**
     * <p>
     * This method should be overridden by any delegate subclasses that need
     * special handling for BLOBs. The default implementation uses standard
     * JDBC <code>java.sql.Blob</code> operations.
     * </p>
     * 
     * @param rs
     *          the result set, already queued to the correct row
     * @param colName
     *          the column name for the BLOB
     * @return the deserialized Object from the ResultSet BLOB
     * @throws ClassNotFoundException
     *           if a class found during deserialization cannot be found
     * @throws IOException
     *           if deserialization causes an error
     */
    protected Object getObjectFromBlob(ResultSet rs, string colName) {
        Object obj = null;

        Blob blobLocator = rs.getBlob(colName);
        if (blobLocator !is null && blobLocator.length() != 0) {
            InputStream binaryInput = blobLocator.getBinaryStream();

            if (null != binaryInput) {
                if (binaryInput instanceof ByteArrayInputStream
                    && ((ByteArrayInputStream) binaryInput).available() == 0 ) {
                    //do nothing
                } else {
                    ObjectInputStream in = new ObjectInputStream(binaryInput);
                    try {
                        obj = in.readObject();
                    } finally {
                        in.close();
                    }
                }
            }

        }
        return obj;
    }

    /**
     * <p>
     * This method should be overridden by any delegate subclasses that need
     * special handling for BLOBs for job details. The default implementation
     * uses standard JDBC <code>java.sql.Blob</code> operations.
     * </p>
     * 
     * @param rs
     *          the result set, already queued to the correct row
     * @param colName
     *          the column name for the BLOB
     * @return the deserialized Object from the ResultSet BLOB
     * @throws ClassNotFoundException
     *           if a class found during deserialization cannot be found
     * @throws IOException
     *           if deserialization causes an error
     */
    protected Object getJobDataFromBlob(ResultSet rs, string colName) {
        if (canUseProperties()) {
            Blob blobLocator = rs.getBlob(colName);
            if (blobLocator !is null) {
                InputStream binaryInput = blobLocator.getBinaryStream();
                return binaryInput;
            } else {
                return null;
            }
        }

        return getObjectFromBlob(rs, colName);
    }

    /** 
     * @see hunt.quartz.impl.jdbcjobstore.DriverDelegate#selectPausedTriggerGroups(java.sql.Connection)
     */
    Set!(string) selectPausedTriggerGroups(Connection conn) {
        PreparedStatement ps = null;
        ResultSet rs = null;

        HashSet!(string) set = new HashSet!(string)();
        try {
            ps = conn.prepareStatement(rtp(SELECT_PAUSED_TRIGGER_GROUPS));
            rs = ps.executeQuery();

            while (rs.next()) {
                string groupName = rs.getString(COL_TRIGGER_GROUP);
                set.add(groupName);
            }
            return set;
        } finally {
            closeResultSet(rs);
            closeStatement(ps);
        }
    }

    /**
     * Cleanup helper method that closes the given <code>ResultSet</code>
     * while ignoring any errors.
     */
    protected static void closeResultSet(ResultSet rs) {
        if (null != rs) {
            try {
                rs.close();
            } catch (SQLException ignore) {
            }
        }
    }

    /**
     * Cleanup helper method that closes the given <code>Statement</code>
     * while ignoring any errors.
     */
    protected static void closeStatement(Statement statement) {
        if (null != statement) {
            try {
                statement.close();
            } catch (SQLException ignore) {
            }
        }
    }
    

    /**
     * Sets the designated parameter to the given Java <code>bool</code> value.
     * This just wraps <code>{@link PreparedStatement#setBoolean(int, bool)}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support the bool type.
     */
    protected void setBoolean(PreparedStatement ps, int index, bool val) {
        ps.setBoolean(index, val);
    }

    /**
     * Retrieves the value of the designated column in the current row as
     * a <code>bool</code>.
     * This just wraps <code>{@link ResultSet#getBoolean(java.lang.string)}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support the bool type.
     */
    protected bool getBoolean(ResultSet rs, string columnName) {
        return rs.getBoolean(columnName);
    }
    
    /**
     * Retrieves the value of the designated column index in the current row as
     * a <code>bool</code>.
     * This just wraps <code>{@link ResultSet#getBoolean(java.lang.string)}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support the bool type.
     */
    protected bool getBoolean(ResultSet rs, int columnIndex) {
        return rs.getBoolean(columnIndex);
    }
    
    /**
     * Sets the designated parameter to the byte array of the given
     * <code>ByteArrayOutputStream</code>.  Will set parameter value to null if the 
     * <code>ByteArrayOutputStream</code> is null.
     * This just wraps <code>{@link PreparedStatement#setBytes(int, byte[])}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support storing bytes in this way.
     */
    protected void setBytes(PreparedStatement ps, int index, ByteArrayOutputStream baos) {
        ps.setBytes(index, (baos is null) ? new byte[0] : baos.toByteArray());
    }
}

// EOF
