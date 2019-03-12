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
module test.quartz.SimpleTriggerTest;

import hunt.quartz.impl.triggers.SimpleTriggerImpl;
import hunt.quartz.SimpleTrigger;
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
 * Unit test for SimpleTrigger serialization backwards compatibility.
 */
class SimpleTriggerTest {
    private enum string[] VERSIONS = ["2.0"];
    private __gshared ZoneId EST_TIME_ZONE;
    private __gshared ZonedDateTime START_TIME;
    private __gshared ZonedDateTime END_TIME;
    
    shared static this()
    {
        EST_TIME_ZONE = ZoneId.of("US/Eastern"); 
        START_TIME = ZonedDateTime.of(2006, Month.JUNE, 1, 10, 5, 15, 0, EST_TIME_ZONE);
        END_TIME = ZonedDateTime.of(2006, Month.JUNE, 1, 10, 5, 15, 0, EST_TIME_ZONE);
    }
    
    /**
     * Get the object to serialize when generating serialized file for future
     * tests, and against which to validate deserialized object.
     */
    
    // override
    // protected Object getTargetObject() {
    //     JobDataMap jobDataMap = new JobDataMap();
    //     jobDataMap.put("A", "B");
        
    //     SimpleTriggerImpl t = new SimpleTriggerImpl("SimpleTrigger", "SimpleGroup",
    //             "JobName", "JobGroup", START_TIME.getTime(),
    //             END_TIME.getTime(), 5, 1000);
    //     t.setCalendarName("MyCalendar");
    //     t.setDescription("SimpleTriggerDesc");
    //     t.setJobDataMap(jobDataMap);
    //     t.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT);

    //     return t;
    // }
    
    /**
     * Get the Quartz versions for which we should verify
     * serialization backwards compatibility.
     */
    // override
    // protected string[] getVersions() {
    //     return VERSIONS;
    // }
    
    /**
     * Verify that the target object and the object we just deserialized 
     * match.
     */
    // protected void verifyMatch(Object target, Object deserialized) {
    //     SimpleTriggerImpl targetSimpleTrigger = cast(SimpleTriggerImpl)target;
    //     SimpleTriggerImpl deserializedSimpleTrigger = cast(SimpleTriggerImpl)deserialized;
        
    //     assertNotNull(deserializedSimpleTrigger);
    //     assertEquals(targetSimpleTrigger.getName(), deserializedSimpleTrigger.getName());
    //     assertEquals(targetSimpleTrigger.getGroup(), deserializedSimpleTrigger.getGroup());
    //     assertEquals(targetSimpleTrigger.getJobName(), deserializedSimpleTrigger.getJobName());
    //     assertEquals(targetSimpleTrigger.getJobGroup(), deserializedSimpleTrigger.getJobGroup());
    //     assertEquals(targetSimpleTrigger.getStartTime(), deserializedSimpleTrigger.getStartTime());
    //     assertEquals(targetSimpleTrigger.getEndTime(), deserializedSimpleTrigger.getEndTime());
    //     assertEquals(targetSimpleTrigger.getRepeatCount(), deserializedSimpleTrigger.getRepeatCount());
    //     assertEquals(targetSimpleTrigger.getRepeatInterval(), deserializedSimpleTrigger.getRepeatInterval());
    //     assertEquals(targetSimpleTrigger.getCalendarName(), deserializedSimpleTrigger.getCalendarName());
    //     assertEquals(targetSimpleTrigger.getDescription(), deserializedSimpleTrigger.getDescription());
    //     assertEquals(targetSimpleTrigger.getJobDataMap(), deserializedSimpleTrigger.getJobDataMap());
    //     assertEquals(targetSimpleTrigger.getMisfireInstruction(), deserializedSimpleTrigger.getMisfireInstruction());
    // }
    
    void testUpdateAfterMisfire() {
        
        LocalDateTime startTime = LocalDateTime.of(2005, Month.JULY, 5, 9, 0, 0);
        
        LocalDateTime endTime = LocalDateTime.of(2005, Month.JULY, 5, 10, 0, 0);
        
        SimpleTriggerImpl simpleTrigger = new SimpleTriggerImpl();
        simpleTrigger.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_EXISTING_REPEAT_COUNT);
        simpleTrigger.setRepeatCount(5);
        simpleTrigger.setStartTime(startTime);
        simpleTrigger.setEndTime(endTime);
        
        simpleTrigger.updateAfterMisfire(null);
        assertEquals(startTime, simpleTrigger.getStartTime());
        assertEquals(endTime, simpleTrigger.getEndTime());
        assertNull(simpleTrigger.getNextFireTime());
    }
    
    void testGetFireTimeAfter() {
        SimpleTriggerImpl simpleTrigger = new SimpleTriggerImpl();
        LocalDateTime startTime = LocalDateTime.now();

        simpleTrigger.setStartTime(startTime);
        simpleTrigger.setRepeatInterval(10);
        simpleTrigger.setRepeatCount(4);
        
        LocalDateTime fireTimeAfter = simpleTrigger.getFireTimeAfter(startTime.plusMilliseconds(34));
        assert(fireTimeAfter !is null);
        Duration dur = Duration.between(startTime, fireTimeAfter);
        assertEquals(40, dur.toMillis());
    }
    
    void testClone() {
        implementationMissing(false);
        // SimpleTriggerImpl simpleTrigger = new SimpleTriggerImpl();
        
        // // Make sure empty sub-objects are cloned okay
        // Trigger clone = cast(Trigger)simpleTrigger.clone();
        // assertEquals(0, clone.getJobDataMap().size());
        
        // // Make sure non-empty sub-objects are cloned okay
        // simpleTrigger.getJobDataMap().put("K1", "V1");
        // simpleTrigger.getJobDataMap().put("K2", "V2");
        // clone = cast(Trigger)simpleTrigger.clone();
        // assertEquals(2, clone.getJobDataMap().size());
        // assertEquals("V1", clone.getJobDataMap().get("K1"));
        // assertEquals("V2", clone.getJobDataMap().get("K2"));
        
        // // Make sure sub-object collections have really been cloned by ensuring 
        // // their modification does not change the source Trigger 
        // clone.getJobDataMap().remove("K1");
        // assertEquals(1, clone.getJobDataMap().size());
        
        // assertEquals(2, simpleTrigger.getJobDataMap().size());
        // assertEquals("V1", simpleTrigger.getJobDataMap().get("K1"));
        // assertEquals("V2", simpleTrigger.getJobDataMap().get("K2"));
    }
    
    // NPE in equals()
    void testQuartz665() {
        new SimpleTriggerImpl().opEquals(new SimpleTriggerImpl());
    }
    
    void testMisfireInstructionValidity(){
        SimpleTriggerImpl trigger = new SimpleTriggerImpl();

        try {
            trigger.setMisfireInstruction(Trigger.MISFIRE_INSTRUCTION_IGNORE_MISFIRE_POLICY);
            trigger.setMisfireInstruction(Trigger.MISFIRE_INSTRUCTION_SMART_POLICY);
            trigger.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_FIRE_NOW);
            trigger.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_EXISTING_COUNT);
            trigger.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT);
            trigger.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_EXISTING_REPEAT_COUNT);
            trigger.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_REMAINING_REPEAT_COUNT);
        }
        catch(Exception e) {
            fail("Unexpected exception while setting misfire instruction: " ~ e.msg);
        }
        
        try {
            trigger.setMisfireInstruction(SimpleTrigger.MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_EXISTING_COUNT + 1);
            
            fail("Expected exception while setting invalid misfire instruction but did not get it.");
        }
        catch(Exception e) {
        }
    }

    
    // execute with version number to generate a new version's serialized form
    // static void main(string[] args){
    //     new SimpleTriggerTest().writeJobDataFile("2.0");
    // }
    
}
