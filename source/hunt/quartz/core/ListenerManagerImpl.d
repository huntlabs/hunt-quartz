module hunt.quartz.core.ListenerManagerImpl;

import hunt.container;

import hunt.quartz.JobKey;
import hunt.quartz.JobListener;
import hunt.quartz.ListenerManager;
import hunt.quartz.Matcher;
import hunt.quartz.SchedulerListener;
import hunt.quartz.TriggerKey;
import hunt.quartz.TriggerListener;
import hunt.quartz.impl.matchers.EverythingMatcher;

class ListenerManagerImpl : ListenerManager {

    private Map!(string, JobListener) globalJobListeners;

    private Map!(string, TriggerListener) globalTriggerListeners;

    private Map!(string, List!(Matcher!(JobKey))) globalJobListenersMatchers;

    private Map!(string, List!(Matcher!(TriggerKey))) globalTriggerListenersMatchers;

    private ArrayList!(SchedulerListener) schedulerListeners;

    this() {

        globalJobListeners = new LinkedHashMap!(string, JobListener)(10);

        globalTriggerListeners = new LinkedHashMap!(string, TriggerListener)(10);

        globalJobListenersMatchers = new LinkedHashMap!(string, List!(Matcher!(JobKey)))(10);

        globalTriggerListenersMatchers = new LinkedHashMap!(string, List!(Matcher!(TriggerKey)))(10);

        schedulerListeners = new ArrayList!(SchedulerListener)(10);
    }

    
    void addJobListener(JobListener jobListener, Matcher!(JobKey)[] matchers ... ) {
        addJobListener(jobListener, Arrays.asList(matchers));
    }

    void addJobListener(JobListener jobListener, List!(Matcher!(JobKey)) matchers) {
        if (jobListener.getName() is null || jobListener.getName().length() == 0) {
            throw new IllegalArgumentException(
                    "JobListener name cannot be empty.");
        }
        
        synchronized (globalJobListeners) {
            globalJobListeners.put(jobListener.getName(), jobListener);
            LinkedList!(Matcher!(JobKey)) matchersL = new  LinkedList!(Matcher!(JobKey))();
            if(matchers !is null && matchers.size() > 0)
                matchersL.addAll(matchers);
            else
                matchersL.add(EverythingMatcher.allJobs());
            
            globalJobListenersMatchers.put(jobListener.getName(), matchersL);
        }
    }


    void addJobListener(JobListener jobListener) {
        addJobListener(jobListener, EverythingMatcher.allJobs());
    }
    
    void addJobListener(JobListener jobListener, Matcher!(JobKey) matcher) {
        if (jobListener.getName() is null || jobListener.getName().length() == 0) {
            throw new IllegalArgumentException(
                    "JobListener name cannot be empty.");
        }
        
        synchronized (globalJobListeners) {
            globalJobListeners.put(jobListener.getName(), jobListener);
            LinkedList!(Matcher!(JobKey)) matchersL = new  LinkedList!(Matcher!(JobKey))();
            if(matcher !is null)
                matchersL.add(matcher);
            else
                matchersL.add(EverythingMatcher.allJobs());
            
            globalJobListenersMatchers.put(jobListener.getName(), matchersL);
        }
    }


    bool addJobListenerMatcher(string listenerName, Matcher!(JobKey) matcher) {
        if(matcher is null)
            throw new IllegalArgumentException("Null value not acceptable.");
        
        synchronized (globalJobListeners) {
            List!(Matcher!(JobKey)) matchers = globalJobListenersMatchers.get(listenerName);
            if(matchers is null)
                return false;
            matchers.add(matcher);
            return true;
        }
    }

    bool removeJobListenerMatcher(string listenerName, Matcher!(JobKey) matcher) {
        if(matcher is null)
            throw new IllegalArgumentException("Non-null value not acceptable.");
        
        synchronized (globalJobListeners) {
            List!(Matcher!(JobKey)) matchers = globalJobListenersMatchers.get(listenerName);
            if(matchers is null)
                return false;
            return matchers.remove(matcher);
        }
    }

    List!(Matcher!(JobKey)) getJobListenerMatchers(string listenerName) {
        synchronized (globalJobListeners) {
            List!(Matcher!(JobKey)) matchers = globalJobListenersMatchers.get(listenerName);
            if(matchers is null)
                return null;
            return Collections.unmodifiableList(matchers);
        }
    }

    bool setJobListenerMatchers(string listenerName, List!(Matcher!(JobKey)) matchers)  {
        if(matchers is null)
            throw new IllegalArgumentException("Non-null value not acceptable.");
        
        synchronized (globalJobListeners) {
            List!(Matcher!(JobKey)) oldMatchers = globalJobListenersMatchers.get(listenerName);
            if(oldMatchers is null)
                return false;
            globalJobListenersMatchers.put(listenerName, matchers);
            return true;
        }
    }


    bool removeJobListener(string name) {
        synchronized (globalJobListeners) {
            return (globalJobListeners.remove(name) !is null);
        }
    }
    
    List!(JobListener) getJobListeners() {
        synchronized (globalJobListeners) {
            return java.container.Collections.unmodifiableList(new LinkedList!(JobListener)(globalJobListeners.values()));
        }
    }

    JobListener getJobListener(string name) {
        synchronized (globalJobListeners) {
            return globalJobListeners.get(name);
        }
    }

    void addTriggerListener(TriggerListener triggerListener, Matcher!(TriggerKey)[] matchers... ) {
        addTriggerListener(triggerListener, Arrays.asList(matchers));
    }
    
    void addTriggerListener(TriggerListener triggerListener, List!(Matcher!(TriggerKey)) matchers) {
        if (triggerListener.getName() is null
                || triggerListener.getName().length() == 0) {
            throw new IllegalArgumentException(
                    "TriggerListener name cannot be empty.");
        }

        synchronized (globalTriggerListeners) {
            globalTriggerListeners.put(triggerListener.getName(), triggerListener);

            LinkedList!(Matcher!(TriggerKey)) matchersL = new  LinkedList!(Matcher!(TriggerKey))();
            if(matchers !is null && matchers.size() > 0)
                matchersL.addAll(matchers);
            else
                matchersL.add(EverythingMatcher.allTriggers());

            globalTriggerListenersMatchers.put(triggerListener.getName(), matchersL);
        }
    }
    
    void addTriggerListener(TriggerListener triggerListener) {
        addTriggerListener(triggerListener, EverythingMatcher.allTriggers());
    }

    void addTriggerListener(TriggerListener triggerListener, Matcher!(TriggerKey) matcher) {
        if(matcher is null)
            throw new IllegalArgumentException("Null value not acceptable for matcher.");
        
        if (triggerListener.getName() is null
                || triggerListener.getName().length() == 0) {
            throw new IllegalArgumentException(
                    "TriggerListener name cannot be empty.");
        }

        synchronized (globalTriggerListeners) {
            globalTriggerListeners.put(triggerListener.getName(), triggerListener);
            List!(Matcher!(TriggerKey)) matchers = new LinkedList!(Matcher!(TriggerKey))();
            matchers.add(matcher);
            globalTriggerListenersMatchers.put(triggerListener.getName(), matchers);
        }
    }

    bool addTriggerListenerMatcher(string listenerName, Matcher!(TriggerKey) matcher) {
        if(matcher is null)
            throw new IllegalArgumentException("Non-null value not acceptable.");
        
        synchronized (globalTriggerListeners) {
            List!(Matcher!(TriggerKey)) matchers = globalTriggerListenersMatchers.get(listenerName);
            if(matchers is null)
                return false;
            matchers.add(matcher);
            return true;
        }
    }

    bool removeTriggerListenerMatcher(string listenerName, Matcher!(TriggerKey) matcher) {
        if(matcher is null)
            throw new IllegalArgumentException("Non-null value not acceptable.");
        
        synchronized (globalTriggerListeners) {
            List!(Matcher!(TriggerKey)) matchers = globalTriggerListenersMatchers.get(listenerName);
            if(matchers is null)
                return false;
            return matchers.remove(matcher);
        }
    }

    List!(Matcher!(TriggerKey)) getTriggerListenerMatchers(string listenerName) {
        synchronized (globalTriggerListeners) {
            List!(Matcher!(TriggerKey)) matchers = globalTriggerListenersMatchers.get(listenerName);
            if(matchers is null)
                return null;
            return Collections.unmodifiableList(matchers);
        }
    }

    bool setTriggerListenerMatchers(string listenerName, List!(Matcher!(TriggerKey)) matchers)  {
        if(matchers is null)
            throw new IllegalArgumentException("Non-null value not acceptable.");
        
        synchronized (globalTriggerListeners) {
            List!(Matcher!(TriggerKey)) oldMatchers = globalTriggerListenersMatchers.get(listenerName);
            if(oldMatchers is null)
                return false;
            globalTriggerListenersMatchers.put(listenerName, matchers);
            return true;
        }
    }

    bool removeTriggerListener(string name) {
        synchronized (globalTriggerListeners) {
            return (globalTriggerListeners.remove(name) !is null);
        }
    }
    

    List!(TriggerListener) getTriggerListeners() {
        synchronized (globalTriggerListeners) {
            return java.container.Collections.unmodifiableList(new LinkedList!(TriggerListener)(globalTriggerListeners.values()));
        }
    }

    TriggerListener getTriggerListener(string name) {
        synchronized (globalTriggerListeners) {
            return globalTriggerListeners.get(name);
        }
    }
    
    
    void addSchedulerListener(SchedulerListener schedulerListener) {
        synchronized (schedulerListeners) {
            schedulerListeners.add(schedulerListener);
        }
    }

    bool removeSchedulerListener(SchedulerListener schedulerListener) {
        synchronized (schedulerListeners) {
            return schedulerListeners.remove(schedulerListener);
        }
    }

    List!(SchedulerListener) getSchedulerListeners() {
        synchronized (schedulerListeners) {
            return java.container.Collections.unmodifiableList(new ArrayList!(SchedulerListener)(schedulerListeners));
        }
    }
}
