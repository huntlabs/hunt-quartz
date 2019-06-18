module hunt.quartz.dbstore.model.JobDetails;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_JOB_DETAILS)
class JobDetails : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_JOB_NAME)
    string jobName;

    @PrimaryKey @Column(TableConstants.COL_JOB_GROUP)
    string jobGroup;

    @Column(TableConstants.COL_DESCRIPTION)
    string description;

    @Column(TableConstants.COL_JOB_CLASS)
    string jobClassName;

    @Column(TableConstants.COL_IS_DURABLE)
    bool isDurable;

    @Column(TableConstants.COL_IS_NONCONCURRENT)
    bool isNonconcurrent;

    @Column(TableConstants.COL_IS_UPDATE_DATA)
    bool isUpdateData;

    @Column(TableConstants.COL_REQUESTS_RECOVERY)
    bool requestsRecovery;

    @Column(TableConstants.COL_JOB_DATAMAP)
    ubyte[] jobData;

    // override string toString() {
    //     return cast(string)jobData;
    // }
}