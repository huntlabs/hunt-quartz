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

module hunt.quartz.impl.jdbcjobstore.CacheDelegate;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.ObjectInputStream;
import java.sql.Blob;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * <p>
 * This is a driver delegate for Intersystems Caché database.
 * </p>
 * 
 * <p>
 * Works with the Oracle table creation scripts / schema.
 * </p>
 * 
 * @author Franck Routier
 * @author <a href="mailto:alci@mecadu.org">Franck Routier</a>
 */
class CacheDelegate : StdJDBCDelegate {
        
    //---------------------------------------------------------------------------
    // protected methods that can be overridden by subclasses
    //---------------------------------------------------------------------------
  
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
        ps.setObject(index, ((baos is null) ? null : baos.toByteArray()), java.sql.Types.BLOB);
    } 

    /**
     * {@inheritDoc}
     * <p>
     * Caché requires {@code java.sql.Blob} instances to be explicitly freed.
     */
    override
    protected Object getObjectFromBlob(ResultSet rs, string colName) {
        Blob blob = rs.getBlob(colName);
        if (blob is null) {
            return null;
        } else {
            try {
                if (blob.length() == 0) {
                    return null;
                } else {
                    InputStream binaryInput = blob.getBinaryStream();
                    if (binaryInput is null) {
                        return null;
                    } else if (binaryInput instanceof ByteArrayInputStream && ((ByteArrayInputStream) binaryInput).available() == 0 ) {
                        return null;
                    } else {
                        ObjectInputStream in = new ObjectInputStream(binaryInput);
                        try {
                            return in.readObject();
                        } finally {
                            in.close();
                        }
                    }
                }
            } finally {
                blob.free();
            }
        }
    }

    /**
     * {@inheritDoc}
     * <p>
     * Caché requires {@code java.sql.Blob} instances to be explicitly freed.
     */
    override
    protected Object getJobDataFromBlob(ResultSet rs, string colName) {
        if (canUseProperties()) {
            Blob blob = rs.getBlob(colName);
            if (blob is null) {
                return null;
            } else {
                return new BlobFreeingStream(blob, blob.getBinaryStream());
            }
        } else {
            return getObjectFromBlob(rs, colName);
        }
    }
    
    private static class BlobFreeingStream : InputStream {
        
        private final Blob source;
        private final InputStream delegate;

        private BlobFreeingStream(Blob blob, InputStream stream) {
            this.source = blob;
            this.delegate = stream;
        }

        override
        int read() {
            return delegate.read();
        }

        override
        int read(byte[] b) {
            return delegate.read(b);
        }

        override
        int read(byte[] b, int off, int len) {
            return delegate.read(b, off, len);
        }

        override
        long skip(long n) {
            return delegate.skip(n);
        }

        override
        int available() {
            return delegate.available();
        }

        override
        void close() {
            try {
                delegate.close();
            } finally {
                try {
                    source.free();
                } catch (SQLException ex) {
                    throw new IOException(ex);
                }
            }
        }

        override
        synchronized void mark(int readlimit) {
            delegate.mark(readlimit);
        }

        override
        synchronized void reset() {
            delegate.reset();
        }

        override
        bool markSupported() {
            return delegate.markSupported();
        }
    }
}

