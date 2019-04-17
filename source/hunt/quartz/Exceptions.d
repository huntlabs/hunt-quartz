module hunt.quartz.Exceptions;

import hunt.Exceptions;

import hunt.quartz.Exceptions;
import hunt.quartz.JobDetail;
import hunt.quartz.Trigger;


class SchedulerException : Exception {
    mixin BasicExceptionCtors;


    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Return the exception that is the underlying cause of this exception.
     * </p>
     * 
     * <p>
     * This may be used to find more detail about the cause of the error.
     * </p>
     * 
     * @return the underlying exception, or <code>null</code> if there is not
     *         one.
     */
    Throwable getUnderlyingException() {
        return next();
    }

    override string toString() {
        Throwable cause = getUnderlyingException(); 
        if (cause is null || cause == this) {
            return super.toString();
        } else {
            return super.toString() ~ " [See nested exception: " ~ cause.toString() ~ "]";
        }
    }
}

class VetoedException : Exception {
    mixin BasicExceptionCtors;
}

class JobPersistenceException : SchedulerException {
    mixin BasicExceptionCtors;
}

class SchedulerConfigException : SchedulerException {
    mixin BasicExceptionCtors;
}

class UnableToInterruptJobException : SchedulerException {
    mixin BasicExceptionCtors;
}


class NoSuchDelegateException : JobPersistenceException {
    mixin BasicExceptionCtors;
}


class LockException : SchedulerException {
    mixin BasicExceptionCtors;
}

class JobExecutionException : SchedulerException {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private bool refire = false;

    private bool unscheduleTrigg = false;

    private bool unscheduleAllTriggs = false;

    mixin BasicExceptionCtors;

    /**
     * <p>
     * Create a JobExcecutionException with the 're-fire immediately' flag set
     * to the given value.
     * </p>
     */
    this(bool refireImmediately) {
        refire = refireImmediately;
    }

    /**
     * <p>
     * Create a JobExcecutionException with the given underlying exception, and
     * the 're-fire immediately' flag set to the given value.
     * </p>
     */
    this(Throwable cause, bool refireImmediately) {
        super(cause);

        refire = refireImmediately;
    }

    
    /**
     * <p>
     * Create a JobExcecutionException with the given message, and underlying
     * exception, and the 're-fire immediately' flag set to the given value.
     * </p>
     */
    this(string msg, Throwable cause, bool refireImmediately) {
        super(msg, cause);

        refire = refireImmediately;
    }
    
    /**
     * Create a JobExcecutionException with the given message and the 're-fire 
     * immediately' flag set to the given value.
     */
    this(string msg, bool refireImmediately) {
        super(msg);

        refire = refireImmediately;
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    void setRefireImmediately(bool refire) {
        this.refire = refire;
    }

    bool refireImmediately() {
        return refire;
    }

    void setUnscheduleFiringTrigger(bool unscheduleTrigg) {
        this.unscheduleTrigg = unscheduleTrigg;
    }

    bool unscheduleFiringTrigger() {
        return unscheduleTrigg;
    }

    void setUnscheduleAllTriggers(bool unscheduleAllTriggs) {
        this.unscheduleAllTriggs = unscheduleAllTriggs;
    }

    bool unscheduleAllTriggers() {
        return unscheduleAllTriggs;
    }

}

class ObjectStreamException : IOException {
    mixin BasicExceptionCtors;
}

class NotSerializableException : ObjectStreamException {
    mixin BasicExceptionCtors;
}


/**
 * An exception that is thrown to indicate that an attempt to store a new
 * object (i.e. <code>{@link hunt.quartz.JobDetail}</code>,<code>{@link Trigger}</code>
 * or <code>{@link Calendar}</code>) in a <code>{@link Scheduler}</code>
 * failed, because one with the same name & group already exists.
 * 
 * @author James House
 */
class ObjectAlreadyExistsException : JobPersistenceException {
  

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a <code>ObjectAlreadyExistsException</code> with the given
     * message.
     * </p>
     */
    this(string msg) {
        super(msg);
    }

    /**
     * <p>
     * Create a <code>ObjectAlreadyExistsException</code> and auto-generate a
     * message using the name/group from the given <code>JobDetail</code>.
     * </p>
     * 
     * <p>
     * The message will read: <BR>"Unable to store Job with name: '__' and
     * group: '__', because one already exists with this identification."
     * </p>
     */
    this(JobDetail offendingJob) {
        super("Unable to store Job : '" ~ offendingJob.getKey().toString()
                ~ "', because one already exists with this identification.");
    }

    /**
     * <p>
     * Create a <code>ObjectAlreadyExistsException</code> and auto-generate a
     * message using the name/group from the given <code>Trigger</code>.
     * </p>
     * 
     * <p>
     * The message will read: <BR>"Unable to store Trigger with name: '__' and
     * group: '__', because one already exists with this identification."
     * </p>
     */
    this(Trigger offendingTrigger) {
        super("Unable to store Trigger with name: '"
                ~ offendingTrigger.getKey().getName() ~ "' and group: '"
                ~ offendingTrigger.getKey().getGroup()
                ~ "', because one already exists with this identification.");
    }

}
