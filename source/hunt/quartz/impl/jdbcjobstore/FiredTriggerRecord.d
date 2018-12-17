/* 
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not 
 * use this file except in compliance with the License. You may obtain a copy 
 * of the License at 
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0 
 *   
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
 * License for the specific language governing permissions and limitations 
 * under the License.
 * 
 */

module hunt.quartz.impl.jdbcjobstore.FiredTriggerRecord;

import hunt.quartz.JobKey;
import hunt.quartz.TriggerKey;

/**
 * <p>
 * Conveys the state of a fired-trigger record.
 * </p>
 * 
 * @author James House
 */
class FiredTriggerRecord implements java.io.Serializable {


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private string fireInstanceId;

    private long fireTimestamp;

    private long scheduleTimestamp;
    
    private string schedulerInstanceId;

    private TriggerKey triggerKey;

    private string fireInstanceState;

    private JobKey jobKey;

    private bool jobDisallowsConcurrentExecution;

    private bool jobRequestsRecovery;

    private int priority;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    string getFireInstanceId() {
        return fireInstanceId;
    }

    long getFireTimestamp() {
        return fireTimestamp;
    }

    long getScheduleTimestamp() {
        return scheduleTimestamp;
    }

    bool isJobDisallowsConcurrentExecution() {
        return jobDisallowsConcurrentExecution;
    }

    JobKey getJobKey() {
        return jobKey;
    }

    string getSchedulerInstanceId() {
        return schedulerInstanceId;
    }

    TriggerKey getTriggerKey() {
        return triggerKey;
    }

    string getFireInstanceState() {
        return fireInstanceState;
    }

    void setFireInstanceId(string string) {
        fireInstanceId = string;
    }

    void setFireTimestamp(long l) {
        fireTimestamp = l;
    }

    void setScheduleTimestamp(long l) {
        scheduleTimestamp = l;
    }

    void setJobDisallowsConcurrentExecution(bool b) {
        jobDisallowsConcurrentExecution = b;
    }

    void setJobKey(JobKey key) {
        jobKey = key;
    }

    void setSchedulerInstanceId(string string) {
        schedulerInstanceId = string;
    }

    void setTriggerKey(TriggerKey key) {
        triggerKey = key;
    }

    void setFireInstanceState(string string) {
        fireInstanceState = string;
    }

    bool isJobRequestsRecovery() {
        return jobRequestsRecovery;
    }

    void setJobRequestsRecovery(bool b) {
        jobRequestsRecovery = b;
    }

    int getPriority() {
        return priority;
    }
    

    void setPriority(int priority) {
        this.priority = priority;
    }
    

}

// EOF
