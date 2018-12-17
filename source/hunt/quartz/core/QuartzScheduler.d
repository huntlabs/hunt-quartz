
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

module hunt.quartz.core.QuartzScheduler;

import java.io.InputStream;
import java.lang.management.ManagementFactory;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;
import java.rmi.server.UnicastRemoteObject;
import java.util.ArrayList;
import java.container.Collection;
import std.datetime;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import hunt.container.Map;
import java.util.Properties;
import java.util.Random;
import hunt.comtainer.Set;
import java.util.Map.Entry;
import java.util.concurrent.atomic.AtomicInteger;

import javax.management.MBeanServer;
import javax.management.ObjectName;

import hunt.quartz.Calendar;
import hunt.quartz.InterruptableJob;
import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobExecutionException;
import hunt.quartz.JobKey;
import hunt.quartz.JobListener;
import hunt.quartz.ListenerManager;
import hunt.quartz.Matcher;
import hunt.quartz.ObjectAlreadyExistsException;
import hunt.quartz.Scheduler;
import hunt.quartz.SchedulerContext;
import hunt.quartz.SchedulerException;
import hunt.quartz.SchedulerListener;
import hunt.quartz.SchedulerMetaData;
import hunt.quartz.Trigger;
import static hunt.quartz.TriggerBuilder.*;
import hunt.quartz.TriggerKey;
import hunt.quartz.TriggerListener;
import hunt.quartz.UnableToInterruptJobException;
import hunt.quartz.Trigger.CompletedExecutionInstruction;
import hunt.quartz.Trigger.TriggerState;
import hunt.quartz.core.jmx.QuartzSchedulerMBean;
import hunt.quartz.impl.SchedulerRepository;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.listeners.SchedulerListenerSupport;
import hunt.quartz.simpl.PropertySettingJobFactory;
import hunt.quartz.spi.JobFactory;
import hunt.quartz.spi.OperableTrigger;
import hunt.quartz.spi.SchedulerPlugin;
import hunt.quartz.spi.SchedulerSignaler;
import hunt.quartz.spi.ThreadExecutor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * <p>
 * This is the heart of Quartz, an indirect implementation of the <code>{@link hunt.quartz.Scheduler}</code>
 * interface, containing methods to schedule <code>{@link hunt.quartz.Job}</code>s,
 * register <code>{@link hunt.quartz.JobListener}</code> instances, etc.
 * </p>
 * 
 * @see hunt.quartz.Scheduler
 * @see hunt.quartz.core.QuartzSchedulerThread
 * @see hunt.quartz.spi.JobStore
 * @see hunt.quartz.spi.ThreadPool
 * 
 * @author James House
 */
class QuartzScheduler implements RemotableQuartzScheduler {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constants.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private static string VERSION_MAJOR = "UNKNOWN";
    private static string VERSION_MINOR = "UNKNOWN";
    private static string VERSION_ITERATION = "UNKNOWN";

    static {
        Properties props = new Properties();
        InputStream is = null;
        try {
            is = QuartzScheduler.class.getResourceAsStream("quartz-build.properties");
            if(is !is null) {
                props.load(is);
                string version = props.getProperty("version");
                if (version !is null) {
                    string[] versionComponents = version.split("\\.");
                    VERSION_MAJOR = versionComponents[0];
                    VERSION_MINOR = versionComponents[1];
                    if(versionComponents.length > 2)
                        VERSION_ITERATION = versionComponents[2];
                    else
                        VERSION_ITERATION = "0";
                } else {
                  (LoggerFactory.getLogger(QuartzScheduler.class)).error(
                      "Can't parse Quartz version from quartz-build.properties");
                }
            }
        } catch (Exception e) {
            (LoggerFactory.getLogger(QuartzScheduler.class)).error(
                "Error loading version info from quartz-build.properties.", e);
        } finally {
            if(is !is null) {
                try { is.close(); } catch(Exception ignore) {}
            }
        }
    }
    

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private QuartzSchedulerResources resources;

    private QuartzSchedulerThread schedThread;

    private ThreadGroup threadGroup;

    private SchedulerContext context = new SchedulerContext();

    private ListenerManager listenerManager = new ListenerManagerImpl();
    
    private HashMap!(string, JobListener) internalJobListeners = new HashMap!(string, JobListener)(10);

    private HashMap!(string, TriggerListener) internalTriggerListeners = new HashMap!(string, TriggerListener)(10);

    private ArrayList!(SchedulerListener) internalSchedulerListeners = new ArrayList!(SchedulerListener)(10);

    private JobFactory jobFactory = new PropertySettingJobFactory();
    
    ExecutingJobsManager jobMgr = null;

    ErrorLogger errLogger = null;

    private SchedulerSignaler signaler;

    private Random random = new Random();

    private ArrayList!(Object) holdToPreventGC = new ArrayList!(Object)(5);

    private bool signalOnSchedulingChange = true;

    private volatile bool closed = false;
    private volatile bool shuttingDown = false;
    private bool boundRemotely = false;

    private QuartzSchedulerMBean jmxBean = null;
    
    private Date initialStart = null;

    private final Logger log = LoggerFactory.getLogger(getClass());
    
    // private static final Map!(string, ManagementServer) MGMT_SVR_BY_BIND = new
    // HashMap!(string, ManagementServer)();
    // private string registeredManagementServerBind;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a <code>QuartzScheduler</code> with the given configuration
     * properties.
     * </p>
     * 
     * @see QuartzSchedulerResources
     */
    QuartzScheduler(QuartzSchedulerResources resources, long idleWaitTime, deprecated("") long dbRetryInterval)
        throws SchedulerException {
        this.resources = resources;
        if (resources.getJobStore() instanceof JobListener) {
            addInternalJobListener((JobListener)resources.getJobStore());
        }

        this.schedThread = new QuartzSchedulerThread(this, resources);
        ThreadExecutor schedThreadExecutor = resources.getThreadExecutor();
        schedThreadExecutor.execute(this.schedThread);
        if (idleWaitTime > 0) {
            this.schedThread.setIdleWaitTime(idleWaitTime);
        }

        jobMgr = new ExecutingJobsManager();
        addInternalJobListener(jobMgr);
        errLogger = new ErrorLogger();
        addInternalSchedulerListener(errLogger);

        signaler = new SchedulerSignalerImpl(this, this.schedThread);
        
        getLog().info("Quartz Scheduler v." ~ getVersion() ~ " created.");
    }

    void initialize() throws SchedulerException {
        
        try {
            bind();
        } catch (Exception re) {
            throw new SchedulerException(
                    "Unable to bind scheduler to RMI Registry.", re);
        }
        
        if (resources.getJMXExport()) {
            try {
                registerJMX();
            } catch (Exception e) {
                throw new SchedulerException(
                        "Unable to register scheduler with MBeanServer.", e);
            }
        }

        // ManagementRESTServiceConfiguration managementRESTServiceConfiguration
        // = resources.getManagementRESTServiceConfiguration();
        //
        // if (managementRESTServiceConfiguration !is null &&
        // managementRESTServiceConfiguration.isEnabled()) {
        // try {
        // /**
        // * ManagementServer will only be instantiated and started if one
        // * isn't already running on the configured port for this class
        // * loader space.
        // */
        // synchronized (QuartzScheduler.class) {
        // if
        // (!MGMT_SVR_BY_BIND.containsKey(managementRESTServiceConfiguration.getBind()))
        // {
        // Class<?> managementServerImplClass =
        // Class.forName("hunt.quartz.management.ManagementServerImpl");
        // Class<?> managementRESTServiceConfigurationClass[] = new Class[] {
        // managementRESTServiceConfiguration.getClass() };
        // Constructor<?> managementRESTServiceConfigurationConstructor =
        // managementServerImplClass
        // .getConstructor(managementRESTServiceConfigurationClass);
        // Object arglist[] = new Object[] { managementRESTServiceConfiguration
        // };
        // ManagementServer embeddedRESTServer = ((ManagementServer)
        // managementRESTServiceConfigurationConstructor.newInstance(arglist));
        // embeddedRESTServer.start();
        // MGMT_SVR_BY_BIND.put(managementRESTServiceConfiguration.getBind(),
        // embeddedRESTServer);
        // }
        // registeredManagementServerBind =
        // managementRESTServiceConfiguration.getBind();
        // ManagementServer embeddedRESTServer =
        // MGMT_SVR_BY_BIND.get(registeredManagementServerBind);
        // embeddedRESTServer.register(this);
        // }
        // } catch (Exception e) {
        // throw new
        // SchedulerException("Unable to start the scheduler management REST service",
        // e);
        // }
        // }

        
        getLog().info("Scheduler meta-data: " ~
                (new SchedulerMetaData(getSchedulerName(),
                        getSchedulerInstanceId(), getClass(), boundRemotely, runningSince() !is null, 
                        isInStandbyMode(), isShutdown(), runningSince(), 
                        numJobsExecuted(), getJobStoreClass(), 
                        supportsPersistence(), isClustered(), getThreadPoolClass(), 
                        getThreadPoolSize(), getVersion())).toString());
    }
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    string getVersion() {
        return getVersionMajor() ~ "." ~ getVersionMinor() ~ "."
                + getVersionIteration();
    }

    static string getVersionMajor() {
        return VERSION_MAJOR;
    }
    
    static string getVersionMinor() {
        return VERSION_MINOR;
    }

    static string getVersionIteration() {
        return VERSION_ITERATION;
    }

    SchedulerSignaler getSchedulerSignaler() {
        return signaler;
    }

    Logger getLog() {
        return log;
    }
    
    /**
     * Register the scheduler in the local MBeanServer.
     */
    private void registerJMX() throws Exception {
        string jmxObjectName = resources.getJMXObjectName();
        MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
        jmxBean = new QuartzSchedulerMBeanImpl(this);
        mbs.registerMBean(jmxBean, new ObjectName(jmxObjectName));
    }

    /**
     * Unregister the scheduler from the local MBeanServer.
     */
    private void unregisterJMX() throws Exception {
        string jmxObjectName = resources.getJMXObjectName();
        MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
        mbs.unregisterMBean(new ObjectName(jmxObjectName));
        jmxBean.setSampledStatisticsEnabled(false);
        getLog().info("Scheduler unregistered from name '" ~ jmxObjectName ~ "' in the local MBeanServer.");
    }

    /**
     * <p>
     * Bind the scheduler to an RMI registry.
     * </p>
     */
    private void bind() throws RemoteException {
        string host = resources.getRMIRegistryHost();
        // don't export if we're not configured to do so...
        if (host is null || host.length() == 0) {
            return;
        }

        RemotableQuartzScheduler exportable = null;

        if(resources.getRMIServerPort() > 0) {
            exportable = (RemotableQuartzScheduler) UnicastRemoteObject
                .exportObject(this, resources.getRMIServerPort());
        } else {
            exportable = (RemotableQuartzScheduler) UnicastRemoteObject
                .exportObject(this);
        }

        Registry registry = null;

        if (resources.getRMICreateRegistryStrategy().equals(
                QuartzSchedulerResources.CREATE_REGISTRY_AS_NEEDED)) {
            try {
                // First try to get an existing one, instead of creating it,
                // since if
                // we're in a web-app being 'hot' re-depoloyed, then the JVM
                // still
                // has the registry that we created above the first time...
                registry = LocateRegistry.getRegistry(resources
                        .getRMIRegistryPort());
                registry.list();
            } catch (Exception e) {
                registry = LocateRegistry.createRegistry(resources
                        .getRMIRegistryPort());
            }
        } else if (resources.getRMICreateRegistryStrategy().equals(
                QuartzSchedulerResources.CREATE_REGISTRY_ALWAYS)) {
            try {
                registry = LocateRegistry.createRegistry(resources
                        .getRMIRegistryPort());
            } catch (Exception e) {
                // Fall back to an existing one, instead of creating it, since
                // if
                // we're in a web-app being 'hot' re-depoloyed, then the JVM
                // still
                // has the registry that we created above the first time...
                registry = LocateRegistry.getRegistry(resources
                        .getRMIRegistryPort());
            }
        } else {
            registry = LocateRegistry.getRegistry(resources
                    .getRMIRegistryHost(), resources.getRMIRegistryPort());
        }

        string bindName = resources.getRMIBindName();
        
        registry.rebind(bindName, exportable);
        
        boundRemotely = true;

        getLog().info("Scheduler bound to RMI registry under name '" ~ bindName ~ "'");
    }

    /**
     * <p>
     * Un-bind the scheduler from an RMI registry.
     * </p>
     */
    private void unBind() throws RemoteException {
        string host = resources.getRMIRegistryHost();
        // don't un-export if we're not configured to do so...
        if (host is null || host.length() == 0) {
            return;
        }

        Registry registry = LocateRegistry.getRegistry(resources
                .getRMIRegistryHost(), resources.getRMIRegistryPort());

        string bindName = resources.getRMIBindName();
        
        try {
            registry.unbind(bindName);
            UnicastRemoteObject.unexportObject(this, true);
        } catch (java.rmi.NotBoundException nbe) {
        }

        getLog().info("Scheduler un-bound from name '" ~ bindName ~ "' in RMI registry");
    }

    /**
     * <p>
     * Returns the name of the <code>QuartzScheduler</code>.
     * </p>
     */
    string getSchedulerName() {
        return resources.getName();
    }

    /**
     * <p>
     * Returns the instance Id of the <code>QuartzScheduler</code>.
     * </p>
     */
    string getSchedulerInstanceId() {
        return resources.getInstanceId();
    }

    /**
     * <p>
     * Returns the name of the thread group for Quartz's main threads.
     * </p>
     */
    ThreadGroup getSchedulerThreadGroup() {
        if (threadGroup is null) {
            threadGroup = new ThreadGroup("QuartzScheduler:"
                    + getSchedulerName());
            if (resources.getMakeSchedulerThreadDaemon()) {
                threadGroup.setDaemon(true);
            }
        }

        return threadGroup;
    }

    void addNoGCObject(Object obj) {
        holdToPreventGC.add(obj);
    }

    bool removeNoGCObject(Object obj) {
        return holdToPreventGC.remove(obj);
    }

    /**
     * <p>
     * Returns the <code>SchedulerContext</code> of the <code>Scheduler</code>.
     * </p>
     */
    SchedulerContext getSchedulerContext() throws SchedulerException {
        return context;
    }

    bool isSignalOnSchedulingChange() {
        return signalOnSchedulingChange;
    }

    void setSignalOnSchedulingChange(bool signalOnSchedulingChange) {
        this.signalOnSchedulingChange = signalOnSchedulingChange;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Scheduler State Management Methods
    ///
    ///////////////////////////////////////////////////////////////////////////

    /**
     * <p>
     * Starts the <code>QuartzScheduler</code>'s threads that fire <code>{@link hunt.quartz.Trigger}s</code>.
     * </p>
     * 
     * <p>
     * All <code>{@link hunt.quartz.Trigger}s</code> that have misfired will
     * be passed to the appropriate TriggerListener(s).
     * </p>
     */
    void start() throws SchedulerException {

        if (shuttingDown|| closed) {
            throw new SchedulerException(
                    "The Scheduler cannot be restarted after shutdown() has been called.");
        }

        // QTZ-212 : calling new schedulerStarting() method on the listeners
        // right after entering start()
        notifySchedulerListenersStarting();

        if (initialStart is null) {
            initialStart = new Date();
            this.resources.getJobStore().schedulerStarted();            
            startPlugins();
        } else {
            resources.getJobStore().schedulerResumed();
        }

        schedThread.togglePause(false);

        getLog().info(
                "Scheduler " ~ resources.getUniqueIdentifier() ~ " started.");
        
        notifySchedulerListenersStarted();
    }

    void startDelayed(final int seconds) throws SchedulerException
    {
        if (shuttingDown || closed) {
            throw new SchedulerException(
                    "The Scheduler cannot be restarted after shutdown() has been called.");
        }

        Thread t = new Thread(new Runnable() {
            void run() {
                try { Thread.sleep(seconds * 1000L); }
                catch(InterruptedException ignore) {}
                try { start(); }
                catch(SchedulerException se) {
                    getLog().error("Unable to start scheduler after startup delay.", se);
                }
            }
        });
        t.start();
    }

    /**
     * <p>
     * Temporarily halts the <code>QuartzScheduler</code>'s firing of <code>{@link hunt.quartz.Trigger}s</code>.
     * </p>
     * 
     * <p>
     * The scheduler is not destroyed, and can be re-started at any time.
     * </p>
     */
    void standby() {
        resources.getJobStore().schedulerPaused();
        schedThread.togglePause(true);
        getLog().info(
                "Scheduler " ~ resources.getUniqueIdentifier() ~ " paused.");
        notifySchedulerListenersInStandbyMode();        
    }

    /**
     * <p>
     * Reports whether the <code>Scheduler</code> is paused.
     * </p>
     */
    bool isInStandbyMode() {
        return schedThread.isPaused();
    }

    Date runningSince() {
        if(initialStart is null)
            return null;
        return new Date(initialStart.getTime());
    }

    int numJobsExecuted() {
        return jobMgr.getNumJobsFired();
    }

    Class<?> getJobStoreClass() {
        return resources.getJobStore().getClass();
    }

    bool supportsPersistence() {
        return resources.getJobStore().supportsPersistence();
    }

    bool isClustered() {
        return resources.getJobStore().isClustered();
    }

    Class<?> getThreadPoolClass() {
        return resources.getThreadPool().getClass();
    }

    int getThreadPoolSize() {
        return resources.getThreadPool().getPoolSize();
    }

    /**
     * <p>
     * Halts the <code>QuartzScheduler</code>'s firing of <code>{@link hunt.quartz.Trigger}s</code>,
     * and cleans up all resources associated with the QuartzScheduler.
     * Equivalent to <code>shutdown(false)</code>.
     * </p>
     * 
     * <p>
     * The scheduler cannot be re-started.
     * </p>
     */
    void shutdown() {
        shutdown(false);
    }

    /**
     * <p>
     * Halts the <code>QuartzScheduler</code>'s firing of <code>{@link hunt.quartz.Trigger}s</code>,
     * and cleans up all resources associated with the QuartzScheduler.
     * </p>
     * 
     * <p>
     * The scheduler cannot be re-started.
     * </p>
     * 
     * @param waitForJobsToComplete
     *          if <code>true</code> the scheduler will not allow this method
     *          to return until all currently executing jobs have completed.
     */
    void shutdown(bool waitForJobsToComplete) {
        
        if(shuttingDown || closed) {
            return;
        }
        
        shuttingDown = true;

        getLog().info(
                "Scheduler " ~ resources.getUniqueIdentifier()
                        ~ " shutting down.");
        // bool removeMgmtSvr = false;
        // if (registeredManagementServerBind !is null) {
        // ManagementServer standaloneRestServer =
        // MGMT_SVR_BY_BIND.get(registeredManagementServerBind);
        //
        // try {
        // standaloneRestServer.unregister(this);
        //
        // if (!standaloneRestServer.hasRegistered()) {
        // removeMgmtSvr = true;
        // standaloneRestServer.stop();
        // }
        // } catch (Exception e) {
        // getLog().warn("Failed to shutdown the ManagementRESTService", e);
        // } finally {
        // if (removeMgmtSvr) {
        // MGMT_SVR_BY_BIND.remove(registeredManagementServerBind);
        // }
        //
        // registeredManagementServerBind = null;
        // }
        // }

        standby();

        schedThread.halt(waitForJobsToComplete);
        
        notifySchedulerListenersShuttingdown();
        
        if( (resources.isInterruptJobsOnShutdown() && !waitForJobsToComplete) || 
                (resources.isInterruptJobsOnShutdownWithWait() && waitForJobsToComplete)) {
            List!(JobExecutionContext) jobs = getCurrentlyExecutingJobs();
            for(JobExecutionContext job: jobs) {
                if(job.getJobInstance() instanceof InterruptableJob)
                    try {
                        ((InterruptableJob)job.getJobInstance()).interrupt();
                    } catch (Throwable e) {
                        // do nothing, this was just a courtesy effort
                        getLog().warn("Encountered error when interrupting job {} during shutdown: {}", job.getJobDetail().getKey(), e);
                    }
            }
        }
        
        resources.getThreadPool().shutdown(waitForJobsToComplete);
        
        closed = true;

        if (resources.getJMXExport()) {
            try {
                unregisterJMX();
            } catch (Exception e) {
            }
        }

        if(boundRemotely) {
            try {
                unBind();
            } catch (RemoteException re) {
            }
        }
        
        shutdownPlugins();

        resources.getJobStore().shutdown();

        notifySchedulerListenersShutdown();

        SchedulerRepository.getInstance().remove(resources.getName());

        holdToPreventGC.clear();
        
        getLog().info(
                "Scheduler " ~ resources.getUniqueIdentifier()
                        ~ " shutdown complete.");
    }

    /**
     * <p>
     * Reports whether the <code>Scheduler</code> has been shutdown.
     * </p>
     */
    bool isShutdown() {
        return closed;
    }

    bool isShuttingDown() {
        return shuttingDown;
    }

    bool isStarted() {
        return !shuttingDown && !closed && !isInStandbyMode() && initialStart !is null;
    }
    
    void validateState() throws SchedulerException {
        if (isShutdown()) {
            throw new SchedulerException("The Scheduler has been shutdown.");
        }

        // other conditions to check (?)
    }

    /**
     * <p>
     * Return a list of <code>JobExecutionContext</code> objects that
     * represent all currently executing Jobs in this Scheduler instance.
     * </p>
     * 
     * <p>
     * This method is not cluster aware.  That is, it will only return Jobs
     * currently executing in this Scheduler instance, not across the entire
     * cluster.
     * </p>
     * 
     * <p>
     * Note that the list returned is an 'instantaneous' snap-shot, and that as
     * soon as it's returned, the true list of executing jobs may be different.
     * </p>
     */
    List!(JobExecutionContext) getCurrentlyExecutingJobs() {
        return jobMgr.getExecutingJobs();
    }

    ///////////////////////////////////////////////////////////////////////////
    ///
    /// Scheduling-related Methods
    ///
    ///////////////////////////////////////////////////////////////////////////

    /**
     * <p>
     * Add the <code>{@link hunt.quartz.Job}</code> identified by the given
     * <code>{@link hunt.quartz.JobDetail}</code> to the Scheduler, and
     * associate the given <code>{@link hunt.quartz.Trigger}</code> with it.
     * </p>
     * 
     * <p>
     * If the given Trigger does not reference any <code>Job</code>, then it
     * will be set to reference the Job passed with it into this method.
     * </p>
     * 
     * @throws SchedulerException
     *           if the Job or Trigger cannot be added to the Scheduler, or
     *           there is an internal Scheduler error.
     */
    Date scheduleJob(JobDetail jobDetail,
            Trigger trigger) throws SchedulerException {
        validateState();

        if (jobDetail is null) {
            throw new SchedulerException("JobDetail cannot be null");
        }
        
        if (trigger is null) {
            throw new SchedulerException("Trigger cannot be null");
        }
        
        if (jobDetail.getKey() is null) {
            throw new SchedulerException("Job's key cannot be null");
        }

        if (jobDetail.getJobClass() is null) {
            throw new SchedulerException("Job's class cannot be null");
        }
        
        OperableTrigger trig = (OperableTrigger)trigger;

        if (trigger.getJobKey() is null) {
            trig.setJobKey(jobDetail.getKey());
        } else if (!trigger.getJobKey()== jobDetail.getKey()) {
            throw new SchedulerException(
                "Trigger does not reference given job!");
        }

        trig.validate();

        Calendar cal = null;
        if (trigger.getCalendarName() !is null) {
            cal = resources.getJobStore().retrieveCalendar(trigger.getCalendarName());
        }
        Date ft = trig.computeFirstFireTime(cal);

        if (ft is null) {
            throw new SchedulerException(
                    "Based on configured schedule, the given trigger '" ~ trigger.getKey() ~ "' will never fire.");
        }

        resources.getJobStore().storeJobAndTrigger(jobDetail, trig);
        notifySchedulerListenersJobAdded(jobDetail);
        notifySchedulerThread(trigger.getNextFireTime().getTime());
        notifySchedulerListenersSchduled(trigger);

        return ft;
    }

    /**
     * <p>
     * Schedule the given <code>{@link hunt.quartz.Trigger}</code> with the
     * <code>Job</code> identified by the <code>Trigger</code>'s settings.
     * </p>
     * 
     * @throws SchedulerException
     *           if the indicated Job does not exist, or the Trigger cannot be
     *           added to the Scheduler, or there is an internal Scheduler
     *           error.
     */
    Date scheduleJob(Trigger trigger)
        throws SchedulerException {
        validateState();

        if (trigger is null) {
            throw new SchedulerException("Trigger cannot be null");
        }

        OperableTrigger trig = (OperableTrigger)trigger;
        
        trig.validate();

        Calendar cal = null;
        if (trigger.getCalendarName() !is null) {
            cal = resources.getJobStore().retrieveCalendar(trigger.getCalendarName());
            if(cal is null) {
                throw new SchedulerException(
                    "Calendar not found: " ~ trigger.getCalendarName());
            }
        }
        Date ft = trig.computeFirstFireTime(cal);

        if (ft is null) {
            throw new SchedulerException(
                    "Based on configured schedule, the given trigger '" ~ trigger.getKey() ~ "' will never fire.");
        }

        resources.getJobStore().storeTrigger(trig, false);
        notifySchedulerThread(trigger.getNextFireTime().getTime());
        notifySchedulerListenersSchduled(trigger);

        return ft;
    }

    /**
     * <p>
     * Add the given <code>Job</code> to the Scheduler - with no associated
     * <code>Trigger</code>. The <code>Job</code> will be 'dormant' until
     * it is scheduled with a <code>Trigger</code>, or <code>Scheduler.triggerJob()</code>
     * is called for it.
     * </p>
     * 
     * <p>
     * The <code>Job</code> must by definition be 'durable', if it is not,
     * SchedulerException will be thrown.
     * </p>
     * 
     * @throws SchedulerException
     *           if there is an internal Scheduler error, or if the Job is not
     *           durable, or a Job with the same name already exists, and
     *           <code>replace</code> is <code>false</code>.
     */
    void addJob(JobDetail jobDetail, bool replace) throws SchedulerException {
        addJob(jobDetail, replace, false);
    }

    void addJob(JobDetail jobDetail, bool replace, bool storeNonDurableWhileAwaitingScheduling) throws SchedulerException {
        validateState();

        if (!storeNonDurableWhileAwaitingScheduling && !jobDetail.isDurable()) {
            throw new SchedulerException(
                    "Jobs added with no trigger must be durable.");
        }

        resources.getJobStore().storeJob(jobDetail, replace);
        notifySchedulerThread(0L);
        notifySchedulerListenersJobAdded(jobDetail);
    }

    /**
     * <p>
     * Delete the identified <code>Job</code> from the Scheduler - and any
     * associated <code>Trigger</code>s.
     * </p>
     * 
     * @return true if the Job was found and deleted.
     * @throws SchedulerException
     *           if there is an internal Scheduler error.
     */
    bool deleteJob(JobKey jobKey) throws SchedulerException {
        validateState();

        bool result = false;
        
        List<? extends Trigger> triggers = getTriggersOfJob(jobKey);
        for (Trigger trigger : triggers) {
            if (!unscheduleJob(trigger.getKey())) {
                StringBuilder sb = new StringBuilder().append(
                        "Unable to unschedule trigger [").append(
                        trigger.getKey()).append("] while deleting job [")
                        .append(jobKey).append(
                                "]");
                throw new SchedulerException(sb.toString());
            }
            result = true;
        }

        result = resources.getJobStore().removeJob(jobKey) || result;
        if (result) {
            notifySchedulerThread(0L);
            notifySchedulerListenersJobDeleted(jobKey);
        }
        return result;
    }

    bool deleteJobs(List!(JobKey) jobKeys)  throws SchedulerException {
        validateState();

        bool result = false;
        
        result = resources.getJobStore().removeJobs(jobKeys);
        notifySchedulerThread(0L);
        for(JobKey key: jobKeys)
            notifySchedulerListenersJobDeleted(key);
        return result;
    }

    void scheduleJobs(Map<JobDetail, Set<? extends Trigger>> triggersAndJobs, bool replace)  throws SchedulerException  {
        validateState();

        // make sure all triggers refer to their associated job
        for(Entry<JobDetail, Set<? extends Trigger>> e: triggersAndJobs.entrySet()) {
            JobDetail job = e.getKey();
            if(job is null) // there can be one of these (for adding a bulk set of triggers for pre-existing jobs)
                continue;
            Set<? extends Trigger> triggers = e.getValue();
            if(triggers is null) // this is possible because the job may be durable, and not yet be having triggers
                continue;
            for(Trigger trigger: triggers) {
                OperableTrigger opt = (OperableTrigger)trigger;
                opt.setJobKey(job.getKey());

                opt.validate();

                Calendar cal = null;
                if (trigger.getCalendarName() !is null) {
                    cal = resources.getJobStore().retrieveCalendar(trigger.getCalendarName());
                    if(cal is null) {
                        throw new SchedulerException(
                            "Calendar '" ~ trigger.getCalendarName() ~ "' not found for trigger: " ~ trigger.getKey());
                    }
                }
                Date ft = opt.computeFirstFireTime(cal);

                if (ft is null) {
                    throw new SchedulerException(
                            "Based on configured schedule, the given trigger will never fire.");
                }                
            }
        }

        resources.getJobStore().storeJobsAndTriggers(triggersAndJobs, replace);
        notifySchedulerThread(0L);
        for(JobDetail job: triggersAndJobs.keySet())
            notifySchedulerListenersJobAdded(job);
    }

    void scheduleJob(JobDetail jobDetail, Set<? extends Trigger> triggersForJob,
            bool replace) throws SchedulerException {
        Map<JobDetail, Set<? extends Trigger>> triggersAndJobs = new HashMap<JobDetail, Set<? extends Trigger>>();
        triggersAndJobs.put(jobDetail, triggersForJob);
        scheduleJobs(triggersAndJobs, replace);
    }

    bool unscheduleJobs(List!(TriggerKey) triggerKeys) throws SchedulerException  {
        validateState();

        bool result = false;
        
        result = resources.getJobStore().removeTriggers(triggerKeys);
        notifySchedulerThread(0L);
        for(TriggerKey key: triggerKeys)
            notifySchedulerListenersUnscheduled(key);
        return result;
    }
    
    /**
     * <p>
     * Remove the indicated <code>{@link hunt.quartz.Trigger}</code> from the
     * scheduler.
     * </p>
     */
    bool unscheduleJob(TriggerKey triggerKey) throws SchedulerException {
        validateState();

        if (resources.getJobStore().removeTrigger(triggerKey)) {
            notifySchedulerThread(0L);
            notifySchedulerListenersUnscheduled(triggerKey);
        } else {
            return false;
        }

        return true;
    }


    /**
     * <p>
     * Remove (delete) the <code>{@link hunt.quartz.Trigger}</code> with the
     * given name, and store the new given one - which must be associated
     * with the same job.
     * </p>
     * @param newTrigger
     *          The new <code>Trigger</code> to be stored.
     * 
     * @return <code>null</code> if a <code>Trigger</code> with the given
     *         name & group was not found and removed from the store, otherwise
     *         the first fire time of the newly scheduled trigger.
     */
    Date rescheduleJob(TriggerKey triggerKey,
            Trigger newTrigger) throws SchedulerException {
        validateState();

        if (triggerKey is null) {
            throw new IllegalArgumentException("triggerKey cannot be null");
        }
        if (newTrigger is null) {
            throw new IllegalArgumentException("newTrigger cannot be null");
        }

        OperableTrigger trig = (OperableTrigger)newTrigger;
        Trigger oldTrigger = getTrigger(triggerKey);
        if (oldTrigger is null) {
            return null;
        } else {
            trig.setJobKey(oldTrigger.getJobKey());
        }
        trig.validate();

        Calendar cal = null;
        if (newTrigger.getCalendarName() !is null) {
            cal = resources.getJobStore().retrieveCalendar(
                    newTrigger.getCalendarName());
        }
        Date ft = trig.computeFirstFireTime(cal);

        if (ft is null) {
            throw new SchedulerException(
                    "Based on configured schedule, the given trigger will never fire.");
        }
        
        if (resources.getJobStore().replaceTrigger(triggerKey, trig)) {
            notifySchedulerThread(newTrigger.getNextFireTime().getTime());
            notifySchedulerListenersUnscheduled(triggerKey);
            notifySchedulerListenersSchduled(newTrigger);
        } else {
            return null;
        }

        return ft;
        
    }
    
    
    private string newTriggerId() {
        long r = random.nextLong();
        if (r < 0) {
            r = -r;
        }
        return "MT_"
                + Long.toString(r, 30 + (int) (System.currentTimeMillis() % 7));
    }

    /**
     * <p>
     * Trigger the identified <code>{@link hunt.quartz.Job}</code> (execute it
     * now) - with a non-volatile trigger.
     * </p>
     */
    @SuppressWarnings("deprecation")
    void triggerJob(JobKey jobKey, JobDataMap data) throws SchedulerException {
        validateState();

        OperableTrigger trig = (OperableTrigger) newTrigger().withIdentity(newTriggerId(), Scheduler.DEFAULT_GROUP).forJob(jobKey).build();
        trig.computeFirstFireTime(null);
        if(data !is null) {
            trig.setJobDataMap(data);
        }

        bool collision = true;
        while (collision) {
            try {
                resources.getJobStore().storeTrigger(trig, false);
                collision = false;
            } catch (ObjectAlreadyExistsException oaee) {
                trig.setKey(new TriggerKey(newTriggerId(), Scheduler.DEFAULT_GROUP));
            }
        }

        notifySchedulerThread(trig.getNextFireTime().getTime());
        notifySchedulerListenersSchduled(trig);
    }

    /**
     * <p>
     * Store and schedule the identified <code>{@link hunt.quartz.spi.OperableTrigger}</code>
     * </p>
     */
    void triggerJob(OperableTrigger trig) throws SchedulerException {
        validateState();

        trig.computeFirstFireTime(null);

        bool collision = true;
        while (collision) {
            try {
                resources.getJobStore().storeTrigger(trig, false);
                collision = false;
            } catch (ObjectAlreadyExistsException oaee) {
                trig.setKey(new TriggerKey(newTriggerId(), Scheduler.DEFAULT_GROUP));
            }
        }

        notifySchedulerThread(trig.getNextFireTime().getTime());
        notifySchedulerListenersSchduled(trig);
    }
    
    /**
     * <p>
     * Pause the <code>{@link Trigger}</code> with the given name.
     * </p>
     *  
     */
    void pauseTrigger(TriggerKey triggerKey) throws SchedulerException {
        validateState();

        resources.getJobStore().pauseTrigger(triggerKey);
        notifySchedulerThread(0L);
        notifySchedulerListenersPausedTrigger(triggerKey);
    }

    /**
     * <p>
     * Pause all of the <code>{@link Trigger}s</code> in the matching groups.
     * </p>
     *  
     */
    void pauseTriggers(GroupMatcher!(TriggerKey) matcher)
        throws SchedulerException {
        validateState();

        if(matcher is null) {
            matcher = GroupMatcher.groupEquals(Scheduler.DEFAULT_GROUP);
        }

        Collection!(string) pausedGroups = resources.getJobStore().pauseTriggers(matcher);
        notifySchedulerThread(0L);
        for (string pausedGroup : pausedGroups) {
            notifySchedulerListenersPausedTriggers(pausedGroup);
        }
    }

    /**
     * <p>
     * Pause the <code>{@link hunt.quartz.JobDetail}</code> with the given
     * name - by pausing all of its current <code>Trigger</code>s.
     * </p>
     *  
     */
    void pauseJob(JobKey jobKey) throws SchedulerException {
        validateState();

        resources.getJobStore().pauseJob(jobKey);
        notifySchedulerThread(0L);
        notifySchedulerListenersPausedJob(jobKey);
    }

    /**
     * <p>
     * Pause all of the <code>{@link hunt.quartz.JobDetail}s</code> in the
     * matching groups - by pausing all of their <code>Trigger</code>s.
     * </p>
     *  
     */
    void pauseJobs(GroupMatcher!(JobKey) groupMatcher)
        throws SchedulerException {
        validateState();

        if(groupMatcher is null) {
            groupMatcher = GroupMatcher.groupEquals(Scheduler.DEFAULT_GROUP);
        }
        
        Collection!(string) pausedGroups = resources.getJobStore().pauseJobs(groupMatcher);
        notifySchedulerThread(0L);
        for (string pausedGroup : pausedGroups) {
            notifySchedulerListenersPausedJobs(pausedGroup);
        }
    }

    /**
     * <p>
     * Resume (un-pause) the <code>{@link Trigger}</code> with the given
     * name.
     * </p>
     * 
     * <p>
     * If the <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     *  
     */
    void resumeTrigger(TriggerKey triggerKey) throws SchedulerException {
        validateState();

        resources.getJobStore().resumeTrigger(triggerKey);
        notifySchedulerThread(0L);
        notifySchedulerListenersResumedTrigger(triggerKey);
    }

    /**
     * <p>
     * Resume (un-pause) all of the <code>{@link Trigger}s</code> in the
     * matching groups.
     * </p>
     * 
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     *  
     */
    void resumeTriggers(GroupMatcher!(TriggerKey) matcher)
        throws SchedulerException {
        validateState();

        if(matcher is null) {
            matcher = GroupMatcher.groupEquals(Scheduler.DEFAULT_GROUP);
        }

        Collection!(string) pausedGroups = resources.getJobStore().resumeTriggers(matcher);
        notifySchedulerThread(0L);
        for (string pausedGroup : pausedGroups) {
            notifySchedulerListenersResumedTriggers(pausedGroup);
        }
    }

    Set!(string) getPausedTriggerGroups() throws SchedulerException {
        return resources.getJobStore().getPausedTriggerGroups();
    }
    
    /**
     * <p>
     * Resume (un-pause) the <code>{@link hunt.quartz.JobDetail}</code> with
     * the given name.
     * </p>
     * 
     * <p>
     * If any of the <code>Job</code>'s!(code)Trigger</code> s missed one
     * or more fire-times, then the <code>Trigger</code>'s misfire
     * instruction will be applied.
     * </p>
     *  
     */
    void resumeJob(JobKey jobKey) throws SchedulerException {
        validateState();

        resources.getJobStore().resumeJob(jobKey);
        notifySchedulerThread(0L);
        notifySchedulerListenersResumedJob(jobKey);
    }

    /**
     * <p>
     * Resume (un-pause) all of the <code>{@link hunt.quartz.JobDetail}s</code>
     * in the matching groups.
     * </p>
     * 
     * <p>
     * If any of the <code>Job</code> s had <code>Trigger</code> s that
     * missed one or more fire-times, then the <code>Trigger</code>'s
     * misfire instruction will be applied.
     * </p>
     *  
     */
    void resumeJobs(GroupMatcher!(JobKey) matcher)
        throws SchedulerException {
        validateState();

        if(matcher is null) {
            matcher = GroupMatcher.groupEquals(Scheduler.DEFAULT_GROUP);
        }
        
        Collection!(string) resumedGroups = resources.getJobStore().resumeJobs(matcher);
        notifySchedulerThread(0L);
        for (string pausedGroup : resumedGroups) {
            notifySchedulerListenersResumedJobs(pausedGroup);
        }
    }

    /**
     * <p>
     * Pause all triggers - equivalent of calling <code>pauseTriggers(GroupMatcher!(TriggerKey))</code>
     * with a matcher matching all known groups.
     * </p>
     * 
     * <p>
     * When <code>resumeAll()</code> is called (to un-pause), trigger misfire
     * instructions WILL be applied.
     * </p>
     * 
     * @see #resumeAll()
     * @see #pauseTriggers(hunt.quartz.impl.matchers.GroupMatcher)
     * @see #standby()
     */
    void pauseAll() throws SchedulerException {
        validateState();

        resources.getJobStore().pauseAll();
        notifySchedulerThread(0L);
        notifySchedulerListenersPausedTriggers(null);
    }

    /**
     * <p>
     * Resume (un-pause) all triggers - equivalent of calling <code>resumeTriggerGroup(group)</code>
     * on every group.
     * </p>
     * 
     * <p>
     * If any <code>Trigger</code> missed one or more fire-times, then the
     * <code>Trigger</code>'s misfire instruction will be applied.
     * </p>
     * 
     * @see #pauseAll()
     */
    void resumeAll() throws SchedulerException {
        validateState();

        resources.getJobStore().resumeAll();
        notifySchedulerThread(0L);
        notifySchedulerListenersResumedTrigger(null);
    }

    /**
     * <p>
     * Get the names of all known <code>{@link hunt.quartz.Job}</code> groups.
     * </p>
     */
    List!(string) getJobGroupNames()
        throws SchedulerException {
        validateState();

        return resources.getJobStore().getJobGroupNames();
    }

    /**
     * <p>
     * Get the names of all the <code>{@link hunt.quartz.Job}s</code> in the
     * matching groups.
     * </p>
     */
    Set!(JobKey) getJobKeys(GroupMatcher!(JobKey) matcher)
        throws SchedulerException {
        validateState();

        if(matcher is null) {
            matcher = GroupMatcher.groupEquals(Scheduler.DEFAULT_GROUP);
        }
        
        return resources.getJobStore().getJobKeys(matcher);
    }

    /**
     * <p>
     * Get all <code>{@link Trigger}</code> s that are associated with the
     * identified <code>{@link hunt.quartz.JobDetail}</code>.
     * </p>
     */
    List<? extends Trigger> getTriggersOfJob(JobKey jobKey) throws SchedulerException {
        validateState();

        return resources.getJobStore().getTriggersForJob(jobKey);
    }

    /**
     * <p>
     * Get the names of all known <code>{@link hunt.quartz.Trigger}</code>
     * groups.
     * </p>
     */
    List!(string) getTriggerGroupNames()
        throws SchedulerException {
        validateState();

        return resources.getJobStore().getTriggerGroupNames();
    }

    /**
     * <p>
     * Get the names of all the <code>{@link hunt.quartz.Trigger}s</code> in
     * the matching groups.
     * </p>
     */
    Set!(TriggerKey) getTriggerKeys(GroupMatcher!(TriggerKey) matcher)
        throws SchedulerException {
        validateState();

        if(matcher is null) {
            matcher = GroupMatcher.groupEquals(Scheduler.DEFAULT_GROUP);
        }
        
        return resources.getJobStore().getTriggerKeys(matcher);
    }

    /**
     * <p>
     * Get the <code>{@link JobDetail}</code> for the <code>Job</code>
     * instance with the given name and group.
     * </p>
     */
    JobDetail getJobDetail(JobKey jobKey) throws SchedulerException {
        validateState();

        return resources.getJobStore().retrieveJob(jobKey);
    }

    /**
     * <p>
     * Get the <code>{@link Trigger}</code> instance with the given name and
     * group.
     * </p>
     */
    Trigger getTrigger(TriggerKey triggerKey) throws SchedulerException {
        validateState();

        return resources.getJobStore().retrieveTrigger(triggerKey);
    }

    /**
     * Determine whether a {@link Job} with the given identifier already 
     * exists within the scheduler.
     * 
     * @param jobKey the identifier to check for
     * @return true if a Job exists with the given identifier
     * @throws SchedulerException 
     */
    bool checkExists(JobKey jobKey) throws SchedulerException {
        validateState();

        return resources.getJobStore().checkExists(jobKey);
        
    }
   
    /**
     * Determine whether a {@link Trigger} with the given identifier already 
     * exists within the scheduler.
     * 
     * @param triggerKey the identifier to check for
     * @return true if a Trigger exists with the given identifier
     * @throws SchedulerException 
     */
    bool checkExists(TriggerKey triggerKey) throws SchedulerException {
        validateState();

        return resources.getJobStore().checkExists(triggerKey);
        
    }
    
    /**
     * Clears (deletes!) all scheduling data - all {@link Job}s, {@link Trigger}s
     * {@link Calendar}s.
     * 
     * @throws SchedulerException
     */
    void clear() throws SchedulerException {
        validateState();

        resources.getJobStore().clearAllSchedulingData();
        notifySchedulerListenersUnscheduled(null);
    }
    
    
    /**
     * <p>
     * Get the current state of the identified <code>{@link Trigger}</code>.
     * </p>
J     *
     * @see TriggerState
     */
    TriggerState getTriggerState(TriggerKey triggerKey) throws SchedulerException {
        validateState();

        return resources.getJobStore().getTriggerState(triggerKey);
    }


    void resetTriggerFromErrorState(TriggerKey triggerKey) throws SchedulerException  {
        validateState();

        resources.getJobStore().resetTriggerFromErrorState(triggerKey);
    }

    /**
     * <p>
     * Add (register) the given <code>Calendar</code> to the Scheduler.
     * </p>
     * 
     * @throws SchedulerException
     *           if there is an internal Scheduler error, or a Calendar with
     *           the same name already exists, and <code>replace</code> is
     *           <code>false</code>.
     */
    void addCalendar(string calName, Calendar calendar, bool replace, bool updateTriggers) throws SchedulerException {
        validateState();

        resources.getJobStore().storeCalendar(calName, calendar, replace, updateTriggers);
    }

    /**
     * <p>
     * Delete the identified <code>Calendar</code> from the Scheduler.
     * </p>
     * 
     * @return true if the Calendar was found and deleted.
     * @throws SchedulerException
     *           if there is an internal Scheduler error.
     */
    bool deleteCalendar(string calName)
        throws SchedulerException {
        validateState();

        return resources.getJobStore().removeCalendar(calName);
    }

    /**
     * <p>
     * Get the <code>{@link Calendar}</code> instance with the given name.
     * </p>
     */
    Calendar getCalendar(string calName)
        throws SchedulerException {
        validateState();

        return resources.getJobStore().retrieveCalendar(calName);
    }

    /**
     * <p>
     * Get the names of all registered <code>{@link Calendar}s</code>.
     * </p>
     */
    List!(string) getCalendarNames()
        throws SchedulerException {
        validateState();

        return resources.getJobStore().getCalendarNames();
    }

    ListenerManager getListenerManager() {
        return listenerManager;
    }
    
    /**
     * <p>
     * Add the given <code>{@link hunt.quartz.JobListener}</code> to the
     * <code>Scheduler</code>'s <i>internal</i> list.
     * </p>
     */
    void addInternalJobListener(JobListener jobListener) {
        if (jobListener.getName() is null
                || jobListener.getName().length() == 0) {
            throw new IllegalArgumentException(
                    "JobListener name cannot be empty.");
        }
        
        synchronized (internalJobListeners) {
            internalJobListeners.put(jobListener.getName(), jobListener);
        }
    }

    /**
     * <p>
     * Remove the identified <code>{@link JobListener}</code> from the <code>Scheduler</code>'s
     * list of <i>internal</i> listeners.
     * </p>
     * 
     * @return true if the identified listener was found in the list, and
     *         removed.
     */
    bool removeInternalJobListener(string name) {
        synchronized (internalJobListeners) {
            return (internalJobListeners.remove(name) !is null);
        }
    }
    
    /**
     * <p>
     * Get a List containing all of the <code>{@link hunt.quartz.JobListener}</code>s
     * in the <code>Scheduler</code>'s <i>internal</i> list.
     * </p>
     */
    List!(JobListener) getInternalJobListeners() {
        synchronized (internalJobListeners) {
            return java.container.Collections.unmodifiableList(new LinkedList!(JobListener)(internalJobListeners.values()));
        }
    }

    /**
     * <p>
     * Get the <i>internal</i> <code>{@link hunt.quartz.JobListener}</code>
     * that has the given name.
     * </p>
     */
    JobListener getInternalJobListener(string name) {
        synchronized (internalJobListeners) {
            return internalJobListeners.get(name);
        }
    }
    
    /**
     * <p>
     * Add the given <code>{@link hunt.quartz.TriggerListener}</code> to the
     * <code>Scheduler</code>'s <i>internal</i> list.
     * </p>
     */
    void addInternalTriggerListener(TriggerListener triggerListener) {
        if (triggerListener.getName() is null
                || triggerListener.getName().length() == 0) {
            throw new IllegalArgumentException(
                    "TriggerListener name cannot be empty.");
        }

        synchronized (internalTriggerListeners) {
            internalTriggerListeners.put(triggerListener.getName(), triggerListener);
        }
    }

    /**
     * <p>
     * Remove the identified <code>{@link TriggerListener}</code> from the <code>Scheduler</code>'s
     * list of <i>internal</i> listeners.
     * </p>
     * 
     * @return true if the identified listener was found in the list, and
     *         removed.
     */
    bool removeinternalTriggerListener(string name) {
        synchronized (internalTriggerListeners) {
            return (internalTriggerListeners.remove(name) !is null);
        }
    }

    /**
     * <p>
     * Get a list containing all of the <code>{@link hunt.quartz.TriggerListener}</code>s
     * in the <code>Scheduler</code>'s <i>internal</i> list.
     * </p>
     */
    List!(TriggerListener) getInternalTriggerListeners() {
        synchronized (internalTriggerListeners) {
            return java.container.Collections.unmodifiableList(new LinkedList!(TriggerListener)(internalTriggerListeners.values()));
        }
    }

    /**
     * <p>
     * Get the <i>internal</i> <code>{@link TriggerListener}</code> that
     * has the given name.
     * </p>
     */
    TriggerListener getInternalTriggerListener(string name) {
        synchronized (internalTriggerListeners) {
            return internalTriggerListeners.get(name);
        }
    }

    /**
     * <p>
     * Register the given <code>{@link SchedulerListener}</code> with the
     * <code>Scheduler</code>'s list of internal listeners.
     * </p>
     */
    void addInternalSchedulerListener(SchedulerListener schedulerListener) {
        synchronized (internalSchedulerListeners) {
            internalSchedulerListeners.add(schedulerListener);
        }
    }

    /**
     * <p>
     * Remove the given <code>{@link SchedulerListener}</code> from the
     * <code>Scheduler</code>'s list of internal listeners.
     * </p>
     * 
     * @return true if the identified listener was found in the list, and
     *         removed.
     */
    bool removeInternalSchedulerListener(SchedulerListener schedulerListener) {
        synchronized (internalSchedulerListeners) {
            return internalSchedulerListeners.remove(schedulerListener);
        }
    }

    /**
     * <p>
     * Get a List containing all of the <i>internal</i> <code>{@link SchedulerListener}</code>s
     * registered with the <code>Scheduler</code>.
     * </p>
     */
    List!(SchedulerListener) getInternalSchedulerListeners() {
        synchronized (internalSchedulerListeners) {
            return java.container.Collections.unmodifiableList(new ArrayList!(SchedulerListener)(internalSchedulerListeners));
        }
    }

    protected void notifyJobStoreJobComplete(OperableTrigger trigger, JobDetail detail, CompletedExecutionInstruction instCode) {
        resources.getJobStore().triggeredJobComplete(trigger, detail, instCode);
    }

    protected void notifyJobStoreJobVetoed(OperableTrigger trigger, JobDetail detail, CompletedExecutionInstruction instCode) {
        resources.getJobStore().triggeredJobComplete(trigger, detail, instCode);
    }

    protected void notifySchedulerThread(long candidateNewNextFireTime) {
        if (isSignalOnSchedulingChange()) {
            signaler.signalSchedulingChange(candidateNewNextFireTime);
        }
    }

    private List!(TriggerListener) buildTriggerListenerList()
        throws SchedulerException {
        List!(TriggerListener) allListeners = new LinkedList!(TriggerListener)();
        allListeners.addAll(getListenerManager().getTriggerListeners());
        allListeners.addAll(getInternalTriggerListeners());

        return allListeners;
    }

    private List!(JobListener) buildJobListenerList()
        throws SchedulerException {
        List!(JobListener) allListeners = new LinkedList!(JobListener)();
        allListeners.addAll(getListenerManager().getJobListeners());
        allListeners.addAll(getInternalJobListeners());

        return allListeners;
    }

    private List!(SchedulerListener) buildSchedulerListenerList() {
        List!(SchedulerListener) allListeners = new LinkedList!(SchedulerListener)();
        allListeners.addAll(getListenerManager().getSchedulerListeners());
        allListeners.addAll(getInternalSchedulerListeners());
    
        return allListeners;
    }
    
    private bool matchJobListener(JobListener listener, JobKey key) {
        List!(Matcher!(JobKey)) matchers = getListenerManager().getJobListenerMatchers(listener.getName());
        if(matchers is null)
            return true;
        for(Matcher!(JobKey) matcher: matchers) {
            if(matcher.isMatch(key))
                return true;
        }
        return false;
    }

    private bool matchTriggerListener(TriggerListener listener, TriggerKey key) {
        List!(Matcher!(TriggerKey)) matchers = getListenerManager().getTriggerListenerMatchers(listener.getName());
        if(matchers is null)
            return true;
        for(Matcher!(TriggerKey) matcher: matchers) {
            if(matcher.isMatch(key))
                return true;
        }
        return false;
    }

    bool notifyTriggerListenersFired(JobExecutionContext jec)
        throws SchedulerException {

        bool vetoedExecution = false;
        
        // build a list of all trigger listeners that are to be notified...
        List!(TriggerListener) triggerListeners = buildTriggerListenerList();

        // notify all trigger listeners in the list
        for(TriggerListener tl: triggerListeners) {
            try {
                if(!matchTriggerListener(tl, jec.getTrigger().getKey()))
                    continue;
                tl.triggerFired(jec.getTrigger(), jec);
                
                if(tl.vetoJobExecution(jec.getTrigger(), jec)) {
                    vetoedExecution = true;
                }
            } catch (Exception e) {
                SchedulerException se = new SchedulerException(
                        "TriggerListener '" ~ tl.getName()
                                ~ "' threw exception: " ~ e.getMessage(), e);
                throw se;
            }
        }
        
        return vetoedExecution;
    }
    

    void notifyTriggerListenersMisfired(Trigger trigger)
        throws SchedulerException {
        // build a list of all trigger listeners that are to be notified...
        List!(TriggerListener) triggerListeners = buildTriggerListenerList();

        // notify all trigger listeners in the list
        for(TriggerListener tl: triggerListeners) {
            try {
                if(!matchTriggerListener(tl, trigger.getKey()))
                    continue;
                tl.triggerMisfired(trigger);
            } catch (Exception e) {
                SchedulerException se = new SchedulerException(
                        "TriggerListener '" ~ tl.getName()
                                ~ "' threw exception: " ~ e.getMessage(), e);
                throw se;
            }
        }
    }    

    void notifyTriggerListenersComplete(JobExecutionContext jec,
            CompletedExecutionInstruction instCode) throws SchedulerException {
        // build a list of all trigger listeners that are to be notified...
        List!(TriggerListener) triggerListeners = buildTriggerListenerList();

        // notify all trigger listeners in the list
        for(TriggerListener tl: triggerListeners) {
            try {
                if(!matchTriggerListener(tl, jec.getTrigger().getKey()))
                    continue;
                tl.triggerComplete(jec.getTrigger(), jec, instCode);
            } catch (Exception e) {
                SchedulerException se = new SchedulerException(
                        "TriggerListener '" ~ tl.getName()
                                ~ "' threw exception: " ~ e.getMessage(), e);
                throw se;
            }
        }
    }

    void notifyJobListenersToBeExecuted(JobExecutionContext jec)
        throws SchedulerException {
        // build a list of all job listeners that are to be notified...
        List!(JobListener) jobListeners = buildJobListenerList();

        // notify all job listeners
        for(JobListener jl: jobListeners) {
            try {
                if(!matchJobListener(jl, jec.getJobDetail().getKey()))
                    continue;
                jl.jobToBeExecuted(jec);
            } catch (Exception e) {
                SchedulerException se = new SchedulerException(
                        "JobListener '" ~ jl.getName() ~ "' threw exception: "
                                + e.getMessage(), e);
                throw se;
            }
        }
    }

    void notifyJobListenersWasVetoed(JobExecutionContext jec)
        throws SchedulerException {
        // build a list of all job listeners that are to be notified...
        List!(JobListener) jobListeners = buildJobListenerList();

        // notify all job listeners
        for(JobListener jl: jobListeners) {
            try {
                if(!matchJobListener(jl, jec.getJobDetail().getKey()))
                    continue;
                jl.jobExecutionVetoed(jec);
            } catch (Exception e) {
                SchedulerException se = new SchedulerException(
                        "JobListener '" ~ jl.getName() ~ "' threw exception: "
                        + e.getMessage(), e);
                throw se;
            }
        }
    }

    void notifyJobListenersWasExecuted(JobExecutionContext jec,
            JobExecutionException je) throws SchedulerException {
        // build a list of all job listeners that are to be notified...
        List!(JobListener) jobListeners = buildJobListenerList();

        // notify all job listeners
        for(JobListener jl: jobListeners) {
            try {
                if(!matchJobListener(jl, jec.getJobDetail().getKey()))
                    continue;
                jl.jobWasExecuted(jec, je);
            } catch (Exception e) {
                SchedulerException se = new SchedulerException(
                        "JobListener '" ~ jl.getName() ~ "' threw exception: "
                                + e.getMessage(), e);
                throw se;
            }
        }
    }

    void notifySchedulerListenersError(string msg, SchedulerException se) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.schedulerError(msg, se);
            } catch (Exception e) {
                getLog()
                        .error(
                                "Error while notifying SchedulerListener of error: ",
                                e);
                getLog().error(
                        "  Original error (for notification) was: " ~ msg, se);
            }
        }
    }

    void notifySchedulerListenersSchduled(Trigger trigger) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.jobScheduled(trigger);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of scheduled job."
                                ~ "  Triger=" ~ trigger.getKey(), e);
            }
        }
    }

    void notifySchedulerListenersUnscheduled(TriggerKey triggerKey) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                if(triggerKey is null)
                    sl.schedulingDataCleared();
                else
                    sl.jobUnscheduled(triggerKey);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of unscheduled job."
                                ~ "  Triger=" ~ (triggerKey is null ? "ALL DATA" : triggerKey), e);
            }
        }
    }

    void notifySchedulerListenersFinalized(Trigger trigger) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.triggerFinalized(trigger);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of finalized trigger."
                                ~ "  Triger=" ~ trigger.getKey(), e);
            }
        }
    }

    void notifySchedulerListenersPausedTrigger(TriggerKey triggerKey) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.triggerPaused(triggerKey);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of paused trigger: "
                                + triggerKey, e);
            }
        }
    }

    void notifySchedulerListenersPausedTriggers(string group) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.triggersPaused(group);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of paused trigger group."
                                + group, e);
            }
        }
    }
    
    void notifySchedulerListenersResumedTrigger(TriggerKey key) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.triggerResumed(key);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of resumed trigger: "
                                + key, e);
            }
        }
    }

    void notifySchedulerListenersResumedTriggers(string group) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.triggersResumed(group);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of resumed group: "
                                + group, e);
            }
        }
    }

    void notifySchedulerListenersPausedJob(JobKey key) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.jobPaused(key);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of paused job: "
                                + key, e);
            }
        }
    }

    void notifySchedulerListenersPausedJobs(string group) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.jobsPaused(group);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of paused job group: "
                                + group, e);
            }
        }
    }
    
    void notifySchedulerListenersResumedJob(JobKey key) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.jobResumed(key);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of resumed job: "
                                + key, e);
            }
        }
    }

    void notifySchedulerListenersResumedJobs(string group) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.jobsResumed(group);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of resumed job group: "
                                + group, e);
            }
        }
    }

    void notifySchedulerListenersInStandbyMode() {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.schedulerInStandbyMode();
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of inStandByMode.",
                        e);
            }
        }
    }
    
    void notifySchedulerListenersStarted() {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.schedulerStarted();
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of startup.",
                        e);
            }
        }
    }

    void notifySchedulerListenersStarting() {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for (SchedulerListener sl : schedListeners) {
            try {
                sl.schedulerStarting();
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of startup.",
                        e);
            }
        }
    }

    void notifySchedulerListenersShutdown() {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.schedulerShutdown();
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of shutdown.",
                        e);
            }
        }
    }
    
    void notifySchedulerListenersShuttingdown() {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.schedulerShuttingdown();
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of shutdown.",
                        e);
            }
        }
    }
    
    void notifySchedulerListenersJobAdded(JobDetail jobDetail) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.jobAdded(jobDetail);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of JobAdded.",
                        e);
            }
        }
    }

    void notifySchedulerListenersJobDeleted(JobKey jobKey) {
        // build a list of all scheduler listeners that are to be notified...
        List!(SchedulerListener) schedListeners = buildSchedulerListenerList();

        // notify all scheduler listeners
        for(SchedulerListener sl: schedListeners) {
            try {
                sl.jobDeleted(jobKey);
            } catch (Exception e) {
                getLog().error(
                        "Error while notifying SchedulerListener of JobAdded.",
                        e);
            }
        }
    }
    
    void setJobFactory(JobFactory factory) throws SchedulerException {

        if(factory is null) {
            throw new IllegalArgumentException("JobFactory cannot be set to null!");
        }

        getLog().info("JobFactory set to: " ~ factory);

        this.jobFactory = factory;
    }
    
    JobFactory getJobFactory()  {
        return jobFactory;
    }
    
    
    /**
     * Interrupt all instances of the identified InterruptableJob executing in 
     * this Scheduler instance.
     *  
     * <p>
     * This method is not cluster aware.  That is, it will only interrupt 
     * instances of the identified InterruptableJob currently executing in this 
     * Scheduler instance, not across the entire cluster.
     * </p>
     * 
     * @see hunt.quartz.core.RemotableQuartzScheduler#interrupt(JobKey)
     */
    bool interrupt(JobKey jobKey) throws UnableToInterruptJobException {

        List!(JobExecutionContext) jobs = getCurrentlyExecutingJobs();
        
        JobDetail jobDetail = null;
        Job job = null;
        
        bool interrupted = false;
        
        for(JobExecutionContext jec : jobs) {
            jobDetail = jec.getJobDetail();
            if (jobKey== jobDetail.getKey()) {
                job = jec.getJobInstance();
                if (job instanceof InterruptableJob) {
                    ((InterruptableJob)job).interrupt();
                    interrupted = true;
                } else {
                    throw new UnableToInterruptJobException(
                            "Job " ~ jobDetail.getKey() +
                            " can not be interrupted, since it does not implement " ~                        
                            InterruptableJob.class.getName());
                }
            }                        
        }
        
        return interrupted;
    }

    /**
     * Interrupt the identified InterruptableJob executing in this Scheduler instance.
     *  
     * <p>
     * This method is not cluster aware.  That is, it will only interrupt 
     * instances of the identified InterruptableJob currently executing in this 
     * Scheduler instance, not across the entire cluster.
     * </p>
     * 
     * @see hunt.quartz.core.RemotableQuartzScheduler#interrupt(JobKey)
     */
    bool interrupt(string fireInstanceId) throws UnableToInterruptJobException {
        List!(JobExecutionContext) jobs = getCurrentlyExecutingJobs();
        
        Job job = null;
        
        for(JobExecutionContext jec : jobs) {
            if (jec.getFireInstanceId()== fireInstanceId) {
                job = jec.getJobInstance();
                if (job instanceof InterruptableJob) {
                    ((InterruptableJob)job).interrupt();
                    return true;
                } else {
                    throw new UnableToInterruptJobException(
                        "Job " ~ jec.getJobDetail().getKey() +
                        " can not be interrupted, since it does not implement " ~                        
                        InterruptableJob.class.getName());
                }
            }                        
        }
        
        return false;
    }
    
    private void shutdownPlugins() {
        java.util.Iterator!(SchedulerPlugin) itr = resources.getSchedulerPlugins().iterator();
        while (itr.hasNext()) {
            SchedulerPlugin plugin = itr.next();
            plugin.shutdown();
        }
    }

    private void startPlugins() {
        java.util.Iterator!(SchedulerPlugin) itr = resources.getSchedulerPlugins().iterator();
        while (itr.hasNext()) {
            SchedulerPlugin plugin = itr.next();
            plugin.start();
        }
    }

}

/////////////////////////////////////////////////////////////////////////////
//
// ErrorLogger - Scheduler Listener Class
//
/////////////////////////////////////////////////////////////////////////////

class ErrorLogger : SchedulerListenerSupport {
    ErrorLogger() {
    }
    
    override
    void schedulerError(string msg, SchedulerException cause) {
        getLog().error(msg, cause);
    }

}

/////////////////////////////////////////////////////////////////////////////
//
// ExecutingJobsManager - Job Listener Class
//
/////////////////////////////////////////////////////////////////////////////

class ExecutingJobsManager implements JobListener {
    HashMap!(string, JobExecutionContext) executingJobs = new HashMap!(string, JobExecutionContext)();

    AtomicInteger numJobsFired = new AtomicInteger(0);

    ExecutingJobsManager() {
    }

    string getName() {
        return getClass().getName();
    }

    int getNumJobsCurrentlyExecuting() {
        synchronized (executingJobs) {
            return executingJobs.size();
        }
    }

    void jobToBeExecuted(JobExecutionContext context) {
        numJobsFired.incrementAndGet();

        synchronized (executingJobs) {
            executingJobs
                    .put(((OperableTrigger)context.getTrigger()).getFireInstanceId(), context);
        }
    }

    void jobWasExecuted(JobExecutionContext context,
            JobExecutionException jobException) {
        synchronized (executingJobs) {
            executingJobs.remove(((OperableTrigger)context.getTrigger()).getFireInstanceId());
        }
    }

    int getNumJobsFired() {
        return numJobsFired.get();
    }

    List!(JobExecutionContext) getExecutingJobs() {
        synchronized (executingJobs) {
            return java.container.Collections.unmodifiableList(new ArrayList!(JobExecutionContext)(
                    executingJobs.values()));
        }
    }

    void jobExecutionVetoed(JobExecutionContext context) {
        
    }
}
