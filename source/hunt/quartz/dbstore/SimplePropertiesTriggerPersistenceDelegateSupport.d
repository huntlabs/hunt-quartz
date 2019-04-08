/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module hunt.quartz.dbstore.SimplePropertiesTriggerPersistenceDelegateSupport;

import hunt.quartz.dbstore.model;
import hunt.quartz.dbstore.SimplePropertiesTriggerProperties;
import hunt.quartz.dbstore.StdSqlConstants;
import hunt.quartz.dbstore.TableConstants;
import hunt.quartz.dbstore.TriggerPersistenceDelegate;

import hunt.quartz.JobDetail;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.TriggerKey;
import hunt.quartz.spi.OperableTrigger;

import hunt.Exceptions;
import hunt.entity.EntityManager;
import hunt.entity.NativeQuery;
import hunt.entity.eql.EqlQuery;
import hunt.database.driver.ResultSet;
import hunt.database.Row;


/**
 * A base implementation of {@link TriggerPersistenceDelegate} that persists 
 * trigger fields in the "QRTZ_SIMPROP_TRIGGERS" table.  This allows extending
 * concrete classes to simply implement a couple methods that do the work of
 * getting/setting the trigger's fields, and creating the {@link ScheduleBuilder}
 * for the particular type of trigger. 
 * 
 * @see CalendarIntervalTriggerPersistenceDelegate for an example extension
 * 
 * @author jhouse
 */
abstract class SimplePropertiesTriggerPersistenceDelegateSupport : TriggerPersistenceDelegate {

    protected enum string SELECT_SIMPLE_PROPS_TRIGGER = "SELECT *" ~ " FROM "
        ~ ModelConstants.MODEL_SIMPLE_PROPERTIES_TRIGGERS ~ " t WHERE t."
        ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ StdSqlConstants.SCHED_NAME_SUBST
        ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    protected enum string DELETE_SIMPLE_PROPS_TRIGGER = "DELETE FROM "
        ~ ModelConstants.MODEL_SIMPLE_PROPERTIES_TRIGGERS ~ " t WHERE t."
        ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ StdSqlConstants.SCHED_NAME_SUBST
        ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    protected enum string INSERT_SIMPLE_PROPS_TRIGGER = "INSERT INTO "
        ~ ModelConstants.MODEL_SIMPLE_PROPERTIES_TRIGGERS ~ " t (t."
        ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", t."
        ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ", t."
        ~ ModelConstants.FIELD_STR_PROP_1 ~ ", t." ~ ModelConstants.FIELD_STR_PROP_2 ~ ", t." 
        ~ ModelConstants.FIELD_STR_PROP_3 ~ ", t."
        ~ ModelConstants.FIELD_INT_PROP_1 ~ ", t." ~ ModelConstants.FIELD_INT_PROP_2 ~ ", t."
        ~ ModelConstants.FIELD_LONG_PROP_1 ~ ", t." ~ ModelConstants.FIELD_LONG_PROP_2 ~ ", t."
        ~ ModelConstants.FIELD_DEC_PROP_1 ~ ", t." ~ ModelConstants.FIELD_DEC_PROP_2 ~ ", t."
        ~ ModelConstants.FIELD_BOOL_PROP_1 ~ ", t." ~ ModelConstants.FIELD_BOOL_PROP_2 
        ~ ") " ~ " VALUES(" ~ StdSqlConstants.SCHED_NAME_SUBST ~ ", ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    protected enum string UPDATE_SIMPLE_PROPS_TRIGGER = "UPDATE "
        ~ ModelConstants.MODEL_SIMPLE_PROPERTIES_TRIGGERS ~ " t SET t."
        ~ ModelConstants.FIELD_STR_PROP_1 ~ " = ?, t." ~ ModelConstants.FIELD_STR_PROP_2 ~ " = ?, t." 
        ~ ModelConstants.FIELD_STR_PROP_3 ~ " = ?, t."
        ~ ModelConstants.FIELD_INT_PROP_1 ~ " = ?, t." ~ ModelConstants.FIELD_INT_PROP_2 ~ " = ?, t."
        ~ ModelConstants.FIELD_LONG_PROP_1 ~ " = ?, t." ~ ModelConstants.FIELD_LONG_PROP_2 ~ " = ?, t."
        ~ ModelConstants.FIELD_DEC_PROP_1 ~ " = ?, t." ~ ModelConstants.FIELD_DEC_PROP_2 ~ " = ?, t."
        ~ ModelConstants.FIELD_BOOL_PROP_1 ~ " = ?, t." ~ ModelConstants.FIELD_BOOL_PROP_2 
        ~ " = ? WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ StdSqlConstants.SCHED_NAME_SUBST
        ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME
        ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";
    
    protected string tablePrefix;

    protected string schedNameLiteral;

    void initialize(string theTablePrefix, string schedName) {
        this.tablePrefix = theTablePrefix;
        this.schedNameLiteral = "'" ~ schedName ~ "'";
    }

    protected abstract SimplePropertiesTriggerProperties getTriggerProperties(OperableTrigger trigger);
    
    protected abstract TriggerPropertyBundle getTriggerPropertyBundle(SimplePropertiesTriggerProperties properties);

    protected final string rtp(string query) {
        return format(query, schedNameLiteral);
    }
    
    int deleteExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {
        EqlQuery!(SimpPropertiesTriggers) query = conn.createQuery!(SimpPropertiesTriggers)(
            rtp(DELETE_SIMPLE_PROPS_TRIGGER));

        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());
        return query.exec();
    }

    int insertExtendedTriggerProperties(Connection conn, 
        OperableTrigger trigger, string state, JobDetail jobDetail) {

        SimplePropertiesTriggerProperties properties = getTriggerProperties(trigger);
        
        EqlQuery!(SimpPropertiesTriggers) query = conn.createQuery!(SimpPropertiesTriggers)(
            rtp(INSERT_SIMPLE_PROPS_TRIGGER));

        query.setParameter(1, trigger.getKey().getName());
        query.setParameter(2, trigger.getKey().getGroup());
        query.setParameter(3, properties.getString1());
        query.setParameter(4, properties.getString2());
        query.setParameter(5, properties.getString3());
        query.setParameter(6, properties.getInt1());
        query.setParameter(7, properties.getInt2());
        query.setParameter(8, properties.getLong1());
        query.setParameter(9, properties.getLong2());
        query.setParameter(10, properties.getDecimal1());
        query.setParameter(11, properties.getDecimal2());
        query.setParameter(12, properties.isBoolean1());
        query.setParameter(13, properties.isBoolean2());

        return query.exec();
    }

    TriggerPropertyBundle loadExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {
        EqlQuery!(SimpPropertiesTriggers) query = conn.createQuery!(SimpPropertiesTriggers)(
            rtp(SELECT_SIMPLE_PROPS_TRIGGER));
        
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());

        SimpPropertiesTriggers trigger = query.getSingleResult();
    
        if (trigger !is null) {
            SimplePropertiesTriggerProperties properties = new SimplePropertiesTriggerProperties();
                
            properties.setString1(trigger.strProp1);
            properties.setString2(trigger.strProp2);
            properties.setString3(trigger.strProp3);
            properties.setInt1(trigger.intProp1);
            properties.setInt2(trigger.intProp2);
            properties.setLong1(trigger.longProp1);
            properties.setLong2(trigger.longProp2);
            properties.setDecimal1(trigger.decProp1);
            properties.setDecimal2(trigger.decProp2);
            properties.setBoolean1(trigger.boolProp1);
            properties.setBoolean2(trigger.boolProp2);
            
            return getTriggerPropertyBundle(properties);
        }
        
        throw new IllegalStateException("No record found for selection of Trigger with key: '" 
            ~ triggerKey.toString() ~ "' and statement: " ~ rtp(SELECT_SIMPLE_PROPS_TRIGGER);

    }

    int updateExtendedTriggerProperties(Connection conn, OperableTrigger trigger, string state, JobDetail jobDetail) {
        SimplePropertiesTriggerProperties properties = getTriggerProperties(trigger);

        EqlQuery!(SimpPropertiesTriggers) query = conn.createQuery!(SimpPropertiesTriggers)(
            rtp(UPDATE_SIMPLE_PROPS_TRIGGER));
        

        query.setParameter(1, properties.getString1());
        query.setParameter(2, properties.getString2());
        query.setParameter(3, properties.getString3());
        query.setParameter(4, properties.getInt1());
        query.setParameter(5, properties.getInt2());
        query.setParameter(6, properties.getLong1());
        query.setParameter(7, properties.getLong2());
        query.setParameter(8, properties.getDecimal1());
        query.setParameter(9, properties.getDecimal2());
        query.setParameter(10, properties.isBoolean1());
        query.setParameter(11, properties.isBoolean2());
        query.setParameter(12, trigger.getKey().getName());
        query.setParameter(13, trigger.getKey().getGroup());

        return query.exec();
    }

}
