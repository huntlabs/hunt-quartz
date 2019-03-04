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

module hunt.quartz.utils.counter.sampled.SampledRateCounterImpl;

import hunt.quartz.utils.counter.sampled.SampledRateCounter;
import hunt.quartz.utils.counter.sampled.SampledCounterImpl;
import hunt.quartz.utils.counter.sampled.SampledRateCounterConfig;

import hunt.Exceptions;

/**
 * An implementation of {@link SampledRateCounter}
 * 
 * @author <a href="mailto:asanoujam@terracottatech.com">Abhishek Sanoujam</a>
 * @since 1.8
 * 
 */
class SampledRateCounterImpl : SampledCounterImpl, SampledRateCounter {
  

    private enum string OPERATION_NOT_SUPPORTED_MSG = "This operation is not supported. Use SampledCounter Or Counter instead";

    private long numeratorValue;
    private long denominatorValue;

    /**
     * Constructor accepting the config
     * 
     * @param config
     */
    this(SampledRateCounterConfig config) {
        super(config);
    }

    /**
     * {@inheritDoc}
     */
    void setValue(long numerator, long denominator) {
        this.numeratorValue = numerator;
        this.denominatorValue = denominator;
    }

    /**
     * {@inheritDoc}
     */
    void increment(long numerator, long denominator) {
        this.numeratorValue += numerator;
        this.denominatorValue += denominator;
    }

    /**
     * {@inheritDoc}
     */
    void decrement(long numerator, long denominator) {
        this.numeratorValue -= numerator;
        this.denominatorValue -= denominator;
    }

    /**
     * {@inheritDoc}
     */
    void setDenominatorValue(long newValue) {
        this.denominatorValue = newValue;
    }

    /**
     * {@inheritDoc}
     */
    void setNumeratorValue(long newValue) {
        this.numeratorValue = newValue;
    }

    /**
     * {@inheritDoc}
     */
    override
    long getValue() {
        return denominatorValue == 0 ? 0 : (numeratorValue / denominatorValue);
    }

    /**
     * {@inheritDoc}
     */
    override
    long getAndReset() {
        long prevVal = getValue();
        setValue(0, 0);
        return prevVal;
    }

    // ====== unsupported operations. These operations need multiple params for
    // this class
    /**
     * throws {@link UnsupportedOperationException}
     */
    override
    long getAndSet(long newValue) {
        throw new UnsupportedOperationException(OPERATION_NOT_SUPPORTED_MSG);
    }

    /**
     * throws {@link UnsupportedOperationException}
     */
    override
    void setValue(long newValue) {
        throw new UnsupportedOperationException(OPERATION_NOT_SUPPORTED_MSG);
    }

    /**
     * throws {@link UnsupportedOperationException}
     */
    override
    long decrement() {
        throw new UnsupportedOperationException(OPERATION_NOT_SUPPORTED_MSG);
    }

    /**
     * throws {@link UnsupportedOperationException}
     */
    override
    long decrement(long amount) {
        throw new UnsupportedOperationException(OPERATION_NOT_SUPPORTED_MSG);
    }

    /**
     * throws {@link UnsupportedOperationException}
     */
    long getMaxValue() {
        throw new UnsupportedOperationException(OPERATION_NOT_SUPPORTED_MSG);
    }

    /**
     * throws {@link UnsupportedOperationException}
     */
    long getMinValue() {
        throw new UnsupportedOperationException(OPERATION_NOT_SUPPORTED_MSG);
    }

    /**
     * throws {@link UnsupportedOperationException}
     */
    override
    long increment() {
        throw new UnsupportedOperationException(OPERATION_NOT_SUPPORTED_MSG);
    }

    /**
     * throws {@link UnsupportedOperationException}
     */
    override
    long increment(long amount) {
        throw new UnsupportedOperationException(OPERATION_NOT_SUPPORTED_MSG);
    }

}
