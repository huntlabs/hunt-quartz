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
 */
module hunt.quartz.impl.jdbcjobstore.AttributeRestoringConnectionInvocationHandler;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.SQLException;

import hunt.logging;


/**
 * <p>
 * Protects a <code>{@link java.sql.Connection}</code>'s attributes from being permanently modfied.
 * </p>
 * 
 * <p>
 * Wraps a provided <code>{@link java.sql.Connection}</code> such that its auto 
 * commit and transaction isolation attributes can be overwritten, but 
 * will automatically restored to their original values when the connection
 * is actually closed (and potentially returned to a pool for reuse).
 * </p>
 * 
 * @see hunt.quartz.impl.jdbcjobstore.JobStoreSupport#getConnection()
 * @see hunt.quartz.impl.jdbcjobstore.JobStoreCMT#getNonManagedTXConnection()
 */
class AttributeRestoringConnectionInvocationHandler : InvocationHandler {
    private Connection conn;
    
    private bool overwroteOriginalAutoCommitValue;
    private bool overwroteOriginalTxIsolationValue;

    // Set if overwroteOriginalAutoCommitValue is true
    private bool originalAutoCommitValue; 

    // Set if overwroteOriginalTxIsolationValue is true
    private int originalTxIsolationValue;
    
    AttributeRestoringConnectionInvocationHandler(
        Connection conn) {
        this.conn = conn;
    }

    
    Object invoke(Object proxy, Method method, Object[] args) {
        if (method.getName().equals("setAutoCommit")) {
            setAutoCommit(((Boolean)args[0]).booleanValue());
        } else if (method.getName().equals("setTransactionIsolation")) {
            setTransactionIsolation(((Integer)args[0]).intValue());
        } else if (method.getName().equals("close")) {
            close();
        } else {
            try {
                return method.invoke(conn, args);
            }
            catch(InvocationTargetException ite) {
                throw (ite.getCause() !is null ? ite.getCause() : ite);
            }
            
        }
        
        return null;
    }
     
    /**
     * Sets this connection's auto-commit mode to the given state, saving
     * the original mode.  The connection's original auto commit mode is restored
     * when the connection is closed.
     */
    void setAutoCommit(bool autoCommit) {
        bool currentAutoCommitValue = conn.getAutoCommit();
            
        if (autoCommit != currentAutoCommitValue) {
            if (overwroteOriginalAutoCommitValue == false) {
                overwroteOriginalAutoCommitValue = true;
                originalAutoCommitValue = currentAutoCommitValue;
            }
            
            conn.setAutoCommit(autoCommit);
        }
    }

    /**
     * Attempts to change the transaction isolation level to the given level, saving
     * the original level.  The connection's original transaction isolation level is 
     * restored when the connection is closed.
     */
    void setTransactionIsolation(int level) {
        int currentLevel = conn.getTransactionIsolation();
        
        if (level != currentLevel) {
            if (overwroteOriginalTxIsolationValue == false) {
                overwroteOriginalTxIsolationValue = true;
                originalTxIsolationValue = currentLevel;
            }
            
            conn.setTransactionIsolation(level);
        }
    }
    
    /**
     * Gets the underlying connection to which all operations ultimately 
     * defer.  This is provided in case a user ever needs to punch through 
     * the wrapper to access vendor specific methods outside of the 
     * standard <code>java.sql.Connection</code> interface.
     * 
     * @return The underlying connection to which all operations
     * ultimately defer.
     */
    Connection getWrappedConnection() {
        return conn;
    }

    /**
     * Attempts to restore the auto commit and transaction isolation connection
     * attributes of the wrapped connection to their original values (if they
     * were overwritten).
     */
    void restoreOriginalAtributes() {
        try {
            if (overwroteOriginalAutoCommitValue) {
                conn.setAutoCommit(originalAutoCommitValue);
            }
        } catch (Throwable t) {
            warning("Failed restore connection's original auto commit setting.", t);
        }
        
        try {    
            if (overwroteOriginalTxIsolationValue) {
                conn.setTransactionIsolation(originalTxIsolationValue);
            }
        } catch (Throwable t) {
            warning("Failed restore connection's original transaction isolation setting.", t);
        }
    }
    
    /**
     * Attempts to restore the auto commit and transaction isolation connection
     * attributes of the wrapped connection to their original values (if they
     * were overwritten), before finally actually closing the wrapped connection.
     */
    void close() {
        restoreOriginalAtributes();
        
        conn.close();
    }
}
