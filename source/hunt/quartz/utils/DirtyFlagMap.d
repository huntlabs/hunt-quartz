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

// import hunt.quartz.utils.DirtyFlagIterator;

// import java.lang.reflect.Array;
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

    // Set!(Entry!(K,V)) entrySet() {
    //     return new DirtyFlagMapEntrySet(map.entrySet());
    // }

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

    // Set!(K) keySet() {
    //     return new DirtyFlagSet!(K)(map.byKey());
    // }

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

    // Collection!(V) values() {
    //     return new DirtyFlagCollection!(V)(map.values());
    // }

    // override
    // suppress warnings on generic cast of super.clone() and map.clone() lines.
    Object clone() {
        implementationMissing(false);
        return this;
        //     DirtyFlagMap!(K,V) copy;
        //     try {
        //         copy = (DirtyFlagMap!(K,V)) super.clone();
        //         if (map instanceof HashMap) {
        //             copy.map = (Map!(K,V))((HashMap!(K,V))map).clone();
        //         }
        //     } catch (CloneNotSupportedException ex) {
        //         throw new IncompatibleClassChangeError("Not Cloneable.");
        //     }

        //     return copy;
    }

    /**
     * Wrap a Collection so we can mark the DirtyFlagMap as dirty if
     * the underlying Collection is modified.
     */
    private class DirtyFlagCollection(T) : AbstractCollection!(T) {
        private Collection!(T) collection;

        this(T[] c) {
            collection = new ArrayList!T(c);
        }

        this(Collection!(T) c) {
            collection = c;
        }

        protected Collection!(T) getWrappedCollection() {
            return collection;
        }

        // Iterator!(T) iterator() {
        //     return new DirtyFlagIterator!(T)(collection.iterator());
        // }

        override bool remove(T o) {
            bool removed = collection.remove(o);
            if (removed) {
                dirty = true;
            }
            return removed;
        }

        override bool removeAll(Collection!T c) {
            bool changed = collection.removeAll(c);
            if (changed) {
                dirty = true;
            }
            return changed;
        }

        override bool retainAll(Collection!T c) {
            bool changed = collection.retainAll(c);
            if (changed) {
                dirty = true;
            }
            return changed;
        }

        override void clear() {
            if (collection.isEmpty() == false) {
                dirty = true;
            }
            collection.clear();
        }

        // Pure wrapper methods
        override int size() {
            return collection.size();
        }

        override bool isEmpty() {
            return collection.isEmpty();
        }

        override bool contains(T o) {
            return collection.contains(o);
        }

        override bool add(T o) {
            return collection.add(o);
        } // Not supported

        override bool addAll(Collection!T c) {
            return collection.addAll(c);
        } // Not supported

        override bool containsAll(Collection!T c) {
            return collection.containsAll(c);
        }

        override T[] toArray() {
            return collection.toArray();
        }
        // T[] toArray(T[] array) { return collection.toArray(array); }
    }

    /**
     * Wrap a Set so we can mark the DirtyFlagMap as dirty if
     * the underlying Collection is modified.
     */
    private class DirtyFlagSet(T) : DirtyFlagCollection!(T), Set!(T) {
        this(Set!(T) set) {
            super(set);
        }

        protected Set!(T) getWrappedSet() {
            return cast(Set!(T)) getWrappedCollection();
        }


        override bool opEquals(IObject o) {
            return opEquals(cast(Object) o);
        }
        
        override bool opEquals(Object o) {
            return super.opEquals(o);
        }

        override size_t toHash() @trusted nothrow {
            return super.toHash();
        }

        override string toString() {
            return super.toString();
        }        
    }

    /**
     * Wrap an Iterator so that we can mark the DirtyFlagMap as dirty if an
     * element is removed.
     */
    private class DirtyFlagIterator(T) : Iterator!(T) {
        private Iterator!(T) iterator;

        this(Iterator!(T) iterator) {
            this.iterator = iterator;
        }

        void remove() {
            dirty = true;
            implementationMissing(false);
            // iterator.remove();
        }

        // Pure wrapper methods
        bool hasNext() {
            return iterator.hasNext();
        }

        T next() {
            return iterator.next();
        }
    }

    /**
     * Wrap a MapEntry Set so we can mark the Map as dirty if
     * the Set is modified, and return MapEntry objects
     * wrapped in the <code>DirtyFlagMapEntry</code> class.
     */
    private class DirtyFlagMapEntrySet : DirtyFlagSet!(MapEntry!(K, V)) {

        this(Set!(MapEntry!(K, V)) set) {
            super(set);
        }

        // override
        // Iterator!(MapEntry!(K,V)) iterator() {
        //     return new DirtyFlagMapEntryIterator(getWrappedSet().iterator());
        // }

        // override
        // V[] toArray() {
        //     return toArray(new Object[super.size()]);
        // }

        //  // suppress warnings on both U[] and U casting.
        // override
        // <U> U[] toArray(U[] array) {
        //     if (array.getClass().getComponentType().isAssignableFrom(MapEntry.class) == false) {
        //         throw new IllegalArgumentException("Array must be of type assignable from MapEntry");
        //     }

        //     int size = super.size();

        //     U[] result =
        //         array.length < size ?
        //             (U[])Array.newInstance(array.getClass().getComponentType(), size) : array;

        //     Iterator!(MapEntry!(K,V)) entryIter = iterator(); // Will return DirtyFlagMapEntry objects
        //     for (int i = 0; i < size; i++) {
        //         result[i] = ( U ) entryIter.next();
        //     }

        //     if (result.length > size) {
        //         result[size] = null;
        //     }

        //     return result;
        // }
    }

    /**
     * Wrap an Iterator over MapEntry objects so that we can
     * mark the Map as dirty if an element is removed or modified.
     */
    private class DirtyFlagMapEntryIterator : DirtyFlagIterator!(MapEntry!(K, V)) {
        this(Iterator!(MapEntry!(K, V)) iterator) {
            super(iterator);
        }

        override DirtyFlagMapEntry next() {
            return new DirtyFlagMapEntry(super.next());
        }
    }

    /**
     * Wrap a MapEntry so we can mark the Map as dirty if
     * a value is set.
     */
    private class DirtyFlagMapEntry : MapEntry!(K, V) {
        private MapEntry!(K, V) entry;

        this(MapEntry!(K, V) entry) {
            this.entry = entry;
        }

        V setValue(V o) {
            dirty = true;
            return entry.setValue(o);
        }

        // Pure wrapper methods
        K getKey() {
            return entry.getKey();
        }

        V getValue() {
            return entry.getValue();
        }

        override bool opEquals(IObject o) {
            return opEquals(cast(Object) o);
        }        

        override bool opEquals(Object o) {
            return entry == o;
        }

        override size_t toHash() @trusted nothrow {
            return super.toHash();
        }

        override string toString() {
            return super.toString();
        }
    }
}
