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

import hunt.quartz.dbstore.StdSqlConstants;
import hunt.quartz.dbstore.TableConstants;
import hunt.quartz.dbstore.TriggerPersistenceDelegate;

import hunt.quartz.JobDetail;
import hunt.quartz.SimpleScheduleBuilder;
import hunt.quartz.SimpleTrigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.impl.triggers.SimpleTriggerImpl;
import hunt.quartz.spi.OperableTrigger;

import hunt.Exceptions;

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
        // PreparedStatement ps = null;

        // try {
        //     ps = conn.prepareStatement(Util.rtp(DELETE_SIMPLE_TRIGGER, tablePrefix, schedNameLiteral));
        //     ps.setString(1, triggerKey.getName());
        //     ps.setString(2, triggerKey.getGroup());

        //     return ps.executeUpdate();
        // } finally {
        //     Util.closeStatement(ps);
        // }

        implementationMissing(false);
        return 0;
    }

    int insertExtendedTriggerProperties(Connection conn, OperableTrigger trigger, string state, JobDetail jobDetail) {

        // SimpleTrigger simpleTrigger = cast(SimpleTrigger)trigger;
        
        // PreparedStatement ps = null;
        
        // try {
        //     ps = conn.prepareStatement(Util.rtp(INSERT_SIMPLE_TRIGGER, tablePrefix, schedNameLiteral));
        //     ps.setString(1, trigger.getKey().getName());
        //     ps.setString(2, trigger.getKey().getGroup());
        //     ps.setInt(3, simpleTrigger.getRepeatCount());
        //     ps.setBigDecimal(4, new BigDecimal(string.valueOf(simpleTrigger.getRepeatInterval())));
        //     ps.setInt(5, simpleTrigger.getTimesTriggered());

        //     return ps.executeUpdate();
        // } finally {
        //     Util.closeStatement(ps);
        // }

        implementationMissing(false);
        return 0;
    }

    TriggerPropertyBundle loadExtendedTriggerProperties(Connection conn, TriggerKey triggerKey) {

        // PreparedStatement ps = null;
        // ResultSet rs = null;
        
        // try {
        //     ps = conn.prepareStatement(Util.rtp(SELECT_SIMPLE_TRIGGER, tablePrefix, schedNameLiteral));
        //     ps.setString(1, triggerKey.getName());
        //     ps.setString(2, triggerKey.getGroup());
        //     rs = ps.executeQuery();
    
        //     if (rs.next()) {
        //         int repeatCount = rs.getInt(COL_REPEAT_COUNT);
        //         long repeatInterval = rs.getLong(COL_REPEAT_INTERVAL);
        //         int timesTriggered = rs.getInt(COL_TIMES_TRIGGERED);

        //         SimpleScheduleBuilder sb = SimpleScheduleBuilder.simpleSchedule()
        //             .withRepeatCount(repeatCount)
        //             .withIntervalInMilliseconds(repeatInterval);
                
        //         string[] statePropertyNames = { "timesTriggered" };
        //         Object[] statePropertyValues = { timesTriggered };
                
        //         return new TriggerPropertyBundle(sb, statePropertyNames, statePropertyValues);
        //     }
            
        //     throw new IllegalStateException("No record found for selection of Trigger with key: '" ~ triggerKey ~ "' and statement: " ~ Util.rtp(SELECT_SIMPLE_TRIGGER, tablePrefix, schedNameLiteral));
        // } finally {
        //     Util.closeResultSet(rs);
        //     Util.closeStatement(ps);
        // }
        implementationMissing(false);
        return null;
    }

    int updateExtendedTriggerProperties(Connection conn, OperableTrigger trigger, string state, JobDetail jobDetail) {

        // SimpleTrigger simpleTrigger = cast(SimpleTrigger)trigger;
        
        // PreparedStatement ps = null;

        // try {
        //     ps = conn.prepareStatement(Util.rtp(UPDATE_SIMPLE_TRIGGER, tablePrefix, schedNameLiteral));

        //     ps.setInt(1, simpleTrigger.getRepeatCount());
        //     ps.setBigDecimal(2, new BigDecimal(string.valueOf(simpleTrigger.getRepeatInterval())));
        //     ps.setInt(3, simpleTrigger.getTimesTriggered());
        //     ps.setString(4, simpleTrigger.getKey().getName());
        //     ps.setString(5, simpleTrigger.getKey().getGroup());

        //     return ps.executeUpdate();
        // } finally {
        //     Util.closeStatement(ps);
        // }

        implementationMissing(false);
        return 0;
    }

}
