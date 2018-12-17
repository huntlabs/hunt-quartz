module hunt.quartz.core.NullSampledStatisticsImpl;

class NullSampledStatisticsImpl implements SampledStatistics {
    long getJobsCompletedMostRecentSample() {
        return 0;
    }

    long getJobsExecutingMostRecentSample() {
        return 0;
    }

    long getJobsScheduledMostRecentSample() {
        return 0;
    }

    void shutdown() {
        // nothing to do
    }
}
