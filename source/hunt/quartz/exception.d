module hunt.quartz.exception;

import hunt.Exceptions;


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