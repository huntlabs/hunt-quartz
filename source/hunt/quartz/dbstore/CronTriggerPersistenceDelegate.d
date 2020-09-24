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
module hunt.quartz.dbstore.CronTriggerPersistenceDelegate;

import hunt.quartz.dbstore.model;
import hunt.quartz.dbstore.StdSqlConstants;
import hunt.quartz.dbstore.TableConstants;
import hunt.quartz.dbstore.TriggerPersistenceDelegate;

import hunt.quartz.CronScheduleBuilder;
import hunt.quartz.CronTrigger;
import hunt.quartz.JobDetail;
import hunt.quartz.TriggerKey;
import hunt.quartz.impl.triggers.CronTriggerImpl;
import hunt.quartz.spi.OperableTrigger;

import hunt.Exceptions;
import hunt.entity.EntityManager;
import hunt.entity.NativeQuery;
import hunt.entity.eql.EqlQuery;
import hunt.database;
import hunt.time.ZoneId;
import hunt.time.ZoneRegion;

import std.format;

class CronTriggerPersistenceDelegate : TriggerPersistenceDelegate {

    protected string tablePrefix;
    protected string schedNameLiteral;

    void initialize(string theTablePrefix, string schedName) {
        this.tablePrefix = theTablePrefix;
        this.schedNameLiteral = "'" ~ schedName ~ "'";
    }

    string getHandledTriggerTypeDiscriminator() {
        return TableConstants.TTYPE_CRON;
    }

    bool canHandleTriggerType(OperableTrigger trigger) {
        CronTriggerImpl s = cast(CronTriggerImpl)trigger;
        if(s !is null) {
            return !s.hasAdditionalProperties();
        }
        return false;
    }

    int deleteExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {
        EqlQuery!(CronTriggers) query = conn.createQuery!(CronTriggers)(
            format(StdSqlConstants.DELETE_CRON_TRIGGER, schedNameLiteral));

        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());

        return query.exec();
    }

    int insertExtendedTriggerProperties(Connection conn, 
        OperableTrigger trigger, string state, JobDetail jobDetail) {

        EqlQuery!(CronTriggers) query = conn.createQuery!(CronTriggers)(
            format(StdSqlConstants.INSERT_CRON_TRIGGER, schedNameLiteral));

        CronTrigger cronTrigger = cast(CronTrigger)trigger;
        
        query.setParameter(1, trigger.getKey().getName());
        query.setParameter(2, trigger.getKey().getGroup());
        query.setParameter(3, cronTrigger.getCronExpression());
        query.setParameter(4, cronTrigger.getTimeZone().getId());

        return query.exec();
    }

    TriggerPropertyBundle loadExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {

        EqlQuery!(CronTriggers) query = conn.createQuery!(CronTriggers)(
            format(StdSqlConstants.SELECT_CRON_TRIGGER, schedNameLiteral));
        
        query.setParameter(1, triggerKey.getName());
        query.setParameter(2, triggerKey.getGroup());

        CronTriggers trigger = query.getSingleResult();

        if (trigger !is null) {
            string cronExpr = trigger.cronExpression;
            string timeZoneId = trigger.timeZoneId;

            CronScheduleBuilder cb = CronScheduleBuilder.cronSchedule(cronExpr);
            
            if (timeZoneId !is null) 
                cb.inTimeZone(ZoneRegion.of(timeZoneId));
            
            return new TriggerPropertyBundle(cb, null, null);
        }
        
        throw new IllegalStateException("No record found for selection of Trigger with key: '" 
            ~ triggerKey.toString() ~ "' and statement: " 
            ~ format(StdSqlConstants.SELECT_CRON_TRIGGER, schedNameLiteral));
    }

    int updateExtendedTriggerProperties(Connection conn, 
        OperableTrigger trigger, string state, JobDetail jobDetail) {

        CronTrigger cronTrigger = cast(CronTrigger)trigger;
        EqlQuery!(CronTriggers) query = conn.createQuery!(CronTriggers)(
            format(StdSqlConstants.UPDATE_CRON_TRIGGER, schedNameLiteral));
    
        query.setParameter(1, cronTrigger.getCronExpression());
        query.setParameter(2, cronTrigger.getTimeZone().getId());
        query.setParameter(3, trigger.getKey().getName());
        query.setParameter(4, trigger.getKey().getGroup());

        return query.exec();
    }

}
