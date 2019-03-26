import hunt.concurrency.thread;
import hunt.logging;
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

void main()
{
	// testUnits!(AnnualCalendarTest);
	// testUnits!(CronExpressionTest);
	// testUnits!(CronTriggerTest);
	// testUnits!(DbSchedulerTest);
	testUnits!(RAMSchedulerTest);
	// testUnits!(SimpleTriggerTest);
	// testUnits!(VersionTest);

	// Test test.quartz.utils.*
	// testUnits!(PropertiesParserTest);
}
