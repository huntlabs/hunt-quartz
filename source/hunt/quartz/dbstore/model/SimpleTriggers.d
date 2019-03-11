module hunt.quartz.dbstore.model.SimpleTriggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_SIMPLE_TRIGGERS)
class SimpleTriggers : Model {
    mixin MakeModel;

    // @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    // string schedulerName;

    // @PrimaryKey @Column(TableConstants.COL_LOCK_NAME)
    // string lockName;
}
