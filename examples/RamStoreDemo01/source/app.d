import std.stdio;

import hunt.quartz;
import hunt.time;

import witchcraft;
import hunt.logging.ConsoleLogger;

void main() {

	SchedulerFactory sf = new StdSchedulerFactory();
	Scheduler scheduler = sf.getScheduler();
	
	
	JobDetail job = JobBuilder.newJob(RAMJob.classinfo)
			.withDescription("this is a ram job") 
			.withIdentity("ramJob", "ramGroup") 
			.usingJobData("jobDetail1", "job's data")
			.build();
	JobDataMap dataMap = job.getJobDataMap();
	dataMap.putAsString("url", "http://127.0.0.1");
	
	LocalDateTime statTime = LocalDateTime.now; 
	statTime.plusSeconds(3);
	
	Trigger t = newTrigger!Trigger()
				.withDescription("Demo for RAM store")
				.withIdentity("ramTrigger", "ramTriggerGroup")
				.usingJobData("trigger1", "trigger1's data")
				.withSchedule(SimpleScheduleBuilder.simpleSchedule())
				.startAt(statTime)  
				.withSchedule(CronScheduleBuilder.cronSchedule("0/2 * * * * ?")) 
				.build();
	
	scheduler.scheduleJob(job, t);
	
	scheduler.start();
	info("Launched");
	// import core.thread;
	// thread_joinAll();
}


class RAMJob : Job {
	
    mixin Witchcraft;

	public void execute(JobExecutionContext context) {
		info("Say hello to Quartz ");
		trace(context.getJobDetail().getJobDataMap().get("jobDetail1"));
		trace(context.getTrigger().getJobDataMap().get("trigger1"));


        JobDetail job = context.getJobDetail();
        JobDataMap dataMap = job.getJobDataMap();
		string url = dataMap.getString("url");
		info("url=", url);

		info("execute done.");
	}
	
}