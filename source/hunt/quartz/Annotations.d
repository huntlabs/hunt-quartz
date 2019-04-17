module hunt.quartz.Annotations;

/**
 * An annotation that marks a {@link Job} class as one that must not have multiple
 * instances executed concurrently (where instance is based-upon a {@link JobDetail} 
 * definition - or in other words based upon a {@link JobKey}).
 *
 * @see PersistJobDataAfterExecution
 * 
 * @author jhouse
 */
interface DisallowConcurrentExecution {
}

/**
 * An annotation that marks a {@link Job} class as one that makes updates to its
 * {@link JobDataMap} during execution, and wishes the scheduler to re-store the
 * <code>JobDataMap</code> when execution completes. 
 *   
 * <p>Jobs that are marked with this annotation should also seriously consider
 * using the {@link DisallowConcurrentExecution} annotation, to avoid data
 * storage race conditions with concurrently executing job instances.</p>
 *
 * @see DisallowConcurrentExecution
 * 
 * @author jhouse
 */
interface PersistJobDataAfterExecution {
}
