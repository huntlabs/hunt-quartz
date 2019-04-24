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

module hunt.quartz.utils.DirtyFlagMap;

import hunt.collection.AbstractMap;
import hunt.collection.ArrayList;
import hunt.collection.AbstractCollection;
import hunt.collection.Collection;
import hunt.collection.HashMap;
import hunt.collection.Iterator;
import hunt.collection.Map;
import hunt.collection.Set;

import hunt.Exceptions;
import hunt.Object;
import hunt.util.Traits;

import std.range;

/**
 * <p>
 * An implementation of <code>Map</code> that wraps another <code>Map</code>
 * and flags itself 'dirty' when it is modified.
 * </p>
 *
 * @author James House
 */
class DirtyFlagMap(K, V) : AbstractMap!(K, V) { // , Cloneable, java.io.Serializable //  Map

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Data members.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    private bool dirty = false;
    protected Map!(K, V) map;

    /*
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     *
     * Constructors.
     *
     * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * <p>
     * Create a DirtyFlagMap that 'wraps' a <code>HashMap</code>.
     * </p>
     *
     * @see java.util.HashMap
     */
    this() {
        map = new HashMap!(K, V)();
    }

    /**
     * <p>
     * Create a DirtyFlagMap that 'wraps' a <code>HashMap</code> that has the
     * given initial capacity.
     * </p>
     *
     * @see java.util.HashMap
     */
    this(int initialCapacity) {
        map = new HashMap!(K, V)(initialCapacity);
    }

    /**
     * <p>
     * Create a DirtyFlagMap that 'wraps' a <code>HashMap</code> that has the
     * given initial capacity and load factor.
     * </p>
     *
     * @see java.util.HashMap
     */
    this(int initialCapacity, float loadFactor) {
        map = new HashMap!(K, V)(initialCapacity, loadFactor);
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
     * Clear the 'dirty' flag (set dirty flag to <code>false</code>).
     * </p>
     */
    void clearDirtyFlag() {
        dirty = false;
    }

    /**
     * <p>
     * Determine whether the <code>Map</code> is flagged dirty.
     * </p>
     */
    bool isDirty() {
        return dirty;
    }

    /**
     * <p>
     * Get a direct handle to the underlying Map.
     * </p>
     */
    Map!(K, V) getWrappedMap() {
        return map;
    }

    override void clear() {
        if (!map.isEmpty()) {
            dirty = true;
        }
        map.clear();
    }

    override bool containsKey(K key) {
        return map.containsKey(key);
    }

    override bool containsValue(V val) {
        return map.containsValue(val);
    }
    
    override int opApply(scope int delegate(ref K, ref V) dg) {
        return map.opApply(dg);
    }

    override int opApply(scope int delegate(MapEntry!(K, V) entry) dg) {
        return map.opApply(dg);
    }

    override InputRange!K byKey() {
        return map.byKey();
    }

    override InputRange!V byValue() {
        return map.byValue();
    }


    // override
    // bool opEquals(Object o) {
    //     if (obj is null || !(obj instanceof DirtyFlagMap)) {
    //         return false;
    //     }

    //     return map.equals(((DirtyFlagMap<?,?>) obj).getWrappedMap());
    // }

    override size_t toHash() @trusted nothrow {
        return map.toHash();
    }

    override V get(K key) {
        return map.get(key);
    }

    override bool isEmpty() {
        return map.isEmpty();
    }


    override V put(K key, V val) {
        dirty = true;

        return map.put(key, val);
    }

    override void putAll(Map!(K, V) t) {
        if (!t.isEmpty()) {
            dirty = true;
        }

        map.putAll(t);
    }

    override V remove(K key) {
        V obj = map.remove(key);

        if (obj !is null) {
            dirty = true;
        }

        return obj;
    }

    override int size() {
        return map.size();
    }

    override V[] values() {
        return map.values();
    }


    // override
    // // suppress warnings on generic cast of super.clone() and map.clone() lines.
    // Object clone() {
    //     DirtyFlagMap!(K,V) copy;
    //     try {
    //         copy = cast(DirtyFlagMap!(K,V)) super.clone();

    //         enum string s = generateObjectClone!(DirtyFlagMap!(K,V), this.stringof, copy.stringof);
    //         mixin(s);

    //         HashMap!(K,V) hashMap = cast(HashMap!(K,V))map;
    //         if (hashMap !is null) {
    //             copy.map = cast(Map!(K,V))(hashMap.clone());
    //         }
    //     } catch (CloneNotSupportedException ex) {
    //         throw new IncompatibleClassChangeError("Not Cloneable.");
    //     }

    //     return copy;
    // }


    mixin CloneMemberTemplate!(typeof(this), (typeof(this) from, typeof(this) to) {
        HashMap!(K,V) hashMap = cast(HashMap!(K,V))from.map;
        if (hashMap !is null) {
            to.map = cast(Map!(K,V))(hashMap.clone());
        }
    }); 

}
