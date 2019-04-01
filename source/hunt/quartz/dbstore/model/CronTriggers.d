module hunt.quartz.dbstore.model.CronTriggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_CRON_TRIGGERS)
class CronTriggers : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_NAME)
    string triggerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_GROUP)
    string triggerGroup;

    @Column(TableConstants.COL_CRON_EXPRESSION)
    string cronExpression;

    @Column(TableConstants.COL_TIME_ZONE_ID)
    string timeZoneId;
}