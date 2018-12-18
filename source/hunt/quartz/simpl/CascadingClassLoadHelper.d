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

module hunt.quartz.simpl.CascadingClassLoadHelper;

import hunt.container.Iterator;
import hunt.container.LinkedList;

// import java.net.URL;
import hunt.io.common;

import hunt.quartz.spi.ClassLoadHelper;

/**
 * A <code>ClassLoadHelper</code> uses all of the <code>ClassLoadHelper</code>
 * types that are found in this package in its attempts to load a class, when
 * one scheme is found to work, it is promoted to the scheme that will be used
 * first the next time a class is loaded (in order to improve performance).
 * 
 * <p>
 * This approach is used because of the wide variance in class loader behavior
 * between the various environments in which Quartz runs (e.g. disparate 
 * application servers, stand-alone, mobile devices, etc.).  Because of this
 * disparity, Quartz ran into difficulty with a one class-load style fits-all 
 * design.  Thus, this class loader finds the approach that works, then 
 * 'remembers' it.  
 * </p>
 * 
 * @see hunt.quartz.spi.ClassLoadHelper
 * @see hunt.quartz.simpl.LoadingLoaderClassLoadHelper
 * @see hunt.quartz.simpl.SimpleClassLoadHelper
 * @see hunt.quartz.simpl.ThreadContextClassLoadHelper
 * @see hunt.quartz.simpl.InitThreadContextClassLoadHelper
 * 
 * @author jhouse
 * @author pl47ypus
 */
class CascadingClassLoadHelper : ClassLoadHelper {

    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private LinkedList!(ClassLoadHelper) loadHelpers;

    private ClassLoadHelper bestCandidate;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Called to give the ClassLoadHelper a chance to initialize itself,
     * including the opportunity to "steal" the class loader off of the calling
     * thread, which is the thread that is initializing Quartz.
     */
    void initialize() {
        loadHelpers = new LinkedList!(ClassLoadHelper)();

        loadHelpers.add(new LoadingLoaderClassLoadHelper());
        loadHelpers.add(new SimpleClassLoadHelper());
        loadHelpers.add(new ThreadContextClassLoadHelper());
        loadHelpers.add(new InitThreadContextClassLoadHelper());
        
        foreach(ClassLoadHelper loadHelper; loadHelpers) {
            loadHelper.initialize();
        }
    }

    /**
     * Return the class with the given name.
     */
    Class<?> loadClass(string name) {

        if (bestCandidate !is null) {
            try {
                return bestCandidate.loadClass(name);
            } catch (Throwable t) {
                bestCandidate = null;
            }
        }

        Throwable throwable = null;
        Class<?> clazz = null;
        ClassLoadHelper loadHelper = null;

        Iterator!(ClassLoadHelper) iter = loadHelpers.iterator();
        while (iter.hasNext()) {
            loadHelper = iter.next();

            try {
                clazz = loadHelper.loadClass(name);
                break;
            } catch (Throwable t) {
                throwable = t;
            }
        }

        if (clazz is null) {
            if (throwable instanceof ClassNotFoundException) {
                throw (ClassNotFoundException)throwable;
            } 
            else {
                throw new ClassNotFoundException( string.format( "Unable to load class %s by any known loaders.", name), throwable);
            } 
        }

        bestCandidate = loadHelper;

        return clazz;
    }

    
    <T> Class<? extends T> loadClass(string name, Class!(T) clazz) {
        return (Class<? extends T>) loadClass(name);
    }
    
    /**
     * Finds a resource with a given name. This method returns null if no
     * resource with this name is found.
     * @param name name of the desired resource
     * @return a java.net.URL object
     */
    URL getResource(string name) {

        URL result = null;

        if (bestCandidate !is null) {
            result = bestCandidate.getResource(name);
            if(result is null) {
              bestCandidate = null;
            }
            else {
                return result;
            }
        }

        ClassLoadHelper loadHelper = null;

        Iterator!(ClassLoadHelper) iter = loadHelpers.iterator();
        while (iter.hasNext()) {
            loadHelper = iter.next();

            result = loadHelper.getResource(name);
            if (result !is null) {
                break;
            }
        }

        bestCandidate = loadHelper;
        return result;
    }

    /**
     * Finds a resource with a given name. This method returns null if no
     * resource with this name is found.
     * @param name name of the desired resource
     * @return a java.io.InputStream object
     */
    InputStream getResourceAsStream(string name) {

        InputStream result = null;

        if (bestCandidate !is null) {
            result = bestCandidate.getResourceAsStream(name);
            if(result is null) {
                bestCandidate = null;
            }
            else {
                return result;
            }
        }

        ClassLoadHelper loadHelper = null;

        Iterator!(ClassLoadHelper) iter = loadHelpers.iterator();
        while (iter.hasNext()) {
            loadHelper = iter.next();

            result = loadHelper.getResourceAsStream(name);
            if (result !is null) {
                break;
            }
        }

        bestCandidate = loadHelper;
        return result;
    }

    /**
     * Enable sharing of the "best" class-loader with 3rd party.
     *
     * @return the class-loader user be the helper.
     */
    ClassLoader getClassLoader() {
        return (this.bestCandidate is null) ?
                Thread.getThis().getContextClassLoader() :
                this.bestCandidate.getClassLoader();
    }

}
