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

module hunt.quartz.utils.PropertiesParser;

import hunt.collection.ArrayList;
// import java.util.Enumeration;
import hunt.collection.HashSet;
// import java.util.Properties;
import hunt.text.StringTokenizer;

import hunt.Exceptions;
import hunt.Byte;
import hunt.Double;
import hunt.Float;
import hunt.Integer;
import hunt.Long;
import hunt.Short;

import std.array;
import std.conv;
import std.string;

alias Properties = string[string];

/**
 * <p>
 * This is an utility calss used to parse the properties.
 * </p>
 * 
 * @author James House
 */
class PropertiesParser {

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Data members.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    Properties props;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Constructors.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    this(Properties props) {
        this.props = props;
    }

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     * 
     * Interface.
     * 
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    Properties getUnderlyingProperties() {
        return props;
    }

    /**
     * Get the trimmed string value of the property with the given 
     * <code>name</code>.  If the value the empty string (after
     * trimming), then it returns null.
     */
    string getStringProperty(string name) {
        return getStringProperty(name, null);
    }

    /**
     * Get the trimmed string value of the property with the given 
     * <code>name</code> or the given default value if the value is 
     * null or empty after trimming.
     */
    string getStringProperty(string name, string def) {
        string val = props.get(name, def);
        val = val.strip();
        
        return val.empty() ? def : val;
    }

    string[] getStringArrayProperty(string name) {
        return getStringArrayProperty(name, null);
    }

    string[] getStringArrayProperty(string name, string[] def) {
        string vals = getStringProperty(name);
        if (vals is null) {
            return def;
        }

        StringTokenizer stok = new StringTokenizer(vals, ",");
        ArrayList!(string) strs = new ArrayList!(string)();
        try {
            while (stok.hasMoreTokens()) {
                strs.add(stok.nextToken().strip());
            }
            
            return strs.toArray();
        } catch (Exception e) {
            return def;
        }
    }

    bool getBooleanProperty(string name) {
        return getBooleanProperty(name, false);
    }

    bool getBooleanProperty(string name, bool def) {
        string val = getStringProperty(name);
        
        return (val.empty()) ? def : to!bool(val);
    }

    byte getByteProperty(string name) {
        string val = getStringProperty(name);
        if (val.empty()) {
            throw new NumberFormatException(" null string");
        }

        try {
            return Byte.parseByte(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    byte getByteProperty(string name, byte def) {
        string val = getStringProperty(name);
        if (val.empty()) {
            return def;
        }

        try {
            return Byte.parseByte(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    char getCharProperty(string name) {
        return getCharProperty(name, '\0');
    }

    char getCharProperty(string name, char def) {
        string param = getStringProperty(name);
        return  (param is null) ? def : param[0];
    }

    double getDoubleProperty(string name) {
        string val = getStringProperty(name);
        if (val.empty()) {
            throw new NumberFormatException(" null string");
        }

        try {
            return Double.parseDouble(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    double getDoubleProperty(string name, double def) {
        string val = getStringProperty(name);
        if (val.empty()) {
            return def;
        }

        try {
            return Double.parseDouble(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    float getFloatProperty(string name) {
        string val = getStringProperty(name);
        if (val.empty()) {
            throw new NumberFormatException(" null string");
        }

        try {
            return Float.parseFloat(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    float getFloatProperty(string name, float def) {
        string val = getStringProperty(name);
        if (val.empty()) {
            return def;
        }

        try {
            return Float.parseFloat(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    int getIntProperty(string name) {
        string val = getStringProperty(name);
        if (val.empty()) {
            throw new NumberFormatException(" null string");
        }

        try {
            return Integer.parseInt(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    int getIntProperty(string name, int def) {
        string val = getStringProperty(name);
        if (val.empty()) {
            return def;
        }

        try {
            return Integer.parseInt(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    int[] getIntArrayProperty(string name) {
        return getIntArrayProperty(name, null);
    }

    int[] getIntArrayProperty(string name, int[] def) {
        string vals = getStringProperty(name);
        if (vals is null) {
            return def;
        }

        StringTokenizer stok = new StringTokenizer(vals, ",");
        ArrayList!(int) ints = new ArrayList!(int)();
        try {
            while (stok.hasMoreTokens()) {
                try {
                    ints.add(to!int(stok.nextToken().strip()));
                } catch (NumberFormatException nfe) {
                    throw new NumberFormatException(" '" ~ vals ~ "'");
                }
            }
                        
            int[] outInts = new int[ints.size()];
            for (int i = 0; i < ints.size(); i++) {
                outInts[i] = ints.get(i);
            }
            return outInts;
        } catch (Exception e) {
            return def;
        }
    }

    long getLongProperty(string name) {
        string val = getStringProperty(name);
        if (val.empty()) {
            throw new NumberFormatException(" null string");
        }

        try {
            return Long.parseLong(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    long getLongProperty(string name, long def) {
        string val = getStringProperty(name);
        if (val.empty()) {
            return def;
        }

        try {
            return Long.parseLong(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    short getShortProperty(string name) {
        string val = getStringProperty(name);
        if (val.empty()) {
            throw new NumberFormatException(" null string");
        }

        try {
            return Short.parseShort(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    short getShortProperty(string name, short def) {
        string val = getStringProperty(name);
        if (val.empty()) {
            return def;
        }

        try {
            return Short.parseShort(val);
        } catch (NumberFormatException nfe) {
            throw new NumberFormatException(" '" ~ val ~ "'");
        }
    }

    string[] getPropertyGroups(string prefix) {
        HashSet!(string) groups = new HashSet!(string)(10);

        if (!prefix.endsWith(".")) {
            prefix ~= ".";
        }

        foreach(string key; props.byKey()) {
            if (key.startsWith(prefix)) {
                ptrdiff_t endIndex = key.indexOf('.', prefix.length);
                size_t beginIndex = prefix.length;
                string groupName = key[beginIndex .. beginIndex+endIndex];
                groups.add(groupName);
            }
        }

        return groups.toArray();
    }

    Properties getPropertyGroup(string prefix) {
        return getPropertyGroup(prefix, false, null);
    }

    Properties getPropertyGroup(string prefix, bool stripPrefix) {
        return getPropertyGroup(prefix, stripPrefix, null);
    }

    /**
     * Get all properties that start with the given prefix.  
     * 
     * @param prefix The prefix for which to search.  If it does not end in 
     *      a "." then one will be added to it for search purposes.
     * @param stripPrefix Whether to strip off the given <code>prefix</code>
     *      in the result's keys.
     * @param excludedPrefixes Optional array of fully qualified prefixes to
     *      exclude.  For example if <code>prefix</code> is "a.b.c", then 
     *      <code>excludedPrefixes</code> might be "a.b.c.ignore".
     *      
     * @return Group of <code>Properties</code> that start with the given prefix, 
     *      optionally have that prefix removed, and do not include properties 
     *      that start with one of the given excluded prefixes.
     */
    Properties getPropertyGroup(string prefix, bool stripPrefix, string[] excludedPrefixes) {
        Properties group;

        if (!prefix.endsWith(".")) {
            prefix ~= ".";
        }

        foreach(string key; props.byKey()) {
            if (key.startsWith(prefix)) {
                bool exclude = false;
                if (excludedPrefixes !is null) {
                    for (size_t i = 0; (i < excludedPrefixes.length) && !exclude; i++) {
                        exclude = key.startsWith(excludedPrefixes[i]);
                    }
                }

                if (!exclude) {
                    string value = getStringProperty(key, "");
                    
                    if (stripPrefix) { 
                        string k = key[0 .. prefix.length];
                        group[k] = value;
                    } else {
                        group[key] = value;
                    }
                }
            }
        }

        return group;
    }
}
