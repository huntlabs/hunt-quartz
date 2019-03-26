module test.quartz.DbSchedulerTest;

import hunt.quartz.dbstore.JobStoreTX;
import hunt.quartz.impl.DirectSchedulerFactory;
import hunt.quartz.impl.SchedulerRepository;
// import hunt.quartz.impl.StdSchedulerFactory;
import hunt.quartz.simpl.SimpleThreadPool;
import hunt.quartz.Scheduler;

import core.thread;
import std.conv;

import test.quartz.SchedulerTestBase;

class DbSchedulerTest : SchedulerTestBase{

    override protected Scheduler createScheduler(string name, int threadPoolSize) 
    {
        // return null;
        // try {
        //     JdbcQuartzTestUtilities.createDatabase(name ~ "Database");
        // } catch (SQLException e) {
        //     throw new AssertionError(e);
        // }
        JobStoreTX jobStore = new JobStoreTX();
        jobStore.setDataSource(name ~ "Database");
        jobStore.setTablePrefix("QRTZ_");
        jobStore.setInstanceId("AUTO");
        DirectSchedulerFactory.getInstance().createScheduler(name ~ "Scheduler", "AUTO", 
            new SimpleThreadPool(threadPoolSize, Thread.PRIORITY_DEFAULT), jobStore);
        return SchedulerRepository.getInstance().lookup(name ~ "Scheduler");
    }
}
