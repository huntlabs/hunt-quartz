import std.stdio;

import hunt.quartz;
import hunt.time;

import witchcraft;
import hunt.logging.ConsoleLogger;

void main() {

	SchedulerFactory sf = new StdSchedulerFactory();
	Scheduler scheduler = sf.getScheduler();
	
	
	JobDetail jb = JobBuilder.newJob(RAMJob.classinfo)
			.withDescription("this is a ram job") 
			.withIdentity("ramJob", "ramGroup") 
			.build();
	
	LocalDateTime statTime = LocalDateTime.now; 
	statTime.plusSeconds(3);
	
	Trigger t = TriggerBuilderHelper.newTrigger!Trigger()
				.withDescription("Demo for RAM store")
				.withIdentity("ramTrigger", "ramTriggerGroup")
				.withSchedule(SimpleScheduleBuilder.simpleSchedule())
				.startAt(statTime)  
				.withSchedule(CronScheduleBuilder.cronSchedule("0/2 * * * * ?")) 
				.build();
	
	scheduler.scheduleJob(jb, t);
	
	scheduler.start();
	info("Launched");
	// import core.thread;
	// thread_joinAll();
}


class RAMJob : Job {
	
    mixin Witchcraft;

	public void execute(JobExecutionContext context) {
		
		info("Say hello to Quartz ");
	}
	
}