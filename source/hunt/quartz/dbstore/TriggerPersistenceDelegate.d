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
module hunt.quartz.dbstore.TriggerPersistenceDelegate;

// import java.io.IOException;
// import java.sql.Connection;
// import java.sql.SQLException;

import hunt.quartz.JobDetail;
import hunt.quartz.ScheduleBuilder;
import hunt.quartz.TriggerKey;
import hunt.quartz.spi.OperableTrigger;

import hunt.entity.EntityManager;

alias Connection = EntityManager;

/**
 * An interface which provides an implementation for storing a particular
 * type of <code>Trigger</code>'s extended properties.
 *  
 * @author jhouse
 */
interface TriggerPersistenceDelegate {

    void initialize(string tablePrefix, string schedulerName);
    
    bool canHandleTriggerType(OperableTrigger trigger);
    
    string getHandledTriggerTypeDiscriminator();
    
    int insertExtendedTriggerProperties(Connection conn, OperableTrigger trigger, string state, JobDetail jobDetail);

    int updateExtendedTriggerProperties(Connection conn, OperableTrigger trigger, string state, JobDetail jobDetail);
    
    int deleteExtendedTriggerProperties(Connection conn, TriggerKey triggerKey);

    TriggerPropertyBundle loadExtendedTriggerProperties(Connection conn, TriggerKey triggerKey);
    
    
}


class TriggerPropertyBundle {
    
    private ScheduleBuilder sb;
    private string[] statePropertyNames;
    private Object[] statePropertyValues;
    
    this(ScheduleBuilder sb, string[] statePropertyNames, Object[] statePropertyValues) {
        this.sb = sb;
        this.statePropertyNames = statePropertyNames;
        this.statePropertyValues = statePropertyValues;
    }

    ScheduleBuilder getScheduleBuilder() {
        return sb;
    }

    string[] getStatePropertyNames() {
        return statePropertyNames;
    }

    Object[] getStatePropertyValues() {
        return statePropertyValues;
    }
}