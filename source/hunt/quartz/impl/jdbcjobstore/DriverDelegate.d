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

module hunt.quartz.impl.jdbcjobstore.DriverDelegate;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.List;
import hunt.comtainer.Set;

import hunt.quartz.Calendar;
import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobKey;
import hunt.quartz.JobPersistenceException;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.spi.ClassLoadHelper;
import hunt.quartz.spi.OperableTrigger;
import hunt.quartz.utils.Key;
import org.slf4j.Logger;

/**
 * <p>
 * This is the base interface for all driver delegate classes.
 * </p>
 * 
 * <p>
 * This interface is very similar to the <code>{@link
 * hunt.quartz.spi.JobStore}</code>
 * interface except each method has an additional <code>{@link java.sql.Connection}</code>
 * parameter.
 * </p>
 * 
 * <p>
 * Unless a database driver has some <strong>extremely-DB-specific</strong>
 * requirements, any DriverDelegate implementation classes should extend the
 * <code>{@link hunt.quartz.impl.jdbcjobstore.StdJDBCDelegate}</code> class.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 * @author James House
 */
interface DriverDelegate {

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
    void initialize(Logger logger, string tablePrefix, string schedName, string instanceId, ClassLoadHelper classLoadHelper, bool useProperties, string initString);

    //---------------------------------------------------------------------------
    // startup / recovery
    //---------------------------------------------------------------------------
    /**
     * <p>
     * Update all triggers having one of the two given states, to the given new
     * state.
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
        string newState, string oldState1, string oldState2);

    /**
     * <p>
     * Get the names of all of the triggers that have misfired - according to
     * the given timestamp.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>{@link
     * hunt.quartz.utils.Key}</code> objects
     */
    List!(TriggerKey) selectMisfiredTriggers(Connection conn, long ts);

    /**
     * <p>
     * Get the names of all of the triggers in the given state that have
     * misfired - according to the given timestamp.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>{@link
     * hunt.quartz.utils.Key}</code> objects
     */
    List!(TriggerKey) selectMisfiredTriggersInState(Connection conn, string state,
        long ts);
    
    /**
     * <p>
     * Get the names of all of the triggers in the given states that have
     * misfired - according to the given timestamp.  No more than count will
     * be returned.
     * </p>
     * 
     * @param conn the DB Connection
     * @param count the most misfired triggers to return, negative for all
     * @param resultList Output parameter.  A List of 
     *      <code>{@link hunt.quartz.utils.Key}</code> objects.  Must not be null.
     *          
     * @return Whether there are more misfired triggers left to find beyond
     *         the given count.
     */
    bool hasMisfiredTriggersInState(Connection conn, string state1, 
        long ts, int count, List!(TriggerKey) resultList);
    
    /**
     * <p>
     * Get the number of triggers in the given state that have
     * misfired - according to the given timestamp.
     * </p>
     * 
     * @param conn the DB Connection
     */
    int countMisfiredTriggersInState(
        Connection conn, string state1, long ts);

    /**
     * <p>
     * Get the names of all of the triggers in the given group and state that
     * have misfired - according to the given timestamp.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>{@link
     * hunt.quartz.utils.Key}</code> objects
     */
    List!(TriggerKey) selectMisfiredTriggersInGroupInState(Connection conn,
        string groupName, string state, long ts);
    

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
    List!(OperableTrigger) selectTriggersForRecoveringJobs(Connection conn);

    /**
     * <p>
     * Delete all fired triggers.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of rows deleted
     */
    int deleteFiredTriggers(Connection conn);

    /**
     * <p>
     * Delete all fired triggers of the given instance.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of rows deleted
     */
    int deleteFiredTriggers(Connection conn, string instanceId);

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
    int insertJobDetail(Connection conn, JobDetail job);

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
    int updateJobDetail(Connection conn, JobDetail job);

    /**
     * <p>
     * Get the names of all of the triggers associated with the given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return an array of <code>{@link
     * hunt.quartz.utils.Key}</code> objects
     */
    List!(TriggerKey) selectTriggerKeysForJob(Connection conn, JobKey jobKey);

    /**
     * <p>
     * Delete the job detail record for the given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return the number of rows deleted
     */
    int deleteJobDetail(Connection conn, JobKey jobKey);

    /**
     * <p>
     * Check whether or not the given job disallows concurrent execution.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return true if the job exists and disallows concurrent execution, false otherwise
     */
    bool isJobNonConcurrent(Connection conn, JobKey jobKey);

    /**
     * <p>
     * Check whether or not the given job exists.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return true if the job exists, false otherwise
     */
    bool jobExists(Connection conn, JobKey jobKey);

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
     * @throws IOException
     *           if there were problems serializing the JobDataMap
     */
    int updateJobData(Connection conn, JobDetail job);

    /**
     * <p>
     * Select the JobDetail object for a given job name / group name.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return the populated JobDetail object
     * @throws ClassNotFoundException
     *           if a class found during deserialization cannot be found or if
     *           the job class could not be found
     * @throws IOException
     *           if deserialization causes an error
     */
    JobDetail selectJobDetail(Connection conn, JobKey jobKey,
        ClassLoadHelper loadHelper);

    /**
     * <p>
     * Select the total number of jobs stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the total number of jobs stored
     */
    int selectNumJobs(Connection conn);

    /**
     * <p>
     * Select all of the job group names that are stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>string</code> group names
     */
    List!(string) selectJobGroups(Connection conn);

    /**
     * <p>
     * Select all of the jobs contained in a given group.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param matcher
     *          the group matcher to evaluate against the known jobs
     * @return an array of <code>string</code> job names
     */
    Set!(JobKey) selectJobsInGroup(Connection conn, GroupMatcher!(JobKey) matcher);

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
        JobDetail jobDetail);

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
        JobDetail jobDetail);

    /**
     * <p>
     * Check whether or not a trigger exists.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return the number of rows updated
     */
    bool triggerExists(Connection conn, TriggerKey triggerKey);

    /**
     * <p>
     * Update the state for a given trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @param state
     *          the new state for the trigger
     * @return the number of rows updated
     */
    int updateTriggerState(Connection conn, TriggerKey triggerKey,
        string state);

    /**
     * <p>
     * Update the given trigger to the given new state, if it is in the given
     * old state.
     * </p>
     * 
     * @param conn
     *          the DB connection
     * 
     * @param newState
     *          the new state for the trigger
     * @param oldState
     *          the old state the trigger must be in
     * @return int the number of rows updated
     * @throws SQLException
     */
    int updateTriggerStateFromOtherState(Connection conn,
        TriggerKey triggerKey, string newState, string oldState);

    /**
     * <p>
     * Update the given trigger to the given new state, if it is one of the
     * given old states.
     * </p>
     * 
     * @param conn
     *          the DB connection
     * 
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
        string oldState2, string oldState3);

    /**
     * <p>
     * Update all triggers in the given group to the given new state, if they
     * are in one of the given old states.
     * </p>
     * 
     * @param conn
     *          the DB connection
     * @param matcher
     *          the group matcher to evaluate against the known triggers
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
        string oldState2, string oldState3);

    /**
     * <p>
     * Update all of the triggers of the given group to the given new state, if
     * they are in the given old state.
     * </p>
     * 
     * @param conn
     *          the DB connection
     * @param matcher
     *          the matcher to evaluate against the known triggers
     * @param newState
     *          the new state for the trigger group
     * @param oldState
     *          the old state the triggers must be in
     * @return int the number of rows updated
     * @throws SQLException
     */
    int updateTriggerGroupStateFromOtherState(Connection conn,
        GroupMatcher!(TriggerKey) matcher, string newState, string oldState);

    /**
     * <p>
     * Update the states of all triggers associated with the given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @param state
     *          the new state for the triggers
     * @return the number of rows updated
     */
    int updateTriggerStatesForJob(Connection conn, JobKey jobKey,
        string state);

    /**
     * <p>
     * Update the states of any triggers associated with the given job, that
     * are the given current state.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @param state
     *          the new state for the triggers
     * @param oldState
     *          the old state of the triggers
     * @return the number of rows updated
     */
    int updateTriggerStatesForJobFromOtherState(Connection conn,
        JobKey jobKey, string state, string oldState);

    /**
     * <p>
     * Delete the base trigger data for a trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return the number of rows deleted
     */
    int deleteTrigger(Connection conn, TriggerKey triggerKey);

    /**
     * <p>
     * Select the number of triggers associated with a given job.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of triggers for the given job
     */
    int selectNumTriggersForJob(Connection conn, JobKey jobKey);

    /**
     * <p>
     * Select the job to which the trigger is associated.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return the <code>{@link hunt.quartz.JobDetail}</code> object
     *         associated with the given trigger
     */
    JobDetail selectJobForTrigger(Connection conn, ClassLoadHelper loadHelper,
        TriggerKey triggerKey);

    /**
     * <p>
     * Select the job to which the trigger is associated. Allow option to load actual job class or not. When case of
     * remove, we do not need to load the class, which in many cases, it's no longer exists.
     * </p>
     */
    JobDetail selectJobForTrigger(Connection conn, ClassLoadHelper loadHelper,
        TriggerKey triggerKey, bool loadJobClass);

    /**
     * <p>
     * Select the triggers for a job
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return an array of <code>(@link hunt.quartz.Trigger)</code> objects
     *         associated with a given job.
     * @throws SQLException
     * @throws JobPersistenceException 
     */
    List!(OperableTrigger) selectTriggersForJob(Connection conn, JobKey jobKey) throws SQLException, ClassNotFoundException,
        IOException, JobPersistenceException;

    /**
     * <p>
     * Select the triggers for a calendar
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @param calName
     *          the name of the calendar
     * @return an array of <code>(@link hunt.quartz.Trigger)</code> objects
     *         associated with the given calendar.
     * @throws SQLException
     * @throws JobPersistenceException 
     */
    List!(OperableTrigger) selectTriggersForCalendar(Connection conn, string calName);
    /**
     * <p>
     * Select a trigger.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return the <code>{@link hunt.quartz.Trigger}</code> object
     * @throws JobPersistenceException 
     */
    OperableTrigger selectTrigger(Connection conn, TriggerKey triggerKey) throws SQLException, ClassNotFoundException,
        IOException, JobPersistenceException;

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
        string groupName) throws SQLException, ClassNotFoundException,
        IOException;

    /**
     * <p>
     * Select a trigger' state value.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return the <code>{@link hunt.quartz.Trigger}</code> object
     */
    string selectTriggerState(Connection conn, TriggerKey triggerKey);

    /**
     * <p>
     * Select a trigger' status (state & next fire time).
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return a <code>TriggerStatus</code> object, or null
     */
    TriggerStatus selectTriggerStatus(Connection conn,
        TriggerKey triggerKey);

    /**
     * <p>
     * Select the total number of triggers stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the total number of triggers stored
     */
    int selectNumTriggers(Connection conn);

    /**
     * <p>
     * Select all of the trigger group names that are stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>string</code> group names
     */
    List!(string) selectTriggerGroups(Connection conn);

    List!(string) selectTriggerGroups(Connection conn, GroupMatcher!(TriggerKey) matcher);

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
    Set!(TriggerKey) selectTriggersInGroup(Connection conn, GroupMatcher!(TriggerKey) matcher);

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
    List!(TriggerKey) selectTriggersInState(Connection conn, string state);

    int insertPausedTriggerGroup(Connection conn, string groupName);

    int deletePausedTriggerGroup(Connection conn, string groupName);

    int deletePausedTriggerGroup(Connection conn, GroupMatcher!(TriggerKey) matcher);

    int deleteAllPausedTriggerGroups(Connection conn);

    bool isTriggerGroupPaused(Connection conn, string groupName);

    Set!(string) selectPausedTriggerGroups(Connection conn);
    
    bool isExistingTriggerGroup(Connection conn, string groupName);

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
        Calendar calendar);

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
        Calendar calendar);

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
    bool calendarExists(Connection conn, string calendarName);

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
    Calendar selectCalendar(Connection conn, string calendarName);

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
    bool calendarIsReferenced(Connection conn, string calendarName);

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
    int deleteCalendar(Connection conn, string calendarName);

    /**
     * <p>
     * Select the total number of calendars stored.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the total number of calendars stored
     */
    int selectNumCalendars(Connection conn);

    /**
     * <p>
     * Select all of the stored calendars.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return an array of <code>string</code> calendar names
     */
    List!(string) selectCalendars(Connection conn);

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
    long selectNextFireTime(Connection conn);

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
    Key<?> selectTriggerForFireTime(Connection conn, long fireTime);

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
    List!(TriggerKey) selectTriggerToAcquire(Connection conn, long noLaterThan, long noEarlierThan);
    
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
    List!(TriggerKey) selectTriggerToAcquire(Connection conn, long noLaterThan, long noEarlierThan, int maxCount);

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
        string state, JobDetail jobDetail);

    /**
     * <p>
     * Update a fired trigger record.  Will update the fields  
     * "firing instance", "fire time", and "state".
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
        string state, JobDetail jobDetail);

    /**
     * <p>
     * Select the states of all fired-trigger records for a given trigger, or
     * trigger group if trigger name is <code>null</code>.
     * </p>
     * 
     * @return a List of FiredTriggerRecord objects.
     */
    List!(FiredTriggerRecord) selectFiredTriggerRecords(Connection conn, string triggerName, string groupName);

    /**
     * <p>
     * Select the states of all fired-trigger records for a given job, or job
     * group if job name is <code>null</code>.
     * </p>
     * 
     * @return a List of FiredTriggerRecord objects.
     */
    List!(FiredTriggerRecord) selectFiredTriggerRecordsByJob(Connection conn, string jobName, string groupName);

    /**
     * <p>
     * Select the states of all fired-trigger records for a given scheduler
     * instance.
     * </p>
     * 
     * @return a List of FiredTriggerRecord objects.
     */
    List!(FiredTriggerRecord) selectInstancesFiredTriggerRecords(Connection conn,
        string instanceName);

    
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
    Set!(string) selectFiredTriggerInstanceNames(Connection conn);
    
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
    int deleteFiredTrigger(Connection conn, string entryId);

    /**
     * <p>
     * Get the number instances of the identified job currently executing.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * 
     * @return the number instances of the identified job currently executing.
     */
    int selectJobExecutionCount(Connection conn, JobKey jobKey);

    /**
     * <p>
     * Insert a scheduler-instance state record.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of inserted rows.
     */
    int insertSchedulerState(Connection conn, string instanceId,
        long checkInTime, long interval);

    /**
     * <p>
     * Delete a scheduler-instance state record.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of deleted rows.
     */
    int deleteSchedulerState(Connection conn, string instanceId);

    
    /**
     * <p>
     * Update a scheduler-instance state record.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     * @return the number of updated rows.
     */
    int updateSchedulerState(Connection conn, string instanceId, long checkInTime);
    
    /**
     * <p>
     * A List of all current <code>SchedulerStateRecords</code>.
     * </p>
     * 
     * <p>
     * If instanceId is not null, then only the record for the identified
     * instance will be returned.
     * </p>
     * 
     * @param conn
     *          the DB Connection
     */
    List!(SchedulerStateRecord) selectSchedulerStateRecords(Connection conn, string instanceId);

    /**
     * Clear (delete!) all scheduling data - all {@link Job}s, {@link Trigger}s
     * {@link Calendar}s.
     * 
     * @throws JobPersistenceException
     */
    void clearData(Connection conn);
    
}

// EOF
