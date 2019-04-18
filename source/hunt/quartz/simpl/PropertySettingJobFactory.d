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
module hunt.quartz.simpl.PropertySettingJobFactory;

import hunt.quartz.simpl.SimpleJobFactory;

import hunt.collection.Map;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.time.util.Locale;

import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.Scheduler;
import hunt.quartz.SchedulerContext;
import hunt.quartz.Exceptions;
import hunt.quartz.spi.TriggerFiredBundle;

import witchcraft;


/**
 * A JobFactory that instantiates the Job instance (using the default no-arg
 * constructor, or more specifically: <code>class.newInstance()</code>), and
 * then attempts to set all values from the <code>SchedulerContext</code> and
 * the <code>JobExecutionContext</code>'s merged <code>JobDataMap</code> onto 
 * bean properties of the <code>Job</code>.
 * 
 * <p>Set the warnIfPropertyNotFound property to true if you'd like noisy logging in
 * the case of values in the JobDataMap not mapping to properties on your Job
 * class.  This may be useful for troubleshooting typos of property names, etc.
 * but very noisy if you regularly (and purposely) have extra things in your
 * JobDataMap.</p>
 * 
 * <p>Also of possible interest is the throwIfPropertyNotFound property which
 * will throw exceptions on unmatched JobDataMap keys.</p>
 * 
 * @see hunt.quartz.spi.JobFactory
 * @see SimpleJobFactory
 * @see SchedulerContext
 * @see hunt.quartz.JobExecutionContext#getMergedJobDataMap()
 * @see #setWarnIfPropertyNotFound(bool)
 * @see #setThrowIfPropertyNotFound(bool)
 * 
 * @author jhouse
 */
class PropertySettingJobFactory : SimpleJobFactory {
    private bool warnIfNotFound = false;
    private bool throwIfNotFound = false;
    
    override
    Job newJob(TriggerFiredBundle bundle, Scheduler scheduler) {

        Job job = super.newJob(bundle, scheduler);
        
        JobDataMap jobDataMap = new JobDataMap();
        jobDataMap.putAll(scheduler.getContext());
        jobDataMap.putAll(bundle.getJobDetail().getJobDataMap());
        jobDataMap.putAll(bundle.getTrigger().getJobDataMap());

        setBeanProps(job, jobDataMap);
        
        return job;
    }
    
    protected void setBeanProps(ClassAccessor accessor, JobDataMap data) {
        if(accessor is null) {
            warning("The object is not a ClassAccessor");
            return ;
        }

        
        const Class metaInfo = accessor.getMetaType();
        version(HUNT_DEBUG) trace("job: ", metaInfo.toString());
        
        // Get the wrapped entry set so don't have to incur overhead of wrapping for
        // dirty flag checking since this is read only access
        import std.ascii;
        foreach(string name, Object o; data) {
            char c = name[0].toUpper();
            string methName = "set" ~ c ~ name[1 .. $];
            version(HUNT_DEBUG) trace("checking method: ", methName);

            const Method setMeth = metaInfo.getMethod(methName);
            if (setMeth is null) {
                handleError("No setter on Job class " ~ metaInfo.getFullName() ~ 
                    " for property '" ~ name ~ "'");
                continue;
            }            

            const(TypeInfo) paramType = setMeth.getParameterTypeInfos()[0];
            tracef("parameter: %s, argement: %s", paramType, typeid(o));
            
            try {

                implementationMissing(false);
        
                if(paramType == typeid(o)) {

                }
                
                // Object parm = null;
                // if (paramType.isPrimitive()) {
                //     if (o is null) {
                //         handleError(
                //             "Cannot set primitive property '" ~ name ~
                //             "' on Job class " ~ metaInfo.getFullName() ~ 
                //             " to null.");
                //         continue;
                //     }

                //     if (paramType== int.class) {
                //         if (o instanceof string) {                            
                //             parm = Integer.valueOf((string)o);
                //         } else if (o instanceof Integer) {
                //             parm = o;
                //         }
                //     } else if (paramType== long.class) {
                //         if (o instanceof string) {
                //             parm = Long.valueOf((string)o);
                //         } else if (o instanceof Long) {
                //             parm = o;
                //         }
                //     } else if (paramType== float.class) {
                //         if (o instanceof string) {
                //             parm = Float.valueOf((string)o);
                //         } else if (o instanceof Float) {
                //             parm = o;
                //         }
                //     } else if (paramType== double.class) {
                //         if (o instanceof string) {
                //             parm = Double.valueOf((string)o);
                //         } else if (o instanceof Double) {
                //             parm = o;
                //         }
                //     } else if (paramType== bool.class) {
                //         if (o instanceof string) {
                //             parm = Boolean.valueOf((string)o);
                //         } else if (o instanceof Boolean) {
                //             parm = o;
                //         }
                //     } else if (paramType== byte.class) {
                //         if (o instanceof string) {
                //             parm = Byte.valueOf((string)o);
                //         } else if (o instanceof Byte) {
                //             parm = o;
                //         }
                //     } else if (paramType== short.class) {
                //         if (o instanceof string) {
                //             parm = Short.valueOf((string)o);
                //         } else if (o instanceof Short) {
                //             parm = o;
                //         }
                //     } else if (paramType== char.class) {
                //         if (o instanceof string) {
                //             string str = (string)o;
                //             if (str.length() == 1) {
                //                 parm = Character.valueOf(str[0]);
                //             }
                //         } else if (o instanceof Character) {
                //             parm = o;
                //         }
                //     }
                // } else if ((o !is null) && (paramType.isAssignableFrom(o.getClass()))) {
                //     parm = o;
                // }
                
                // // If the parameter wasn't originally null, but we didn't find a 
                // // matching parameter, then we are stuck.
                // if ((o !is null) && (parm is null)) {
                //     handleError(
                //         "The setter on Job class " ~ metaInfo.getFullName() ~ 
                //         " for property '" ~ name ~
                //         "' expects a " ~ paramType + 
                //         " but was given " ~ typeid(o).name);
                //     continue;
                // }
                                
                // setMeth.invoke(obj, new Object[]{ parm });
            } catch (NumberFormatException nfe) {
                handleError(
                    "The setter on Job class " ~ metaInfo.getFullName() ~ 
                    " for property '" ~ name ~
                    "' expects a " ~ paramType.toString() ~ 
                    " but was given " ~ typeid(o).name, nfe);
            } catch (IllegalArgumentException e) {
                handleError(
                    "The setter on Job class " ~ metaInfo.getFullName() ~ 
                    " for property '" ~ name ~
                    "' expects a " ~ paramType.toString() ~ 
                    " but was given " ~ typeid(o).name, e);
            // } catch (IllegalAccessException e) {
            //     handleError(
            //         "The setter on Job class " ~ metaInfo.getFullName() ~ 
            //         " for property '" ~ name ~
            //         "' could not be accessed.", e);
            // } catch (InvocationTargetException e) {
            //     handleError(
            //         "The setter on Job class " ~ metaInfo.getFullName() ~ 
            //         " for property '" ~ name ~
            //         "' could not be invoked.", e);
            } catch(Exception ex) {
                handleError("Unhandled error.", ex);
            }
        }
    }
     
    private void handleError(string message) {
        handleError(message, null);
    }
    
    private void handleError(string message, Exception e) {
        if (isThrowIfPropertyNotFound()) {
            throw new SchedulerException(message, e);
        }
        
        if (isWarnIfPropertyNotFound()) {
            if (e is null) {
                warning(message);
            } else {
                warning(message, e);
            }
        }
    }
    
    // private java.lang.reflect.Method getSetMethod(string name,
    //         PropertyDescriptor[] props) {
    //     for (int i = 0; i < props.length; i++) {
    //         java.lang.reflect.Method wMeth = props[i].getWriteMethod();
        
    //         if(wMeth is null) {
    //             continue;
    //         }
            
    //         if(wMeth.getParameterTypes().length != 1) {
    //             continue;
    //         }
            
    //         if (wMeth.getName()== name) {
    //             return wMeth;
    //         }
    //     }
        
    //     return null;
    // }

    /**
     * Whether the JobInstantiation should fail and throw and exception if
     * a key (name) and value (type) found in the JobDataMap does not 
     * correspond to a proptery setter on the Job class.
     *  
     * @return Returns the throwIfNotFound.
     */
    bool isThrowIfPropertyNotFound() {
        return throwIfNotFound;
    }

    /**
     * Whether the JobInstantiation should fail and throw and exception if
     * a key (name) and value (type) found in the JobDataMap does not 
     * correspond to a proptery setter on the Job class.
     *  
     * @param throwIfNotFound defaults to <code>false</code>.
     */
    void setThrowIfPropertyNotFound(bool throwIfNotFound) {
        this.throwIfNotFound = throwIfNotFound;
    }

    /**
     * Whether a warning should be logged if
     * a key (name) and value (type) found in the JobDataMap does not 
     * correspond to a proptery setter on the Job class.
     *  
     * @return Returns the warnIfNotFound.
     */
    bool isWarnIfPropertyNotFound() {
        return warnIfNotFound;
    }

    /**
     * Whether a warning should be logged if
     * a key (name) and value (type) found in the JobDataMap does not 
     * correspond to a proptery setter on the Job class.
     *  
     * @param warnIfNotFound defaults to <code>true</code>.
     */
    void setWarnIfPropertyNotFound(bool warnIfNotFound) {
        this.warnIfNotFound = warnIfNotFound;
    }
}