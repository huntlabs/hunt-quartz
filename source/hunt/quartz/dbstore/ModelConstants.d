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

module hunt.quartz.dbstore.ModelConstants;

/**
 */
struct ModelConstants {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    // Model names
    enum string MODEL_JOB_DETAILS = "JOB_DETAILS";

    enum string MODEL_TRIGGERS = "TRIGGERS";

    enum string MODEL_SIMPLE_TRIGGERS = "SIMPLE_TRIGGERS";

    enum string MODEL_CRON_TRIGGERS = "CRON_TRIGGERS";

    enum string MODEL_BLOB_TRIGGERS = "BLOB_TRIGGERS";

    enum string MODEL_FIRED_TRIGGERS = "FIRED_TRIGGERS";

    enum string MODEL_CALENDARS = "CALENDARS";

    enum string MODEL_PAUSED_TRIGGERS = "PAUSED_TRIGGER_GRPS";

    enum string MODEL_LOCKS = "LOCKS";

    enum string MODEL_SCHEDULER_STATE = "SCHEDULER_STATE";

    // MODEL_JOB_DETAILS columns names
    
    enum string FIELD_SCHEDULER_NAME = "SCHED_NAME";
    
    enum string FIELD_JOB_NAME = "JOB_NAME";

    enum string FIELD_JOB_GROUP = "JOB_GROUP";

    enum string FIELD_IS_DURABLE = "IS_DURABLE";

    enum string FIELD_IS_VOLATILE = "IS_VOLATILE";

    enum string FIELD_IS_NONCONCURRENT = "IS_NONCONCURRENT";

    enum string FIELD_IS_UPDATE_DATA = "IS_UPDATE_DATA";

    enum string FIELD_REQUESTS_RECOVERY = "REQUESTS_RECOVERY";

    enum string FIELD_JOB_DATAMAP = "JOB_DATA";

    enum string FIELD_JOB_CLASS = "JOB_CLASS_NAME";

    enum string FIELD_DESCRIPTION = "DESCRIPTION";

    // MODEL_TRIGGERS columns names
    enum string FIELD_TRIGGER_NAME = "TRIGGER_NAME";

    enum string FIELD_TRIGGER_GROUP = "TRIGGER_GROUP";

    enum string FIELD_NEXT_FIRE_TIME = "NEXT_FIRE_TIME";

    enum string FIELD_PREV_FIRE_TIME = "PREV_FIRE_TIME";

    enum string FIELD_TRIGGER_STATE = "TRIGGER_STATE";

    enum string FIELD_TRIGGER_TYPE = "TRIGGER_TYPE";

    enum string FIELD_START_TIME = "START_TIME";

    enum string FIELD_END_TIME = "END_TIME";

    enum string FIELD_PRIORITY = "PRIORITY";

    enum string FIELD_MISFIRE_INSTRUCTION = "MISFIRE_INSTR";

    enum string ALIAS_FIELD_NEXT_FIRE_TIME = "ALIAS_NXT_FR_TM";

    // MODEL_SIMPLE_TRIGGERS columns names
    enum string FIELD_REPEAT_COUNT = "REPEAT_COUNT";

    enum string FIELD_REPEAT_INTERVAL = "REPEAT_INTERVAL";

    enum string FIELD_TIMES_TRIGGERED = "TIMES_TRIGGERED";

    // MODEL_CRON_TRIGGERS columns names
    enum string FIELD_CRON_EXPRESSION = "CRON_EXPRESSION";

    // MODEL_BLOB_TRIGGERS columns names
    enum string FIELD_BLOB = "BLOB_DATA";

    enum string FIELD_TIME_ZONE_ID = "TIME_ZONE_ID";

    // MODEL_FIRED_TRIGGERS columns names
    enum string FIELD_INSTANCE_NAME = "INSTANCE_NAME";

    enum string FIELD_FIRED_TIME = "FIRED_TIME";

    enum string FIELD_SCHED_TIME = "SCHED_TIME";
    
    enum string FIELD_ENTRY_ID = "ENTRY_ID";

    enum string FIELD_ENTRY_STATE = "STATE";

    // MODEL_CALENDARS columns names
    enum string FIELD_CALENDAR_NAME = "CALENDAR_NAME";

    enum string FIELD_CALENDAR = "CALENDAR";

    // MODEL_LOCKS columns names
    enum string FIELD_LOCK_NAME = "LOCK_NAME";

    // MODEL_LOCKS columns names
    enum string FIELD_LAST_CHECKIN_TIME = "LAST_CHECKIN_TIME";

    enum string FIELD_CHECKIN_INTERVAL = "CHECKIN_INTERVAL";

    // MISC CONSTANTS
    enum string DEFAULT_MODEL_PREFIX = "QRTZ_";

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
