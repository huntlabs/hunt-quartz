
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

module hunt.quartz.core.QuartzSchedulerResources;

import java.util.ArrayList;
import java.util.List;

import hunt.quartz.management.ManagementRESTServiceConfiguration;
import hunt.quartz.spi.JobStore;
import hunt.quartz.spi.SchedulerPlugin;
import hunt.quartz.spi.ThreadExecutor;
import hunt.quartz.spi.ThreadPool;

/**
 * <p>
 * Contains all of the resources (<code>JobStore</code>,<code>ThreadPool</code>,
 * etc.) necessary to create a <code>{@link QuartzScheduler}</code> instance.
 * </p>
 * 
 * @see QuartzScheduler
 * 
 * @author James House
 */
class QuartzSchedulerResources {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    enum string CREATE_REGISTRY_NEVER = "never";

    enum string CREATE_REGISTRY_ALWAYS = "always";

    enum string CREATE_REGISTRY_AS_NEEDED = "as_needed";

    private string name;

    private string instanceId;

    private string threadName;
    
    private string rmiRegistryHost = null;

    private int rmiRegistryPort = 1099;

    private int rmiServerPort = -1;

    private string rmiCreateRegistryStrategy = CREATE_REGISTRY_NEVER;

    private ThreadPool threadPool;

    private JobStore jobStore;

    private JobRunShellFactory jobRunShellFactory;

    private List!(SchedulerPlugin) schedulerPlugins = new ArrayList!(SchedulerPlugin)(10);
    
    private bool makeSchedulerThreadDaemon = false;

    private bool threadsInheritInitializersClassLoadContext = false;

    private string rmiBindName;
    
    private bool jmxExport;
    
    private string jmxObjectName;

    private ManagementRESTServiceConfiguration managementRESTServiceConfiguration;

    private ThreadExecutor threadExecutor;

    private long batchTimeWindow = 0;

    private int maxBatchSize = 1;

    private bool interruptJobsOnShutdown = false;
    private bool interruptJobsOnShutdownWithWait = false;
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create an instance with no properties initialized.
     * </p>
     */
    QuartzSchedulerResources() {
        // do nothing...
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
     * Get the name for the <code>{@link QuartzScheduler}</code>.
     * </p>
     */
    string getName() {
        return name;
    }

    /**
     * <p>
     * Set the name for the <code>{@link QuartzScheduler}</code>.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty.
     */
    void setName(string name) {
        if (name is null || name.trim().length() == 0) {
            throw new IllegalArgumentException(
                    "Scheduler name cannot be empty.");
        }

        this.name = name;
        
        if (threadName is null) {
            // thread name not already set, use default thread name
            setThreadName(name ~ "_QuartzSchedulerThread");
        }        
    }

    /**
     * <p>
     * Get the instance Id for the <code>{@link QuartzScheduler}</code>.
     * </p>
     */
    string getInstanceId() {
        return instanceId;
    }

    /**
     * <p>
     * Set the name for the <code>{@link QuartzScheduler}</code>.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty.
     */
    void setInstanceId(string instanceId) {
        if (instanceId is null || instanceId.trim().length() == 0) {
            throw new IllegalArgumentException(
                    "Scheduler instanceId cannot be empty.");
        }

        this.instanceId = instanceId;
    }

    static string getUniqueIdentifier(string schedName,
            string schedInstId) {
        return schedName ~ "_$_" ~ schedInstId;
    }

    string getUniqueIdentifier() {
        return getUniqueIdentifier(name, instanceId);
    }

    /**
     * <p>
     * Get the host name of the RMI Registry that the scheduler should export
     * itself to.
     * </p>
     */
    string getRMIRegistryHost() {
        return rmiRegistryHost;
    }

    /**
     * <p>
     * Set the host name of the RMI Registry that the scheduler should export
     * itself to.
     * </p>
     */
    void setRMIRegistryHost(string hostName) {
        this.rmiRegistryHost = hostName;
    }

    /**
     * <p>
     * Get the port number of the RMI Registry that the scheduler should export
     * itself to.
     * </p>
     */
    int getRMIRegistryPort() {
        return rmiRegistryPort;
    }

    /**
     * <p>
     * Set the port number of the RMI Registry that the scheduler should export
     * itself to.
     * </p>
     */
    void setRMIRegistryPort(int port) {
        this.rmiRegistryPort = port;
    }


    /**
     * <p>
     * Get the port number the scheduler server will be bound to.
     * </p>
     */
    int getRMIServerPort() {
        return rmiServerPort;
    }

    /**
     * <p>
     * Set the port number the scheduler server will be bound to.
     * </p>
     */
    void setRMIServerPort(int port) {
        this.rmiServerPort = port;
    }
    
    /**
     * <p>
     * Get the setting of whether or not Quartz should create an RMI Registry,
     * and if so, how.
     * </p>
     */
    string getRMICreateRegistryStrategy() {
        return rmiCreateRegistryStrategy;
    }

    /**
     * <p>
     * Get the name for the <code>{@link QuartzSchedulerThread}</code>.
     * </p>
     */
    string getThreadName() {
        return threadName;
    }

    /**
     * <p>
     * Set the name for the <code>{@link QuartzSchedulerThread}</code>.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty.
     */
    void setThreadName(string threadName) {
        if (threadName is null || threadName.trim().length() == 0) {
            throw new IllegalArgumentException(
                    "Scheduler thread name cannot be empty.");
        }

        this.threadName = threadName;
    }    
    
    /**
     * <p>
     * Set whether or not Quartz should create an RMI Registry, and if so, how.
     * </p>
     * 
     * @see #CREATE_REGISTRY_ALWAYS
     * @see #CREATE_REGISTRY_AS_NEEDED
     * @see #CREATE_REGISTRY_NEVER
     */
    void setRMICreateRegistryStrategy(string rmiCreateRegistryStrategy) {
        if (rmiCreateRegistryStrategy is null
                || rmiCreateRegistryStrategy.trim().length() == 0) {
            rmiCreateRegistryStrategy = CREATE_REGISTRY_NEVER;
        } else if (rmiCreateRegistryStrategy.equalsIgnoreCase("true")) {
            rmiCreateRegistryStrategy = CREATE_REGISTRY_AS_NEEDED;
        } else if (rmiCreateRegistryStrategy.equalsIgnoreCase("false")) {
            rmiCreateRegistryStrategy = CREATE_REGISTRY_NEVER;
        } else if (rmiCreateRegistryStrategy.equalsIgnoreCase(CREATE_REGISTRY_ALWAYS)) {
            rmiCreateRegistryStrategy = CREATE_REGISTRY_ALWAYS;
        } else if (rmiCreateRegistryStrategy.equalsIgnoreCase(CREATE_REGISTRY_AS_NEEDED)) {
            rmiCreateRegistryStrategy = CREATE_REGISTRY_AS_NEEDED;
        } else if (rmiCreateRegistryStrategy.equalsIgnoreCase(CREATE_REGISTRY_NEVER)) {
            rmiCreateRegistryStrategy = CREATE_REGISTRY_NEVER;
        } else {
            throw new IllegalArgumentException(
                    "Faild to set RMICreateRegistryStrategy - strategy unknown: '"
                            + rmiCreateRegistryStrategy ~ "'");
        }

        this.rmiCreateRegistryStrategy = rmiCreateRegistryStrategy;
    }

    /**
     * <p>
     * Get the <code>{@link ThreadPool}</code> for the <code>{@link QuartzScheduler}</code>
     * to use.
     * </p>
     */
    ThreadPool getThreadPool() {
        return threadPool;
    }

    /**
     * <p>
     * Set the <code>{@link ThreadPool}</code> for the <code>{@link QuartzScheduler}</code>
     * to use.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if threadPool is null.
     */
    void setThreadPool(ThreadPool threadPool) {
        if (threadPool is null) {
            throw new IllegalArgumentException("ThreadPool cannot be null.");
        }

        this.threadPool = threadPool;
    }

    /**
     * <p>
     * Get the <code>{@link JobStore}</code> for the <code>{@link QuartzScheduler}</code>
     * to use.
     * </p>
     */
    JobStore getJobStore() {
        return jobStore;
    }

    /**
     * <p>
     * Set the <code>{@link JobStore}</code> for the <code>{@link QuartzScheduler}</code>
     * to use.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if jobStore is null.
     */
    void setJobStore(JobStore jobStore) {
        if (jobStore is null) {
            throw new IllegalArgumentException("JobStore cannot be null.");
        }

        this.jobStore = jobStore;
    }

    /**
     * <p>
     * Get the <code>{@link JobRunShellFactory}</code> for the <code>{@link QuartzScheduler}</code>
     * to use.
     * </p>
     */
    JobRunShellFactory getJobRunShellFactory() {
        return jobRunShellFactory;
    }

    /**
     * <p>
     * Set the <code>{@link JobRunShellFactory}</code> for the <code>{@link QuartzScheduler}</code>
     * to use.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if jobRunShellFactory is null.
     */
    void setJobRunShellFactory(JobRunShellFactory jobRunShellFactory) {
        if (jobRunShellFactory is null) {
            throw new IllegalArgumentException(
                    "JobRunShellFactory cannot be null.");
        }

        this.jobRunShellFactory = jobRunShellFactory;
    }

    /**
     * <p>
     * Add the given <code>{@link hunt.quartz.spi.SchedulerPlugin}</code> for the 
     * <code>{@link QuartzScheduler}</code> to use. This method expects the plugin's
     * "initialize" method to be invoked externally (either before or after
     * this method is called).
     * </p>
     */
    void addSchedulerPlugin(SchedulerPlugin plugin) {
        schedulerPlugins.add(plugin);
    }
    
    /**
     * <p>
     * Get the <code>List</code> of all 
     * <code>{@link hunt.quartz.spi.SchedulerPlugin}</code>s for the 
     * <code>{@link QuartzScheduler}</code> to use.
     * </p>
     */
    List!(SchedulerPlugin) getSchedulerPlugins() {
        return schedulerPlugins;
    }

    /**
     * Get whether to mark the Quartz scheduling thread as daemon.
     * 
     * @see Thread#setDaemon(bool)
     */
    bool getMakeSchedulerThreadDaemon() {
        return makeSchedulerThreadDaemon;
    }

    /**
     * Set whether to mark the Quartz scheduling thread as daemon.
     * 
     * @see Thread#setDaemon(bool)
     */
    void setMakeSchedulerThreadDaemon(bool makeSchedulerThreadDaemon) {
        this.makeSchedulerThreadDaemon = makeSchedulerThreadDaemon;
    }

    /**
     * Get whether to set the class load context of spawned threads to that
     * of the initializing thread.
     */
    bool isThreadsInheritInitializersClassLoadContext() {
        return threadsInheritInitializersClassLoadContext;
    }

    /**
     * Set whether to set the class load context of spawned threads to that
     * of the initializing thread.
     */
    void setThreadsInheritInitializersClassLoadContext(
            bool threadsInheritInitializersClassLoadContext) {
        this.threadsInheritInitializersClassLoadContext = threadsInheritInitializersClassLoadContext;
    }

    /**
     * Get the name under which to bind the QuartzScheduler in RMI.  Will 
     * return the value of the uniqueIdentifier property if explict RMI bind 
     * name was never set.
     * 
     * @see #getUniqueIdentifier()
     */
    string getRMIBindName() {
        return (rmiBindName is null) ? getUniqueIdentifier() : rmiBindName;
    }

    /**
     * Set the name under which to bind the QuartzScheduler in RMI.  If unset, 
     * defaults to the value of the uniqueIdentifier property.
     * 
     * @see #getUniqueIdentifier()
     */
    void setRMIBindName(string rmiBindName) {
        this.rmiBindName = rmiBindName;
    }

    /**
     * Get whether the QuartzScheduler should be registered with the local 
     * MBeanServer.
     */
    bool getJMXExport() {
        return jmxExport;
    }

    /**
     * Set whether the QuartzScheduler should be registered with the local 
     * MBeanServer.
     */
    void setJMXExport(bool jmxExport) {
        this.jmxExport = jmxExport;
    }

    /**
     * Get the name under which the QuartzScheduler should be registered with 
     * the local MBeanServer.  If unset, defaults to the value calculated by 
     * <code>generateJMXObjectName!(code).
     * 
     * @see #generateJMXObjectName(string, string)
     */
    string getJMXObjectName() {
        return (jmxObjectName is null) ? generateJMXObjectName(name, instanceId) : jmxObjectName;
    }

    /**
     * Set the name under which the QuartzScheduler should be registered with 
     * the local MBeanServer.  If unset, defaults to the value calculated by 
     * <code>generateJMXObjectName!(code).
     * 
     * @see #generateJMXObjectName(string, string)
     */
    void setJMXObjectName(string jmxObjectName) {
        this.jmxObjectName = jmxObjectName;
    }

    /**
     * Get the ThreadExecutor which runs the QuartzSchedulerThread
     */
    ThreadExecutor getThreadExecutor() {
        return threadExecutor;
    }

    /**
     * Set the ThreadExecutor which runs the QuartzSchedulerThread
     */
    void setThreadExecutor(ThreadExecutor threadExecutor) {
        this.threadExecutor = threadExecutor;
    }

    /**
     * Create the name under which this scheduler should be registered in JMX.
     * <p>
     * The name is composed as:
     * quartz:type=QuartzScheduler,name=<i>[schedName]</i>,instance=<i>[schedInstId]</i>
     * </p>
     */
    static string generateJMXObjectName(string schedName, string schedInstId) {
        return "quartz:type=QuartzScheduler" ~ ",name="
            + schedName.replaceAll(":|=|\n", ".")
            ~ ",instance=" ~ schedInstId;
    }

    long getBatchTimeWindow() {
        return batchTimeWindow;
    }

    void setBatchTimeWindow(long batchTimeWindow) {
        this.batchTimeWindow = batchTimeWindow;
    }

    int getMaxBatchSize() {
      return maxBatchSize;
    }

    void setMaxBatchSize(int maxBatchSize) {
      this.maxBatchSize = maxBatchSize;
    }
    
    bool isInterruptJobsOnShutdown() {
        return interruptJobsOnShutdown;
    }

    void setInterruptJobsOnShutdown(bool interruptJobsOnShutdown) {
        this.interruptJobsOnShutdown = interruptJobsOnShutdown;
    }
    
    bool isInterruptJobsOnShutdownWithWait() {
        return interruptJobsOnShutdownWithWait;
    }

    void setInterruptJobsOnShutdownWithWait(
            bool interruptJobsOnShutdownWithWait) {
        this.interruptJobsOnShutdownWithWait = interruptJobsOnShutdownWithWait;
    }


    ManagementRESTServiceConfiguration getManagementRESTServiceConfiguration() {
        return managementRESTServiceConfiguration;
    }

    void setManagementRESTServiceConfiguration(ManagementRESTServiceConfiguration managementRESTServiceConfiguration) {
        this.managementRESTServiceConfiguration = managementRESTServiceConfiguration;
    }

}
