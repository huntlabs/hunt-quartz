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

module hunt.quartz.impl.jdbcjobstore.SchedulerStateRecord;

/**
 * <p>
 * Conveys a scheduler-instance state record.
 * </p>
 * 
 * @author James House
 */
class SchedulerStateRecord : java.io.Serializable {


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private string schedulerInstanceId;

    private long checkinTimestamp;

    private long checkinInterval;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     */
    long getCheckinInterval() {
        return checkinInterval;
    }

    /**
     */
    long getCheckinTimestamp() {
        return checkinTimestamp;
    }

    /**
     */
    string getSchedulerInstanceId() {
        return schedulerInstanceId;
    }

    /**
     */
     void setCheckinInterval(long l) {
        checkinInterval = l;
    }

    /**
     */
    void setCheckinTimestamp(long l) {
        checkinTimestamp = l;
    }

    /**
     */
    void setSchedulerInstanceId(string string) {
        schedulerInstanceId = string;
    }

}

// EOF
