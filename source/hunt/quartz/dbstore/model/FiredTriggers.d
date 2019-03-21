module hunt.quartz.dbstore.model.FiredTriggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_FIRED_TRIGGERS)
class FiredTriggers : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_ENTRY_ID)
    string entryId;

    @Column(TableConstants.COL_TRIGGER_NAME)
    string triggerName;

    @Column(TableConstants.COL_TRIGGER_GROUP)
    string triggerGroup;

    @Column(TableConstants.COL_INSTANCE_NAME)
    string instanceName;

    @Column(TableConstants.COL_FIRED_TIME)
    long firedTime;
    
    @Column(TableConstants.COL_SCHED_TIME)
    long schedTime;
    
    @Column(TableConstants.COL_PRIORITY)
    int priority;

    @Column(TableConstants.COL_ENTRY_STATE)
    string state;

    @Column(TableConstants.COL_JOB_NAME)
    string jobName;

    @Column(TableConstants.COL_JOB_GROUP)
    string jobGroup;

    @Column(TableConstants.COL_IS_NONCONCURRENT)
    bool isNonconcurrent;

    @Column(TableConstants.COL_REQUESTS_RECOVERY)
    bool requestsRecovery;
}