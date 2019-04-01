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
    enum string TABLE_JOB_DETAILS = "job_details";

    enum string TABLE_TRIGGERS = "triggers";

    enum string TABLE_SIMPLE_TRIGGERS = "simple_triggers";

    enum string TABLE_SIMPLE_PROPERTIES_TRIGGERS = "simprop_triggers";

    enum string TABLE_CRON_TRIGGERS = "cron_triggers";

    enum string TABLE_BLOB_TRIGGERS = "blob_triggers";

    enum string TABLE_FIRED_TRIGGERS = "fired_triggers";

    enum string TABLE_CALENDARS = "calendars";

    enum string TABLE_PAUSED_TRIGGERS = "paused_trigger_grps";

    enum string TABLE_LOCKS = "locks";

    enum string TABLE_SCHEDULER_STATE = "scheduler_state";

    // TABLE_JOB_DETAILS columns names
    
    enum string COL_SCHEDULER_NAME = "sched_name";
    
    enum string COL_JOB_NAME = "job_name";

    enum string COL_JOB_GROUP = "job_group";

    enum string COL_IS_DURABLE = "is_durable";

    enum string COL_IS_VOLATILE = "is_volatile";

    enum string COL_IS_NONCONCURRENT = "is_nonconcurrent";

    enum string COL_IS_UPDATE_DATA = "is_update_data";

    enum string COL_REQUESTS_RECOVERY = "requests_recovery";

    enum string COL_JOB_DATAMAP = "job_data";

    enum string COL_JOB_CLASS = "job_class_name";

    enum string COL_DESCRIPTION = "description";

    // TABLE_TRIGGERS columns names
    enum string COL_TRIGGER_NAME = "trigger_name";

    enum string COL_TRIGGER_GROUP = "trigger_group";

    enum string COL_NEXT_FIRE_TIME = "next_fire_time";

    enum string COL_PREV_FIRE_TIME = "prev_fire_time";

    enum string COL_TRIGGER_STATE = "trigger_state";

    enum string COL_TRIGGER_TYPE = "trigger_type";

    enum string COL_START_TIME = "start_time";

    enum string COL_END_TIME = "end_time";

    enum string COL_PRIORITY = "priority";

    enum string COL_MISFIRE_INSTRUCTION = "misfire_instr";

    enum string ALIAS_COL_NEXT_FIRE_TIME = "alias_nxt_fr_tm";

    // TABLE_SIMPLE_TRIGGERS columns names
    enum string COL_REPEAT_COUNT = "repeat_count";

    enum string COL_REPEAT_INTERVAL = "repeat_interval";

    enum string COL_TIMES_TRIGGERED = "times_triggered";

    // TABLE_SIMPLE_PROPERTIES_TRIGGERS columns names
    enum string COL_STR_PROP_1 = "str_prop_1";
    enum string COL_STR_PROP_2 = "str_prop_2";
    enum string COL_STR_PROP_3 = "str_prop_3";
    enum string COL_INT_PROP_1 = "str_int_1";
    enum string COL_INT_PROP_2 = "str_int_2";
    enum string COL_LONG_PROP_1 = "str_long_1";
    enum string COL_LONG_PROP_2 = "str_long_2";
    enum string COL_DEC_PROP_1 = "str_dec_1";
    enum string COL_DEC_PROP_2 = "str_dec_2";
    enum string COL_BOOL_PROP_1 = "str_bool_1";
    enum string COL_BOOL_PROP_2 = "str_bool_2";


    // TABLE_CRON_TRIGGERS columns names
    enum string COL_CRON_EXPRESSION = "cron_expression";

    // TABLE_BLOB_TRIGGERS columns names
    enum string COL_BLOB = "blob_data";

    enum string COL_TIME_ZONE_ID = "time_zone_id";

    // TABLE_FIRED_TRIGGERS columns names
    enum string COL_INSTANCE_NAME = "instance_name";

    enum string COL_FIRED_TIME = "fired_time";

    enum string COL_SCHED_TIME = "sched_time";
    
    enum string COL_ENTRY_ID = "entry_id";

    enum string COL_ENTRY_STATE = "state";

    // TABLE_CALENDARS columns names
    enum string COL_CALENDAR_NAME = "calendar_name";

    enum string COL_CALENDAR = "calendar";

    // TABLE_LOCKS columns names
    enum string COL_LOCK_NAME = "lock_name";

    // TABLE_SCHEDULER_STATE columns names
    enum string COL_LAST_CHECKIN_TIME = "last_checkin_time";

    enum string COL_CHECKIN_INTERVAL = "checkin_interval";

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
