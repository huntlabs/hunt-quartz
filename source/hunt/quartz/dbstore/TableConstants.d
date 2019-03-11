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

module hunt.quartz.dbstore.TableConstants;

/**
 * <p>
 * This interface can be implemented by any <code>{@link
 * hunt.quartz.impl.jdbcjobstore.DriverDelegate}</code>
 * class that needs to use the constants contained herein.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 * @author James House
 */
struct TableConstants {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    // Table names
    enum string TABLE_JOB_DETAILS = "JOB_DETAILS";

    enum string TABLE_TRIGGERS = "TRIGGERS";

    enum string TABLE_SIMPLE_TRIGGERS = "SIMPLE_TRIGGERS";

    enum string TABLE_SIMPROP_TRIGGERS = "SIMPROP_TRIGGERS";

    enum string TABLE_CRON_TRIGGERS = "CRON_TRIGGERS";

    enum string TABLE_BLOB_TRIGGERS = "BLOB_TRIGGERS";

    enum string TABLE_FIRED_TRIGGERS = "FIRED_TRIGGERS";

    enum string TABLE_CALENDARS = "CALENDARS";

    enum string TABLE_PAUSED_TRIGGERS = "PAUSED_TRIGGER_GRPS";

    enum string TABLE_LOCKS = "LOCKS";

    enum string TABLE_SCHEDULER_STATE = "SCHEDULER_STATE";

    // TABLE_JOB_DETAILS columns names
    
    enum string COL_SCHEDULER_NAME = "SCHED_NAME";
    
    enum string COL_JOB_NAME = "JOB_NAME";

    enum string COL_JOB_GROUP = "JOB_GROUP";

    enum string COL_IS_DURABLE = "IS_DURABLE";

    enum string COL_IS_VOLATILE = "IS_VOLATILE";

    enum string COL_IS_NONCONCURRENT = "IS_NONCONCURRENT";

    enum string COL_IS_UPDATE_DATA = "IS_UPDATE_DATA";

    enum string COL_REQUESTS_RECOVERY = "REQUESTS_RECOVERY";

    enum string COL_JOB_DATAMAP = "JOB_DATA";

    enum string COL_JOB_CLASS = "JOB_CLASS_NAME";

    enum string COL_DESCRIPTION = "DESCRIPTION";

    // TABLE_TRIGGERS columns names
    enum string COL_TRIGGER_NAME = "TRIGGER_NAME";

    enum string COL_TRIGGER_GROUP = "TRIGGER_GROUP";

    enum string COL_NEXT_FIRE_TIME = "NEXT_FIRE_TIME";

    enum string COL_PREV_FIRE_TIME = "PREV_FIRE_TIME";

    enum string COL_TRIGGER_STATE = "TRIGGER_STATE";

    enum string COL_TRIGGER_TYPE = "TRIGGER_TYPE";

    enum string COL_START_TIME = "START_TIME";

    enum string COL_END_TIME = "END_TIME";

    enum string COL_PRIORITY = "PRIORITY";

    enum string COL_MISFIRE_INSTRUCTION = "MISFIRE_INSTR";

    enum string ALIAS_COL_NEXT_FIRE_TIME = "ALIAS_NXT_FR_TM";

    // TABLE_SIMPLE_TRIGGERS columns names
    enum string COL_REPEAT_COUNT = "REPEAT_COUNT";

    enum string COL_REPEAT_INTERVAL = "REPEAT_INTERVAL";

    enum string COL_TIMES_TRIGGERED = "TIMES_TRIGGERED";

    // TABLE_CRON_TRIGGERS columns names
    enum string COL_CRON_EXPRESSION = "CRON_EXPRESSION";

    // TABLE_BLOB_TRIGGERS columns names
    enum string COL_BLOB = "BLOB_DATA";

    enum string COL_TIME_ZONE_ID = "TIME_ZONE_ID";

    // TABLE_FIRED_TRIGGERS columns names
    enum string COL_INSTANCE_NAME = "INSTANCE_NAME";

    enum string COL_FIRED_TIME = "FIRED_TIME";

    enum string COL_SCHED_TIME = "SCHED_TIME";
    
    enum string COL_ENTRY_ID = "ENTRY_ID";

    enum string COL_ENTRY_STATE = "STATE";

    // TABLE_CALENDARS columns names
    enum string COL_CALENDAR_NAME = "CALENDAR_NAME";

    enum string COL_CALENDAR = "CALENDAR";

    // TABLE_LOCKS columns names
    enum string COL_LOCK_NAME = "LOCK_NAME";

    // TABLE_LOCKS columns names
    enum string COL_LAST_CHECKIN_TIME = "LAST_CHECKIN_TIME";

    enum string COL_CHECKIN_INTERVAL = "CHECKIN_INTERVAL";

    // MISC CONSTANTS
    enum string DEFAULT_TABLE_PREFIX = "QRTZ_";

    // STATES
    enum string STATE_WAITING = "WAITING";

    enum string STATE_ACQUIRED = "ACQUIRED";

    enum string STATE_EXECUTING = "EXECUTING";

    enum string STATE_COMPLETE = "COMPLETE";

    enum string STATE_BLOCKED = "BLOCKED";

    enum string STATE_ERROR = "ERROR";

    enum string STATE_PAUSED = "PAUSED";

    enum string STATE_PAUSED_BLOCKED = "PAUSED_BLOCKED";

    enum string STATE_DELETED = "DELETED";

    /**
     * @deprecated Whether a trigger has misfired is no longer a state, but 
     * rather now identified dynamically by whether the trigger's next fire 
     * time is more than the misfire threshold time in the past.
     */
    enum string STATE_MISFIRED = "MISFIRED";

    enum string ALL_GROUPS_PAUSED = "_$_ALL_GROUPS_PAUSED_$_";

    // TRIGGER TYPES
    /** Simple Trigger type. */
    enum string TTYPE_SIMPLE = "SIMPLE";

    /** Cron Trigger type. */
    enum string TTYPE_CRON = "CRON";

    /** Calendar Interval Trigger type. */
    enum string TTYPE_CAL_INT = "CAL_INT";

    /** Daily Time Interval Trigger type. */
    enum string TTYPE_DAILY_TIME_INT = "DAILY_I";

    /** A general blob Trigger type. */
    enum string TTYPE_BLOB = "BLOB";
}

// EOF
