module test.quartz.RAMSchedulerTest;

import hunt.quartz.impl.StdSchedulerFactory;
import hunt.quartz.Scheduler;
import std.conv;


import test.quartz.SchedulerTestBase;

class RAMSchedulerTest : SchedulerTestBase{

    override protected Scheduler createScheduler(string name, int threadPoolSize) 
    {
        string[string] config;
        config["hunt.quartz.scheduler.instanceName"] = name ~ "Scheduler";
        config["hunt.quartz.scheduler.instanceId"] = "AUTO";
        config["hunt.quartz.threadPool.threadCount"] = threadPoolSize.to!string();
        config["hunt.quartz.threadPool.class"] = "hunt.quartz.simpl.SimpleThreadPool.SimpleThreadPool";
        return new StdSchedulerFactory(config).getScheduler();
    }
}

    