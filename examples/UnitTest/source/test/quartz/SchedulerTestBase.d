module test.quartz.SchedulerTestBase;


import hunt.quartz.exception;
import hunt.quartz.impl.matchers.GroupMatcher;
import hunt.quartz.impl.StdScheduler;
import hunt.quartz.impl.StdSchedulerFactory;
import hunt.quartz.Job;
import hunt.quartz.JobBuilder;
import hunt.quartz.JobDetail;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobKey;
import hunt.quartz.Scheduler;
import hunt.quartz.SchedulerContext;
import hunt.quartz.SimpleScheduleBuilder;
import hunt.quartz.StatefulJob;
import hunt.quartz.Trigger;
import hunt.quartz.TriggerBuilder;
import hunt.quartz.TriggerKey;
import hunt.quartz.spi.OperableTrigger;

import hunt.Assert;
import hunt.collection.ArrayList;
import hunt.collection.HashSet;
import hunt.collection.List;
import hunt.collection.Map;
import hunt.collection.Set;
import hunt.concurrency.thread;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.DateTime;
import hunt.util.Traits;
import hunt.util.UnitTest;

import std.conv;
import core.atomic;
import core.thread;
import core.sync.barrier;

alias jobKey = JobKey.jobKey;
alias simpleSchedule = SimpleScheduleBuilder.simpleSchedule;
alias triggerKey = TriggerKey.triggerKey;

alias assertTrue = Assert.assertTrue;
alias assertFalse = Assert.assertFalse;
alias assertThat = Assert.assertThat;
alias assertEquals = Assert.assertEquals;
alias assertNotNull = Assert.assertNotNull;
alias assertNull = Assert.assertNull;
alias fail = Assert.fail;



enum string BARRIER = "BARRIER";
enum string DATE_STAMPS = "DATE_STAMPS";
enum string JOB_THREAD = "JOB_THREAD";

enum TEST_TIMEOUT_SECONDS = 125;


class SchedulerTestBase {

    protected abstract Scheduler createScheduler(string name, int threadPoolSize);

    @Test
    void testBasicStorageFunctions(){
        Scheduler sched = createScheduler("testBasicStorageFunctions", 2);

        // test basic storage functions of scheduler...
        info("Cleanup test data....");
        sched.deleteJob(jobKey("j1"));
        sched.deleteJob(jobKey("j2", "g1"));
        sched.deleteJob(jobKey("j3", "g1"));
        sched.deleteJob(jobKey("j4", "g1"));
        info("Cleanup done.");
        
        JobDetail job = JobBuilder.newJob()
            .ofType(typeid(TestJob))
            .withIdentity("j1")
            .storeDurably()
            .build();

        assertFalse("Unexpected existence of job named 'j1'.", 
            sched.checkExists(jobKey("j1")));

        sched.addJob(job, false); 
        assertTrue("Expected existence of job named 'j1' but checkExists return false.", 
            sched.checkExists(jobKey("j1")));

        job = sched.getJobDetail(jobKey("j1"));
        assertNotNull("Stored job not found!", job);
        
        sched.deleteJob(jobKey("j1"));
        
        Trigger trigger = TriggerBuilderHelper.newTrigger!Trigger()
            .withIdentity("t1")
            .forJob(job)
            .startNow()
            .withSchedule(simpleSchedule()
                    .repeatForever()
                    .withIntervalInSeconds(5))
             .build();

        assertFalse("Unexpected existence of trigger named '11'.", sched.checkExists(triggerKey("t1")));

        sched.scheduleJob(job, trigger);
        
        assertTrue("Expected existence of trigger named 't1' but checkExists return false.", 
            sched.checkExists(triggerKey("t1")));

        job = sched.getJobDetail(jobKey("j1"));
        assertNotNull("Stored job not found!", job);
        
        trigger = sched.getTrigger(triggerKey("t1"));
        assertNotNull("Stored trigger not found!", trigger);


        job = JobBuilder.newJob()
            .ofType(typeid(TestJob))
            .withIdentity("j2", "g1")
            .build();
    
        trigger = TriggerBuilderHelper.newTrigger!Trigger()
            .withIdentity("t2", "g1")
            .forJob(job)
            .startNow()
            .withSchedule(simpleSchedule()
                    .repeatForever()
                    .withIntervalInSeconds(5))
             .build();

        sched.scheduleJob(job, trigger);
        
        job = JobBuilder.newJob()
            .ofType(typeid(TestJob))
            .withIdentity("j3", "g1")
            .build();
    
        trigger = TriggerBuilderHelper.newTrigger!Trigger()
            .withIdentity("t3", "g1")
            .forJob(job)
            .startNow()
            .withSchedule(simpleSchedule()
                    .repeatForever()
                    .withIntervalInSeconds(5))
             .build();
    
        sched.scheduleJob(job, trigger);
        
                
        List!(string) jobGroups = sched.getJobGroupNames();
        List!(string) triggerGroups = sched.getTriggerGroupNames();
        
        assertTrue("Job group list size expected to be = 2 ", jobGroups.size() == 2);
        assertTrue("Trigger group list size expected to be = 2 ", triggerGroups.size() == 2);
        
        Set!(JobKey) jobKeys = sched.getJobKeys(GroupMatcherHelper.jobGroupEquals(JobKey.DEFAULT_GROUP));
        Set!(TriggerKey) triggerKeys = 
            sched.getTriggerKeys(GroupMatcherHelper.triggerGroupEquals(TriggerKey.DEFAULT_GROUP));

        assertTrue("Number of jobs expected in default group was 1 ", jobKeys.size() == 1);
        assertTrue("Number of triggers expected in default group was 1 ", triggerKeys.size() == 1);

        jobKeys = sched.getJobKeys(GroupMatcherHelper.jobGroupEquals("g1"));
        triggerKeys = sched.getTriggerKeys(GroupMatcherHelper.triggerGroupEquals("g1"));

        assertTrue("Number of jobs expected in 'g1' group was 2 ", jobKeys.size() == 2);
        assertTrue("Number of triggers expected in 'g1' group was 2 ", triggerKeys.size() == 2);

        
        TriggerState s = sched.getTriggerState(triggerKey("t2", "g1"));
        assertTrue("State of trigger t2 expected to be NORMAL ", s == TriggerState.NORMAL);
        
        sched.pauseTrigger(triggerKey("t2", "g1"));
        s = sched.getTriggerState(triggerKey("t2", "g1"));
        assertTrue("State of trigger t2 expected to be PAUSED ", s == TriggerState.PAUSED);

        sched.resumeTrigger(triggerKey("t2", "g1"));
        s = sched.getTriggerState(triggerKey("t2", "g1"));
        assertTrue("State of trigger t2 expected to be NORMAL ", s == TriggerState.NORMAL);

        Set!(string) pausedGroups = sched.getPausedTriggerGroups();
        assertTrue("Size of paused trigger groups list expected to be 0 ", pausedGroups.size() == 0);
        
        sched.pauseTriggers(GroupMatcherHelper.triggerGroupEquals("g1"));
        
        // test that adding a trigger to a paused group causes the new trigger to be paused also... 
        job = JobBuilder.newJob()
            .ofType(typeid(TestJob))
            .withIdentity("j4", "g1")
            .build();
    
        trigger = TriggerBuilderHelper.newTrigger!Trigger()
            .withIdentity("t4", "g1")
            .forJob(job)
            .startNow()
            .withSchedule(simpleSchedule()
                    .repeatForever()
                    .withIntervalInSeconds(5))
             .build();
    
        sched.scheduleJob(job, trigger);

        pausedGroups = sched.getPausedTriggerGroups();
        assertTrue("Size of paused trigger groups list expected to be 1 ", pausedGroups.size() == 1);

        s = sched.getTriggerState(triggerKey("t2", "g1"));
        assertTrue("State of trigger t2 expected to be PAUSED ", s == TriggerState.PAUSED);

        s = sched.getTriggerState(triggerKey("t4", "g1"));
        assertTrue("State of trigger t4 expected to be PAUSED ", s == TriggerState.PAUSED);
        
        sched.resumeTriggers(GroupMatcherHelper.triggerGroupEquals("g1"));
        s = sched.getTriggerState(triggerKey("t2", "g1"));
        assertTrue("State of trigger t2 expected to be NORMAL ", s == TriggerState.NORMAL);
        s = sched.getTriggerState(triggerKey("t4", "g1"));
        assertTrue("State of trigger t4 expected to be NORMAL ", s == TriggerState.NORMAL);
        pausedGroups = sched.getPausedTriggerGroups();
        assertTrue("Size of paused trigger groups list expected to be 0 ", pausedGroups.size() == 0);

        
        assertFalse("Scheduler should have returned 'false' from attempt to unschedule non-existing trigger. ", 
            sched.unscheduleJob(triggerKey("foasldfksajdflk")));

        assertTrue("Scheduler should have returned 'true' from attempt to unschedule existing trigger. ", 
            sched.unscheduleJob(triggerKey("t3", "g1")));
        
        jobKeys = sched.getJobKeys(GroupMatcherHelper.jobGroupEquals("g1"));
        triggerKeys = sched.getTriggerKeys(GroupMatcherHelper.triggerGroupEquals("g1"));

        // job should have been deleted also, because it is non-durable
        assertTrue("Number of jobs expected in 'g1' group was 1 ", jobKeys.size() == 2); 
        assertTrue("Number of triggers expected in 'g1' group was 1 ", triggerKeys.size() == 2);

        assertTrue("Scheduler should have returned 'true' from attempt to unschedule existing trigger. ", 
            sched.unscheduleJob(triggerKey("t1")));
        
        jobKeys = sched.getJobKeys(GroupMatcherHelper.jobGroupEquals(JobKey.DEFAULT_GROUP));
        triggerKeys = sched.getTriggerKeys(GroupMatcherHelper.triggerGroupEquals(TriggerKey.DEFAULT_GROUP));

        // job should have been left in place, because it is non-durable
        assertTrue("Number of jobs expected in default group was 1 ", jobKeys.size() == 1); 
        assertTrue("Number of triggers expected in default group was 0 ", triggerKeys.size() == 0);

        sched.shutdown(true);
    }
    
    @Test
    void testDurableStorageFunctions(){
        Scheduler sched = createScheduler("testDurableStorageFunctions", 2);
        info("Cleanup test data....");
        sched.deleteJob(jobKey("j1"));
        sched.deleteJob(jobKey("j2"));
        info("Cleanup done.");

        try {
            // test basic storage functions of scheduler...

            JobDetail job = JobBuilder.newJob()
                    .ofType(typeid(TestJob))
                    .withIdentity("j1")
                    .storeDurably()
                    .build();

            assertFalse("Unexpected existence of job named 'j1'.", sched.checkExists(jobKey("j1")));

            sched.addJob(job, false);

            assertTrue("Unexpected non-existence of job named 'j1'.", sched.checkExists(jobKey("j1")));

            JobDetail nonDurableJob = JobBuilder.newJob()
                    .ofType(typeid(TestJob))
                    .withIdentity("j2")
                    .build();

            try {
                sched.addJob(nonDurableJob, false);
                fail("Storage of non-durable job should not have succeeded.");
            }
            catch(SchedulerException expected) {
                assertFalse("Unexpected existence of job named 'j2'.", sched.checkExists(jobKey("j2")));
            }

            sched.addJob(nonDurableJob, false, true);

            assertTrue("Unexpected non-existence of job named 'j2'.", sched.checkExists(jobKey("j2")));
        } finally {
            sched.shutdown(true);
        }
    }

    // @Test
    // void testShutdownWithSleepReturnsAfterAllThreadsAreStopped(){
    //    // TODO: Tasks pending completion -@zxp at 3/8/2019, 11:07:16 AM
    //    // 
    //   Map!(Thread, StackTraceElement[]) allThreadsStart = Thread.getAllStackTraces();
    //   int threadPoolSize = 5;
    //   Scheduler scheduler = createScheduler("testShutdownWithSleepReturnsAfterAllThreadsAreStopped", threadPoolSize);
      
    //   Thread.sleep(500L);
      
    //   Map!(Thread, StackTraceElement[]) allThreadsRunning = Thread.getAllStackTraces();

    //   scheduler.shutdown( true );
      
    //   Thread.sleep(200L);

    //   Map!(Thread, StackTraceElement[]) allThreadsEnd = Thread.getAllStackTraces();
    //   Set!(Thread) endingThreads = new HashSet!(Thread)(allThreadsEnd.keySet());
    //   // remove all pre-existing threads from the set
    //   foreach(Thread t; allThreadsStart.byKey()) {
    //     allThreadsEnd.remove(t);
    //   }
    //   // remove threads that are known artifacts of the test
    //   for(Thread t: endingThreads) {
    //     if(t.getName().contains("derby") && t.getThreadGroup().getName().contains("derby")) {
    //       allThreadsEnd.remove(t);
    //     }
    //     if(t.getThreadGroup() != null && t.getThreadGroup().getName().equals("system")) {
    //       allThreadsEnd.remove(t);
          
    //     }
    //     if(t.getThreadGroup() != null && t.getThreadGroup().getName().equals("main")) {
    //       allThreadsEnd.remove(t);
    //     }
    //   }
    //   if(allThreadsEnd.size() > 0) {
    //     // log the additional threads
    //     for(Thread t: allThreadsEnd.keySet()) {
    //       trace("*** Found additional thread: " ~ t.getName() ~ " (of type " ~ t.getClass().getName() +")  in group: " ~ t.getThreadGroup().getName() ~ " with parent group: " ~ (t.getThreadGroup().getParent() == null ? "-none-" : t.getThreadGroup().getParent().getName()));
    //     }          
    //     // log all threads that were running before shutdown
    //     for(Thread t: allThreadsRunning.keySet()) {
    //       trace("- Test runtime thread: " ~ t.getName() ~ " (of type " ~ t.getClass().getName() +")  in group: " ~ (t.getThreadGroup() == null ? "-none-" : (t.getThreadGroup().getName() ~ " with parent group: " ~ (t.getThreadGroup().getParent() == null ? "-none-" : t.getThreadGroup().getParent().getName()))));
    //     }          
    //   }
    //   assertTrue( "Found unexpected new threads (see console output for listing)", allThreadsEnd.size() == 0  );
    // }
    
    @Test
    void testAbilityToFireImmediatelyWhenStartedBefore(){
    	
		List!(long) jobExecTimestamps = new ArrayList!(long)(); // Collections.synchronizedList(new ArrayList!(long)());
		Barrier barrier = new Barrier(2);
    	
        Scheduler sched = createScheduler("testAbilityToFireImmediatelyWhenStartedBefore", 5);
        sched.getContext().put(BARRIER, barrier);
        sched.getContext().put(DATE_STAMPS, cast(Object)jobExecTimestamps);
        sched.start();
        
        Thread.yield();
        
        sched.deleteJob(jobKey("job1"));

		JobDetail job1 = JobBuilder.newJob(typeid(TestJobWithSync)).withIdentity("job1").build();
		Trigger trigger1 = TriggerBuilderHelper.newTrigger!Trigger().forJob(job1).build(); 
		long sTime = DateTimeHelper.currentTimeMillis();
		
		sched.scheduleJob(job1, trigger1);
		
	    // barrier.await(TEST_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        barrier.wait();
	    sched.shutdown(true);
		long fTime = jobExecTimestamps.get(0);

		// This is dangerously subjective!  but what else to do?
		assertTrue("Immediate trigger did not fire within a reasonable amount of time.", (fTime - sTime  < 7000L));  
    }
    
    @Test
    void testAbilityToFireImmediatelyWhenStartedBeforeWithTriggerJob(){
    	
		List!(long) jobExecTimestamps = new ArrayList!(long)(); // Collections.synchronizedList
		Barrier barrier = new Barrier(2);
    	
        Scheduler sched = createScheduler("testAbilityToFireImmediatelyWhenStartedBeforeWithTriggerJob", 5);
        sched.getContext().put(BARRIER, barrier);
        sched.getContext().put(DATE_STAMPS, cast(Object)jobExecTimestamps);

        sched.start();
        
        // Thread.yield();
        sched.deleteJob(jobKey("job1"));
        JobDetail job1 = JobBuilder.newJob!(TestJobWithSync)().withIdentity("job1").storeDurably().build();
		sched.addJob(job1, false);
		
		long sTime = DateTimeHelper.currentTimeMillis();
		
		sched.triggerJob(job1.getKey());
	    barrier.wait();
	    sched.shutdown(true);

		long fTime = jobExecTimestamps.get(0);
		
        // This is dangerously subjective!  but what else to do?
		assertTrue("Immediate trigger did not fire within a reasonable amount of time.", (fTime - sTime  < 7000L)); 
    }
    
    @Test
    void testAbilityToFireImmediatelyWhenStartedAfter(){
    	
		List!(long) jobExecTimestamps = new ArrayList!(long)(); // Collections.synchronizedList(new ArrayList!(long)());
		Barrier barrier = new Barrier(2);
    	
        Scheduler sched = createScheduler("testAbilityToFireImmediatelyWhenStartedAfter", 5);
        sched.getContext().put(BARRIER, barrier);
        sched.getContext().put(DATE_STAMPS, cast(Object)jobExecTimestamps);
        
		JobDetail job1 = JobBuilder.newJob!(TestJobWithSync).withIdentity("job1").build();
		Trigger trigger1 = TriggerBuilderHelper.newTrigger!Trigger().forJob(job1).build(); 
		
		long sTime = DateTimeHelper.currentTimeMillis();
		
		sched.scheduleJob(job1, trigger1);
        sched.start();
        barrier.wait();
		
	    // barrier.await(TEST_TIMEOUT_SECONDS, TimeUnit.SECONDS);
	    sched.shutdown(true);

		long fTime = jobExecTimestamps.get(0);

		// This is dangerously subjective!  but what else to do?
		assertTrue("Immediate trigger did not fire within a reasonable amount of time.", (fTime - sTime  < 7000L));  
    }
    
    @Test
	void testScheduleMultipleTriggersForAJob(){
		// scheduler.deleteJob(jobKey("job", "group1"));
		JobDetail job = JobBuilder.newJob(typeid(TestJob)).withIdentity("job1", "group1").build();
		Trigger trigger1 = TriggerBuilderHelper.newTrigger!Trigger()
				.withIdentity("trigger1", "group1")
				.startNow()
				.withSchedule(
						SimpleScheduleBuilder.simpleSchedule().withIntervalInSeconds(1)
								.repeatForever())
				.build();
		Trigger trigger2 = TriggerBuilderHelper.newTrigger!Trigger()
				.withIdentity("trigger2", "group1")
				.startNow()
				.withSchedule(
						SimpleScheduleBuilder.simpleSchedule().withIntervalInSeconds(1)
								.repeatForever())
				.build();
		Set!(Trigger) triggersForJob = new HashSet!(Trigger)(); 
		triggersForJob.add(trigger1);
		triggersForJob.add(trigger2);
		
		Scheduler sched = createScheduler("testScheduleMultipleTriggersForAJob", 5);
		sched.scheduleJob(job,triggersForJob, true);
		
		List!(OperableTrigger) triggersOfJob = sched.getTriggersOfJob(job.getKey());
		assertEquals(2,triggersOfJob.size());
		assertTrue(triggersOfJob.contains(cast(OperableTrigger)trigger1));
		assertTrue(triggersOfJob.contains(cast(OperableTrigger)trigger2));
		
		sched.shutdown(true);
	}
    
    @Test
    void testShutdownWithoutWaitIsUnclean(){
        Barrier barrier = new Barrier(2);
        Scheduler scheduler = createScheduler("testShutdownWithoutWaitIsUnclean", 8);
        try {
            scheduler.deleteJob(jobKey("job"));
            scheduler.getContext().put(BARRIER, barrier);
            scheduler.start();

            scheduler.addJob(JobBuilder.newJob().ofType(typeid(UncleanShutdownJob))
                .withIdentity("job").storeDurably().build(), false);

            scheduler.scheduleJob(TriggerBuilderHelper.newTrigger!Trigger().forJob("job").startNow().build());
            while (scheduler.getCurrentlyExecutingJobs().isEmpty()) {
                Thread.sleep(50.msecs);
            }
        } finally {
            scheduler.shutdown(false);
        }
        
        barrier.wait();
        // barrier.await(TEST_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        
        // Thread jobThread = cast(Thread) scheduler.getContext().get(JOB_THREAD);
        // jobThread.join();
        // jobThread.join(TimeUnit.SECONDS.toMillis(TEST_TIMEOUT_SECONDS));
    }
    

    @Test
    void testShutdownWithWaitIsClean(){
        shared bool shutdown = false;
        List!(long) jobExecTimestamps = new ArrayList!(long)(); // Collections.synchronizedList(new ArrayList!(long)());
        Barrier barrier = new Barrier(2);
        Scheduler scheduler = createScheduler("testShutdownWithWaitIsClean", 8);
        try {
            scheduler.deleteJob(jobKey("job"));

            scheduler.getContext().put(BARRIER, barrier);
            scheduler.getContext().put(DATE_STAMPS, cast(Object)jobExecTimestamps);
            scheduler.start();
            scheduler.addJob(JobBuilder.newJob().ofType(typeid(TestJobWithSync))
                .withIdentity("job").storeDurably().build(), false);
            scheduler.scheduleJob(TriggerBuilderHelper.newTrigger!Trigger().forJob("job").startNow().build());
            while (scheduler.getCurrentlyExecutingJobs().isEmpty()) {
                Thread.sleep(50.msecs);
            }
        } finally {
            Thread t = new class ThreadEx {
                override
                void run() {
                    try {
                        scheduler.shutdown(true);
                        atomicStore(shutdown, true);
                    } catch (SchedulerException ex) {
                        throw new RuntimeException(ex);
                    }
                }
            };
            t.start();
            // Thread.sleep(1000.msecs);
            assertFalse(shutdown);
            barrier.wait();
            // barrier.await(TEST_TIMEOUT_SECONDS, TimeUnit.SECONDS);
            // t.join();
        }
    }    
}


    
class TestStatefulJob : StatefulJob {
    void execute(JobExecutionContext context){
        info("executing the job...");
    }
}

class TestJob : Job {
    void execute(JobExecutionContext context){
        info("executing the job...");
    }
}
    
class TestJobWithSync : Job {
    void execute(JobExecutionContext context){
        
        try {
            trace("executing a job...");
            List!(long) jobExecTimestamps = cast(List!(long))context.getScheduler().getContext().get(DATE_STAMPS);
            Barrier barrier =  cast(Barrier)context.getScheduler().getContext().get(BARRIER);
            jobExecTimestamps.add(DateTimeHelper.currentTimeMillis());
            barrier.wait();
            trace("a job executed.");
            // barrier.await(TEST_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        } catch (Throwable e) {
            error(e.msg);
            throw new AssertionError("Await on barrier was interrupted: " ~ e.msg);
        } 
    }
}
    
class TestAnnotatedJob : Job {
    void execute(JobExecutionContext context){
        info("executing the job...");
    }
}
    

class UncleanShutdownJob : Job {
    void execute(JobExecutionContext context){
        try {
            SchedulerContext schedulerContext = context.getScheduler().getContext();
            schedulerContext.put(JOB_THREAD, ThreadEx.currentThread());
            Barrier barrier =  cast(Barrier) schedulerContext.get(BARRIER);
            barrier.wait();
            // barrier.await(TEST_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        } catch (Throwable e) {
            error(e.msg);
            throw new AssertionError("Await on barrier was interrupted: " ~ e.msg);
        } 
    }
}