
/* 
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not 
 * use this file except in compliance with the License. You may obtain a copy 
 * of the License at 
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0 
 *   
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
 * License for the specific language governing permissions and limitations 
 * under the License.
 * 
 */

module hunt.quartz.impl.JobDetailImpl;

import hunt.quartz.DisallowConcurrentExecution;
import hunt.quartz.Job;
import hunt.quartz.JobBuilder;
import hunt.quartz.JobDataMap;
import hunt.quartz.JobDetail;
import hunt.quartz.JobExecutionContext;
import hunt.quartz.JobKey;
import hunt.quartz.PersistJobDataAfterExecution;
import hunt.quartz.Scheduler;
import hunt.quartz.StatefulJob;
import hunt.quartz.Trigger;
import hunt.quartz.utils.ClassUtils;

import hunt.lang.exception;

import std.array;
import std.conv;

/**
 * <p>
 * Conveys the detail properties of a given <code>Job</code> instance.
 * </p>
 * 
 * <p>
 * Quartz does not store an actual instance of a <code>Job</code> class, but
 * instead allows you to define an instance of one, through the use of a <code>JobDetail</code>.
 * </p>
 * 
 * <p>
 * <code>Job</code>s have a name and group associated with them, which
 * should uniquely identify them within a single <code>{@link Scheduler}</code>.
 * </p>
 * 
 * <p>
 * <code>Trigger</code>s are the 'mechanism' by which <code>Job</code>s
 * are scheduled. Many <code>Trigger</code>s can point to the same <code>Job</code>,
 * but a single <code>Trigger</code> can only point to one <code>Job</code>.
 * </p>
 * 
 * @see Job
 * @see StatefulJob
 * @see JobDataMap
 * @see Trigger
 * 
 * @author James House
 * @author Sharada Jambula
 */

class JobDetailImpl : JobDetail {

    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private string name;

    private string group = Scheduler.DEFAULT_GROUP;

    private string description;

    private TypeInfo_Class jobClass;

    private JobDataMap jobDataMap;

    private bool durability = false;

    private bool shouldRecover = false;

    private JobKey key = null;

    /*
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    *
    * Constructors.
    *
    * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */

    /**
     * <p>
     * Create a <code>JobDetail</code> with no specified name or group, and
     * the default settings of all the other properties.
     * </p>
     * 
     * <p>
     * Note that the {@link #setName(string)},{@link #setGroup(string)}and
     * {@link #setJobClass(Class)}methods must be called before the job can be
     * placed into a {@link Scheduler}
     * </p>
     */
    this() {
        // do nothing...
    }

    /**
     * <p>
     * Create a <code>JobDetail</code> with the given name, given class, default group, 
     * and the default settings of all the other properties.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty, or the group is an empty string.
     *              
     * @deprecated use {@link JobBuilder}              
     */
    this(string name, TypeInfo_Class jobClass) {
        this(name, null, jobClass);
    }

    /**
     * <p>
     * Create a <code>JobDetail</code> with the given name, group and class, 
     * and the default settings of all the other properties.
     * </p>
     * 
     * @param group if <code>null</code>, Scheduler.DEFAULT_GROUP will be used.
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty, or the group is an empty string.
     *              
     * @deprecated use {@link JobBuilder}              
     */
    this(string name, string group, TypeInfo_Class jobClass) {
        setName(name);
        setGroup(group);
        setJobClass(jobClass);
    }

    /**
     * <p>
     * Create a <code>JobDetail</code> with the given name, and group, and
     * the given settings of all the other properties.
     * </p>
     * 
     * @param group if <code>null</code>, Scheduler.DEFAULT_GROUP will be used.
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty, or the group is an empty string.
     *              
     * @deprecated use {@link JobBuilder}              
     */
    this(string name, string group, TypeInfo_Class jobClass,
                     bool durability, bool recover) {
        setName(name);
        setGroup(group);
        setJobClass(jobClass);
        setDurability(durability);
        setRequestsRecovery(recover);
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Get the name of this <code>Job</code>.
     * </p>
     */
    string getName() {
        return name;
    }

    /**
     * <p>
     * Set the name of this <code>Job</code>.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if name is null or empty.
     */
    void setName(string name) {
        if (name.empty()) {
            throw new IllegalArgumentException("Job name cannot be empty.");
        }

        this.name = name;
        this.key = null;
    }

    /**
     * <p>
     * Get the group of this <code>Job</code>.
     * </p>
     */
    string getGroup() {
        return group;
    }

    /**
     * <p>
     * Set the group of this <code>Job</code>.
     * </p>
     * 
     * @param group if <code>null</code>, Scheduler.DEFAULT_GROUP will be used.
     * 
     * @exception IllegalArgumentException
     *              if the group is an empty string.
     */
    void setGroup(string group) {
        if (group.empty()) {
            throw new IllegalArgumentException(
                    "Group name cannot be empty.");
        }

        if (group is null) {
            group = Scheduler.DEFAULT_GROUP;
        }

        this.group = group;
        this.key = null;
    }

    /**
     * <p>
     * Returns the 'full name' of the <code>JobDetail</code> in the format
     * "group.name".
     * </p>
     */
    string getFullName() {
        return group ~ "." ~ name;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.JobDetailI#getKey()
     */
    JobKey getKey() {
        if(key is null) {
            if(getName() is null)
                return null;
            key = new JobKey(getName(), getGroup());
        }

        return key;
    }
    
    void setKey(JobKey key) {
        if(key is null)
            throw new IllegalArgumentException("Key cannot be null!");

        setName(key.getName());
        setGroup(key.getGroup());
        this.key = key;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.JobDetailI#getDescription()
     */
    string getDescription() {
        return description;
    }

    /**
     * <p>
     * Set a description for the <code>Job</code> instance - may be useful
     * for remembering/displaying the purpose of the job, though the
     * description has no meaning to Quartz.
     * </p>
     */
    void setDescription(string description) {
        this.description = description;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.JobDetailI#getJobClass()
     */
    TypeInfo_Class getJobClass() {
        return jobClass;
    }

    /**
     * <p>
     * Set the instance of <code>Job</code> that will be executed.
     * </p>
     * 
     * @exception IllegalArgumentException
     *              if jobClass is null or the class is not a <code>Job</code>.
     */
    void setJobClass(TypeInfo_Class jobClass) {
        if (jobClass is null) {
            throw new IllegalArgumentException("Job class cannot be null.");
        }

        // if (!Job.class.isAssignableFrom(jobClass)) {
        //     throw new IllegalArgumentException(
        //             "Job class must implement the Job interface.");
        // }

        this.jobClass = jobClass;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.JobDetailI#getJobDataMap()
     */
    JobDataMap getJobDataMap() {
        if (jobDataMap is null) {
            jobDataMap = new JobDataMap();
        }
        return jobDataMap;
    }

    /**
     * <p>
     * Set the <code>JobDataMap</code> to be associated with the <code>Job</code>.
     * </p>
     */
    void setJobDataMap(JobDataMap jobDataMap) {
        this.jobDataMap = jobDataMap;
    }

    /**
     * <p>
     * Set whether or not the <code>Job</code> should remain stored after it
     * is orphaned (no <code>{@link Trigger}s</code> point to it).
     * </p>
     * 
     * <p>
     * If not explicitly set, the default value is <code>false</code>.
     * </p>
     */
    void setDurability(bool durability) {
        this.durability = durability;
    }

    /**
     * <p>
     * Set whether or not the the <code>Scheduler</code> should re-execute
     * the <code>Job</code> if a 'recovery' or 'fail-over' situation is
     * encountered.
     * </p>
     * 
     * <p>
     * If not explicitly set, the default value is <code>false</code>.
     * </p>
     * 
     * @see JobExecutionContext#isRecovering()
     */
    void setRequestsRecovery(bool shouldRecover) {
        this.shouldRecover = shouldRecover;
    }

    /* (non-Javadoc)
     * @see hunt.quartz.JobDetailI#isDurable()
     */
    bool isDurable() {
        return durability;
    }

    /**
     * @return whether the associated Job class carries the {@link PersistJobDataAfterExecution} annotation.
     */
    bool isPersistJobDataAfterExecution() {
        implementationMissing(false);
        return false;
        // return ClassUtils.isAnnotationPresent(jobClass, PersistJobDataAfterExecution.class);
    }

    /**
     * @return whether the associated Job class carries the {@link DisallowConcurrentExecution} annotation.
     */
    bool isConcurrentExectionDisallowed() {
        implementationMissing(false);
        return false;        
        // return ClassUtils.isAnnotationPresent(jobClass, DisallowConcurrentExecution.class);
    }

    /* (non-Javadoc)
     * @see hunt.quartz.JobDetailI#requestsRecovery()
     */
    bool requestsRecovery() {
        return shouldRecover;
    }

    /**
     * <p>
     * Return a simple string representation of this object.
     * </p>
     */
    override
    string toString() {
        return "JobDetail '" ~ getFullName() ~ "':  jobClass: '"
                ~ ((getJobClass() is null) ? "null" : getJobClass().name)
                ~ " concurrentExectionDisallowed: " ~ isConcurrentExectionDisallowed().to!string() 
                ~ " persistJobDataAfterExecution: " ~ isPersistJobDataAfterExecution().to!string() 
                ~ " isDurable: " ~ isDurable().to!string() ~ " requestsRecovers: " ~ requestsRecovery().to!string();
    }

    override
    bool opEquals(Object obj) {
        JobDetail other = cast(JobDetail) obj;
        if(other is null)
            return false;

        if(other.getKey() is null || getKey() is null)
            return false;
        
        if (other.getKey() != getKey()) {
            return false;
        }
            
        return true;
    }

    override
    size_t toHash() @trusted nothrow {
        JobKey key;
        try{
            key = getKey();
        } catch(Exception) {
            
        }
        return key is null ? 0 : key.toHash();
    }

    int opCmp(JobDetail o) {
        implementationMissing(false);
        return 0;
    }

    alias opCmp = Object.opCmp;
    
    Object clone() {
        implementationMissing(false);
        return this;
    //     JobDetailImpl copy;
    //     try {
    //         copy = (JobDetailImpl) super.clone();
    //         if (jobDataMap !is null) {
    //             copy.jobDataMap = (JobDataMap) jobDataMap.clone();
    //         }
    //     } catch (CloneNotSupportedException ex) {
    //         throw new IncompatibleClassChangeError("Not Cloneable.");
    //     }

    //     return copy;
    }

    JobBuilder getJobBuilder() {
        JobBuilder b = JobBuilder.newJob()
            .ofType(getJobClass())
            .requestRecovery(requestsRecovery())
            .storeDurably(isDurable())
            .usingJobData(getJobDataMap())
            .withDescription(getDescription())
            .withIdentity(getKey());
        return b;
    }
}
