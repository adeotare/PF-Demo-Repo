/* Description: purpose of this class is to copy data from one record to another record 
* through twin field functionality. If the field has the same API name and same soap type 
* then the data will automatically copy over from parent to child with the corresponding  
* twin object mapping record created - individual fields can be overridden with the 
* twin object field mapping. This mimics the twin fielding functionality of the Salesforce CPQ Package. */

public without sharing class CA2_TwinField {
    //constructor - must be run in trigger context
    public static void runTwinHelper(List<sObject> sObjectList) {
        twinHelper(sObjectList);
    }
    public class TwinFieldException extends Exception {}
    //moving global describe for performance caching
    
    public static Map<String, Schema.SObjectType> gd {get {
        if(gd == null) {
            gd = Schema.getGlobalDescribe();
        }
        return gd;
    } set;}
    
    private static Map<String, Schema.DescribeSObjectResult> objectDescribeMap = new Map<String, Schema.DescribeSObjectResult>();
    //accessor method to get the Schema.DescribeSObjectResult for a given object's api name
    public static Schema.DescribeSObjectResult getObjectDescribe(String objectApiName) {
        Schema.DescribeSObjectResult returnResult = objectDescribeMap.get(objectApiName);
        if(returnResult == null) {
            returnResult = gd.get(objectAPIName).getDescribe();
            objectDescribeMap.put(objectApiName, returnResult);
        }
        return  returnResult;
    }
    
    //for unit tests
    private static boolean testRecords { get{
        return Test.isRunningTest();
    }}
    
    //set of fields to exclude from queries
    private static Set<String> globalExclusionSet = new Set<String>{        
        'Id',
            'CreatedDate',
            'CreatedById',
            'LastModifiedDate',
            'LastModifiedById',
            'IsDeleted',
            'SystemModstap',
            'LastViewedDate',
            'LastReferencedDate',
            'RecordTypeId',
            'Status',
            'QS_Asset__c',
            'QS_Asset_Status__c',
            'QS_Contract__c',
            'QS_Currently_Active__c',
            'QS_Customer_Asset__c',
            'QS_Decommission_Reason__c',
            'Effective_Decommission_Date__c',
            'QS_End_Date__c',
            'QS_Maintain_Line__c',
            'QS_Product__c',
            'QS_Start_Date__c',
            'QS_Subscribed_Asset__c',
            'QS_Subscription__c',
            'QS_Quote_Line__c'
            };
                
                private static Map<String, ObjectHelper> objectHelperMap = new Map<String, ObjectHelper>();
    
    //returns the object helper based upon the object name
    @TestVisible
    private static ObjectHelper getObjectHelper(String objectName) {
        System.debug(objectName);
        if(objectHelperMap.get(objectName) == null) {
            //        System.debug(objectName);
            new ObjectHelper(objectName);
        }
        //    System.debug(objectName);
        return objectHelperMap.get(objectName);
    }
    
    //object helper is a class to cache metadata and help reduce any performance concerns that are native with the schema calls
    @TestVisible
    private class ObjectHelper {
        public Set<String>                      writableFields = new Set<String>(); //used for the target object overrides
        public Set<String>                      allFields = new Set<String>();
        public Set<String>                      allButExcludedFields = new Set<String>();
        public Set<String>                      fieldNamesIgnoringNamespace = new Set<String>();          
        public Set<String>                      exclusionSet = new Set<String>(); //list of exluded fields could vary per object in the future
        //public Schema.SObjectType               sObjType;
        public Schema.DescribeSObjectResult     sObjDescribe;
        public Map<String, Schema.SObjectField> fields;
        public String                           name {get {return sObjDescribe.getName();}}
        
        public ObjectHelper(String objectName) {
            System.debug(objectName);
            sObjDescribe    = getObjectDescribe(objectName); //set description of object
            if(sObjDescribe == null) {
                System.debug('Invalid object name: ' + objectName);
                throw new TwinFieldException('Invalid object name: ' + sObjDescribe);
            }
            fields          = sObjDescribe.fields.getMap(); //set field map
            exclusionSet    = globalExclusionSet; //set the excluded fields
            
            //populate field sets initializes writableFields and all fields
            populateFieldSets();
            
            writableFields = removeExclusions(writableFields); //remove the exluded fields
            
            allButExcludedFields = removeExclusions(allFields); //remove the exluded fields            
            fieldNamesIgnoringNamespace = removeExclusions(fieldNamesIgnoringNamespace);
            objectHelperMap.put(objectName, this);
        }
        
        //build the set of fields
        public void populateFieldSets() {
            for(SObjectField field : fields.values()) {
                Schema.DescribeFieldResult describeResult = field.getDescribe();
                if(describeResult.isCreateable() && describeResult.isUpdateable()) {
                    writableFields.add(describeResult.getName());
                }
                fieldNamesIgnoringNamespace.add(fieldNameIgnoringNamespace(describeResult.getName()));
                allFields.add(describeResult.getName());
            }
            //writableFields.add('CurrencyIsoCode');
            //fieldNamesIgnoringNamespace.add('CurrencyIsoCode');
            //allFields.add('CurrencyIsoCode');
        }
        private Set<String> removeExclusions(Set<String> allFields) {
            Set<String> returnSet = allFields.clone();
            for(String s: exclusionSet) {
                returnSet.remove(s);
            }
            return returnSet;
        }
    }
    
    
    //to be called from the trigger event
    //loops through the twin records to see if a twin is needed - then loops through the corresponding sObject lists and twins as configured
    @TestVisible 
    private static void twinHelper(List<sObject> targetRecords) {
        if(targetRecords == null || targetRecords.isEmpty()) { return; }
        sObject firstRecord = targetRecords[0];
        String targetObjectName = firstRecord.getSObjectType().getDescribe().getName();
        if(targetObjectName != 'QS_Customer_Asset_Detail__c' && targetObjectName != 'QS_Customer_Asset__c' ) {
            throw new TwinFieldException('Unsupported object type: ' + targetObjectName);
        }
        /* First Level - Direct Relationship fields */
        Map<String, String> fieldNameToObjectName = new Map<String, String>(); //key is the relationship name of the field, value is the object name
        List<String> fieldsToProcess = new List<String>(); //ordered list to process values
        if(targetObjectName == 'QS_Customer_Asset_Detail__c') { 
            fieldNameToObjectName.put('QS_Asset__c', 'Asset');
            fieldNameToObjectName.put('QS_Subscription__c', 'SBQQ__Subscription__c'); 
            fieldNameToObjectName.put('QS_Quote_Line__c', 'SBQQ__QuoteLine__c'); 
            fieldsToProcess.add('QS_Asset__c');
            fieldsToProcess.add('QS_Subscription__c');
            fieldsToProcess.add('QS_Quote_Line__c');
           
        }   
        else {
            throw new TwinFieldException('Unsupported object: ' + targetObjectName);
        }
        
        //populate IDS for records to query
        
        for(String field: fieldsToProcess) {
            String lookupField                                  = field;
            ObjectHelper source                                 = getObjectHelper(fieldNametoObjectName.get(field));
            //target object is the object that is getting the fields overwritten (e.g. the new object being created)
            ObjectHelper target                                 = getObjectHelper(targetObjectName);
            
            Set<Id> sourceIds                                   = pluckIds(targetRecords, lookupField);
            
            if(sourceIds.isEmpty()) { continue; } //return if no records to parse;
            if(source == null) {
                system.debug('no source found');
                continue;
            } else if(target == null) {
                system.debug('no target found');
                continue;
            }
            Map<Id, sObject> sourceRecordMap = new Map<Id, sObject>();
            
            for(sObject sobj: queryObjectDataByType(source.name, 
                                                    source.allButExcludedFields, 
                                                    null, 
                                                    null, 
                                                    sourceIds)) {
                                                        sourceRecordMap.put((Id)sobj.get('Id'), sobj);
                                                    }
            
            for(sObject targetObj: targetRecords) { //loop through the trigger records
                if(targetObj.get(lookupField) != null) { //ensure that the value is populated in the lookup
                    if(sourceRecordMap.get((Id)targetObj.get(lookupField)) != null) { //ensure that a record was quried in the db
                        sObject sourceObj = sourceRecordMap.get((Id)targetObj.get(lookupField)); //specify the source record to be replicated from
                        //   System.debug('TIGER sourceObj' + sourceObj);
                        for(String targetField: target.writableFields) { //loop through fields of target object
                            String sourceFieldVar;
                            String targetFieldVar;
                            if(target.writableFields.contains(targetfield)) {
                                targetFieldVar = targetField;
                            } else if (target.writableFields.contains(fieldNameIgnoringNamespace(targetField))) {
                                targetFieldVar = fieldNameIgnoringNamespace(targetField);
                            }
                            for(String sourceField: source.allButExcludedFields) {
                                if(sourceField == targetField) {
                                    sourceFieldVar = sourceField;
                                } else if (fieldNameIgnoringNamespace(sourceField) == targetFieldVar) {
                                    sourceFieldVar = sourceField;
                                } else if (fieldNameIgnoringNamespace(sourceField) == fieldNameIgnoringNamespace(targetFieldVar)) {
                                    sourceFieldVar = sourceField;
                                }
                            }
                            if(sourceFieldVar == null || targetFieldVar == null) {
                                continue;
                            }
                            try {
                                if(replicateField(sourceObj.get(sourceFieldVar), source.fields.get(sourceFieldVar), target.fields.get(targetFieldVar))) {//check to see if we need to replicate this field
                                     if(sourceObj.get(sourceFieldVar) != null) {
                                        try {
                                            targetObj.put(targetFieldVar, sourceObj.get(sourceFieldVar));
                                         
                                            
                                        } catch (exception e) {
                                            system.debug('Error placing field value: ' + e);
                                        }
                                    }
                                }
                            } catch (Exception ex2) {
                                system.debug('failure ' + ex2);
                            }
                        }
                    }
                }
            }
        }
    }
    @TestVisible
    //query helper - get fields passed in for a given object - with an ID filter 
    private static List<SObject> queryObjectDataByType(String objectType, Set<String> fieldSet, String whereClause, Integer queryLimit, Set<Id> idSet) {
        List<SObject> returnList = new List<SObject>();
        //Don't allow open queries
        System.debug(fieldSet);
        System.debug(idSet);
        if(idSet != null & idSet.size() > 0) {
            String fieldnames = '';
            
            fieldSet.remove('Id');
            if (fieldSet != null && fieldSet.size() > 0) {
                for (String field : fieldSet) {
                    fieldnames += field + ',';
                }
            }
            fieldnames += ' Id '; //add ID field as the last field in the array
            
            string query = 'SELECT ' + fieldnames + ' FROM ' + objectType;
            Boolean whereBool = false;
            if (whereClause != null && whereClause != '') {
                whereBool = true;
                query = query + ' WHERE ' + whereClause;
            }
            if (idSet != null && idSet.size() > 0) {
                if (whereBool == true) {
                    query = query + ' AND Id IN: idSet ';
                } else {
                    query = query + ' WHERE Id IN: idSet ';
                }
            }
            if (queryLimit != null && queryLimit > 0) {
                query = query + ' LIMIT ' + queryLimit;
            }
            if (query != null && query != '') {
                System.debug('=======> query: ' + query);
                returnList = database.query(query);
            }
        } else {
            System.assert(false, 'Must use ID set to filter this query.');
        }
        return returnList;
    }
    
    //method to determine if we should copy the source field into the target field
    private static Boolean replicateField(Object fieldValue, Schema.SObjectField sourceField, Schema.SObjectField targetField) {
        Schema.DescribeFieldResult sourceDescription = sourceField.getDescribe();
        Schema.DescribeFieldResult targetDescription = targetField.getDescribe();
        return fieldMatchesType(fieldValue, sourceDescription, targetDescription);
    }
    
    public static String fieldNameIgnoringNamespace(String fieldName) {
        String returnValue = fieldName;
        if(fieldName.contains('__')) {
            String[] splitString = fieldName.split('__');
            if(splitString.size() == 3) { //all namespace fields are custom so starts with SBQQ__ and ends with __c
                returnValue = splitString[1] + '__' + splitString [2];
            }
        } 
        return returnValue;
    }
    public static String nameSpacePrefix(String fieldName) {
        String returnValue;
        if(fieldName.contains('__')) {
            String[] splitString = fieldName.split('__');
            if(splitString.size() == 3) { //all namespace fields are custom so starts with SBQQ__ and ends with __c
                returnValue = splitString[0];
            }
        } 
        return returnValue;
    }
    //method to determine if the soap type / lookup relation is the same
    private static Boolean fieldMatchesType(Object fieldValue, Schema.DescribeFieldResult sourceField, Schema.DescribeFieldResult targetField) {
        //System.debug('TIGER Source Field-->' + sourceField + '     ' + 'Target field-->' + targetField);
        
        if(sourceField.getSOAPType() == targetField.getSOAPType()) {
            //   System.debug('TIGER Twin Field Reference to Check ' + sourceField.getReferenceTo() + '    ' + targetField.getReferenceTo());
            if(sourceField.getReferenceTo() != null || targetField.getReferenceTo() != null) {
                
                
                if(sourceField.getReferenceTo() == targetField.getReferenceTo()) {
                    return true;
                } else {
                    //handle polymorphic fields - twin if possible
                    try {
                        Id lookupFieldId = (Id)fieldValue;
                        if(targetField.getReferenceTo().contains(lookupFieldId.getSobjectType())) {
                            return true;
                        } else {
                            return false;
                        }
                    } catch (exception e) {
                        System.debug(e);
                        return false;
                    }
                }
                
            } else {
                return true;
            }
        }
        return false;
    }
    //helper to pluck a set of IDs from a set of records
    private static Set<Id> pluckIds(List<sObject> sobjects, String idField) {
        
        Set<Id> returnSet = new Set<Id>();
        for(sObject sobj: sObjects) {
            try {
                returnSet.add((Id)sobj.get(idField));
            } catch (exception e) {
                system.debug('Ignoring record: ' + e);
            }
        }
        
        returnSet.remove(null);
        return returnSet;
    }
    
    
    
}