module hunt.quartz.dbstore.model.BlobTriggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_BLOB_TRIGGERS)
class BlobTriggers : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_NAME)
    string triggerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_GROUP)
    string triggerGroup;

    @Column(TableConstants.COL_BLOB)
    ubyte[] blogData;
}