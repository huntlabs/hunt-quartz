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

module hunt.quartz.impl.StdSchedulerFactory;

import hunt.quartz.impl.matchers.EverythingMatcher;
import hunt.quartz.impl.DefaultThreadExecutor;
import hunt.quartz.impl.SchedulerDetailsSetter;
import hunt.quartz.impl.SchedulerRepository;
import hunt.quartz.impl.StdScheduler;

import hunt.quartz.JobListener;
import hunt.quartz.Scheduler;
import hunt.quartz.Exceptions;
import hunt.quartz.SchedulerFactory;
import hunt.quartz.TriggerListener;
import hunt.quartz.core.JobRunShellFactory;
import hunt.quartz.core.QuartzScheduler;
import hunt.quartz.core.QuartzSchedulerResources;
import hunt.quartz.ee.jta.JTAAnnotationAwareJobRunShellFactory;
// import hunt.quartz.ee.jta.JTAJobRunShellFactory;
// import hunt.quartz.ee.jta.UserTransactionHelper;
// import hunt.quartz.impl.jdbcjobstore.JobStoreSupport;
// import hunt.quartz.impl.jdbcjobstore.Semaphore;
// import hunt.quartz.impl.jdbcjobstore.TablePrefixAware;
import hunt.quartz.management.ManagementRESTServiceConfiguration;
import hunt.quartz.simpl.RAMJobStore;
import hunt.quartz.simpl.SimpleThreadPool;
import hunt.quartz.simpl.SimpleInstanceIdGenerator;
import hunt.quartz.spi.ClassLoadHelper;
import hunt.quartz.spi.InstanceIdGenerator;
import hunt.quartz.spi.JobFactory;
import hunt.quartz.spi.JobStore;
import hunt.quartz.spi.SchedulerPlugin;
import hunt.quartz.spi.ThreadExecutor;
import hunt.quartz.spi.ThreadPool;
// import hunt.quartz.utils.ConnectionProvider;
import hunt.quartz.dbstore.DBConnectionManager;
// import hunt.quartz.utils.JNDIConnectionProvider;
// import hunt.quartz.utils.PoolingConnectionProvider;
import hunt.quartz.utils.PropertiesParser;

import hunt.collection.Collection;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.Locale;
import hunt.util.ObjectUtils;
import hunt.util.Configuration;

import std.array;
import std.exception;
import std.file;
import std.format;
import std.path;
import std.process;
import std.string;
        

/**
 * <p>
 * An implementation of <code>{@link hunt.quartz.SchedulerFactory}</code> that
 * does all of its work of creating a <code>QuartzScheduler</code> instance
 * based on the contents of a <code>Properties</code> file.
 * </p>
 *
 * <p>
 * By default a properties file named "quartz.properties" is loaded from the
 * 'current working directory'. If that fails, then the "quartz.properties"
 * file located (as a resource) in the org/quartz package is loaded. If you
 * wish to use a file other than these defaults, you must define the system
 * property 'hunt.quartz.properties' to point to the file you want.
 * </p>
 *
 * <p>
 * Alternatively, you can explicitly initialize the factory by calling one of
 * the <code>initialize(xx)</code> methods before calling <code>getScheduler()</code>.
 * </p>
 *
 * <p>
 * See the sample properties files that are distributed with Quartz for
 * information about the various settings available within the file.
 * Full configuration documentation can be found at
 * http://www.quartz-scheduler.org/docs/index.html
 * </p>
 *
 * <p>
 * Instances of the specified <code>{@link hunt.quartz.spi.JobStore}</code>,
 * <code>{@link hunt.quartz.spi.ThreadPool}</code>, and other SPI classes will be created
 * by name, and then any additional properties specified for them in the config
 * file will be set on the instance by calling an equivalent 'set' method. For
 * example if the properties file contains the property
 * 'hunt.quartz.jobStore.myProp = 10' then after the JobStore class has been
 * instantiated, the method 'setMyProp()' will be called on it. Type conversion
 * to primitive Java types (int, long, float, double, bool, and string) are
 * performed before calling the property's setter method.
 * </p>
 * 
 * <p>
 * One property can reference another property's value by specifying a value
 * following the convention of "$@other.property.name", for example, to reference
 * the scheduler's instance name as the value for some other property, you
 * would use "$@hunt.quartz.scheduler.instanceName".
 * </p> 
 *
 * @author James House
 * @author Anthony Eden
 * @author Mohammad Rezaei
 */
class StdSchedulerFactory : SchedulerFactory {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Constants.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    enum string PROPERTIES_FILE = "hunt.quartz.properties";

    enum string PROP_SCHED_INSTANCE_NAME = "hunt.quartz.scheduler.instanceName";

    enum string PROP_SCHED_INSTANCE_ID = "hunt.quartz.scheduler.instanceId";

    enum string PROP_SCHED_INSTANCE_ID_GENERATOR_PREFIX = "hunt.quartz.scheduler.instanceIdGenerator";

    enum string PROP_SCHED_INSTANCE_ID_GENERATOR_CLASS =
        PROP_SCHED_INSTANCE_ID_GENERATOR_PREFIX ~ ".class";

    enum string PROP_SCHED_THREAD_NAME = "hunt.quartz.scheduler.threadName";

    enum string PROP_SCHED_BATCH_TIME_WINDOW = "hunt.quartz.scheduler.batchTriggerAcquisitionFireAheadTimeWindow";

    enum string PROP_SCHED_MAX_BATCH_SIZE = "hunt.quartz.scheduler.batchTriggerAcquisitionMaxCount";

    enum string PROP_SCHED_JMX_EXPORT = "hunt.quartz.scheduler.jmx.export";

    enum string PROP_SCHED_JMX_OBJECT_NAME = "hunt.quartz.scheduler.jmx.objectName";

    enum string PROP_SCHED_JMX_PROXY = "hunt.quartz.scheduler.jmx.proxy";

    enum string PROP_SCHED_JMX_PROXY_CLASS = "hunt.quartz.scheduler.jmx.proxy.class";
    
    enum string PROP_SCHED_RMI_EXPORT = "hunt.quartz.scheduler.rmi.export";

    enum string PROP_SCHED_RMI_PROXY = "hunt.quartz.scheduler.rmi.proxy";

    enum string PROP_SCHED_RMI_HOST = "hunt.quartz.scheduler.rmi.registryHost";

    enum string PROP_SCHED_RMI_PORT = "hunt.quartz.scheduler.rmi.registryPort";

    enum string PROP_SCHED_RMI_SERVER_PORT = "hunt.quartz.scheduler.rmi.serverPort";

    enum string PROP_SCHED_RMI_CREATE_REGISTRY = "hunt.quartz.scheduler.rmi.createRegistry";

    enum string PROP_SCHED_RMI_BIND_NAME = "hunt.quartz.scheduler.rmi.bindName";

    enum string PROP_SCHED_WRAP_JOB_IN_USER_TX = "hunt.quartz.scheduler.wrapJobExecutionInUserTransaction";

    enum string PROP_SCHED_USER_TX_URL = "hunt.quartz.scheduler.userTransactionURL";

    enum string PROP_SCHED_IDLE_WAIT_TIME = "hunt.quartz.scheduler.idleWaitTime";

    enum string PROP_SCHED_DB_FAILURE_RETRY_INTERVAL = "hunt.quartz.scheduler.dbFailureRetryInterval";

    enum string PROP_SCHED_MAKE_SCHEDULER_THREAD_DAEMON = "hunt.quartz.scheduler.makeSchedulerThreadDaemon";

    enum string PROP_SCHED_SCHEDULER_THREADS_INHERIT_CONTEXT_CLASS_LOADER_OF_INITIALIZING_THREAD = "hunt.quartz.scheduler.threadsInheritContextClassLoaderOfInitializer";

    enum string PROP_SCHED_CLASS_LOAD_HELPER_CLASS = "hunt.quartz.scheduler.classLoadHelper.class";

    enum string PROP_SCHED_JOB_FACTORY_CLASS = "hunt.quartz.scheduler.jobFactory.class";

    enum string PROP_SCHED_JOB_FACTORY_PREFIX = "hunt.quartz.scheduler.jobFactory";

    enum string PROP_SCHED_INTERRUPT_JOBS_ON_SHUTDOWN = "hunt.quartz.scheduler.interruptJobsOnShutdown";

    enum string PROP_SCHED_INTERRUPT_JOBS_ON_SHUTDOWN_WITH_WAIT = "hunt.quartz.scheduler.interruptJobsOnShutdownWithWait";

    enum string PROP_SCHED_CONTEXT_PREFIX = "hunt.quartz.context.key";

    enum string PROP_THREAD_POOL_PREFIX = "hunt.quartz.threadPool";

    enum string PROP_THREAD_POOL_CLASS = "hunt.quartz.threadPool.class";

    enum string PROP_JOB_STORE_PREFIX = "hunt.quartz.jobStore";

    enum string PROP_JOB_STORE_LOCK_HANDLER_PREFIX = PROP_JOB_STORE_PREFIX ~ ".lockHandler";

    enum string PROP_JOB_STORE_LOCK_HANDLER_CLASS = PROP_JOB_STORE_LOCK_HANDLER_PREFIX ~ ".class";

    enum string PROP_TABLE_PREFIX = "tablePrefix";

    enum string PROP_SCHED_NAME = "schedName";

    enum string PROP_JOB_STORE_CLASS = "hunt.quartz.jobStore.class";

    enum string PROP_JOB_STORE_USE_PROP = "hunt.quartz.jobStore.useProperties";

    enum string PROP_DATASOURCE_PREFIX = "hunt.quartz.dataSource";

    enum string PROP_CONNECTION_PROVIDER_CLASS = "connectionProvider.class";

//     /**
//      * @deprecated Replaced with {@link PoolingConnectionProvider#DB_DRIVER}
//      */
//     deprecated("")
//     enum string PROP_DATASOURCE_DRIVER = "driver";

//     /**
//      * @deprecated Replaced with {@link PoolingConnectionProvider#DB_URL}
//      */
//     deprecated("")
//     enum string PROP_DATASOURCE_URL = "URL";

//     /**
//      * @deprecated Replaced with {@link PoolingConnectionProvider#DB_USER}
//      */
//     deprecated("")
//     enum string PROP_DATASOURCE_USER = "user";

//     /**
//      * @deprecated Replaced with {@link PoolingConnectionProvider#DB_PASSWORD}
//      */
//     deprecated("")
//     enum string PROP_DATASOURCE_PASSWORD = "password";

//     /**
//      * @deprecated Replaced with {@link PoolingConnectionProvider#DB_MAX_CONNECTIONS}
//      */
//     deprecated("")
//     enum string PROP_DATASOURCE_MAX_CONNECTIONS = "maxConnections";

//     /**
//      * @deprecated Replaced with {@link PoolingConnectionProvider#DB_VALIDATION_QUERY}
//      */
//     deprecated("")
//     enum string PROP_DATASOURCE_VALIDATION_QUERY = "validationQuery";

    enum string PROP_DATASOURCE_JNDI_URL = "jndiURL";

    enum string PROP_DATASOURCE_JNDI_ALWAYS_LOOKUP = "jndiAlwaysLookup";

    enum string PROP_DATASOURCE_JNDI_INITIAL = "java.naming.factory.initial";

    enum string PROP_DATASOURCE_JNDI_PROVDER = "java.naming.provider.url";

    enum string PROP_DATASOURCE_JNDI_PRINCIPAL = "java.naming.security.principal";

    enum string PROP_DATASOURCE_JNDI_CREDENTIALS = "java.naming.security.credentials";

    enum string PROP_PLUGIN_PREFIX = "hunt.quartz.plugin";

    enum string PROP_PLUGIN_CLASS = "class";

    enum string PROP_JOB_LISTENER_PREFIX = "hunt.quartz.jobListener";

    enum string PROP_TRIGGER_LISTENER_PREFIX = "hunt.quartz.triggerListener";

    enum string PROP_LISTENER_CLASS = "class";

    enum string DEFAULT_INSTANCE_ID = "NON_CLUSTERED";

    enum string AUTO_GENERATE_INSTANCE_ID = "AUTO";

    enum string PROP_THREAD_EXECUTOR = "hunt.quartz.threadExecutor";

    enum string PROP_THREAD_EXECUTOR_CLASS = "hunt.quartz.threadExecutor.class";

    enum string SYSTEM_PROPERTY_AS_INSTANCE_ID = "SYS_PROP";
    
    enum string MANAGEMENT_REST_SERVICE_ENABLED = "hunt.quartz.managementRESTService.enabled";

    enum string MANAGEMENT_REST_SERVICE_HOST_PORT = "hunt.quartz.managementRESTService.bind";

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Data members.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private SchedulerException initException = null;

    private string propSrc = null;

    private PropertiesParser cfg;

    private Scheduler scheduler;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Constructors.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Create an uninitialized StdSchedulerFactory.
     */
    this() {
    }

    /**
     * Create a StdSchedulerFactory that has been initialized via
     * <code>{@link #initialize(Properties)}</code>.
     *
     * @see #initialize(Properties)
     */
    this(string[string] props) {
        initialize(props);
    }

    /**
     * Create a StdSchedulerFactory that has been initialized via
     * <code>{@link #initialize(string)}</code>.
     *
     * @see #initialize(string)
     */
    this(string fileName) {
        initialize(fileName);
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
     * Initialize the <code>{@link hunt.quartz.SchedulerFactory}</code> with
     * the contents of a <code>Properties</code> file and overriding System
     * properties.
     * </p>
     *
     * <p>
     * By default a properties file named "quartz.properties" is loaded from
     * the 'current working directory'. If that fails, then the
     * "quartz.properties" file located (as a resource) in the org/quartz
     * package is loaded. If you wish to use a file other than these defaults,
     * you must define the system property 'hunt.quartz.properties' to point to
     * the file you want.
     * </p>
     *
     * <p>
     * System properties (environment variables, and -D definitions on the
     * command-line when running the JVM) override any properties in the
     * loaded file.  For this reason, you may want to use a different initialize()
     * method if your application security policy prohibits access to
     * <code>{@link java.lang.System#getProperties()}</code>.
     * </p>
     */
    void initialize() {
        // short-circuit if already initialized
        if (cfg !is null) {
            return;
        }
        if (initException !is null) {
            throw initException;
        }

        string requestedFile = environment.get(PROPERTIES_FILE, "");
        string propFileName = requestedFile.empty ? "quartz.properties"
                : requestedFile;
        initialize(propFileName);

        // File propFile = new File(propFileName);

        // Properties props = new Properties();

        // InputStream in = null;

        // try {
        //     if (propFile.exists()) {
        //         try {
        //             if (requestedFile !is null) {
        //                 propSrc = "specified file: '" ~ requestedFile ~ "'";
        //             } else {
        //                 propSrc = "default file in current working dir: 'quartz.properties'";
        //             }

        //             in = new BufferedInputStream(new FileInputStream(propFileName));
        //             props.load(in);

        //         } catch (IOException ioe) {
        //             initException = new SchedulerException("Properties file: '"
        //                     + propFileName ~ "' could not be read.", ioe);
        //             throw initException;
        //         }
        //     } else if (requestedFile !is null) {
        //         in =
        //             Thread.getThis().getContextClassLoader().getResourceAsStream(requestedFile);

        //         if(in is null) {
        //             initException = new SchedulerException("Properties file: '"
        //                 + requestedFile ~ "' could not be found.");
        //             throw initException;
        //         }

        //         propSrc = "specified file: '" ~ requestedFile ~ "' in the class resource path.";

        //         in = new BufferedInputStream(in);
        //         try {
        //             props.load(in);
        //         } catch (IOException ioe) {
        //             initException = new SchedulerException("Properties file: '"
        //                     + requestedFile ~ "' could not be read.", ioe);
        //             throw initException;
        //         }

        //     } else {
        //         propSrc = "default resource file in Quartz package: 'quartz.properties'";

        //         ClassLoader cl = getClass().getClassLoader();
        //         if(cl is null)
        //             cl = findClassloader();
        //         if(cl is null)
        //             throw new SchedulerConfigException("Unable to find a class loader on the current thread or class.");

        //         in = cl.getResourceAsStream(
        //                 "quartz.properties");

        //         if (in is null) {
        //             in = cl.getResourceAsStream(
        //                     "/quartz.properties");
        //         }
        //         if (in is null) {
        //             in = cl.getResourceAsStream(
        //                     "org/quartz/quartz.properties");
        //         }
        //         if (in is null) {
        //             initException = new SchedulerException(
        //                     "Default quartz.properties not found in class path");
        //             throw initException;
        //         }
        //         try {
        //             props.load(in);
        //         } catch (IOException ioe) {
        //             initException = new SchedulerException(
        //                     "Resource properties file: 'org/quartz/quartz.properties' "
        //                             ~ "could not be read from the classpath.", ioe);
        //             throw initException;
        //         }
        //     }
        // } finally {
        //     if(in !is null) {
        //         try { in.close(); } catch(IOException ignore) { /* ignore */ }
        //     }
        // }

        // initialize(overrideWithSysProps(props));
    }

//     /**
//      * Add all System properties to the given <code>props</code>.  Will override
//      * any properties that already exist in the given <code>props</code>.
//      */
//     private Properties overrideWithSysProps(Properties props) {
//         Properties sysProps = null;
//         try {
//             sysProps = System.getProperties();
//         } catch (AccessControlException e) {
//             warning(
//                 "Skipping overriding quartz properties with System properties " ~
//                 "during initialization because of an AccessControlException.  " ~
//                 "This is likely due to not having read/write access for " ~
//                 "java.util.PropertyPermission as required by java.lang.System.getProperties().  " ~
//                 "To resolve this warning, either add this permission to your policy file or " ~
//                 "use a non-default version of initialize().",
//                 e);
//         }

//         if (sysProps !is null) {
//             props.putAll(sysProps);
//         }

//         return props;
//     }

    private string[string] loadConfig(string filename) {
        string[string] props; 
        import std.stdio;

        auto f = File(filename, "r");
        if (!f.isOpen())
            return null;
        scope (exit)
            f.close();

        int line = 1;
        while (!f.eof()) {
            scope (exit)
                line += 1;
            string str = f.readln();
            str = strip(str);
            if (str.length == 0)
                continue;
            if (str[0] == '#' || str[0] == ';')
                continue;
            auto len = str.length - 1;
            if (str[0] == '[' && str[len] == ']') {
                // skip section []
                continue;
            }

            str = stripInlineComment(str);
            auto site = str.indexOf("=");
            enforce!BadFormatException((site > 0),
                    format("Bad format in file %s, at line %d", filename, line));
            string key = str[0 .. site].strip;
            string value = str[site + 1 .. $].strip;
            // tracef("key=%s, value=%s", key, value);
            props[key] = value;
        }
        return props;
    }

    private static string stripInlineComment(string line) {
        ptrdiff_t index = indexOf(line, "# ");

        if (index == -1)
            return line;
        else
            return line[0 .. index];
    }

    /**
     * <p>
     * Initialize the <code>{@link hunt.quartz.SchedulerFactory}</code> with
     * the contents of the <code>Properties</code> file with the given
     * name.
     * </p>
     */
    void initialize(string filename) {
        // short-circuit if already initialized
        if (cfg !is null) {
            return;
        }

        if (initException !is null) {
            throw initException;
        }


        Properties props;
        string appRoot = dirName(thisExePath());
        string fullFileName = buildPath(appRoot, filename);

        try {
            props = loadConfig(fullFileName);
            
        } catch (Exception ioe) {
            warning(ioe.msg);
            initException = new SchedulerException("Properties file: '"
                    ~ filename ~ "' could not be read.", ioe);
            throw initException;
        }

        initialize(props);
    }


    /**
     * <p>
     * Initialize the <code>{@link hunt.quartz.SchedulerFactory}</code> with
     * the contents of the given <code>Properties</code> object.
     * </p>
     */
    void initialize(string[string] props) {
        if (propSrc is null) {
            propSrc = "an externally provided properties instance.";
        }

        this.cfg = new PropertiesParser(props);
    }

    private T createObject(T)(string fullClassName) {
        Object o = Object.factory(fullClassName);
        if(o is null) {
            string msg = format("Can't create a object from %s", fullClassName);
            warningf(msg);
            throw new Exception(msg);
        } else {
            return cast(T)o;
        }
    }

    private Scheduler instantiate() {
        if (cfg is null) {
            initialize();
        }

        if (initException !is null) {
            throw initException;
        }

        JobStore js = null;
        ThreadPool tp = null;
        QuartzScheduler qs = null;
        DBConnectionManager dbMgr = null;
        string instanceIdGeneratorClass = null;
        Properties tProps = null;
        string userTXLocation = null;
        bool wrapJobInTx = false;
        bool autoId = false;
        long idleWaitTime = -1;
        long dbFailureRetry = 15000L; // 15 secs
        string classLoadHelperClass;
        string jobFactoryClass;
        ThreadExecutor threadExecutor;


        SchedulerRepository schedRep = SchedulerRepository.getInstance();

        // Get Scheduler Properties
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        string schedName = cfg.getStringProperty(PROP_SCHED_INSTANCE_NAME,
                "QuartzScheduler");

        string threadName = cfg.getStringProperty(PROP_SCHED_THREAD_NAME,
                schedName ~ "_QuartzSchedulerThread");

        string schedInstId = cfg.getStringProperty(PROP_SCHED_INSTANCE_ID,
                DEFAULT_INSTANCE_ID);

        if (schedInstId== AUTO_GENERATE_INSTANCE_ID) {
            autoId = true;
            instanceIdGeneratorClass = cfg.getStringProperty(
                    PROP_SCHED_INSTANCE_ID_GENERATOR_CLASS,
                    "hunt.quartz.simpl.SimpleInstanceIdGenerator.SimpleInstanceIdGenerator");
        }
        else if (schedInstId== SYSTEM_PROPERTY_AS_INSTANCE_ID) {
            autoId = true;
            instanceIdGeneratorClass = 
                    "hunt.quartz.simpl.SystemPropertyInstanceIdGenerator.SystemPropertyInstanceIdGenerator";
        }

        userTXLocation = cfg.getStringProperty(PROP_SCHED_USER_TX_URL,
                userTXLocation);
        if (userTXLocation.empty()) {
            userTXLocation = null;
        }

        classLoadHelperClass = cfg.getStringProperty(
                PROP_SCHED_CLASS_LOAD_HELPER_CLASS,
                "hunt.quartz.simpl.CascadingClassLoadHelper.CascadingClassLoadHelper");
        wrapJobInTx = cfg.getBooleanProperty(PROP_SCHED_WRAP_JOB_IN_USER_TX,
                wrapJobInTx);

        jobFactoryClass = cfg.getStringProperty(
                PROP_SCHED_JOB_FACTORY_CLASS, null);

        idleWaitTime = cfg.getLongProperty(PROP_SCHED_IDLE_WAIT_TIME,
                idleWaitTime);
        if(idleWaitTime > -1 && idleWaitTime < 1000) {
            throw new SchedulerException("hunt.quartz.scheduler.idleWaitTime of less than 1000ms is not legal.");
        }
        
        dbFailureRetry = cfg.getLongProperty(PROP_SCHED_DB_FAILURE_RETRY_INTERVAL, dbFailureRetry);
        if (dbFailureRetry < 0) {
            throw new SchedulerException(PROP_SCHED_DB_FAILURE_RETRY_INTERVAL ~ " of less than 0 ms is not legal.");
        }

        bool makeSchedulerThreadDaemon =
            cfg.getBooleanProperty(PROP_SCHED_MAKE_SCHEDULER_THREAD_DAEMON);

        bool threadsInheritInitalizersClassLoader =
            cfg.getBooleanProperty(PROP_SCHED_SCHEDULER_THREADS_INHERIT_CONTEXT_CLASS_LOADER_OF_INITIALIZING_THREAD);

        long batchTimeWindow = cfg.getLongProperty(PROP_SCHED_BATCH_TIME_WINDOW, 0L);
        int maxBatchSize = cfg.getIntProperty(PROP_SCHED_MAX_BATCH_SIZE, 1);

        bool interruptJobsOnShutdown = cfg.getBooleanProperty(PROP_SCHED_INTERRUPT_JOBS_ON_SHUTDOWN, false);
        bool interruptJobsOnShutdownWithWait = cfg.getBooleanProperty(PROP_SCHED_INTERRUPT_JOBS_ON_SHUTDOWN_WITH_WAIT, false);

        bool jmxExport = cfg.getBooleanProperty(PROP_SCHED_JMX_EXPORT);
        string jmxObjectName = cfg.getStringProperty(PROP_SCHED_JMX_OBJECT_NAME);
        
        bool jmxProxy = cfg.getBooleanProperty(PROP_SCHED_JMX_PROXY);
        string jmxProxyClass = cfg.getStringProperty(PROP_SCHED_JMX_PROXY_CLASS);

        bool rmiExport = cfg.getBooleanProperty(PROP_SCHED_RMI_EXPORT, false);
        bool rmiProxy = cfg.getBooleanProperty(PROP_SCHED_RMI_PROXY, false);
        string rmiHost = cfg.getStringProperty(PROP_SCHED_RMI_HOST, "localhost");
        int rmiPort = cfg.getIntProperty(PROP_SCHED_RMI_PORT, 1099);
        int rmiServerPort = cfg.getIntProperty(PROP_SCHED_RMI_SERVER_PORT, -1);
        string rmiCreateRegistry = cfg.getStringProperty(
                PROP_SCHED_RMI_CREATE_REGISTRY,
                QuartzSchedulerResources.CREATE_REGISTRY_NEVER);
        string rmiBindName = cfg.getStringProperty(PROP_SCHED_RMI_BIND_NAME);

        if (jmxProxy && rmiProxy) {
            throw new SchedulerConfigException("Cannot proxy both RMI and JMX.");
        }
        
        bool managementRESTServiceEnabled = cfg.getBooleanProperty(MANAGEMENT_REST_SERVICE_ENABLED, false);
        string managementRESTServiceHostAndPort = cfg.getStringProperty(MANAGEMENT_REST_SERVICE_HOST_PORT, "0.0.0.0:9889");

        Properties schedCtxtProps = cfg.getPropertyGroup(PROP_SCHED_CONTEXT_PREFIX, true);

        // If Proxying to remote scheduler, short-circuit here...
        // ~~~~~~~~~~~~~~~~~~
        if (rmiProxy) {

            // if (autoId) {
            //     schedInstId = DEFAULT_INSTANCE_ID;
            // }

            // string uid = (rmiBindName is null) ? QuartzSchedulerResources.getUniqueIdentifier(
            //         schedName, schedInstId) : rmiBindName;

            // RemoteScheduler remoteScheduler = new RemoteScheduler(uid, rmiHost, rmiPort);

            // schedRep.bind(remoteScheduler);

            // return remoteScheduler;
            implementationMissing(false);
        }


        // Create class load helper
        // ClassLoadHelper loadHelper = null;
        // try {
        //     loadHelper = (ClassLoadHelper) loadClass(classLoadHelperClass)
        //             .newInstance();
        // } catch (Exception e) {
        //     throw new SchedulerConfigException(
        //             "Unable to instantiate class load helper class: "
        //                     ~ e.msg, e);
        // }
        // loadHelper.initialize();

        // If Proxying to remote JMX scheduler, short-circuit here...
        // ~~~~~~~~~~~~~~~~~~
        // if (jmxProxy) {
        //     if (autoId) {
        //         schedInstId = DEFAULT_INSTANCE_ID;
        //     }

        //     if (jmxProxyClass is null) {
        //         throw new SchedulerConfigException("No JMX Proxy Scheduler class provided");
        //     }

        //     RemoteMBeanScheduler jmxScheduler = null;
        //     try {
        //         jmxScheduler = (RemoteMBeanScheduler)loadHelper.loadClass(jmxProxyClass)
        //                 .newInstance();
        //     } catch (Exception e) {
        //         throw new SchedulerConfigException(
        //                 "Unable to instantiate RemoteMBeanScheduler class.", e);
        //     }

        //     if (jmxObjectName is null) {
        //         jmxObjectName = QuartzSchedulerResources.generateJMXObjectName(schedName, schedInstId);
        //     }

        //     jmxScheduler.setSchedulerObjectName(jmxObjectName);

        //     tProps = cfg.getPropertyGroup(PROP_SCHED_JMX_PROXY, true);
        //     try {
        //         setBeanProps(jmxScheduler, tProps);
        //     } catch (Exception e) {
        //         initException = new SchedulerException("RemoteMBeanScheduler class '"
        //                 + jmxProxyClass ~ "' props could not be configured.", e);
        //         throw initException;
        //     }

        //     jmxScheduler.initialize();

        //     schedRep.bind(jmxScheduler);

        //     return jmxScheduler;
        // }

        
        JobFactory jobFactory = null;
        if(!jobFactoryClass.empty()) {
            implementationMissing(false);
            
            // try {
            //     jobFactory = (JobFactory) loadHelper.loadClass(jobFactoryClass)
            //             .newInstance();
            // } catch (Exception e) {
            //     throw new SchedulerConfigException(
            //             "Unable to instantiate JobFactory class: "
            //                     ~ e.msg, e);
            // }

            // tProps = cfg.getPropertyGroup(PROP_SCHED_JOB_FACTORY_PREFIX, true);
            // try {
            //     setBeanProps(jobFactory, tProps);
            // } catch (Exception e) {
            //     initException = new SchedulerException("JobFactory class '"
            //             + jobFactoryClass ~ "' props could not be configured.", e);
            //     throw initException;
            // }
        }

        InstanceIdGenerator instanceIdGenerator = null;
        if(!instanceIdGeneratorClass.empty()) {
            try {
                instanceIdGenerator = createObject!InstanceIdGenerator(instanceIdGeneratorClass);
            } catch (Exception e) {
                throw new SchedulerConfigException(
                        "Unable to instantiate InstanceIdGenerator class", e);
            }

            tProps = cfg.getPropertyGroup(PROP_SCHED_INSTANCE_ID_GENERATOR_PREFIX, true);
            try {
                setBeanProps(instanceIdGenerator, tProps);
            } catch (Exception e) {
                initException = new SchedulerException("InstanceIdGenerator class '"
                        ~ instanceIdGeneratorClass ~ "' props could not be configured.", e);
                throw initException;
            }
        }

        // Get ThreadPool Properties
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        string tpClass = cfg.getStringProperty(PROP_THREAD_POOL_CLASS, typeid(SimpleThreadPool).name);

        if (tpClass.empty()) {
            initException = new SchedulerException("ThreadPool class not specified. ");
            throw initException;
        }

        try {
            tp = createObject!ThreadPool(tpClass);
        } catch (Exception e) {
            initException = new SchedulerException("ThreadPool class '"
                    ~ tpClass ~ "' could not be instantiated.", e);
            throw initException;
        }
        tProps = cfg.getPropertyGroup(PROP_THREAD_POOL_PREFIX, true);
        try {
            setBeanProps(tp, tProps);
        } catch (Exception e) {
            initException = new SchedulerException("ThreadPool class '"
                    ~ tpClass ~ "' props could not be configured.", e);
            throw initException;
        }

        // Get JobStore Properties
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        string jsClass = cfg.getStringProperty(PROP_JOB_STORE_CLASS,
                typeid(RAMJobStore).name);

        if (jsClass is null) {
            initException = new SchedulerException(
                    "JobStore class not specified. ");
            throw initException;
        }

        js = cast(JobStore)Object.factory(jsClass);
        if(js is null)  {
            initException = new SchedulerException("JobStore class '" ~ jsClass
                    ~ "' could not be instantiated.");
            throw initException;
        }

        SchedulerDetailsSetter.setDetails(js, schedName, schedInstId);

        // tProps = cfg.getPropertyGroup(PROP_JOB_STORE_PREFIX, true, [PROP_JOB_STORE_LOCK_HANDLER_PREFIX]);
        // try {
        //     setBeanProps(js, tProps);
        // } catch (Exception e) {
        //     initException = new SchedulerException("JobStore class '" ~ jsClass
        //             ~ "' props could not be configured.", e);
        //     throw initException;
        // }
        // JobStoreSupport jss = cast(JobStoreSupport)js;
        // if (jss !is null) {
        //     // Install custom lock handler (Semaphore)
        //     string lockHandlerClass = cfg.getStringProperty(PROP_JOB_STORE_LOCK_HANDLER_CLASS);
        //     if (!lockHandlerClass.empty()) {
        //         try {
        //             Semaphore lockHandler = cast(Semaphore)Object.factory(lockHandlerClass);

        //             tProps = cfg.getPropertyGroup(PROP_JOB_STORE_LOCK_HANDLER_PREFIX, true);

        //             // If this lock handler requires the table prefix, add it to its properties.
        //             if (lockHandler instanceof TablePrefixAware) {
        //                 tProps.setProperty(
        //                         PROP_TABLE_PREFIX, ((JobStoreSupport)js).getTablePrefix());
        //                 tProps.setProperty(
        //                         PROP_SCHED_NAME, schedName);
        //             }

        //             // try {
        //             //     setBeanProps(lockHandler, tProps);
        //             // } catch (Exception e) {
        //             //     initException = new SchedulerException("JobStore LockHandler class '" ~ lockHandlerClass
        //             //             ~ "' props could not be configured.", e);
        //             //     throw initException;
        //             // }

        //             ((JobStoreSupport)js).setLockHandler(lockHandler);
        //             info("Using custom data access locking (synchronization): " ~ lockHandlerClass);
        //         } catch (Exception e) {
        //             initException = new SchedulerException("JobStore LockHandler class '" ~ lockHandlerClass
        //                     ~ "' could not be instantiated.", e);
        //             throw initException;
        //         }
        //     }
        // }

        // Set up any DataSources
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        string[] dsNames = cfg.getPropertyGroups(PROP_DATASOURCE_PREFIX);
        for (size_t i = 0; i < dsNames.length; i++) {
            PropertiesParser pp = new PropertiesParser(cfg.getPropertyGroup(
                    PROP_DATASOURCE_PREFIX ~ "." ~ dsNames[i], true));

            string cpClass = pp.getStringProperty(PROP_CONNECTION_PROVIDER_CLASS, null);

            // custom connectionProvider...
            // if(!cpClass.empty()) {
            //     ConnectionProvider cp = null;
            //     try {
            //         cp = cast(ConnectionProvider)Object.factory(cpClass);
            //     } catch (Exception e) {
            //         initException = new SchedulerException("ConnectionProvider class '" ~ cpClass
            //                 ~ "' could not be instantiated.", e);
            //         throw initException;
            //     }

            //     try {
            //         // remove the class name, so it isn't attempted to be set
            //         pp.getUnderlyingProperties().remove(
            //                 PROP_CONNECTION_PROVIDER_CLASS);
            //         PoolingConnectionProvider pcp = cast(PoolingConnectionProvider)cp;
            //         if (pcp !is null) {
            //             populateProviderWithExtraProps(pcp, pp.getUnderlyingProperties());
            //         } else {
            //             // setBeanProps(cp, pp.getUnderlyingProperties());
            //         }
            //         cp.initialize();
            //     } catch (Exception e) {
            //         initException = new SchedulerException("ConnectionProvider class '" ~ cpClass
            //                 ~ "' props could not be configured.", e);
            //         throw initException;
            //     }

            //     dbMgr = DBConnectionManager.getInstance();
            //     dbMgr.addConnectionProvider(dsNames[i], cp);
            // } else {
            //     string dsJndi = pp.getStringProperty(PROP_DATASOURCE_JNDI_URL, null);

            //     if (dsJndi !is null) {
            //         bool dsAlwaysLookup = pp.getBooleanProperty(
            //                 PROP_DATASOURCE_JNDI_ALWAYS_LOOKUP);
            //         string dsJndiInitial = pp.getStringProperty(
            //                 PROP_DATASOURCE_JNDI_INITIAL);
            //         string dsJndiProvider = pp.getStringProperty(
            //                 PROP_DATASOURCE_JNDI_PROVDER);
            //         string dsJndiPrincipal = pp.getStringProperty(
            //                 PROP_DATASOURCE_JNDI_PRINCIPAL);
            //         string dsJndiCredentials = pp.getStringProperty(
            //                 PROP_DATASOURCE_JNDI_CREDENTIALS);
            //         Properties props = null;
            //         if (null != dsJndiInitial || null != dsJndiProvider
            //                 || null != dsJndiPrincipal || null != dsJndiCredentials) {
            //             props = new Properties();
            //             if (dsJndiInitial !is null) {
            //                 props.put(PROP_DATASOURCE_JNDI_INITIAL,
            //                         dsJndiInitial);
            //             }
            //             if (dsJndiProvider !is null) {
            //                 props.put(PROP_DATASOURCE_JNDI_PROVDER,
            //                         dsJndiProvider);
            //             }
            //             if (dsJndiPrincipal !is null) {
            //                 props.put(PROP_DATASOURCE_JNDI_PRINCIPAL,
            //                         dsJndiPrincipal);
            //             }
            //             if (dsJndiCredentials !is null) {
            //                 props.put(PROP_DATASOURCE_JNDI_CREDENTIALS,
            //                         dsJndiCredentials);
            //             }
            //         }
            //         JNDIConnectionProvider cp = new JNDIConnectionProvider(dsJndi,
            //                 props, dsAlwaysLookup);
            //         dbMgr = DBConnectionManager.getInstance();
            //         dbMgr.addConnectionProvider(dsNames[i], cp);
            //     } else {
            //         string poolingProvider = pp.getStringProperty(PoolingConnectionProvider.POOLING_PROVIDER);
            //         string dsDriver = pp.getStringProperty(PoolingConnectionProvider.DB_DRIVER);
            //         string dsURL = pp.getStringProperty(PoolingConnectionProvider.DB_URL);

            //         if (dsDriver is null) {
            //             initException = new SchedulerException(
            //                     "Driver not specified for DataSource: "
            //                             + dsNames[i]);
            //             throw initException;
            //         }
            //         if (dsURL is null) {
            //             initException = new SchedulerException(
            //                     "DB URL not specified for DataSource: "
            //                             + dsNames[i]);
            //             throw initException;
            //         }
            //         // we load even these "core" providers by class name in order to avoid a static dependency on
            //         // the c3p0 and hikaricp libraries
            //         if(poolingProvider !is null && poolingProvider== PoolingConnectionProvider.POOLING_PROVIDER_HIKARICP) {
            //             cpClass = "hunt.quartz.utils.HikariCpPoolingConnectionProvider";
            //         }
            //         else {
            //             cpClass = "hunt.quartz.utils.C3p0PoolingConnectionProvider";
            //         }
            //         info("Using ConnectionProvider class '" ~ cpClass ~ "' for data source '" ~ dsNames[i] ~ "'");

            //         try {
            //             ConnectionProvider cp = null;
            //             try {
            //                 Constructor constructor = loadHelper.loadClass(cpClass).getConstructor(Properties.class);
            //                 cp = (ConnectionProvider) constructor.newInstance(pp.getUnderlyingProperties());
            //             } catch (Exception e) {
            //                 initException = new SchedulerException("ConnectionProvider class '" ~ cpClass
            //                         ~ "' could not be instantiated.", e);
            //                 throw initException;
            //             }
            //             dbMgr = DBConnectionManager.getInstance();
            //             dbMgr.addConnectionProvider(dsNames[i], cp);

            //             // Populate the underlying C3P0/HikariCP data source pool properties
            //             populateProviderWithExtraProps((PoolingConnectionProvider)cp, pp.getUnderlyingProperties());
            //         } catch (Exception sqle) {
            //             initException = new SchedulerException(
            //                     "Could not initialize DataSource: " ~ dsNames[i],
            //                     sqle);
            //             throw initException;
            //         }
            //     }

            // }

        }

        // Set up any SchedulerPlugins
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        string[] pluginNames = cfg.getPropertyGroups(PROP_PLUGIN_PREFIX);
        SchedulerPlugin[] plugins = new SchedulerPlugin[pluginNames.length];
        for (size_t i = 0; i < pluginNames.length; i++) {
            Properties pp = cfg.getPropertyGroup(PROP_PLUGIN_PREFIX ~ "."
                    ~ pluginNames[i], true);

            string plugInClass = pp.get(PROP_PLUGIN_CLASS, null);

            // if (plugInClass is null) {
            //     initException = new SchedulerException(
            //             "SchedulerPlugin class not specified for plugin '"
            //                     ~ pluginNames[i] ~ "'");
            //     throw initException;
            // }
            // SchedulerPlugin plugin = null;
            // try {
            //     plugin = cast(SchedulerPlugin)Object.factory(plugInClass);
            // } catch (Exception e) {
            //     initException = new SchedulerException(
            //             "SchedulerPlugin class '" ~ plugInClass
            //                     ~ "' could not be instantiated.", e);
            //     throw initException;
            // }
            // try {
            //     setBeanProps(plugin, pp);
            // } catch (Exception e) {
            //     initException = new SchedulerException(
            //             "JobStore SchedulerPlugin '" ~ plugInClass
            //                     ~ "' props could not be configured.", e);
            //     throw initException;
            // }

            // plugins[i] = plugin;
        }

        // Set up any JobListeners
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        // TypeInfo_Class[] strArg = new Class[] { string.class };
        // string[] jobListenerNames = cfg.getPropertyGroups(PROP_JOB_LISTENER_PREFIX);
        // JobListener[] jobListeners = new JobListener[jobListenerNames.length];
        // for (int i = 0; i < jobListenerNames.length; i++) {
        //     Properties lp = cfg.getPropertyGroup(PROP_JOB_LISTENER_PREFIX ~ "."
        //             + jobListenerNames[i], true);

        //     string listenerClass = lp.getProperty(PROP_LISTENER_CLASS, null);

        //     if (listenerClass is null) {
        //         initException = new SchedulerException(
        //                 "JobListener class not specified for listener '"
        //                         + jobListenerNames[i] ~ "'");
        //         throw initException;
        //     }
        //     JobListener listener = null;
        //     try {
        //         listener = (JobListener)
        //                loadHelper.loadClass(listenerClass).newInstance();
        //     } catch (Exception e) {
        //         initException = new SchedulerException(
        //                 "JobListener class '" ~ listenerClass
        //                         ~ "' could not be instantiated.", e);
        //         throw initException;
        //     }
        //     try {
        //         Method nameSetter = null;
        //         try { 
        //             nameSetter = listener.getClass().getMethod("setName", strArg);
        //         }
        //         catch(NoSuchMethodException ignore) { 
        //             /* do nothing */ 
        //         }
        //         if(nameSetter !is null) {
        //             nameSetter.invoke(listener, new Object[] {jobListenerNames[i] } );
        //         }
        //         setBeanProps(listener, lp);
        //     } catch (Exception e) {
        //         initException = new SchedulerException(
        //                 "JobListener '" ~ listenerClass
        //                         ~ "' props could not be configured.", e);
        //         throw initException;
        //     }
        //     jobListeners[i] = listener;
        // }

        // Set up any TriggerListeners
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        string[] triggerListenerNames = cfg.getPropertyGroups(PROP_TRIGGER_LISTENER_PREFIX);
        TriggerListener[] triggerListeners = new TriggerListener[triggerListenerNames.length];
        for (size_t i = 0; i < triggerListenerNames.length; i++) {
            Properties lp = cfg.getPropertyGroup(PROP_TRIGGER_LISTENER_PREFIX ~ "."
                    ~ triggerListenerNames[i], true);

            string listenerClass = lp.get(PROP_LISTENER_CLASS, null);

            if (listenerClass.empty) {
                initException = new SchedulerException(
                        "TriggerListener class not specified for listener '"
                                ~ triggerListenerNames[i] ~ "'");
                throw initException;
            }
            // TriggerListener listener = null;
            // try {
            //     listener = cast(TriggerListener)
            //            loadHelper.loadClass(listenerClass).newInstance();
            // } catch (Exception e) {
            //     initException = new SchedulerException(
            //             "TriggerListener class '" ~ listenerClass
            //                     ~ "' could not be instantiated.", e);
            //     throw initException;
            // }
            // try {
            //     Method nameSetter = null;
            //     try { 
            //         nameSetter = listener.getClass().getMethod("setName", strArg);
            //     }
            //     catch(NoSuchMethodException ignore) { /* do nothing */ }
            //     if(nameSetter !is null) {
            //         nameSetter.invoke(listener, new Object[] {triggerListenerNames[i] } );
            //     }
            //     setBeanProps(listener, lp);
            // } catch (Exception e) {
            //     initException = new SchedulerException(
            //             "TriggerListener '" ~ listenerClass
            //                     ~ "' props could not be configured.", e);
            //     throw initException;
            // }
            // triggerListeners[i] = listener;
        }

        bool tpInited = false;
        bool qsInited = false;


        // Get ThreadExecutor Properties
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        string threadExecutorClass = cfg.getStringProperty(PROP_THREAD_EXECUTOR_CLASS);
        if (!threadExecutorClass.empty()) {
            tProps = cfg.getPropertyGroup(PROP_THREAD_EXECUTOR, true);
            try {
                threadExecutor = cast(ThreadExecutor)Object.factory(threadExecutorClass);
                trace("Using custom implementation for ThreadExecutor: " ~ threadExecutorClass);

                setBeanProps(threadExecutor, tProps);
            } catch (Exception e) {
                initException = new SchedulerException(
                        "ThreadExecutor class '" ~ threadExecutorClass ~ "' could not be instantiated.", e);
                throw initException;
            }
        } else {
            trace("Using default implementation for ThreadExecutor");
            threadExecutor = new DefaultThreadExecutor();
        }


        // Fire everything up
        // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        try {
                
    
            JobRunShellFactory jrsf = null; // Create correct run-shell factory...
    
            // if (userTXLocation !is null) {
            //     UserTransactionHelper.setUserTxLocation(userTXLocation);
            // }
    
            // if (wrapJobInTx) {
            //     jrsf = new JTAJobRunShellFactory();
            // } else {
                jrsf = new JTAAnnotationAwareJobRunShellFactory();
            // }
    
            if (autoId) {
                try {
                  schedInstId = DEFAULT_INSTANCE_ID;
                  if (js.isClustered()) {
                      schedInstId = instanceIdGenerator.generateInstanceId();
                  }
                } catch (Exception e) {
                    error("Couldn't generate instance Id!", e);
                    throw new IllegalStateException("Cannot run without an instance id.");
                }
            }

            string jsName = typeid(cast(Object)js).name;

            // if (jsName.startsWith("org.terracotta.quartz")) {
            //     try {
            //         string uuid = (string) js.getClass().getMethod("getUUID").invoke(js);
            //         if(schedInstId== DEFAULT_INSTANCE_ID) {
            //             schedInstId = "TERRACOTTA_CLUSTERED,node=" ~ uuid;
            //             if (jmxObjectName is null) {
            //                 jmxObjectName = QuartzSchedulerResources.generateJMXObjectName(schedName, schedInstId);
            //             }
            //         } else if(jmxObjectName is null) {
            //             jmxObjectName = QuartzSchedulerResources.generateJMXObjectName(schedName, schedInstId ~ ",node=" ~ uuid);
            //         }
            //     } catch(Exception e) {
            //         throw new RuntimeException("Problem obtaining node id from TerracottaJobStore.", e);
            //     }

            //     if(null == cfg.getStringProperty(PROP_SCHED_JMX_EXPORT)) {
            //         jmxExport = true;
            //     }
            // }
            
            // JobStoreSupport jjs = cast(JobStoreSupport)js;
            // if (jjs !is null) {
            //     jjs.setDbRetryInterval(dbFailureRetry);
            //     if(threadsInheritInitalizersClassLoader)
            //         jjs.setThreadsInheritInitializersClassLoadContext(threadsInheritInitalizersClassLoader);
                
            //     jjs.setThreadExecutor(threadExecutor);
            // }
    
            QuartzSchedulerResources rsrcs = new QuartzSchedulerResources();
            rsrcs.setName(schedName);
            rsrcs.setThreadName(threadName);
            rsrcs.setInstanceId(schedInstId);            
            rsrcs.setJobRunShellFactory(jrsf);
            rsrcs.setMakeSchedulerThreadDaemon(makeSchedulerThreadDaemon);
            rsrcs.setThreadsInheritInitializersClassLoadContext(threadsInheritInitalizersClassLoader);
            rsrcs.setBatchTimeWindow(batchTimeWindow);
            rsrcs.setMaxBatchSize(maxBatchSize);
            rsrcs.setInterruptJobsOnShutdown(interruptJobsOnShutdown);
            rsrcs.setInterruptJobsOnShutdownWithWait(interruptJobsOnShutdownWithWait);
            rsrcs.setJMXExport(jmxExport);
            rsrcs.setJMXObjectName(jmxObjectName);

            if (managementRESTServiceEnabled) {
                ManagementRESTServiceConfiguration managementRESTServiceConfiguration = new ManagementRESTServiceConfiguration();
                managementRESTServiceConfiguration.setBind(managementRESTServiceHostAndPort);
                managementRESTServiceConfiguration.setEnabled(managementRESTServiceEnabled);
                rsrcs.setManagementRESTServiceConfiguration(managementRESTServiceConfiguration);
            }
    
            if (rmiExport) {
                implementationMissing(false);
                // rsrcs.setRMIRegistryHost(rmiHost);
                // rsrcs.setRMIRegistryPort(rmiPort);
                // rsrcs.setRMIServerPort(rmiServerPort);
                // rsrcs.setRMICreateRegistryStrategy(rmiCreateRegistry);
                // rsrcs.setRMIBindName(rmiBindName);
            }
    
            SchedulerDetailsSetter.setDetails(tp, schedName, schedInstId);

            rsrcs.setThreadExecutor(threadExecutor);
            threadExecutor.initialize();

            rsrcs.setThreadPool(tp);
            SimpleThreadPool stp = cast(SimpleThreadPool)tp;
            if(stp !is null) {
                if(threadsInheritInitalizersClassLoader)
                    (cast(SimpleThreadPool)tp).setThreadsInheritContextClassLoaderOfInitializingThread(threadsInheritInitalizersClassLoader);
            }
            tp.initialize();
            tpInited = true;
    
            rsrcs.setJobStore(js);
    
            // add plugins
            for (size_t i = 0; i < plugins.length; i++) {
                rsrcs.addSchedulerPlugin(plugins[i]);
            }
    
            qs = new QuartzScheduler(rsrcs, idleWaitTime);
            qsInited = true;
    
            // Create Scheduler ref...
            Scheduler scheduler = instantiate(rsrcs, qs);
    
            // set job factory if specified
            if(jobFactory !is null) {
                qs.setJobFactory(jobFactory);
            }
    
            // Initialize plugins now that we have a Scheduler instance.
            for (size_t i = 0; i < plugins.length; i++) {
                plugins[i].initialize(pluginNames[i], scheduler);
            }
    
            // add listeners
            // for (size_t i = 0; i < jobListeners.length; i++) {
            //     qs.getListenerManager().addJobListener(jobListeners[i], EverythingMatcher.allJobs());
            // }

            // for (size_t i = 0; i < triggerListeners.length; i++) {
            //     qs.getListenerManager().addTriggerListener(triggerListeners[i], EverythingMatcher.allTriggers());
            // }
    
            // set scheduler context data...
            foreach(string key, string val; schedCtxtProps) {
                scheduler.getContext().put(key, val);
            }
    
            // fire up job store, and runshell factory
    
            js.setInstanceId(schedInstId);
            js.setInstanceName(schedName);
            js.setThreadPoolSize(tp.getPoolSize());
            js.initialize(qs.getSchedulerSignaler());

            if(jrsf !is null)
                jrsf.initialize(scheduler);
            
            qs.initialize();
    
            trace("Quartz scheduler '" ~ scheduler.getSchedulerName()
                            ~ "' initialized from " ~ propSrc);
    
            trace("Quartz scheduler version: " ~ qs.getVersion());
    
            // prevents the repository from being garbage collected
            qs.addNoGCObject(schedRep);
            // prevents the db manager from being garbage collected
            if (dbMgr !is null) {
                qs.addNoGCObject(dbMgr);
            }
    
            schedRep.bind(scheduler);
            return scheduler;
        }
        catch(SchedulerException e) {
            shutdownFromInstantiateException(tp, qs, tpInited, qsInited);
            throw e;
        }
        catch(RuntimeException re) {
            shutdownFromInstantiateException(tp, qs, tpInited, qsInited);
            throw re;
        }
        catch(Error re) {
            shutdownFromInstantiateException(tp, qs, tpInited, qsInited);
            throw re;
        }
    }

//     private void populateProviderWithExtraProps(PoolingConnectionProvider cp, Properties props) {
//         Properties copyProps = new Properties();
//         copyProps.putAll(props);

//         // Remove all the default properties first (they don't always match to setter name, and they are already
//         // been set!)
//         copyProps.remove(PoolingConnectionProvider.DB_DRIVER);
//         copyProps.remove(PoolingConnectionProvider.DB_URL);
//         copyProps.remove(PoolingConnectionProvider.DB_USER);
//         copyProps.remove(PoolingConnectionProvider.DB_PASSWORD);
//         copyProps.remove(PoolingConnectionProvider.DB_MAX_CONNECTIONS);
//         copyProps.remove(PoolingConnectionProvider.DB_VALIDATION_QUERY);
//         props.remove(PoolingConnectionProvider.POOLING_PROVIDER);
//         setBeanProps(cp.getDataSource(), copyProps);
//     }

    private void shutdownFromInstantiateException(ThreadPool tp, QuartzScheduler qs, bool tpInited, bool qsInited) {
        try {
            if(qsInited)
                qs.shutdown(false);
            else if(tpInited)
                tp.shutdown(false);
        } catch (Exception e) {
            error("Got another exception while shutting down after instantiation exception", e.msg);
        }
    }

    protected Scheduler instantiate(QuartzSchedulerResources rsrcs, QuartzScheduler qs) {
        Scheduler scheduler = new StdScheduler(qs);
        return scheduler;
    }

    private void setBeanProps(T)(T obj, Properties props) {
        props.remove("class");
        props.remove("provider");

        foreach(string key, string value; props) {
            // infof("key=%s, value=%s", key, value);
            setProperty(obj, key, value);
        }
    }


    // private void setBeanProps(Object obj, Properties props) IllegalAccessException,
    //         java.lang.reflect.InvocationTargetException,
    //         IntrospectionException, SchedulerConfigException {
    //     props.remove("class");
    //     props.remove(PoolingConnectionProvider.POOLING_PROVIDER);

    //     BeanInfo bi = Introspector.getBeanInfo(obj.getClass());
    //     PropertyDescriptor[] propDescs = bi.getPropertyDescriptors();
    //     PropertiesParser pp = new PropertiesParser(props);

    //     java.util.Enumeration!(Object) keys = props.keys();
    //     while (keys.hasMoreElements()) {
    //         string name = (string) keys.nextElement();
    //         string c = name.substring(0, 1).toUpperCase(Locale.US);
    //         string methName = "set" ~ c + name.substring(1);

    //         java.lang.reflect.Method setMeth = getSetMethod(methName, propDescs);

    //         try {
    //             if (setMeth is null) {
    //                 throw new NoSuchMethodException(
    //                         "No setter for property '" ~ name ~ "'");
    //             }

    //             TypeInfo_Class[] params = setMeth.getParameterTypes();
    //             if (params.length != 1) {
    //                 throw new NoSuchMethodException(
    //                     "No 1-argument setter for property '" ~ name ~ "'");
    //             }
                
    //             // does the property value reference another property's value? If so, swap to look at its value
    //             PropertiesParser refProps = pp;
    //             string refName = pp.getStringProperty(name);
    //             if(refName !is null && refName.startsWith("$@")) {
    //                 refName =  refName.substring(2);
    //                 refProps = cfg;
    //             }
    //             else
    //                 refName = name;
                
    //             if (params[0]== int.class) {
    //                 setMeth.invoke(obj, new Object[]{Integer.valueOf(refProps.getIntProperty(refName))});
    //             } else if (params[0]== long.class) {
    //                 setMeth.invoke(obj, new Object[]{Long.valueOf(refProps.getLongProperty(refName))});
    //             } else if (params[0]== float.class) {
    //                 setMeth.invoke(obj, new Object[]{Float.valueOf(refProps.getFloatProperty(refName))});
    //             } else if (params[0]== double.class) {
    //                 setMeth.invoke(obj, new Object[]{Double.valueOf(refProps.getDoubleProperty(refName))});
    //             } else if (params[0]== bool.class) {
    //                 setMeth.invoke(obj, new Object[]{Boolean.valueOf(refProps.getBooleanProperty(refName))});
    //             } else if (params[0]== string.class) {
    //                 setMeth.invoke(obj, new Object[]{refProps.getStringProperty(refName)});
    //             } else {
    //                 throw new NoSuchMethodException(
    //                         "No primitive-type setter for property '" ~ name
    //                                 ~ "'");
    //             }
    //         } catch (NumberFormatException nfe) {
    //             throw new SchedulerConfigException("Could not parse property '"
    //                     + name ~ "' into correct data type: " ~ nfe.toString());
    //         }
    //     }
    // }

    // private java.lang.reflect.Method getSetMethod(string name,
    //         PropertyDescriptor[] props) {
    //     for (int i = 0; i < props.length; i++) {
    //         java.lang.reflect.Method wMeth = props[i].getWriteMethod();

    //         if (wMeth !is null && wMeth.getName()== name) {
    //             return wMeth;
    //         }
    //     }

    //     return null;
    // }

    // private TypeInfo_Class loadClass(string className) {

    //     try {
    //         ClassLoader cl = findClassloader();
    //         if(cl !is null)
    //             return cl.loadClass(className);
    //         throw new SchedulerConfigException("Unable to find a class loader on the current thread or class.");
    //     } catch (ClassNotFoundException e) {
    //         if(getClass().getClassLoader() !is null)
    //             return getClass().getClassLoader().loadClass(className);
    //         throw e;
    //     }
    // }

    // private ClassLoader findClassloader() {
    //     // work-around set context loader for windows-service started jvms (QUARTZ-748)
    //     if(Thread.getThis().getContextClassLoader() is null && getClass().getClassLoader() !is null) {
    //         Thread.getThis().setContextClassLoader(getClass().getClassLoader());
    //     }
    //     return Thread.getThis().getContextClassLoader();
    // }

    private string getSchedulerName() {
        return cfg.getStringProperty(PROP_SCHED_INSTANCE_NAME,
                "QuartzScheduler");
    }

    /**
     * <p>
     * Returns a handle to the Scheduler produced by this factory.
     * </p>
     *
     * <p>
     * If one of the <code>initialize</code> methods has not be previously
     * called, then the default (no-arg) <code>initialize()</code> method
     * will be called by this method.
     * </p>
     */
    Scheduler getScheduler() {
        if (cfg is null) {
            initialize();
        }

        SchedulerRepository schedRep = SchedulerRepository.getInstance();

        Scheduler sched = schedRep.lookup(getSchedulerName());

        if (sched !is null) {
            if (sched.isShutdown()) {
                schedRep.remove(getSchedulerName());
            } else {
                return sched;
            }
        }

        sched = instantiate();

        return sched;
    }

    /**
     * <p>
     * Returns a handle to the default Scheduler, creating it if it does not
     * yet exist.
     * </p>
     *
     * @see #initialize()
     */
    static Scheduler getDefaultScheduler() {
        StdSchedulerFactory fact = new StdSchedulerFactory();

        return fact.getScheduler();
    }

    /**
     * <p>
     * Returns a handle to the Scheduler with the given name, if it exists (if
     * it has already been instantiated).
     * </p>
     */
    Scheduler getScheduler(string schedName) {
        return SchedulerRepository.getInstance().lookup(schedName);
    }

    /**
     * <p>
     * Returns a handle to all known Schedulers (made by any
     * StdSchedulerFactory instance.).
     * </p>
     */
    Scheduler[] getAllSchedulers() {
        return SchedulerRepository.getInstance().lookupAll();
    }
}
