module hunt.quartz.core.SampledStatistics;

interface SampledStatistics {
    long getJobsScheduledMostRecentSample();
    long getJobsExecutingMostRecentSample();
    long getJobsCompletedMostRecentSample();
    void shutdown();
}
