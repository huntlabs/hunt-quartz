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
module hunt.quartz.impl.matchers.KeyMatcher;

import hunt.quartz.Matcher;
import hunt.quartz.utils.Key;

/**
 * Matches on the complete key being equal (both name and group). 
 *  
 * @author jhouse
 */
class KeyMatcher(T) : Matcher!(T) {
  
    protected T compareTo;
    
    protected this(T compareTo) {
        this.compareTo = compareTo;
    }
    
    /**
     * Create a KeyMatcher that matches Keys that equal the given key. 
     */
    static KeyMatcher!(U) keyEquals(U)(U compareTo) {
        return new KeyMatcher!(U)(compareTo);
    }

    bool isMatch(T key) {

        return compareTo== key;
    }

    T getCompareToValue() {
        return compareTo;
    }

    override
    size_t toHash() @trusted nothrow {
        final int prime = 31;
        int result = 1;
        result = prime * result
                + ((compareTo is null) ? 0 : compareTo.toHash());
        return result;
    }

    override
    bool opEquals(Object o) {
        if (this == obj)
            return true;
        if (obj is null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        KeyMatcher!T other = cast(KeyMatcher!T) obj;
        if (compareTo is null) {
            if (other.compareTo !is null)
                return false;
        } else if (!compareTo== other.compareTo)
            return false;
        return true;
    }
    
}
