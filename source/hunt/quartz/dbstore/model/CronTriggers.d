module hunt.quartz.dbstore.model.CronTriggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_CRON_TRIGGERS)
class CronTriggers : Model {
    mixin MakeModel;

    // @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    // string schedulerName;

    // @PrimaryKey @Column(TableConstants.COL_LOCK_NAME)
    // string lockName;
}