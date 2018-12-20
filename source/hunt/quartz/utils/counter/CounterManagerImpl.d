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

module hunt.quartz.utils.counter.CounterManagerImpl;

import hunt.quartz.utils.counter.Counter;
import hunt.quartz.utils.counter.CounterConfig;
import hunt.quartz.utils.counter.CounterManager;

import hunt.container.ArrayList;
import hunt.container.List;
import hunt.util.timer;

import hunt.quartz.utils.counter.sampled.SampledCounter;
import hunt.quartz.utils.counter.sampled.SampledCounterImpl;

/**
 * An implementation of a {@link CounterManager}.
 * 
 * @author <a href="mailto:asanoujam@terracottatech.com">Abhishek Sanoujam</a>
 * @since 1.8
 * 
 */
class CounterManagerImpl : CounterManager {

    private Timer timer;
    private bool _isShutdown;
    private List!(Counter) counters;

    /**
     * Constructor that accepts a timer that will be used for scheduling sampled
     * counter if any is created
     */
    this(Timer timer) {
        if (timer is null) {
            throw new IllegalArgumentException("Timer cannot be null");
        }
        this.timer = timer;
        counters = new ArrayList!(Counter)();
    }

    /**
     * {@inheritDoc}
     */
    void shutdown(bool killTimer) {
        if (_isShutdown) {
            return;
        }
        try {
            // shutdown the counters of this counterManager
            foreach(Counter counter ; counters) {
                SampledCounter sc = cast(SampledCounter) counter;
                if (sc !is null) {
                    sc.shutdown();
                }
            }
            if(killTimer)
                timer.cancel();
        } finally {
            _isShutdown = true;
        }
    }

    /**
     * {@inheritDoc}
     */
    Counter createCounter(CounterConfig config) {
        if (_isShutdown) {
            throw new IllegalStateException("counter manager is shutdown");
        }
        if (config is null) {
            throw new NullPointerException("config cannot be null");
        }
        Counter counter = config.createCounter();
        SampledCounterImpl sampledCounter = cast(SampledCounterImpl) counter;
        if (sampledCounter !is null) {
            timer.schedule(sampledCounter.getTimerTask(), sampledCounter.getIntervalMillis(), sampledCounter.getIntervalMillis());
        }
        counters.add(counter);
        return counter;
    }

    /**
     * {@inheritDoc}
     */
    void shutdownCounter(Counter counter) {
        SampledCounter sc = cast(SampledCounter) counter;
        if (sc !is null) {
            sc.shutdown();
        }
    }

}
