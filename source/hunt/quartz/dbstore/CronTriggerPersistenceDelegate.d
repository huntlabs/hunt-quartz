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

import hunt.quartz.dbstore.StdSqlConstants;
import hunt.quartz.dbstore.TriggerPersistenceDelegate;

// import java.io.IOException;
// import java.sql.Connection;
// import java.sql.PreparedStatement;
// import java.sql.ResultSet;
// import java.sql.SQLException;
// import std.datetime : TimeZone;

import hunt.quartz.CronScheduleBuilder;
import hunt.quartz.CronTrigger;
import hunt.quartz.JobDetail;
import hunt.quartz.TriggerKey;
import hunt.quartz.impl.triggers.CronTriggerImpl;
import hunt.quartz.spi.OperableTrigger;

class CronTriggerPersistenceDelegate : TriggerPersistenceDelegate {

    protected string tablePrefix;
    protected string schedNameLiteral;

    void initialize(string theTablePrefix, string schedName) {
        this.tablePrefix = theTablePrefix;
        this.schedNameLiteral = "'" ~ schedName ~ "'";
    }

    string getHandledTriggerTypeDiscriminator() {
        return TTYPE_CRON;
    }

    bool canHandleTriggerType(OperableTrigger trigger) {
        CronTriggerImpl s = cast(CronTriggerImpl)trigger;
        if(s !is null) {
            return !s.hasAdditionalProperties();
        }
        return false;
    }

    int deleteExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {

        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(Util.rtp(DELETE_CRON_TRIGGER, tablePrefix, schedNameLiteral));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());

            return ps.executeUpdate();
        } finally {
            Util.closeStatement(ps);
        }
    }

    int insertExtendedTriggerProperties(Connection conn, OperableTrigger trigger, string state, JobDetail jobDetail) {

        CronTrigger cronTrigger = cast(CronTrigger)trigger;
        
        PreparedStatement ps = null;
        
        try {
            ps = conn.prepareStatement(Util.rtp(INSERT_CRON_TRIGGER, tablePrefix, schedNameLiteral));
            ps.setString(1, trigger.getKey().getName());
            ps.setString(2, trigger.getKey().getGroup());
            ps.setString(3, cronTrigger.getCronExpression());
            ps.setString(4, cronTrigger.getTimeZone().getID());

            return ps.executeUpdate();
        } finally {
            Util.closeStatement(ps);
        }
    }

    TriggerPropertyBundle loadExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {

        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            ps = conn.prepareStatement(Util.rtp(SELECT_CRON_TRIGGER, tablePrefix, schedNameLiteral));
            ps.setString(1, triggerKey.getName());
            ps.setString(2, triggerKey.getGroup());
            rs = ps.executeQuery();

            if (rs.next()) {
                string cronExpr = rs.getString(COL_CRON_EXPRESSION);
                string timeZoneId = rs.getString(COL_TIME_ZONE_ID);

                CronScheduleBuilder cb = CronScheduleBuilder.cronSchedule(cronExpr);
              
                if (timeZoneId !is null) 
                    cb.inTimeZone(TimeZone.getTimeZone(timeZoneId));
                
                return new TriggerPropertyBundle(cb, null, null);
            }
            
            throw new IllegalStateException("No record found for selection of Trigger with key: '" ~ triggerKey ~ "' and statement: " ~ Util.rtp(SELECT_CRON_TRIGGER, tablePrefix, schedNameLiteral));
        } finally {
            Util.closeResultSet(rs);
            Util.closeStatement(ps);
        }
    }

    int updateExtendedTriggerProperties(Connection conn, OperableTrigger trigger, string state, JobDetail jobDetail) {

        CronTrigger cronTrigger = cast(CronTrigger)trigger;
        
        PreparedStatement ps = null;

        try {
            ps = conn.prepareStatement(Util.rtp(UPDATE_CRON_TRIGGER, tablePrefix, schedNameLiteral));
            ps.setString(1, cronTrigger.getCronExpression());
            ps.setString(2, cronTrigger.getTimeZone().getID());
            ps.setString(3, trigger.getKey().getName());
            ps.setString(4, trigger.getKey().getGroup());
            
            return ps.executeUpdate();
        } finally {
            Util.closeStatement(ps);
        }
    }

}
