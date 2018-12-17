/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not 
 * use this file except in compliance with the License. You may obtain a copy 
 * of the License at 
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0 
 *   
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
 * License for the specific language governing permissions and limitations 
 * under the License.
 * 
 */
module hunt.quartz.impl.matchers.NameMatcher;

import hunt.quartz.JobKey;
import hunt.quartz.TriggerKey;
import hunt.quartz.utils.Key;

/**
 * Matches on name (ignores group) property of Keys.
 *  
 * @author jhouse
 */
class NameMatcher<T extends Key<?>> extends StringMatcher!(T) {
  

    protected NameMatcher(string compareTo, StringOperatorName compareWith) {
        super(compareTo, compareWith);
    }
    
    /**
     * Create a NameMatcher that matches names equaling the given string.
     */
    static <T extends Key<?>> NameMatcher!(T) nameEquals(string compareTo) {
        return new NameMatcher!(T)(compareTo, StringOperatorName.EQUALS);
    }

    /**
     * Create a NameMatcher that matches job names equaling the given string.
     */
    static NameMatcher!(JobKey) jobNameEquals(string compareTo) {
        return NameMatcher.nameEquals(compareTo);
    }
    
    /**
     * Create a NameMatcher that matches trigger names equaling the given string.
     */
    static NameMatcher!(TriggerKey) triggerNameEquals(string compareTo) {
        return NameMatcher.nameEquals(compareTo);
    }
    
    /**
     * Create a NameMatcher that matches names starting with the given string.
     */
    static <U extends Key<?>> NameMatcher!(U) nameStartsWith(string compareTo) {
        return new NameMatcher!(U)(compareTo, StringOperatorName.STARTS_WITH);
    }

    /**
     * Create a NameMatcher that matches job names starting with the given string.
     */
    static NameMatcher!(JobKey) jobNameStartsWith(string compareTo) {
        return NameMatcher.nameStartsWith(compareTo);
    }
    
    /**
     * Create a NameMatcher that matches trigger names starting with the given string.
     */
    static NameMatcher!(TriggerKey) triggerNameStartsWith(string compareTo) {
        return NameMatcher.nameStartsWith(compareTo);
    }

    /**
     * Create a NameMatcher that matches names ending with the given string.
     */
    static <U extends Key<?>> NameMatcher!(U) nameEndsWith(string compareTo) {
        return new NameMatcher!(U)(compareTo, StringOperatorName.ENDS_WITH);
    }

    /**
     * Create a NameMatcher that matches job names ending with the given string.
     */
    static NameMatcher!(JobKey) jobNameEndsWith(string compareTo) {
        return NameMatcher.nameEndsWith(compareTo);
    }
    
    /**
     * Create a NameMatcher that matches trigger names ending with the given string.
     */
    static NameMatcher!(TriggerKey) triggerNameEndsWith(string compareTo) {
        return NameMatcher.nameEndsWith(compareTo);
    }

    /**
     * Create a NameMatcher that matches names containing the given string.
     */
    static <U extends Key<?>> NameMatcher!(U) nameContains(string compareTo) {
        return new NameMatcher!(U)(compareTo, StringOperatorName.CONTAINS);
    }

    /**
     * Create a NameMatcher that matches job names containing the given string.
     */
    static NameMatcher!(JobKey) jobNameContains(string compareTo) {
        return NameMatcher.nameContains(compareTo);
    }
    
    /**
     * Create a NameMatcher that matches trigger names containing the given string.
     */
    static NameMatcher!(TriggerKey) triggerNameContains(string compareTo) {
        return NameMatcher.nameContains(compareTo);
    }
    
    override
    protected string getValue(T key) {
        return key.getName();
    }

}
