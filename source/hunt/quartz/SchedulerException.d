
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

module hunt.quartz.SchedulerException;



/**
 * Base class for exceptions thrown by the Quartz <code>{@link Scheduler}</code>.
 * 
 * <p>
 * <code>SchedulerException</code>s may contain a reference to another
 * <code>Exception</code>, which was the underlying cause of the <code>SchedulerException</code>.
 * </p>
 * 
 * @author James House
 */
class SchedulerException : Exception {
  

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    SchedulerException() {
        super();
    }

    SchedulerException(string msg) {
        super(msg);
    }

    SchedulerException(Throwable cause) {
        super(cause);
    }

    SchedulerException(string msg, Throwable cause) {
        super(msg, cause);
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
     * Return the exception that is the underlying cause of this exception.
     * </p>
     * 
     * <p>
     * This may be used to find more detail about the cause of the error.
     * </p>
     * 
     * @return the underlying exception, or <code>null</code> if there is not
     *         one.
     */
    Throwable getUnderlyingException() {
        return super.next();
    }

    override string toString() {
        Throwable cause = getUnderlyingException(); 
        if (cause is null || cause == this) {
            return super.toString();
        } else {
            return super.toString() ~ " [See nested exception: " ~ cause.toString() ~ "]";
        }
    }


}
