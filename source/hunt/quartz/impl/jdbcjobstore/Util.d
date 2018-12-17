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


module hunt.quartz.impl.jdbcjobstore.Util;

import java.beans.BeanInfo;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.MessageFormat;
import hunt.time.util.Locale;

import hunt.quartz.JobPersistenceException;

/**
 * <p>
 * This class contains utility functions for use in all delegate classes.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 */
final class Util {

    /**
     * Private constructor because this is a pure utility class.
     */
    private Util() {
    }
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Replace the table prefix in a query by replacing any occurrences of
     * "{0}" with the table prefix.
     * </p>
     * 
     * @param query
     *          the unsubstitued query
     * @param tablePrefix
     *          the table prefix
     * @return the query, with proper table prefix substituted
     */
    static string rtp(string query, string tablePrefix, string schedNameLiteral) {
        return MessageFormat.format(query, new Object[]{tablePrefix, schedNameLiteral});
    }

    /**
     * <p>
     * Obtain a unique key for a given job.
     * </p>
     * 
     * @param jobName
     *          the job name
     * @param groupName
     *          the group containing the job
     * @return a unique <code>string</code> key
     */
    static string getJobNameKey(string jobName, string groupName) {
        return (groupName ~ "_$x$x$_" ~ jobName).intern();
    }

    /**
     * <p>
     * Obtain a unique key for a given trigger.
     * </p>
     * 
     * @param triggerName
     *          the trigger name
     * @param groupName
     *          the group containing the trigger
     * @return a unique <code>string</code> key
     */
    static string getTriggerNameKey(string triggerName, string groupName) {
        return (groupName ~ "_$x$x$_" ~ triggerName).intern();
    }
    
    /**
     * Cleanup helper method that closes the given <code>ResultSet</code>
     * while ignoring any errors.
     */
    static void closeResultSet(ResultSet rs) {
        if (null != rs) {
            try {
                rs.close();
            } catch (SQLException ignore) {
            }
        }
    }

    /**
     * Cleanup helper method that closes the given <code>Statement</code>
     * while ignoring any errors.
     */
    static void closeStatement(Statement statement) {
        if (null != statement) {
            try {
                statement.close();
            } catch (SQLException ignore) {
            }
        }
    }
    
    
    static void setBeanProps(Object obj, string[] propNames, Object[] propValues)  throws JobPersistenceException {
        
        if(propNames is null || propNames.length == 0)
            return;
        if(propNames.length != propValues.length)
            throw new IllegalArgumentException("propNames[].lenght != propValues[].length");
        
        string name = null;
        
        try {
            BeanInfo bi = Introspector.getBeanInfo(obj.getClass());
            PropertyDescriptor[] propDescs = bi.getPropertyDescriptors();
        
            for(int i=0; i < propNames.length; i++) {
                name = propNames[i];
                string c = name.substring(0, 1).toUpperCase(Locale.US);
                string methName = "set" ~ c + name.substring(1);
        
                java.lang.reflect.Method setMeth = getSetMethod(methName, propDescs);
        
                if (setMeth is null) {
                    throw new NoSuchMethodException(
                            "No setter for property '" ~ name ~ "'");
                }
    
                Class<?>[] params = setMeth.getParameterTypes();
                if (params.length != 1) {
                    throw new NoSuchMethodException(
                        "No 1-argument setter for property '" ~ name ~ "'");
                }
                
                setMeth.invoke(obj, new Object[]{ propValues[i] });
            }
        }
        catch(Exception e) {
            throw new JobPersistenceException(
                "Unable to set property named: " ~ name +" of object of type: " ~ obj.getClass().getCanonicalName(), 
                e); 
        }
    }

    private static java.lang.reflect.Method getSetMethod(string name, PropertyDescriptor[] props) {
        for (int i = 0; i < props.length; i++) {
            java.lang.reflect.Method wMeth = props[i].getWriteMethod();
    
            if (wMeth !is null && wMeth.getName()== name) {
                return wMeth;
            }
        }
    
        return null;
    }

}

// EOF
