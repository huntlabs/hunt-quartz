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

module hunt.quartz.dbstore.TriggerStatus;

// import std.datetime;
import hunt.time.LocalDateTime;

import hunt.quartz.JobKey;
import hunt.quartz.TriggerKey;


/**
 * <p>
 * Object representing a job or trigger key.
 * </p>
 * 
 * @author James House
 */
class TriggerStatus {

    // FUTURE_TODO: Repackage under spi or root pkg ?, put status constants here.
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private TriggerKey key;

    private JobKey jobKey;

    private string status;
    
    private LocalDateTime nextFireTime;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Construct a new TriggerStatus with the status name and nextFireTime.
     * 
     * @param status
     *          the trigger's status
     * @param nextFireTime
     *          the next time the trigger will fire
     */
    this(string status, LocalDateTime nextFireTime) {
        this.status = status;
        this.nextFireTime = nextFireTime;
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    JobKey getJobKey() {
        return jobKey;
    }

    void setJobKey(JobKey jobKey) {
        this.jobKey = jobKey;
    }

    TriggerKey getKey() {
        return key;
    }

    void setKey(TriggerKey key) {
        this.key = key;
    }

    /**
     * <p>
     * Get the name portion of the key.
     * </p>
     * 
     * @return the name
     */
    string getStatus() {
        return status;
    }

    /**
     * <p>
     * Get the group portion of the key.
     * </p>
     * 
     * @return the group
     */
    LocalDateTime getNextFireTime() {
        return nextFireTime;
    }

    /**
     * <p>
     * Return the string representation of the TriggerStatus.
     * </p>
     *  
     */
    override
    string toString() {
        return "status: " ~ getStatus() ~ ", next Fire = " ~ getNextFireTime().toString();
    }
}

// EOF
