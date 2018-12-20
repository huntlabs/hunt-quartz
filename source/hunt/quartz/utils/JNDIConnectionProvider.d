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

module hunt.quartz.utils.JNDIConnectionProvider;

// import java.sql.Connection;
// import java.sql.SQLException;
// import java.util.Properties;

// import javax.naming.Context;
// import javax.naming.InitialContext;
// import javax.sql.DataSource;
// import javax.sql.XADataSource;

// import hunt.logging;


// /**
//  * <p>
//  * A <code>ConnectionProvider</code> that provides connections from a <code>DataSource</code>
//  * that is managed by an application server, and made available via JNDI.
//  * </p>
//  * 
//  * @see DBConnectionManager
//  * @see ConnectionProvider
//  * @see PoolingConnectionProvider
//  * 
//  * @author James House
//  * @author Sharada Jambula
//  * @author Mohammad Rezaei
//  * @author Patrick Lightbody
//  * @author Srinivas Venkatarangaiah
//  */
// class JNDIConnectionProvider : ConnectionProvider {

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Data members.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     private string url;

//     private Properties props;

//     private Object datasource;

//     private bool alwaysLookup = false;


//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Constructors.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     /**
//      * Constructor
//      * 
//      * @param jndiUrl
//      *          The url for the datasource
//      */
//     JNDIConnectionProvider(string jndiUrl, bool alwaysLookup) {
//         this.url = jndiUrl;
//         this.alwaysLookup = alwaysLookup;
//         init();
//     }

//     /**
//      * Constructor
//      * 
//      * @param jndiUrl
//      *          The URL for the DataSource
//      * @param jndiProps
//      *          The JNDI properties to use when establishing the InitialContext
//      *          for the lookup of the given URL.
//      */
//     JNDIConnectionProvider(string jndiUrl, Properties jndiProps,
//             bool alwaysLookup) {
//         this.url = jndiUrl;
//         this.props = jndiProps;
//         this.alwaysLookup = alwaysLookup;
//         init();
//     }

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Interface.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */


//     private void init() {

//         if (!isAlwaysLookup()) {
//             Context ctx = null;
//             try {
//                 ctx = (props !is null) ? new InitialContext(props) : new InitialContext(); 

//                 datasource = (DataSource) ctx.lookup(url);
//             } catch (Exception e) {
//                 error("Error looking up datasource: " ~ e.getMessage(), e);
//             } finally {
//                 if (ctx !is null) {
//                     try { ctx.close(); } catch(Exception ignore) {}
//                 }
//             }
//         }
//     }

//     Connection getConnection() {
//         Context ctx = null;
//         try {
//             Object ds = this.datasource;

//             if (ds is null || isAlwaysLookup()) {
//                 ctx = (props !is null) ? new InitialContext(props): new InitialContext(); 

//                 ds = ctx.lookup(url);
//                 if (!isAlwaysLookup()) {
//                     this.datasource = ds;
//                 }
//             }

//             if (ds is null) {
//                 throw new SQLException( "There is no object at the JNDI URL '" ~ url ~ "'");
//             }

//             if (ds instanceof XADataSource) {
//                 return (((XADataSource) ds).getXAConnection().getConnection());
//             } else if (ds instanceof DataSource) { 
//                 return ((DataSource) ds).getConnection();
//             } else {
//                 throw new SQLException("Object at JNDI URL '" ~ url ~ "' is not a DataSource.");
//             }
//         } catch (Exception e) {
//             this.datasource = null;
//             throw new SQLException(
//                     "Could not retrieve datasource via JNDI url '" ~ url ~ "' "
//                             + e.getClass().getName() ~ ": " ~ e.getMessage());
//         } finally {
//             if (ctx !is null) {
//                 try { ctx.close(); } catch(Exception ignore) {}
//             }
//         }
//     }

//     bool isAlwaysLookup() {
//         return alwaysLookup;
//     }

//     void setAlwaysLookup(bool b) {
//         alwaysLookup = b;
//     }

//     /* 
//      * @see hunt.quartz.utils.ConnectionProvider#shutdown()
//      */
//     void shutdown() {
//         // do nothing
//     }

//     void initialize() {
//         // do nothing, already initialized during constructor call
//     }
// }
