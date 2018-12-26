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

import hunt.quartz.utils.counter.Counter;

import hunt.io.common;
import hunt.concurrent.atomic.AtomicHelper;
import core.atomic;

/**
 * A simple counter implementation
 * 
 * @author <a href="mailto:asanoujam@terracottatech.com">Abhishek Sanoujam</a>
 * @since 1.8
 * 
 */
class CounterImpl : Counter, Serializable {
  
    private shared long value;

    /**
     * Default Constructor
     */
    this() {
        this(0L);
    }

    /**
     * Constructor with initial value
     * 
     * @param initialValue
     */
    this(long initialValue) {
        this.value = initialValue;
    }

    /**
     * {@inheritDoc}
     */
    long increment() {
        return increment(1);
    }

    /**
     * {@inheritDoc}
     */
    long decrement() {
        return decrement(1);
    }

    /**
     * {@inheritDoc}
     */
    long getAndSet(long newValue) {
        return AtomicHelper.getAndSet(value, newValue);
    }

    /**
     * {@inheritDoc}
     */
    long getValue() {
        return atomicLoad(value);
    }

    /**
     * {@inheritDoc}
     */
    long increment(long amount) {
        return atomicOp!("+=")(value, amount);
    }

    /**
     * {@inheritDoc}
     */
    long decrement(long amount) {
        return atomicOp!("-=")(value, amount);
    }

    /**
     * {@inheritDoc}
     */
    void setValue(long newValue) {
        atomicStore(value, newValue);
    }

}
