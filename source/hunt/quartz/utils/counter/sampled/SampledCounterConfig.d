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

module hunt.quartz.utils.counter.sampled.SampledCounterConfig;

import hunt.quartz.utils.counter.sampled.SampledCounterImpl;
import hunt.quartz.utils.counter.Counter;
import hunt.quartz.utils.counter.CounterConfig;


import hunt.Exceptions;
import std.conv;

/**
 * Config for a {@link SampledCounter}
 * 
 * @author <a href="mailto:asanoujam@terracottatech.com">Abhishek Sanoujam</a>
 * @since 1.7
 * 
 */
class SampledCounterConfig : CounterConfig {
    private int intervalSecs;
    private int historySize;
    private bool isReset;

    /**
     * Make a new timed counter config (duh)
     * 
     * @param intervalSecs
     *            the interval (in seconds) between sampling
     * @param historySize
     *            number of counter samples that will be retained in memory
     * @param isResetOnSample
     *            true if the counter should be reset to 0 upon each sample
     */
    this(int intervalSecs, int historySize, bool isResetOnSample, long initialValue) {
        super(initialValue);
        if (intervalSecs < 1) {
            throw new IllegalArgumentException("Interval (" ~ 
                intervalSecs.to!string() ~ ") must be greater than or equal to 1");
        }
        if (historySize < 1) {
            throw new IllegalArgumentException("History size (" ~ 
                historySize.to!string() ~ ") must be greater than or equal to 1");
        }

        this.intervalSecs = intervalSecs;
        this.historySize = historySize;
        this.isReset = isResetOnSample;
    }

    /**
     * Returns the history size
     * 
     * @return The history size
     */
    int getHistorySize() {
        return historySize;
    }

    /**
     * Returns the interval time (seconds)
     * 
     * @return Interval of the sampling thread in seconds
     */
    int getIntervalSecs() {
        return intervalSecs;
    }

    /**
     * Returns true if counters created from this config will reset on each
     * sample
     * 
     * @return true if values are reset to the initial value after each sample
     */
    bool isResetOnSample() {
        return this.isReset;
    }

    /**
     * {@inheritDoc}
     */
    override
    Counter createCounter() {
        return new SampledCounterImpl(this);
    }
}