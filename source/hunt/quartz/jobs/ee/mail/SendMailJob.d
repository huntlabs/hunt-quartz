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

module hunt.quartz.jobs.ee.mail.SendMailJob;

// import std.datetime;
// import java.util.Properties;

// import javax.mail.Address;
// import javax.mail.Authenticator;
// import javax.mail.Message;
// import javax.mail.MessagingException;
// import javax.mail.PasswordAuthentication;
// import javax.mail.Session;
// import javax.mail.Transport;
// import javax.mail.internet.InternetAddress;
// import javax.mail.internet.MimeMessage;

// import hunt.logging;

// import hunt.quartz.Job;
// import hunt.quartz.JobDataMap;
// import hunt.quartz.JobExecutionContext;
// import hunt.quartz.exception;

// /**
//  * <p>
//  * A Job which sends an e-mail with the configured content to the configured
//  * recipient.
//  * 
//  * Arbitrary mail.smtp.xxx settings can be added to job data and they will be
//  * passed along the mail session
//  * </p>
//  * 
//  * @author James House
//  */
// class SendMailJob : Job {


//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Constants.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     /**
//      * The host name of the smtp server. REQUIRED.
//      */
//     enum string PROP_SMTP_HOST = "smtp_host";

//     /**
//      * The e-mail address to send the mail to. REQUIRED.
//      */
//     enum string PROP_RECIPIENT = "recipient";

//     /**
//      * The e-mail address to cc the mail to. Optional.
//      */
//     enum string PROP_CC_RECIPIENT = "cc_recipient";

//     /**
//      * The e-mail address to claim the mail is from. REQUIRED.
//      */
//     enum string PROP_SENDER = "sender";

//     /**
//      * The e-mail address the message should say to reply to. Optional.
//      */
//     enum string PROP_REPLY_TO = "reply_to";

//     /**
//      * The subject to place on the e-mail. REQUIRED.
//      */
//     enum string PROP_SUBJECT = "subject";

//     /**
//      * The e-mail message body. REQUIRED.
//      */
//     enum string PROP_MESSAGE = "message";

//     /**
//      * The message content type. For example, "text/html". Optional.
//      */
//     enum string PROP_CONTENT_TYPE = "content_type";
    
//     /**
//      * Username for authenticated session. Password must also be set if username is used. Optional.
//      */
//     enum string PROP_USERNAME = "username";
    
//     /**
//      * Password for authenticated session. Optional.
//      */
//     enum string PROP_PASSWORD = "password";    

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Interface.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     /**
//      * @see hunt.quartz.Job#execute(hunt.quartz.JobExecutionContext)
//      */
//     void execute(JobExecutionContext context) {

//         JobDataMap data = context.getMergedJobDataMap();

//         MailInfo mailInfo = populateMailInfo(data, createMailInfo());
        
//         info("Sending message " ~ mailInfo);

//         try {
//             MimeMessage mimeMessage = prepareMimeMessage(mailInfo);
            
//             Transport.send(mimeMessage);
//         } catch (MessagingException e) {
//             throw new JobExecutionException("Unable to send mail: " ~ mailInfo,
//                     e, false);
//         }

//     }


//     protected MimeMessage prepareMimeMessage(MailInfo mailInfo) {
//         Session session = getMailSession(mailInfo);

//         MimeMessage mimeMessage = new MimeMessage(session);

//         Address[] toAddresses = InternetAddress.parse(mailInfo.getTo());
//         mimeMessage.setRecipients(Message.RecipientType.TO, toAddresses);

//         if (mailInfo.getCc() !is null) {
//             Address[] ccAddresses = InternetAddress.parse(mailInfo.getCc());
//             mimeMessage.setRecipients(Message.RecipientType.CC, ccAddresses);
//         }

//         mimeMessage.setFrom(new InternetAddress(mailInfo.getFrom()));
        
//         if (mailInfo.getReplyTo() !is null) {
//             mimeMessage.setReplyTo(new InternetAddress[]{new InternetAddress(mailInfo.getReplyTo())});
//         }
        
//         mimeMessage.setSubject(mailInfo.getSubject());
        
//         mimeMessage.setSentDate(new Date());

//         setMimeMessageContent(mimeMessage, mailInfo);

//         return mimeMessage;
//     }
    
//     protected void setMimeMessageContent(MimeMessage mimeMessage, MailInfo mailInfo) {
//         if (mailInfo.getContentType() is null) {
//             mimeMessage.setText(mailInfo.getMessage());
//         } else {
//             mimeMessage.setContent(mailInfo.getMessage(), mailInfo.getContentType());
//         }
//     }

//     protected Session getMailSession(final MailInfo mailInfo) {
//         Properties properties = new Properties();
//         properties.put("mail.smtp.host", mailInfo.getSmtpHost());
        
//         // pass along extra smtp settings from users
//         Properties extraSettings = mailInfo.getSmtpProperties();
//         if (extraSettings !is null) {
//             properties.putAll(extraSettings);
//         }
        
//         Authenticator authenticator = null;
//         if (mailInfo.getUsername() !is null && mailInfo.getPassword() !is null) {
//             info("using username '{}' and password 'xxx'", mailInfo.getUsername());
//             authenticator = new Authenticator() { 
//                 protected PasswordAuthentication getPasswordAuthentication() { 
//                     return new PasswordAuthentication(mailInfo.getUsername(), mailInfo.getPassword()); 
//                 }
//             };
//         }
//         trace("Sending mail with properties: {}", properties);
//         return Session.getDefaultInstance(properties, authenticator);
//     }
    
//     protected MailInfo createMailInfo() {
//         return new MailInfo();
//     }
    
//     protected MailInfo populateMailInfo(JobDataMap data, MailInfo mailInfo) {
//         // Required parameters
//         mailInfo.setSmtpHost(getRequiredParm(data, PROP_SMTP_HOST, "PROP_SMTP_HOST"));
//         mailInfo.setTo(getRequiredParm(data, PROP_RECIPIENT, "PROP_RECIPIENT"));
//         mailInfo.setFrom(getRequiredParm(data, PROP_SENDER, "PROP_SENDER"));
//         mailInfo.setSubject(getRequiredParm(data, PROP_SUBJECT, "PROP_SUBJECT"));
//         mailInfo.setMessage(getRequiredParm(data, PROP_MESSAGE, "PROP_MESSAGE"));
        
//         // Optional parameters
//         mailInfo.setReplyTo(getOptionalParm(data, PROP_REPLY_TO));
//         mailInfo.setCc(getOptionalParm(data, PROP_CC_RECIPIENT));
//         mailInfo.setContentType(getOptionalParm(data, PROP_CONTENT_TYPE));
//         mailInfo.setUsername(getOptionalParm(data, PROP_USERNAME));
//         mailInfo.setPassword(getOptionalParm(data, PROP_PASSWORD));
        
//         // extra mail.smtp. properties from user
//         Properties smtpProperties = new Properties();
//         foreach(string key ; data.keySet()) {
//             if (key.startsWith("mail.smtp.")) {
//                 smtpProperties.put(key, data.getString(key));
//             }
//         }
//         if (mailInfo.getSmtpProperties() is null) {
//             mailInfo.setSmtpProperties(smtpProperties);
//         } else {
//             mailInfo.getSmtpProperties().putAll(smtpProperties);
//         }

        
//         return mailInfo;
//     }
    
    
//     protected string getRequiredParm(JobDataMap data, string property, string constantName) {
//         string value = getOptionalParm(data, property);
        
//         if (value is null) {
//             throw new IllegalArgumentException(constantName ~ " not specified.");
//         }
        
//         return value;
//     }
    
//     protected string getOptionalParm(JobDataMap data, string property) {
//         string value = data.getString(property);
        
//         if ((value !is null) && (value.trim().length() == 0)) {
//             return null;
//         }
        
//         return value;
//     }
    
//     protected static class MailInfo {
//         private string smtpHost;
//         private string to;
//         private string from;
//         private string subject;
//         private string message;
//         private string replyTo;
//         private string cc;
//         private string contentType;
//         private string username;
//         private string password;
//         private Properties smtpProperties;

//         override
//         string toString() {
//             return "'" ~ getSubject() ~ "' to: " ~ getTo();
//         }
        
//         string getCc() {
//             return cc;
//         }

//         void setCc(string cc) {
//             this.cc = cc;
//         }

//         string getContentType() {
//             return contentType;
//         }

//         void setContentType(string contentType) {
//             this.contentType = contentType;
//         }

//         string getFrom() {
//             return from;
//         }

//         void setFrom(string from) {
//             this.from = from;
//         }

//         string getMessage() {
//             return message;
//         }

//         void setMessage(string message) {
//             this.message = message;
//         }

//         string getReplyTo() {
//             return replyTo;
//         }

//         void setReplyTo(string replyTo) {
//             this.replyTo = replyTo;
//         }

//         string getSmtpHost() {
//             return smtpHost;
//         }

//         void setSmtpHost(string smtpHost) {
//             this.smtpHost = smtpHost;
//         }

//         string getSubject() {
//             return subject;
//         }

//         void setSubject(string subject) {
//             this.subject = subject;
//         }

//         string getTo() {
//             return to;
//         }

//         void setTo(string to) {
//             this.to = to;
//         }
        
//         Properties getSmtpProperties() {
//             return smtpProperties;
//         }
        
//         void setSmtpProperties(Properties smtpProperties) {
//             this.smtpProperties = smtpProperties;
//         }
        
//         string getUsername() {
//             return username;
//         }
        
//         void setUsername(string username) {
//             this.username = username;
//         }
        
//         string getPassword() {
//             return password;
//         }
        
//         void setPassword(string password) {
//             this.password = password;
//         }
//     }
// }
