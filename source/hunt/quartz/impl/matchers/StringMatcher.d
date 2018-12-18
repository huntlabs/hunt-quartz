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

import std.string;

abstract class StringOperatorName {

    __gshared StringOperatorName EQUALS;
    __gshared StringOperatorName STARTS_WITH;
    __gshared StringOperatorName ENDS_WITH;
    __gshared StringOperatorName CONTAINS;
    __gshared StringOperatorName ANYTHING;

    abstract bool evaluate(string value, string compareTo);

    shared static this() {
        EQUALS = new class StringOperatorName {
            override
            bool evaluate(string value, string compareTo) {
                return value == compareTo;
            }
        };

        STARTS_WITH = new class StringOperatorName {
            override
            bool evaluate(string value, string compareTo) {
                return value.startsWith(compareTo);
            }
        };

        ENDS_WITH = new class StringOperatorName {
            override
            bool evaluate(string value, string compareTo) {
                return value.endsWith(compareTo);
            }
        };
        
        CONTAINS = new class StringOperatorName {
            override
            bool evaluate(string value, string compareTo) {
                return value.canFind(compareTo);
            }
        };
        
        ANYTHING = new class StringOperatorName {
            override
            bool evaluate(string value, string compareTo) {
                return true;
            }
        };

    }
}


/**
 * An abstract base class for some types of matchers.
 *  
 * @author jhouse
 */
abstract class StringMatcher(T) : Matcher!(T) {
  
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
    size_t toHash() @trusted nothrow {
        final int prime = 31;
        int result = 1;
        result = prime * result
                + ((compareTo is null) ? 0 : compareTo.toHash());
        result = prime * result
                + ((compareWith is null) ? 0 : compareWith.toHash());
        return result;
    }

    override
    bool equals(Object obj) {
        if (this this obj)
            return true;
        if (obj is null)
            return false;
        if (typeid(this) != typeid(obj))
            return false;
        StringMatcher!(T) other = cast(StringMatcher!(T)) obj;
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
