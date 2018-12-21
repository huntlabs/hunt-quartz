
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

module hunt.quartz.core.RemotableQuartzScheduler;

// import java.rmi.Remote;
// import java.rmi.RemoteException;

import hunt.quartz.Calendar;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobKey;
import hunt.quartz.SchedulerContext;
import hunt.quartz.exception;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerKey;
import hunt.quartz.exception;
import hunt.quartz.Trigger : TriggerState;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.spi.OperableTrigger;

import hunt.container.List;
import hunt.container.Map;
import hunt.container.Set;
import hunt.time.LocalDateTime;

import std.datetime;

/**
 * @author James House
 */
interface RemotableQuartzScheduler { // : Remote 

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    string getSchedulerName();

    string getSchedulerInstanceId();

    SchedulerContext getSchedulerContext();

    void start();

    void startDelayed(int seconds);
    
    void standby();

    bool isInStandbyMode();

    void shutdown();

    void shutdown(bool waitForJobsToComplete);

    bool isShutdown();

    LocalDateTime runningSince();

    string getVersion();

    int numJobsExecuted();

    TypeInfo_Class getJobStoreClass();

    bool supportsPersistence();

    bool isClustered();

    TypeInfo_Class getThreadPoolClass();

    int getThreadPoolSize();

    void clear();
    
    List!(JobExecutionContext) getCurrentlyExecutingJobs();

    LocalDateTime scheduleJob(JobDetail jobDetail, Trigger trigger);

    LocalDateTime scheduleJob(Trigger trigger);

    void addJob(JobDetail jobDetail, bool replace);

    void addJob(JobDetail jobDetail, bool replace, bool storeNonDurableWhileAwaitingScheduling);

    bool deleteJob(JobKey jobKey);

    bool unscheduleJob(TriggerKey triggerKey);

    LocalDateTime rescheduleJob(TriggerKey triggerKey, Trigger newTrigger);
        
    void triggerJob(JobKey jobKey, JobDataMap data);

    void triggerJob(OperableTrigger trig);
    
    void pauseTrigger(TriggerKey triggerKey);

    void pauseTriggers(GroupMatcher!(TriggerKey) matcher);

    void pauseJob(JobKey jobKey);

    void pauseJobs(GroupMatcher!(JobKey) matcher);

    void resumeTrigger(TriggerKey triggerKey);

    void resumeTriggers(GroupMatcher!(TriggerKey) matcher);

    Set!(string) getPausedTriggerGroups();
    
    void resumeJob(JobKey jobKey);

    void resumeJobs(GroupMatcher!(JobKey) matcher);

    void pauseAll();

    void resumeAll();

    List!(string) getJobGroupNames();

    Set!(JobKey) getJobKeys(GroupMatcher!(JobKey) matcher);

    List!(Trigger) getTriggersOfJob(JobKey jobKey);

    List!(string) getTriggerGroupNames();

    Set!(TriggerKey) getTriggerKeys(GroupMatcher!(TriggerKey) matcher);

    JobDetail getJobDetail(JobKey jobKey);

    Trigger getTrigger(TriggerKey triggerKey);

    TriggerState getTriggerState(TriggerKey triggerKey);

    void resetTriggerFromErrorState(TriggerKey triggerKey);

    void addCalendar(string calName, Calendar calendar, bool replace, bool updateTriggers);

    bool deleteCalendar(string calName);

    Calendar getCalendar(string calName);

    List!(string) getCalendarNames();

    bool interrupt(JobKey jobKey);

    bool interrupt(string fireInstanceId);
    
    bool checkExists(JobKey jobKey); 
   
    bool checkExists(TriggerKey triggerKey);
 
    bool deleteJobs(List!(JobKey) jobKeys);

    void scheduleJobs(Map!(JobDetail, Set!(Trigger)) triggersAndJobs, bool replace);

    void scheduleJob(JobDetail jobDetail, Set!(Trigger) triggersForJob, bool replace);

    bool unscheduleJobs(List!(TriggerKey) triggerKeys);
    
}
