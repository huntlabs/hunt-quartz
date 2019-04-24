import hunt.concurrency.thread;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;

import std.stdio;

import test.quartz.AnnualCalendarTest;
import test.quartz.CronExpressionTest;
import test.quartz.CronTriggerTest;
import test.quartz.RAMSchedulerTest;
import test.quartz.SimpleTriggerTest;
import test.quartz.VersionTest;

import test.quartz.DbSchedulerTest;

import test.quartz.utils.PropertiesParserTest;

import hunt.time;

void main()
{
	// testUnits!(AnnualCalendarTest);
	testUnits!(CronExpressionTest);
	// testUnits!(CronTriggerTest);
	// testUnits!(DbSchedulerTest);
	// testUnits!(RAMSchedulerTest);
	// testUnits!(SimpleTriggerTest);
	// testUnits!(VersionTest);

	// Test test.quartz.utils.*
	// testUnits!(PropertiesParserTest);

	// // LocalDateTime ldt = LocalDateTime.of(2019, 4, 23, 17, 59, 57);
	// LocalDateTime ldt = LocalDateTime.of(2019, 4, 25, 17, 59, 57);
	// LocalDateTime ldt2 = LocalDateTime.now;
	// trace(ldt.toString());
	// trace(ldt2.toString());

	// tracef("ldt: %d, now: %d", ldt.toEpochMilli(), ldt2.toEpochMilli());

	// trace(ldt2.isAfter(ldt));
}
