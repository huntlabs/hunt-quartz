/*
 * All content copyright Terracotta, Inc., unless otherwise indicated. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
module hunt.quartz.dbstore.SimplePropertiesTriggerProperties;

// import java.math.BigDecimal;

class SimplePropertiesTriggerProperties {

    private string string1;
    private string string2;
    private string string3;

    private int int1;
    private int int2;

    private long long1;
    private long long2;
    // TODO: Tasks pending completion -@zhangxueping at 3/28/2019, 10:06:13 AM
    // 
    // private BigDecimal decimal1;
    // private BigDecimal decimal2;
    private long decimal1;
    private long decimal2;

    private bool boolean1;
    private bool boolean2;

    string getString1() {
        return string1;
    }

    void setString1(string string1) {
        this.string1 = string1;
    }

    string getString2() {
        return string2;
    }

    void setString2(string string2) {
        this.string2 = string2;
    }

    string getString3() {
        return string3;
    }

    void setString3(string string3) {
        this.string3 = string3;
    }

    int getInt1() {
        return int1;
    }

    void setInt1(int int1) {
        this.int1 = int1;
    }

    int getInt2() {
        return int2;
    }

    void setInt2(int int2) {
        this.int2 = int2;
    }

    long getLong1() {
        return long1;
    }

    void setLong1(long long1) {
        this.long1 = long1;
    }

    long getLong2() {
        return long2;
    }

    void setLong2(long long2) {
        this.long2 = long2;
    }

    long getDecimal1() {
        return decimal1;
    }

    void setDecimal1(long decimal1) {
        this.decimal1 = decimal1;
    }

    long getDecimal2() {
        return decimal2;
    }

    void setDecimal2(long decimal2) {
        this.decimal2 = decimal2;
    }

    bool isBoolean1() {
        return boolean1;
    }

    void setBoolean1(bool boolean1) {
        this.boolean1 = boolean1;
    }

    bool isBoolean2() {
        return boolean2;
    }

    void setBoolean2(bool boolean2) {
        this.boolean2 = boolean2;
    }

}
