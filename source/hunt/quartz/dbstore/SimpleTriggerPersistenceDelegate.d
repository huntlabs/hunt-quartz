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
module hunt.quartz.dbstore.SimpleTriggerPersistenceDelegate;

import hunt.quartz.dbstore.model;
import hunt.quartz.dbstore.StdSqlConstants;
import hunt.quartz.dbstore.TableConstants;
import hunt.quartz.dbstore.TriggerPersistenceDelegate;

import hunt.quartz.JobDetail;
import hunt.quartz.SimpleScheduleBuilder;
import hunt.quartz.SimpleTrigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.impl.triggers.SimpleTriggerImpl;
import hunt.quartz.spi.OperableTrigger;

import hunt.entity.EntityManager;
import hunt.entity.NativeQuery;
import hunt.entity.eql.EqlQuery;
import hunt.database;

import hunt.Exceptions;
import hunt.Integer;

import std.format;

/**
*/
class SimpleTriggerPersistenceDelegate : TriggerPersistenceDelegate {

    protected string tablePrefix;
    protected string schedNameLiteral;

    void initialize(string theTablePrefix, string schedName) {
        this.tablePrefix = theTablePrefix;
        this.schedNameLiteral = "'" ~ schedName ~ "'";
    }

    string getHandledTriggerTypeDiscriminator() {
        return TableConstants.TTYPE_SIMPLE;
    }

    bool canHandleTriggerType(OperableTrigger trigger) {
        SimpleTriggerImpl s = cast(SimpleTriggerImpl)trigger;
        if(s !is null) {
            return !s.hasAdditionalProperties();
        }
        return false;
    }

    int deleteExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {
        EqlQuery!(SimpleTriggers)  query = conn.createQuery!(SimpleTriggers)(rtp(StdSqlConstants.DELETE_SIMPLE_TRIGGER));
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());
        return query.exec();
    }

    int insertExtendedTriggerProperties(Connection conn, OperableTrigger trigger, 
        string state, JobDetail jobDetail) {

        SimpleTrigger simpleTrigger = cast(SimpleTrigger)trigger;
        assert(simpleTrigger !is null);

        EqlQuery!(SimpleTriggers)  query = conn.createQuery!(SimpleTriggers)(rtp(StdSqlConstants.INSERT_SIMPLE_TRIGGER));
        query.setParameter(1, trigger.getKey().getName());
        query.setParameter(2, trigger.getKey().getGroup());
        query.setParameter(3, simpleTrigger.getRepeatCount());
        query.setParameter(4, simpleTrigger.getRepeatInterval());
        query.setParameter(5, simpleTrigger.getTimesTriggered());

        int r = query.exec();
        return r;
    }

    protected final string rtp(string query) {
        return format(query, schedNameLiteral);
    }

    TriggerPropertyBundle loadExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {
        EqlQuery!(SimpleTriggers)  query = conn.createQuery!(SimpleTriggers)(
            rtp(StdSqlConstants.SELECT_SIMPLE_TRIGGER));
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());
        SimpleTriggers rt = query.getSingleResult();
    
        if (rt is null) {
            throw new IllegalStateException("No record found for selection of Trigger with key: '" 
                ~ triggerKey.toString() 
                ~ "' and statement: " 
                ~ rtp(StdSqlConstants.SELECT_SIMPLE_TRIGGER));
        } else {
            int repeatCount = cast(int)rt.repeatCount;
            long repeatInterval = rt.repeatInterval;
            int timesTriggered = cast(int)rt.timesTriggered;

            SimpleScheduleBuilder sb = SimpleScheduleBuilder.simpleSchedule()
                .withRepeatCount(repeatCount)
                .withIntervalInMilliseconds(repeatInterval);
            
            string[] statePropertyNames = [ "timesTriggered" ];
            Object[] statePropertyValues = [ new Integer(timesTriggered) ];
            
            return new TriggerPropertyBundle(sb, statePropertyNames, statePropertyValues);
        }
        
    }

    int updateExtendedTriggerProperties(Connection conn, OperableTrigger trigger, 
        string state, JobDetail jobDetail) {

        SimpleTrigger simpleTrigger = cast(SimpleTrigger)trigger;
        assert(simpleTrigger !is null);

        EqlQuery!(SimpleTriggers)  query = conn.createQuery!(SimpleTriggers)(rtp(StdSqlConstants.UPDATE_SIMPLE_TRIGGER));
        query.setParameter(1, simpleTrigger.getRepeatCount());
        query.setParameter(2, simpleTrigger.getRepeatInterval());
        query.setParameter(3, simpleTrigger.getTimesTriggered());
        query.setParameter(4, simpleTrigger.getKey().getName());
        query.setParameter(5, simpleTrigger.getKey().getGroup());

        int r = query.exec();
        return r;
    }

}
