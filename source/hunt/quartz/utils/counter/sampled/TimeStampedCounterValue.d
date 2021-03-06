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

module hunt.quartz.utils.counter.sampled.TimeStampedCounterValue;

import std.conv;

/**
 * A counter value at a particular time instance
 * 
 * @author <a href="mailto:asanoujam@terracottatech.com">Abhishek Sanoujam</a>
 * @since 1.8
 */
class TimeStampedCounterValue { //  : Serializable
    
    private long counterValue;
    private long timestamp;

    /**
     * Constructor accepting the value of both timestamp and the counter value.
     * 
     * @param timestamp
     * @param value
     */
    this(long timestamp, long value) {
        this.timestamp = timestamp;
        this.counterValue = value;
    }

    /**
     * Get the counter value
     * 
     * @return The counter value
     */
    long getCounterValue() {
        return this.counterValue;
    }

    /**
     * Get value of the timestamp
     * 
     * @return the timestamp associated with the current value
     */
    long getTimestamp() {
        return this.timestamp;
    }

    /**
     * {@inheritDoc}
     */
    override
    string toString() {
        return "value: " ~ this.counterValue.to!string() ~ ", timestamp: " ~ this.timestamp.to!string();
    }

}
