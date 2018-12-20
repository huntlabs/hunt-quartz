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

module hunt.quartz.jobs.NativeJob;

// import java.io.BufferedReader;
// import java.io.IOException;
// import hunt.io.common;
// import java.io.InputStreamReader;

// import hunt.logging;

// import hunt.quartz.Job;
// import hunt.quartz.JobDataMap;
// import hunt.quartz.JobExecutionContext;
// import hunt.quartz.exception;

// /**
//  * <p> Built in job for executing native executables in a separate process.</p> 
//  * 
//  * <pre>
//  *             JobDetail job = new JobDetail("dumbJob", null, hunt.quartz.jobs.NativeJob.class);
//  *             job.getJobDataMap().put(hunt.quartz.jobs.NativeJob.PROP_COMMAND, "echo \"hi\" >> foobar.txt");
//  *             Trigger trigger = TriggerUtils.makeSecondlyTrigger(5);
//  *             trigger.setName("dumbTrigger");
//  *             sched.scheduleJob(job, trigger);
//  * </pre>
//  * 
//  * If PROP_WAIT_FOR_PROCESS is true, then the Integer exit value of the process
//  * will be saved as the job execution result in the JobExecutionContext.
//  * 
//  * @see #PROP_COMMAND
//  * @see #PROP_PARAMETERS
//  * @see #PROP_WAIT_FOR_PROCESS
//  * @see #PROP_CONSUME_STREAMS
//  * 
//  * @author Matthew Payne
//  * @author James House
//  * @author Steinar Overbeck Cook
//  */
// class NativeJob : Job {


//     /*
//      *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      *
//      * Constants.
//      *  
//      *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */
        
//     /**
//      * Required parameter that specifies the name of the command (executable) 
//      * to be ran.
//      */
//     enum string PROP_COMMAND = "command";
    
//     /**
//      * Optional parameter that specifies the parameters to be passed to the
//      * executed command.
//      */
//     enum string PROP_PARAMETERS = "parameters";
    
    
//     /**
//      * Optional parameter (value should be 'true' or 'false') that specifies 
//      * whether the job should wait for the execution of the native process to 
//      * complete before it completes.
//      * 
//      * <p>Defaults to <code>true</code>.</p>  
//      */
//     enum string PROP_WAIT_FOR_PROCESS = "waitForProcess";
    
//     /**
//      * Optional parameter (value should be 'true' or 'false') that specifies 
//      * whether the spawned process's stdout and stderr streams should be 
//      * consumed.  If the process creates output, it is possible that it might
//      * 'hang' if the streams are not consumed.
//      * 
//      * <p>Defaults to <code>false</code>.</p>  
//      */
//     enum string PROP_CONSUME_STREAMS = "consumeStreams";
    
    
//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Interface.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     void execute(JobExecutionContext context) {

//         JobDataMap data = context.getMergedJobDataMap();
        
//         string command = data.getString(PROP_COMMAND);

//         string parameters = data.getString(PROP_PARAMETERS);

//         if (parameters is null) {
//             parameters = "";
//         }

//         bool wait = true;
//         if(data.containsKey(PROP_WAIT_FOR_PROCESS)) {
//             wait = data.getBooleanValue(PROP_WAIT_FOR_PROCESS);
//         }
//         bool consumeStreams = false;
//         if(data.containsKey(PROP_CONSUME_STREAMS)) {
//             consumeStreams = data.getBooleanValue(PROP_CONSUME_STREAMS);
//         }
            
//         Integer exitCode = this.runNativeCommand(command, parameters, wait, consumeStreams);
//         context.setResult(exitCode);
        
//     }

    
//     private Integer runNativeCommand(string command, string parameters, bool wait, bool consumeStreams) {

//         string[] cmd;
//         string[] args = new string[2];
//         Integer  result = null;
//         args[0] = command;
//         args[1] = parameters;

        
//         try {
//             //with this variable will be done the swithcing
//             string osName = System.getProperty("os.name");

//             // specific for Windows
//             if (osName.startsWith("Windows")) {
//                 cmd = new string[args.length + 2];
//                 if (osName.equals("Windows 95")) { // windows 95 only
//                     cmd[0] = "command.com";
//                 } else {
//                     cmd[0] = "cmd.exe";
//                 }
//                 cmd[1] = "/C";
//                 System.arraycopy(args, 0, cmd, 2, args.length);
//             } else if (osName.equals("Linux")) {
//                 cmd = new string[3];
//                 cmd[0] = "/bin/sh";
//                  cmd[1] = "-c";
//                  cmd[2] = args[0] ~ " " ~ args[1];
//             } else { // try this... 
//                 cmd = args;
//             }

//             Runtime rt = Runtime.getRuntime();
//             // Executes the command
//             info("About to run " ~ cmd[0] ~ " " ~ cmd[1] ~ " " ~ (cmd.length>2 ? cmd[2] : "") ~ " ..."); 
//             Process proc = rt.exec(cmd);
//             // Consumes the stdout from the process
//             StreamConsumer stdoutConsumer = new StreamConsumer(proc.getInputStream(), "stdout");

//             // Consumes the stderr from the process
//             if(consumeStreams) {
//                 StreamConsumer stderrConsumer = new StreamConsumer(proc.getErrorStream(), "stderr");
//                 stdoutConsumer.start();
//                 stderrConsumer.start();
//             }
            
//             if(wait) {
//                 result = proc.waitFor();
//             }
//             // any error message?
            
//         } catch (Throwable x) {
//             throw new JobExecutionException("Error launching native command: ", x, false);
//         }
        
//         return result;
//     }

//     /**
//      * Consumes data from the given input stream until EOF and prints the data to stdout
//      *
//      * @author cooste
//      * @author jhouse
//      */
//     class StreamConsumer : Thread {
//         InputStream is;
//         string type;

//         /**
//          *
//          */
//         StreamConsumer(InputStream inputStream, string type) {
//             this.is = inputStream;
//             this.type = type;
//         }

//         /**
//          * Runs this object as a separate thread, printing the contents of the InputStream
//          * supplied during instantiation, to either stdout or stderr
//          */
//         override
//         void run() {
//             BufferedReader br = null;
//             try {
//                 br = new BufferedReader(new InputStreamReader(is));
//                 string line;

//                 while ((line = br.readLine()) !is null) {
//                     if(type.equalsIgnoreCase("stderr")) {
//                         warning(type ~ ">" ~ line);
//                     } else {
//                         info(type ~ ">" ~ line);
//                     }
//                 }
//             } catch (IOException ioe) {
//                 error("Error consuming " ~ type ~ " stream of spawned process.", ioe);
//             } finally {
//                 if(br !is null) {
//                     try { br.close(); } catch(Exception ignore) {}
//                 }
//             }
//         }
//     }
    
// }
