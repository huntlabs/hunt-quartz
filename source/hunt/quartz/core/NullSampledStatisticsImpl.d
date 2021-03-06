module hunt.quartz.core.NullSampledStatisticsImpl;

import hunt.quartz.core.SampledStatistics;

class NullSampledStatisticsImpl : SampledStatistics {
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
