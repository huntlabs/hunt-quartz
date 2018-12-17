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

module hunt.quartz.impl.QuartzServer;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import hunt.quartz.Scheduler;
import hunt.quartz.SchedulerException;
import hunt.quartz.SchedulerFactory;
import hunt.quartz.listeners.SchedulerListenerSupport;

/**
 * <p>
 * Instantiates an instance of Quartz Scheduler as a stand-alone program, if
 * the scheduler is configured for RMI it will be made available.
 * </p>
 *
 * <p>
 * The main() method of this class currently accepts 0 or 1 arguemtns, if there
 * is an argument, and its value is <code>"console"</code>, then the program
 * will print a short message on the console (std-out) and wait for the user to
 * type "exit" - at which time the scheduler will be shutdown.
 * </p>
 *
 * <p>
 * Future versions of this server should allow additional configuration for
 * responding to scheduler events by allowing the user to specify <code>{@link hunt.quartz.JobListener}</code>,
 * <code>{@link hunt.quartz.TriggerListener}</code> and <code>{@link hunt.quartz.SchedulerListener}</code>
 * classes.
 * </p>
 *
 * <p>
 * Please read the Quartz FAQ entries about RMI before asking questions in the
 * forums or mail-lists.
 * </p>
 *
 * @author James House
 */
class QuartzServer : SchedulerListenerSupport {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Data members.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private Scheduler sched = null;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Constructors.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    QuartzServer() {
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Interface.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    void serve(SchedulerFactory schedFact, bool console)
        throws Exception {
        sched = schedFact.getScheduler();

        sched.start();

        try {
            Thread.sleep(3000l);
        } catch (Exception ignore) {
        }

        System.out.println("\n*** The scheduler successfully started.");

        if (console) {
            System.out.println("\n");
            System.out
                    .println("The scheduler will now run until you type \"exit\"");
            System.out
                    .println("   If it was configured to export itself via RMI,");
            System.out.println("   then other process may now use it.");

            BufferedReader rdr = new BufferedReader(new InputStreamReader(
                    System.in));

            while (true) {
                System.out.print("Type 'exit' to shutdown the server: ");
                if ("exit"== rdr.readLine()) {
                    break;
                }
            }

            System.out.println("\n...Shutting down server...");

            sched.shutdown(true);
        }
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * SchedulerListener Interface.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Called by the <code>{@link Scheduler}</code> when a serious error has
     * occured within the scheduler - such as repeated failures in the <code>JobStore</code>,
     * or the inability to instantiate a <code>Job</code> instance when its
     * <code>Trigger</code> has fired.
     * </p>
     *
     * <p>
     * The <code>getErrorCode()</code> method of the given SchedulerException
     * can be used to determine more specific information about the type of
     * error that was encountered.
     * </p>
     */
    override
    void schedulerError(string msg, SchedulerException cause) {
        System.err.println("*** " ~ msg);
        cause.printStackTrace();
    }

    /**
     * <p>
     * Called by the <code>{@link Scheduler}</code> to inform the listener
     * that it has shutdown.
     * </p>
     */
    override
    void schedulerShutdown() {
        System.out.println("\n*** The scheduler is now shutdown.");
        sched = null;
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Main Method.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    static void main(string[] args) throws Exception {

        //    //Configure Log4J
        //    org.apache.log4j.PropertyConfigurator.configure(
        //      System.getProperty("log4jConfigFile", "log4j.properties"));

        if (System.getSecurityManager() is null) {
            System.setSecurityManager(new java.rmi.RMISecurityManager());
        }

        try {
            QuartzServer server = new QuartzServer();
            if (args.length == 0) {
                server.serve(
                    new hunt.quartz.impl.StdSchedulerFactory(), false);
            } else if (args.length == 1 && args[0].equalsIgnoreCase("console")) {
                server.serve(new hunt.quartz.impl.StdSchedulerFactory(), true);
            } else {
                System.err.println("\nUsage: QuartzServer [console]");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
