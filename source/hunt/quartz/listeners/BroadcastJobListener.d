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
module hunt.quartz.listeners.BroadcastJobListener;

import hunt.quartz.JobExecutionContext;
import hunt.quartz.Exceptions;
import hunt.quartz.JobListener;

import hunt.collection.Iterator;
import hunt.collection.LinkedList;
import hunt.collection.List;
import hunt.Exceptions;

/**
 * Holds a List of references to JobListener instances and broadcasts all
 * events to them (in order).
 *
 * <p>The broadcasting behavior of this listener to delegate listeners may be
 * more convenient than registering all of the listeners directly with the
 * Scheduler, and provides the flexibility of easily changing which listeners
 * get notified.</p>
 *
 *
 * @see #addListener(hunt.quartz.JobListener)
 * @see #removeListener(hunt.quartz.JobListener)
 * @see #removeListener(string)
 *
 * @author James House (jhouse AT revolition DOT net)
 */
class BroadcastJobListener : JobListener {

    private string name;
    private List!(JobListener) listeners;

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
        listeners = new LinkedList!(JobListener)();
    }

    /**
     * Construct an instance with the given name, and List of listeners.
     *
     * @param name the name of this instance
     * @param listeners the initial List of JobListeners to broadcast to.
     */
    this(string name, List!(JobListener) listeners) {
        this(name);
        this.listeners.addAll(listeners);
    }

    string getName() {
        return name;
    }

    void addListener(JobListener listener) {
        listeners.add(listener);
    }

    bool removeListener(JobListener listener) {
        return listeners.remove(listener);
    }

    bool removeListener(string listenerName) {
        // JobListener[] ls;
        foreach(JobListener jl; listeners) {
            if(jl.getName() == listenerName) {
                // itr.remove();
                // ls ~= jl;
                listeners.remove(jl);
                return true;
            }
        }
        
        return false;
    }

    List!(JobListener) getListeners() {
        return (listeners);
    }

    void jobToBeExecuted(JobExecutionContext context) {
        foreach(JobListener jl; listeners) {
            jl.jobToBeExecuted(context);
        }
    }

    void jobExecutionVetoed(JobExecutionContext context) {
        foreach(JobListener jl; listeners) {
            jl.jobExecutionVetoed(context);
        }
    }

    void jobWasExecuted(JobExecutionContext context, JobExecutionException jobException) {
        foreach(JobListener jl; listeners) {
            jl.jobWasExecuted(context, jobException);
        }
    }

}
