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

import hunt.container.ArrayList;
import hunt.container.List;
import java.util.Timer;

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
    private bool shutdown;
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
        if (shutdown) {
            return;
        }
        try {
            // shutdown the counters of this counterManager
            foreach(Counter counter ; counters) {
                if (counter instanceof SampledCounter) {
                    ((SampledCounter) counter).shutdown();
                }
            }
            if(killTimer)
                timer.cancel();
        } finally {
            shutdown = true;
        }
    }

    /**
     * {@inheritDoc}
     */
    Counter createCounter(CounterConfig config) {
        if (shutdown) {
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
