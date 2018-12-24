
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

module hunt.quartz.TriggerUtils;

import hunt.quartz.Calendar;
import hunt.quartz.spi.OperableTrigger;

import hunt.container.LinkedList;
import hunt.container.List;
import hunt.lang.exception;
import hunt.time.LocalDateTime;

import std.datetime;

/**
 * Convenience and utility methods for working with <code>{@link Trigger}s</code>.
 * 
 * 
 * @see CronTrigger
 * @see SimpleTrigger
 * @see DateBuilder
 * 
 * @author James House
 */
class TriggerUtils {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Private constructor because this is a pure utility class.
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

    /**
     * Returns a list of Dates that are the next fire times of a 
     * <code>Trigger</code>.
     * The input trigger will be cloned before any work is done, so you need
     * not worry about its state being altered by this method.
     * 
     * @param trigg
     *          The trigger upon which to do the work
     * @param cal
     *          The calendar to apply to the trigger's schedule
     * @param numTimes
     *          The number of next fire times to produce
     * @return List of java.util.LocalDateTime objects
     */
    static List!(LocalDateTime) computeFireTimes(OperableTrigger trigg, 
        Calendar cal, int numTimes) {
        LinkedList!(LocalDateTime) lst = new LinkedList!(LocalDateTime)();

        implementationMissing(false);
        // OperableTrigger t = cast(OperableTrigger) trigg.clone();
        OperableTrigger t = trigg;


        if (t.getNextFireTime() is null) {
            t.computeFirstFireTime(cal);
        }

        for (int i = 0; i < numTimes; i++) {
            LocalDateTime d = t.getNextFireTime();
            if (d !is null) {
                lst.add(d);
                t.triggered(cal);
            } else {
                break;
            }
        }

        // return java.container.Collections.unmodifiableList(lst);
        return lst;
    }
    
    /**
     * Compute the <code>LocalDateTime</code> that is 1 second after the Nth firing of 
     * the given <code>Trigger</code>, taking the triger's associated 
     * <code>Calendar</code> into consideration.
     *  
     * The input trigger will be cloned before any work is done, so you need
     * not worry about its state being altered by this method.
     * 
     * @param trigg
     *          The trigger upon which to do the work
     * @param cal
     *          The calendar to apply to the trigger's schedule
     * @param numTimes
     *          The number of next fire times to produce
     * @return the computed LocalDateTime, or null if the trigger (as configured) will not fire that many times.
     */
    static LocalDateTime computeEndTimeToAllowParticularNumberOfFirings(OperableTrigger trigg, Calendar cal, 
            int numTimes) {

        OperableTrigger t = cast(OperableTrigger) trigg; //.clone();

        if (t.getNextFireTime() is null) {
            t.computeFirstFireTime(cal);
        }
        
        int c = 0;
        LocalDateTime endTime = null;
        
        for (int i = 0; i < numTimes; i++) {
            LocalDateTime d = t.getNextFireTime();
            if (d !is null) {
                c++;
                t.triggered(cal);
                if(c == numTimes)
                    endTime = d;
            } else {
                break;
            }
        }
        
        if(endTime is null)
            return null;
        
        endTime = endTime.plusSeconds(1);
        
        return endTime;
    }

    /**
     * Returns a list of Dates that are the next fire times of a 
     * <code>Trigger</code>
     * that fall within the given date range. The input trigger will be cloned
     * before any work is done, so you need not worry about its state being
     * altered by this method.
     * 
     * <p>
     * NOTE: if this is a trigger that has previously fired within the given
     * date range, then firings which have already occurred will not be listed
     * in the output List.
     * </p>
     * 
     * @param trigg
     *          The trigger upon which to do the work
     * @param cal
     *          The calendar to apply to the trigger's schedule
     * @param from
     *          The starting date at which to find fire times
     * @param to
     *          The ending date at which to stop finding fire times
     * @return List of java.util.LocalDateTime objects
     */
    static List!(LocalDateTime) computeFireTimesBetween(OperableTrigger trigg,
            Calendar cal, LocalDateTime from, LocalDateTime to) {
        LinkedList!(LocalDateTime) lst = new LinkedList!(LocalDateTime)();

        OperableTrigger t = cast(OperableTrigger) trigg; //.clone();

        if (t.getNextFireTime() is null) {
            t.setStartTime(from);
            t.setEndTime(to);
            t.computeFirstFireTime(cal);
        }

        while (true) {
            LocalDateTime d = t.getNextFireTime();
            if (d !is null) {
                if (d.isBefore(from)) {
                    t.triggered(cal);
                    continue;
                }
                if (d.isAfter(to)) {
                    break;
                }
                lst.add(d);
                t.triggered(cal);
            } else {
                break;
            }
        }

        // return java.container.Collections.unmodifiableList(lst);
        return lst;
    }

}
