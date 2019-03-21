module hunt.quartz.dbstore.model.SchedulerState;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_SCHEDULER_STATE)
class SchedulerState : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;
    
    @PrimaryKey @Column(TableConstants.COL_INSTANCE_NAME)
    string instanceName;

    @Column(TableConstants.COL_LAST_CHECKIN_TIME)
    long lastCheckinTime;

    @Column(TableConstants.COL_CHECKIN_INTERVAL)
    long checkinInterval;
}
