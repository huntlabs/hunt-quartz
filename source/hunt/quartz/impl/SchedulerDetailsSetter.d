/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module hunt.quartz.impl.SchedulerDetailsSetter;

// import java.lang.reflect.InvocationTargetException;
// import java.lang.reflect.Method;
// import java.lang.reflect.Modifier;

import hunt.logging;
import hunt.Exceptions;
import hunt.quartz.Exceptions;

import hunt.util.Traits;

/**
 * This utility calls methods reflectively on the given objects even though the
 * methods are likely on a proper interface (ThreadPool, JobStore, etc). The
 * motivation is to be tolerant of older implementations that have not been
 * updated for the changes in the interfaces (eg. LocalTaskExecutorThreadPool in
 * spring quartz helpers)
 *
 * @author teck
 */
class SchedulerDetailsSetter {

    private this() {
        //
    }

    static void setDetails(T)(T target, string schedulerName,
            string schedulerId) {
        // implementationMissing(false);
        // set(target, "setInstanceName", schedulerName);
        // set(target, "setInstanceId", schedulerId);
        setProperty(target, "InstanceName", schedulerName);
        setProperty(target, "InstanceId", schedulerId);
    }

    // private static void set(Object target, string method, string value) {
    //     final Method setter;

    //     try {
    //         setter = target.getClass().getMethod(method, string.class);
    //     } catch (SecurityException e) {
    //         LOGGER.error("A SecurityException occured: " ~ e.getMessage(), e);
    //         return;
    //     } catch (NoSuchMethodException e) {
    //         // This probably won't happen since the interface has the method
    //         LOGGER.warn(target.getClass().getName()
    //                 ~ " does not contain public method " ~ method ~ "(string)");
    //         return;
    //     }

    //     if (Modifier.isAbstract(setter.getModifiers())) {
    //         // expected if method not implemented (but is present on
    //         // interface)
    //         LOGGER.warn(target.getClass().getName()
    //                 ~ " does not implement " ~ method
    //                 ~ "(string)");
    //         return;
    //     }

    //     try {
    //         setter.invoke(target, value);
    //     } catch (InvocationTargetException ite) {
    //         throw new SchedulerException(ite.getTargetException());
    //     } catch (Exception e) {
    //         throw new SchedulerException(e);
    //     }
    // }

}
