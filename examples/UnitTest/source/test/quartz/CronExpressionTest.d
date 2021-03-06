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
module test.quartz.CronExpressionTest;


import hunt.quartz;
import hunt.time.LocalDateTime;
import hunt.time.Month;
import hunt.time.ZoneId;
import hunt.time.ZoneRegion;

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
alias fail = Assert.fail;

import std.conv;
import std.string;

class CronExpressionTest  { // : SerializationTestSupport
    private enum string[] VERSIONS = ["1.5.2"];

    private __gshared ZoneId EST_TIME_ZONE;

    shared static this() {
        EST_TIME_ZONE = ZoneRegion.of("US/Eastern");  
    }

    /**
     * Get the object to serialize when generating serialized file for future
     * tests, and against which to validate deserialized object.
     */
    
    protected Object getTargetObject() {
        CronExpression cronExpression = new CronExpression("0 15 10 * * ? 2005");
        cronExpression.setTimeZone(EST_TIME_ZONE);
        
        return cronExpression;
    }
    
    /**
     * Get the Quartz versions for which we should verify
     * serialization backwards compatibility.
     */
    
    protected string[] getVersions() {
        return VERSIONS;
    }

    /**
     * Verify that the target object and the object we just deserialized 
     * match.
     */
    
    // protected void verifyMatch(Object target, Object deserialized) {
    //     CronExpression targetCronExpression = cast(CronExpression)target;
    //     CronExpression deserializedCronExpression = cast(CronExpression)deserialized;
        
    //     assertNotNull(deserializedCronExpression);
    //     assertEquals(targetCronExpression.getCronExpression(), deserializedCronExpression.getCronExpression());
    //     assertEquals(targetCronExpression.getTimeZone(), deserializedCronExpression.getTimeZone());
    // }
    
    /*
     * Test method for 'org.quartz.CronExpression.isSatisfiedBy(Date)'.
     */
    void testIsSatisfiedBy() {
        CronExpression cronExpression = new CronExpression("0 15 10 * * ? 2005");
        
        LocalDateTime cal = LocalDateTime.of(2005, Month.JUNE, 1, 10, 15, 0);
        assertTrue(cronExpression.isSatisfiedBy(cal));
        
        cal = cal.withYear(2006);
        assertFalse(cronExpression.isSatisfiedBy(cal));

        cal = LocalDateTime.of(2005, Month.JUNE, 1, 10, 16, 0);
        assertFalse(cronExpression.isSatisfiedBy(cal));

        cal = LocalDateTime.of(2005, Month.JUNE, 1, 10, 14, 0);
        assertFalse(cronExpression.isSatisfiedBy(cal));
    }

    void testLastDayOffset() {
        CronExpression cronExpression = new CronExpression("0 15 10 L-2 * ? 2010");
        
        LocalDateTime cal = LocalDateTime.of(2010, Month.OCTOBER, 29, 10, 15, 0); // last day - 2
        assertTrue(cronExpression.isSatisfiedBy(cal));
        
        cal = LocalDateTime.of(2010, Month.OCTOBER, 28, 10, 15, 0);
        assertFalse(cronExpression.isSatisfiedBy(cal));
        
        cronExpression = new CronExpression("0 15 10 L-5W * ? 2010");
        
        cal = LocalDateTime.of(2010, Month.OCTOBER, 26, 10, 15, 0); // last day - 5
        assertTrue(cronExpression.isSatisfiedBy(cal));
        
        cronExpression = new CronExpression("0 15 10 L-1 * ? 2010");
        
        cal = LocalDateTime.of(2010, Month.OCTOBER, 30, 10, 15, 0); // last day - 1
        assertTrue(cronExpression.isSatisfiedBy(cal));
        
        cronExpression = new CronExpression("0 15 10 L-1W * ? 2010");
        
        cal = LocalDateTime.of(2010, Month.OCTOBER, 29, 10, 15, 0); // nearest weekday to last day - 1 (29th is a friday in 2010)
        assertTrue(cronExpression.isSatisfiedBy(cal));
        
    }

    /*
     * QUARTZ-571: Showing that expressions with months correctly serialize.
     */
    // void testQuartz571() {
    //     CronExpression cronExpression = new CronExpression("19 15 10 4 Apr ? ");

    //     ByteArrayOutputStream baos = new ByteArrayOutputStream();
    //     ObjectOutputStream oos = new ObjectOutputStream(baos);
    //     oos.writeObject(cronExpression);
    //     ByteArrayInputStream bais = new ByteArrayInputStream(baos.toByteArray());
    //     ObjectInputStream ois = new ObjectInputStream(bais);
    //     CronExpression newExpression = cast(CronExpression) ois.readObject();

    //     assertEquals(newExpression.getCronExpression(), cronExpression.getCronExpression());

    //     // if broken, this will throw an exception
    //     newExpression.getNextValidTimeAfter(new Date());
    // }

 	void testQtzSeconds() {
 		CronScheduleBuilder schedBuilder = CronScheduleBuilder.cronSchedule("0/6 * * * * ?");
 		Trigger trigger = TriggerBuilderHelper
            .newTrigger!Trigger()
            .withIdentity("test")
            .withSchedule(schedBuilder)
            .build();
 		
 		int i = 0;
 		LocalDateTime pdate = trigger.getFireTimeAfter(LocalDateTime.of(2019, 4, 25, 17, 59, 57));
 		while (++i < 5) {
 			LocalDateTime date = trigger.getFireTimeAfter(pdate);
 			trace("index: " ~ i.to!string() ~ ", fireTime: " ~ date.toString() ~ ", previousFireTime: " ~ pdate.toString());
 			assertFalse("Next fire time is the same as previous fire time!", pdate == date);
 			pdate = date;
 		}
 	}

    /**
     * QTZ-259 : last day offset causes repeating fire time
     * 
     */
 	void testQtz259() {
 		CronScheduleBuilder schedBuilder = CronScheduleBuilder.cronSchedule("0 0 0 L-2 * ? *");
 		Trigger trigger = TriggerBuilderHelper
            .newTrigger!Trigger()
            .withIdentity("test")
            .withSchedule(schedBuilder)
            .build();
 				
 		int i = 0;
 		LocalDateTime pdate = trigger.getFireTimeAfter(LocalDateTime.now());
 		while (++i < 26) {
 			LocalDateTime date = trigger.getFireTimeAfter(pdate);
 			trace("index: " ~ i.to!string() ~ ", fireTime: " ~ date.toString() ~ ", previousFireTime: " ~ pdate.toString());
 			assertFalse("Next fire time is the same as previous fire time!", pdate == date);
 			pdate = date;
 		}
 	}
    
    /**
     * QTZ-259 : last day offset causes repeating fire time
     * 
     */
 	void testQtz259LW() {
 		CronScheduleBuilder schedBuilder = CronScheduleBuilder.cronSchedule("0 0 0 LW * ? *");
 		Trigger trigger = TriggerBuilderHelper
            .newTrigger!Trigger()
            .withIdentity("test")
            .withSchedule(schedBuilder)
            .build();
 				
 		int i = 0;
 		LocalDateTime pdate = trigger.getFireTimeAfter(LocalDateTime.now());
 		while (++i < 26) {
 			LocalDateTime date = trigger.getFireTimeAfter(pdate);
 			trace("index: " ~ i.to!string() ~ ", fireTime: " ~ date.toString() ~ ", previousFireTime: " ~ pdate.toString());
 			assertFalse("Next fire time is the same as previous fire time!", pdate == date);
 			pdate = date;
 		}
 	}
 	
    /*
     * QUARTZ-574: Showing that storeExpressionVals correctly calculates the month number
     */
    void testQuartz574() {
        try {
            new CronExpression("* * * * Foo ? ");
            fail("Expected ParseException did not fire for non-existent month");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("Invalid Month value:"));
        }

        try {
            new CronExpression("* * * * Jan-Foo ? ");
            fail("Expected ParseException did not fire for non-existent month");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("Invalid Month value:"));
        }
    }

    void testQuartz621() {
        try {
            new CronExpression("0 0 * * * *");
            fail("Expected ParseException did not fire for wildcard day-of-month and day-of-week");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("Support for specifying both a day-of-week AND a day-of-month parameter is not implemented."));
        }
        try {
            new CronExpression("0 0 * 4 * *");
            fail("Expected ParseException did not fire for specified day-of-month and wildcard day-of-week");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("Support for specifying both a day-of-week AND a day-of-month parameter is not implemented."));
        }
        try {
            new CronExpression("0 0 * * * 4");
            fail("Expected ParseException did not fire for wildcard day-of-month and specified day-of-week");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("Support for specifying both a day-of-week AND a day-of-month parameter is not implemented."));
        }
    }

    void testQuartz640() {
        try {
            new CronExpression("0 43 9 1,5,29,L * ?");
            fail("Expected ParseException did not fire for L combined with other days of the month");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("Support for specifying 'L' and 'LW' with other days of the month is not implemented"));
        }
        try {
            new CronExpression("0 43 9 ? * SAT,SUN,L");
            fail("Expected ParseException did not fire for L combined with other days of the week");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("Support for specifying 'L' with other days of the week is not implemented"));
        }
        try {
            new CronExpression("0 43 9 ? * 6,7,L");
            fail("Expected ParseException did not fire for L combined with other days of the week");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("Support for specifying 'L' with other days of the week is not implemented"));
        }
        try {
            new CronExpression("0 43 9 ? * 5L");
        } catch(ParseException pe) {
            fail("Unexpected ParseException thrown for supported '5L' expression.");
        }
    }
    
    
    void testQtz96() {
        try {
            new CronExpression("0/5 * * 32W 1 ?");
            fail("Expected ParseException did not fire for W with value larger than 31");
        } catch(ParseException pe) {
            assertTrue("Incorrect ParseException thrown", 
                pe.msg.startsWith("The 'W' option does not make sense with values larger than"));
        }
    }

    void testQtz395_CopyConstructorMustPreserveTimeZone () {
        ZoneId nonDefault =  ZoneRegion.of("Europe/Brussels");
        if (nonDefault == ZoneRegion.systemDefault()) {
            nonDefault = EST_TIME_ZONE;
        }
        CronExpression cronExpression = new CronExpression("0 15 10 * * ? 2005");
        cronExpression.setTimeZone(nonDefault);

        CronExpression copyCronExpression = new CronExpression(cronExpression);
        assertEquals(nonDefault, copyCronExpression.getTimeZone());
    }

    // Issue #58
    void testSecRangeIntervalAfterSlash() {
        // Test case 1
        try {
            new CronExpression("/120 0 8-18 ? * 2-6");
            fail("Cron did not validate bad range interval in '_blank/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 60 : 120");
        }

        // Test case 2
        try {
            new CronExpression("0/120 0 8-18 ? * 2-6");
            fail("Cron did not validate bad range interval in in '0/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 60 : 120");
        }

        // Test case 3
        try {
            new CronExpression("/ 0 8-18 ? * 2-6");
            fail("Cron did not validate bad range interval in '_blank/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }

        // Test case 4
        try {
            new CronExpression("0/ 0 8-18 ? * 2-6");
            fail("Cron did not validate bad range interval in '0/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }
    }


    // Issue #58
    void testMinRangeIntervalAfterSlash() {
        // Test case 1
        try {
            new CronExpression("0 /120 8-18 ? * 2-6");
            fail("Cron did not validate bad range interval in '_blank/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 60 : 120");
        }

        // Test case 2
        try {
            new CronExpression("0 0/120 8-18 ? * 2-6");
            fail("Cron did not validate bad range interval in in '0/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 60 : 120");
        }

        // Test case 3
        try {
            new CronExpression("0 / 8-18 ? * 2-6");
            fail("Cron did not validate bad range interval in '_blank/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }

        // Test case 4
        try {
            new CronExpression("0 0/ 8-18 ? * 2-6");
            fail("Cron did not validate bad range interval in '0/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }
    }

    // Issue #58
    void testHourRangeIntervalAfterSlash() {
        // Test case 1
        try {
            new CronExpression("0 0 /120 ? * 2-6");
            fail("Cron did not validate bad range interval in '_blank/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 24 : 120");
        }

        // Test case 2
        try {
            new CronExpression("0 0 0/120 ? * 2-6");
            fail("Cron did not validate bad range interval in in '0/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 24 : 120");
        }

        // Test case 3
        try {
            new CronExpression("0 0 / ? * 2-6");
            fail("Cron did not validate bad range interval in '_blank/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }

        // Test case 4
        try {
            new CronExpression("0 0 0/ ? * 2-6");
            fail("Cron did not validate bad range interval in '0/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }
    }

    // Issue #58
    void testDayOfMonthRangeIntervalAfterSlash() {
        // Test case 1
        try {
            new CronExpression("0 0 0 /120 * 2-6");
            fail("Cron did not validate bad range interval in '_blank/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 31 : 120");
        }

        // Test case 2
        try {
            new CronExpression("0 0 0 0/120 * 2-6");
            fail("Cron did not validate bad range interval in in '0/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 31 : 120");
        }

        // Test case 3
        try {
            new CronExpression("0 0 0 / * 2-6");
            fail("Cron did not validate bad range interval in '_blank/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }

        // Test case 4
        try {
            new CronExpression("0 0 0 0/ * 2-6");
            fail("Cron did not validate bad range interval in '0/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }
    }

    // Issue #58
    void testMonthRangeIntervalAfterSlash() {
        // Test case 1
        try {
            new CronExpression("0 0 0 ? /120 2-6");
            fail("Cron did not validate bad range interval in '_blank/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 12 : 120");
        }

        // Test case 2
        try {
            new CronExpression("0 0 0 ? 0/120 2-6");
            fail("Cron did not validate bad range interval in in '0/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 12 : 120");
        }

        // Test case 3
        try {
            new CronExpression("0 0 0 ? / 2-6");
            fail("Cron did not validate bad range interval in '_blank/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }

        // Test case 4
        try {
            new CronExpression("0 0 0 ? 0/ 2-6");
            fail("Cron did not validate bad range interval in '0/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }
    }



    // Issue #58
    void testDayOfWeekRangeIntervalAfterSlash() {
        // Test case 1
        try {
            new CronExpression("0 0 0 ? * /120");
            fail("Cron did not validate bad range interval in '_blank/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 7 : 120");
        }

        // Test case 2
        try {
            new CronExpression("0 0 0 ? * 0/120");
            fail("Cron did not validate bad range interval in in '0/xxx' form");
        } catch (ParseException e) {
            assertEquals(e.msg, "Increment > 7 : 120");
        }

        // Test case 3
        try {
            new CronExpression("0 0 0 ? * /");
            fail("Cron did not validate bad range interval in '_blank/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }

        // Test case 4
        try {
            new CronExpression("0 0 0 ? * 0/");
            fail("Cron did not validate bad range interval in '0/_blank'");
        } catch (ParseException e) {
            assertEquals(e.msg, "'/' must be followed by an integer.");
        }
    }
}
