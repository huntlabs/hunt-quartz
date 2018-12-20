
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

module hunt.quartz.SchedulerMetaData;

import std.datetime;
import std.string;

/**
 * Describes the settings and capabilities of a given <code>{@link Scheduler}</code>
 * instance.
 * 
 * @author James House
 */
class SchedulerMetaData {
  

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private string schedName;

    private string schedInst;

    private TypeInfo_Class schedClass; 

    private bool isRemote;

    private bool started;

    private bool _isInStandbyMode;

    private bool shutdown;

    private Date startTime;

    private int numJobsExec;

    private TypeInfo_Class jsClass;

    private bool jsPersistent;

    private bool jsClustered;

    private TypeInfo_Class tpClass;

    private int tpSize;

    private string _version;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    this(string schedName, string schedInst,
            TypeInfo_Class schedClass, bool isRemote, bool started,
            bool isInStandbyMode, bool shutdown, Date startTime, int numJobsExec,
            TypeInfo_Class jsClass, bool jsPersistent, bool jsClustered, TypeInfo_Class tpClass, int tpSize,
            string ver) {
        this.schedName = schedName;
        this.schedInst = schedInst;
        this.schedClass = schedClass;
        this.isRemote = isRemote;
        this.started = started;
        this._isInStandbyMode = isInStandbyMode;
        this.shutdown = shutdown;
        this.startTime = startTime;
        this.numJobsExec = numJobsExec;
        this.jsClass = jsClass;
        this.jsPersistent = jsPersistent;
        this.jsClustered = jsClustered;
        this.tpClass = tpClass;
        this.tpSize = tpSize;
        this._version = ver;
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
     * Returns the name of the <code>Scheduler</code>.
     * </p>
     */
    string getSchedulerName() {
        return schedName;
    }

    /**
     * <p>
     * Returns the instance Id of the <code>Scheduler</code>.
     * </p>
     */
    string getSchedulerInstanceId() {
        return schedInst;
    }

    /**
     * <p>
     * Returns the class-name of the <code>Scheduler</code> instance.
     * </p>
     */
    TypeInfo_Class getSchedulerClass() {
        return schedClass;
    }

    /**
     * <p>
     * Returns the <code>Date</code> at which the Scheduler started running.
     * </p>
     * 
     * @return null if the scheduler has not been started.
     */
    Date getRunningSince() {
        return startTime;
    }
    
    /**
     * <p>
     * Returns the number of jobs executed since the <code>Scheduler</code>
     * started..
     * </p>
     */
    int getNumberOfJobsExecuted() {
        return numJobsExec;
    }

    /**
     * <p>
     * Returns whether the <code>Scheduler</code> is being used remotely (via
     * RMI).
     * </p>
     */
    bool isSchedulerRemote() {
        return isRemote;
    }

    /**
     * <p>
     * Returns whether the scheduler has been started.
     * </p>
     * 
     * <p>
     * Note: <code>isStarted()</code> may return <code>true</code> even if
     * <code>isInStandbyMode()</code> returns <code>true</code>.
     * </p>
     */
    bool isStarted() {
        return started;
    }

    /**
     * Reports whether the <code>Scheduler</code> is in standby mode.
     */
    bool isInStandbyMode() {
        return _isInStandbyMode;
    }

    /**
     * <p>
     * Reports whether the <code>Scheduler</code> has been shutdown.
     * </p>
     */
    bool isShutdown() {
        return shutdown;
    }

    /**
     * <p>
     * Returns the class-name of the <code>JobStore</code> instance that is
     * being used by the <code>Scheduler</code>.
     * </p>
     */
    TypeInfo_Class getJobStoreClass() {
        return jsClass;
    }
    
    /**
     * <p>
     * Returns whether or not the <code>Scheduler</code>'s!(code)JobStore</code>
     * instance supports persistence.
     * </p>
     */
    bool isJobStoreSupportsPersistence() {
        return jsPersistent;
    }

    /**
     * <p>
     * Returns whether or not the <code>Scheduler</code>'s!(code)JobStore</code>
     * is clustered.
     * </p>
     */
    bool isJobStoreClustered() {
        return jsClustered;
    }

    /**
     * <p>
     * Returns the class-name of the <code>ThreadPool</code> instance that is
     * being used by the <code>Scheduler</code>.
     * </p>
     */
    TypeInfo_Class getThreadPoolClass() {
        return tpClass;
    }

    /**
     * <p>
     * Returns the number of threads currently in the <code>Scheduler</code>'s
     * <code>ThreadPool</code>.
     * </p>
     */
    int getThreadPoolSize() {
        return tpSize;
    }

    /**
     * <p>
     * Returns the version of Quartz that is running.
     * </p>
     */
    string getVersion() {
        return _version;
    }

    /**
     * <p>
     * Return a simple string representation of this object.
     * </p>
     */
    override
    string toString() {
        try {
            return getSummary();
        } catch (SchedulerException se) {
            return "SchedulerMetaData: undeterminable.";
        }
    }

    /**
     * <p>
     * Returns a formatted (human readable) string describing all the <code>Scheduler</code>'s
     * meta-data values.
     * </p>
     * 
     * <p>
     * The format of the string looks something like this:
     * 
     * <pre>
     * 
     * 
     *  Quartz Scheduler 'SchedulerName' with instanceId 'SchedulerInstanceId' Scheduler class: 'hunt.quartz.impl.StdScheduler' - running locally. Running since: '11:33am on Jul 19, 2002' Not currently paused. Number of Triggers fired: '123' Using thread pool 'hunt.quartz.simpl.SimpleThreadPool' - with '8' threads Using job-store 'hunt.quartz.impl.JDBCJobStore' - which supports persistence.
     * </pre>
     * 
     * </p>
     */
    string getSummary() {
        StringBuilder str = new StringBuilder("Quartz Scheduler (v");
        str.append(getVersion());
        str.append(") '");

        str.append(getSchedulerName());
        str.append("' with instanceId '");
        str.append(getSchedulerInstanceId());
        str.append("'\n");

        str.append("  Scheduler class: '");
        str.append(getSchedulerClass().getName());
        str.append("'");
        if (isSchedulerRemote()) {
            str.append(" - access via RMI.");
        } else {
            str.append(" - running locally.");
        }
        str.append("\n");

        if (!isShutdown()) {
            if (getRunningSince() !is null) {
                str.append("  Running since: ");
                str.append(getRunningSince());
            } else {
                str.append("  NOT STARTED.");
            }
            str.append("\n");

            if (_isInStandbyMode()) {
                str.append("  Currently in standby mode.");
            } else {
                str.append("  Not currently in standby mode.");
            }
        } else {
            str.append("  Scheduler has been SHUTDOWN.");
        }
        str.append("\n");

        str.append("  Number of jobs executed: ");
        str.append(getNumberOfJobsExecuted());
        str.append("\n");

        str.append("  Using thread pool '");
        str.append(getThreadPoolClass().getName());
        str.append("' - with ");
        str.append(getThreadPoolSize());
        str.append(" threads.");
        str.append("\n");

        str.append("  Using job-store '");
        str.append(getJobStoreClass().getName());
        str.append("' - which ");
        if (isJobStoreSupportsPersistence()) {
            str.append("supports persistence.");
        } else {
            str.append("does not support persistence.");
        }
        if (isJobStoreClustered()) {
            str.append(" and is clustered.");
        } else {
            str.append(" and is not clustered.");
        }
        str.append("\n");

        return str.toString();
    }

}
