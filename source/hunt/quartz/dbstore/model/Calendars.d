module hunt.quartz.dbstore.model.Calendars;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_CALENDARS)
class Calendars : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_CALENDAR_NAME)
    string calendarName;

    @Column(TableConstants.COL_CALENDAR)
    ubyte[] calendar;
}