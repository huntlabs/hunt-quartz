module hunt.quartz.dbstore.model.SimpleTriggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_SIMPLE_TRIGGERS)
class SimpleTriggers : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_NAME)
    string triggerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_GROUP)
    string triggerGroup;

    @Column(TableConstants.COL_REPEAT_COUNT)
    long repeatCount;

    @Column(TableConstants.COL_REPEAT_INTERVAL)
    long repeatInterval;

    @Column(TableConstants.COL_TIMES_TRIGGERED)
    long timesTriggered;
}
