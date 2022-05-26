public with sharing class P7InverterSubarrayInfo {
    public Static String rowGeneratorAttrName = Constants.SUB_ARRAY;
        public Static String prepopulateColumnName = Constants.INVERTER_NAME;
        public Static String parentSiteMetadataPrompt = Constants.P5_INVERTS_BUILD_AND_COUNTS; 
        public Static String currentPromptName = Constants.P7_INVERTER_SUBARRAY_INFO;
        public Static String assetName = Constants.SUBARRAY_NAME;

        /*
         * Query Site Metadata record for current prompt name and Plant Asset Id , and check if any record exists,
	    if No,
            a. Create a record in Plant Asset Prompt Detail Object  for the current  Prompt 
            b. For Current  prompt specific  attribute (Subarray Name) , form a sequence based on the row generation prompt attribute count and the parent attribute . (eg., I1-Subarray-01, Parent name -I1 , Row generation prompt attribute count -01). 
            c. Query Site Metadata record of current prompt and return to lwc "assetBuilderCustomDatatable" for prompt table creation through
                    the current prompt  lwc component
        if yes,
            a. New Site Metadata records are  newly created for the current prompt
            b. Query the Plant Asset Prompt Detail  of current prompt and compares the "Previous_Plant_Asset_Prompt__c" field  with the previous prompt name ,
                if not matched,
                        Previous_Plant_Asset_Prompt__c field is updated with previous prompt name.
            c. Query Site Metadata record of current prompt and return to lwc  "assetBuilderCustomDatatable" for prompt table creation through 
                the current prompt  lwc component
        
        @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
        @param {String} jsonInputParametersAndValues - Holds the BulkImport Boolean variable as true or false.
        */
        @AuraEnabled
        public static String getCustomDatatableCompInput(String plantAssetId, String previousPromptName, Boolean isClearExecuted, String jsonInputParametersAndValues){
            Savepoint sp = Database.setSavepoint();
            try {
                Boolean isBulkUploadCheck = false; //This attibute holds whether the prompt navigates based on BulkImport or User Guided Navigation
                if(!String.isBlank(jsonInputParametersAndValues)){
                    Map<String,String> jsonInputParametersAndValuesMap = Utils.deserializeAttribute(jsonInputParametersAndValues);
                    isBulkUploadCheck = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD));
                }

                Id basetAssetId;
                String baseAssetShortName;
                String csvData;
                List<Core_Attribute__c> filteredCoreAttributes = new List<Core_Attribute__c>();
                List<Core_Attribute__c> coreAttributes = new List<Core_Attribute__c>();
                Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName,plantAssetId);
                Integer currentSitemetadataCount = 0;
    
                if(!String.isBlank(jsonInputParametersAndValues)){
                    Map<String,String> jsonInputParametersAndValuesMap = Utils.deserializeAttribute(jsonInputParametersAndValues);
                    Boolean isImpWizUpLoad = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_IMPWIZ_UPLOAD));
                    Boolean isOverride = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_OVERRIDE));
                    if(isImpWizUpLoad && isOverride) {
                        csvData = Utils2.getImpWizCSVFileforPrompts(jsonInputParametersAndValues, plantAssetId, currentPromptName);
                    } else {
                        csvData = Utils.getBulkUploadCSVFileforPrompts(jsonInputParametersAndValues, plantAssetId, currentPromptName);
                    }                
                }

                List<Site_Metadata__c> g1PromptSiteMetadata = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);
                Boolean bifacialModules = false;
    
                if(g1PromptSiteMetadata.size() > 0){
                    Map<String, String> promptSpecificInfoMap = 
                                (Map<String, String>) System.JSON.deserialize(g1PromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class); 
                    if(promptSpecificInfoMap.containsKey(Constants.BIFACIAL_MODULES)){
                        bifacialModules = promptSpecificInfoMap.get(Constants.BIFACIAL_MODULES) == 'true' ? true : false;
                    }
                }

                if(promptInfo.Base_Asset_Template__c != NULL){
                    basetAssetId = promptInfo.Base_Asset_Template__c;
                    baseAssetShortName = promptInfo.Base_Asset_Template__r.Asset_Short_Name__c;
                    Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
                    Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
                    Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
                    filteredCoreAttributes = Utils.queryCoreAttributesP7(basetAssetId, filteredAttributesId, bifacialModules);
                    coreAttributes = Utils.queryCoreAttributesP7(basetAssetId, allAttributesId, bifacialModules);
                }
                List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);
                
                String coreAttributeInfoJSON = Utils.serializeAttribute(coreAttributes);
                Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
                
                // Query current prompt site metadata table rows
                List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
                String parentPlantAssetPromptDetail;

                List<Site_Metadata__c> rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(parentSiteMetadataPrompt, plantAssetId);
                
                // The currentSitemetadataCount is get the count of current sitemetadata records
                for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                    Map<String, String> promptSpecificInfoMap = 
                        (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                    if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){
                        if(!String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                            currentSitemetadataCount += Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName));
                        }
                    }
                }

                if(currentSitemetadataCount >= Constants.RECORD_COUNT_FOR_EACH_PROMPT && currentPromptSiteMetadata.size()<=0){
                    if(rowGeneratorPromptSiteMetadata.size()>0){
                        parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
                    }
                    list<Plant_Asset_Prompt_Detail__c> plantAssetPromptDetailLst = [SELECT Id,Name FROM Plant_Asset_Prompt_Detail__c WHERE 
                    Account_Plant__c =: plantAssetId AND Is_Deleted__c = false AND
                        Prompt_Information__r.Name =: currentPromptName];
                    if(plantAssetPromptDetailLst.size()<=0){
                        Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                        insert plantAssetPromptCreateInstance; 
                    }
                }

                if(currentSitemetadataCount < Constants.RECORD_COUNT_FOR_EACH_PROMPT){
                    if(currentPromptSiteMetadata.size()<=0){
                        // Query previous prompt site metadata to populate table rows
                        List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                        if(rowGeneratorPromptSiteMetadata.size()>0){
                            parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
                        }
                        Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, 
                            previousPromptName, parentPlantAssetPromptDetail);
                        insert plantAssetPromptCreateInstance;
                        if(rowGeneratorPromptSiteMetadata.size() > 0){
                            if(!String.isBlank(rowGeneratorAttrName)){
                                for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                                    Map<String, String> promptSpecificInfoMap = 
                                        (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                                    if(!String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                                        Integer subArrayCount = Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName));
                                        for(Integer i = 1;i<= subArrayCount;i++ ){
                                            String prepopulateColumnValue = promptSpecificInfoMap.get(prepopulateColumnName);
                                            promptAttributeInfo.put(prepopulateColumnName,rowGenMetadata.Id);
                                            String promptAttrName = prepopulateColumnValue + ' - '+ 'Subarray ' + ((subArrayCount >= 1)?string.valueof(i).leftPad(2, '0'):'');
                                            promptAttributeInfo.put(assetName,promptAttrName);
                                            Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                plantAssetPromptCreateInstance.Id, coreAttributeInfoJSON, rowGenMetadata.Id, basetAssetId, promptInfo.Id, promptAttrName);
                                                siteMetadata.Asset_Short_Name__c = baseAssetShortName+string.valueof(i).leftPad(2, '0');
                                                siteMetadata.Parent_Asset_Short_Name__c = rowGenMetadata.Parent_Asset_Short_Name__c +'\\'+
                                                                                                rowGenMetadata.Asset_Short_Name__c;
                                                siteMetadataCreation.add(siteMetadata);
                                        }                
                                    }
                                }
                                if(siteMetadataCreation.size()>0){
                                    //sitemetadata insert in Util method
                                    Utils.insertSitemetadata(siteMetadataCreation);
                                }
                                currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
                            }
                        }else{
                            throw new AuraHandledException(System.Label.P7ValidationErrorOnInverterInfo);
                        }
                    }else if(isClearExecuted){
    
                        rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(parentSiteMetadataPrompt, plantAssetId);
                        Map<String,String> parentSiteMetadataRecord = new Map<String,String>();
    
                        for(Site_Metadata__c parentSiteMetadata : rowGeneratorPromptSiteMetadata){
                            Map <String,String> parentPromptSpecificInfoMap =
                                (Map<String, String > ) System.JSON.deserialize(parentSiteMetadata.Prompt_Specific_Info__c, Map < String, String > .class);
                            parentSiteMetadataRecord.put(string.valueof(parentSiteMetadata.Id),parentPromptSpecificInfoMap.get(prepopulateColumnName));
                        }
                       
                        Map<Id,Integer> parentSiteMetadataIdToCount = new Map<Id,Integer>();
                        List<Site_Metadata__c> updatepromptSiteMetaData = new List<Site_Metadata__c>();
    
                        for (Site_Metadata__c siteMetadata: currentPromptSiteMetadata) {
                            if (!parentSiteMetadataIdToCount.containsKey(siteMetadata.Parent_Site_Metadata__c)) {
                                parentSiteMetadataIdToCount.put(siteMetadata.Parent_Site_Metadata__c, 0);
                            }
                            
                            Integer count = parentSiteMetadataIdToCount.get(siteMetadata.Parent_Site_Metadata__c);
                            Integer recordNameSequenceNo  = count + 1;
                            parentSiteMetadataIdToCount.put(siteMetadata.Parent_Site_Metadata__c, recordNameSequenceNo);
                            Map <String,String> currentPromptSpecificInfoMap =
                                (Map<String, String > ) System.JSON.deserialize(siteMetadata.Prompt_Specific_Info__c, Map < String, String > .class);
                            if (String.isBlank(currentPromptSpecificInfoMap.get(assetName))) {
    
                                if(parentSiteMetadataRecord.containsKey(currentPromptSpecificInfoMap.get(prepopulateColumnName))){
                                    String prepopulateColumnMapValue = currentPromptSpecificInfoMap.get(prepopulateColumnName);
                                    String promptAttrName = parentSiteMetadataRecord.get(prepopulateColumnMapValue) + ' - ' + 'Subarray ' + string.valueof(recordNameSequenceNo).leftPad(2, '0') + '';
                                    currentPromptSpecificInfoMap.put(assetName, promptAttrName);
                                    siteMetadata.Prompt_Specific_Info__c = JSON.serialize(currentPromptSpecificInfoMap);
                                    updatepromptSiteMetaData.add(siteMetadata);
                                }
                            }
                        }
                       if(updatepromptSiteMetaData.size()>0){
                            update updatepromptSiteMetaData;
                        }
                        currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
                    } else if(currentPromptSiteMetadata.size()>0){
                        currentPromptSiteMetadata  =  Utils.newSiteMetadataRecords(prepopulateColumnName, Constants.P5_INVERTS_BUILD_AND_COUNTS, plantAssetId, rowGeneratorAttrName, currentPromptName, parentPlantAssetPromptDetail);
                        rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(parentSiteMetadataPrompt, plantAssetId);
                        Map<String,String> parentSiteMetadataRecord = new Map<String,String>();
    
                        Map<Id,String> ParentAssetNameToIdMap = new Map<Id,String>();
                        for(Site_Metadata__c ParentAssetNameToId : rowGeneratorPromptSiteMetadata){
                            ParentAssetNameToIdMap.put(string.valueof(ParentAssetNameToId.Id), 
                            string.valueOf(ParentAssetNameToId.Parent_Asset_Short_Name__c) + '\\' + string.valueOf(ParentAssetNameToId.Asset_Short_Name__c));
                        }
    
                        for(Site_Metadata__c parentSiteMetadata : rowGeneratorPromptSiteMetadata){
                            Map <String,String> parentPromptSpecificInfoMap =
                                (Map<String, String > ) System.JSON.deserialize(parentSiteMetadata.Prompt_Specific_Info__c, Map < String, String > .class);
                            parentSiteMetadataRecord.put(string.valueof(parentSiteMetadata.Id),parentPromptSpecificInfoMap.get(prepopulateColumnName));
                        }
                       
                        Map<Id,Integer> parentSiteMetadataIdToCount = new Map<Id,Integer>();
                        List<Site_Metadata__c> updatepromptSiteMetaData = new List<Site_Metadata__c>();
    
                        for (Site_Metadata__c siteMetadata: currentPromptSiteMetadata) {
                            if (!parentSiteMetadataIdToCount.containsKey(siteMetadata.Parent_Site_Metadata__c)) {
                                parentSiteMetadataIdToCount.put(siteMetadata.Parent_Site_Metadata__c, 0);
                            }
                            
                            Integer count = parentSiteMetadataIdToCount.get(siteMetadata.Parent_Site_Metadata__c);
                            Integer recordNameSequenceNo  = count + 1;
                            parentSiteMetadataIdToCount.put(siteMetadata.Parent_Site_Metadata__c, recordNameSequenceNo);
                            Map <String,String> currentPromptSpecificInfoMap =
                                (Map<String, String > ) System.JSON.deserialize(siteMetadata.Prompt_Specific_Info__c, Map < String, String > .class);
                            if (String.isBlank(currentPromptSpecificInfoMap.get(assetName))) {
    
                                if(parentSiteMetadataRecord.containsKey(currentPromptSpecificInfoMap.get(prepopulateColumnName))){
                                    String prepopulateColumnMapValue = currentPromptSpecificInfoMap.get(prepopulateColumnName);
                                    String promptAttrName = parentSiteMetadataRecord.get(prepopulateColumnMapValue) + ' - ' + 'Subarray ' + string.valueof(recordNameSequenceNo).leftPad(2, '0') + '';
                                    currentPromptSpecificInfoMap.put(assetName, promptAttrName);
                                    siteMetadata.Asset_Name__C = promptAttrName;
                                    siteMetadata.Prompt_Specific_Info__c = JSON.serialize(currentPromptSpecificInfoMap);
                                    siteMetadata.Asset_Short_Name__c = baseAssetShortName+string.valueof(recordNameSequenceNo).leftPad(2, '0');
                                    siteMetadata.Parent_Asset_Short_Name__c = parentAssetNameToIdMap.get(siteMetadata.Parent_Site_Metadata__c);
                                    updatepromptSiteMetaData.add(siteMetadata);
                                }
                            }
                        }
                        if(updatepromptSiteMetaData.size()>0){
                            update updatepromptSiteMetaData;
                        }
                    } 
                    currentPromptSiteMetadata.clear();
                    currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
                }
                
                Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                Utils.checkPreviousPlantAsset(plantAssetPromptDetail, previousPromptName);
                //Map<String,Object> dataTableInputString = Utils.getDatatableInputsMap(filteredCoreAttributes, promptSpecificAttributes, 
                    //currentPromptSiteMetadata, plantAssetPromptDetail, promptInfo);

                Map<String,Object> dataTableInputString = Utils.getDatatableInputsMapWithoutSiteMetadata(filteredCoreAttributes, promptSpecificAttributes, 
                    currentSitemetadataCount, plantAssetPromptDetail, promptInfo);
                if(!String.isBlank(csvData) && !String.isBlank(jsonInputParametersAndValues)){
                    dataTableInputString.put('csvData', csvData);
                }
                //This condition is to get the next prompt response either to navigate to Next or Finish.
                if(isBulkUploadCheck){
                    String nextPromptFinderResponse = Utils.nextPromptFinder(currentPromptName, plantAssetId);
                    dataTableInputString.put('nextPromptFinderResponse', nextPromptFinderResponse);
                }
                
                return JSON.serialize(dataTableInputString);
            }catch(Exception exceptionDetails){
                Database.rollback(sp);
                String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
                System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
                throw new AuraHandledException(errorMessage);
            } 
        }
        
        /*
            * On click of Save button, calls "saveSiteMetadataRecords" of the prompt Controller,
            a. Pass the modified site metadata records from  lwc  "assetBuilderCustomDatatable" , Plant Asset id, Prompt Information, isKeyToGenerateRows to the "saveSiteMetadataRecords" method of Utils Class.
            b. Any decrease in the prompt specific attribute in Parent prompt is tracked by a boolean variable "isKeyToGenerateRows".
            @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
            @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
            @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked  
        */
        @AuraEnabled
        public static Boolean saveSiteMetadataRecords(String plantAssetId, String siteMetadataRecordsToSave, Boolean isKeyToGenerateRows,
            Boolean attrValueChanged, Boolean finalBatchBoolean){
            try {
                if(!String.isBlank(siteMetadataRecordsToSave)){
                    Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
                    return Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
                }else{
                    return true;
                }
            } catch (Exception exceptionDetails) {
                String errorMessage = System.Label.AssetBuilderExceptionMessage;
                System.debug('Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
                throw new AuraHandledException(errorMessage);
            }
        }
        
        /*
         * On click of Next Button,
            a.  Saves the Current Site Metadata records, only if any changes occured in the prompt which is tracked by a boolean variable "attrValueChanged"
            b.  Based on the next available prompt attribute count, the nextPromptFinder method in the utils class navigates to the next prompt.
            
            @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
            @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
            @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked
            @param {Boolean} attrValueChanged - Any changes occured in the prompt which is tracked
         */
        @AuraEnabled
        public static String findNextPromptId(String plantAssetId, String siteMetadataRecordsToSave, Boolean isKeyToGenerateRows, 
            Boolean attrValueChanged, String additionalParamsForNext, Boolean finalBatchBoolean){           
            String nextPromptId;
            try{
                Boolean saveSiteMetadataOutput = true;
                Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
                Map<String,String> additionalParamsMap  = (Map<String,String>)JSON.deserialize(additionalParamsForNext, Map<String,String>.class); 
                if(!String.isBlank(siteMetadataRecordsToSave) && additionalParamsMap.get('isReadOnly') == 'false') { 
                    saveSiteMetadataOutput = Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
                }
                if(finalBatchBoolean){
                    if(saveSiteMetadataOutput){
                        nextPromptId = Utils.nextPromptFinder(currentPromptName, plantAssetId);
                    }
                    if(nextPromptId.length() <= 8 && additionalParamsMap.get('isReadOnly') == 'false'){
                        Utils.updateValidateOnPrevious(plantAssetId, currentPromptName);
                    }
                    Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                    return Utils.nextPromptFinderResponse(plantAssetId,PromptNavigationHelper.findPromptId(currentPromptName),nextPromptId,plantAssetPromptDetail.Id);
                }else{
                    return 'calling Next Batch';
                }
            }catch (Exception exceptionDetails) {
                String errorMessage = System.Label.AssetBuilderExceptionMessage;
                System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
                throw new AuraHandledException(errorMessage);
            }
            
        }
        
        /*
            * On click of Clear Button, calls "clearPromptInfo" of Prompt Controller 
                a.makes the attribute Info and Prompt specific info field into empty and again calls the getCustomDatatableCompInput method to generate the prompt
            @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
            @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
        */
        @AuraEnabled
        public static String  clearPromptInfo(String plantAssetId, String previousPromptName){
            String result = 'false';
            try{
                List<String> retainValuesForPromptAttr = new List<String>{prepopulateColumnName};
                List<String> retainValuesForCoreAttr = new List<String>();
                
                Boolean clearPromptInfoResult = Utils.clearPromptInfo(plantAssetId, currentPromptName, retainValuesForCoreAttr, retainValuesForPromptAttr);
                
                if(clearPromptInfoResult){
                    result = getCustomDatatableCompInput(plantAssetId, previousPromptName, true, '');
                } 

                return result;
            }catch(Exception exceptionDetails){
                String errorMessage = System.Label.AssetBuilderExceptionMessage;
                System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
                throw new AuraHandledException(errorMessage);
            } 
        }
    }