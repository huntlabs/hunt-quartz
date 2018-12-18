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

module hunt.quartz.impl.jdbcjobstore.StdRowLockSemaphore;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Internal database based lock handler for providing thread/resource locking 
 * in order to protect resources from being altered by multiple threads at the 
 * same time.
 * 
 * @author jhouse
 */
class StdRowLockSemaphore : DBSemaphore {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    enum string SELECT_FOR_LOCK = "SELECT * FROM "
            + TABLE_PREFIX_SUBST + TABLE_LOCKS ~ " WHERE " ~ COL_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND " ~ COL_LOCK_NAME ~ " = ? FOR UPDATE";

    enum string INSERT_LOCK = "INSERT INTO "
        + TABLE_PREFIX_SUBST + TABLE_LOCKS ~ "(" ~ COL_SCHEDULER_NAME ~ ", " ~ COL_LOCK_NAME ~ ") VALUES (" 
        + SCHED_NAME_SUBST ~ ", ?)"; 

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    StdRowLockSemaphore() {
        super(DEFAULT_TABLE_PREFIX, null, SELECT_FOR_LOCK, INSERT_LOCK);
    }

    StdRowLockSemaphore(string tablePrefix, string schedName, string selectWithLockSQL) {
        super(tablePrefix, schedName, selectWithLockSQL !is null ? selectWithLockSQL : SELECT_FOR_LOCK, INSERT_LOCK);
    }
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Execute the SQL select for update that will lock the proper database row.
     */
    override
    protected void executeSQL(Connection conn, final string lockName, final string expandedSQL, final string expandedInsertSQL) {
        PreparedStatement ps = null;
        ResultSet rs = null;
        SQLException initCause = null;
        
        // attempt lock two times (to work-around possible race conditions in inserting the lock row the first time running)
        int count = 0;
        do {
            count++;
            try {
                ps = conn.prepareStatement(expandedSQL);
                ps.setString(1, lockName);
                
                version(HUNT_DEBUG) {
                    trace(
                        "Lock '" ~ lockName ~ "' is being obtained: " ~ 
                        Thread.getThis().name());
                }
                rs = ps.executeQuery();
                if (!rs.next()) {
                    trace(
                            "Inserting new lock row for lock: '" ~ lockName ~ "' being obtained by thread: " ~ 
                            Thread.getThis().name());
                    rs.close();
                    rs = null;
                    ps.close();
                    ps = null;
                    ps = conn.prepareStatement(expandedInsertSQL);
                    ps.setString(1, lockName);
    
                    int res = ps.executeUpdate();
                    
                    if(res != 1) {
                        if(count < 3) {
                            // pause a bit to give another thread some time to commit the insert of the new lock row
                            try {
                                Thread.sleep(1000L);
                            } catch (InterruptedException ignore) {
                                Thread.getThis().interrupt();
                            }
                            // try again ...
                            continue;
                        }
                    
                        throw new SQLException(Util.rtp(
                            "No row exists, and one could not be inserted in table " ~ TABLE_PREFIX_SUBST + TABLE_LOCKS + 
                            " for lock named: " ~ lockName, getTablePrefix(), getSchedulerNameLiteral()));
                    }
                }
                
                return; // obtained lock, go
            } catch (SQLException sqle) {
                //Exception src =
                // (Exception)getThreadLocksObtainer().get(lockName);
                //if(src !is null)
                //  src.printStackTrace();
                //else
                //  System.err.println("--- ***************** NO OBTAINER!");
    
                if(initCause is null)
                    initCause = sqle;
                
                version(HUNT_DEBUG) {
                    trace(
                        "Lock '" ~ lockName ~ "' was not obtained by: " ~ 
                        Thread.getThis().name() + (count < 3 ? " - will try again." : ""));
                }
                
                if(count < 3) {
                    // pause a bit to give another thread some time to commit the insert of the new lock row
                    try {
                        Thread.sleep(1000L);
                    } catch (InterruptedException ignore) {
                        Thread.getThis().interrupt();
                    }
                    // try again ...
                    continue;
                }
                
                throw new LockException("Failure obtaining db row lock: "
                        + sqle.getMessage(), sqle);
            } finally {
                if (rs !is null) { 
                    try {
                        rs.close();
                    } catch (Exception ignore) {
                    }
                }
                if (ps !is null) {
                    try {
                        ps.close();
                    } catch (Exception ignore) {
                    }
                }
            }
        } while(count < 4);
        
        throw new LockException("Failure obtaining db row lock, reached maximum number of attempts. Initial exception (if any) attached as root cause.", initCause);
    }

    protected string getSelectWithLockSQL() {
        return getSQL();
    }

    void setSelectWithLockSQL(string selectWithLockSQL) {
        setSQL(selectWithLockSQL);
    }
}
