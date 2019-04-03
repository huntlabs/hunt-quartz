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

module hunt.quartz.dbstore.StdSqlConstants;

import hunt.quartz.dbstore.TableConstants;
import hunt.quartz.dbstore.model;
import hunt.quartz.Trigger;

/**
 * <p>
 * This interface extends <code>{@link
 * hunt.quartz.impl.jdbcjobstore.Constants}</code>
 * to include the query string constants in use by the <code>{@link
 * hunt.quartz.impl.jdbcjobstore.StdJDBCDelegate}</code>
 * class.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 */
struct StdSqlConstants {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    // table prefix substitution string
    enum string TABLE_PREFIX_SUBST = "{0}";

    // table prefix substitution string
    enum string SCHED_NAME_SUBST = "%s";

    // QUERIES
    enum string UPDATE_TRIGGER_STATES_FROM_OTHER_STATES = "UPDATE "
            ~ ModelConstants.MODEL_TRIGGERS
            ~ " t SET t."
            ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ?"
            ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME 
            ~ " = " ~ SCHED_NAME_SUBST ~ " AND (t."
            ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ? OR t."
            ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?)";

//     enum string SELECT_MISFIRED_TRIGGERS = "SELECT * FROM "
//         ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
//         ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
//         ~ " AND NOT ("
//         ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ " = " ~ Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY ~ ") AND t." 
//         ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " < ? "
//         ~ "ORDER BY " ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " ASC, " ~ ModelConstants.FIELD_PRIORITY ~ " DESC";
    
//     enum string SELECT_TRIGGERS_IN_STATE = "SELECT "
//             ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", " ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM "
//             ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
//             ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST ~ " AND t."
//             ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?";

//     enum string SELECT_MISFIRED_TRIGGERS_IN_STATE = "SELECT "
//         ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", " ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM "
//         ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
//         ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST ~ " AND NOT ("
//         ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ " = " ~ Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY ~ ") AND t." 
//         ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " < ? AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ? "
//         ~ "ORDER BY " ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " ASC, " ~ ModelConstants.FIELD_PRIORITY ~ " DESC";

//     enum string COUNT_MISFIRED_TRIGGERS_IN_STATE = "SELECT COUNT("
//         ~ ModelConstants.FIELD_TRIGGER_NAME ~ ") FROM "
//         ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
//         ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST ~ " AND NOT ("
//         ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ " = " ~ Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY ~ ") AND t." 
//         ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " < ? " 
//         ~ "AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?";
    
//     enum string SELECT_HAS_MISFIRED_TRIGGERS_IN_STATE = "SELECT "
//         ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", " ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM "
//         ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
//         ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST ~ " AND NOT ("
//         ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ " = " ~ Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY ~ ") AND t." 
//         ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " < ? " 
//         ~ "AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ? "
//         ~ "ORDER BY " ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " ASC, " ~ ModelConstants.FIELD_PRIORITY ~ " DESC";

//     enum string SELECT_MISFIRED_TRIGGERS_IN_GROUP_IN_STATE = "SELECT "
//         ~ ModelConstants.FIELD_TRIGGER_NAME
//         ~ " FROM "
//         ~ ModelConstants.MODEL_TRIGGERS
//         ~ " t WHERE t."
//         ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST ~ " AND NOT ("
//         ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ " = " ~ Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY ~ ") AND t." 
//         ~ ModelConstants.FIELD_NEXT_FIRE_TIME
//         ~ " < ? AND t."
//         ~ ModelConstants.FIELD_TRIGGER_GROUP
//         ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ? "
//         ~ "ORDER BY " ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " ASC, " ~ ModelConstants.FIELD_PRIORITY ~ " DESC";


    enum string DELETE_FIRED_TRIGGERS = "DELETE FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS
            ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
            
    enum string INSERT_JOB_DETAIL = "INSERT INTO "
            ~ ModelConstants.MODEL_JOB_DETAILS ~ " t (t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", t." ~ ModelConstants.FIELD_JOB_NAME
            ~ ", t." ~ ModelConstants.FIELD_JOB_GROUP ~ ", t." ~ ModelConstants.FIELD_DESCRIPTION ~ ", t."
            ~ ModelConstants.FIELD_JOB_CLASS ~ ", t." ~ ModelConstants.FIELD_IS_DURABLE ~ ", t." 
            ~ ModelConstants.FIELD_IS_NONCONCURRENT ~  ", t." ~ ModelConstants.FIELD_IS_UPDATE_DATA ~ ", t." 
            ~ ModelConstants.FIELD_REQUESTS_RECOVERY ~ ", t."
            ~ ModelConstants.FIELD_JOB_DATAMAP ~ ") " ~ " VALUES(" ~ SCHED_NAME_SUBST ~ ", ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    enum string UPDATE_JOB_DETAIL = "UPDATE "
            ~ ModelConstants.MODEL_JOB_DETAILS ~ " SET "
            ~ ModelConstants.FIELD_DESCRIPTION ~ " = ?, " ~ ModelConstants.FIELD_JOB_CLASS ~ " = ?, "
            ~ ModelConstants.FIELD_IS_DURABLE ~ " = ?, " 
            ~ ModelConstants.FIELD_IS_NONCONCURRENT ~ " = ?, " ~ ModelConstants.FIELD_IS_UPDATE_DATA ~ " = ?, " 
            ~ ModelConstants.FIELD_REQUESTS_RECOVERY ~ " = ?, "
            ~ ModelConstants.FIELD_JOB_DATAMAP ~ " = ? " ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string SELECT_TRIGGERS_FOR_JOB = "SELECT t."
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM "
            ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string SELECT_TRIGGERS_FOR_CALENDAR = "SELECT t."
        ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM "
        ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
        ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
        ~ " AND t." ~ ModelConstants.FIELD_CALENDAR_NAME
        ~ " = ?";

    enum string DELETE_JOB_DETAIL = "DELETE FROM "
            ~ ModelConstants.MODEL_JOB_DETAILS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string SELECT_JOB_NONCONCURRENT = "SELECT "
            ~ ModelConstants.FIELD_IS_NONCONCURRENT ~ " FROM " ~ ModelConstants.MODEL_JOB_DETAILS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string SELECT_JOB_EXISTENCE = "SELECT t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " FROM " ~ ModelConstants.MODEL_JOB_DETAILS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string UPDATE_JOB_DATA = "UPDATE " ~ ModelConstants.MODEL_JOB_DETAILS ~ " SET " ~ ModelConstants.FIELD_JOB_DATAMAP ~ " = ? "
            ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string SELECT_JOB_DETAIL = "SELECT *" ~ " FROM "
            ~ ModelConstants.MODEL_JOB_DETAILS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";
            

    enum string SELECT_NUM_JOBS = "SELECT COUNT(" ~ ModelConstants.FIELD_JOB_NAME
            ~ ") " ~ " FROM " ~ ModelConstants.MODEL_JOB_DETAILS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string SELECT_JOB_GROUPS = "SELECT DISTINCT("
            ~ ModelConstants.FIELD_JOB_GROUP ~ ") FROM " ~ ModelConstants.MODEL_JOB_DETAILS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string SELECT_JOBS_IN_GROUP_LIKE = "SELECT " ~ ModelConstants.FIELD_JOB_NAME ~ ", " ~ ModelConstants.FIELD_JOB_GROUP
            ~ " FROM " ~ ModelConstants.MODEL_JOB_DETAILS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " LIKE ?";

    enum string SELECT_JOBS_IN_GROUP = "SELECT " ~ ModelConstants.FIELD_JOB_NAME ~ ", " ~ ModelConstants.FIELD_JOB_GROUP
            ~ " FROM " ~ ModelConstants.MODEL_JOB_DETAILS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string INSERT_TRIGGER = "INSERT INTO "
            ~ ModelConstants.MODEL_TRIGGERS ~ " t (t." ~ ModelConstants.FIELD_SCHEDULER_NAME 
            ~ ", t." ~ ModelConstants.FIELD_TRIGGER_NAME
            ~ ", t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ", t." ~ ModelConstants.FIELD_JOB_NAME
            ~ ", t." ~ ModelConstants.FIELD_JOB_GROUP ~ ", t." ~ ModelConstants.FIELD_DESCRIPTION
            ~ ", t." ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ ", t." ~ ModelConstants.FIELD_PREV_FIRE_TIME
            ~ ", t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ ", t." ~ ModelConstants.FIELD_TRIGGER_TYPE
            ~ ", t." ~ ModelConstants.FIELD_START_TIME ~ ", t." ~ ModelConstants.FIELD_END_TIME 
            ~ ", t." ~ ModelConstants.FIELD_CALENDAR_NAME
            ~ ", t." ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ ", t." ~ ModelConstants.FIELD_JOB_DATAMAP 
            ~ ", t." ~ ModelConstants.FIELD_PRIORITY ~ ") "
            ~ " VALUES(" ~ SCHED_NAME_SUBST ~ ", ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    enum string INSERT_SIMPLE_TRIGGER = "INSERT INTO "
            ~ ModelConstants.MODEL_SIMPLE_TRIGGERS ~ " t ( t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", t."
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ", t."
            ~ ModelConstants.FIELD_REPEAT_COUNT ~ ", t." ~ ModelConstants.FIELD_REPEAT_INTERVAL ~ ", t."
            ~ ModelConstants.FIELD_TIMES_TRIGGERED ~ ") " ~ " VALUES(" ~ SCHED_NAME_SUBST ~ ", ?, ?, ?, ?, ?)";

    enum string INSERT_CRON_TRIGGER = "INSERT INTO "
            ~ ModelConstants.MODEL_CRON_TRIGGERS ~ " t ( t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", t."
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ", t."
            ~ ModelConstants.FIELD_CRON_EXPRESSION ~ ", t." ~ ModelConstants.FIELD_TIME_ZONE_ID ~ ") "
            ~ " VALUES(" ~ SCHED_NAME_SUBST ~ ", ?, ?, ?, ?)";

    enum string INSERT_BLOB_TRIGGER = "INSERT INTO "
            ~ ModelConstants.MODEL_BLOB_TRIGGERS ~ " t (t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", t."
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", t." 
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ", t." ~ ModelConstants.FIELD_BLOB
            ~ ") " ~ " VALUES(" ~ SCHED_NAME_SUBST ~ ", ?, ?, ?)";

    enum string UPDATE_TRIGGER_SKIP_DATA = "UPDATE " ~ ModelConstants.MODEL_TRIGGERS ~ " SET " ~ ModelConstants.FIELD_JOB_NAME ~ " = ?, "
            ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?, " 
            ~ ModelConstants.FIELD_DESCRIPTION ~ " = ?, " ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " = ?, "
            ~ ModelConstants.FIELD_PREV_FIRE_TIME ~ " = ?, " ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?, "
            ~ ModelConstants.FIELD_TRIGGER_TYPE ~ " = ?, " ~ ModelConstants.FIELD_START_TIME ~ " = ?, "
            ~ ModelConstants.FIELD_END_TIME ~ " = ?, " ~ ModelConstants.FIELD_CALENDAR_NAME ~ " = ?, "
            ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ " = ?, " ~ ModelConstants.FIELD_PRIORITY 
            ~ " = ? WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string UPDATE_TRIGGER = "UPDATE " ~ ModelConstants.MODEL_TRIGGERS ~ " SET " ~ ModelConstants.FIELD_JOB_NAME ~ " = ?, "
        ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?, "
        ~ ModelConstants.FIELD_DESCRIPTION ~ " = ?, " ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " = ?, "
        ~ ModelConstants.FIELD_PREV_FIRE_TIME ~ " = ?, " ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?, "
        ~ ModelConstants.FIELD_TRIGGER_TYPE ~ " = ?, " ~ ModelConstants.FIELD_START_TIME ~ " = ?, "
        ~ ModelConstants.FIELD_END_TIME ~ " = ?, " ~ ModelConstants.FIELD_CALENDAR_NAME ~ " = ?, "
        ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ " = ?, " ~ ModelConstants.FIELD_PRIORITY ~ " = ?, " 
        ~ ModelConstants.FIELD_JOB_DATAMAP ~ " = ? WHERE t." 
        ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
        ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";
    
    enum string UPDATE_SIMPLE_TRIGGER = "UPDATE "
            ~ ModelConstants.MODEL_SIMPLE_TRIGGERS ~ " t SET t."
            ~ ModelConstants.FIELD_REPEAT_COUNT ~ " = ?, t." ~ ModelConstants.FIELD_REPEAT_INTERVAL ~ " = ?, t."
            ~ ModelConstants.FIELD_TIMES_TRIGGERED ~ " = ? WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string UPDATE_CRON_TRIGGER = "UPDATE "
            ~ ModelConstants.MODEL_CRON_TRIGGERS ~ " SET "
            ~ ModelConstants.FIELD_CRON_EXPRESSION ~ " = ?, " ~ ModelConstants.FIELD_TIME_ZONE_ID  
            ~ " = ? WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME
            ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string UPDATE_BLOB_TRIGGER = "UPDATE "
            ~ ModelConstants.MODEL_BLOB_TRIGGERS ~ " SET " ~ ModelConstants.FIELD_BLOB
            ~ " = ? WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t."
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_TRIGGER_EXISTENCE = "SELECT t."
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ " FROM " ~ ModelConstants.MODEL_TRIGGERS
            ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP
            ~ " = ?";

    enum string UPDATE_TRIGGER_STATE = "UPDATE "
            ~ ModelConstants.MODEL_TRIGGERS ~ " SET " ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ?" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t."
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string UPDATE_TRIGGER_STATE_FROM_STATE = "UPDATE "
            ~ ModelConstants.MODEL_TRIGGERS ~ " SET " ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ?" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t."
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?";

    enum string UPDATE_TRIGGER_GROUP_STATE_FROM_STATE = "UPDATE "
            ~ ModelConstants.MODEL_TRIGGERS
            ~ " SET "
            ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ?"
            ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP
            ~ " LIKE ? AND t."
            ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?";

    enum string UPDATE_TRIGGER_STATE_FROM_STATES = "UPDATE "
            ~ ModelConstants.MODEL_TRIGGERS ~ " SET " ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ?" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t."
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ? AND (" ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ? OR "
            ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ? OR " ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?)";

    enum string UPDATE_TRIGGER_GROUP_STATE_FROM_STATES = "UPDATE "
            ~ ModelConstants.MODEL_TRIGGERS
            ~ " SET "
            ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ?"
            ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP
            ~ " LIKE ? AND ("
            ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ? OR "
            ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ? OR "
            ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?)";

    enum string UPDATE_JOB_TRIGGER_STATES = "UPDATE "
            ~ ModelConstants.MODEL_TRIGGERS ~ " SET " ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ? WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP
            ~ " = ?";

    enum string UPDATE_JOB_TRIGGER_STATES_FROM_OTHER_STATE = "UPDATE "
            ~ ModelConstants.MODEL_TRIGGERS
            ~ " SET "
            ~ ModelConstants.FIELD_TRIGGER_STATE
            ~ " = ? WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME
            ~ " = ? AND t."
            ~ ModelConstants.FIELD_JOB_GROUP
            ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ?";

    enum string DELETE_SIMPLE_TRIGGER = "DELETE FROM "
            ~ ModelConstants.MODEL_SIMPLE_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string DELETE_CRON_TRIGGER = "DELETE FROM "
            ~ ModelConstants.MODEL_CRON_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string DELETE_BLOB_TRIGGER = "DELETE FROM "
            ~ ModelConstants.MODEL_BLOB_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string DELETE_TRIGGER = "DELETE FROM "
            ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_NUM_TRIGGERS_FOR_JOB = "SELECT COUNT("
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ") FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST ~ " AND t." 
            ~ ModelConstants.FIELD_JOB_NAME ~ " = ? AND t."
            ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string SELECT_JOB_FOR_TRIGGER = "SELECT J."
            ~ ModelConstants.FIELD_JOB_NAME ~ ", J." ~ ModelConstants.FIELD_JOB_GROUP ~ ", J." ~ ModelConstants.FIELD_IS_DURABLE
            ~ ", J." ~ ModelConstants.FIELD_JOB_CLASS ~ ", J." ~ ModelConstants.FIELD_REQUESTS_RECOVERY ~ " FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " T, " ~ ModelConstants.MODEL_JOB_DETAILS
            ~ " J WHERE T." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND J." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST 
            ~ " AND T." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND T."
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ? AND T." ~ ModelConstants.FIELD_JOB_NAME ~ " = J."
            ~ ModelConstants.FIELD_JOB_NAME ~ " AND T." ~ ModelConstants.FIELD_JOB_GROUP ~ " = J."
            ~ ModelConstants.FIELD_JOB_GROUP;

    enum string SELECT_TRIGGER = "SELECT * FROM "
            ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_TRIGGER_DATA = "SELECT " ~ 
            ModelConstants.FIELD_JOB_DATAMAP ~ " FROM "
            ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";
        
    enum string SELECT_TRIGGER_STATE = "SELECT "
            ~ ModelConstants.FIELD_TRIGGER_STATE ~ " FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t."
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_TRIGGER_STATUS = "SELECT t."
            ~ ModelConstants.FIELD_TRIGGER_STATE ~ ", t." ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ ", t."
            ~ ModelConstants.FIELD_JOB_NAME ~ ", t." ~ ModelConstants.FIELD_JOB_GROUP ~ " FROM "
            ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_SIMPLE_TRIGGER = "SELECT *" ~ " FROM "
            ~ ModelConstants.MODEL_SIMPLE_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_CRON_TRIGGER = "SELECT *" ~ " FROM "
            ~ ModelConstants.MODEL_CRON_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_BLOB_TRIGGER = "SELECT *" ~ " FROM "
            ~ ModelConstants.MODEL_BLOB_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_NUM_TRIGGERS = "SELECT COUNT("
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ") " ~ " FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string SELECT_NUM_TRIGGERS_IN_GROUP = "SELECT COUNT("
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ") " ~ " FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

//     enum string SELECT_NUM_TRIGGERS_IN_GROUP = "SELECT COUNT("
//             ~ TableConstants.COL_TRIGGER_NAME ~ ") " ~ " FROM " ~ TABLE_PREFIX_SUBST ~ TableConstants.TABLE_TRIGGERS ~ " WHERE " 
//             ~ TableConstants.COL_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
//             ~ " AND " ~ TableConstants.COL_TRIGGER_GROUP ~ " = ?";
           

    enum string SELECT_TRIGGER_GROUPS = "SELECT DISTINCT("
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ") FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string SELECT_TRIGGER_GROUPS_FILTERED = "SELECT DISTINCT("
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ") FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST ~ " AND t." 
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " LIKE ?";

    enum string SELECT_TRIGGERS_IN_GROUP_LIKE = "SELECT t."
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM " 
            ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " LIKE ?";

    enum string SELECT_TRIGGERS_IN_GROUP = "SELECT t."
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM " 
            ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string INSERT_CALENDAR = "INSERT INTO "
            ~ ModelConstants.MODEL_CALENDARS ~ " t ( t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", t." 
            ~ ModelConstants.FIELD_CALENDAR_NAME
            ~ ", t." ~ ModelConstants.FIELD_CALENDAR ~ ") " ~ " VALUES(" ~ SCHED_NAME_SUBST ~ ", ?, ?)";

    enum string UPDATE_CALENDAR = "UPDATE " ~ ModelConstants.MODEL_CALENDARS ~ " SET " 
            ~ ModelConstants.FIELD_CALENDAR ~ " = ? " ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_CALENDAR_NAME ~ " = ?";

    enum string SELECT_CALENDAR_EXISTENCE = "SELECT "
            ~ ModelConstants.FIELD_CALENDAR_NAME ~ " FROM " ~ ModelConstants.MODEL_CALENDARS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_CALENDAR_NAME ~ " = ?";

    enum string SELECT_CALENDAR = "SELECT *" ~ " FROM "
            ~ ModelConstants.MODEL_CALENDARS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_CALENDAR_NAME ~ " = ?";

    enum string SELECT_REFERENCED_CALENDAR = "SELECT "
            ~ ModelConstants.FIELD_CALENDAR_NAME ~ " FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_CALENDAR_NAME ~ " = ?";

    enum string DELETE_CALENDAR = "DELETE FROM "
            ~ ModelConstants.MODEL_CALENDARS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_CALENDAR_NAME ~ " = ?";

    enum string SELECT_NUM_CALENDARS = "SELECT COUNT("
            ~ ModelConstants.FIELD_CALENDAR_NAME ~ ") " ~ " FROM " ~ ModelConstants.MODEL_CALENDARS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string SELECT_CALENDARS = "SELECT " ~ ModelConstants.FIELD_CALENDAR_NAME
            ~ " FROM " ~ ModelConstants.MODEL_CALENDARS
            ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string SELECT_NEXT_FIRE_TIME = "SELECT MIN("
            ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ ") AS " ~ TableConstants.ALIAS_COL_NEXT_FIRE_TIME
            ~ " FROM " ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ? AND t." ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " >= 0";

    enum string SELECT_TRIGGER_FOR_FIRE_TIME = "SELECT "
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", " ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM "
            ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ? AND t." ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " = ?";

    enum string SELECT_NEXT_TRIGGER_TO_ACQUIRE = "SELECT "
        ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", " ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ", "
        ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ ", " ~ ModelConstants.FIELD_PRIORITY ~ " FROM "
        ~ ModelConstants.MODEL_TRIGGERS ~ " t WHERE t."
        ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
        ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_STATE ~ " = ? AND t." ~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " <= ? " 
        ~ "AND (" ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION ~ " = -1 OR (" ~ ModelConstants.FIELD_MISFIRE_INSTRUCTION 
        ~ " != -1 AND t."~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " >= ?)) "
        ~ "ORDER BY "~ ModelConstants.FIELD_NEXT_FIRE_TIME ~ " ASC, " ~ ModelConstants.FIELD_PRIORITY ~ " DESC";
    
    
    enum string INSERT_FIRED_TRIGGER = "INSERT INTO "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS ~ " (" ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", " ~ ModelConstants.FIELD_ENTRY_ID
            ~ ", " ~ ModelConstants.FIELD_TRIGGER_NAME ~ ", " ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ", "
            ~ ModelConstants.FIELD_INSTANCE_NAME ~ ", "
            ~ ModelConstants.FIELD_FIRED_TIME ~ ", " ~ ModelConstants.FIELD_SCHED_TIME ~ ", " ~ ModelConstants.FIELD_ENTRY_STATE 
            ~ ", " ~ ModelConstants.FIELD_JOB_NAME
            ~ ", " ~ ModelConstants.FIELD_JOB_GROUP ~ ", " ~ ModelConstants.FIELD_IS_NONCONCURRENT ~ ", "
            ~ ModelConstants.FIELD_REQUESTS_RECOVERY ~ ", " ~ ModelConstants.FIELD_PRIORITY
            ~ ") VALUES(" ~ SCHED_NAME_SUBST ~ ", ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    enum string UPDATE_FIRED_TRIGGER = "UPDATE "
        ~ ModelConstants.MODEL_FIRED_TRIGGERS ~ " SET " 
        ~ ModelConstants.FIELD_INSTANCE_NAME ~ " = ?, "
        ~ ModelConstants.FIELD_FIRED_TIME ~ " = ?, " ~ ModelConstants.FIELD_SCHED_TIME ~ " = ?, " ~ ModelConstants.FIELD_ENTRY_STATE 
        ~ " = ?, " ~ ModelConstants.FIELD_JOB_NAME
        ~ " = ?, " ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?, " ~ ModelConstants.FIELD_IS_NONCONCURRENT ~ " = ?, "
        ~ ModelConstants.FIELD_REQUESTS_RECOVERY ~ " = ? WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
        ~ " AND t." ~ ModelConstants.FIELD_ENTRY_ID ~ " = ?";

    enum string SELECT_INSTANCES_FIRED_TRIGGERS = "SELECT * FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS
            ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_INSTANCE_NAME ~ " = ?";

    enum string SELECT_INSTANCES_RECOVERABLE_FIRED_TRIGGERS = "SELECT * FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS
            ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_INSTANCE_NAME ~ " = ? AND t." 
            ~ ModelConstants.FIELD_REQUESTS_RECOVERY ~ " = ?";

    enum string SELECT_JOB_EXECUTION_COUNT = "SELECT COUNT("
            ~ ModelConstants.FIELD_TRIGGER_NAME ~ ") FROM " ~ ModelConstants.MODEL_FIRED_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME ~ " = ? AND t."
            ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string SELECT_FIRED_TRIGGERS = "SELECT * FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS
            ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string SELECT_FIRED_TRIGGER = "SELECT * FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_FIRED_TRIGGER_GROUP = "SELECT * FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_FIRED_TRIGGERS_OF_JOB = "SELECT * FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_JOB_NAME ~ " = ? AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string SELECT_FIRED_TRIGGERS_OF_JOB_GROUP = "SELECT * FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS
            ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_JOB_GROUP ~ " = ?";

    enum string DELETE_FIRED_TRIGGER = "DELETE FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_ENTRY_ID ~ " = ?";

    enum string DELETE_INSTANCES_FIRED_TRIGGERS = "DELETE FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_INSTANCE_NAME ~ " = ?";

    enum string DELETE_NO_RECOVERY_FIRED_TRIGGERS = "DELETE FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS
            ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_INSTANCE_NAME ~ " = ?" ~ ModelConstants.FIELD_REQUESTS_RECOVERY ~ " = ?";

    enum string DELETE_ALL_SIMPLE_TRIGGERS = "DELETE FROM " ~ "SIMPLE_TRIGGERS " ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    enum string DELETE_ALL_SIMPROP_TRIGGERS = "DELETE FROM " ~ "SIMPROP_TRIGGERS " ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    enum string DELETE_ALL_CRON_TRIGGERS = "DELETE FROM " ~ "CRON_TRIGGERS" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    enum string DELETE_ALL_BLOB_TRIGGERS = "DELETE FROM " ~ "BLOB_TRIGGERS" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    enum string DELETE_ALL_TRIGGERS = "DELETE FROM " ~ "TRIGGERS" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    enum string DELETE_ALL_JOB_DETAILS = "DELETE FROM " ~ "JOB_DETAILS" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    enum string DELETE_ALL_CALENDARS = "DELETE FROM " ~ "CALENDARS" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    enum string DELETE_ALL_PAUSED_TRIGGER_GRPS = "DELETE FROM " ~ "PAUSED_TRIGGER_GRPS" ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    
    enum string SELECT_FIRED_TRIGGER_INSTANCE_NAMES = 
            "SELECT DISTINCT " ~ ModelConstants.FIELD_INSTANCE_NAME ~ " FROM "
            ~ ModelConstants.MODEL_FIRED_TRIGGERS
            ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;
    
    enum string INSERT_SCHEDULER_STATE = "INSERT INTO "
            ~ ModelConstants.MODEL_SCHEDULER_STATE ~ " ("
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", "
            ~ ModelConstants.FIELD_INSTANCE_NAME ~ ", " ~ ModelConstants.FIELD_LAST_CHECKIN_TIME ~ ", "
            ~ ModelConstants.FIELD_CHECKIN_INTERVAL ~ ") VALUES(" ~ SCHED_NAME_SUBST ~ ", ?, ?, ?)";

    enum string SELECT_SCHEDULER_STATE = "SELECT * FROM "
            ~ ModelConstants.MODEL_SCHEDULER_STATE ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_INSTANCE_NAME ~ " = ?";

    enum string SELECT_SCHEDULER_STATES = "SELECT * FROM "
            ~ ModelConstants.MODEL_SCHEDULER_STATE
            ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string DELETE_SCHEDULER_STATE = "DELETE FROM "
        ~ ModelConstants.MODEL_SCHEDULER_STATE ~ " t WHERE t."
        ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
        ~ " AND t." ~ ModelConstants.FIELD_INSTANCE_NAME ~ " = ?";

    enum string UPDATE_SCHEDULER_STATE = "UPDATE "
        ~ ModelConstants.MODEL_SCHEDULER_STATE ~ " SET " 
        ~ ModelConstants.FIELD_LAST_CHECKIN_TIME ~ " = ? WHERE t."
        ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
        ~ " AND t." ~ ModelConstants.FIELD_INSTANCE_NAME ~ " = ?";

    enum string INSERT_PAUSED_TRIGGER_GROUP = "INSERT INTO "
            ~ ModelConstants.MODEL_PAUSED_TRIGGERS ~ " ("
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ ", "
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ ") VALUES(" ~ SCHED_NAME_SUBST ~ ", ?)";

    enum string SELECT_PAUSED_TRIGGER_GROUP = "SELECT t."
            ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM " ~ ModelConstants.MODEL_PAUSED_TRIGGERS ~ " t WHERE t." 
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " = ?";

    enum string SELECT_PAUSED_TRIGGER_GROUPS = "SELECT t."
        ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " FROM " ~ ModelConstants.MODEL_PAUSED_TRIGGERS
        ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    enum string DELETE_PAUSED_TRIGGER_GROUP = "DELETE FROM "
            ~ ModelConstants.MODEL_PAUSED_TRIGGERS ~ " t WHERE t."
            ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST
            ~ " AND t." ~ ModelConstants.FIELD_TRIGGER_GROUP ~ " LIKE ?";

    enum string DELETE_PAUSED_TRIGGER_GROUPS = "DELETE FROM "
            ~ ModelConstants.MODEL_PAUSED_TRIGGERS
            ~ " t WHERE t." ~ ModelConstants.FIELD_SCHEDULER_NAME ~ " = " ~ SCHED_NAME_SUBST;

    //  CREATE TABLE qrtz_scheduler_state(INSTANCE_NAME VARCHAR2(80) NOT NULL,
    // LAST_CHECKIN_TIME NUMBER(13) NOT NULL, CHECKIN_INTERVAL NUMBER(13) NOT
    // NULL, PRIMARY KEY (INSTANCE_NAME));

}

// EOF
