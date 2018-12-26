/**
 *  Copyright Terracotta, Inc.
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
module hunt.quartz.management.ManagementRESTServiceConfiguration;

import hunt.lang.exception;
import std.conv;
import std.string;

/**
 * Configuration class of management REST services.
 * 
 * @author Ludovic Orban
 * 
 *         TODO : could be merged with ehcache
 *         ManagementRESTServiceConfiguration in a common module
 */
class ManagementRESTServiceConfiguration {

    /**
     * Default bind value.
     */
    enum string DEFAULT_BIND = "0.0.0.0:9888";

    /**
     * Default timeout for the connection to the configured security service
     */
    enum int DEFAULT_SECURITY_SVC_TIMEOUT = 5 * 1000;

    private bool enabled = false;
    private string securityServiceLocation;
    private int securityServiceTimeout = DEFAULT_SECURITY_SVC_TIMEOUT;
    private string bind = DEFAULT_BIND;

    // private int sampleHistorySize =
    // CacheStatisticsSampler.DEFAULT_HISTORY_SIZE;
    // private int sampleIntervalSeconds =
    // CacheStatisticsSampler.DEFAULT_INTERVAL_SECS;
    // private int sampleSearchIntervalSeconds =
    // CacheStatisticsSampler.DEFAULT_SEARCH_INTERVAL_SEC;

    /**
     * Check if the REST services should be enabled or not.
     * @return true if REST services should be enabled.
     */
    bool isEnabled() {
        return enabled;
    }

    /**
     * Set that the REST services should be enabled or disabled.
     * @param enabled true if the REST services should be enabled.
     */
    void setEnabled(bool enabled) {
        this.enabled = enabled;
    }

    /**
     * Returns the security service location required for trusted identity assertion to the embedded REST management
     * service.  This feature is only available with an enterprise license.
     * <p/>
     * If this value is set, then this service will require secure dialog with the TMS or other 3rd party REST client
     * implementations. The service furnished by the enterprise version of the TMC is located is provided at /api/assertIdentity.
     *
     *
     * @return a string representing the URL of the security service.
     */
    string getSecurityServiceLocation() {
        return securityServiceLocation;
    }

    /**
     * Sets the security service location required for trusted identity assertion to the embedded REST management
     * service.  This feature is only available with an enterprise license.
     * <p/>
     * If this value is set, then this service will require secure dialog with the TMS or other 3rd party REST client
     * implementations. The service furnished by the enterprise version of the TMC is located is provided at /api/assertIdentity.
     *
     * @param securityServiceURL a string representing the URL of the security service.
     */
    void setSecurityServiceLocation(string securityServiceURL) {
        this.securityServiceLocation = securityServiceURL;
    }

    /**
     * Returns the connection/read timeout value for the security service in milliseconds.
     *
     * @return security service timeout
     */
    int getSecurityServiceTimeout() {
        return securityServiceTimeout;
    }

    /**
     * Sets the connection/read timeout value for the security service in milliseconds.
     *
     * @param securityServiceTimeout milliseconds to timeout
     */
    void setSecurityServiceTimeout(int securityServiceTimeout) {
        this.securityServiceTimeout = securityServiceTimeout;
    }

    /**
     * Get the host:port pair to which the REST server should be bound.
     * Format is: [IP address|host name]:[port number]
     * @return the host:port pair to which the REST server should be bound.
     */
    string getBind() {
        return bind;
    }

    /**
     * Get the host part of the host:port pair to which the REST server should be bound.
     * @return the host part of the host:port pair to which the REST server should be bound.
     */
    string getHost() {
        if (bind is null) {
            return null;
        }
        return bind.split("\\:")[0];
    }

    /**
     * Get the port part of the host:port pair to which the REST server should be bound.
     * @return the port part of the host:port pair to which the REST server should be bound.
     */
    int getPort() {
        if (bind is null) {
            return -1;
        }
        string[] split = bind.split("\\:");
        if (split.length != 2) {
            throw new IllegalArgumentException("invalid bind format (should be IP:port)");
        }
        return to!int(split[1]);
    }

    /**
     * Set the host:port pair to which the REST server should be bound.
     * @param bind host:port pair to which the REST server should be bound.
     */
    void setBind(string bind) {
        this.bind = bind;
    }

    /**
     * Returns the sample history size to be applied to the {@link SampledCounterConfig} for sampled statistics
     *
     * @return the sample history size
     */
    // public int getSampleHistorySize() {
    // return sampleHistorySize;
    // }

    /**
     * Sets the sample history size to be applied to the {@link SampledCounterConfig} for sampled statistics
     *
     * @param sampleHistorySize to set
     */
    // public void setSampleHistorySize(final int sampleHistorySize) {
    // this.sampleHistorySize = sampleHistorySize;
    // }

    /**
     * Returns the sample interval in seconds to be applied to the {@link SampledCounterConfig} for sampled statistics
     *
     * @return the sample interval in seconds
     */
    // public int getSampleIntervalSeconds() {
    // return sampleIntervalSeconds;
    // }

    /**
     * Sets the sample interval in seconds to be applied to the {@link SampledCounterConfig} for sampled statistics
     *
     * @param sampleIntervalSeconds to set
     */
    // public void setSampleIntervalSeconds(final int sampleIntervalSeconds) {
    // this.sampleIntervalSeconds = sampleIntervalSeconds;
    // }

    /**
     * Returns the sample search interval in seconds to be applied to the {@link SampledRateCounterConfig} for sampled statistics
     *
     * @return the sample search interval in seconds
     */
    // public int getSampleSearchIntervalSeconds() {
    // return sampleSearchIntervalSeconds;
    // }

    /**
     * Sets the sample search interval in seconds to be applied to the {@link SampledCounterConfig} for sampled statistics
     *
     * @param sampleSearchInterval to set
     */
    // public void setSampleSearchIntervalSeconds(final int
    // sampleSearchInterval) {
    // this.sampleSearchIntervalSeconds = sampleSearchInterval;
    // }

    /**
     * A factory method for {@link SampledCounterConfig} based on the global settings defined on this object
     *
     * @see #getSampleIntervalSeconds()
     * @see #getSampleHistorySize()
     *
     * @return a {@code SampledCounterConfig}
     */
    // public SampledCounterConfig makeSampledCounterConfig() {
    // return new SampledCounterConfig(getSampleIntervalSeconds(),
    // getSampleHistorySize(), true, 0L);
    // }

    /**
     * A factory method for {@link SampledCounterConfig} based on the global settings defined on this object
     *
     * @see #getSampleIntervalSeconds()
     * @see #getSampleHistorySize()
     *
     * @return a {@code SampledCounterConfig}
     */
    // public SampledRateCounterConfig makeSampledGetRateCounterConfig() {
    // return new SampledRateCounterConfig(getSampleIntervalSeconds(),
    // getSampleHistorySize(), true);
    // }

    /**
     * A factory method for {@link SampledCounterConfig} based on the global settings defined on this object
     *
     * @see #getSampleSearchIntervalSeconds()
     * @see #getSampleHistorySize()
     *
     * @return a {@code SampledCounterConfig}
     */
    // public SampledRateCounterConfig makeSampledSearchRateCounterConfig() {
    // return new SampledRateCounterConfig(getSampleSearchIntervalSeconds(),
    // getSampleHistorySize(), true);
    // }
}
