module hunt.quartz.dbstore.model.Triggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_TRIGGERS)
class Triggers : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_NAME)
    string triggerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_GROUP)
    string triggerGroup;

    @Column(TableConstants.COL_JOB_NAME)
    string jobName;

    @Column(TableConstants.COL_JOB_GROUP)
    string jobGroup;

    @Column(TableConstants.COL_DESCRIPTION)
    string description;

    @Column(TableConstants.COL_NEXT_FIRE_TIME)
    long nextFireTime;

    @Column(TableConstants.COL_PREV_FIRE_TIME)
    long prevFireTime;
    
    @Column(TableConstants.COL_PRIORITY)
    int priority;

    @Column(TableConstants.COL_TRIGGER_STATE)
    string triggerState;

    @Column(TableConstants.COL_TRIGGER_TYPE)
    string triggerType;

    @Column(TableConstants.COL_START_TIME)
    long startTime;

    @Column(TableConstants.COL_END_TIME)
    long endTime;

    @Column(TableConstants.COL_CALENDAR_NAME)
    string calendarName;

    @Column(TableConstants.COL_MISFIRE_INSTRUCTION)
    short misfireInstruction;
    
    @Column(TableConstants.COL_JOB_DATAMAP)
    ubyte[] jobData;

}

