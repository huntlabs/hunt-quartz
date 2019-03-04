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

module hunt.quartz.impl.DirectSchedulerFactory;

import hunt.quartz.impl.DefaultThreadExecutor;

import hunt.quartz.Scheduler;
import hunt.quartz.exception;
import hunt.quartz.SchedulerFactory;
import hunt.quartz.core.JobRunShellFactory;
import hunt.quartz.core.QuartzScheduler;
import hunt.quartz.core.QuartzSchedulerResources;
import hunt.quartz.simpl.CascadingClassLoadHelper;
import hunt.quartz.simpl.RAMJobStore;
import hunt.quartz.simpl.SimpleThreadPool;
import hunt.quartz.spi.ClassLoadHelper;
import hunt.quartz.spi.JobStore;
import hunt.quartz.spi.SchedulerPlugin;
import hunt.quartz.spi.ThreadExecutor;
import hunt.quartz.spi.ThreadPool;

import hunt.collection.Collection;
import hunt.collection.Iterator;
import hunt.collection.Map;
import hunt.logging;


/**
 * <p>
 * A singleton implementation of <code>{@link hunt.quartz.SchedulerFactory}</code>.
 * </p>
 *
 * <p>
 * Here are some examples of using this class:
 * </p>
 * <p>
 * To create a scheduler that does not write anything to the database (is not
 * persistent), you can call <code>createVolatileScheduler</code>:
 *
 * <pre>
 *  DirectSchedulerFactory.getInstance().createVolatileScheduler(10); // 10 threads * // don't forget to start the scheduler: DirectSchedulerFactory.getInstance().getScheduler().start();
 * </pre>
 *
 *
 * <p>
 * Several create methods are provided for convenience. All create methods
 * eventually end up calling the create method with all the parameters:
 * </p>
 *
 * <pre>
 *  void createScheduler(string schedulerName, string schedulerInstanceId, ThreadPool threadPool, JobStore jobStore, string rmiRegistryHost, int rmiRegistryPort)
 * </pre>
 *
 *
 * <p>
 * Here is an example of using this method:
 * </p>
 *  *
 *  * <pre>// create the thread pool SimpleThreadPool threadPool = new SimpleThreadPool(maxThreads, Thread.NORM_PRIORITY); threadPool.initialize(); * // create the job store JobStore jobStore = new RAMJobStore();
 *
 *  DirectSchedulerFactory.getInstance().createScheduler("My Quartz Scheduler", "My Instance", threadPool, jobStore, "localhost", 1099); * // don't forget to start the scheduler: DirectSchedulerFactory.getInstance().getScheduler("My Quartz Scheduler", "My Instance").start();
 * </pre>
 *
 *
 * <p>
 * You can also use a JDBCJobStore instead of the RAMJobStore:
 * </p>
 *
 * <pre>
 *  DBConnectionManager.getInstance().addConnectionProvider("someDatasource", new JNDIConnectionProvider("someDatasourceJNDIName"));
 *
 *  JobStoreTX jdbcJobStore = new JobStoreTX(); jdbcJobStore.setDataSource("someDatasource"); jdbcJobStore.setPostgresStyleBlobs(true); jdbcJobStore.setTablePrefix("QRTZ_"); jdbcJobStore.setInstanceId("My Instance");
 * </pre>
 *
 * @author Mohammad Rezaei
 * @author James House
 *
 * @see JobStore
 * @see ThreadPool
 */
// class DirectSchedulerFactory : SchedulerFactory {

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      *
//      * Constants.
//      *
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */
//     enum string DEFAULT_INSTANCE_ID = "SIMPLE_NON_CLUSTERED";

//     enum string DEFAULT_SCHEDULER_NAME = "SimpleQuartzScheduler";

//     private enum bool DEFAULT_JMX_EXPORT = false;

//     private enum string DEFAULT_JMX_OBJECTNAME = null;

//     private enum int DEFAULT_BATCH_MAX_SIZE = 1;

//     private enum long DEFAULT_BATCH_TIME_WINDOW = 0L;

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      *
//      * Data members.
//      *
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     private bool initialized = false;

//     private __gshared DefaultThreadExecutor DEFAULT_THREAD_EXECUTOR;
//     private __gshared DirectSchedulerFactory instance;


//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      *
//      * Constructors.
//      *
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */
//     shared static this() {
//         DEFAULT_THREAD_EXECUTOR = new DefaultThreadExecutor();
//         instance = new DirectSchedulerFactory();
//     }


//     /**
//      * Constructor
//      */
//     protected this() {
//     }

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      *
//      * Interface.
//      *
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     static DirectSchedulerFactory getInstance() {
//         return instance;
//     }

//     /**
//      * Creates an in memory job store (<code>{@link RAMJobStore}</code>)
//      * The thread priority is set to Thread.NORM_PRIORITY
//      *
//      * @param maxThreads
//      *          The number of threads in the thread pool
//      * @throws SchedulerException
//      *           if initialization failed.
//      */
//     void createVolatileScheduler(int maxThreads) {
//         SimpleThreadPool threadPool = new SimpleThreadPool(maxThreads,
//                 Thread.NORM_PRIORITY);
//         threadPool.initialize();
//         JobStore jobStore = new RAMJobStore();
//         this.createScheduler(threadPool, jobStore);
//     }


//     /**
//      * Creates a proxy to a remote scheduler. This scheduler can be retrieved
//      * via {@link DirectSchedulerFactory#getScheduler()}
//      *
//      * @param rmiHost
//      *          The hostname for remote scheduler
//      * @param rmiPort
//      *          Port for the remote scheduler. The default RMI port is 1099.
//      * @throws SchedulerException
//      *           if the remote scheduler could not be reached.
//      */
//     void createRemoteScheduler(string rmiHost, int rmiPort) {
//         createRemoteScheduler(DEFAULT_SCHEDULER_NAME, DEFAULT_INSTANCE_ID,
//                 rmiHost, rmiPort);
//     }

//     /**
//      * Same as
//      * {@link DirectSchedulerFactory#createRemoteScheduler(string rmiHost, int rmiPort)},
//      * with the addition of specifying the scheduler name and instance ID. This
//      * scheduler can only be retrieved via
//      * {@link DirectSchedulerFactory#getScheduler(string)}
//      *
//      * @param schedulerName
//      *          The name for the scheduler.
//      * @param schedulerInstanceId
//      *          The instance ID for the scheduler.
//      * @param rmiHost
//      *          The hostname for remote scheduler
//      * @param rmiPort
//      *          Port for the remote scheduler. The default RMI port is 1099.
//      * @throws SchedulerException
//      *           if the remote scheduler could not be reached.
//      */
//     void createRemoteScheduler(string schedulerName,
//             string schedulerInstanceId, string rmiHost, int rmiPort) {
//         createRemoteScheduler(schedulerName,
//                 schedulerInstanceId, null, rmiHost, rmiPort);
//     }

//     /**
//      * Same as
//      * {@link DirectSchedulerFactory#createRemoteScheduler(string rmiHost, int rmiPort)},
//      * with the addition of specifying the scheduler name, instance ID, and rmi
//      * bind name. This scheduler can only be retrieved via
//      * {@link DirectSchedulerFactory#getScheduler(string)}
//      *
//      * @param schedulerName
//      *          The name for the scheduler.
//      * @param schedulerInstanceId
//      *          The instance ID for the scheduler.
//      * @param rmiBindName
//      *          The name of the remote scheduler in the RMI repository.  If null
//      *          defaults to the generated unique identifier.
//      * @param rmiHost
//      *          The hostname for remote scheduler
//      * @param rmiPort
//      *          Port for the remote scheduler. The default RMI port is 1099.
//      * @throws SchedulerException
//      *           if the remote scheduler could not be reached.
//      */
//     void createRemoteScheduler(string schedulerName,
//             string schedulerInstanceId, string rmiBindName, string rmiHost, int rmiPort) {

//         string uid = (rmiBindName !is null) ? rmiBindName :
//             QuartzSchedulerResources.getUniqueIdentifier(
//                 schedulerName, schedulerInstanceId);

//         RemoteScheduler remoteScheduler = new RemoteScheduler(uid, rmiHost, rmiPort);

//         SchedulerRepository schedRep = SchedulerRepository.getInstance();
//         schedRep.bind(remoteScheduler);
//         initialized = true;
//     }

//     /**
//      * Creates a scheduler using the specified thread pool and job store. This
//      * scheduler can be retrieved via
//      * {@link DirectSchedulerFactory#getScheduler()}
//      *
//      * @param threadPool
//      *          The thread pool for executing jobs
//      * @param jobStore
//      *          The type of job store
//      * @throws SchedulerException
//      *           if initialization failed
//      */
//     void createScheduler(ThreadPool threadPool, JobStore jobStore) {
//         createScheduler(DEFAULT_SCHEDULER_NAME, DEFAULT_INSTANCE_ID,
//                 threadPool, jobStore);
//     }

//     /**
//      * Same as
//      * {@link DirectSchedulerFactory#createScheduler(ThreadPool threadPool, JobStore jobStore)},
//      * with the addition of specifying the scheduler name and instance ID. This
//      * scheduler can only be retrieved via
//      * {@link DirectSchedulerFactory#getScheduler(string)}
//      *
//      * @param schedulerName
//      *          The name for the scheduler.
//      * @param schedulerInstanceId
//      *          The instance ID for the scheduler.
//      * @param threadPool
//      *          The thread pool for executing jobs
//      * @param jobStore
//      *          The type of job store
//      * @throws SchedulerException
//      *           if initialization failed
//      */
//     void createScheduler(string schedulerName,
//             string schedulerInstanceId, ThreadPool threadPool, JobStore jobStore) {
//         createScheduler(schedulerName, schedulerInstanceId, threadPool,
//                 jobStore, null, 0, -1, -1);
//     }

//     /**
//      * Creates a scheduler using the specified thread pool and job store and
//      * binds it to RMI.
//      *
//      * @param schedulerName
//      *          The name for the scheduler.
//      * @param schedulerInstanceId
//      *          The instance ID for the scheduler.
//      * @param threadPool
//      *          The thread pool for executing jobs
//      * @param jobStore
//      *          The type of job store
//      * @param rmiRegistryHost
//      *          The hostname to register this scheduler with for RMI. Can use
//      *          "null" if no RMI is required.
//      * @param rmiRegistryPort
//      *          The port for RMI. Typically 1099.
//      * @param idleWaitTime
//      *          The idle wait time in milliseconds. You can specify "-1" for
//      *          the default value, which is currently 30000 ms.
//      * @throws SchedulerException
//      *           if initialization failed
//      */
//     void createScheduler(string schedulerName,
//             string schedulerInstanceId, ThreadPool threadPool,
//             JobStore jobStore, string rmiRegistryHost, int rmiRegistryPort,
//             long idleWaitTime, long dbFailureRetryInterval) {
//         createScheduler(schedulerName,
//                 schedulerInstanceId, threadPool,
//                 jobStore, null, // plugins
//                 rmiRegistryHost, rmiRegistryPort,
//                 idleWaitTime, dbFailureRetryInterval,
//                 DEFAULT_JMX_EXPORT, DEFAULT_JMX_OBJECTNAME);
//     }

//     /**
//      * Creates a scheduler using the specified thread pool, job store, and
//      * plugins, and binds it to RMI.
//      *
//      * @param schedulerName
//      *          The name for the scheduler.
//      * @param schedulerInstanceId
//      *          The instance ID for the scheduler.
//      * @param threadPool
//      *          The thread pool for executing jobs
//      * @param jobStore
//      *          The type of job store
//      * @param schedulerPluginMap
//      *          Map from a <code>string</code> plugin names to
//      *          <code>{@link hunt.quartz.spi.SchedulerPlugin}</code>s.  Can use
//      *          "null" if no plugins are required.
//      * @param rmiRegistryHost
//      *          The hostname to register this scheduler with for RMI. Can use
//      *          "null" if no RMI is required.
//      * @param rmiRegistryPort
//      *          The port for RMI. Typically 1099.
//      * @param idleWaitTime
//      *          The idle wait time in milliseconds. You can specify "-1" for
//      *          the default value, which is currently 30000 ms.
//      * @throws SchedulerException
//      *           if initialization failed
//      */
//     void createScheduler(string schedulerName,
//             string schedulerInstanceId, ThreadPool threadPool,
//             JobStore jobStore, Map!(string, SchedulerPlugin) schedulerPluginMap,
//             string rmiRegistryHost, int rmiRegistryPort,
//             long idleWaitTime, long dbFailureRetryInterval,
//             bool jmxExport, string jmxObjectName) {
//         createScheduler(schedulerName, schedulerInstanceId, threadPool,
//                 DEFAULT_THREAD_EXECUTOR, jobStore, schedulerPluginMap,
//                 rmiRegistryHost, rmiRegistryPort, idleWaitTime,
//                 dbFailureRetryInterval, jmxExport, jmxObjectName);
//     }

//     /**
//      * Creates a scheduler using the specified thread pool, job store, and
//      * plugins, and binds it to RMI.
//      *
//      * @param schedulerName
//      *          The name for the scheduler.
//      * @param schedulerInstanceId
//      *          The instance ID for the scheduler.
//      * @param threadPool
//      *          The thread pool for executing jobs
//      * @param threadExecutor
//      *          The thread executor for executing jobs
//      * @param jobStore
//      *          The type of job store
//      * @param schedulerPluginMap
//      *          Map from a <code>string</code> plugin names to
//      *          <code>{@link hunt.quartz.spi.SchedulerPlugin}</code>s.  Can use
//      *          "null" if no plugins are required.
//      * @param rmiRegistryHost
//      *          The hostname to register this scheduler with for RMI. Can use
//      *          "null" if no RMI is required.
//      * @param rmiRegistryPort
//      *          The port for RMI. Typically 1099.
//      * @param idleWaitTime
//      *          The idle wait time in milliseconds. You can specify "-1" for
//      *          the default value, which is currently 30000 ms.
//      * @throws SchedulerException
//      *           if initialization failed
//      */
//     void createScheduler(string schedulerName,
//             string schedulerInstanceId, ThreadPool threadPool,
//             ThreadExecutor threadExecutor,
//             JobStore jobStore, Map!(string, SchedulerPlugin) schedulerPluginMap,
//             string rmiRegistryHost, int rmiRegistryPort,
//             long idleWaitTime, long dbFailureRetryInterval,
//             bool jmxExport, string jmxObjectName) {
//         createScheduler(schedulerName, schedulerInstanceId, threadPool,
//                 DEFAULT_THREAD_EXECUTOR, jobStore, schedulerPluginMap,
//                 rmiRegistryHost, rmiRegistryPort, idleWaitTime,
//                 dbFailureRetryInterval, jmxExport, jmxObjectName, DEFAULT_BATCH_MAX_SIZE, DEFAULT_BATCH_TIME_WINDOW);
//     }

//     /**
//      * Creates a scheduler using the specified thread pool, job store, and
//      * plugins, and binds it to RMI.
//      *
//      * @param schedulerName
//      *          The name for the scheduler.
//      * @param schedulerInstanceId
//      *          The instance ID for the scheduler.
//      * @param threadPool
//      *          The thread pool for executing jobs
//      * @param threadExecutor
//      *          The thread executor for executing jobs
//      * @param jobStore
//      *          The type of job store
//      * @param schedulerPluginMap
//      *          Map from a <code>string</code> plugin names to
//      *          <code>{@link hunt.quartz.spi.SchedulerPlugin}</code>s.  Can use
//      *          "null" if no plugins are required.
//      * @param rmiRegistryHost
//      *          The hostname to register this scheduler with for RMI. Can use
//      *          "null" if no RMI is required.
//      * @param rmiRegistryPort
//      *          The port for RMI. Typically 1099.
//      * @param idleWaitTime
//      *          The idle wait time in milliseconds. You can specify "-1" for
//      *          the default value, which is currently 30000 ms.
//      * @param maxBatchSize
//      *          The maximum batch size of triggers, when acquiring them
//      * @param batchTimeWindow
//      *          The time window for which it is allowed to "pre-acquire" triggers to fire
//      * @throws SchedulerException
//      *           if initialization failed
//      */
//     void createScheduler(string schedulerName,
//             string schedulerInstanceId, ThreadPool threadPool,
//             ThreadExecutor threadExecutor,
//             JobStore jobStore, Map!(string, SchedulerPlugin) schedulerPluginMap,
//             string rmiRegistryHost, int rmiRegistryPort,
//             long idleWaitTime, long dbFailureRetryInterval,
//             bool jmxExport, string jmxObjectName, int maxBatchSize, long batchTimeWindow) {
//         // Currently only one run-shell factory is available...
//         JobRunShellFactory jrsf = new StdJobRunShellFactory();

//         // Fire everything up
//         // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//         threadPool.initialize();
        
//         QuartzSchedulerResources qrs = new QuartzSchedulerResources();

//         qrs.setName(schedulerName);
//         qrs.setInstanceId(schedulerInstanceId);
//         SchedulerDetailsSetter.setDetails(threadPool, schedulerName, schedulerInstanceId);
//         qrs.setJobRunShellFactory(jrsf);
//         qrs.setThreadPool(threadPool);
//         qrs.setThreadExecutor(threadExecutor);
//         qrs.setJobStore(jobStore);
//         qrs.setMaxBatchSize(maxBatchSize);
//         qrs.setBatchTimeWindow(batchTimeWindow);
//         qrs.setRMIRegistryHost(rmiRegistryHost);
//         qrs.setRMIRegistryPort(rmiRegistryPort);
//         qrs.setJMXExport(jmxExport);
//         if (jmxObjectName !is null) {
//            qrs.setJMXObjectName(jmxObjectName);
//         }
        
//         // add plugins
//         if (schedulerPluginMap !is null) {
//             foreach(SchedulerPlugin sp; schedulerPluginMap.values())
//             {
//                 qrs.addSchedulerPlugin(pluginIter.next());
//             }
//         }

//         QuartzScheduler qs = new QuartzScheduler(qrs, idleWaitTime, dbFailureRetryInterval);

//         ClassLoadHelper cch = new CascadingClassLoadHelper();
//         cch.initialize();

//         SchedulerDetailsSetter.setDetails(jobStore, schedulerName, schedulerInstanceId);

//         jobStore.initialize(cch, qs.getSchedulerSignaler());

//         Scheduler scheduler = new StdScheduler(qs);

//         jrsf.initialize(scheduler);

//         qs.initialize();
        

//         // Initialize plugins now that we have a Scheduler instance.
//         if (schedulerPluginMap !is null) {
//             for (Iterator!(Entry!(string, SchedulerPlugin)) pluginEntryIter = schedulerPluginMap.entrySet().iterator(); pluginEntryIter.hasNext();) {
//                 Entry!(string, SchedulerPlugin) pluginEntry = pluginEntryIter.next();

//                 pluginEntry.getValue().initialize(pluginEntry.getKey(), scheduler, cch);
//             }
//         }

//         info("Quartz scheduler '" ~ scheduler.getSchedulerName());

//         info("Quartz scheduler version: " ~ qs.getVersion());

//         SchedulerRepository schedRep = SchedulerRepository.getInstance();

//         qs.addNoGCObject(schedRep); // prevents the repository from being
//         // garbage collected

//         schedRep.bind(scheduler);
        
//         initialized = true;
//     }

//     /*
//      * public void registerSchedulerForRmi(string schedulerName, string
//      * schedulerId, string registryHost, int registryPort) throws
//      * SchedulerException, RemoteException { QuartzScheduler scheduler =
//      * (QuartzScheduler) this.getScheduler(); scheduler.bind(registryHost,
//      * registryPort); }
//      */

//     /**
//      * <p>
//      * Returns a handle to the Scheduler produced by this factory.
//      * </p>
//      *
//      * <p>
//      * you must call createRemoteScheduler or createScheduler methods before
//      * calling getScheduler()
//      * </p>
//      */
//     Scheduler getScheduler() {
//         if (!initialized) {
//             throw new SchedulerException(
//                 "you must call createRemoteScheduler or createScheduler methods before calling getScheduler()");
//         }

//         return getScheduler(DEFAULT_SCHEDULER_NAME);
//     }

//     /**
//      * <p>
//      * Returns a handle to the Scheduler with the given name, if it exists.
//      * </p>
//      */
//     Scheduler getScheduler(string schedName) {
//         SchedulerRepository schedRep = SchedulerRepository.getInstance();

//         return schedRep.lookup(schedName);
//     }

//     /**
//      * <p>
//      * Returns a handle to all known Schedulers (made by any
//      * StdSchedulerFactory instance.).
//      * </p>
//      */
//     Collection!(Scheduler) getAllSchedulers() {
//         return SchedulerRepository.getInstance().lookupAll();
//     }

// }
