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
module hunt.quartz.impl.matchers.StringMatcher;

import hunt.quartz.Matcher;
import hunt.quartz.utils.Key;

/**
 * An abstract base class for some types of matchers.
 *  
 * @author jhouse
 */
abstract class StringMatcher<T extends Key<?>> implements Matcher!(T) {
  

    enum StringOperatorName {

        EQUALS {
            override
            bool evaluate(final string value, final string compareTo) {
                return value== compareTo;
            }
        },

        STARTS_WITH {
            override
            bool evaluate(final string value, final string compareTo) {
                return value.startsWith(compareTo);
            }
        },

        ENDS_WITH {
            override
            bool evaluate(final string value, final string compareTo) {
                return value.endsWith(compareTo);
            }
        },

        CONTAINS {
            override
            bool evaluate(final string value, final string compareTo) {
                return value.contains(compareTo);
            }
        },

        ANYTHING {
            override
            bool evaluate(final string value, final string compareTo) {
                return true;
            }
        };

        abstract bool evaluate(string value, string compareTo);
    }

    protected string compareTo;
    protected StringOperatorName compareWith;
    
    protected StringMatcher(string compareTo, StringOperatorName compareWith) {
        if(compareTo is null)
            throw new IllegalArgumentException("CompareTo value cannot be null!");
        if(compareWith is null)
            throw new IllegalArgumentException("CompareWith operator cannot be null!");
        
        this.compareTo = compareTo;
        this.compareWith = compareWith;
    }

    protected abstract string getValue(T key);
    
    bool isMatch(T key) {

        return compareWith.evaluate(getValue(key), compareTo);
    }

    override
    size_t toHash() @trusted nothrow() {
        final int prime = 31;
        int result = 1;
        result = prime * result
                + ((compareTo is null) ? 0 : compareTo.hashCode());
        result = prime * result
                + ((compareWith is null) ? 0 : compareWith.hashCode());
        return result;
    }

    override
    bool equals(Object obj) {
        if (this == obj)
            return true;
        if (obj is null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        StringMatcher<?> other = (StringMatcher<?>) obj;
        if (compareTo is null) {
            if (other.compareTo !is null)
                return false;
        } else if (!compareTo== other.compareTo)
            return false;
        if (compareWith is null) {
            if (other.compareWith !is null)
                return false;
        } else if (!compareWith== other.compareWith)
            return false;
        return true;
    }

    string getCompareToValue() {
        return compareTo;
    }

    StringOperatorName getCompareWithOperator() {
        return compareWith;
    }

}
