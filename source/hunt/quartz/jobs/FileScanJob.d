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

module hunt.quartz.jobs.FileScanJob;

// import java.io.File;
// import java.net.URL;
// import java.net.URLDecoder;

import hunt.quartz.DisallowConcurrentExecution;
import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.exception;
import hunt.quartz.PersistJobDataAfterExecution;
import hunt.quartz.SchedulerContext;
import hunt.quartz.exception;

import hunt.logging;


/**
 * Inspects a file and compares whether it's "last modified date" has changed
 * since the last time it was inspected.  If the file has been updated, the
 * job invokes a "call-back" method on an identified 
 * <code>FileScanListener</code> that can be found in the 
 * <code>SchedulerContext</code>.
 * 
 * @author jhouse
 * @author pl47ypus
 * @see hunt.quartz.jobs.FileScanListener
 */
// class FileScanJob : Job {

//     /**
//      * <code>JobDataMap</code> key with which to specify 
//      * the name of the file to monitor.
//      */
//     enum string FILE_NAME = "FILE_NAME";
    
//     /**
//      * <code>JobDataMap</code> key with which to specify the 
//      * {@link hunt.quartz.jobs.FileScanListener} to be 
//      * notified when the file contents change.  
//      */
//     enum string FILE_SCAN_LISTENER_NAME = "FILE_SCAN_LISTENER_NAME";
    
//     /**
//      * <code>JobDataMap</code> key with which to specify a <code>long</code>
//      * value that represents the minimum number of milliseconds that must have
//      * past since the file's last modified time in order to consider the file
//      * new/altered.  This is necessary because another process may still be
//      * in the middle of writing to the file when the scan occurs, and the
//      * file may therefore not yet be ready for processing.
//      * 
//      * <p>If this parameter is not specified, a default value of 
//      * <code>5000</code> (five seconds) will be used.</p>
//      */
//     enum string MINIMUM_UPDATE_AGE = "MINIMUM_UPDATE_AGE";

//     private enum string LAST_MODIFIED_TIME = "LAST_MODIFIED_TIME";
    

//     this() {
//     }

//     /** 
//      * @see hunt.quartz.Job#execute(hunt.quartz.JobExecutionContext)
//      */
//     void execute(JobExecutionContext context) {
//         JobDataMap mergedJobDataMap = context.getMergedJobDataMap();
//         SchedulerContext schedCtxt = null;
//         try {
//             schedCtxt = context.getScheduler().getContext();
//         } catch (SchedulerException e) {
//             throw new JobExecutionException("Error obtaining scheduler context.", e, false);
//         }
        
//         string fileName = mergedJobDataMap.getString(FILE_NAME);
//         string listenerName = mergedJobDataMap.getString(FILE_SCAN_LISTENER_NAME);
        
//         if(fileName is null) {
//             throw new JobExecutionException("Required parameter '" ~ 
//                     FILE_NAME ~ "' not found in merged JobDataMap");
//         }
//         if(listenerName is null) {
//             throw new JobExecutionException("Required parameter '" ~ 
//                     FILE_SCAN_LISTENER_NAME ~ "' not found in merged JobDataMap");
//         }

//         FileScanListener listener = (FileScanListener)schedCtxt.get(listenerName);
        
//         if(listener is null) {
//             throw new JobExecutionException("FileScanListener named '" ~ 
//                     listenerName ~ "' not found in SchedulerContext");
//         }
        
//         long lastDate = -1;
//         if(mergedJobDataMap.containsKey(LAST_MODIFIED_TIME)) {
//             lastDate = mergedJobDataMap.getLong(LAST_MODIFIED_TIME);
//         }

//         long minAge = 5000;
//         if(mergedJobDataMap.containsKey(MINIMUM_UPDATE_AGE)) {
//             minAge = mergedJobDataMap.getLong(MINIMUM_UPDATE_AGE);
//         }
//         long maxAgeDate = DateTimeHelper.currentTimeMillis() + minAge;
        
        
//         long newDate = getLastModifiedDate(fileName);
        
//         if(newDate < 0) {
//             log.warn("File '" ~fileName~ "' does not exist.");
//             return;
//         }
        
//         if(lastDate > 0 && (newDate > lastDate && newDate < maxAgeDate)) {
//             // notify call back...
//             info("File '" ~fileName~ "' updated, notifying listener.");
//             listener.fileUpdated(fileName); 
//         } else version(HUNT_DEBUG) {
//             trace("File '" ~fileName~ "' unchanged.");
//         }
        
//         // It is the JobDataMap on the JobDetail which is actually stateful
//         context.getJobDetail().getJobDataMap().put(LAST_MODIFIED_TIME, newDate);
//     }
    
//     protected long getLastModifiedDate(string fileName) {
//         URL resource = Thread.getThis().getContextClassLoader().getResource(fileName);
        
//         // Get the absolute path.
//         string filePath = (resource is null) ? fileName : URLDecoder.decode(resource.getFile()); ;
        
//         // If the jobs file is inside a jar point to the jar file (to get it modification date).
//         // Otherwise continue as usual.
//         int jarIndicator = filePath.indexOf('!');
        
//         if (jarIndicator > 0) {
//             filePath = filePath.substring(5, filePath.indexOf('!'));
//         }

//         File file = new File(filePath);
        
//         if(!file.exists()) {
//             return -1;
//         } else {
//             return file.lastModified();
//         }
//     }
// }
