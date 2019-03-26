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
    void testDurableStorageFunctions(){
        Scheduler sched = createScheduler("testDurableStorageFunctions", 2);
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
        
        Thread.yield();

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
        
        Thread jobThread = cast(Thread) scheduler.getContext().get(JOB_THREAD);
        jobThread.join();
        // jobThread.join(TimeUnit.SECONDS.toMillis(TEST_TIMEOUT_SECONDS));
    }
    

    @Test
    void testShutdownWithWaitIsClean(){
        shared bool shutdown = false;
        List!(long) jobExecTimestamps = new ArrayList!(long)(); // Collections.synchronizedList(new ArrayList!(long)());
        Barrier barrier = new Barrier(2);
        Scheduler scheduler = createScheduler("testShutdownWithWaitIsClean", 8);
        try {
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
            Thread.sleep(1000.msecs);
            assertFalse(shutdown);
            barrier.wait();
            // barrier.await(TEST_TIMEOUT_SECONDS, TimeUnit.SECONDS);
            t.join();
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