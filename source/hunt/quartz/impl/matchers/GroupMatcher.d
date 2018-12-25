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
module hunt.quartz.impl.matchers.GroupMatcher;

import hunt.quartz.impl.matchers.StringMatcher;

import hunt.quartz.JobKey;
import hunt.quartz.TriggerKey;
import hunt.quartz.utils.Key;

class GroupMatcherHelper {
    
    /**
     * Create a GroupMatcher that matches groups equaling the given string.
     */
    static GroupMatcher!(T) groupEquals(T)(string compareTo) {
        return new GroupMatcher!(T)(compareTo, StringOperatorName.EQUALS);
    }

    /**
     * Create a GroupMatcher that matches job groups equaling the given string.
     */
    static GroupMatcher!(JobKey) jobGroupEquals(string compareTo) {
        return groupEquals!(JobKey)(compareTo);
    }
    
    /**
     * Create a GroupMatcher that matches trigger groups equaling the given string.
     */
    static GroupMatcher!(TriggerKey) triggerGroupEquals(string compareTo) {
        return groupEquals!(TriggerKey)(compareTo);
    }
    
    /**
     * Create a GroupMatcher that matches groups starting with the given string.
     */
    static GroupMatcher!(T) groupStartsWith(T)(string compareTo) {
        return new GroupMatcher!(T)(compareTo, StringOperatorName.STARTS_WITH);
    }

    /**
     * Create a GroupMatcher that matches job groups starting with the given string.
     */
    static GroupMatcher!(JobKey) jobGroupStartsWith(string compareTo) {
        return groupStartsWith!(JobKey)(compareTo);
    }
    
    /**
     * Create a GroupMatcher that matches trigger groups starting with the given string.
     */
    static GroupMatcher!(TriggerKey) triggerGroupStartsWith(string compareTo) {
        return groupStartsWith!(TriggerKey)(compareTo);
    }

    /**
     * Create a GroupMatcher that matches groups ending with the given string.
     */
    static GroupMatcher!(T) groupEndsWith(T)(string compareTo) {
        return new GroupMatcher!(T)(compareTo, StringOperatorName.ENDS_WITH);
    }

    /**
     * Create a GroupMatcher that matches job groups ending with the given string.
     */
    static GroupMatcher!(JobKey) jobGroupEndsWith(string compareTo) {
        return groupEndsWith!(JobKey)(compareTo);
    }
    
    /**
     * Create a GroupMatcher that matches trigger groups ending with the given string.
     */
    static GroupMatcher!(TriggerKey) triggerGroupEndsWith(string compareTo) {
        return groupEndsWith!(TriggerKey)(compareTo);
    }
    
    /**
     * Create a GroupMatcher that matches groups containing the given string.
     */
    static GroupMatcher!(T) groupContains(T)(string compareTo) {
        return new GroupMatcher!(T)(compareTo, StringOperatorName.CONTAINS);
    }

    /**
     * Create a GroupMatcher that matches job groups containing the given string.
     */
    static GroupMatcher!(JobKey) jobGroupContains(string compareTo) {
        return groupContains!(JobKey)(compareTo);
    }
    
    /**
     * Create a GroupMatcher that matches trigger groups containing the given string.
     */
    static GroupMatcher!(TriggerKey) triggerGroupContains(string compareTo) {
        return groupContains!(TriggerKey)(compareTo);
    }

    /**
     * Create a GroupMatcher that matches groups starting with the given string.
     */
    static GroupMatcher!(T) anyGroup(T)() {
        return new GroupMatcher!(T)("", StringOperatorName.ANYTHING);
    }

    /**
     * Create a GroupMatcher that matches job groups starting with the given string.
     */
    static GroupMatcher!(JobKey) anyJobGroup() {
        return anyGroup!(JobKey)();
    }

    /**
     * Create a GroupMatcher that matches trigger groups starting with the given string.
     */
    static GroupMatcher!(TriggerKey) anyTriggerGroup() {
        return anyGroup!(TriggerKey)();
    }
}

/**
 * Matches on group (ignores name) property of Keys.
 *  
 * @author jhouse
 */
class GroupMatcher(T) : StringMatcher!(T) {
  

    protected this(string compareTo, StringOperatorName compareWith) {
        super(compareTo, compareWith);
    }
    


    override
    protected string getValue(T key) {
        return key.getGroup();
    }

}
