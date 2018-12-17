module hunt.quartz.management.ManagementServer;

import hunt.quartz.core.QuartzScheduler;


/**
 *  Copyright Terracotta, Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */


/**
 * Interface implemented by management servers.
 *
 * @author Ludovic Orban
 * @author brandony
 */
interface ManagementServer {

    /**
     * Start the management server
     */
    void start();

    /**
     * Stop the management server
     */
    void stop();

    /**
     * Puts the submitted resource under the purview of this {@code ManagementServer}.
     *
     * @param managedResource the resource to be managed
     */
    void register(QuartzScheduler managedResource);

    /**
     * Removes the submitted resource under the purview of this {@code ManagementServer}.
     *
     * @param managedResource the resource to be managed
     */
    void unregister(QuartzScheduler managedResource);

    /**
     * Returns true if this {@code ManagementServer} has any resources registered.
     *
     * @return true if actively managing resources, false if not.
     */
    bool hasRegistered();

}
