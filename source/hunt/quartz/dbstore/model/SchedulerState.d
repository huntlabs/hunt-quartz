module hunt.quartz.dbstore.model.SchedulerState;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_SCHEDULER_STATE)
class SchedulerState : Model {
    mixin MakeModel;

    // @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    // string schedulerName;

    // @PrimaryKey @Column(TableConstants.COL_LOCK_NAME)
    // string lockName;
}
