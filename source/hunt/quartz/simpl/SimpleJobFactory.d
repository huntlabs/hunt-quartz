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
module hunt.quartz.simpl.SimpleJobFactory;

import hunt.logging;

import hunt.quartz.Job;
import hunt.quartz.JobDetail;
import hunt.quartz.Scheduler;
import hunt.quartz.exception;
import hunt.quartz.spi.JobFactory;
import hunt.quartz.spi.TriggerFiredBundle;

/**
 * The default JobFactory used by Quartz - simply calls 
 * <code>newInstance()</code> on the job class.
 * 
 * @see JobFactory
 * @see PropertySettingJobFactory
 * 
 * @author jhouse
 */
class SimpleJobFactory : JobFactory {
    
    Job newJob(TriggerFiredBundle bundle, Scheduler Scheduler) {

        JobDetail jobDetail = bundle.getJobDetail();
        TypeInfo_Class jobClass = jobDetail.getJobClass();
        try {
            if(log.isDebugEnabled()) {
                trace("Producing instance of Job '" ~ jobDetail.getKey().toString() ~ 
                    "', class=" ~ jobClass.getName());
            }
            
            return jobClass.newInstance();
        } catch (Exception e) {
            SchedulerException se = new SchedulerException(
                    "Problem instantiating class '"
                            ~ jobDetail.getJobClass().getName() ~ "'", e.msg);
            throw se;
        }
    }

}
