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
module hunt.quartz.impl.matchers.NotMatcher;

import hunt.quartz.Matcher;
import hunt.quartz.utils.Key;

/**
 * Matches using an NOT operator on another Matcher. 
 *  
 * @author jhouse
 */
class NotMatcher<T extends Key<?>> implements Matcher!(T) {
  

    protected Matcher!(T) operand;
    
    protected NotMatcher(Matcher!(T) operand) {
        if(operand is null)
            throw new IllegalArgumentException("Non-null operand required!");
        
        this.operand = operand;
    }
    
    /**
     * Create a NotMatcher that reverses the result of the given matcher.
     */
    static <U extends Key<?>> NotMatcher!(U) not(Matcher!(U) operand) {
        return new NotMatcher!(U)(operand);
    }

    bool isMatch(T key) {

        return !operand.isMatch(key);
    }

    Matcher!(T) getOperand() {
        return operand;
    }

    override
    size_t toHash() @trusted nothrow() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((operand is null) ? 0 : operand.hashCode());
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
        NotMatcher<?> other = (NotMatcher<?>) obj;
        if (operand is null) {
            if (other.operand !is null)
                return false;
        } else if (!operand== other.operand)
            return false;
        return true;
    }
}
