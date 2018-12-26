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

module hunt.quartz.utils.counter.CounterConfig;

import hunt.quartz.utils.counter.Counter;
import hunt.quartz.utils.counter.CounterImpl;

/**
 * Config for a simple Counter
 * 
 * @author <a href="mailto:asanoujam@terracottatech.com">Abhishek Sanoujam</a>
 * @since 1.8
 * 
 */
class CounterConfig {

    private long initialValue;

    /**
     * Creates a config with the initial value
     * 
     * @param initialValue
     */
    this(long initialValue) {
        this.initialValue = initialValue;
    }

    /**
     * Gets the initial value
     * 
     * @return the initial value of counters created by this config
     */
    final long getInitialValue() {
        return initialValue;
    }

    /**
     * Creates and returns a Counter based on the initial value
     * 
     * @return The counter created by this config
     */
    Counter createCounter() {
        return new CounterImpl(initialValue);
    }
}
