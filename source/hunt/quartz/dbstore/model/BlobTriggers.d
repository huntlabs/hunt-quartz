module hunt.quartz.dbstore.model.BlobTriggers;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_BLOB_TRIGGERS)
class BlobTriggers : Model {
    mixin MakeModel;

    // @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    // string schedulerName;

    // @PrimaryKey @Column(TableConstants.COL_LOCK_NAME)
    // string lockName;
}