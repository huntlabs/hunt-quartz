import hunt.concurrency.thread;
import hunt.logging;
import hunt.util.UnitTest;

import std.stdio;

import test.quartz.AnnualCalendarTest;
import test.quartz.CronExpressionTest;
import test.quartz.RAMSchedulerTest;
import test.quartz.VersionTest;

import test.quartz.utils.PropertiesParserTest;

void main()
{
	// testUnits!(AnnualCalendarTest);
	// testUnits!(CronExpressionTest);
	testUnits!(RAMSchedulerTest);
	// testUnits!(VersionTest);

	// Test test.quartz.utils.*
	// testUnits!(PropertiesParserTest);
}
