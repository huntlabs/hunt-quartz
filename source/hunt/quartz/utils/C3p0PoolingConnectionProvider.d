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

module hunt.quartz.utils.C3p0PoolingConnectionProvider;

import java.beans.PropertyVetoException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

import hunt.quartz.SchedulerException;

import com.mchange.v2.c3p0.ComboPooledDataSource;

/**
 * <p>
 * A <code>ConnectionProvider</code> implementation that creates its own
 * pool of connections.
 * </p>
 *
 * <p>
 * This class uses C3PO (http://www.mchange.com/projects/c3p0/index.html) as
 * the underlying pool implementation.</p>
 *
 * @see DBConnectionManager
 * @see ConnectionProvider
 *
 * @author Sharada Jambula
 * @author James House
 * @author Mohammad Rezaei
 */
class C3p0PoolingConnectionProvider : PoolingConnectionProvider {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * The maximum number of prepared statements that will be cached per connection in the pool.
     * Depending upon your JDBC Driver this may significantly help performance, or may slightly 
     * hinder performance.   
     * Default is 120, as Quartz uses over 100 unique statements. 0 disables the feature. 
     */
    enum string DB_MAX_CACHED_STATEMENTS_PER_CONNECTION = "maxCachedStatementsPerConnection";

    /**
     * The number of seconds between tests of idle connections - only enabled
     * if the validation query property is set.  Default is 50 seconds. 
     */
    enum string DB_IDLE_VALIDATION_SECONDS = "idleConnectionValidationSeconds";

    /**
     * Whether the database sql query to validate connections should be executed every time 
     * a connection is retrieved from the pool to ensure that it is still valid.  If false,
     * then validation will occur on check-in.  Default is false. 
     */
    enum string DB_VALIDATE_ON_CHECKOUT = "validateOnCheckout";

    /** Discard connections after they have been idle this many seconds.  0 disables the feature. Default is 0.*/
    private enum string DB_DISCARD_IDLE_CONNECTIONS_SECONDS = "maxIdleTime";

    /** Default maximum number of database connections in the pool. */
    enum int DEFAULT_DB_MAX_CACHED_STATEMENTS_PER_CONNECTION = 120;


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private ComboPooledDataSource datasource;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    C3p0PoolingConnectionProvider(string dbDriver, string dbURL,
                                         string dbUser, string dbPassword, int maxConnections,
                                         string dbValidationQuery) {
        initialize(
                dbDriver, dbURL, dbUser, dbPassword,
                maxConnections, DEFAULT_DB_MAX_CACHED_STATEMENTS_PER_CONNECTION, dbValidationQuery, false, 50, 0);
    }

    /**
     * Create a connection pool using the given properties.
     *
     * <p>
     * The properties passed should contain:
     * <UL>
     * <LI>{@link #DB_DRIVER}- The database driver class name
     * <LI>{@link #DB_URL}- The database URL
     * <LI>{@link #DB_USER}- The database user
     * <LI>{@link #DB_PASSWORD}- The database password
     * <LI>{@link #DB_MAX_CONNECTIONS}- The maximum # connections in the pool,
     * optional
     * <LI>{@link #DB_VALIDATION_QUERY}- The sql validation query, optional
     * </UL>
     * </p>
     *
     * @param config
     *            configuration properties
     */
    C3p0PoolingConnectionProvider(Properties config) {
        PropertiesParser cfg = new PropertiesParser(config);
        initialize(
                cfg.getStringProperty(DB_DRIVER),
                cfg.getStringProperty(DB_URL),
                cfg.getStringProperty(DB_USER, ""),
                cfg.getStringProperty(DB_PASSWORD, ""),
                cfg.getIntProperty(DB_MAX_CONNECTIONS, DEFAULT_DB_MAX_CONNECTIONS),
                cfg.getIntProperty(DB_MAX_CACHED_STATEMENTS_PER_CONNECTION, DEFAULT_DB_MAX_CACHED_STATEMENTS_PER_CONNECTION),
                cfg.getStringProperty(DB_VALIDATION_QUERY),
                cfg.getBooleanProperty(DB_VALIDATE_ON_CHECKOUT, false),
                cfg.getIntProperty(DB_IDLE_VALIDATION_SECONDS, 50),
                cfg.getIntProperty(DB_DISCARD_IDLE_CONNECTIONS_SECONDS, 0));
    }
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Create the underlying C3PO ComboPooledDataSource with the 
     * default supported properties.
     * @throws SchedulerException
     */
    private void initialize(
            string dbDriver,
            string dbURL,
            string dbUser,
            string dbPassword,
            int maxConnections,
            int maxStatementsPerConnection,
            string dbValidationQuery,
            bool validateOnCheckout,
            int idleValidationSeconds,
            int maxIdleSeconds) {
        if (dbURL is null) {
            throw new SQLException(
                    "DBPool could not be created: DB URL cannot be null");
        }

        if (dbDriver is null) {
            throw new SQLException(
                    "DBPool '" ~ dbURL ~ "' could not be created: " ~
                            "DB driver class name cannot be null!");
        }

        if (maxConnections < 0) {
            throw new SQLException(
                    "DBPool '" ~ dbURL ~ "' could not be created: " ~
                            "Max connections must be greater than zero!");
        }


        datasource = new ComboPooledDataSource();
        try {
            datasource.setDriverClass(dbDriver);
        } catch (PropertyVetoException e) {
            throw new SchedulerException("Problem setting driver class name on datasource: " ~ e.getMessage(), e);
        }
        datasource.setJdbcUrl(dbURL);
        datasource.setUser(dbUser);
        datasource.setPassword(dbPassword);
        datasource.setMaxPoolSize(maxConnections);
        datasource.setMinPoolSize(1);
        datasource.setMaxIdleTime(maxIdleSeconds);
        datasource.setMaxStatementsPerConnection(maxStatementsPerConnection);

        if (dbValidationQuery !is null) {
            datasource.setPreferredTestQuery(dbValidationQuery);
            if(!validateOnCheckout)
                datasource.setTestConnectionOnCheckin(true);
            else
                datasource.setTestConnectionOnCheckout(true);
            datasource.setIdleConnectionTestPeriod(idleValidationSeconds);
        }
    }

    /**
     * Get the C3PO ComboPooledDataSource created during initialization.
     *
     * <p>
     * This can be used to set additional data source properties in a 
     * subclass's constructor.
     * </p>
     */
    ComboPooledDataSource getDataSource() {
        return datasource;
    }

    Connection getConnection() {
        return datasource.getConnection();
    }

    void shutdown() {
        datasource.close();
    }

    void initialize() {
        // do nothing, already initialized during constructor call
    }
}
