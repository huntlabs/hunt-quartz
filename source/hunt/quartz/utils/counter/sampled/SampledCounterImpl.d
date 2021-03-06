/**
 *  All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

module hunt.quartz.utils.counter.sampled.SampledCounterImpl;

import hunt.quartz.utils.counter.sampled.SampledCounter;
import hunt.quartz.utils.counter.sampled.SampledCounterConfig;
import hunt.quartz.utils.counter.sampled.TimeStampedCounterValue;

// import java.util.TimerTask;

import hunt.quartz.utils.CircularLossyQueue;
import hunt.quartz.utils.counter.CounterImpl;
import hunt.util.DateTime;

/**
 * An implementation of {@link SampledCounter}
 * 
 * @author <a href="mailto:asanoujam@terracottatech.com">Abhishek Sanoujam</a>
 * @since 1.7
 * 
 */
class SampledCounterImpl : CounterImpl, SampledCounter {
  
    
    private enum int MILLIS_PER_SEC = 1000;

    /**
     * The history of this counter
     */
    protected CircularLossyQueue!(TimeStampedCounterValue) history;

    /**
     * Should the counter reset on each sample?
     */
    protected bool resetOnSample;
    // private TimerTask samplerTask;
    private long intervalMillis;

    /**
     * Constructor accepting a {@link SampledCounterConfig}
     * 
     * @param config
     */
    this(SampledCounterConfig config) {
        super(config.getInitialValue());

        this.intervalMillis = config.getIntervalSecs() * MILLIS_PER_SEC;
        this.history = new CircularLossyQueue!(TimeStampedCounterValue)(config.getHistorySize());
        this.resetOnSample = config.isResetOnSample();

// TODO: Tasks pending completion -@zxp at 12/20/2018, 10:23:57 AM
// 
        // this.samplerTask = new TimerTask() {
        //     override
        //     void run() {
        //         recordSample();
        //     }
        // };

        recordSample();
    }

    /**
     * {@inheritDoc}
     */
    TimeStampedCounterValue getMostRecentSample() {
        return this.history.peek();
    }

    /**
     * {@inheritDoc}
     */
    TimeStampedCounterValue[] getAllSampleValues() {
        return this.history.toArray(new TimeStampedCounterValue[this.history.depth()]);
    }

    /**
     * {@inheritDoc}
     */
    void shutdown() {
        // if (samplerTask !is null) {
        //     samplerTask.cancel();
        // }
    }

    /**
     * Returns the timer task for this sampled counter
     * 
     * @return the timer task for this sampled counter
     */
    // TimerTask getTimerTask() {
    //     return this.samplerTask;
    // }

    /**
     * Returns the sampling thread interval in millis
     * 
     * @return the sampling thread interval in millis
     */
    long getIntervalMillis() {
        return intervalMillis;
    }

    /**
     * {@inheritDoc}
     */
    void recordSample() {
        long sample;
        if (resetOnSample) {
            sample = getAndReset();
        } else {
            sample = getValue();
        }

        long now = DateTime.currentTimeMillis();
        TimeStampedCounterValue timedSample = new TimeStampedCounterValue(now, sample);

        history.push(timedSample);
    }

    /**
     * {@inheritDoc}
     */
    long getAndReset() {
        return getAndSet(0L);
    }
}
