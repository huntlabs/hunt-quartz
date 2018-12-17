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
module hunt.quartz.impl.matchers.AndMatcher;

import hunt.quartz.Matcher;
import hunt.quartz.utils.Key;

/**
 * Matches using an AND operator on two Matcher operands. 
 *  
 * @author jhouse
 */
class AndMatcher<T extends Key<?>> implements Matcher!(T) {
  

    protected Matcher!(T) leftOperand;
    protected Matcher!(T) rightOperand;
    
    protected AndMatcher(Matcher!(T) leftOperand, Matcher!(T) rightOperand) {
        if(leftOperand is null || rightOperand is null)
            throw new IllegalArgumentException("Two non-null operands required!");
        
        this.leftOperand = leftOperand;
        this.rightOperand = rightOperand;
    }
    
    /**
     * Create an AndMatcher that depends upon the result of both of the given matchers.
     */
    static <U extends Key<?>> AndMatcher!(U) and(Matcher!(U) leftOperand, Matcher!(U) rightOperand) {
        return new AndMatcher!(U)(leftOperand, rightOperand);
    }

    bool isMatch(T key) {

        return leftOperand.isMatch(key) && rightOperand.isMatch(key);
    }

    Matcher!(T) getLeftOperand() {
        return leftOperand;
    }

    Matcher!(T) getRightOperand() {
        return rightOperand;
    }

    override
    size_t toHash() @trusted nothrow() {
        final int prime = 31;
        int result = 1;
        result = prime * result
                + ((leftOperand is null) ? 0 : leftOperand.hashCode());
        result = prime * result
                + ((rightOperand is null) ? 0 : rightOperand.hashCode());
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
        AndMatcher<?> other = (AndMatcher<?>) obj;
        if (leftOperand is null) {
            if (other.leftOperand !is null)
                return false;
        } else if (!leftOperand== other.leftOperand)
            return false;
        if (rightOperand is null) {
            if (other.rightOperand !is null)
                return false;
        } else if (!rightOperand== other.rightOperand)
            return false;
        return true;
    }

}
