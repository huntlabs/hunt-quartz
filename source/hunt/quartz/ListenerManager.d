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

module hunt.quartz.ListenerManager;

import hunt.quartz.JobKey;
import hunt.quartz.JobListener;
import hunt.quartz.Matcher;
import hunt.quartz.SchedulerListener;
import hunt.quartz.TriggerKey;
import hunt.quartz.TriggerListener;

import hunt.container.List;

/**
 * Client programs may be interested in the 'listener' interfaces that are
 * available from Quartz. The <code>{@link JobListener}</code> interface
 * provides notifications of <code>Job</code> executions. The 
 * <code>{@link TriggerListener}</code> interface provides notifications of 
 * <code>Trigger</code> firings. The <code>{@link SchedulerListener}</code> 
 * interface provides notifications of <code>Scheduler</code> events and 
 * errors.  Listeners can be associated with local schedulers through the 
 * {@link ListenerManager} interface.  
 * 
 * <p>Listener registration order is preserved, and hence notification of listeners
 * will be in the order in which they were registered.</p>
 * 
 * @author jhouse
 * @since 2.0 - previously listeners were managed directly on the Scheduler interface.
 */
interface ListenerManager {

    /**
     * Add the given <code>{@link JobListener}</code> to the <code>Scheduler</code>,
     * and register it to receive events for all Jobs.
     * 
     * Because no matchers are provided, the <code>EverythingMatcher</code> will be used.
     * 
     * @see Matcher
     * @see hunt.quartz.impl.matchers.EverythingMatcher
     */
    void addJobListener(JobListener jobListener);

    /**
     * Add the given <code>{@link JobListener}</code> to the <code>Scheduler</code>,
     * and register it to receive events for Jobs that are matched by the
     * given Matcher.
     * 
     * If no matchers are provided, the <code>EverythingMatcher</code> will be used.
     * 
     * @see Matcher
     * @see hunt.quartz.impl.matchers.EverythingMatcher
     */
    void addJobListener(JobListener jobListener, Matcher!(JobKey) matcher);

    /**
     * Add the given <code>{@link JobListener}</code> to the <code>Scheduler</code>,
     * and register it to receive events for Jobs that are matched by ANY of the
     * given Matchers.
     * 
     * If no matchers are provided, the <code>EverythingMatcher</code> will be used.
     * 
     * @see Matcher
     * @see hunt.quartz.impl.matchers.EverythingMatcher
     */
    void addJobListener(JobListener jobListener, Matcher!(JobKey)[] matchers... );

    /**
     * Add the given <code>{@link JobListener}</code> to the <code>Scheduler</code>,
     * and register it to receive events for Jobs that are matched by ANY of the
     * given Matchers.
     * 
     * If no matchers are provided, the <code>EverythingMatcher</code> will be used.
     * 
     * @see Matcher
     * @see hunt.quartz.impl.matchers.EverythingMatcher
     */
    void addJobListener(JobListener jobListener, List!(Matcher!(JobKey)) matchers);

    /**
     * Add the given Matcher to the set of matchers for which the listener
     * will receive events if ANY of the matchers match.
     *  
     * @param listenerName the name of the listener to add the matcher to
     * @param matcher the additional matcher to apply for selecting events
     * @return true if the identified listener was found and updated
     */
    bool addJobListenerMatcher(string listenerName, Matcher!(JobKey) matcher);

    /**
     * Remove the given Matcher to the set of matchers for which the listener
     * will receive events if ANY of the matchers match.
     *  
     * @param listenerName the name of the listener to add the matcher to
     * @param matcher the additional matcher to apply for selecting events
     * @return true if the given matcher was found and removed from the listener's list of matchers
     */
    bool removeJobListenerMatcher(string listenerName, Matcher!(JobKey) matcher);

    /**
     * Set the set of Matchers for which the listener
     * will receive events if ANY of the matchers match.
     * 
     * <p>Removes any existing matchers for the identified listener!</p>
     *  
     * @param listenerName the name of the listener to add the matcher to
     * @param matchers the matchers to apply for selecting events
     * @return true if the given matcher was found and removed from the listener's list of matchers
     */
    bool setJobListenerMatchers(string listenerName, List!(Matcher!(JobKey)) matchers);

    /**
     * Get the set of Matchers for which the listener
     * will receive events if ANY of the matchers match.
     * 
     *  
     * @param listenerName the name of the listener to add the matcher to
     * @return the matchers registered for selecting events for the identified listener
     */
    List!(Matcher!(JobKey)) getJobListenerMatchers(string listenerName);

    /**
     * Remove the identified <code>{@link JobListener}</code> from the <code>Scheduler</code>.
     * 
     * @return true if the identified listener was found in the list, and
     *         removed.
     */
    bool removeJobListener(string name);

    /**
     * Get a List containing all of the <code>{@link JobListener}</code>s in
     * the <code>Scheduler</code>, in the order in which they were registered.
     */
    List!(JobListener) getJobListeners();

    /**
     * Get the <code>{@link JobListener}</code> that has the given name.
     */
    JobListener getJobListener(string name);

    /**
     * Add the given <code>{@link TriggerListener}</code> to the <code>Scheduler</code>,
     * and register it to receive events for all Triggers.
     * 
     * Because no matcher is provided, the <code>EverythingMatcher</code> will be used.
     * 
     * @see Matcher
     * @see hunt.quartz.impl.matchers.EverythingMatcher
     */
    void addTriggerListener(TriggerListener triggerListener);
    
    /**
     * Add the given <code>{@link TriggerListener}</code> to the <code>Scheduler</code>,
     * and register it to receive events for Triggers that are matched by the
     * given Matcher.
     * 
     * If no matcher is provided, the <code>EverythingMatcher</code> will be used.
     * 
     * @see Matcher
     * @see hunt.quartz.impl.matchers.EverythingMatcher
     */
    void addTriggerListener(TriggerListener triggerListener, Matcher!(TriggerKey) matcher);
    
    /**
     * Add the given <code>{@link TriggerListener}</code> to the <code>Scheduler</code>,
     * and register it to receive events for Triggers that are matched by ANY of the
     * given Matchers.
     * 
     * If no matcher is provided, the <code>EverythingMatcher</code> will be used.
     * 
     * @see Matcher
     * @see hunt.quartz.impl.matchers.EverythingMatcher
     */
    void addTriggerListener(TriggerListener triggerListener, Matcher!(TriggerKey)[] matchers... );

    /**
     * Add the given <code>{@link TriggerListener}</code> to the <code>Scheduler</code>,
     * and register it to receive events for Triggers that are matched by ANY of the
     * given Matchers.
     * 
     * If no matcher is provided, the <code>EverythingMatcher</code> will be used.
     * 
     * @see Matcher
     * @see hunt.quartz.impl.matchers.EverythingMatcher
     */
    void addTriggerListener(TriggerListener triggerListener, List!(Matcher!(TriggerKey)) matchers);

    /**
     * Add the given Matcher to the set of matchers for which the listener
     * will receive events if ANY of the matchers match.
     *  
     * @param listenerName the name of the listener to add the matcher to
     * @param matcher the additional matcher to apply for selecting events
     * @return true if the identified listener was found and updated
     */
    bool addTriggerListenerMatcher(string listenerName, Matcher!(TriggerKey) matcher);

    /**
     * Remove the given Matcher to the set of matchers for which the listener
     * will receive events if ANY of the matchers match.
     *  
     * @param listenerName the name of the listener to add the matcher to
     * @param matcher the additional matcher to apply for selecting events
     * @return true if the given matcher was found and removed from the listener's list of matchers
     */
    bool removeTriggerListenerMatcher(string listenerName, Matcher!(TriggerKey) matcher);

    /**
     * Set the set of Matchers for which the listener
     * will receive events if ANY of the matchers match.
     * 
     * <p>Removes any existing matchers for the identified listener!</p>
     *  
     * @param listenerName the name of the listener to add the matcher to
     * @param matchers the matchers to apply for selecting events
     * @return true if the given matcher was found and removed from the listener's list of matchers
     */
    bool setTriggerListenerMatchers(string listenerName, List!(Matcher!(TriggerKey)) matchers);

    /**
     * Get the set of Matchers for which the listener
     * will receive events if ANY of the matchers match.
     * 
     *  
     * @param listenerName the name of the listener to add the matcher to
     * @return the matchers registered for selecting events for the identified listener
     */
    List!(Matcher!(TriggerKey)) getTriggerListenerMatchers( string listenerName);

    /**
     * Remove the identified <code>{@link TriggerListener}</code> from the <code>Scheduler</code>.
     * 
     * @return true if the identified listener was found in the list, and
     *         removed.
     */
    bool removeTriggerListener(string name);

    /**
     * Get a List containing all of the <code>{@link TriggerListener}</code>s 
     * in the <code>Scheduler</code>, in the order in which they were registered.
     */
    List!(TriggerListener) getTriggerListeners();

    /**
     * Get the <code>{@link TriggerListener}</code> that has the given name.
     */
    TriggerListener getTriggerListener(string name);

    /**
     * Register the given <code>{@link SchedulerListener}</code> with the
     * <code>Scheduler</code>.
     */
    void addSchedulerListener(SchedulerListener schedulerListener);

    /**
     * Remove the given <code>{@link SchedulerListener}</code> from the
     * <code>Scheduler</code>.
     * 
     * @return true if the identified listener was found in the list, and
     *         removed.
     */
    bool removeSchedulerListener(SchedulerListener schedulerListener);

    /**
     * Get a List containing all of the <code>{@link SchedulerListener}</code>s
     * registered with the <code>Scheduler</code>, in the order in which they were registered.
     */
    List!(SchedulerListener) getSchedulerListeners();

}