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

module hunt.quartz.jobs.ee.ejb.EJBInvokerJob;

// import java.lang.reflect.InvocationTargetException;
// import java.lang.reflect.Method;
// import java.rmi.RemoteException;
// import java.util.Hashtable;

// import javax.ejb.EJBHome;
// import javax.ejb.EJBMetaData;
// import javax.ejb.EJBObject;
// import javax.naming.Context;
// import javax.naming.InitialContext;
// import javax.naming.NamingException;
// import javax.rmi.PortableRemoteObject;

// import hunt.quartz.Job;
// import hunt.quartz.JobDataMap;
// import hunt.quartz.JobExecutionContext;
// import hunt.quartz.JobExecutionException;

// /**
//  * <p>
//  * A <code>Job</code> that invokes a method on an EJB.
//  * </p>
//  * 
//  * <p>
//  * Expects the properties corresponding to the following keys to be in the
//  * <code>JobDataMap</code> when it executes:
//  * <ul>
//  * <li><code>EJB_JNDI_NAME_KEY</code>- the JNDI name (location) of the
//  * EJB's home interface.</li>
//  * <li><code>EJB_METHOD_KEY</code>- the name of the method to invoke on the
//  * EJB.</li>
//  * <li><code>EJB_ARGS_KEY</code>- an Object[] of the args to pass to the
//  * method (optional, if left out, there are no arguments).</li>
//  * <li><code>EJB_ARG_TYPES_KEY</code>- an Class[] of the types of the args to 
//  * pass to the method (optional, if left out, the types will be derived by 
//  * calling getClass() on each of the arguments).</li>
//  * </ul>
//  * <br/>
//  * The following keys can also be used at need:
//  * <ul>
//  * <li><code>INITIAL_CONTEXT_FACTORY</code> - the context factory used to 
//  * build the context.</li>
//  * <li><code>PROVIDER_URL</code> - the name of the environment property
//  * for specifying configuration information for the service provider to use.
//  * </li>
//  * </ul>
//  * </p>
//  * 
//  * <p>
//  * The result of the EJB method invocation will be available to 
//  * <code>Job/TriggerListener</code>s via
//  * <code>{@link hunt.quartz.JobExecutionContext#getResult()}</code>.
//  * </p>
//  * 
//  * @author Andrew Collins
//  * @author James House
//  * @author Joel Shellman
//  * @author <a href="mailto:bonhamcm@thirdeyeconsulting.com">Chris Bonham</a>
//  */
// class EJBInvokerJob : Job {

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Constants.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     enum string EJB_JNDI_NAME_KEY = "ejb";

//     enum string EJB_METHOD_KEY = "method";

//     enum string EJB_ARG_TYPES_KEY = "argTypes";

//     enum string EJB_ARGS_KEY = "args";
    
//     enum string INITIAL_CONTEXT_FACTORY = "java.naming.factory.initial";
    
//     enum string PROVIDER_URL = "java.naming.provider.url";

//     enum string PRINCIPAL = "java.naming.security.principal";

//     enum string CREDENTIALS = "java.naming.security.credentials";


//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Constructors.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     EJBInvokerJob() {
//         // nothing
//     }

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Interface.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     void execute(JobExecutionContext context) {
//         JobDataMap dataMap = context.getMergedJobDataMap();

//         string ejb = dataMap.getString(EJB_JNDI_NAME_KEY);
//         string method = dataMap.getString(EJB_METHOD_KEY);
//         Object[] arguments = (Object[]) dataMap.get(EJB_ARGS_KEY);
//         if (arguments is null) {
//             arguments = new Object[0];
//         }

//         if (ejb is null) { 
//             // must specify remote home
//             throw new JobExecutionException(); 
//         }

//         InitialContext jndiContext = null;

//         // get initial context
//         try {
//             jndiContext = getInitialContext(dataMap);
//         } catch (NamingException ne) {
//             throw new JobExecutionException(ne);
//         }
             
//         try {
//             Object value = null;
            
//             // locate home interface
//             try {
//                 value = jndiContext.lookup(ejb);
//             } catch (NamingException ne) {
//                 throw new JobExecutionException(ne);
//             } 
    
//             // get home interface
//             EJBHome ejbHome = (EJBHome) PortableRemoteObject.narrow(value,
//                     EJBHome.class);
    
//             // get meta data
//             EJBMetaData metaData = null;
    
//             try {
//                 metaData = ejbHome.getEJBMetaData();
//             } catch (RemoteException re) {
//                 throw new JobExecutionException(re);
//             }
    
//             // get home interface class
//             TypeInfo_Class homeClass = metaData.getHomeInterfaceClass();
    
//             // get remote interface class
//             TypeInfo_Class remoteClass = metaData.getRemoteInterfaceClass();
    
//             // get home interface
//             ejbHome = (EJBHome) PortableRemoteObject.narrow(ejbHome, homeClass);
    
//             Method methodCreate = null;
    
//             try {
//                 // create method 'create()' on home interface
//                 methodCreate = homeClass.getMethod("create", ((Class[])null));
//             } catch (NoSuchMethodException nsme) {
//                 throw new JobExecutionException(nsme);
//             }
    
//             // create remote object
//             EJBObject remoteObj = null;
    
//             try {
//                 // invoke 'create()' method on home interface
//                 remoteObj = (EJBObject) methodCreate.invoke(ejbHome, ((Object[])null));
//             } catch (IllegalAccessException iae) {
//                 throw new JobExecutionException(iae);
//             } catch (InvocationTargetException ite) {
//                 throw new JobExecutionException(ite);
//             }
    
//             // execute user-specified method on remote object
//             Method methodExecute = null;
    
//             try {
//                 // create method signature
    
//                 TypeInfo_Class[] argTypes = (Class[]) dataMap.get(EJB_ARG_TYPES_KEY);
//                 if (argTypes is null) {
//                     argTypes = new Class[arguments.length];
//                     for (int i = 0; i < arguments.length; i++) {
//                         argTypes[i] = arguments[i].getClass();
//                     }
//                 }
    
//                 // get method on remote object
//                 methodExecute = remoteClass.getMethod(method, argTypes);
//             } catch (NoSuchMethodException nsme) {
//                 throw new JobExecutionException(nsme);
//             }
    
//             try {
//                 // invoke user-specified method on remote object
//                 Object returnObj = methodExecute.invoke(remoteObj, arguments);
                
//                 // Return any result in the JobExecutionContext so it will be 
//                 // available to Job/TriggerListeners
//                 context.setResult(returnObj);
//             } catch (IllegalAccessException iae) {
//                 throw new JobExecutionException(iae);
//             } catch (InvocationTargetException ite) {
//                 throw new JobExecutionException(ite);
//             }
//         } finally {
//             // Don't close jndiContext until after method execution because
//             // WebLogic requires context to be open to keep the user credentials
//             // available.  See JIRA Issue: QUARTZ-401
//             if (jndiContext !is null) {
//                 try {
//                     jndiContext.close();
//                 } catch (NamingException e) {
//                     // Ignore any errors closing the initial context
//                 }
//             }
//         }
//     }

//     protected InitialContext getInitialContext(JobDataMap jobDataMap) {
//         Hashtable!(string, string) params = new Hashtable!(string, string)(2);
        
//         string initialContextFactory =
//             jobDataMap.getString(INITIAL_CONTEXT_FACTORY);
//         if (initialContextFactory !is null) {
//             params.put(Context.INITIAL_CONTEXT_FACTORY, initialContextFactory);
//         }
        
//         string providerUrl = jobDataMap.getString(PROVIDER_URL);
//         if (providerUrl !is null) {
//             params.put(Context.PROVIDER_URL, providerUrl);
//         }

//         string principal = jobDataMap.getString(PRINCIPAL);
//         if ( principal !is null ) {
//             params.put( Context.SECURITY_PRINCIPAL, principal );
//         }

//         string credentials = jobDataMap.getString(CREDENTIALS);
//         if ( credentials !is null ) {
//             params.put( Context.SECURITY_CREDENTIALS, credentials );
//         }

//         return (params.size() == 0) ? new InitialContext() : new InitialContext(params);
//     }    
// }