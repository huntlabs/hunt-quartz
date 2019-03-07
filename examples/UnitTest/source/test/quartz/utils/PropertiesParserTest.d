/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module test.quartz.utils.PropertiesParserTest;

import hunt.quartz.utils.PropertiesParser;

import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.Assert;


alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;

/**
 * Unit tests for PropertiesParser.
 */
public class PropertiesParserTest  {

    /**
     * Unit test for full getPropertyGroup() method.
     */
    public void testGetPropertyGroupStringBooleanStringArray() {
        // Test that an empty property does not cause an exception
        Properties props;
        props["x.y.z"] = "";
        
        PropertiesParser propertiesParser = new PropertiesParser(props);
        Properties propGroup = propertiesParser.getPropertyGroup("x.y", true, []);
        assertEquals("", propGroup["z"]);
    }
}
