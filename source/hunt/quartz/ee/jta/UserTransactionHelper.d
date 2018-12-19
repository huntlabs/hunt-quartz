
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

module hunt.quartz.ee.jta.UserTransactionHelper;

import javax.naming.InitialContext;
import javax.transaction.HeuristicMixedException;
import javax.transaction.HeuristicRollbackException;
import javax.transaction.NotSupportedException;
import javax.transaction.RollbackException;
import javax.transaction.SystemException;
import javax.transaction.UserTransaction;

import hunt.quartz.SchedulerException;
import hunt.logging;


/**
 * <p>
 * A helper for obtaining a handle to a UserTransaction...
 * </p>
 * <p>
 * To ensure proper cleanup of the InitalContext used to create/lookup
 * the UserTransaction, be sure to always call returnUserTransaction() when
 * you are done with the UserTransaction. 
 * </p>
 * 
 * @author James House
 */
class UserTransactionHelper {
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    enum string DEFAULT_USER_TX_LOCATION = "java:comp/UserTransaction";
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private static string userTxURL = DEFAULT_USER_TX_LOCATION;
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Do not allow the creation of an all static utility class.
     */
    private this() {
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    static string getUserTxLocation() {
        return userTxURL;
    }

    /**
     * Set the JNDI URL at which the Application Server's UserTransaction can
     * be found. If not set, the default value is "java:comp/UserTransaction" -
     * which works for nearly all application servers.
     */
    static void setUserTxLocation(string userTxURL) {
        if (userTxURL !is null) {
            UserTransactionHelper.userTxURL = userTxURL;
        }
    }

    /**
     * Create/Lookup a UserTransaction in the InitialContext via the
     * name set in setUserTxLocation().
     */
    static UserTransaction lookupUserTransaction() {
        return new UserTransactionWithContext();
    }
    
    /**
     * Return a UserTransaction that was retrieved via getUserTransaction().
     * This will make sure that the InitalContext used to lookup/create the 
     * UserTransaction is properly cleaned up.
     */
    static void returnUserTransaction(UserTransaction userTransaction) {
        UserTransactionWithContext userTransactionWithContext = 
            cast(UserTransactionWithContext)userTransaction;
        if (userTransactionWithContext !is null) {
            userTransactionWithContext.closeContext();
        }
    }
}


/**
 * This class wraps a UserTransaction with the InitialContext that was used
 * to look it up, so that when the UserTransaction is returned to the 
 * UserTransactionHelper the InitialContext can be closed.
 */
private class UserTransactionWithContext : UserTransaction {
    InitialContext context;
    UserTransaction userTransaction;
    
    this() {
        try {
            context = new InitialContext();
        } catch (Throwable t) {
            throw new SchedulerException(
                "UserTransactionHelper failed to create InitialContext to lookup/create UserTransaction.", t);
        }
        
        try {
            userTransaction = cast(UserTransaction)context.lookup(userTxURL);
        } catch (Throwable t) {
            closeContext();
            throw new SchedulerException(
                "UserTransactionHelper could not lookup/create UserTransaction.",
                t);
        }
        
        if (userTransaction is null) {
            closeContext();
            throw new SchedulerException(
                "UserTransactionHelper could not lookup/create UserTransaction from the InitialContext.");
        }
    }

    /**
     * Close the InitialContext that was used to lookup/create the
     * underlying UserTransaction.
     */
    void closeContext() {
        try {
            if (context !is null) {
                context.close();
            }
        } catch (Throwable t) {
            warning("Failed to close InitialContext used to get a UserTransaction.", t);
        }
        context = null;
    }

    /**
     * When we are being garbage collected, make sure we were properly
     * returned to the UserTransactionHelper.
     */
    override
    protected void finalize() {
        try {
            if (context !is null) {
                warning("UserTransaction was never returned to the UserTransactionHelper.");
                closeContext();
            }
        } finally {
            super.finalize();
        }
    }

    
    // Wrapper methods that just delegate to the underlying UserTransaction
    
    void begin() {
        userTransaction.begin();
    }

    void commit() {
        userTransaction.commit();        
    }

    void rollback() {
        userTransaction.rollback();
    }

    void setRollbackOnly() {
        userTransaction.setRollbackOnly();
    }

    int getStatus() {
        return userTransaction.getStatus();
    }

    void setTransactionTimeout(int seconds) {
        userTransaction.setTransactionTimeout(seconds);
    }
}