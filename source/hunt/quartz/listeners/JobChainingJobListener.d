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
 */
module hunt.quartz.listeners.JobChainingJobListener;

import java.util.HashMap;
import hunt.container.Map;

import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobExecutionException;
import hunt.quartz.JobKey;
import hunt.quartz.SchedulerException;

/**
 * Keeps a collection of mappings of which Job to trigger after the completion
 * of a given job.  If this listener is notified of a job completing that has a
 * mapping, then it will then attempt to trigger the follow-up job.  This
 * achieves "job chaining", or a "poor man's workflow".
 *
 * <p>Generally an instance of this listener would be registered as a global
 * job listener, rather than being registered directly to a given job.</p>
 *
 * <p>If for some reason there is a failure creating the trigger for the
 * follow-up job (which would generally only be caused by a rare serious
 * failure in the system, or the non-existence of the follow-up job), an error
 * messsage is logged, but no other action is taken. If you need more rigorous
 * handling of the error, consider scheduling the triggering of the flow-up
 * job within your job itself.</p>
 *
 * @author James House (jhouse AT revolition DOT net)
 */
class JobChainingJobListener : JobListenerSupport {

    private string name;
    private Map!(JobKey, JobKey) chainLinks;


    /**
     * Construct an instance with the given name.
     *
     * @param name the name of this instance
     */
    JobChainingJobListener(string name) {
        if(name is null) {
            throw new IllegalArgumentException("Listener name cannot be null!");
        }
        this.name = name;
        chainLinks = new HashMap!(JobKey, JobKey)();
    }

    string getName() {
        return name;
    }

    /**
     * Add a chain mapping - when the Job identified by the first key completes
     * the job identified by the second key will be triggered.
     *
     * @param firstJob a JobKey with the name and group of the first job
     * @param secondJob a JobKey with the name and group of the follow-up job
     */
    void addJobChainLink(JobKey firstJob, JobKey secondJob) {

        if(firstJob is null || secondJob is null) {
            throw new IllegalArgumentException("Key cannot be null!");
        }

        if(firstJob.getName() is null || secondJob.getName() is null) {
            throw new IllegalArgumentException("Key cannot have a null name!");
        }

        chainLinks.put(firstJob, secondJob);
    }

    override
    void jobWasExecuted(JobExecutionContext context, JobExecutionException jobException) {

        JobKey sj = chainLinks.get(context.getJobDetail().getKey());

        if(sj is null) {
            return;
        }

        info("Job '" ~ context.getJobDetail().getKey() ~ "' will now chain to Job '" ~ sj ~ "'");

        try {
             context.getScheduler().triggerJob(sj);
        } catch(SchedulerException se) {
            error("Error encountered during chaining to Job '" ~ sj ~ "'", se);
        }
    }
}

