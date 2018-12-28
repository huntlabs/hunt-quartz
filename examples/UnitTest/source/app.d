import hunt.concurrent.thread;
import hunt.logging;
import hunt.util.UnitTest;

import std.stdio;

import test.quartz.CronExpressionTest;
import test.quartz.VersionTest;

void main()
{
	testUnits!(CronExpressionTest);
	// testUnits!(VersionTest);
}
