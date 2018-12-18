
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

module hunt.quartz.impl.jdbcjobstore.UpdateLockRowSemaphore;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * Provide thread/resource locking in order to protect
 * resources from being altered by multiple threads at the same time using
 * a db row update.
 * 
 * <p>
 * <b>Note:</b> This Semaphore implementation is useful for databases that do
 * not support row locking via "SELECT FOR UPDATE" type syntax, for example
 * Microsoft SQLServer (MSSQL).
 * </p> 
 */
class UpdateLockRowSemaphore : DBSemaphore {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Constants.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    enum string UPDATE_FOR_LOCK = 
        "UPDATE " ~ TABLE_PREFIX_SUBST + TABLE_LOCKS + 
        " SET " ~ COL_LOCK_NAME ~ " = " ~ COL_LOCK_NAME +
        " WHERE " ~ COL_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
        ~ " AND " ~ COL_LOCK_NAME ~ " = ? ";


    enum string INSERT_LOCK = "INSERT INTO "
        + TABLE_PREFIX_SUBST + TABLE_LOCKS ~ "(" ~ COL_SCHEDULER_NAME ~ ", " ~ COL_LOCK_NAME ~ ") VALUES (" 
        + SCHED_NAME_SUBST ~ ", ?)"; 
    
    private enum int RETRY_COUNT = 2;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Constructors.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    UpdateLockRowSemaphore() {
        super(DEFAULT_TABLE_PREFIX, null, UPDATE_FOR_LOCK, INSERT_LOCK);
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
        SQLException lastFailure = null;
        for (int i = 0; i < RETRY_COUNT; i++) {
            try {
                if (!lockViaUpdate(conn, lockName, expandedSQL)) {
                    lockViaInsert(conn, lockName, expandedInsertSQL);
                }
                return;
            } catch (SQLException e) {
                lastFailure = e;
                if ((i + 1) == RETRY_COUNT) {
                    trace("Lock '{}' was not obtained by: {}", lockName, Thread.getThis().name());
                } else {
                    trace("Lock '{}' was not obtained by: {} - will try again.", lockName, Thread.getThis().name());
                }
                try {
                    Thread.sleep(1000L);
                } catch (InterruptedException _) {
                    Thread.getThis().interrupt();
                }
            }
        }
        throw new LockException("Failure obtaining db row lock: " ~ lastFailure.getMessage(), lastFailure);
    }
    
    protected string getUpdateLockRowSQL() {
        return getSQL();
    }

    void setUpdateLockRowSQL(string updateLockRowSQL) {
        setSQL(updateLockRowSQL);
    }

    private bool lockViaUpdate(Connection conn, string lockName, string sql) {
        PreparedStatement ps = conn.prepareStatement(sql);
        try {
            ps.setString(1, lockName);
            trace("Lock '" ~ lockName ~ "' is being obtained: " ~ Thread.getThis().name());
            return ps.executeUpdate() >= 1;
        } finally {
            ps.close();
        }
    }

    private void lockViaInsert(Connection conn, string lockName, string sql) {
        trace("Inserting new lock row for lock: '" ~ lockName ~ "' being obtained by thread: " ~ Thread.getThis().name());
        PreparedStatement ps = conn.prepareStatement(sql);
        try {
            ps.setString(1, lockName);
            if(ps.executeUpdate() != 1) {
                throw new SQLException(Util.rtp(
                    "No row exists, and one could not be inserted in table " ~ TABLE_PREFIX_SUBST + TABLE_LOCKS + 
                    " for lock named: " ~ lockName, getTablePrefix(), getSchedulerNameLiteral()));
            }
        } finally {
            ps.close();
        }
    }
}
