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

import hunt.quartz.dbstore.CalendarIntervalTriggerPersistenceDelegate;
import hunt.quartz.dbstore.CronTriggerPersistenceDelegate;
import hunt.quartz.dbstore.DailyTimeIntervalTriggerPersistenceDelegate;
import hunt.quartz.dbstore.DriverDelegate;
import hunt.quartz.dbstore.FiredTriggerRecord;
import hunt.quartz.dbstore.model;
import hunt.quartz.dbstore.SchedulerStateRecord;
import hunt.quartz.dbstore.SimpleTriggerPersistenceDelegate;
import hunt.quartz.dbstore.StdSqlConstants;
import hunt.quartz.dbstore.TableConstants;
import hunt.quartz.dbstore.TriggerStatus;
import hunt.quartz.dbstore.TriggerPersistenceDelegate;

import hunt.quartz.Calendar;
import hunt.quartz.Exceptions;
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
import hunt.quartz.utils.PropertiesParser;

import hunt.collection.HashMap;
import hunt.collection.HashSet;
import hunt.collection.Iterator;
import hunt.collection.LinkedList;
import hunt.collection.List;
import hunt.collection.Map;
import hunt.collection.Set;

import hunt.Exceptions;
import hunt.entity.EntityManager;
import hunt.entity.NativeQuery;
import hunt.entity.eql.EqlQuery;
import hunt.database.driver.ResultSet;
import hunt.database.Row;
import hunt.io.ByteArrayOutputStream;
import hunt.logging;
import hunt.String;
import hunt.time.LocalDateTime;
import hunt.time.ZoneOffset;
import hunt.util.DateTime;
import hunt.util.Serialize;

import witchcraft;

import std.array;
import std.conv;
import std.format;

alias triggerKey = TriggerKey.triggerKey;
alias jobKey = JobKey.jobKey;



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
    
    protected List!(TriggerPersistenceDelegate) triggerPersistenceDelegates;

    
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
        triggerPersistenceDelegates = new LinkedList!(TriggerPersistenceDelegate)();
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
    void initialize(string tablePrefix, string schedName, string instanceId, 
        bool useProperties, string initString) { 

        this.tablePrefix = tablePrefix;
        this.schedName = schedName;
        this.instanceId = instanceId;
        this.useProperties = useProperties;
        // this.classLoadHelper = classLoadHelper;
        addDefaultTriggerPersistenceDelegates();

        // if(initString is null)
        //     return;

        // string[] settings = initString.split("\\|");
        
        // foreach(string setting; settings) {
        //     string[] parts = setting.split("=");
        //     string name = parts[0];
        //     if(parts.length == 1 || parts[1] is null || parts[1].equals(""))
        //         continue;

        //     if(name.equals("triggerPersistenceDelegateClasses")) {
                
        //         string[] trigDelegates = parts[1].split(",");
                
        //         foreach(string trigDelClassName; trigDelegates) {
        //             try {
        //                 Class<?> trigDelClass = classLoadHelper.loadClass(trigDelClassName);
        //                 addTriggerPersistenceDelegate((TriggerPersistenceDelegate) trigDelClass.newInstance());
        //             } catch (Exception e) {
        //                 throw new NoSuchDelegateException("Error instantiating TriggerPersistenceDelegate of type: " ~ trigDelClassName, e);
        //             } 
        //         }
        //     }
        //     else
        //         throw new NoSuchDelegateException("Unknown setting: '" ~ name ~ "'");
        // }
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
    
    void addTriggerPersistenceDelegate(TriggerPersistenceDelegate d) {
        trace("Adding TriggerPersistenceDelegate of type: " ~ typeid(d).name); // d.getClass().getCanonicalName()
        d.initialize(tablePrefix, schedName);
        this.triggerPersistenceDelegates.add(d);
    }
    
    TriggerPersistenceDelegate findTriggerPersistenceDelegate(OperableTrigger trigger)  {
        foreach(TriggerPersistenceDelegate d; triggerPersistenceDelegates) {
            if(d.canHandleTriggerType(trigger))
                return d;
        }
        
        return null;
    }

    TriggerPersistenceDelegate findTriggerPersistenceDelegate(string discriminator)  {
        foreach(TriggerPersistenceDelegate d; triggerPersistenceDelegates) {
            if(d.getHandledTriggerTypeDiscriminator()== discriminator)
                return d;
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.UPDATE_TRIGGER_STATES_FROM_OTHER_STATES));
        query.setParameter(1, newState);
        query.setParameter(2, oldState1);
        query.setParameter(3, oldState2);
        return query.exec();
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
        
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.SELECT_MISFIRED_TRIGGERS));

        query.setParameter(1, ts);
        Triggers[] triggers = query.getResultList();

        LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
        foreach(Triggers t; triggers) {
            string triggerName = t.triggerName;
            string groupName = t.triggerGroup;
            list.add(triggerKey(triggerName, groupName));
        }
        return list;
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

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.SELECT_TRIGGERS_IN_STATE));

        query.setParameter(1, state);
        ResultSet rs = query.getNativeResult();
        
        LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
        foreach(Row r; rs) {
            list.add(triggerKey(r[0], r[1]));
        }

        return list;
    }

    List!(TriggerKey) selectMisfiredTriggersInState(Connection conn, string state, long ts) {

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.SELECT_MISFIRED_TRIGGERS_IN_STATE));

        query.setParameter(1, ts);
        query.setParameter(2, state);

        LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
        ResultSet rs = query.getNativeResult();
        foreach(Row r; rs) {
            string triggerName = r[0];
            string groupName = r[1];
            list.add(triggerKey(triggerName, groupName));
        }
        return list;
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

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.SELECT_HAS_MISFIRED_TRIGGERS_IN_STATE));

        query.setParameter(1, ts);
        query.setParameter(2, state1);
        
        ResultSet rs = query.getNativeResult();

        bool hasReachedLimit = false;
        foreach(Row r; rs) {
            if (resultList.size() == count) {
                hasReachedLimit = true;
                break;
            } else {
                string triggerName = r[0];
                string groupName = r[1];
                resultList.add(triggerKey(triggerName, groupName));
            }
        }
        
        return hasReachedLimit;
    }
    
    /**
     * <p>
     * Get the number of triggers in the given states that have
     * misfired - according to the given timestamp.
     * </p>
     * 
     * @param conn the DB Connection
     */
    int countMisfiredTriggersInState(Connection conn, string state1, long ts) {
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.COUNT_MISFIRED_TRIGGERS_IN_STATE));

        query.setParameter(1, ts);
        query.setParameter(2, state1);
        
        ResultSet rs = query.getNativeResult();

        if (!rs.empty()) {
            Row r = rs.front;
            return r.getAs!int(0);
        }

        throw new SQLException("No misfired trigger count returned.");
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
        
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.SELECT_MISFIRED_TRIGGERS_IN_GROUP_IN_STATE));
            
        query.setParameter(1, ts);
        query.setParameter(2, groupName);
        query.setParameter(3, state);
        
        ResultSet rs = query.getNativeResult();

        LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
        foreach(Row r; rs) {
            list.add(triggerKey(r[0], groupName));
        }
        return list;
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
        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(
            rtp(StdSqlConstants.SELECT_INSTANCES_RECOVERABLE_FIRED_TRIGGERS));

        query.setParameter(1, instanceId);
        query.setParameter(2, true);
        
        FiredTriggers[] triggers = query.getResultList();

        long dumId = DateTimeHelper.currentTimeMillis();
        LinkedList!(OperableTrigger) list = new LinkedList!(OperableTrigger)();
        foreach(FiredTriggers t; triggers) {
            string jobName = t.jobName;
            string jobGroup = t.jobGroup;
            string trigName = t.triggerName;
            string trigGroup = t.triggerGroup;
            long firedTime = t.firedTime;
            long scheduledTime = t.schedTime;
            int priority = t.priority;
            
            SimpleTriggerImpl rcvryTrig = new SimpleTriggerImpl("recover_"
                    ~ instanceId ~ "_" ~ to!string(dumId++),
                    Scheduler.DEFAULT_RECOVERY_GROUP, LocalDateTime.ofEpochMilli(scheduledTime));
            rcvryTrig.setJobName(jobName);
            rcvryTrig.setJobGroup(jobGroup);
            rcvryTrig.setPriority(priority);
            rcvryTrig.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY);

            JobDataMap jd = selectTriggerJobDataMap(conn, trigName, trigGroup);
            jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_NAME, trigName);
            jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_GROUP, trigGroup);
            jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_FIRETIME_IN_MILLISECONDS, to!string(firedTime));
            jd.put(Scheduler.FAILED_JOB_ORIGINAL_TRIGGER_SCHEDULED_FIRETIME_IN_MILLISECONDS, to!string(scheduledTime));
            rcvryTrig.setJobDataMap(jd);
            
            list.add(rcvryTrig);
        }
        return list;
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
        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(
            rtp(StdSqlConstants.DELETE_FIRED_TRIGGERS));
        return query.exec();
    }

    int deleteFiredTriggers(Connection conn, string theInstanceId) {
        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(
            rtp(StdSqlConstants.DELETE_INSTANCES_FIRED_TRIGGERS));
        query.setParameter(1, theInstanceId);
        return query.exec();
    }

    
    /**
     * Clear (delete!) all scheduling data - all {@link Job}s, {@link Trigger}s
     * {@link Calendar}s.
     * 
     * @throws JobPersistenceException
     */
    void clearData(Connection conn) {
        int count;

        {
            EqlQuery!(SimpleTriggers) query = conn.createQuery!(SimpleTriggers)(rtp(StdSqlConstants.DELETE_ALL_SIMPLE_TRIGGERS));
            count = query.exec();
        }

        {
            EqlQuery!(SimpPropertiesTriggers) query = conn.createQuery!(SimpPropertiesTriggers)(rtp(StdSqlConstants.DELETE_ALL_SIMPROP_TRIGGERS));
            count = query.exec();
        }


        {
            EqlQuery!(CronTriggers) query = conn.createQuery!(CronTriggers)(rtp(StdSqlConstants.DELETE_ALL_CRON_TRIGGERS));
            count = query.exec();
        }

        {
            EqlQuery!(BlobTriggers) query = conn.createQuery!(BlobTriggers)(rtp(StdSqlConstants.DELETE_ALL_BLOB_TRIGGERS));
            count = query.exec();
        }

        {
            EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.DELETE_ALL_TRIGGERS));
            count = query.exec();
        }

        {
            EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.DELETE_ALL_JOB_DETAILS));
            count = query.exec();
        }

        {
            EqlQuery!(Calendars) query = conn.createQuery!(Calendars)(rtp(StdSqlConstants.DELETE_ALL_CALENDARS));
            count = query.exec();
        }

        {
            EqlQuery!(PausedTriggerGrps) query = conn.createQuery!(PausedTriggerGrps)(rtp(StdSqlConstants.DELETE_ALL_PAUSED_TRIGGER_GRPS));
            count = query.exec();
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
        ubyte[] baos = serializeJobData(job.getJobDataMap());

        int insertResult = 0;
        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.INSERT_JOB_DETAIL));
        query.setParameter(1, job.getKey().getName());
        query.setParameter(2, job.getKey().getGroup());
        query.setParameter(3, job.getDescription());
        query.setParameter(4, job.getJobClass().name);
        query.setParameter(5, job.isDurable());
        query.setParameter(6, job.isConcurrentExectionDisallowed());
        query.setParameter(7, job.isPersistJobDataAfterExecution());
        query.setParameter(8, job.requestsRecovery());
        query.setParameter(9, baos);
        insertResult = query.exec();

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

        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.UPDATE_JOB_DETAIL));
        ubyte[] baos = serializeJobData(job.getJobDataMap());

        int insertResult = 0;

        query.setParameter(1, job.getDescription());
        query.setParameter(2, job.getJobClass().name);
        query.setParameter(3, job.isDurable());
        query.setParameter(4, job.isConcurrentExectionDisallowed());
        query.setParameter(5, job.isPersistJobDataAfterExecution());
        query.setParameter(6, job.requestsRecovery());
        query.setParameter(7, baos);
        query.setParameter(8, job.getKey().getName());
        query.setParameter(9, job.getKey().getGroup());

        insertResult = query.exec();
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGERS_FOR_JOB));
        query.setParameter(1, jobKey.getName());
        query.setParameter(2, jobKey.getGroup());
        Triggers[] triggers = query.getResultList();

        LinkedList!(TriggerKey) list = new LinkedList!(TriggerKey)();
        foreach(Triggers t; triggers) {
                list.add(triggerKey(t.triggerName, t.triggerGroup));
        }
        return list;
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
        version(HUNT_DEBUG) {
            info("Deleting job: " ~ jobKey.toString());
        }

        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.DELETE_JOB_DETAIL));
        query.setParameter(1, jobKey.getName());
        query.setParameter(2, jobKey.getGroup());
        return query.exec();
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
        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.SELECT_JOB_NONCONCURRENT));
        query.setParameter(1, jobKey.getName());
        query.setParameter(2, jobKey.getGroup());

        ResultSet rs = query.getNativeResult();
        if (!rs.empty) { 
            Row r = rs.front;
            return r.getAs!bool(0);
        }
        
        return false; 
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
        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.SELECT_JOB_EXISTENCE));
        query.setParameter(1, jobKey.getName());
        query.setParameter(2, jobKey.getGroup());
        JobDetails r = query.getSingleResult();
        version(HUNT_DEBUG) {
            trace("The job %s exists: %s ", jobKey.toString(), r !is null);
        }
        return r !is null;
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
        ubyte[] baos = serializeJobData(job.getJobDataMap());
        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.UPDATE_JOB_DATA));

        query.setParameter(1, baos);
        query.setParameter(2, job.getKey().getName());
        query.setParameter(3, job.getKey().getGroup());

        return query.exec();
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
    JobDetail selectJobDetail(Connection conn, JobKey jobKey) {
        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.SELECT_JOB_DETAIL));
        query.setParameter(1, jobKey.getName());
        query.setParameter(2, jobKey.getGroup());
        JobDetails j = query.getSingleResult();
        if(j is null)
            return null;

        JobDetailImpl job = new JobDetailImpl();
        job.setName(j.jobName);
        job.setGroup(j.jobGroup);
        job.setDescription(j.description);
        
        job.setJobClass(cast(TypeInfo_Class)TypeInfo_Class.find(j.jobClassName));

        job.setDurability(j.isDurable.to!bool());
        job.setRequestsRecovery(j.requestsRecovery.to!bool());
        // FIXME: Needing refactor or cleanup -@zhangxueping at 4/16/2019, 12:26:07 PM
        // to check
        // implementationMissing(false);
        Map!(string, Object) map = null;
        if (canUseProperties()) {
            map = getMapFromProperties(j.jobData);
        } else {
            map = unserialize!(JobDataMap)(cast(byte[])j.jobData); //getObjectFromBlob(rs, COL_JOB_DATAMAP);
        }

        if (map !is null) {
            job.setJobDataMap(new JobDataMap(map));
        }
        return job;
    }

    /**
     * build Map from java.util.Properties encoding.
     */
    private Map!(string, Object) getMapFromProperties(ubyte[] data) {
        if(data is null) {
            return null;
        }

        Properties properties = unserialize!(Properties)(cast(byte[])data);

        return convertFromProperty(properties);
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
        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.SELECT_NUM_JOBS));
        ResultSet rs = query.getNativeResult();

        int count = 0;
        if(!rs.empty){
            Row r = rs.front;
            count = r.getAs!int(0);
        }

        return count;
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
        EqlQuery!(JobDetails) query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.SELECT_JOB_GROUPS));
        ResultSet rs = query.getNativeResult();
        assert(rs !is null);

        LinkedList!(string) list = new LinkedList!(string)();
        foreach(Row r; rs) {
            list.add(r[0]);
        }

        return list;
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
        EqlQuery!(JobDetails) query;

        if(isMatcherEquals(matcher)) {
            query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.SELECT_JOBS_IN_GROUP));
            query.setParameter(1, toSqlEqualsClause(matcher));
        } else {
            query = conn.createQuery!(JobDetails)(rtp(StdSqlConstants.SELECT_JOBS_IN_GROUP_LIKE));
            query.setParameter(1, toSqlLikeClause(matcher));
        }
        ResultSet rs = query.getNativeResult();

        LinkedList!(JobKey) list = new LinkedList!(JobKey)();
        foreach(Row r; rs) {
            list.add(jobKey(r[0], r[1]));
        }

        return new HashSet!(JobKey)(list);
    }

    protected bool isMatcherEquals(T)(GroupMatcher!T matcher) {
        return matcher.getCompareWithOperator() == StringOperatorName.EQUALS;
    }

    protected string toSqlEqualsClause(T)(GroupMatcher!T matcher) {
        return matcher.getCompareToValue();
    }

    protected string toSqlLikeClause(T)(GroupMatcher!T matcher) {
        string groupName;
        StringOperatorName operatorName = matcher.getCompareWithOperator();

        if(operatorName is StringOperatorName.EQUALS) {
            groupName = matcher.getCompareToValue();
        } else if(operatorName is StringOperatorName.CONTAINS) {
            groupName = "%" ~ matcher.getCompareToValue() ~ "%";
        } else if(operatorName is StringOperatorName.ENDS_WITH) {
            groupName = "%" ~ matcher.getCompareToValue();
        } else if(operatorName is StringOperatorName.STARTS_WITH) {
            groupName = matcher.getCompareToValue() ~ "%";
        } else if(operatorName is StringOperatorName.ANYTHING) {
            groupName = "%";
            
        } else {
            throw new UnsupportedOperationException("Don't know how to translate " ~ 
                operatorName.toString() ~ " into SQL");
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
    int insertTrigger(Connection conn, OperableTrigger trigger,
            string state, JobDetail jobDetail) {

        ubyte[] baos = null;
        if(trigger.getJobDataMap().size() > 0) {
            baos = serializeJobData(trigger.getJobDataMap());
        }
        
        int insertResult = 0;
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.INSERT_TRIGGER));

        query.setParameter(1, trigger.getKey().getName());
        query.setParameter(2, trigger.getKey().getGroup());
        query.setParameter(3, trigger.getJobKey().getName());
        query.setParameter(4, trigger.getJobKey().getGroup());
        query.setParameter(5, trigger.getDescription());        

        LocalDateTime ldt = trigger.getNextFireTime();
        if(ldt !is null) {
            long t = ldt.toEpochMilli();
            query.setParameter(6, t);
        } else {
            query.setParameter(6, cast(Object)null);
        }

        long prevFireTime = -1;
        ldt = trigger.getPreviousFireTime();
        if (ldt !is null) {
            prevFireTime = ldt.toEpochMilli(); // trigger.getPreviousFireTime().getTime();
        }
        query.setParameter(7, prevFireTime);
        query.setParameter(8, state);
            
        TriggerPersistenceDelegate tDel = findTriggerPersistenceDelegate(trigger);
            
        string type = TableConstants.TTYPE_BLOB;
        if(tDel !is null)
            type = tDel.getHandledTriggerTypeDiscriminator();
        query.setParameter(9, type);
        
        query.setParameter(10, trigger.getStartTime().toEpochMilli());
        long endTime = 0;
        if (trigger.getEndTime() !is null) {
            endTime = trigger.getEndTime().toEpochMilli();
        }
        query.setParameter(11, endTime);
        query.setParameter(12, trigger.getCalendarName());
        query.setParameter(13, trigger.getMisfireInstruction());
        query.setParameter(14, baos);
        query.setParameter(15, trigger.getPriority());
        
        insertResult = query.exec();
        
        if(tDel is null)
            insertBlobTrigger(conn, trigger);
        else
            tDel.insertExtendedTriggerProperties(conn, trigger, state, jobDetail);

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
        EqlQuery!(BlobTriggers) query = conn.createQuery!(BlobTriggers)(rtp(StdSqlConstants.INSERT_BLOB_TRIGGER));
        query.setParameter(1, trigger.getKey().getName());
        query.setParameter(2, trigger.getKey().getGroup());
        query.setParameter(3, cast(ubyte[])[0x11, 0xA1]);
        
        return query.exec();

        // ByteArrayOutputStream os = null;

        //     // update the blob
        //     os = new ByteArrayOutputStream();
        //     ObjectOutputStream oos = new ObjectOutputStream(os);
        //     oos.writeObject(trigger);
        //     oos.close();

        //     byte[] buf = os.toByteArray();
        //     ByteArrayInputStream is = new ByteArrayInputStream(buf);


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
        ubyte[] baos = null;
        if(updateJobData) {
            baos = serializeJobData(trigger.getJobDataMap());
            // implementationMissing(false);
        }
                
        int insertResult = 0;

        EqlQuery!(Triggers)  query;
        if(updateJobData) {
            query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.UPDATE_TRIGGER));
        } else {
            query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.UPDATE_TRIGGER_SKIP_DATA));
        }
            
        query.setParameter(1, trigger.getJobKey().getName());
        query.setParameter(2, trigger.getJobKey().getGroup());
        query.setParameter(3, trigger.getDescription());
        long nextFireTime = -1;
        if (trigger.getNextFireTime() !is null) {
            nextFireTime = trigger.getNextFireTime().toEpochMilli();
        }
        query.setParameter(4, nextFireTime);
        long prevFireTime = -1;
        if (trigger.getPreviousFireTime() !is null) {
            prevFireTime = trigger.getPreviousFireTime().toEpochMilli();
        }
        query.setParameter(5, prevFireTime);
        query.setParameter(6, state);
        
        TriggerPersistenceDelegate tDel = findTriggerPersistenceDelegate(trigger);
        
        string type = TableConstants.TTYPE_BLOB;
        if(tDel !is null)
            type = tDel.getHandledTriggerTypeDiscriminator();

        query.setParameter(7, type);
        
        query.setParameter(8, trigger.getStartTime().toEpochMilli());
        long endTime = 0;
        if (trigger.getEndTime() !is null) {
            endTime = trigger.getEndTime().toEpochMilli();
        }
        query.setParameter(9, endTime);
        query.setParameter(10, trigger.getCalendarName());
        query.setParameter(11, trigger.getMisfireInstruction());
        query.setParameter(12, trigger.getPriority());

        if(updateJobData) {
            query.setParameter(13, cast(ubyte[])baos);
            query.setParameter(14, trigger.getKey().getName());
            query.setParameter(15, trigger.getKey().getGroup());
        } else {
            query.setParameter(13, trigger.getKey().getName());
            query.setParameter(14, trigger.getKey().getGroup());
        }

        insertResult = query.exec();
        
        if(tDel is null)
            updateBlobTrigger(conn, trigger);
        else
            tDel.updateExtendedTriggerProperties(conn, trigger, state, jobDetail);
            
  
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

        EqlQuery!(BlobTriggers) query = conn.createQuery!(BlobTriggers)(
            rtp(StdSqlConstants.UPDATE_BLOB_TRIGGER)); 

        // ByteArrayOutputStream os = null;

        //     // update the blob
        //     os = new ByteArrayOutputStream();
        //     ObjectOutputStream oos = new ObjectOutputStream(os);
        //     oos.writeObject(trigger);
        //     oos.close();

        //     byte[] buf = os.toByteArray();
        //     ByteArrayInputStream is = new ByteArrayInputStream(buf);
        // FIXME: Needing refactor or cleanup -@zhangxueping at 4/4/2019, 6:17:11 PM
        // 
        implementationMissing(false);
        query.setParameter(1, cast(ubyte[])[0x1]);
        query.setParameter(2, trigger.getKey().getName());
        query.setParameter(3, trigger.getKey().getGroup());
        
        return query.exec();
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGER_EXISTENCE));
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());
        Triggers r = query.getSingleResult();
        return r !is null;
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

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.UPDATE_TRIGGER_STATE)); 
        query.setParameter(1, state);
        query.setParameter(2, triggerKey.getName());
        query.setParameter(3, triggerKey.getGroup());
        
        return query.exec();
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

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.UPDATE_TRIGGER_STATE_FROM_STATES));      

        query.setParameter(1, newState);
        query.setParameter(2, triggerKey.getName());
        query.setParameter(3, triggerKey.getGroup());
        query.setParameter(4, oldState1);
        query.setParameter(5, oldState2);
        query.setParameter(6, oldState3);
        
        return query.exec();
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
        
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.UPDATE_TRIGGER_GROUP_STATE_FROM_STATES));
        query.setParameter(1, newState);
        query.setParameter(2, toSqlLikeClause(matcher));
        query.setParameter(3, oldState1);
        query.setParameter(4, oldState2);
        query.setParameter(5, oldState3);

        return query.exec();
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
        
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.UPDATE_TRIGGER_STATE_FROM_STATE));

        query.setParameter(1, newState);
        query.setParameter(2, triggerKey.getName());
        query.setParameter(3, triggerKey.getGroup());
        query.setParameter(4, oldState);

        return query.exec();
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

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
            rtp(StdSqlConstants.UPDATE_TRIGGER_GROUP_STATE_FROM_STATE));

        query.setParameter(1, newState);
        query.setParameter(2, toSqlLikeClause(matcher));
        query.setParameter(3, oldState);

        return query.exec();
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
    int updateTriggerStatesForJob(Connection conn, JobKey jobKey, string state) {
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
                rtp(StdSqlConstants.UPDATE_JOB_TRIGGER_STATES));
        query.setParameter(1, state);
        query.setParameter(2, jobKey.getName());
        query.setParameter(3, jobKey.getGroup());

        return query.exec();
    }

    int updateTriggerStatesForJobFromOtherState(Connection conn,
            JobKey jobKey, string state, string oldState) {
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(
                rtp(StdSqlConstants.UPDATE_JOB_TRIGGER_STATES_FROM_OTHER_STATE));
        query.setParameter(1, state);
        query.setParameter(2, jobKey.getName());
        query.setParameter(3, jobKey.getGroup());
        query.setParameter(4, oldState);

        return query.exec();
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
        EqlQuery!(BlobTriggers) query = conn.createQuery!(BlobTriggers)(rtp(StdSqlConstants.DELETE_BLOB_TRIGGER));
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());
        return query.exec();
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
        version(HUNT_DEBUG) infof("Deleting trigger: %s", triggerKey.toString());

        deleteTriggerExtension(conn, triggerKey);

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.DELETE_TRIGGER));
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());
        return query.exec();
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_NUM_TRIGGERS_FOR_JOB));
        query.setParameter(1, jobKey.getName());
        query.setParameter(2, jobKey.getGroup());
        ResultSet rs = query.getNativeResult();

        int count = 0;
        if(!rs.empty()) {
            Row r = rs.front();
            count = r.getAs!int(0);
        }
        return count;
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
    JobDetail selectJobForTrigger(Connection conn, TriggerKey triggerKey) {
        return selectJobForTrigger(conn, triggerKey, true);
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
    JobDetail selectJobForTrigger(Connection conn, 
            TriggerKey triggerKey, bool loadJobClass) {
        
        EqlQuery!(JobDetails, Triggers) query = conn.createQuery!(JobDetails, Triggers)
            (rtp2(StdSqlConstants.SELECT_JOB_FOR_TRIGGER));

        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());

        ResultSet rs = query.getNativeResult();
        if(rs.empty) {
           version(HUNT_DEBUG) {
                trace("No job for trigger '" ~ triggerKey.toString() ~ "'.");
            }
            return null;
        } 
        
        JobDetailImpl job = new JobDetailImpl();
        Row r = rs.front();

        job.setName(r[0]);
        job.setGroup(r[1]);
        job.setDurability(r.getAs!bool(2));
        if (loadJobClass) {
            job.setJobClass(cast(TypeInfo_Class)TypeInfo_Class.find(r[3]));
        }
        job.setRequestsRecovery(r.getAs!bool(4));
        
        return job;
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
    List!(OperableTrigger) selectTriggersForJob(Connection conn, JobKey jobKey) {

        LinkedList!(OperableTrigger) trigList = new LinkedList!(OperableTrigger)();

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGERS_FOR_JOB));
        query.setParameter(1, jobKey.getName());
        query.setParameter(2, jobKey.getGroup());

        Triggers[] triggers = query.getResultList();

        foreach(Triggers t; triggers) {
            OperableTrigger ot = selectTrigger(conn, triggerKey(t.triggerName, t.triggerGroup));
            if(ot !is null) {
                trigList.add(ot);
            }
        }

        return trigList;

    }

    List!(OperableTrigger) selectTriggersForCalendar(Connection conn, string calName) {

        LinkedList!(OperableTrigger) trigList = new LinkedList!(OperableTrigger)();
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGERS_FOR_CALENDAR));
        query.setParameter(1, calName);
        ResultSet rs = query.getNativeResult();

        LinkedList!(string) list = new LinkedList!(string)();
        foreach(Row r; rs) {
            trigList.add(selectTrigger(conn, triggerKey(r[0], r[1])));
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
    OperableTrigger selectTrigger(Connection conn, TriggerKey triggerKey) {

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGER));
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());
        Triggers t = query.getSingleResult();

        if(t is null) {
            return null;
        }

        string jobName =  t.jobName;
        string jobGroup = t.jobGroup;
        string description = t.description;
        long nextFireTime = t.nextFireTime;
        long prevFireTime = t.prevFireTime;
        string triggerType = t.triggerType;
        long startTime = t.startTime;
        long endTime = t.endTime;
        string calendarName = t.calendarName;
        int misFireInstr = t.misfireInstruction;
        int priority = t.priority;

        Map!(string, Object) map = null;
        if (canUseProperties()) {
            map = getMapFromProperties(t.jobData);
        } else {
            map = unserialize!(JobDataMap)(cast(byte[])t.jobData); 
        }

        LocalDateTime nft = null;
        if (nextFireTime > 0) {
            nft = LocalDateTime.ofEpochMilli(nextFireTime);
        }

        LocalDateTime pft = null;
        if (prevFireTime > 0) {
            pft = LocalDateTime.ofEpochMilli(prevFireTime);
        }
        LocalDateTime startTimeD = LocalDateTime.ofEpochMilli(startTime);
        LocalDateTime endTimeD = null;
        if (endTime > 0) {
            endTimeD = LocalDateTime.ofEpochMilli(endTime);
        }

        OperableTrigger trigger = null;

        if (triggerType == TableConstants.TTYPE_BLOB) {
            EqlQuery!(BlobTriggers)  blobTriggersQuery = 
                conn.createQuery!(BlobTriggers)(rtp(StdSqlConstants.SELECT_BLOB_TRIGGER));
            blobTriggersQuery.setParameter(1, triggerKey.getName());
            blobTriggersQuery.setParameter(2, triggerKey.getGroup());
            BlobTriggers r = blobTriggersQuery.getSingleResult();

            if (r !is null) {
                
                // unserialize!(JobDataMap)(cast(byte[])r.blogData); 
                // TODO: Tasks pending completion -@zhangxueping at 4/1/2019, 5:38:10 PM
                // 
                warningf("trigger: %s", triggerKey.getName());
                implementationMissing(false);
                // trigger = cast(OperableTrigger) getObjectFromBlob(rs, COL_BLOB);
            } else {
                version(HUNT_DEBUG) trace("There are no blob triggers");
            }
        } else {
            TriggerPersistenceDelegate tDel = findTriggerPersistenceDelegate(triggerType);
            
            if(tDel is null)
                throw new JobPersistenceException(
                    "No TriggerPersistenceDelegate for trigger discriminator type: " ~ triggerType);

            TriggerPropertyBundle triggerProps = null;
            try {
                triggerProps = tDel.loadExtendedTriggerProperties(conn, triggerKey);
            } catch (IllegalStateException isex) {
                version(HUNT_DEBUG) {
                    warning(isex);
                } else {
                    warning(isex.msg);
                }
                // return null;
                if (isTriggerStillPresent(query)) {
                    throw isex;
                } else {
                    // QTZ-386 Trigger has been deleted
                    return null;
                }
            }

            TriggerBuilder!Trigger tb = TriggerBuilderHelper.newTrigger!Trigger()
                .withDescription(description)
                .withPriority(priority)
                .startAt(startTimeD)
                .endAt(endTimeD)
                .withIdentity(triggerKey)
                .modifiedByCalendar(calendarName)
                .withSchedule(triggerProps.getScheduleBuilder())
                .forJob(jobKey(jobName, jobGroup));

            if (map !is null) {
                tb.usingJobData(new JobDataMap(map));
            }

            trigger = cast(OperableTrigger) tb.build();
            
            trigger.setMisfireInstruction(misFireInstr);
            trigger.setNextFireTime(nft);
            trigger.setPreviousFireTime(pft);
            
            setTriggerStateProperties(trigger, triggerProps);
        }   

        return trigger;          
    }


    private bool isTriggerStillPresent(EqlQuery!(Triggers) query) {
        warning("check trigger again");
        ResultSet rs = query.getNativeResult();
        return !rs.empty;
    }

    private void setTriggerStateProperties(OperableTrigger trigger, TriggerPropertyBundle props) {
        setBeanProps(cast(ClassAccessor)trigger, props.getStatePropertyNames(), props.getStatePropertyValues());
    }

    static void setBeanProps(ClassAccessor accessor, string[] propNames, Object[] propValues) {
        if(accessor is null) {
            warning("The object is not a ClassAccessor");
            return ;
        }

        if(propNames is null)
            return;
        
        foreach(size_t i; 0..propNames.length) {
            tracef("name: %s, value: %s", propNames[i], propValues[i]);
        }


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
    JobDataMap selectTriggerJobDataMap(Connection conn, string triggerName, string groupName) {
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGER_DATA));
        query.setParameter(1, triggerName);
        query.setParameter(2, groupName);
        
        ResultSet rs = query.getNativeResult();
        Map!(string, Object) map = null;
        if(!rs.empty()) {
            Row r = rs.front;
            ubyte[] data = r.getAs!(ubyte[])(0);
            tracef("%(%02X %)", data);
            if (canUseProperties()) {
                map = getMapFromProperties(data);
            } else {
                map = unserialize!(JobDataMap)(cast(byte[])data); 
            }
        }

        if (map is null) {
            return new JobDataMap();
        } else {
            return new JobDataMap(map);
        }
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGER_STATE));
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());

        ResultSet rs = query.getNativeResult();
        string state = null;

        if(rs.empty()) {
            state = TableConstants.STATE_DELETED;
        } else {
            Row r = rs.front;
            state = r[0];
        }

        return state;
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
    TriggerStatus selectTriggerStatus(Connection conn, TriggerKey triggerKey) {

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGER_STATUS));
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());
        Triggers trigger = query.getSingleResult();
        TriggerStatus status = null;

        if (trigger !is null) {
            string state = trigger.triggerState;
            long nextFireTime = trigger.nextFireTime;
            string jobName = trigger.jobName;
            string jobGroup = trigger.jobGroup;

            LocalDateTime nft = null;
            if (nextFireTime > 0) {
                nft = LocalDateTime.ofEpochMilli(nextFireTime);
            }

            status = new TriggerStatus(state, nft);
            status.setKey(triggerKey);
            status.setJobKey(jobKey(jobName, jobGroup));
        }

        return status;
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_NUM_TRIGGERS));
        ResultSet rs = query.getNativeResult();

        int count = 0;
        if(!rs.empty()) {
            Row r = rs.front();
            count = r.getAs!int(0);
        }
        return count;
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGER_GROUPS));

        ResultSet rs = query.getNativeResult();

        LinkedList!(string) list = new LinkedList!(string)();
        foreach(Row r; rs) {
            list.add(r[0]);
        }
        return list;
    }

    List!(string) selectTriggerGroups(Connection conn, GroupMatcher!(TriggerKey) matcher) {

        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGER_GROUPS_FILTERED));
        query.setParameter(1, toSqlLikeClause(matcher));

        ResultSet rs = query.getNativeResult();
        assert(rs !is null);

        LinkedList!(string) list = new LinkedList!(string)();
        foreach(Row r; rs) {
            list.add(r[0]);
        }

        return list;
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

        EqlQuery!(Triggers)  query;

        if(isMatcherEquals(matcher)) {
            query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGERS_IN_GROUP));
            query.setParameter(1, toSqlEqualsClause(matcher));
        }
        else {
            query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGERS_IN_GROUP_LIKE));
            query.setParameter(1, toSqlLikeClause(matcher));
        }

        ResultSet rs = query.getNativeResult();
        Set!(TriggerKey) keys = new HashSet!(TriggerKey)();
        foreach(Row r; rs) {
            keys.add(triggerKey(r[0], r[1]));
        }

        return keys;
    }

    int insertPausedTriggerGroup(Connection conn, string groupName) {
        EqlQuery!(PausedTriggerGrps) query = conn.createQuery!(PausedTriggerGrps)(rtp(StdSqlConstants.INSERT_PAUSED_TRIGGER_GROUP));
        query.setParameter(1, groupName);
        int rows = query.exec();
        return rows;
    }

    int deletePausedTriggerGroup(Connection conn, string groupName) {
        EqlQuery!(PausedTriggerGrps) query = conn.createQuery!(PausedTriggerGrps)(rtp(StdSqlConstants.DELETE_PAUSED_TRIGGER_GROUP));
        query.setParameter(1, groupName);
        int rows = query.exec();
        return rows;
    }

    int deletePausedTriggerGroup(Connection conn, GroupMatcher!(TriggerKey) matcher) {
        EqlQuery!(PausedTriggerGrps) query = conn.createQuery!(PausedTriggerGrps)(rtp(StdSqlConstants.DELETE_PAUSED_TRIGGER_GROUP));
        query.setParameter(1, toSqlLikeClause(matcher));
        int rows = query.exec();
        return rows;
    }

    int deleteAllPausedTriggerGroups(Connection conn) {
        EqlQuery!(PausedTriggerGrps) query = conn.createQuery!(PausedTriggerGrps)(rtp(StdSqlConstants.DELETE_PAUSED_TRIGGER_GROUPS));
        int rows = query.exec();
        return rows;
    }

    bool isTriggerGroupPaused(Connection conn, string groupName) {
        EqlQuery!(PausedTriggerGrps) query = conn.createQuery!(PausedTriggerGrps)(rtp(StdSqlConstants.SELECT_PAUSED_TRIGGER_GROUP));
        query.setParameter(1, groupName);

        ResultSet rs = query.getNativeResult();
        int r = rs.rows();
        return r>0;
    }

    bool isExistingTriggerGroup(Connection conn, string groupName) {
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_NUM_TRIGGERS_IN_GROUP));
        query.setParameter(1, groupName);
        ResultSet rs = query.getNativeResult();

        assert(rs !is null);
        assert(!rs.empty);
        return !rs.empty();
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
    int insertCalendar(Connection conn, string calendarName, Calendar calendar) {
        EqlQuery!(Calendars) query = conn.createQuery!(Calendars)(rtp(StdSqlConstants.INSERT_CALENDAR));
        query.setParameter(1, calendarName);

        ubyte[] data = calendar.serialize();
        query.setParameter(2, data);
        return query.exec();
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
    int updateCalendar(Connection conn, string calendarName, Calendar calendar) {
        EqlQuery!(Calendars) query = conn.createQuery!(Calendars)(rtp(StdSqlConstants.UPDATE_CALENDAR));
        
        ubyte[] data = calendar.serialize();
        query.setParameter(1, data);
        return query.exec();
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
        EqlQuery!(Calendars) query = conn.createQuery!(Calendars)(rtp(StdSqlConstants.SELECT_CALENDAR_EXISTENCE));
        query.setParameter(1, calendarName);
        ResultSet rs = query.getNativeResult();
        return !rs.empty();
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
        EqlQuery!(Calendars) query = conn.createQuery!(Calendars)(rtp(StdSqlConstants.SELECT_CALENDAR));
        query.setParameter(1, calendarName);
        Calendars r = query.getSingleResult();

        version(HUNT_DEBUG) infof("try to select the calendar: ", calendarName);
        
        Calendar cal = null;
        if(r is null) {
                warning("Couldn't find calendar with name '" ~ calendarName
                        ~ "'.");
        } else {
            // TODO: Tasks pending completion -@zhangxueping at 4/8/2019, 8:03:43 PM
            // 
            implementationMissing(false);
            cal = null; // unserialize!Calendar(cast(byte[])r.calendar);
        }
        return cal;
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_REFERENCED_CALENDAR));
        query.setParameter(1, calendarName);
        ResultSet rs = query.getNativeResult();
        return !rs.empty();
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
        EqlQuery!(Calendars) query = conn.createQuery!(Calendars)(rtp(StdSqlConstants.DELETE_CALENDAR));
        query.setParameter(1, calendarName);
        return query.exec();
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
        EqlQuery!(Calendars) query = conn.createQuery!(Calendars)(rtp(StdSqlConstants.SELECT_NUM_CALENDARS));
        ResultSet rs = query.getNativeResult();

        int count = 0;
        if(!rs.empty()) {
            Row r = rs.front();
            count = r.getAs!int(0);
        }
        return count;
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
        EqlQuery!(Calendars) query = conn.createQuery!(Calendars)(rtp(StdSqlConstants.SELECT_CALENDARS));
        query.setParameter(1, TableConstants.STATE_WAITING);
        ResultSet rs = query.getNativeResult();

        LinkedList!(string) list = new LinkedList!(string)();
        foreach(Row r; rs) {
            list.add(r[0]);
        }
        return list;
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_NEXT_FIRE_TIME));
        query.setParameter(1, TableConstants.STATE_WAITING);

        ResultSet rs = query.getNativeResult();
        if(rs.empty)
            return 0;
        Row r = rs.front();
        return r.getAs!int(0);
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
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_TRIGGER_FOR_FIRE_TIME));
        query.setParameter(1, TableConstants.STATE_WAITING);
        query.setParameter(2, fireTime);

        Triggers trigger = query.getSingleResult();
        if(trigger is null) {
            return null;
        }

        return new TriggerKey(trigger.triggerName,trigger.triggerGroup);
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
        List!(TriggerKey) nextTriggers = new LinkedList!(TriggerKey)();
        EqlQuery!(Triggers) query = conn.createQuery!(Triggers)(rtp(StdSqlConstants.SELECT_NEXT_TRIGGER_TO_ACQUIRE));

        // FIXME: Needing refactor or cleanup -@zhangxueping at 4/4/2019, 11:01:29 AM
        // 
        // Set max rows to retrieve
        if (maxCount < 1)
            maxCount = 1; // we want at least one trigger back.
        // ps.setMaxRows(maxCount);
        
        // Try to give jdbc driver a hint to hopefully not pull over more than the few rows we actually need.
        // Note: in some jdbc drivers, such as MySQL, you must set maxRows before fetchSize, or you get exception!
        // ps.setFetchSize(maxCount);
            
        query.setParameter(1, TableConstants.STATE_WAITING);
        query.setParameter(2, noLaterThan);
        query.setParameter(3, noEarlierThan);
        Triggers[] triggers = query.getResultList();
        foreach(Triggers t; triggers) {
            nextTriggers.add(triggerKey(t.triggerName, t.triggerGroup));

            if(nextTriggers.size() > maxCount) {
                break;
            }
        }
        return nextTriggers; 
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
        
        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.INSERT_FIRED_TRIGGER));
        
        query.setParameter(1, trigger.getFireInstanceId());
        query.setParameter(2, trigger.getKey().getName());
        query.setParameter(3, trigger.getKey().getGroup());
        query.setParameter(4, instanceId);
        query.setParameter(5, DateTimeHelper.currentTimeMillis());
        query.setParameter(6, trigger.getNextFireTime().toEpochMilli());
        query.setParameter(7, state);
        if (job !is null) {
            query.setParameter(8, trigger.getJobKey().getName());
            query.setParameter(9, trigger.getJobKey().getGroup());
            query.setParameter(10, job.isConcurrentExectionDisallowed());
            query.setParameter(11, job.requestsRecovery());
        } else {
            query.setParameter(8, cast(Object)null);
            query.setParameter(9, cast(Object)null);
            query.setParameter(10, false);
            query.setParameter(11, false);
        }
        query.setParameter(12, trigger.getPriority());
        
        return query.exec();
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

        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.UPDATE_FIRED_TRIGGER));
        query.setParameter(1, instanceId);

        query.setParameter(2, DateTimeHelper.currentTimeMillis());
        query.setParameter(3, trigger.getNextFireTime().toEpochMilli());
        query.setParameter(4, state);

        if (job !is null) {
            query.setParameter(5, trigger.getJobKey().getName());
            query.setParameter(6, trigger.getJobKey().getGroup());
            query.setParameter(7, job.isConcurrentExectionDisallowed());
            query.setParameter(8, job.requestsRecovery());
        } else {
            query.setParameter(5, cast(Object)null);
            query.setParameter(6, cast(Object)null);
            query.setParameter(7, false);
            query.setParameter(8, false);
        }

        query.setParameter(9, trigger.getFireInstanceId());
        return query.exec();
    }

    private static FiredTriggerRecord tiredTriggersToFiredTriggerRecord(FiredTriggers t) {
        FiredTriggerRecord rec = new FiredTriggerRecord();

            rec.setFireInstanceId(t.entryId);
            rec.setFireInstanceState(t.state);
            rec.setFireTimestamp(t.firedTime);
            rec.setScheduleTimestamp(t.schedTime);
            rec.setSchedulerInstanceId(t.instanceName);
            rec.setTriggerKey(triggerKey(t.triggerName, t.triggerGroup));
            if (rec.getFireInstanceState() != TableConstants.STATE_ACQUIRED) {
                rec.setJobDisallowsConcurrentExecution(t.isNonconcurrent);
                rec.setJobRequestsRecovery(t.requestsRecovery);
                rec.setJobKey(jobKey(t.jobName, t.jobGroup));
            }
            rec.setPriority(t.priority);
        return rec;
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
        List!(FiredTriggerRecord) lst = new LinkedList!(FiredTriggerRecord)();

        EqlQuery!(FiredTriggers)  query;
        if (!triggerName.empty()) {
            query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.SELECT_FIRED_TRIGGER));
            query.setParameter(1, triggerName);
            query.setParameter(2, groupName);
        } else {
            query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.SELECT_FIRED_TRIGGER_GROUP));
            query.setParameter(1, groupName);
        }

        FiredTriggers[] trigers = query.getResultList();
        foreach(FiredTriggers t; trigers) {
            lst.add(tiredTriggersToFiredTriggerRecord(t));
        }

        return lst;
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

        List!(FiredTriggerRecord) lst = new LinkedList!(FiredTriggerRecord)();

        EqlQuery!(FiredTriggers)  query;
        if (!jobName.empty()) {
            query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.SELECT_FIRED_TRIGGERS_OF_JOB));
            query.setParameter(1, jobName);
            query.setParameter(2, groupName);
        } else {
            query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.SELECT_FIRED_TRIGGERS_OF_JOB_GROUP));
            query.setParameter(1, groupName);
        }

        FiredTriggers[] trigers = query.getResultList();
        foreach(FiredTriggers t; trigers) {            
            lst.add(tiredTriggersToFiredTriggerRecord(t));
        }

        return lst;
    }

    List!(FiredTriggerRecord) selectInstancesFiredTriggerRecords(Connection conn, string instanceName) {
        List!(FiredTriggerRecord) lst = new LinkedList!(FiredTriggerRecord)();

        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.SELECT_INSTANCES_FIRED_TRIGGERS));
        query.setParameter(1, instanceName);
        FiredTriggers[] trigers = query.getResultList();
        foreach(FiredTriggers t; trigers) {            
            lst.add(tiredTriggersToFiredTriggerRecord(t));
        }

        return lst;
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
        Set!(string) instanceNames = new HashSet!(string)();
        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.SELECT_FIRED_TRIGGER_INSTANCE_NAMES));
        ResultSet rs = query.getNativeResult();
        foreach(Row r; rs) {
            instanceNames.add(r[0]);
        }
        return instanceNames;
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
        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.DELETE_FIRED_TRIGGER));
        query.setParameter(1, entryId);
        return query.exec();
    }

    int selectJobExecutionCount(Connection conn, JobKey jobKey) {
        EqlQuery!(FiredTriggers) query = conn.createQuery!(FiredTriggers)(rtp(StdSqlConstants.SELECT_JOB_EXECUTION_COUNT));
        query.setParameter(1, jobKey.getName());
        query.setParameter(2, jobKey.getGroup());
        ResultSet rs = query.getNativeResult();

        int count = 0;
        if(!rs.empty()) {
            Row r = rs.front();
            count = r.getAs!int(0);
        }
        return count;
    }
    
    int insertSchedulerState(Connection conn, string theInstanceId,
            long checkInTime, long interval) {
        EqlQuery!(SchedulerState) query = conn.createQuery!(SchedulerState)(rtp(StdSqlConstants.INSERT_SCHEDULER_STATE));
        query.setParameter(1, theInstanceId);
        query.setParameter(2, checkInTime);
        query.setParameter(3, interval);
        return query.exec();
    }

    int deleteSchedulerState(Connection conn, string theInstanceId) {
        EqlQuery!(SchedulerState) query = conn.createQuery!(SchedulerState)(rtp(StdSqlConstants.UPDATE_SCHEDULER_STATE));
        query.setParameter(1, theInstanceId);
        return query.exec();
    }

    int updateSchedulerState(Connection conn, string theInstanceId, long checkInTime) {
        EqlQuery!(SchedulerState) query = conn.createQuery!(SchedulerState)(rtp(StdSqlConstants.UPDATE_SCHEDULER_STATE));
        query.setParameter(1, checkInTime);
        query.setParameter(2, theInstanceId);
        return query.exec();
    }
        
    List!(SchedulerStateRecord) selectSchedulerStateRecords(Connection conn, string theInstanceId) {
        EqlQuery!(SchedulerState) query = conn.createQuery!(SchedulerState)(rtp(StdSqlConstants.SELECT_SCHEDULER_STATE));
        
        List!(SchedulerStateRecord) lst = new LinkedList!(SchedulerStateRecord)();

        if (theInstanceId !is null) {
            query = conn.createQuery!(SchedulerState)(rtp(StdSqlConstants.SELECT_SCHEDULER_STATE));
            query.setParameter(1, theInstanceId);
        } else {
            query = conn.createQuery!(SchedulerState)(rtp(StdSqlConstants.SELECT_SCHEDULER_STATES));
        }
        
        SchedulerState[] states = query.getResultList();

        foreach(SchedulerState st; states) {
            SchedulerStateRecord rec = new SchedulerStateRecord();

            rec.setSchedulerInstanceId(st.instanceName);
            rec.setCheckinTimestamp(st.lastCheckinTime);
            rec.setCheckinInterval(st.checkinInterval);

            lst.add(rec);
        }

        return lst;
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
        return format(query, getSchedulerNameLiteral());
    }

    protected final string rtp2(string query) {
        string s = getSchedulerNameLiteral();
        return format(query, s, s);
    }

    // ditto
    protected final string rtpWithTablePrefix(string query) {
        return format(query, tablePrefix, getSchedulerNameLiteral());
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
    // protected ByteArrayOutputStream serializeObject(Object obj) {
    //     // ByteArrayOutputStream baos = new ByteArrayOutputStream();
    //     // if (null != obj) {
    //     //     ObjectOutputStream out = new ObjectOutputStream(baos);
    //     //     out.writeObject(obj);
    //     //     out.flush();
    //     // }
    //     // return baos;

    //     implementationMissing(false);
    //     return null;
    // }

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
    protected ubyte[] serializeJobData(JobDataMap data) {
        if (canUseProperties()) {
            ubyte[] d = cast(ubyte[])serializeProperties(data);
            tracef("%(%02X %)", d);
            return d;
        }

        try {
            ubyte[] d = cast(ubyte[])serialize(data);
            tracef("%(%02X %)", d);
            return d;
        } catch (NotSerializableException e) {
            throw new NotSerializableException(
                "Unable to serialize JobDataMap for insertion into " ~ 
                "database because the value of property '" ~ 
                // getKeyOfNonSerializableValue(data) ~ 
                "' is not serializable: " ~ e.msg);
        }
    }

    /**
     * Find the key of the first non-serializable value in the given Map.
     * 
     * @return The key of the first non-serializable value in the given Map or 
     * null if all values are serializable.
     */
    // protected Object getKeyOfNonSerializableValue(Map<?, ?> data) {
    //     for (Iterator<?> entryIter = data.entrySet().iterator(); entryIter.hasNext();) {
    //         Map.Entry<?, ?> entry = (Map.Entry<?, ?>)entryIter.next();
            
    //         ByteArrayOutputStream baos = null;
    //         try {
    //             baos = serializeObject(entry.getValue());
    //         } catch (IOException e) {
    //             return entry.getKey();
    //         } finally {
    //             if (baos !is null) {
    //                 try { baos.close(); } catch (IOException ignore) {}
    //             }
    //         }
    //     }
        
    //     // As long as it is true that the Map was not serializable, we should
    //     // not hit this case.
    //     return null;   
    // }
    
    /**
     * serialize the Properties
     */
    private const(ubyte)[] serializeProperties(JobDataMap data) {
        Properties properties = convertToProperty(data.getWrappedMap());
        return cast(ubyte[])serialize(properties);
    }

    /**
     * convert the JobDataMap into a list of properties
     */
    protected Map!(string, Object) convertFromProperty(Properties properties) {
        Object[string] map;
        foreach(string key, string value;  properties) {
            map[key] = new String(value);
        }
        return new HashMap!(string, Object)(map);
    }

    /**
     * convert the JobDataMap into a list of properties
     */
    protected Properties convertToProperty(K, V)(Map!(K, V) data) if(is(K == string)) {
        Properties properties;
        
        foreach(K key, V val; data) {
            
            // if(!(key instanceof string)) {
            //     throw new IOException("JobDataMap keys/values must be Strings " 
            //             ~ "when the 'useProperties' property is set. " 
            //             ~ " offending Key: " ~ key);
            // }
            String v = cast(String)val;
            if( v is null) {
                throw new IOException("JobDataMap values must be Strings " 
                        ~ "when the 'useProperties' property is set. " 
                        ~ " Key of offending value: " ~ key);
            }
            
            properties[key] =  v.value();
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
    // protected Object getObjectFromBlob(ResultSet rs, string colName) {
    //     // Object obj = null;

    //     // Blob blobLocator = rs.getBlob(colName);
    //     // if (blobLocator !is null && blobLocator.length() != 0) {
    //     //     InputStream binaryInput = blobLocator.getBinaryStream();

    //     //     if (null != binaryInput) {
    //     //         if (binaryInput instanceof ByteArrayInputStream
    //     //             && ((ByteArrayInputStream) binaryInput).available() == 0 ) {
    //     //             //do nothing
    //     //         } else {
    //     //             ObjectInputStream in = new ObjectInputStream(binaryInput);
    //     //             try {
    //     //                 obj = in.readObject();
    //     //             } finally {
    //     //                 in.close();
    //     //             }
    //     //         }
    //     //     }

    //     // }
    //     // return obj;

    //     implementationMissing(false);
    //     return null;
    // }

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
    // protected Object getJobDataFromBlob(ResultSet rs, string colName) {
    //     if (canUseProperties()) {
    //         Blob blobLocator = rs.getBlob(colName);
    //         if (blobLocator !is null) {
    //             InputStream binaryInput = blobLocator.getBinaryStream();
    //             return binaryInput;
    //         } else {
    //             return null;
    //         }
    //     }

    //     return getObjectFromBlob(rs, colName);
    // }

    /** 
     * @see hunt.quartz.impl.jdbcjobstore.DriverDelegate#selectPausedTriggerGroups(java.sql.Connection)
     */
    Set!(string) selectPausedTriggerGroups(Connection conn) {

        HashSet!(string) set = new HashSet!(string)();
        EqlQuery!(PausedTriggerGrps) query = conn.createQuery!(PausedTriggerGrps)(
            rtp(StdSqlConstants.SELECT_PAUSED_TRIGGER_GROUPS));
        PausedTriggerGrps[] rs = query.getResultList();
        foreach(PausedTriggerGrps item; rs) {
            set.add(item.triggerGroup);
        }
        return set;
    }

    /**
     * Cleanup helper method that closes the given <code>ResultSet</code>
     * while ignoring any errors.
     */
    // protected static void closeResultSet(ResultSet rs) {
    //     if (null != rs) {
    //         try {
    //             rs.close();
    //         } catch (SQLException ignore) {
    //         }
    //     }
    // }

    /**
     * Cleanup helper method that closes the given <code>Statement</code>
     * while ignoring any errors.
     */
    // protected static void closeStatement(Statement statement) {
    //     if (null != statement) {
    //         try {
    //             statement.close();
    //         } catch (SQLException ignore) {
    //         }
    //     }
    // }
    

    /**
     * Sets the designated parameter to the given Java <code>bool</code> value.
     * This just wraps <code>{@link PreparedStatement#setBoolean(int, bool)}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support the bool type.
     */
    // protected void setBoolean(PreparedStatement ps, int index, bool val) {
    //     ps.setBoolean(index, val);
    // }

    /**
     * Retrieves the value of the designated column in the current row as
     * a <code>bool</code>.
     * This just wraps <code>{@link ResultSet#getBoolean(java.lang.string)}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support the bool type.
     */
    // protected bool getBoolean(ResultSet rs, string columnName) {
    //     return rs.getBoolean(columnName);
    // }
    
    /**
     * Retrieves the value of the designated column index in the current row as
     * a <code>bool</code>.
     * This just wraps <code>{@link ResultSet#getBoolean(java.lang.string)}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support the bool type.
     */
    // protected bool getBoolean(ResultSet rs, int columnIndex) {
    //     return rs.getBoolean(columnIndex);
    // }
    
    /**
     * Sets the designated parameter to the byte array of the given
     * <code>ByteArrayOutputStream</code>.  Will set parameter value to null if the 
     * <code>ByteArrayOutputStream</code> is null.
     * This just wraps <code>{@link PreparedStatement#setBytes(int, byte[])}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support storing bytes in this way.
     */
    // protected void setBytes(PreparedStatement ps, int index, ByteArrayOutputStream baos) {
    //     ps.setBytes(index, (baos is null) ? new byte[0] : baos.toByteArray());
    // }
}

// EOF
