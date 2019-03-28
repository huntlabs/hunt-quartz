module hunt.quartz.dbstore.model.SimpPropertiesTrigger;

import hunt.quartz.dbstore.TableConstants;
import hunt.entity;

@Table(TableConstants.TABLE_SIMPLE_PROPERTIES_TRIGGERS)
class SimpPropertiesTrigger : Model {
    mixin MakeModel;

    @PrimaryKey @Column(TableConstants.COL_SCHEDULER_NAME)
    string schedulerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_NAME)
    string triggerName;

    @PrimaryKey @Column(TableConstants.COL_TRIGGER_GROUP)
    string triggerGroup;

    @Column(TableConstants.COL_STR_PROP_1)
    string strProp1;

    @Column(TableConstants.COL_STR_PROP_2)
    string strProp2;

    @Column(TableConstants.COL_STR_PROP_3)
    string strProp3;

    @Column(TableConstants.COL_INT_PROP_1)
    int intProp1;

    @Column(TableConstants.COL_INT_PROP_2)
    int intProp2;

    @Column(TableConstants.COL_LONG_PROP_1)
    long longProp1;

    @Column(TableConstants.COL_INT_PROP_2)
    long longProp2;

    @Column(TableConstants.COL_DEC_PROP_1)
    long decProp1;

    @Column(TableConstants.COL_DEC_PROP_2)
    long decProp2;

    @Column(TableConstants.COL_BOOL_PROP_1)
    bool boolProp1;

    @Column(TableConstants.COL_BOOL_PROP_2)
    bool boolProp2;

}