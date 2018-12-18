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

module hunt.quartz.jobs.DirectoryScanJob;

// import java.io.File;
// import java.io.FileFilter;

import hunt.quartz.DisallowConcurrentExecution;
import hunt.quartz.Job;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobExecutionException;
import hunt.quartz.PersistJobDataAfterExecution;
import hunt.quartz.SchedulerContext;
import hunt.quartz.SchedulerException;

import hunt.logging;


/**
 * Inspects a directory and compares whether any files' "last modified dates" 
 * have changed since the last time it was inspected.  If one or more files 
 * have been updated (or created), the job invokes a "call-back" method on an 
 * identified <code>DirectoryScanListener</code> that can be found in the 
 * <code>SchedulerContext</code>.
 * 
 * @author pl47ypus
 * @author jhouse
 * @see hunt.quartz.jobs.DirectoryScanListener
 * @see hunt.quartz.SchedulerContext
 */
// class DirectoryScanJob : Job {

//     /**
//      * <code>JobDataMap</code> key with which to specify the directory to be 
//      * monitored - an absolute path is recommended. 
//      */
//     enum string DIRECTORY_NAME = "DIRECTORY_NAME";

//     /**
//      * <code>JobDataMap</code> key with which to specify the 
//      * {@link hunt.quartz.jobs.DirectoryScanListener} to be 
//      * notified when the directory contents change.  
//      */
//     enum string DIRECTORY_SCAN_LISTENER_NAME = "DIRECTORY_SCAN_LISTENER_NAME";

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
    

//     DirectoryScanJob() {
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
        
//         string dirName = mergedJobDataMap.getString(DIRECTORY_NAME);
//         string listenerName = mergedJobDataMap.getString(DIRECTORY_SCAN_LISTENER_NAME);
        
//         if(dirName is null) {
//             throw new JobExecutionException("Required parameter '" ~ 
//                     DIRECTORY_NAME ~ "' not found in merged JobDataMap");
//         }
//         if(listenerName is null) {
//             throw new JobExecutionException("Required parameter '" ~ 
//                     DIRECTORY_SCAN_LISTENER_NAME ~ "' not found in merged JobDataMap");
//         }

//         DirectoryScanListener listener = (DirectoryScanListener)schedCtxt.get(listenerName);
        
//         if(listener is null) {
//             throw new JobExecutionException("DirectoryScanListener named '" ~ 
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
//         long maxAgeDate = DateTimeHelper.currentTimeMillis() - minAge;
        
//         File[] updatedFiles = getUpdatedOrNewFiles(dirName, lastDate, maxAgeDate);

//         if(updatedFiles is null) {
//             log.warn("Directory '"+dirName+"' does not exist.");
//             return;
//         }
        
//         long latestMod = lastDate;
//         foreach(File updFile; updatedFiles) {
//             long lm = updFile.lastModified();
//             latestMod = (lm > latestMod) ? lm : latestMod;
//         }
        
//         if(updatedFiles.length > 0) {
//             // notify call back...
//             info("Directory '"+dirName+"' contents updated, notifying listener.");
//             listener.filesUpdatedOrAdded(updatedFiles); 
//         } else version(HUNT_DEBUG) {
//             trace("Directory '"+dirName+"' contents unchanged.");
//         }
        
//         // It is the JobDataMap on the JobDetail which is actually stateful
//         context.getJobDetail().getJobDataMap().put(LAST_MODIFIED_TIME, latestMod);
//     }
    
//     protected File[] getUpdatedOrNewFiles(string dirName, final long lastDate, final long maxAgeDate) {

//         File dir = new File(dirName);
//         if(!dir.exists() || !dir.isDirectory()) {
//             return null;
//         } 
        
//         File[] files = dir.listFiles(new FileFilter() {

//             bool accept(File pathname) {
//                 if(pathname.lastModified() > lastDate && pathname.lastModified() < maxAgeDate)
//                     return true;
//                 return false;
//             }});

//         if(files is null)
//             files = new File[0];
        
//         return files;
//     }
// }
