module hunt.quartz.listeners.BroadcastSchedulerListener;

import hunt.container.Iterator;
import hunt.container.LinkedList;
import hunt.container.List;

import hunt.quartz.JobDetail;
import hunt.quartz.JobKey;
import hunt.quartz.SchedulerException;
import hunt.quartz.SchedulerListener;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;

/**
 * Holds a List of references to SchedulerListener instances and broadcasts all
 * events to them (in order).
 *
 * <p>This may be more convenient than registering all of the listeners
 * directly with the Scheduler, and provides the flexibility of easily changing
 * which listeners get notified.</p>
 *
 * @see #addListener(hunt.quartz.SchedulerListener)
 * @see #removeListener(hunt.quartz.SchedulerListener)
 *
 * @author James House (jhouse AT revolition DOT net)
 */
class BroadcastSchedulerListener : SchedulerListener {

    private List!(SchedulerListener) listeners;

    this() {
        listeners = new LinkedList!(SchedulerListener)();
    }

    /**
     * Construct an instance with the given List of listeners.
     *
     * @param listeners the initial List of SchedulerListeners to broadcast to.
     */
    this(List!(SchedulerListener) listeners) {
        this();
        this.listeners.addAll(listeners);
    }


    void addListener(SchedulerListener listener) {
        listeners.add(listener);
    }

    bool removeListener(SchedulerListener listener) {
        return listeners.remove(listener);
    }

    List!(SchedulerListener) getListeners() {
        return java.container.Collections.unmodifiableList(listeners);
    }

    void jobAdded(JobDetail jobDetail) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.jobAdded(jobDetail);
        }
    }

    void jobDeleted(JobKey jobKey) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.jobDeleted(jobKey);
        }
    }
    
    void jobScheduled(Trigger trigger) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.jobScheduled(trigger);
        }
    }

    void jobUnscheduled(TriggerKey triggerKey) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.jobUnscheduled(triggerKey);
        }
    }

    void triggerFinalized(Trigger trigger) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.triggerFinalized(trigger);
        }
    }

    void triggerPaused(TriggerKey key) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.triggerPaused(key);
        }
    }

    void triggersPaused(string triggerGroup) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.triggersPaused(triggerGroup);
        }
    }

    void triggerResumed(TriggerKey key) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.triggerResumed(key);
        }
    }

    void triggersResumed(string triggerGroup) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.triggersResumed(triggerGroup);
        }
    }
    
    void schedulingDataCleared() {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.schedulingDataCleared();
        }
    }

    
    void jobPaused(JobKey key) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.jobPaused(key);
        }
    }

    void jobsPaused(string jobGroup) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.jobsPaused(jobGroup);
        }
    }

    void jobResumed(JobKey key) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.jobResumed(key);
        }
    }

    void jobsResumed(string jobGroup) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.jobsResumed(jobGroup);
        }
    }
    
    void schedulerError(string msg, SchedulerException cause) {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.schedulerError(msg, cause);
        }
    }

    void schedulerStarted() {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.schedulerStarted();
        }
    }
    
    void schedulerStarting() {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while (itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.schedulerStarting();
        }
    }

    void schedulerInStandbyMode() {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.schedulerInStandbyMode();
        }
    }
    
    void schedulerShutdown() {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.schedulerShutdown();
        }
    }
    
    void schedulerShuttingdown() {
        Iterator!(SchedulerListener) itr = listeners.iterator();
        while(itr.hasNext()) {
            SchedulerListener l = itr.next();
            l.schedulerShuttingdown();
        }
    }
    
}
