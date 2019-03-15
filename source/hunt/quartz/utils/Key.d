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

module hunt.quartz.utils.Key;

import hunt.util.Common;
import hunt.Exceptions;

import std.algorithm;
import std.format;
import std.uuid;

interface IKey {

    /**
     * The default group for scheduling entities, with the value "DEFAULT".
     */
    enum string DEFAULT_GROUP = "DEFAULT";

    static string createUniqueName(string group) {
        if(group is null)
            group = DEFAULT_GROUP;
        
        string n1 = randomUUID().toString();
        string n2 = randomUUID().toString(); // UUID.nameUUIDFromBytes(group.getBytes()).toString();
        
        return format("%s-%s", n2[24 .. $], n1);
    }
}

/**
 * <p>
 * Object representing a job or trigger key.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 */
class Key(T) : Comparable!(Key!(T)), IKey {
  

    private string name;
    private string group;
    
    
    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * Construct a new key with the given name and group.
     * 
     * @param name
     *          the name
     * @param group
     *          the group
     */
    this(string name, string group) {
        if(name is null)
            throw new IllegalArgumentException("Name cannot be null.");
        this.name = name;
        if(group !is null)
            this.group = group;
        else
            this.group = DEFAULT_GROUP;
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
     * Get the name portion of the key.
     * </p>
     * 
     * @return the name
     */
    string getName() {
        return name;
    }

    /**
     * <p>
     * Get the group portion of the key.
     * </p>
     * 
     * @return the group
     */
    string getGroup() {
        return group;
    }

    /**
     * <p>
     * Return the string representation of the key. The format will be:
     * &lt;group&gt;.&lt;name&gt;.
     * </p>
     * 
     * @return the string representation of the key
     */
    override
    string toString() {
        return getGroup() ~ "." ~ getName();
    }

    override
    size_t toHash() @trusted nothrow {
        size_t prime = 31;
        size_t result = 1;
        result = prime * result + ((group is null) ? 0 : group.hashOf());
        result = prime * result + ((name is null) ? 0 : hashOf(name));
        return result;
    }

    override
    bool opEquals(Object obj) {
        if (this is obj)
            return true;
        if (obj is null)
            return false;
        if (typeid(this) != typeid(obj))
            return false;
        
        Key!(T) other = cast(Key!(T)) obj;
        if (group is null) {
            if (other.group !is null)
                return false;
        } else if (group != other.group)
            return false;
        if (name is null) {
            if (other.name !is null)
                return false;
        } else if (name != other.name)
            return false;
        return true;
    }

    int opCmp(Key!(T) o) {
        
        if(group == DEFAULT_GROUP && o.group != DEFAULT_GROUP)
            return -1;
        if(group != DEFAULT_GROUP && o.group == DEFAULT_GROUP)
            return 1;
            
        int r = cmp(group, o.getGroup());
        if(r != 0)
            return r;
        
        return cmp(name, o.getName());
    }

    alias opCmp = Object.opCmp;
}
