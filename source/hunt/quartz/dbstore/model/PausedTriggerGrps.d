module hunt.quartz.dbstore.model.PausedTriggerGrps;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_PAUSED_TRIGGERS)
class PausedTriggerGrps : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_GROUP)
    string triggerGroup;
}
