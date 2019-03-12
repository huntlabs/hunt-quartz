module hunt.quartz.dbstore.model.Calendars;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_CALENDARS)
class Calendars : Model {
    mixin MakeModel;

    // @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    // string COL_SCHEDULER_NAME;

    // @PrimaryKey @Column(TableConstants.COL_LOCK_NAME)
    // string lockName;
}