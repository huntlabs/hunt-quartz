module test.quartz.JobDataMapTest;

import hunt.quartz.JobDataMap;

import hunt.Exceptions;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.Assert;

import hunt.util.Serialize;

/**
*/
class JobDataMapTest  {

    void testSerialization() {
        JobDataMap m = new JobDataMap();
        m.put("name", "Bob");
        m.put("age", 23);
        trace(m.toString());

        // ubyte[] d = cast(ubyte[])m.serialize();
        // tracef("%(%02X %)", d);

        JSONValue jv = JsonSerializer.toJson(m);
        // trace(jv.toPrettyString());

        JobDataMap m2 = JsonSerializer.fromJson!(JobDataMap)(jv);
        trace(m.toString());
        string name = m2.getFromString!(string)("name");
        int age = m2.getFromString!(int)("age");
        assert(name == "Bob");
        assert(age == 23);
    }
}