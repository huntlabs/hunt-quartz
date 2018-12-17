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

import java.util.UUID;


/**
 * <p>
 * Object representing a job or trigger key.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 */
class Key!(T)  implements Serializable, Comparable!(Key!(T)) {
  

    /**
     * The default group for scheduling entities, with the value "DEFAULT".
     */
    enum string DEFAULT_GROUP = "DEFAULT";

    private final string name;
    private final string group;
    
    
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
    Key(string name, string group) {
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
        return getGroup() + '.' + getName();
    }

    override
    size_t toHash() @trusted nothrow() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((group is null) ? 0 : group.hashCode());
        result = prime * result + ((name is null) ? 0 : name.hashCode());
        return result;
    }

    override
    bool equals(Object obj) {
        if (this == obj)
            return true;
        if (obj is null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        @SuppressWarnings("unchecked")
        Key!(T) other = (Key!(T)) obj;
        if (group is null) {
            if (other.group !is null)
                return false;
        } else if (!group== other.group)
            return false;
        if (name is null) {
            if (other.name !is null)
                return false;
        } else if (!name== other.name)
            return false;
        return true;
    }

    int compareTo(Key!(T) o) {
        
        if(group== DEFAULT_GROUP && !o.group== DEFAULT_GROUP)
            return -1;
        if(!group== DEFAULT_GROUP && o.group== DEFAULT_GROUP)
            return 1;
            
        int r = group.compareTo(o.getGroup());
        if(r != 0)
            return r;
        
        return name.compareTo(o.getName());
    }
    
    static string createUniqueName(string group) {
        if(group is null)
            group = DEFAULT_GROUP;
        
        string n1 = UUID.randomUUID().toString();
        string n2 = UUID.nameUUIDFromBytes(group.getBytes()).toString();
        
        return string.format("%s-%s", n2.substring(24), n1);
    }
}
