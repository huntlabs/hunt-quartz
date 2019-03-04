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

module hunt.quartz.simpl.SimpleClassLoadHelper;

import hunt.quartz.simpl.CascadingClassLoadHelper;
import hunt.quartz.simpl.LoadingLoaderClassLoadHelper;
import hunt.quartz.simpl.ThreadContextClassLoadHelper;
import hunt.quartz.spi.ClassLoadHelper;


// import java.lang.reflect.AccessibleObject;
// import java.lang.reflect.Method;
// import java.net.URL;
// import hunt.io.common;

/**
 * A <code>ClassLoadHelper</code> that simply calls <code>Class.forName(..)</code>.
 * 
 * @see hunt.quartz.spi.ClassLoadHelper
 * @see hunt.quartz.simpl.ThreadContextClassLoadHelper
 * @see hunt.quartz.simpl.CascadingClassLoadHelper
 * @see hunt.quartz.simpl.LoadingLoaderClassLoadHelper
 * 
 * @author jhouse
 * @author pl47ypus
 */
// class SimpleClassLoadHelper : ClassLoadHelper {

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
//         return Class.forName(name);
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
//         // To follow the same behavior of Class.forName(...) I had to play
//         // dirty (Supported by Sun, IBM & BEA JVMs)
//         try {
//             // Get a reference to this class' class-loader
//             ClassLoader cl = this.getClass().getClassLoader();
//             // Create a method instance representing the protected
//             // getCallerClassLoader method of class ClassLoader
//             Method mthd = ClassLoader.class.getDeclaredMethod(
//                     "getCallerClassLoader", new TypeInfo_Class[0]);
//             // Make the method accessible.
//             AccessibleObject.setAccessible(new AccessibleObject[] {mthd}, true);
//             // Try to get the caller's class-loader
//             return (ClassLoader)mthd.invoke(cl, new Object[0]);
//         } catch (Throwable all) {
//             // Use this class' class-loader
//             return this.getClass().getClassLoader();
//         }
//     }

// }
