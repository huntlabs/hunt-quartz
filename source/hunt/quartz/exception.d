module hunt.quartz.exception;

import hunt.lang.exception;


class JobPersistenceException : Exception {
    mixin BasicExceptionCtors;
}



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
        return super.getCause();
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
