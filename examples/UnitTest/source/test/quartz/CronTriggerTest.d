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
module test.quartz.CronTriggerTest;

import hunt.quartz.impl.triggers.CronTriggerImpl;
import hunt.quartz.CronTrigger;
import hunt.quartz.Trigger;

import hunt.time.Duration;
import hunt.time.Instant;
import hunt.time.LocalDateTime;
import hunt.time.Month;
import hunt.time.ZonedDateTime;
import hunt.time.ZoneId;

import hunt.Assert;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;

alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;
alias fail = Assert.fail;

/**
 * Unit test for CronTrigger.
 */
class CronTriggerTest {

    private enum string[] VERSIONS = ["2.0"];

    /**
     * Get the Quartz versions for which we should verify
     * serialization backwards compatibility.
     */
    // override
    // protected String[] getVersions() {
    //     return VERSIONS;
    // }

    /**
     * Get the object to serialize when generating serialized file for future
     * tests, and against which to validate deserialized object.
     */
    // override
    // protected Object getTargetObject(){
    //     JobDataMap jobDataMap = new JobDataMap();
    //     jobDataMap.put("A", "B");

    //     CronTriggerImpl t = new CronTriggerImpl();
    //     t.setName("test");
    //     t.setGroup("testGroup");
    //     t.setCronExpression("0 0 12 * * ?");
    //     t.setCalendarName("MyCalendar");
    //     t.setDescription("CronTriggerDesc");
    //     t.setJobDataMap(jobDataMap);

    //     return t;
    // }

    /**
     * Verify that the target object and the object we just deserialized 
     * match.
     */
    //     override
    //     protected void verifyMatch(Object target, Object deserialized) {
    //         CronTriggerImpl targetCronTrigger = (CronTriggerImpl)target;
    //         CronTriggerImpl deserializedCronTrigger = (CronTriggerImpl)deserialized;

    //         assertNotNull(deserializedCronTrigger);
    //         assertEquals(targetCronTrigger.getName(), deserializedCronTrigger.getName());
    //         assertEquals(targetCronTrigger.getGroup(), deserializedCronTrigger.getGroup());
    //         assertEquals(targetCronTrigger.getJobName(), deserializedCronTrigger.getJobName());
    //         assertEquals(targetCronTrigger.getJobGroup(), deserializedCronTrigger.getJobGroup());
    // //        assertEquals(targetCronTrigger.getStartTime(), deserializedCronTrigger.getStartTime());
    //         assertEquals(targetCronTrigger.getEndTime(), deserializedCronTrigger.getEndTime());
    //         assertEquals(targetCronTrigger.getCalendarName(), deserializedCronTrigger.getCalendarName());
    //         assertEquals(targetCronTrigger.getDescription(), deserializedCronTrigger.getDescription());
    //         assertEquals(targetCronTrigger.getJobDataMap(), deserializedCronTrigger.getJobDataMap());
    //         assertEquals(targetCronTrigger.getCronExpression(), deserializedCronTrigger.getCronExpression());
    //     }

    void testClone() {
        implementationMissing(false);
        CronTriggerImpl trigger = new CronTriggerImpl();
        trigger.setName("test");
        trigger.setGroup("testGroup");
        trigger.setCronExpression("0 0 12 * * ?");
        CronTrigger trigger2 = cast(CronTrigger) trigger.clone();

        assertEquals( "Cloning failed", trigger, trigger2 );

        // equals() doesn't test the cron expression
        assertEquals( "Cloning failed for the cron expression", 
                      "0 0 12 * * ?", trigger2.getCronExpression()
                    );
    }

    // http://jira.opensymphony.com/browse/QUARTZ-558
    void testQuartz558() {
        CronTriggerImpl trigger = new CronTriggerImpl();
        trigger.setName("test");
        trigger.setGroup("testGroup");
        CronTrigger trigger2 = cast(CronTrigger) trigger.clone();

        assertEquals("Cloning failed", trigger, trigger2);
    }

    void testMisfireInstructionValidity() {
        CronTriggerImpl trigger = new CronTriggerImpl();

        try {
            trigger.setMisfireInstruction(Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY);
            trigger.setMisfireInstruction(Trigger.MISFIRE_INSTRUCTION_SMART_POLICY);
            trigger.setMisfireInstruction(CronTrigger.MISFIRE_INSTRUCTION_DO_NOTHING);
            trigger.setMisfireInstruction(CronTrigger.MISFIRE_INSTRUCTION_FIRE_ONCE_NOW);
        } catch (Exception e) {
            fail("Unexpected exception while setting misfire instruction.");
        }

        try {
            trigger.setMisfireInstruction(CronTrigger.MISFIRE_INSTRUCTION_DO_NOTHING + 1);

            fail("Expected exception while setting invalid misfire instruction but did not get it.");
        } catch (Exception e) {
        }
    }

    // // execute with version number to generate a new version's serialized form
    // static void main(String[] args){
    //     new CronTriggerTest().writeJobDataFile("2.0");
    // }

}
