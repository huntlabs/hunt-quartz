module test.quartz.DbSchedulerTest;

import test.quartz.SchedulerTestBase;

import hunt.quartz.dbstore.JobStoreTX;
import hunt.quartz.impl.DirectSchedulerFactory;
import hunt.quartz.impl.SchedulerRepository;

// import hunt.quartz.impl.StdSchedulerFactory;
import hunt.quartz.simpl.SimpleThreadPool;
import hunt.quartz.Scheduler;

import hunt.entity;

import core.thread;
import std.conv;

class DbSchedulerTest : SchedulerTestBase {

    override protected Scheduler createScheduler(string name, int threadPoolSize) {
        // return null;
        // try {
        //     JdbcQuartzTestUtilities.createDatabase(name ~ "Database");
        // } catch (SQLException e) {
        //     throw new AssertionError(e);
        // }

        JobStoreTX jobStore = new JobStoreTX();
        jobStore.setDataSource(name ~ "Database");
        jobStore.setEntityOption(getOption());
        jobStore.setTablePrefix("QRTZ_");
        jobStore.setInstanceId("AUTO");
        DirectSchedulerFactory.getInstance().createScheduler(name ~ "Scheduler", "AUTO",
                new SimpleThreadPool(threadPoolSize, Thread.PRIORITY_DEFAULT), jobStore);
        return SchedulerRepository.getInstance().lookup(name ~ "Scheduler");
    }


    EntityOption getOption() {
        EntityOption option = new EntityOption();
        option.database.driver = "postgresql";
        option.database.host = "10.1.11.44";
        option.database.port = 5432;
        option.database.database = "quartz_test";
        option.database.username = "postgres";
        option.database.password = "123456";
        return option;
    }
}
