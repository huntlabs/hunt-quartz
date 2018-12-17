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
module hunt.quartz.impl.jdbcjobstore.Semaphore;

import java.sql.Connection;

/**
 * An interface for providing thread/resource locking in order to protect
 * resources from being altered by multiple threads at the same time.
 * 
 * @author jhouse
 */
interface Semaphore {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Grants a lock on the identified resource to the calling thread (blocking
     * until it is available).
     * 
     * @param conn Database connection used to establish lock.  Can be null if
     * <code>{@link #requiresConnection()}</code> returns false.
     * 
     * @return true if the lock was obtained.
     */
    bool obtainLock(Connection conn, string lockName);

    /**
     * Release the lock on the identified resource if it is held by the calling
     * thread.
     */
    void releaseLock(string lockName);

    /**
     * Whether this Semaphore implementation requires a database connection for
     * its lock management operations.
     * 
     * @see #obtainLock(Connection, string)
     * @see #releaseLock(string)
     */
    bool requiresConnection();
}
