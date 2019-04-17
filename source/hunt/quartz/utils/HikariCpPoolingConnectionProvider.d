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

module hunt.quartz.utils.HikariCpPoolingConnectionProvider;

// import com.zaxxer.hikari.HikariDataSource;
// import hunt.quartz.Exceptions;

// import java.sql.Connection;
// import java.sql.SQLException;
// import java.util.Properties;

// /**
//  * <p>
//  * A <code>ConnectionProvider</code> implementation that creates its own
//  * pool of connections.
//  * </p>
//  *
//  * <p>
//  * This class uses HikariCP (https://brettwooldridge.github.io/HikariCP/) as
//  * the underlying pool implementation.</p>
//  *
//  * @see DBConnectionManager
//  * @see ConnectionProvider
//  *
//  * @author Ludovic Orban
//  */
// class HikariCpPoolingConnectionProvider : PoolingConnectionProvider {

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      *
//      * Constants.
//      *
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     /** This pooling provider name. */
//     enum string POOLING_PROVIDER_NAME = "hikaricp";

//     /** Discard connections after they have been idle this many seconds.  0 disables the feature. Default is 0.*/
//     private enum string DB_DISCARD_IDLE_CONNECTIONS_SECONDS = "discardIdleConnectionsSeconds";

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      *
//      * Data members.
//      *
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     private HikariDataSource datasource;

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      *
//      * Constructors.
//      *
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     HikariCpPoolingConnectionProvider(string dbDriver, string dbURL,
//                                              string dbUser, string dbPassword, int maxConnections,
//                                              string dbValidationQuery) {
//         initialize(
//                 dbDriver, dbURL, dbUser, dbPassword,
//                 maxConnections, dbValidationQuery, 0);
//     }

//     /**
//      * Create a connection pool using the given properties.
//      *
//      * <p>
//      * The properties passed should contain:
//      * <UL>
//      * <LI>{@link #DB_DRIVER}- The database driver class name
//      * <LI>{@link #DB_URL}- The database URL
//      * <LI>{@link #DB_USER}- The database user
//      * <LI>{@link #DB_PASSWORD}- The database password
//      * <LI>{@link #DB_MAX_CONNECTIONS}- The maximum # connections in the pool,
//      * optional
//      * <LI>{@link #DB_VALIDATION_QUERY}- The sql validation query, optional
//      * </UL>
//      * </p>
//      *
//      * @param config
//      *            configuration properties
//      */
//     HikariCpPoolingConnectionProvider(Properties config) {
//         PropertiesParser cfg = new PropertiesParser(config);
//         initialize(
//                 cfg.getStringProperty(DB_DRIVER),
//                 cfg.getStringProperty(DB_URL),
//                 cfg.getStringProperty(DB_USER, ""),
//                 cfg.getStringProperty(DB_PASSWORD, ""),
//                 cfg.getIntProperty(DB_MAX_CONNECTIONS, DEFAULT_DB_MAX_CONNECTIONS),
//                 cfg.getStringProperty(DB_VALIDATION_QUERY),
//                 cfg.getIntProperty(DB_DISCARD_IDLE_CONNECTIONS_SECONDS, 0));
//     }
    
//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Interface.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     /**
//      * Create the underlying C3PO ComboPooledDataSource with the 
//      * default supported properties.
//      * @throws SchedulerException
//      */
//     private void initialize(
//             string dbDriver,
//             string dbURL,
//             string dbUser,
//             string dbPassword,
//             int maxConnections,
//             string dbValidationQuery,
//             int maxIdleSeconds) {
//         if (dbURL is null) {
//             throw new SQLException(
//                     "DBPool could not be created: DB URL cannot be null");
//         }

//         if (dbDriver is null) {
//             throw new SQLException(
//                     "DBPool '" ~ dbURL ~ "' could not be created: " ~
//                             "DB driver class name cannot be null!");
//         }

//         if (maxConnections < 0) {
//             throw new SQLException(
//                     "DBPool '" ~ dbURL ~ "' could not be created: " ~
//                             "Max connections must be greater than zero!");
//         }


//         datasource = new HikariDataSource();
//         datasource.setDriverClassName(dbDriver);
//         datasource.setJdbcUrl(dbURL);
//         datasource.setUsername(dbUser);
//         datasource.setPassword(dbPassword);
//         datasource.setMaximumPoolSize(maxConnections);
//         datasource.setIdleTimeout(maxIdleSeconds);

//         if (dbValidationQuery !is null) {
//             datasource.setConnectionTestQuery(dbValidationQuery);
//         }
//     }

//     /**
//      * Get the HikariCP HikariDataSource created during initialization.
//      *
//      * <p>
//      * This can be used to set additional data source properties in a 
//      * subclass's constructor.
//      * </p>
//      */
//     HikariDataSource getDataSource() {
//         return datasource;
//     }

//     Connection getConnection() {
//         return datasource.getConnection();
//     }

//     void shutdown() {
//         datasource.close();
//     }

//     void initialize() {
//         // do nothing, already initialized during constructor call
//     }
// }
