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

module hunt.quartz.jobs.ee.jmx.JMXInvokerJob;


// import hunt.collection.LinkedList;
// import hunt.text.StringTokenizer;

// import javax.management.MBeanServer;
// import javax.management.MBeanServerFactory;
// import javax.management.ObjectName;

// import hunt.logging;

// import hunt.quartz.Job;
// import hunt.quartz.JobDataMap;
// import hunt.quartz.JobExecutionContext;
// import hunt.quartz.Exceptions;


// /**
//  * Generic JMX invoker Job.  It supports any number or type of parameters
//  * to the JMX bean.<p>
//  * 
//  * The required parameters are as follows (case doesn't matter):<p>
//  * <dl>
//  * <dt><strong>JMX_OBJECTNAME</strong>
//  * <dd>This is the fully qualifed name of the object (ie in JBoss to lookup
//  * the log4j jmx bean you would specify "jboss.system:type=Log4jService,service=Logging"
//  * <dt><strong>JMX_METHOD</strong>
//  * <dd>This is the method to invoke on the specified JMX Bean. (ie in JBoss to
//  * change the log level you would specify "setLoggerLevel"
//  * <dt><strong>JMX_PARAMDEFS</strong>
//  * <dd>This is a definition of the parameters to be passed to the specified method
//  * and their corresponding java types.  Each parameter definition is comma seperated
//  * and has the following parts: <type>:<name>.  Type is the java type for the parameter.  
//  * The following types are supported:<p>
//  * <b>i</b> - is for int!(p)
//  * <b>l</b> - is for long!(p)
//  * <b>f</b> - is for float!(p)
//  * <b>d</b> - is for double!(p)
//  * <b>s</b> - is for string!(p)
//  * <b>b</b> - is for bool!(p)
//  * For ilfdb use lower for native type and upper for object wrapper. The name portion
//  * of the definition is the name of the parameter holding the string value. (ie
//  * s:fname,s:lname would require 2 parameters of the name fname and lname and
//  * would be passed in that order to the method.
//  * 
//  * @author James Nelson (jmn@provident-solutions.com) -- Provident Solutions LLC
//  * 
//  */
// class JMXInvokerJob : Job {


//     void execute(JobExecutionContext context) {
//         try {
//             Object[] params=null;
//             string[] types=null;
//             string objName = null;
//             string objMethod = null;
            
//             JobDataMap jobDataMap = context.getMergedJobDataMap();
            
//             string[] keys = jobDataMap.getKeys();
//             for (int i = 0; i < keys.length; i++) {
//                 string value = jobDataMap.getString(keys[i]);
//                 if ("JMX_OBJECTNAME".equalsIgnoreCase(keys[i])) {
//                     objName = value;
//                 } else if ("JMX_METHOD".equalsIgnoreCase(keys[i])) {
//                     objMethod = value;
//                 } else if("JMX_PARAMDEFS".equalsIgnoreCase(keys[i])) {
//                     string[] paramdefs=split(value, ",");
//                     params=new Object[paramdefs.length];
//                     types=new string[paramdefs.length];
//                     for(int k=0;k<paramdefs.length;k++) {
//                         string parts[]=  split(paramdefs[k], ":");
//                         if (parts.length<2) {
//                             throw new Exception("Invalid parameter definition: required parts missing " ~paramdefs[k]);
//                         }
//                         switch(parts[0][0]) {
//                             case 'i':
//                                 params[k]=Integer.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Integer.TYPE.getName();
//                                 break;
//                             case 'I':
//                                 params[k]=Integer.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Integer.class.getName();
//                                 break;
//                             case 'l':
//                                 params[k]=Long.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Long.TYPE.getName();
//                                 break;
//                             case 'L':
//                                 params[k]=Long.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Long.class.getName();
//                                 break;
//                             case 'f':
//                                 params[k]=Float.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Float.TYPE.getName();
//                                 break;
//                             case 'F':
//                                 params[k]=Float.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Float.class.getName();
//                                 break;
//                             case 'd':
//                                 params[k]=Double.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Double.TYPE.getName();
//                                 break;
//                             case 'D':
//                                 params[k]=Double.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Double.class.getName();
//                                 break;
//                             case 's':
//                                 params[k]=jobDataMap.getString(parts[1]);
//                                 types[k]=string.class.getName();
//                                 break;
//                             case 'b':
//                                 params[k]= Boolean.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Boolean.TYPE.getName();
//                                 break;
//                             case 'B':
//                                 params[k]= Boolean.valueOf(jobDataMap.getString(parts[1]));
//                                 types[k]=Boolean.class.getName();
//                                 break;
//                         }
//                     }
//                 }
//             }
            
//             if (objName==null || objMethod==null) { 
//                 throw new Exception("Required parameters missing");
//             }
            
//             context.setResult(invoke(objName, objMethod, params, types));
//         } catch (Exception e) {
//             string m = "Caught a " ~ e.getClass().getName() ~ " exception : " ~ e.getMessage();
//             error(m, e);
//             throw new JobExecutionException(m, e, false);
//         }
//     }
  
//     private string[] split(string str, string splitStr) // Same as string.split(.) in JDK 1.4
//     {
//         LinkedList!(string) l = new LinkedList!(string)();
    
//         StringTokenizer strTok = new StringTokenizer(str, splitStr);
//         while(strTok.hasMoreTokens()) {
//             string tok = strTok.nextToken();
//             l.add(tok);
//         }
    
//         return (string[])l.toArray(new string[l.size()]);
//     }

//     private Object invoke(string objectName, string method, Object[] params, string[] types) {
//         MBeanServer server = (MBeanServer) MBeanServerFactory.findMBeanServer(null).get(0);
//         ObjectName mbean = new ObjectName(objectName);

//         if (server is null) {
//             throw new Exception("Can't find mbean server");
//         }

//         info("invoking " ~ method);
//         return server.invoke(mbean, method, params, types);
//     }


// }
