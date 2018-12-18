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

module hunt.quartz.utils.counter.CounterImpl;

import java.util.concurrent.atomic.AtomicLong;

/**
 * A simple counter implementation
 * 
 * @author <a href="mailto:asanoujam@terracottatech.com">Abhishek Sanoujam</a>
 * @since 1.8
 * 
 */
class CounterImpl : Counter, Serializable {
  
    
    private AtomicLong value;

    /**
     * Default Constructor
     */
    CounterImpl() {
        this(0L);
    }

    /**
     * Constructor with initial value
     * 
     * @param initialValue
     */
    CounterImpl(long initialValue) {
        this.value = new AtomicLong(initialValue);
    }

    /**
     * {@inheritDoc}
     */
    long increment() {
        return value.incrementAndGet();
    }

    /**
     * {@inheritDoc}
     */
    long decrement() {
        return value.decrementAndGet();
    }

    /**
     * {@inheritDoc}
     */
    long getAndSet(long newValue) {
        return value.getAndSet(newValue);
    }

    /**
     * {@inheritDoc}
     */
    long getValue() {
        return value.get();
    }

    /**
     * {@inheritDoc}
     */
    long increment(long amount) {
        return value.addAndGet(amount);
    }

    /**
     * {@inheritDoc}
     */
    long decrement(long amount) {
        return value.addAndGet(amount * -1);
    }

    /**
     * {@inheritDoc}
     */
    void setValue(long newValue) {
        value.set(newValue);
    }

}
