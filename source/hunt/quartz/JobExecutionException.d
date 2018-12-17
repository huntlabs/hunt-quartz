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

module hunt.quartz.JobExecutionException;

/**
 * An exception that can be thrown by a <code>{@link hunt.quartz.Job}</code>
 * to indicate to the Quartz <code>{@link Scheduler}</code> that an error
 * occurred while executing, and whether or not the <code>Job</code> requests
 * to be re-fired immediately (using the same <code>{@link JobExecutionContext}</code>,
 * or whether it wants to be unscheduled.
 * 
 * <p>
 * Note that if the flag for 'refire immediately' is set, the flags for
 * unscheduling the Job are ignored.
 * </p>
 * 
 * @see Job
 * @see JobExecutionContext
 * @see SchedulerException
 * 
 * @author James House
 */
class JobExecutionException : SchedulerException {

    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private bool refire = false;

    private bool unscheduleTrigg = false;

    private bool unscheduleAllTriggs = false;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a JobExcecutionException, with the 're-fire immediately' flag set
     * to <code>false</code>.
     * </p>
     */
    this() {
    }

    /**
     * <p>
     * Create a JobExcecutionException, with the given cause.
     * </p>
     */
    this(Throwable cause) {
        super(cause);
    }

    /**
     * <p>
     * Create a JobExcecutionException, with the given message.
     * </p>
     */
    this(string msg) {
        super(msg);
    }

    /**
     * <p>
     * Create a JobExcecutionException with the 're-fire immediately' flag set
     * to the given value.
     * </p>
     */
    this(bool refireImmediately) {
        refire = refireImmediately;
    }

    /**
     * <p>
     * Create a JobExcecutionException with the given underlying exception, and
     * the 're-fire immediately' flag set to the given value.
     * </p>
     */
    this(Throwable cause, bool refireImmediately) {
        super(cause);

        refire = refireImmediately;
    }

    /**
     * <p>
     * Create a JobExcecutionException with the given message, and underlying
     * exception.
     * </p>
     */
    this(string msg, Throwable cause) {
        super(msg, cause);
    }
    
    /**
     * <p>
     * Create a JobExcecutionException with the given message, and underlying
     * exception, and the 're-fire immediately' flag set to the given value.
     * </p>
     */
    this(string msg, Throwable cause,
            bool refireImmediately) {
        super(msg, cause);

        refire = refireImmediately;
    }
    
    /**
     * Create a JobExcecutionException with the given message and the 're-fire 
     * immediately' flag set to the given value.
     */
    this(string msg, bool refireImmediately) {
        super(msg);

        refire = refireImmediately;
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    void setRefireImmediately(bool refire) {
        this.refire = refire;
    }

    bool refireImmediately() {
        return refire;
    }

    void setUnscheduleFiringTrigger(bool unscheduleTrigg) {
        this.unscheduleTrigg = unscheduleTrigg;
    }

    bool unscheduleFiringTrigger() {
        return unscheduleTrigg;
    }

    void setUnscheduleAllTriggers(bool unscheduleAllTriggs) {
        this.unscheduleAllTriggs = unscheduleAllTriggs;
    }

    bool unscheduleAllTriggers() {
        return unscheduleAllTriggs;
    }

}
