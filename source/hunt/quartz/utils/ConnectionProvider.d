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

module hunt.quartz.utils.ConnectionProvider;

import hunt.database.driver.Connection;

/**
 * Implementations of this interface used by <code>DBConnectionManager</code>
 * to provide connections from various sources.
 * 
 * @see DBConnectionManager
 * @see PoolingConnectionProvider
 * @see JNDIConnectionProvider
 * @see hunt.quartz.utils.weblogic.WeblogicConnectionProvider
 * 
 * @author Mohammad Rezaei
 */
interface ConnectionProvider {
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * @return connection managed by this provider
     * @throws SQLException
     */
    Connection getConnection();
    
    
    void shutdown();
    
    void initialize();
}
