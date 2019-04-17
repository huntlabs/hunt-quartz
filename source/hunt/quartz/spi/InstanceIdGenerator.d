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
module hunt.quartz.spi.InstanceIdGenerator;

import hunt.quartz.Exceptions;

/**
 * <p>
 * An InstanceIdGenerator is responsible for generating the clusterwide unique 
 * instance id for a <code>Scheduler</code> node.
 * </p>
 * 
 * <p>
 * This interface may be of use to those wishing to have specific control over 
 * the mechanism by which the <code>Scheduler</code> instances in their 
 * application are named.
 * </p>
 * 
 * @see hunt.quartz.simpl.SimpleInstanceIdGenerator
 */
interface InstanceIdGenerator {
    /**
     * Generate the instance id for a <code>Scheduler</code>
     * 
     * @return The clusterwide unique instance id.
     */
    string generateInstanceId();
}