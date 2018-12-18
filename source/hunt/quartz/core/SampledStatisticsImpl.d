module hunt.quartz.core.SampledStatisticsImpl;

import java.util.Timer;

import hunt.quartz.JobDetail;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobExecutionException;
import hunt.quartz.JobListener;
import hunt.quartz.SchedulerListener;
import hunt.quartz.Trigger;
import hunt.quartz.listeners.SchedulerListenerSupport;
import hunt.quartz.utils.counter.CounterConfig;
import hunt.quartz.utils.counter.CounterManager;
import hunt.quartz.utils.counter.CounterManagerImpl;
import hunt.quartz.utils.counter.sampled.SampledCounter;
import hunt.quartz.utils.counter.sampled.SampledCounterConfig;
import hunt.quartz.utils.counter.sampled.SampledRateCounterConfig;

class SampledStatisticsImpl : SchedulerListenerSupport, SampledStatistics, JobListener, SchedulerListener {
    private QuartzScheduler scheduler;
    
    private enum string NAME = "QuartzSampledStatistics";
    
    private enum int DEFAULT_HISTORY_SIZE = 30;
    private enum int DEFAULT_INTERVAL_SECS = 1;
    private __gshared SampledCounterConfig DEFAULT_SAMPLED_COUNTER_CONFIG;

    // private __gshared SampledRateCounterConfig DEFAULT_SAMPLED_RATE_COUNTER_CONFIG = new SampledRateCounterConfig(DEFAULT_INTERVAL_SECS,
    //         DEFAULT_HISTORY_SIZE, true);

    private CounterManager counterManager;
    private SampledCounter jobsScheduledCount;
    private SampledCounter jobsExecutingCount;
    private SampledCounter jobsCompletedCount;

    shared static this() {
        DEFAULT_SAMPLED_COUNTER_CONFIG = new SampledCounterConfig(DEFAULT_INTERVAL_SECS,
            DEFAULT_HISTORY_SIZE, true, 0L);
    }
    
    this(QuartzScheduler scheduler) {
        this.scheduler = scheduler;
        
        counterManager = new CounterManagerImpl(new Timer(NAME+"Timer"));
        jobsScheduledCount = createSampledCounter(DEFAULT_SAMPLED_COUNTER_CONFIG);
        jobsExecutingCount = createSampledCounter(DEFAULT_SAMPLED_COUNTER_CONFIG);
        jobsCompletedCount = createSampledCounter(DEFAULT_SAMPLED_COUNTER_CONFIG);
        
        scheduler.addInternalSchedulerListener(this);
        scheduler.addInternalJobListener(this);
    }
    
    void shutdown() {
        counterManager.shutdown(true);
    }
    
    private SampledCounter createSampledCounter(CounterConfig defaultCounterConfig) {
        return cast(SampledCounter) counterManager.createCounter(defaultCounterConfig);
    }
    
    /**
     * Clears the collected statistics. Resets all counters to zero
     */
    void clearStatistics() {
        jobsScheduledCount.getAndReset();
        jobsExecutingCount.getAndReset();
        jobsCompletedCount.getAndReset();
    }
    
    long getJobsCompletedMostRecentSample() {
        return jobsCompletedCount.getMostRecentSample().getCounterValue();
    }

    long getJobsExecutingMostRecentSample() {
        return jobsExecutingCount.getMostRecentSample().getCounterValue();
    }

    long getJobsScheduledMostRecentSample() {
        return jobsScheduledCount.getMostRecentSample().getCounterValue();
    }

    string getName() {
        return NAME;
    }

    override
    void jobScheduled(Trigger trigger) {
        jobsScheduledCount.increment();
    }
    
    void jobExecutionVetoed(JobExecutionContext context) {
        /**/
    }

    void jobToBeExecuted(JobExecutionContext context) {
        jobsExecutingCount.increment();
    }

    void jobWasExecuted(JobExecutionContext context,
            JobExecutionException jobException) {
        jobsCompletedCount.increment();
    }

    override
    void jobAdded(JobDetail jobDetail) {
        /**/
    }

    void jobDeleted(string jobName, string groupName) {
        /**/
    }
}
