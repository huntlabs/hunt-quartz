module hunt.quartz.dbstore.model.SimpropTriggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_SIMPROP_TRIGGERS)
class SimpropTriggers : Model {
    mixin MakeModel;

    // @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    // string schedulerName;

    // @PrimaryKey @Column(TableConstants.COL_LOCK_NAME)
    // string lockName;
}