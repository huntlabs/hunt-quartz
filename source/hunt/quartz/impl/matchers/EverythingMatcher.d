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
module hunt.quartz.impl.matchers.EverythingMatcher;

import hunt.quartz.JobKey;
import hunt.quartz.Matcher;
import hunt.quartz.TriggerKey;
import hunt.quartz.utils.Key;

class EverythingMatcherHelper {

    /**
     * Create an EverythingMatcher that matches all jobs.
     */
    static EverythingMatcher!(JobKey) allJobs() {
        return new EverythingMatcher!(JobKey)();
    }

    /**
     * Create an EverythingMatcher that matches all triggers.
     */
    static EverythingMatcher!(TriggerKey) allTriggers() {
        return new EverythingMatcher!(TriggerKey)();
    }
    
}

/**
 * Matches on the complete key being equal (both name and group). 
 *  
 * @author jhouse
 */
class EverythingMatcher(T) : Matcher!(T) {
  
    
    protected this() {
    }
    
    bool isMatch(T key) {
        return true;
    }

    override
    bool opEquals(Object obj) {
        if(obj is null)
            return false;
        
        return typeid(obj) == typeid(this);
    }

    override
    size_t toHash() @trusted nothrow {
        return hashOf(typeid(this).name); // getClass().getName().toHash();
    }

    
}
