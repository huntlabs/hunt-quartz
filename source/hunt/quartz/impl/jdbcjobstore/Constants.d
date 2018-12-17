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

module hunt.quartz.impl.jdbcjobstore.Constants;

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
interface Constants {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    // Table names
    string TABLE_JOB_DETAILS = "JOB_DETAILS";

    string TABLE_TRIGGERS = "TRIGGERS";

    string TABLE_SIMPLE_TRIGGERS = "SIMPLE_TRIGGERS";

    string TABLE_CRON_TRIGGERS = "CRON_TRIGGERS";

    string TABLE_BLOB_TRIGGERS = "BLOB_TRIGGERS";

    string TABLE_FIRED_TRIGGERS = "FIRED_TRIGGERS";

    string TABLE_CALENDARS = "CALENDARS";

    string TABLE_PAUSED_TRIGGERS = "PAUSED_TRIGGER_GRPS";

    string TABLE_LOCKS = "LOCKS";

    string TABLE_SCHEDULER_STATE = "SCHEDULER_STATE";

    // TABLE_JOB_DETAILS columns names
    
    string COL_SCHEDULER_NAME = "SCHED_NAME";
    
    string COL_JOB_NAME = "JOB_NAME";

    string COL_JOB_GROUP = "JOB_GROUP";

    string COL_IS_DURABLE = "IS_DURABLE";

    string COL_IS_VOLATILE = "IS_VOLATILE";

    string COL_IS_NONCONCURRENT = "IS_NONCONCURRENT";

    string COL_IS_UPDATE_DATA = "IS_UPDATE_DATA";

    string COL_REQUESTS_RECOVERY = "REQUESTS_RECOVERY";

    string COL_JOB_DATAMAP = "JOB_DATA";

    string COL_JOB_CLASS = "JOB_CLASS_NAME";

    string COL_DESCRIPTION = "DESCRIPTION";

    // TABLE_TRIGGERS columns names
    string COL_TRIGGER_NAME = "TRIGGER_NAME";

    string COL_TRIGGER_GROUP = "TRIGGER_GROUP";

    string COL_NEXT_FIRE_TIME = "NEXT_FIRE_TIME";

    string COL_PREV_FIRE_TIME = "PREV_FIRE_TIME";

    string COL_TRIGGER_STATE = "TRIGGER_STATE";

    string COL_TRIGGER_TYPE = "TRIGGER_TYPE";

    string COL_START_TIME = "START_TIME";

    string COL_END_TIME = "END_TIME";

    string COL_PRIORITY = "PRIORITY";

    string COL_MISFIRE_INSTRUCTION = "MISFIRE_INSTR";

    string ALIAS_COL_NEXT_FIRE_TIME = "ALIAS_NXT_FR_TM";

    // TABLE_SIMPLE_TRIGGERS columns names
    string COL_REPEAT_COUNT = "REPEAT_COUNT";

    string COL_REPEAT_INTERVAL = "REPEAT_INTERVAL";

    string COL_TIMES_TRIGGERED = "TIMES_TRIGGERED";

    // TABLE_CRON_TRIGGERS columns names
    string COL_CRON_EXPRESSION = "CRON_EXPRESSION";

    // TABLE_BLOB_TRIGGERS columns names
    string COL_BLOB = "BLOB_DATA";

    string COL_TIME_ZONE_ID = "TIME_ZONE_ID";

    // TABLE_FIRED_TRIGGERS columns names
    string COL_INSTANCE_NAME = "INSTANCE_NAME";

    string COL_FIRED_TIME = "FIRED_TIME";

    string COL_SCHED_TIME = "SCHED_TIME";
    
    string COL_ENTRY_ID = "ENTRY_ID";

    string COL_ENTRY_STATE = "STATE";

    // TABLE_CALENDARS columns names
    string COL_CALENDAR_NAME = "CALENDAR_NAME";

    string COL_CALENDAR = "CALENDAR";

    // TABLE_LOCKS columns names
    string COL_LOCK_NAME = "LOCK_NAME";

    // TABLE_LOCKS columns names
    string COL_LAST_CHECKIN_TIME = "LAST_CHECKIN_TIME";

    string COL_CHECKIN_INTERVAL = "CHECKIN_INTERVAL";

    // MISC CONSTANTS
    string DEFAULT_TABLE_PREFIX = "QRTZ_";

    // STATES
    string STATE_WAITING = "WAITING";

    string STATE_ACQUIRED = "ACQUIRED";

    string STATE_EXECUTING = "EXECUTING";

    string STATE_COMPLETE = "COMPLETE";

    string STATE_BLOCKED = "BLOCKED";

    string STATE_ERROR = "ERROR";

    string STATE_PAUSED = "PAUSED";

    string STATE_PAUSED_BLOCKED = "PAUSED_BLOCKED";

    string STATE_DELETED = "DELETED";

    /**
     * @deprecated Whether a trigger has misfired is no longer a state, but 
     * rather now identified dynamically by whether the trigger's next fire 
     * time is more than the misfire threshold time in the past.
     */
    string STATE_MISFIRED = "MISFIRED";

    string ALL_GROUPS_PAUSED = "_$_ALL_GROUPS_PAUSED_$_";

    // TRIGGER TYPES
    /** Simple Trigger type. */
    string TTYPE_SIMPLE = "SIMPLE";

    /** Cron Trigger type. */
    string TTYPE_CRON = "CRON";

    /** Calendar Interval Trigger type. */
    string TTYPE_CAL_INT = "CAL_INT";

    /** Daily Time Interval Trigger type. */
    string TTYPE_DAILY_TIME_INT = "DAILY_I";

    /** A general blob Trigger type. */
    string TTYPE_BLOB = "BLOB";
}

// EOF
