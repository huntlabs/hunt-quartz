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

module hunt.quartz.impl.jdbcjobstore.SybaseDelegate;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import hunt.quartz.spi.ClassLoadHelper;
import hunt.logging;

/**
 * <p>
 * This is a driver delegate for the Sybase database.
 * </p>
 * 
 * @author <a href="mailto:jeff@binaryfeed.org">Jeffrey Wescott</a>
 * @author jhouse
 * @author Ray Case
 */
class SybaseDelegate : StdJDBCDelegate {

    //---------------------------------------------------------------------------
    // protected methods that can be overridden by subclasses
    //---------------------------------------------------------------------------

    /**
     * <p>
     * This method should be overridden by any delegate subclasses that need
     * special handling for BLOBs. The default implementation uses standard
     * JDBC <code>java.sql.Blob</code> operations.
     * </p>
     * 
     * @param rs
     *          the result set, already queued to the correct row
     * @param colName
     *          the column name for the BLOB
     * @return the deserialized Object from the ResultSet BLOB
     * @throws ClassNotFoundException
     *           if a class found during deserialization cannot be found
     * @throws IOException
     *           if deserialization causes an error
     */
    override           
    protected Object getObjectFromBlob(ResultSet rs, string colName) {
        InputStream binaryInput = rs.getBinaryStream(colName);

        if(binaryInput is null || binaryInput.available() == 0) {
            return null;
        }

        Object obj = null;

        ObjectInputStream in = new ObjectInputStream(binaryInput);
        try {
            obj = in.readObject();
        } finally {
            in.close();
        }

        return obj;
    }

    override           
    protected Object getJobDataFromBlob(ResultSet rs, string colName) {
        if (canUseProperties()) {
            InputStream binaryInput = rs.getBinaryStream(colName);
            return binaryInput;
        }
        return getObjectFromBlob(rs, colName);
    }
    
    /**
     * Sets the designated parameter to the byte array of the given
     * <code>ByteArrayOutputStream</code>. Will set parameter value to null if the
     * <code>ByteArrayOutputStream</code> is null.
     * This just wraps <code>{@link PreparedStatement#setBytes(int, byte[])}</code>
     * by default, but it can be overloaded by subclass delegates for databases that
     * don't explicitly support storing bytes in this way.
     */
    override
    protected void setBytes(PreparedStatement ps, int index, ByteArrayOutputStream baos) {
        ps.setBytes(index, (baos is null) ? null: baos.toByteArray());
    } 
}

// EOF
