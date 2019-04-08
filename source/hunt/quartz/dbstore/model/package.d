module hunt.quartz.dbstore.model;

public import hunt.quartz.dbstore.model.BlobTriggers;
public import hunt.quartz.dbstore.model.Calendars;
public import hunt.quartz.dbstore.model.CronTriggers;
public import hunt.quartz.dbstore.model.FiredTriggers;
public import hunt.quartz.dbstore.model.JobDetails;
public import hunt.quartz.dbstore.model.Locks;
public import hunt.quartz.dbstore.model.PausedTriggerGrps;
public import hunt.quartz.dbstore.model.SchedulerState;
public import hunt.quartz.dbstore.model.SimpleTriggers;
public import hunt.quartz.dbstore.model.SimpPropertiesTriggers;
public import hunt.quartz.dbstore.model.Triggers;



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
    enum string MODEL_JOB_DETAILS = JobDetails.stringof;

    enum string MODEL_TRIGGERS = Triggers.stringof;

    enum string MODEL_SIMPLE_TRIGGERS = SimpleTriggers.stringof;

    enum string MODEL_SIMPLE_PROPERTIES_TRIGGERS = SimpPropertiesTriggers.stringof;

    enum string MODEL_CRON_TRIGGERS = CronTriggers.stringof;

    enum string MODEL_BLOB_TRIGGERS = BlobTriggers.stringof;

    enum string MODEL_FIRED_TRIGGERS = FiredTriggers.stringof;

    enum string MODEL_CALENDARS = Calendars.stringof;

    enum string MODEL_PAUSED_TRIGGERS = PausedTriggerGrps.stringof;

    enum string MODEL_LOCKS = Locks.stringof;

    enum string MODEL_SCHEDULER_STATE = SchedulerState.stringof;


    // MODEL_JOB_DETAILS columns names
   
    enum string FIELD_SCHEDULER_NAME = JobDetails.schedulerName.stringof; // "SCHED_NAME";
    
    enum string FIELD_JOB_NAME = JobDetails.jobName.stringof; // "JOB_NAME";

    enum string FIELD_JOB_GROUP = JobDetails.jobGroup.stringof; // "JOB_GROUP";

    enum string FIELD_IS_DURABLE = JobDetails.isDurable.stringof; // "IS_DURABLE";

    enum string FIELD_IS_VOLATILE =  "IS_VOLATILE";

    enum string FIELD_IS_NONCONCURRENT = JobDetails.isNonconcurrent.stringof; // "IS_NONCONCURRENT";

    enum string FIELD_IS_UPDATE_DATA = JobDetails.isUpdateData.stringof; // "IS_UPDATE_DATA";

    enum string FIELD_REQUESTS_RECOVERY = JobDetails.requestsRecovery.stringof; // "REQUESTS_RECOVERY";

    enum string FIELD_JOB_DATAMAP = JobDetails.jobData.stringof; // "JOB_DATA";

    enum string FIELD_JOB_CLASS = JobDetails.jobClassName.stringof; // "JOB_CLASS_NAME";

    enum string FIELD_DESCRIPTION = JobDetails.description.stringof; // "DESCRIPTION";

    // MODEL_TRIGGERS columns names
    enum string FIELD_TRIGGER_NAME =  Triggers.triggerName.stringof; // "TRIGGER_NAME";

    enum string FIELD_TRIGGER_GROUP = Triggers.triggerGroup.stringof; // "TRIGGER_GROUP";

    enum string FIELD_NEXT_FIRE_TIME = Triggers.nextFireTime.stringof; // "NEXT_FIRE_TIME";

    enum string FIELD_PREV_FIRE_TIME = Triggers.prevFireTime.stringof; // "PREV_FIRE_TIME";

    enum string FIELD_TRIGGER_STATE = Triggers.triggerState.stringof; // "TRIGGER_STATE";

    enum string FIELD_TRIGGER_TYPE = Triggers.triggerType.stringof; // "TRIGGER_TYPE";

    enum string FIELD_START_TIME = Triggers.startTime.stringof; // "START_TIME";

    enum string FIELD_END_TIME = Triggers.endTime.stringof; // "END_TIME";

    enum string FIELD_PRIORITY = Triggers.priority.stringof; // "PRIORITY";

    enum string FIELD_MISFIRE_INSTRUCTION = Triggers.misfireInstruction.stringof; // "MISFIRE_INSTR";

    // enum string ALIAS_FIELD_NEXT_FIRE_TIME = "ALIAS_NXT_FR_TM";

    // MODEL_SIMPLE_TRIGGERS columns names
    enum string FIELD_REPEAT_COUNT = SimpleTriggers.repeatCount.stringof; // "REPEAT_COUNT";

    enum string FIELD_REPEAT_INTERVAL = SimpleTriggers.repeatInterval.stringof; // "REPEAT_INTERVAL";

    enum string FIELD_TIMES_TRIGGERED = SimpleTriggers.timesTriggered.stringof; // "TIMES_TRIGGERED";


    // TABLE_SIMPLE_PROPERTIES_TRIGGERS columns names
    enum string FIELD_STR_PROP_1 = SimpPropertiesTriggers.strProp1.stringof;
    enum string FIELD_STR_PROP_2 = SimpPropertiesTriggers.strProp2.stringof;
    enum string FIELD_STR_PROP_3 = SimpPropertiesTriggers.strProp3.stringof;
    enum string FIELD_INT_PROP_1 = SimpPropertiesTriggers.intProp1.stringof;
    enum string FIELD_INT_PROP_2 = SimpPropertiesTriggers.intProp2.stringof;
    enum string FIELD_LONG_PROP_1 = SimpPropertiesTriggers.longProp1.stringof;
    enum string FIELD_LONG_PROP_2 = SimpPropertiesTriggers.longProp2.stringof;
    enum string FIELD_DEC_PROP_1 = SimpPropertiesTriggers.decProp1.stringof;
    enum string FIELD_DEC_PROP_2 = SimpPropertiesTriggers.decProp2.stringof;
    enum string FIELD_BOOL_PROP_1 = SimpPropertiesTriggers.boolProp1.stringof;
    enum string FIELD_BOOL_PROP_2 = SimpPropertiesTriggers.boolProp2.stringof;


    // MODEL_CRON_TRIGGERS columns names
    enum string FIELD_CRON_EXPRESSION = CronTriggers.cronExpression.stringof; // "CRON_EXPRESSION";

    enum string FIELD_TIME_ZONE_ID = CronTriggers.timeZoneId.stringof; // "TIME_ZONE_ID";

    // MODEL_BLOB_TRIGGERS columns names
    enum string FIELD_BLOB = BlobTriggers.blogData.stringof; // "BLOB_DATA";

    // MODEL_FIRED_TRIGGERS columns names
    enum string FIELD_INSTANCE_NAME = FiredTriggers.instanceName.stringof; // "INSTANCE_NAME";

    enum string FIELD_FIRED_TIME = FiredTriggers.firedTime.stringof; // "FIRED_TIME";

    enum string FIELD_SCHED_TIME = FiredTriggers.schedTime.stringof; // "SCHED_TIME";
    
    enum string FIELD_ENTRY_ID = FiredTriggers.entryId.stringof; // "ENTRY_ID";

    enum string FIELD_ENTRY_STATE = FiredTriggers.state.stringof; // "STATE";

    // MODEL_CALENDARS columns names
    enum string FIELD_CALENDAR_NAME = Calendars.calendarName.stringof; // "CALENDAR_NAME";

    enum string FIELD_CALENDAR = Calendars.calendar.stringof; // "CALENDAR";

    // MODEL_LOCKS columns names
    enum string FIELD_LOCK_NAME = Locks.lockName.stringof; // "LOCK_NAME";

    // MODEL_SCHEDULER_STATE columns names
    enum string FIELD_LAST_CHECKIN_TIME = SchedulerState.lastCheckinTime.stringof; // "LAST_CHECKIN_TIME";

    enum string FIELD_CHECKIN_INTERVAL = SchedulerState.checkinInterval.stringof; // "CHECKIN_INTERVAL";

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
