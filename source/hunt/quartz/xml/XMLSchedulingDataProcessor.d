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

module hunt.quartz.xml.XMLSchedulingDataProcessor;

// import static hunt.quartz.CalendarIntervalScheduleBuilder.calendarIntervalSchedule;
// import static hunt.quartz.CronScheduleBuilder.cronSchedule;
// import static hunt.quartz.JobBuilder.newJob;
// import static hunt.quartz.SimpleScheduleBuilder.simpleSchedule;
// import static hunt.quartz.TriggerBuilder.newTrigger;
// import static hunt.quartz.TriggerKey.triggerKey;

// import java.io.File;
// import java.io.FileInputStream;
// import java.io.FileNotFoundException;
// import java.io.IOException;
// import hunt.io.common;
// import java.io.UnsupportedEncodingException;
// import java.net.URL;
// import java.net.URLDecoder;
// import hunt.lang.exception;
// import hunt.container.ArrayList;
// import hunt.container.Collection;
// import hunt.container.Collections;
// import std.datetime;
// import hunt.container.HashMap;
// import hunt.container.Iterator;
// import hunt.container.LinkedList;
// import hunt.container.List;
// import hunt.container.Map;
// import std.datetime : TimeZone;

// import javax.xml.XMLConstants;
// import javax.xml.namespace.NamespaceContext;
// import javax.xml.parsers.DocumentBuilder;
// import javax.xml.parsers.DocumentBuilderFactory;
// import javax.xml.parsers.ParserConfigurationException;
// import javax.xml.xpath.XPath;
// import javax.xml.xpath.XPathConstants;
// import javax.xml.xpath.XPathException;
// import javax.xml.xpath.XPathExpressionException;
// import javax.xml.xpath.XPathFactory;

// import hunt.quartz.*;
// import hunt.quartz.DateBuilder : IntervalUnit;
// import hunt.quartz.impl.matchers.GroupMatcher;
// import hunt.quartz.spi.ClassLoadHelper;
// import hunt.quartz.spi.MutableTrigger;
// import hunt.logging;

// import org.w3c.dom.Document;
// import org.w3c.dom.Node;
// import org.w3c.dom.NodeList;
// import org.xml.sax.ErrorHandler;
// import org.xml.sax.InputSource;
// import org.xml.sax.SAXException;
// import org.xml.sax.SAXParseException;
// import javax.xml.bind.DatatypeConverter;


// /**
//  * Parses an XML file that declares Jobs and their schedules (Triggers), and processes the related data.
//  * 
//  * The xml document must conform to the format defined in
//  * "job_scheduling_data_2_0.xsd"
//  * 
//  * The same instance can be used again and again, however a single instance is not thread-safe.
//  * 
//  * @author James House
//  * @author Past contributions from <a href="mailto:bonhamcm@thirdeyeconsulting.com">Chris Bonham</a>
//  * @author Past contributions from pl47ypus
//  * 
//  * @since Quartz 1.8
//  */
// class XMLSchedulingDataProcessor : ErrorHandler {
//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Constants.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     enum string QUARTZ_NS = "http://www.quartz-scheduler.org/xml/JobSchedulingData";

//     enum string QUARTZ_SCHEMA_WEB_URL = "http://www.quartz-scheduler.org/xml/job_scheduling_data_2_0.xsd";
    
//     enum string QUARTZ_XSD_PATH_IN_JAR = "org/quartz/xml/job_scheduling_data_2_0.xsd";

//     enum string QUARTZ_XML_DEFAULT_FILE_NAME = "quartz_data.xml";

//     enum string QUARTZ_SYSTEM_ID_JAR_PREFIX = "jar:";
    

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Data members.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */

//     // pre-processing commands
//     protected List!(string) jobGroupsToDelete = new LinkedList!(string)();
//     protected List!(string) triggerGroupsToDelete = new LinkedList!(string)();
//     protected List!(JobKey) jobsToDelete = new LinkedList!(JobKey)();
//     protected List!(TriggerKey) triggersToDelete = new LinkedList!(TriggerKey)();

//     // scheduling commands
//     protected List!(JobDetail) loadedJobs = new LinkedList!(JobDetail)();
//     protected List!(MutableTrigger) loadedTriggers = new LinkedList!(MutableTrigger)();
    
//     // directives
//     private bool overWriteExistingData = true;
//     private bool ignoreDuplicates = false;

//     protected Collection!(Exception) validationExceptions = new ArrayList!(Exception)();

    
//     protected ClassLoadHelper classLoadHelper;
//     protected List!(string) jobGroupsToNeverDelete = new LinkedList!(string)();
//     protected List!(string) triggerGroupsToNeverDelete = new LinkedList!(string)();
    
//     private DocumentBuilder docBuilder = null;
//     private XPath xpath = null;
    

//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Constructors.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */
     
//     /**
//      * Constructor for JobSchedulingDataLoader.
//      * 
//      * @param clh               class-loader helper to share with digester.
//      * @throws ParserConfigurationException if the XML parser cannot be configured as needed. 
//      */
//     XMLSchedulingDataProcessor(ClassLoadHelper clh) {
//         this.classLoadHelper = clh;
//         initDocumentParser();
//     }
    
//     /**
//      * Initializes the XML parser.
//      * @throws ParserConfigurationException 
//      */
//     protected void initDocumentParser() {

//         DocumentBuilderFactory docBuilderFactory = DocumentBuilderFactory.newInstance();

//         docBuilderFactory.setNamespaceAware(true);
//         docBuilderFactory.setValidating(true);
        
//         docBuilderFactory.setAttribute("http://java.sun.com/xml/jaxp/properties/schemaLanguage", "http://www.w3.org/2001/XMLSchema");
        
//         docBuilderFactory.setAttribute("http://java.sun.com/xml/jaxp/properties/schemaSource", resolveSchemaSource());
        
//         docBuilder = docBuilderFactory.newDocumentBuilder();
        
//         docBuilder.setErrorHandler(this);
        
//         NamespaceContext nsContext = new NamespaceContext()
//         {
//           string getNamespaceURI(string prefix)
//           {
//               if (prefix is null)
//                   throw new IllegalArgumentException("Null prefix");
//               if (XMLConstants.XML_NS_PREFIX== prefix)
//                   return XMLConstants.XML_NS_URI;
//               if (XMLConstants.XMLNS_ATTRIBUTE== prefix)
//                   return XMLConstants.XMLNS_ATTRIBUTE_NS_URI;
        
//               if ("q"== prefix)
//                   return QUARTZ_NS;
        
//               return XMLConstants.NULL_NS_URI;
//           }
        
//           Iterator<?> getPrefixes(string namespaceURI)
//           {
//               // This method isn't necessary for XPath processing.
//               throw new UnsupportedOperationException();
//           }
        
//           string getPrefix(string namespaceURI)
//           {
//               // This method isn't necessary for XPath processing.
//               throw new UnsupportedOperationException();
//           }
        
//         }; 
        
//         xpath = XPathFactory.newInstance().newXPath();
//         xpath.setNamespaceContext(nsContext);
//     }
    
//     protected Object resolveSchemaSource() {
//         InputSource inputSource;

//         InputStream is = null;

//         try {
//             is = classLoadHelper.getResourceAsStream(QUARTZ_XSD_PATH_IN_JAR);
//         }  finally {
//             if (is !is null) {
//                 inputSource = new InputSource(is);
//                 inputSource.setSystemId(QUARTZ_SCHEMA_WEB_URL);
//                 trace("Utilizing schema packaged in local quartz distribution jar.");
//             }
//             else {
//                 info("Unable to load local schema packaged in quartz distribution jar. Utilizing schema online at " ~ QUARTZ_SCHEMA_WEB_URL);
//                 return QUARTZ_SCHEMA_WEB_URL;
//             }
                
//         }

//         return inputSource;
//     }

//     /**
//      * Whether the existing scheduling data (with same identifiers) will be 
//      * overwritten. 
//      * 
//      * If false, and <code>IgnoreDuplicates</code> is not false, and jobs or 
//      * triggers with the same names already exist as those in the file, an 
//      * error will occur.
//      * 
//      * @see #isIgnoreDuplicates()
//      */
//     bool isOverWriteExistingData() {
//         return overWriteExistingData;
//     }
    
//     /**
//      * Whether the existing scheduling data (with same identifiers) will be 
//      * overwritten. 
//      * 
//      * If false, and <code>IgnoreDuplicates</code> is not false, and jobs or 
//      * triggers with the same names already exist as those in the file, an 
//      * error will occur.
//      * 
//      * @see #setIgnoreDuplicates(bool)
//      */
//     protected void setOverWriteExistingData(bool overWriteExistingData) {
//         this.overWriteExistingData = overWriteExistingData;
//     }

//     /**
//      * If true (and <code>OverWriteExistingData</code> is false) then any 
//      * job/triggers encountered in this file that have names that already exist 
//      * in the scheduler will be ignored, and no error will be produced.
//      * 
//      * @see #isOverWriteExistingData()
//      */ 
//     bool isIgnoreDuplicates() {
//         return ignoreDuplicates;
//     }

//     /**
//      * If true (and <code>OverWriteExistingData</code> is false) then any 
//      * job/triggers encountered in this file that have names that already exist 
//      * in the scheduler will be ignored, and no error will be produced.
//      * 
//      * @see #setOverWriteExistingData(bool)
//      */ 
//     void setIgnoreDuplicates(bool ignoreDuplicates) {
//         this.ignoreDuplicates = ignoreDuplicates;
//     }

//     /**
//      * Add the given group to the list of job groups that will never be
//      * deleted by this processor, even if a pre-processing-command to
//      * delete the group is encountered.
//      */
//     void addJobGroupToNeverDelete(string group) {
//         if(group !is null)
//             jobGroupsToNeverDelete.add(group);
//     }
    
//     /**
//      * Remove the given group to the list of job groups that will never be
//      * deleted by this processor, even if a pre-processing-command to
//      * delete the group is encountered.
//      */
//     bool removeJobGroupToNeverDelete(string group) {
//         return group !is null && jobGroupsToNeverDelete.remove(group);
//     }

//     /**
//      * Get the (unmodifiable) list of job groups that will never be
//      * deleted by this processor, even if a pre-processing-command to
//      * delete the group is encountered.
//      */
//     List!(string) getJobGroupsToNeverDelete() {
//         return Collections.unmodifiableList(jobGroupsToDelete);
//     }

//     /**
//      * Add the given group to the list of trigger groups that will never be
//      * deleted by this processor, even if a pre-processing-command to
//      * delete the group is encountered.
//      */
//     void addTriggerGroupToNeverDelete(string group) {
//         if(group !is null)
//             triggerGroupsToNeverDelete.add(group);
//     }
    
//     /**
//      * Remove the given group to the list of trigger groups that will never be
//      * deleted by this processor, even if a pre-processing-command to
//      * delete the group is encountered.
//      */
//     bool removeTriggerGroupToNeverDelete(string group) {
//         if(group !is null)
//             return triggerGroupsToNeverDelete.remove(group);
//         return false;
//     }

//     /**
//      * Get the (unmodifiable) list of trigger groups that will never be
//      * deleted by this processor, even if a pre-processing-command to
//      * delete the group is encountered.
//      */
//     List!(string) getTriggerGroupsToNeverDelete() {
//         return Collections.unmodifiableList(triggerGroupsToDelete);
//     }
    
//     /*
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      * 
//      * Interface.
//      * 
//      * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//      */


//     /**
//      * Process the xml file in the default location (a file named
//      * "quartz_jobs.xml" in the current working directory).
//      *  
//      */
//     protected void processFile() {
//         processFile(QUARTZ_XML_DEFAULT_FILE_NAME);
//     }

//     /**
//      * Process the xml file named <code>fileName</code>.
//      * 
//      * @param fileName
//      *          meta data file name.
//      */
//     protected void processFile(string fileName) {
//         processFile(fileName, getSystemIdForFileName(fileName));
//     }

//     /**
//      * For the given <code>fileName</code>, attempt to expand it to its full path
//      * for use as a system id.
//      * 
//      * @see #getURL(string)
//      * @see #processFile()
//      * @see #processFile(string)
//      * @see #processFileAndScheduleJobs(Scheduler, bool)
//      * @see #processFileAndScheduleJobs(string, hunt.quartz.Scheduler)
//      */
//     protected string getSystemIdForFileName(string fileName) {
//         File file = new File(fileName); // files in filesystem
//         if (file.exists()) {
//             try {
//                 new FileInputStream(file).close();
//                 return file.toURI().toString();
//             }catch (IOException ignore) {
//                 return fileName;
//             }
//         } else {
//             URL url = getURL(fileName);
//             if (url is null) {
//                 return fileName;
//             } else {
//                 try {
//                     url.openStream().close();
//                     return url.toString();
//                 } catch (IOException ignore) {
//                     return fileName;
//                 }
//             }      
//         }
//     }

//     /**
//      * Returns an <code>URL</code> from the fileName as a resource.
//      * 
//      * @param fileName
//      *          file name.
//      * @return an <code>URL</code> from the fileName as a resource.
//      */
//     protected URL getURL(string fileName) {
//         return classLoadHelper.getResource(fileName); 
//     }

//     protected void prepForProcessing()
//     {
//         clearValidationExceptions();
        
//         setOverWriteExistingData(true);
//         setIgnoreDuplicates(false);

//         jobGroupsToDelete.clear();
//         jobsToDelete.clear();
//         triggerGroupsToDelete.clear();
//         triggersToDelete.clear();
        
//         loadedJobs.clear();
//         loadedTriggers.clear();
//     }
    
//     /**
//      * Process the xmlfile named <code>fileName</code> with the given system
//      * ID.
//      * 
//      * @param fileName
//      *          meta data file name.
//      * @param systemId
//      *          system ID.
//      */
//     protected void processFile(string fileName, string systemId) ParserConfigurationException,
//             SAXException, IOException, SchedulerException,
//             ClassNotFoundException, ParseException, XPathException {

//         prepForProcessing();
        
//         info("Parsing XML file: " ~ fileName + 
//                 " with systemId: " ~ systemId);
//         InputSource is = new InputSource(getInputStream(fileName));
//         is.setSystemId(systemId);
        
//         process(is);
        
//         maybeThrowValidationException();
//     }
    
//     /**
//      * Process the xmlfile named <code>fileName</code> with the given system
//      * ID.
//      * 
//      * @param stream
//      *          an input stream containing the xml content.
//      * @param systemId
//      *          system ID.
//      */
//     void processStreamAndScheduleJobs(InputStream stream, string systemId, Scheduler sched) ParserConfigurationException,
//             SAXException, XPathException, IOException, SchedulerException,
//             ClassNotFoundException, ParseException {

//         prepForProcessing();

//         info("Parsing XML from stream with systemId: " ~ systemId);

//         InputSource is = new InputSource(stream);
//         is.setSystemId(systemId);

//         process(is);
//         executePreProcessCommands(sched);
//         scheduleJobs(sched);

//         maybeThrowValidationException();
//     }
    
    
//     protected void process(InputSource is) {
        
//         // load the document 
//         Document document = docBuilder.parse(is);
        
//         //
//         // Extract pre-processing commands
//         //

//         NodeList deleteJobGroupNodes = (NodeList) xpath.evaluate(
//                 "/q:job-scheduling-data/q:pre-processing-commands/q:delete-jobs-in-group",
//                 document, XPathConstants.NODESET);

//         trace("Found " ~ deleteJobGroupNodes.getLength() ~ " delete job group commands.");

//         for (int i = 0; i < deleteJobGroupNodes.getLength(); i++) {
//             Node node = deleteJobGroupNodes.item(i);
//             string t = node.getTextContent();
//             if(t is null || (t = t.trim()).length() == 0)
//                 continue;
//             jobGroupsToDelete.add(t);
//         }

//         NodeList deleteTriggerGroupNodes = (NodeList) xpath.evaluate(
//                 "/q:job-scheduling-data/q:pre-processing-commands/q:delete-triggers-in-group",
//                 document, XPathConstants.NODESET);

//         trace("Found " ~ deleteTriggerGroupNodes.getLength() ~ " delete trigger group commands.");

//         for (int i = 0; i < deleteTriggerGroupNodes.getLength(); i++) {
//             Node node = deleteTriggerGroupNodes.item(i);
//             string t = node.getTextContent();
//             if(t is null || (t = t.trim()).length() == 0)
//                 continue;
//             triggerGroupsToDelete.add(t);
//         }

//         NodeList deleteJobNodes = (NodeList) xpath.evaluate(
//                 "/q:job-scheduling-data/q:pre-processing-commands/q:delete-job",
//                 document, XPathConstants.NODESET);

//         trace("Found " ~ deleteJobNodes.getLength() ~ " delete job commands.");

//         for (int i = 0; i < deleteJobNodes.getLength(); i++) {
//             Node node = deleteJobNodes.item(i);

//             string name = getTrimmedToNullString(xpath, "q:name", node);
//             string group = getTrimmedToNullString(xpath, "q:group", node);
            
//             if(name is null)
//                 throw new ParseException("Encountered a 'delete-job' command without a name specified.", -1);
//             jobsToDelete.add(new JobKey(name, group));
//         }

//         NodeList deleteTriggerNodes = (NodeList) xpath.evaluate(
//                 "/q:job-scheduling-data/q:pre-processing-commands/q:delete-trigger",
//                 document, XPathConstants.NODESET);

//         trace("Found " ~ deleteTriggerNodes.getLength() ~ " delete trigger commands.");

//         for (int i = 0; i < deleteTriggerNodes.getLength(); i++) {
//             Node node = deleteTriggerNodes.item(i);

//             string name = getTrimmedToNullString(xpath, "q:name", node);
//             string group = getTrimmedToNullString(xpath, "q:group", node);
            
//             if(name is null)
//                 throw new ParseException("Encountered a 'delete-trigger' command without a name specified.", -1);
//             triggersToDelete.add(new TriggerKey(name, group));
//         }
        
//         //
//         // Extract directives
//         //

//         Boolean overWrite = getBoolean(xpath, 
//                 "/q:job-scheduling-data/q:processing-directives/q:overwrite-existing-data", document);
//         if(overWrite is null) {
//             trace("Directive 'overwrite-existing-data' not specified, defaulting to " ~ isOverWriteExistingData());
//         }
//         else {
//             trace("Directive 'overwrite-existing-data' specified as: " ~ overWrite);
//             setOverWriteExistingData(overWrite);
//         }
        
//         Boolean ignoreDupes = getBoolean(xpath, 
//                 "/q:job-scheduling-data/q:processing-directives/q:ignore-duplicates", document);
//         if(ignoreDupes is null) {
//             trace("Directive 'ignore-duplicates' not specified, defaulting to " ~ isIgnoreDuplicates());
//         }
//         else {
//             trace("Directive 'ignore-duplicates' specified as: " ~ ignoreDupes);
//             setIgnoreDuplicates(ignoreDupes);
//         }
        
//         //
//         // Extract Job definitions...
//         //

//         NodeList jobNodes = (NodeList) xpath.evaluate("/q:job-scheduling-data/q:schedule/q:job",
//                 document, XPathConstants.NODESET);

//         trace("Found " ~ jobNodes.getLength() ~ " job definitions.");

//         for (int i = 0; i < jobNodes.getLength(); i++) {
//             Node jobDetailNode = jobNodes.item(i);
//             string t = null;

//             string jobName = getTrimmedToNullString(xpath, "q:name", jobDetailNode);
//             string jobGroup = getTrimmedToNullString(xpath, "q:group", jobDetailNode);
//             string jobDescription = getTrimmedToNullString(xpath, "q:description", jobDetailNode);
//             string jobClassName = getTrimmedToNullString(xpath, "q:job-class", jobDetailNode);
//             t = getTrimmedToNullString(xpath, "q:durability", jobDetailNode);
//             bool jobDurability = (t !is null) && t.equals("true");
//             t = getTrimmedToNullString(xpath, "q:recover", jobDetailNode);
//             bool jobRecoveryRequested = (t !is null) && t.equals("true");

//             Class<? extends Job> jobClass = classLoadHelper.loadClass(jobClassName, Job.class);

//             JobDetail jobDetail = newJob(jobClass)
//                 .withIdentity(jobName, jobGroup)
//                 .withDescription(jobDescription)
//                 .storeDurably(jobDurability)
//                 .requestRecovery(jobRecoveryRequested)
//                 .build();
            
//             NodeList jobDataEntries = (NodeList) xpath.evaluate(
//                     "q:job-data-map/q:entry", jobDetailNode,
//                     XPathConstants.NODESET);
            
//             for (int k = 0; k < jobDataEntries.getLength(); k++) {
//                 Node entryNode = jobDataEntries.item(k);
//                 string key = getTrimmedToNullString(xpath, "q:key", entryNode);
//                 string value = getTrimmedToNullString(xpath, "q:value", entryNode);
//                 jobDetail.getJobDataMap().put(key, value);
//             }
            
//             if(log.isDebugEnabled())
//                 trace("Parsed job definition: " ~ jobDetail);

//             addJobToSchedule(jobDetail);
//         }
        
//         //
//         // Extract Trigger definitions...
//         //

//         NodeList triggerEntries = (NodeList) xpath.evaluate(
//                 "/q:job-scheduling-data/q:schedule/q:trigger/*", document, XPathConstants.NODESET);

//         trace("Found " ~ triggerEntries.getLength() ~ " trigger definitions.");

//         for (int j = 0; j < triggerEntries.getLength(); j++) {
//             Node triggerNode = triggerEntries.item(j);
//             string triggerName = getTrimmedToNullString(xpath, "q:name", triggerNode);
//             string triggerGroup = getTrimmedToNullString(xpath, "q:group", triggerNode);
//             string triggerDescription = getTrimmedToNullString(xpath, "q:description", triggerNode);
//             string triggerMisfireInstructionConst = getTrimmedToNullString(xpath, "q:misfire-instruction", triggerNode);
//             string triggerPriorityString = getTrimmedToNullString(xpath, "q:priority", triggerNode);
//             string triggerCalendarRef = getTrimmedToNullString(xpath, "q:calendar-name", triggerNode);
//             string triggerJobName = getTrimmedToNullString(xpath, "q:job-name", triggerNode);
//             string triggerJobGroup = getTrimmedToNullString(xpath, "q:job-group", triggerNode);

//             int triggerPriority = Trigger.DEFAULT_PRIORITY;
//             if(triggerPriorityString !is null)
//                 triggerPriority = Integer.valueOf(triggerPriorityString);
            
//             string startTimeString = getTrimmedToNullString(xpath, "q:start-time", triggerNode);
//             string startTimeFutureSecsString = getTrimmedToNullString(xpath, "q:start-time-seconds-in-future", triggerNode);
//             string endTimeString = getTrimmedToNullString(xpath, "q:end-time", triggerNode);

//             //QTZ-273 : use of DatatypeConverter.parseDateTime() instead of SimpleDateFormat
//             Date triggerStartTime;
//             if(startTimeFutureSecsString !is null)
//                 triggerStartTime = new Date(DateTimeHelper.currentTimeMillis() + (Long.valueOf(startTimeFutureSecsString) * 1000L));
//             else 
//                 triggerStartTime = (startTimeString is null || startTimeString.length() == 0 ? new Date() : DatatypeConverter.parseDateTime(startTimeString).getTime());
//             Date triggerEndTime = endTimeString is null || endTimeString.length() == 0 ? null : DatatypeConverter.parseDateTime(endTimeString).getTime();

//             TriggerKey triggerKey = triggerKey(triggerName, triggerGroup);
            
//             ScheduleBuilder<?> sched;
            
//             if (triggerNode.getNodeName().equals("simple")) {
//                 string repeatCountString = getTrimmedToNullString(xpath, "q:repeat-count", triggerNode);
//                 string repeatIntervalString = getTrimmedToNullString(xpath, "q:repeat-interval", triggerNode);

//                 int repeatCount = repeatCountString is null ? 0 : Integer.parseInt(repeatCountString);
//                 long repeatInterval = repeatIntervalString is null ? 0 : Long.parseLong(repeatIntervalString);

//                 sched = simpleSchedule()
//                     .withIntervalInMilliseconds(repeatInterval)
//                     .withRepeatCount(repeatCount);
                
//                 if (triggerMisfireInstructionConst !is null && triggerMisfireInstructionConst.length() != 0) {
//                     if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_FIRE_NOW"))
//                         ((SimpleScheduleBuilder)sched).withMisfireHandlingInstructionFireNow();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_EXISTING_COUNT"))
//                         ((SimpleScheduleBuilder)sched).withMisfireHandlingInstructionNextWithExistingCount();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_RESCHEDULE_NEXT_WITH_REMAINING_COUNT"))
//                         ((SimpleScheduleBuilder)sched).withMisfireHandlingInstructionNextWithRemainingCount();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_EXISTING_REPEAT_COUNT"))
//                         ((SimpleScheduleBuilder)sched).withMisfireHandlingInstructionNowWithExistingCount();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_RESCHEDULE_NOW_WITH_REMAINING_REPEAT_COUNT"))
//                         ((SimpleScheduleBuilder)sched).withMisfireHandlingInstructionNowWithRemainingCount();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_SMART_POLICY")) {
//                         // do nothing.... (smart policy is default)
//                     }
//                     else
//                         throw new ParseException("Unexpected/Unhandlable Misfire Instruction encountered '" ~ triggerMisfireInstructionConst ~ "', for trigger: " ~ triggerKey, -1);
//                 }
//             } else if (triggerNode.getNodeName().equals("cron")) {
//                 string cronExpression = getTrimmedToNullString(xpath, "q:cron-expression", triggerNode);
//                 string timezoneString = getTrimmedToNullString(xpath, "q:time-zone", triggerNode);

//                 TimeZone tz = timezoneString is null ? null : TimeZone.getTimeZone(timezoneString);

//                 sched = cronSchedule(cronExpression)
//                     .inTimeZone(tz);

//                 if (triggerMisfireInstructionConst !is null && triggerMisfireInstructionConst.length() != 0) {
//                     if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_DO_NOTHING"))
//                         ((CronScheduleBuilder)sched).withMisfireHandlingInstructionDoNothing();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_FIRE_ONCE_NOW"))
//                         ((CronScheduleBuilder)sched).withMisfireHandlingInstructionFireAndProceed();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_SMART_POLICY")) {
//                         // do nothing.... (smart policy is default)
//                     }
//                     else
//                         throw new ParseException("Unexpected/Unhandlable Misfire Instruction encountered '" ~ triggerMisfireInstructionConst ~ "', for trigger: " ~ triggerKey, -1);
//                 }
//             } else if (triggerNode.getNodeName().equals("calendar-interval")) {
//                 string repeatIntervalString = getTrimmedToNullString(xpath, "q:repeat-interval", triggerNode);
//                 string repeatUnitString = getTrimmedToNullString(xpath, "q:repeat-interval-unit", triggerNode);

//                 int repeatInterval = Integer.parseInt(repeatIntervalString);

//                 IntervalUnit repeatUnit = IntervalUnit.valueOf(repeatUnitString);

//                 sched = calendarIntervalSchedule()
//                     .withInterval(repeatInterval, repeatUnit);

//                 if (triggerMisfireInstructionConst !is null && triggerMisfireInstructionConst.length() != 0) {
//                     if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_DO_NOTHING"))
//                         ((CalendarIntervalScheduleBuilder)sched).withMisfireHandlingInstructionDoNothing();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_FIRE_ONCE_NOW"))
//                         ((CalendarIntervalScheduleBuilder)sched).withMisfireHandlingInstructionFireAndProceed();
//                     else if(triggerMisfireInstructionConst.equals("MISFIRE_INSTRUCTION_SMART_POLICY")) {
//                         // do nothing.... (smart policy is default)
//                     }
//                     else
//                         throw new ParseException("Unexpected/Unhandlable Misfire Instruction encountered '" ~ triggerMisfireInstructionConst ~ "', for trigger: " ~ triggerKey, -1);
//                 }
//             } else {
//                 throw new ParseException("Unknown trigger type: " ~ triggerNode.getNodeName(), -1);
//             }

            
//             MutableTrigger trigger = (MutableTrigger) newTrigger()
//                 .withIdentity(triggerName, triggerGroup)
//                 .withDescription(triggerDescription)
//                 .forJob(triggerJobName, triggerJobGroup)
//                 .startAt(triggerStartTime)
//                 .endAt(triggerEndTime)
//                 .withPriority(triggerPriority)
//                 .modifiedByCalendar(triggerCalendarRef)
//                 .withSchedule(sched)
//                 .build();

//             NodeList jobDataEntries = (NodeList) xpath.evaluate(
//                     "q:job-data-map/q:entry", triggerNode,
//                     XPathConstants.NODESET);
            
//             for (int k = 0; k < jobDataEntries.getLength(); k++) {
//                 Node entryNode = jobDataEntries.item(k);
//                 string key = getTrimmedToNullString(xpath, "q:key", entryNode);
//                 string value = getTrimmedToNullString(xpath, "q:value", entryNode);
//                 trigger.getJobDataMap().put(key, value);
//             }
            
//             if(log.isDebugEnabled())
//                 trace("Parsed trigger definition: " ~ trigger);
            
//             addTriggerToSchedule(trigger);
//         }
//     }
    
//     protected string getTrimmedToNullString(XPath xpathToElement, string elementName, Node parentNode) {
//         string str = (string) xpathToElement.evaluate(elementName,
//                 parentNode, XPathConstants.STRING);
        
//         if(str !is null)
//             str = str.trim();
        
//         if(str !is null && str.length() == 0)
//             str = null;
        
//         return str;
//     }

//     protected Boolean getBoolean(XPath xpathToElement, string elementName, Document document) {
        
//         Node directive = (Node) xpathToElement.evaluate(elementName, document, XPathConstants.NODE);

//         if(directive is null || directive.getTextContent() is null)
//             return null;
        
//         string val = directive.getTextContent();
//         if(val.equalsIgnoreCase("true") || val.equalsIgnoreCase("yes") || val.equalsIgnoreCase("y"))
//             return Boolean.TRUE;
        
//         return Boolean.FALSE;
//     }

//     /**
//      * Process the xml file in the default location, and schedule all of the
//      * jobs defined within it.
//      * 
//      * <p>Note that we will set overWriteExistingJobs after the default xml is parsed. 
//      */
//     void processFileAndScheduleJobs(Scheduler sched,
//             bool overWriteExistingJobs) {
//         string fileName = QUARTZ_XML_DEFAULT_FILE_NAME;
//         processFile(fileName, getSystemIdForFileName(fileName));
//         // The overWriteExistingJobs flag was set by processFile() -> prepForProcessing(), then by xml parsing, and then now
//         // we need to reset it again here by this method parameter to override it.
//         setOverWriteExistingData(overWriteExistingJobs);
//         executePreProcessCommands(sched);
//         scheduleJobs(sched);
//     }

//     /**
//      * Process the xml file in the given location, and schedule all of the
//      * jobs defined within it.
//      * 
//      * @param fileName
//      *          meta data file name.
//      */
//     void processFileAndScheduleJobs(string fileName, Scheduler sched) {
//         processFileAndScheduleJobs(fileName, getSystemIdForFileName(fileName), sched);
//     }
    
//     /**
//      * Process the xml file in the given location, and schedule all of the
//      * jobs defined within it.
//      * 
//      * @param fileName
//      *          meta data file name.
//      */
//     void processFileAndScheduleJobs(string fileName, string systemId, Scheduler sched) {
//         processFile(fileName, systemId);
//         executePreProcessCommands(sched);
//         scheduleJobs(sched);
//     }

//     /**
//      * Returns a <code>List</code> of jobs loaded from the xml file.
//      * <p/>
//      * 
//      * @return a <code>List</code> of jobs.
//      */
//     protected List!(JobDetail) getLoadedJobs() {
//         return Collections.unmodifiableList(loadedJobs);
//     }
    
//     /**
//      * Returns a <code>List</code> of triggers loaded from the xml file.
//      * <p/>
//      * 
//      * @return a <code>List</code> of triggers.
//      */
//     protected List!(MutableTrigger) getLoadedTriggers() {
//         return Collections.unmodifiableList(loadedTriggers);
//     }

//     /**
//      * Returns an <code>InputStream</code> from the fileName as a resource.
//      * 
//      * @param fileName
//      *          file name.
//      * @return an <code>InputStream</code> from the fileName as a resource.
//      */
//     protected InputStream getInputStream(string fileName) {
//         return this.classLoadHelper.getResourceAsStream(fileName);
//     }
    
//     protected void addJobToSchedule(JobDetail job) {
//         loadedJobs.add(job);
//     }
    
//     protected void addTriggerToSchedule(MutableTrigger trigger) {
//         loadedTriggers.add(trigger);
//     }

//     private Map!(JobKey, List!(MutableTrigger)) buildTriggersByFQJobNameMap(List!(MutableTrigger) triggers) {
        
//         Map!(JobKey, List!(MutableTrigger)) triggersByFQJobName = new HashMap!(JobKey, List!(MutableTrigger))();
        
//         foreach(MutableTrigger trigger; triggers) {
//             List!(MutableTrigger) triggersOfJob = triggersByFQJobName.get(trigger.getJobKey());
//             if(triggersOfJob is null) {
//                 triggersOfJob = new LinkedList!(MutableTrigger)();
//                 triggersByFQJobName.put(trigger.getJobKey(), triggersOfJob);
//             }
//             triggersOfJob.add(trigger);
//         }

//         return triggersByFQJobName;
//     }
    
//     protected void executePreProcessCommands(Scheduler scheduler) {
        
//         foreach(string group; jobGroupsToDelete) {
//             if(group.equals("*")) {
//                 info("Deleting all jobs in ALL groups.");
//                 foreach(string groupName ; scheduler.getJobGroupNames()) {
//                     if (!jobGroupsToNeverDelete.contains(groupName)) {
//                         foreach(JobKey key ; scheduler.getJobKeys(GroupMatcher.jobGroupEquals(groupName))) {
//                             scheduler.deleteJob(key);
//                         }
//                     }
//                 }
//             }
//             else {
//                 if(!jobGroupsToNeverDelete.contains(group)) {
//                     info("Deleting all jobs in group: {}", group);
//                     foreach(JobKey key ; scheduler.getJobKeys(GroupMatcher.jobGroupEquals(group))) {
//                         scheduler.deleteJob(key);
//                     }
//                 }
//             }
//         }
        
//         foreach(string group; triggerGroupsToDelete) {
//             if(group.equals("*")) {
//                 info("Deleting all triggers in ALL groups.");
//                 foreach(string groupName ; scheduler.getTriggerGroupNames()) {
//                     if (!triggerGroupsToNeverDelete.contains(groupName)) {
//                         foreach(TriggerKey key ; scheduler.getTriggerKeys(GroupMatcher.triggerGroupEquals(groupName))) {
//                             scheduler.unscheduleJob(key);
//                         }
//                     }
//                 }
//             }
//             else {
//                 if(!triggerGroupsToNeverDelete.contains(group)) {
//                     info("Deleting all triggers in group: {}", group);
//                     foreach(TriggerKey key ; scheduler.getTriggerKeys(GroupMatcher.triggerGroupEquals(group))) {
//                         scheduler.unscheduleJob(key);
//                     }
//                 }
//             }
//         }
        
//         foreach(JobKey key; jobsToDelete) {
//             if(!jobGroupsToNeverDelete.contains(key.getGroup())) {
//                 info("Deleting job: {}", key);
//                 scheduler.deleteJob(key);
//             } 
//         }
        
//         foreach(TriggerKey key; triggersToDelete) {
//             if(!triggerGroupsToNeverDelete.contains(key.getGroup())) {
//                 info("Deleting trigger: {}", key);
//                 scheduler.unscheduleJob(key);
//             }
//         }
//     }

//     /**
//      * Schedules the given sets of jobs and triggers.
//      * 
//      * @param sched
//      *          job scheduler.
//      * @exception SchedulerException
//      *              if the Job or Trigger cannot be added to the Scheduler, or
//      *              there is an internal Scheduler error.
//      */
    
//     protected void scheduleJobs(Scheduler sched) {
        
//         List!(JobDetail) jobs = new LinkedList!(JobDetail)(getLoadedJobs());
//         List!(MutableTrigger) triggers = new LinkedList!(MutableTrigger)( getLoadedTriggers());
        
//         info("Adding " ~ jobs.size() ~ " jobs, " ~ triggers.size() ~ " triggers.");
        
//         Map!(JobKey, List!(MutableTrigger)) triggersByFQJobName = buildTriggersByFQJobNameMap(triggers);
        
//         // add each job, and it's associated triggers
//         Iterator!(JobDetail) itr = jobs.iterator();
//         while(itr.hasNext()) {
//             JobDetail detail = itr.next();
//             itr.remove(); // remove jobs as we handle them...

//             JobDetail dupeJ = null;
//             try {
//                 // The existing job could have been deleted, and Quartz API doesn't allow us to query this without
//                 // loading the job class, so use try/catch to handle it.
//                 dupeJ = sched.getJobDetail(detail.getKey());
//             } catch (JobPersistenceException e) {
//                 if (e.getCause() instanceof ClassNotFoundException && isOverWriteExistingData()) {
//                     // We are going to replace jobDetail anyway, so just delete it first.
//                     info("Removing job: " ~ detail.getKey());
//                     sched.deleteJob(detail.getKey());
//                 } else {
//                     throw e;
//                 }
//             }

//             if ((dupeJ !is null)) {
//                 if(!isOverWriteExistingData() && isIgnoreDuplicates()) {
//                     info("Not overwriting existing job: " ~ dupeJ.getKey());
//                     continue; // just ignore the entry
//                 }
//                 if(!isOverWriteExistingData() && !isIgnoreDuplicates()) {
//                     throw new ObjectAlreadyExistsException(detail);
//                 }
//             }
            
//             if (dupeJ !is null) {
//                 info("Replacing job: " ~ detail.getKey());
//             } else {
//                 info("Adding job: " ~ detail.getKey());
//             }
            
//             List!(MutableTrigger) triggersOfJob = triggersByFQJobName.get(detail.getKey());
            
//             if (!detail.isDurable() && (triggersOfJob is null || triggersOfJob.size() == 0)) {
//                 if (dupeJ is null) {
//                     throw new SchedulerException(
//                         "A new job defined without any triggers must be durable: " ~ 
//                         detail.getKey());
//                 }
                
//                 if ((dupeJ.isDurable() && 
//                     (sched.getTriggersOfJob(
//                         detail.getKey()).size() == 0))) {
//                     throw new SchedulerException(
//                         "Can't change existing durable job without triggers to non-durable: " ~ 
//                         detail.getKey());
//                 }
//             }
            
            
//             if(dupeJ !is null || detail.isDurable()) {
//                 if (triggersOfJob !is null && triggersOfJob.size() > 0)
//                     sched.addJob(detail, true, true);  // add the job regardless is durable or not b/c we have trigger to add
//                 else
//                     sched.addJob(detail, true, false); // add the job only if a replacement or durable, else exception will throw!
//             }
//             else {
//                 bool addJobWithFirstSchedule = true;

//                 // Add triggers related to the job...
//                 foreach(MutableTrigger trigger ; triggersOfJob) {
//                     triggers.remove(trigger);  // remove triggers as we handle them...

//                     if (trigger.getStartTime() is null) {
//                         trigger.setStartTime(new Date());
//                     }

//                     Trigger dupeT = sched.getTrigger(trigger.getKey());
//                     if (dupeT !is null) {
//                         if (isOverWriteExistingData()) {
//                             version(HUNT_DEBUG) {
//                                 trace(
//                                         "Rescheduling job: " ~ trigger.getJobKey() ~ " with updated trigger: " ~ trigger.getKey());
//                             }
//                         } else if (isIgnoreDuplicates()) {
//                             info("Not overwriting existing trigger: " ~ dupeT.getKey());
//                             continue; // just ignore the trigger (and possibly job)
//                         } else {
//                             throw new ObjectAlreadyExistsException(trigger);
//                         }

//                         if (!dupeT.getJobKey()== trigger.getJobKey()) {
//                             log.warn("Possibly duplicately named ({}) triggers in jobs xml file! ", trigger.getKey());
//                         }

//                         sched.rescheduleJob(trigger.getKey(), trigger);
//                     } else {
//                         version(HUNT_DEBUG) {
//                             trace(
//                                     "Scheduling job: " ~ trigger.getJobKey() ~ " with trigger: " ~ trigger.getKey());
//                         }

//                         try {
//                             if (addJobWithFirstSchedule) {
//                                 sched.scheduleJob(detail, trigger); // add the job if it's not in yet...
//                                 addJobWithFirstSchedule = false;
//                             } else {
//                                 sched.scheduleJob(trigger);
//                             }
//                         } catch (ObjectAlreadyExistsException e) {
//                             version(HUNT_DEBUG) {
//                                 trace(
//                                         "Adding trigger: " ~ trigger.getKey() ~ " for job: " ~ detail.getKey() +
//                                                 " failed because the trigger already existed.  " ~
//                                                 "This is likely due to a race condition between multiple instances " ~
//                                                 "in the cluster.  Will try to reschedule instead.");
//                             }

//                             // Let's try one more time as reschedule.
//                             sched.rescheduleJob(trigger.getKey(), trigger);
//                         }
//                     }
//                 }
//             }
//         }
        
//         // add triggers that weren't associated with a new job... (those we already handled were removed above)
//         foreach(MutableTrigger trigger; triggers) {
            
//             if(trigger.getStartTime() is null) {
//                 trigger.setStartTime(new Date());
//             }
            
//             Trigger dupeT = sched.getTrigger(trigger.getKey());
//             if (dupeT !is null) {
//                 if(isOverWriteExistingData()) {
//                     version(HUNT_DEBUG) {
//                         trace(
//                             "Rescheduling job: " ~ trigger.getJobKey() ~ " with updated trigger: " ~ trigger.getKey());
//                     }
//                 }
//                 else if(isIgnoreDuplicates()) {
//                     info("Not overwriting existing trigger: " ~ dupeT.getKey());
//                     continue; // just ignore the trigger 
//                 }
//                 else {
//                     throw new ObjectAlreadyExistsException(trigger);
//                 }
                
//                 if(!dupeT.getJobKey()== trigger.getJobKey()) {
//                     log.warn("Possibly duplicately named ({}) triggers in jobs xml file! ", trigger.getKey());
//                 }
                
//                 sched.rescheduleJob(trigger.getKey(), trigger);
//             } else {
//                 version(HUNT_DEBUG) {
//                     trace(
//                         "Scheduling job: " ~ trigger.getJobKey() ~ " with trigger: " ~ trigger.getKey());
//                 }

//                 try {
//                     sched.scheduleJob(trigger);
//                 } catch (ObjectAlreadyExistsException e) {
//                     version(HUNT_DEBUG) {
//                         trace(
//                             "Adding trigger: " ~ trigger.getKey() ~ " for job: " ~trigger.getJobKey() + 
//                             " failed because the trigger already existed.  " ~
//                             "This is likely due to a race condition between multiple instances " ~ 
//                             "in the cluster.  Will try to reschedule instead.");
//                     }

//                     // Let's rescheduleJob one more time.
//                     sched.rescheduleJob(trigger.getKey(), trigger);
//                 }
//             }
//         }
//     }

//     /**
//      * ErrorHandler interface.
//      * 
//      * Receive notification of a warning.
//      * 
//      * @param e
//      *          The error information encapsulated in a SAX parse exception.
//      * @exception SAXException
//      *              Any SAX exception, possibly wrapping another exception.
//      */
//     void warning(SAXParseException e) {
//         addValidationException(e);
//     }

//     /**
//      * ErrorHandler interface.
//      * 
//      * Receive notification of a recoverable error.
//      * 
//      * @param e
//      *          The error information encapsulated in a SAX parse exception.
//      * @exception SAXException
//      *              Any SAX exception, possibly wrapping another exception.
//      */
//     void error(SAXParseException e) {
//         addValidationException(e);
//     }

//     /**
//      * ErrorHandler interface.
//      * 
//      * Receive notification of a non-recoverable error.
//      * 
//      * @param e
//      *          The error information encapsulated in a SAX parse exception.
//      * @exception SAXException
//      *              Any SAX exception, possibly wrapping another exception.
//      */
//     void fatalError(SAXParseException e) {
//         addValidationException(e);
//     }

//     /**
//      * Adds a detected validation exception.
//      * 
//      * @param e
//      *          SAX exception.
//      */
//     protected void addValidationException(SAXException e) {
//         validationExceptions.add(e);
//     }

//     /**
//      * Resets the the number of detected validation exceptions.
//      */
//     protected void clearValidationExceptions() {
//         validationExceptions.clear();
//     }

//     /**
//      * Throws a ValidationException if the number of validationExceptions
//      * detected is greater than zero.
//      * 
//      * @exception ValidationException
//      *              DTD validation exception.
//      */
//     protected void maybeThrowValidationException() {
//         if (validationExceptions.size() > 0) {
//             throw new ValidationException("Encountered " ~ validationExceptions.size() ~ " validation exceptions.", validationExceptions);
//         }
//     }
// }
