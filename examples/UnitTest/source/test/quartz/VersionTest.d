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
 */
module test.quartz.VersionTest;

import hunt.quartz.core.QuartzScheduler;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.Assert;

alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;

import std.conv;
import std.regex;

/**
*/
class VersionTest  {
    
    private enum string SNAPSHOT_SUFFIX = "-SNAPSHOT";
    private enum string PROTOTYPE_SUFFIX = "-PROTO";

    void testVersionParsing() {
        assertNonNegativeInteger(QuartzScheduler.getVersionMajor());
        assertNonNegativeInteger(QuartzScheduler.getVersionMinor());

        string iter = QuartzScheduler.getVersionIteration();
        assertNotNull(iter);
        Regex!char suffix = regex("(\\d+)(-\\w+)?");
        RegexMatch!string m = matchAll(iter, suffix);
        if (m.empty) {
          throw new RuntimeException(iter ~ " doesn't match pattern '(\\d+)(-\\w+)?'");
        } else {
          assertNonNegativeInteger(m.front.front);
        } 

    }

    private void assertNonNegativeInteger(string s) {
        // info(s);
        assertNotNull(s);
        if(s == "UNKNOWN")
            return;

        bool parsed = false;
        int intVal = -1;
        try {
            intVal = to!int(s);
            parsed = true;
        } catch (NumberFormatException e) {}

        assertTrue(parsed);
        assertTrue(intVal >= 0);
    }
}

