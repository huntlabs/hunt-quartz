module hunt.quartz.spi.OperableTrigger;

import hunt.quartz.spi.MutableTrigger;

import hunt.quartz.Calendar;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.Trigger;
import hunt.quartz.Exceptions;
import hunt.quartz.Scheduler;

import hunt.time.LocalDateTime;
import std.datetime;
import witchcraft.classes;

/**
*/
interface OperableTrigger : MutableTrigger, ClassAccessor { 
    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * Called when the <code>{@link Scheduler}</code> has decided to 'fire'
     * the trigger (execute the associated <code>Job</code>), in order to
     * give the <code>Trigger</code> a chance to update itself for its next
     * triggering (if any).
     * </p>
     * 
     * @see #executionComplete(JobExecutionContext, JobExecutionException)
     */
    void triggered(Calendar calendar);

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * Called by the scheduler at the time a <code>Trigger</code> is first
     * added to the scheduler, in order to have the <code>Trigger</code>
     * compute its first fire time, based on any associated calendar.
     * </p>
     * 
     * <p>
     * After this method has been called, <code>getNextFireTime()</code>
     * should return a valid answer.
     * </p>
     * 
     * @return the first time at which the <code>Trigger</code> will be fired
     *         by the scheduler, which is also the same value <code>getNextFireTime()</code>
     *         will return (until after the first firing of the <code>Trigger</code>).
     *         </p>
     */
    LocalDateTime computeFirstFireTime(Calendar calendar);

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * Called after the <code>{@link Scheduler}</code> has executed the
     * <code>{@link hunt.quartz.JobDetail}</code> associated with the <code>Trigger</code>
     * in order to get the final instruction code from the trigger.
     * </p>
     * 
     * @param context
     *          is the <code>JobExecutionContext</code> that was used by the
     *          <code>Job</code>'s!(code)execute(xx)</code> method.
     * @param result
     *          is the <code>JobExecutionException</code> thrown by the
     *          <code>Job</code>, if any (may be null).
     * @return one of the <code>CompletedExecutionInstruction</code> constants.
     * 
     * @see CompletedExecutionInstruction
     * @see #triggered(Calendar)
     */
    CompletedExecutionInstruction executionComplete(JobExecutionContext context, JobExecutionException result);

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * To be implemented by the concrete classes that extend this class.
     * </p>
     * 
     * <p>
     * The implementation should update the <code>Trigger</code>'s state
     * based on the MISFIRE_INSTRUCTION_XXX that was selected when the <code>Trigger</code>
     * was created.
     * </p>
     */
    void updateAfterMisfire(Calendar cal);

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * To be implemented by the concrete class.
     * </p>
     * 
     * <p>
     * The implementation should update the <code>Trigger</code>'s state
     * based on the given new version of the associated <code>Calendar</code>
     * (the state should be updated so that it's next fire time is appropriate
     * given the Calendar's new settings). 
     * </p>
     * 
     * @param cal
     */
    void updateWithNewCalendar(Calendar cal, long misfireThreshold);

    
    /**
     * <p>
     * Validates whether the properties of the <code>JobDetail</code> are
     * valid for submission into a <code>Scheduler</code>.
     * 
     * @throws IllegalStateException
     *           if a required property (such as Name, Group, Class) is not
     *           set.
     */
    void validate();
    

    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     * 
     * <p>
     * Usable by <code>{@link hunt.quartz.spi.JobStore}</code>
     * implementations, in order to facilitate 'recognizing' instances of fired
     * <code>Trigger</code> s as their jobs complete execution.
     * </p>
     * 
     *  
     */
    void setFireInstanceId(string id);
    
    /**
     * <p>
     * This method should not be used by the Quartz client.
     * </p>
     */
    string getFireInstanceId();

    
    void setNextFireTime(LocalDateTime nextFireTime);
    
    void setPreviousFireTime(LocalDateTime previousFireTime);
}