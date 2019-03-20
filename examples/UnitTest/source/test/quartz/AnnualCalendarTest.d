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
module test.quartz.AnnualCalendarTest;

// import java.util.Calendar;
// import java.util.Locale;
// import java.util.TimeZone;

import hunt.quartz.impl.calendar.AnnualCalendar;

import hunt.time.Constants;
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


/**
 * Unit test for AnnualCalendar serialization backwards compatibility.
 */
public class AnnualCalendarTest {
    private enum string[] VERSIONS = ["1.5.1"];
    
    private __gshared ZoneId EST_TIME_ZONE;

    shared static this() {
        EST_TIME_ZONE = ZoneRegion.of("America/New_York");  
    }


    /**
     * Get the object to serialize when generating serialized file for future
     * tests, and against which to validate deserialized object.
     */
    
    // protected Object getTargetObject() {
    //     AnnualCalendar c = new AnnualCalendar();
    //     c.setDescription("description");
        
    //     LocalDateTime cal = LocalDateTime.of(2005, Month.JANUARY, 20, 10, 5, 15);
        
    //     c.setDayExcluded(cal, true);
        
    //     return c;
    // }
    
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
    //     AnnualCalendar targetCalendar = (AnnualCalendar)target;
    //     AnnualCalendar deserializedCalendar = (AnnualCalendar)deserialized;
        
    //     assertNotNull(deserializedCalendar);
    //     assertEquals(targetCalendar.getDescription(), deserializedCalendar.getDescription());
    //     assertEquals(targetCalendar.getDaysExcluded(), deserializedCalendar.getDaysExcluded());
    //     assertNull(deserializedCalendar.getTimeZone());
    // }

    /**
     * Tests if method <code>setDaysExcluded</code> protects the property daysExcluded against nulling.
     * See: QUARTZ-590
     */
    public void testDaysExcluded() {
		AnnualCalendar annualCalendar = new AnnualCalendar();
		
		annualCalendar.setDaysExcluded(null);
		
		assertNotNull("Annual calendar daysExcluded property should have been set to empty ArrayList, not null.",
            annualCalendar.getDaysExcluded());
    }

    /**
     * Tests the parameter <code>exclude</code> in a method <code>setDaysExcluded</code>
     * of class <code>org.quartz.impl.calendar.AnnualCalendar</code>
     */
    public void testExclude() {
        AnnualCalendar annualCalendar = new AnnualCalendar();

        LocalDateTime day = LocalDateTime.now();
        day = day.withMonth(10).withDayOfMonth(15);
        annualCalendar.setDayExcluded(day, false);

        assertTrue("The day 15 October is not expected to be excluded but it is", !annualCalendar.isDayExcluded(day));

        day = day.withMonth(10).withDayOfMonth(15);
        annualCalendar.setDayExcluded(day, true);

        day = day.withMonth(11).withDayOfMonth(12);
        annualCalendar.setDayExcluded(day, true);

        day = day.withMonth(9).withDayOfMonth(1);
        annualCalendar.setDayExcluded(day, true);

        assertTrue("The day 15 October is expected to be excluded but it is not", annualCalendar.isDayExcluded(day));

        day = day.withMonth(10).withDayOfMonth(15);
        annualCalendar.setDayExcluded(day, false);

        assertTrue("The day 15 October is not expected to be excluded but it is", !annualCalendar.isDayExcluded(day));
    }

    /**
     * QUARTZ-679 Test if the annualCalendar works over years
     */
    public void testDaysExcludedOverTime() {
        AnnualCalendar annualCalendar = new AnnualCalendar();
        LocalDateTime day = LocalDateTime.now();
        
        day = day.withYear(2005).withMonth(MonthCode.JUNE).withDayOfMonth(23);
        annualCalendar.setDayExcluded(day, true);
        
        day = day.withYear(2008).withMonth(MonthCode.FEBRUARY).withDayOfMonth(1);
        annualCalendar.setDayExcluded(day, true);
 
    	assertTrue("The day 1 February is expected to be excluded but it is not", annualCalendar.isDayExcluded(day));    	
    }

    /**
     * Part 2 of the tests of QUARTZ-679
     */
    public void testRemoveInTheFuture() {
        AnnualCalendar annualCalendar = new AnnualCalendar();
        LocalDateTime day = LocalDateTime.now();
        
        day = day.withYear(2005).withMonth(MonthCode.JUNE).withDayOfMonth(23);
        annualCalendar.setDayExcluded(day, true);

    	// Trying to remove the 23th of June
        day = day.withYear(2008).withMonth(MonthCode.JUNE).withDayOfMonth(23);
        annualCalendar.setDayExcluded(day, false);
        
        assertTrue("The day 23 June is not expected to be excluded but it is", ! annualCalendar.isDayExcluded(day));
    }

}
