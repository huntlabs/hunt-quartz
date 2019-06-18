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

module hunt.quartz.dbstore.DBConnectionManager;

import hunt.collection.HashMap;
import hunt.entity;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;

alias Connection = EntityManager;

/**
 * <p>
 * Manages a collection of ConnectionProviders, and provides transparent access
 * to their connections.
 * </p>
 * 
 * @see ConnectionProvider
 * @see PoolingConnectionProvider
 * @see JNDIConnectionProvider
 * @see hunt.quartz.utils.weblogic.WeblogicConnectionProvider
 * 
 * @author James House
 * @author Sharada Jambula
 * @author Mohammad Rezaei
 */
class DBConnectionManager {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    enum string DB_PROPS_PREFIX = "hunt.quartz.db.";

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private __gshared DBConnectionManager instance;

    shared static this() {
        instance = new DBConnectionManager();
    }

    // private HashMap!(string, ConnectionProvider) providers;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Private constructor
     * </p>
     *  
     */
    private this() {
        // providers = new HashMap!(string, ConnectionProvider)();

    }


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    // void addConnectionProvider(string dataSourceName,
    //         ConnectionProvider provider) {
    //     this.providers.put(dataSourceName, provider);
    // }

    /**
     * Get a database connection from the DataSource with the given name.
     * 
     * @return a database connection
     * @exception SQLException
     *              if an error occurs, or there is no DataSource with the
     *              given name.
     */
    Connection getConnection(string dsName, EntityOption option) {
        if (em is null) {
            version(HUNT_QUARTZ_DEBUG) trace("creating EntityManager for " ~ dsName);
            EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("postgresql",
                    option);
            em = entityManagerFactory.createEntityManager();
        }
        return em;
    }

    private static EntityManager em;

    /**
     * Get the class instance.
     * 
     * @return an instance of this class
     */
    static DBConnectionManager getInstance() {
        // since the instance variable is initialized at class loading time,
        // it's not necessary to synchronize this method */
        return instance;
    }

    /**
     * Shuts down database connections from the DataSource with the given name,
     * if applicable for the underlying provider.
     *
     * @exception SQLException
     *              if an error occurs, or there is no DataSource with the
     *              given name.
     */
    void shutdown(string dsName) {

        // ConnectionProvider provider = providers.get(dsName);
        // if (provider is null) {
        //     throw new SQLException("There is no DataSource named '"
        //             ~ dsName ~ "'");
        // }

        // provider.shutdown();
    }

    // ConnectionProvider getConnectionProvider(string key) {
    //     return providers.get(key);
    // }
}
