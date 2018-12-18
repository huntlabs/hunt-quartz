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

module hunt.quartz.jobs.ee.jms.JmsHelper;

import java.lang.reflect.Method;
import java.util.Hashtable;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import hunt.quartz.JobDataMap;

/**
 * Utility class that aids in the processing of JMS based jobs and sending of
 * <code>javax.jms.Message</code>
 * 
 * @author Fernando Ribeiro
 * @author Weston M. Price
 */
final class JmsHelper {
    enum string CREDENTIALS = "java.naming.security.credentials";

    enum string INITIAL_CONTEXT_FACTORY = "java.naming.factory.initial";

    enum string JMS_ACK_MODE = "jms.acknowledge";

    enum string JMS_CONNECTION_FACTORY_JNDI = "jms.connection.factory";

    enum string JMS_DESTINATION_JNDI = "jms.destination";

    enum string JMS_MSG_FACTORY_CLASS_NAME = "jms.message.factory.class.name";

    enum string JMS_PASSWORD = "jms.password";

    enum string JMS_USE_TXN = "jms.use.transaction";

    enum string JMS_USER = "jms.user";

    enum string PRINCIPAL = "java.naming.security.principal";

    enum string PROVIDER_URL = "java.naming.provider.url";

    static void closeResource(final Object resource) {

        if (resource is null)
            return;

        try {
            final Method m = resource.getClass().getMethod("close",
                    new Class[0]);

            m.invoke(resource, new Object[0]);
        } catch (final Exception e) {
        }

    }

    static InitialContext getInitialContext(final JobDataMap dataMap) {
        final Hashtable!(string, string) params = new Hashtable!(string, string)(4);

        final string initialContextFactory = dataMap
                .getString(INITIAL_CONTEXT_FACTORY);

        if (initialContextFactory !is null)
            params.put(Context.INITIAL_CONTEXT_FACTORY, initialContextFactory);

        final string providerUrl = dataMap.getString(PROVIDER_URL);

        if (providerUrl !is null)
            params.put(Context.PROVIDER_URL, providerUrl);

        final string principal = dataMap.getString(PRINCIPAL);

        if (principal !is null)
            params.put(Context.SECURITY_PRINCIPAL, principal);

        final string credentials = dataMap.getString(CREDENTIALS);

        if (credentials !is null)
            params.put(Context.SECURITY_CREDENTIALS, credentials);

        if (params.size() == 0)
            return new InitialContext();
        else
            return new InitialContext(params);

    }

    static JmsMessageFactory getMessageFactory(final string name) {

        try {
            final Class<?> cls = Class.forName(name);

            final JmsMessageFactory factory = (JmsMessageFactory) cls
                    .newInstance();

            return factory;
        } catch (final Exception e) {
            throw new JmsJobException(e.getMessage(), e);
        }

    }

    static bool isDestinationSecure(final JobDataMap dataMap) {
        return ((dataMap.getString(JmsHelper.JMS_USER) !is null) && (dataMap
                .getString(JmsHelper.JMS_PASSWORD) !is null));
    }

    static bool useTransaction(final JobDataMap dataMap) {
        return dataMap.getBoolean(JMS_USE_TXN);
    }

    private JmsHelper() {
    }

}
