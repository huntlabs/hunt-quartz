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
module hunt.quartz.listeners.BroadcastTriggerListener;

import hunt.container.Iterator;
import hunt.container.LinkedList;
import hunt.container.List;

import hunt.quartz.JobExecutionContext;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerListener;
import hunt.quartz.Trigger.CompletedExecutionInstruction;

/**
 * Holds a List of references to TriggerListener instances and broadcasts all
 * events to them (in order).
 *
 * <p>The broadcasting behavior of this listener to delegate listeners may be
 * more convenient than registering all of the listeners directly with the
 * Scheduler, and provides the flexibility of easily changing which listeners
 * get notified.</p>
 *
 * @see #addListener(hunt.quartz.TriggerListener)
 * @see #removeListener(hunt.quartz.TriggerListener)
 * @see #removeListener(string)
 *
 * @author James House (jhouse AT revolition DOT net)
 */
class BroadcastTriggerListener : TriggerListener {

    private string name;
    private List!(TriggerListener) listeners;

    /**
     * Construct an instance with the given name.
     *
     * (Remember to add some delegate listeners!)
     *
     * @param name the name of this instance
     */
    this(string name) {
        if(name is null) {
            throw new IllegalArgumentException("Listener name cannot be null!");
        }
        this.name = name;
        listeners = new LinkedList!(TriggerListener)();
    }

    /**
     * Construct an instance with the given name, and List of listeners.
     *
     * @param name the name of this instance
     * @param listeners the initial List of TriggerListeners to broadcast to.
     */
    this(string name, List!(TriggerListener) listeners) {
        this(name);
        this.listeners.addAll(listeners);
    }

    string getName() {
        return name;
    }

    void addListener(TriggerListener listener) {
        listeners.add(listener);
    }

    bool removeListener(TriggerListener listener) {
        return listeners.remove(listener);
    }

    bool removeListener(string listenerName) {
        Iterator!(TriggerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            TriggerListener l = itr.next();
            if(l.getName()== listenerName) {
                itr.remove();
                return true;
            }
        }
        return false;
    }

    List!(TriggerListener) getListeners() {
        return java.container.Collections.unmodifiableList(listeners);
    }

    void triggerFired(Trigger trigger, JobExecutionContext context) {

        Iterator!(TriggerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            TriggerListener l = itr.next();
            l.triggerFired(trigger, context);
        }
    }

    bool vetoJobExecution(Trigger trigger, JobExecutionContext context) {

        Iterator!(TriggerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            TriggerListener l = itr.next();
            if(l.vetoJobExecution(trigger, context)) {
                return true;
            }
        }
        return false;
    }

    void triggerMisfired(Trigger trigger) {

        Iterator!(TriggerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            TriggerListener l = itr.next();
            l.triggerMisfired(trigger);
        }
    }

    void triggerComplete(Trigger trigger, JobExecutionContext context, CompletedExecutionInstruction triggerInstructionCode) {

        Iterator!(TriggerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            TriggerListener l = itr.next();
            l.triggerComplete(trigger, context, triggerInstructionCode);
        }
    }

}
