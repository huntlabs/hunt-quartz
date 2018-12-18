
module hunt.quartz.simpl.SystemPropertyInstanceIdGenerator;

import hunt.quartz.SchedulerException;
import hunt.quartz.spi.InstanceIdGenerator;

/**
 * InstanceIdGenerator that will use a {@link SystemPropertyInstanceIdGenerator#SYSTEM_PROPERTY system property}
 * to configure the scheduler.  The default system property name to use the value of {@link #SYSTEM_PROPERTY}, but
 * can be specified via the "systemPropertyName" property.
 * 
 * You can also set the properties "postpend" and "prepend" to string values that will be added to the beginning
 * or end (respectively) of the value found in the system property.
 * 
 * If no value set for the property, a {@link hunt.quartz.SchedulerException} is thrown
 *
 * @author Alex Snaps
 */
class SystemPropertyInstanceIdGenerator : InstanceIdGenerator {

  /**
   * System property to read the instanceId from
   */
  public enum string SYSTEM_PROPERTY = "hunt.quartz.scheduler.instanceId";

  private string prepend = null;
  private string postpend = null;
  private string systemPropertyName = SYSTEM_PROPERTY;
  
  /**
   * Returns the cluster wide value for this scheduler instance's id, based on a system property
   * @return the value of the system property named by the value of {@link #getSystemPropertyName()} - which defaults
   * to {@link #SYSTEM_PROPERTY}.
   * @throws SchedulerException Shouldn't a value be found
   */
  public string generateInstanceId() {
    string property = System.getProperty(getSystemPropertyName());
    if(property is null) {
      throw new SchedulerException("No value for '" ~ SYSTEM_PROPERTY
                                   ~ "' system property found, please configure your environment accordingly!");
    }
    if(getPrepend() !is null)
        property = getPrepend() + property;
    if(getPostpend() !is null)
        property = property + getPostpend();
    
    return property;
  }
  
  /**
   * A string of text to prepend (add to the beginning) to the instanceId 
   * found in the system property.
   */
  public string getPrepend() {
    return prepend;
  }

  /**
   * A string of text to prepend (add to the beginning) to the instanceId 
   * found in the system property.
   * 
   * @param prepend the value to prepend, or null if none is desired.
   */
  public void setPrepend(string prepend) {
    this.prepend = prepend is null ?  null  : prepend.trim();
  }
    
  /**
   * A string of text to postpend (add to the end) to the instanceId 
   * found in the system property.
   */
  public string getPostpend() {
    return postpend;
  }

  /**
   * A string of text to postpend (add to the end) to the instanceId 
   * found in the system property.
   * 
   * @param postpend the value to postpend, or null if none is desired.
   */
  public void setPostpend(string postpend) {
    this.postpend = postpend is null ?  null : postpend.trim();
  }

  /**
   * The name of the system property from which to obtain the instanceId.
   * 
   * Defaults to {@link #SYSTEM_PROPERTY}.
   * 
   */  
  public string getSystemPropertyName() {
    return systemPropertyName;
  }

  /**
   * The name of the system property from which to obtain the instanceId.
   * 
   * Defaults to {@link #SYSTEM_PROPERTY}.
   * 
   * @param systemPropertyName the system property name
   */
  public void setSystemPropertyName(string systemPropertyName) {
    this.systemPropertyName = systemPropertyName is null ? SYSTEM_PROPERTY : systemPropertyName.trim();
  }
  
} 
