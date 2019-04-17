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
module hunt.quartz.simpl.SimpleInstanceIdGenerator;

import hunt.quartz.Exceptions;
import hunt.quartz.spi.InstanceIdGenerator;
import hunt.util.DateTime;

import std.conv;
import std.socket;

/**
 * The default InstanceIdGenerator used by Quartz when instance id is to be
 * automatically generated.  Instance id is of the form HOSTNAME + CURRENT_TIME.
 * 
 * @see InstanceIdGenerator
 * @see HostnameInstanceIdGenerator
 */
class SimpleInstanceIdGenerator : InstanceIdGenerator {

    this() {

    }
    string generateInstanceId() {
        try {
            return Socket.hostName() ~ DateTimeHelper.currentTimeMillis().to!string();
        } catch (Exception e) {
            throw new SchedulerException("Couldn't get host name!", e);
        }
    }
}