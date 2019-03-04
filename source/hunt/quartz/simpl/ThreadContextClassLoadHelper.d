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

module hunt.quartz.simpl.ThreadContextClassLoadHelper;

import hunt.quartz.spi.ClassLoadHelper;

// import java.net.URL;
// import hunt.io.common;

/**
 * A <code>ClassLoadHelper</code> that uses either the current thread's
 * context class loader (<code>Thread.getThis().getContextClassLoader().loadClass( .. )</code>).
 * 
 * @see hunt.quartz.spi.ClassLoadHelper
 * @see hunt.quartz.simpl.InitThreadContextClassLoadHelper
 * @see hunt.quartz.simpl.SimpleClassLoadHelper
 * @see hunt.quartz.simpl.CascadingClassLoadHelper
 * @see hunt.quartz.simpl.LoadingLoaderClassLoadHelper
 * 
 * @author jhouse
 * @author pl47ypus
 */
// class ThreadContextClassLoadHelper : ClassLoadHelper {

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Interface.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     /**
//      * Called to give the ClassLoadHelper a chance to initialize itself,
//      * including the opportunity to "steal" the class loader off of the calling
//      * thread, which is the thread that is initializing Quartz.
//      */
//     void initialize() {
//     }

//     /**
//      * Return the class with the given name.
//      */
//     TypeInfo_Class loadClass(string name) {
//         return getClassLoader().loadClass(name);
//     }

//     
//     <T> Class<? extends T> loadClass(string name, Class!(T) clazz) {
//         return (Class<? extends T>) loadClass(name);
//     }
    
//     /**
//      * Finds a resource with a given name. This method returns null if no
//      * resource with this name is found.
//      * @param name name of the desired resource
//      * @return a java.net.URL object
//      */
//     URL getResource(string name) {
//         return getClassLoader().getResource(name);
//     }

//     /**
//      * Finds a resource with a given name. This method returns null if no
//      * resource with this name is found.
//      * @param name name of the desired resource
//      * @return a java.io.InputStream object
//      */
//     InputStream getResourceAsStream(string name) {
//         return getClassLoader().getResourceAsStream(name);
//     }

//     /**
//      * Enable sharing of the class-loader with 3rd party.
//      *
//      * @return the class-loader user be the helper.
//      */
//     ClassLoader getClassLoader() {
//         return Thread.getThis().getContextClassLoader();
//     }

// }
