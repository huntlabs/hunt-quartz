module hunt.quartz.listeners.BroadcastSchedulerListener;

import hunt.container.Iterator;
import hunt.container.LinkedList;
import hunt.container.List;

import hunt.quartz.JobDetail;
import hunt.quartz.JobKey;
import hunt.quartz.exception;
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
        return (listeners); // java.container.Collections.unmodifiableList
    }

    void jobAdded(JobDetail jobDetail) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.jobAdded(jobDetail);
        }
    }

    void jobDeleted(JobKey jobKey) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.jobDeleted(jobKey);
        }
    }
    
    void jobScheduled(Trigger trigger) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.jobScheduled(trigger);
        }
    }

    void jobUnscheduled(TriggerKey triggerKey) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.jobUnscheduled(triggerKey);
        }
    }

    void triggerFinalized(Trigger trigger) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.triggerFinalized(trigger);
        }
    }

    void triggerPaused(TriggerKey key) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.triggerPaused(key);
        }
    }

    void triggersPaused(string triggerGroup) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.triggersPaused(triggerGroup);
        }
    }

    void triggerResumed(TriggerKey key) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.triggerResumed(key);
        }
    }

    void triggersResumed(string triggerGroup) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.triggersResumed(triggerGroup);
        }
    }
    
    void schedulingDataCleared() {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.schedulingDataCleared();
        }
    }

    
    void jobPaused(JobKey key) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.jobPaused(key);
        }
    }

    void jobsPaused(string jobGroup) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.jobsPaused(jobGroup);
        }
    }

    void jobResumed(JobKey key) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.jobResumed(key);
        }
    }

    void jobsResumed(string jobGroup) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.jobsResumed(jobGroup);
        }
    }
    
    void schedulerError(string msg, SchedulerException cause) {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.schedulerError(msg, cause);
        }
    }

    void schedulerStarted() {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.schedulerStarted();
        }
    }
    
    void schedulerStarting() {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.schedulerStarting();
        }
    }

    void schedulerInStandbyMode() {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.schedulerInStandbyMode();
        }
    }
    
    void schedulerShutdown() {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.schedulerShutdown();
        }
    }
    
    void schedulerShuttingdown() {
        foreach(SchedulerListener l; listeners.iterator()) {
            l.schedulerShuttingdown();
        }
    }
    
}
