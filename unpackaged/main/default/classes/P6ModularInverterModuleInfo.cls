public with sharing class P6ModularInverterModuleInfo {
    public static String currentPromptName = Constants.P6_MODULAR_INVERTER_MODULE_INFO;
    public static String prepopulateColumnName = Constants.INVERTER_NAME;
    public static String parentSiteMetadataPrompt = Constants.P5_INVERTS_BUILD_AND_COUNTS;

    /*
    * Query Site Metadata record for current prompt name and Plant Asset Id , and check if any record exists,
        if No,
            a. Create a record in Plant Asset Prompt Detail Object  for the current  Prompt 
            b.Create  SIte Metadata record for Current Prompt,based on the count of row generate atttribute name		
            c. Query Site Metadata record of current prompt and return to lwc "assetBuilderCustomDatatable" for prompt table creation through
                the current prompt  lwc component

        if yes,
            a. New Site Metadata records are  newly created for the current prompt
            b. Query the Plant Asset Prompt Detail  of current prompt and compares the "Previous_Plant_Asset_Prompt__c" field  with the 
                previous prompt name ,
                if not matched,
                        Previous_Plant_Asset_Prompt__c field is updated with previous prompt name.
            c. Query Site Metadata record of current prompt and return to lwc  "assetBuilderCustomDatatable" for prompt table creation through the  current prompt component
        @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
    */
    @AuraEnabled
    public static string getCustomDatatableCompInput(String plantAssetId, String previousPromptName, String jsonInputParametersAndValues){      
        String rowGeneratorAttrName = Constants.MODULAR_INVERTER;
        Savepoint sp = Database.setSavepoint();
        try {
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
                }            }

            if(promptInfo.Base_Asset_Template__c != NULL){
                basetAssetId = promptInfo.Base_Asset_Template__c;
                baseAssetShortName = promptInfo.Base_Asset_Template__r.Asset_Short_Name__c;
                Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
                Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
                Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
                filteredCoreAttributes = Utils.queryCoreAttributes(basetAssetId, filteredAttributesId);
                coreAttributes = Utils.queryCoreAttributes(basetAssetId, allAttributesId);
            }
            
            List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);
            String coreAttributeInfoJSON = Utils.serializeAttribute(coreAttributes);             
            Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
            
            // Query current prompt site metadata table rows
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName,plantAssetId);
            Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = new Plant_Asset_Prompt_Detail__c();
            // Query previous prompt site metadata to populate table rows 
            List<Site_Metadata__c> rowGeneratorPromptSiteMetadata = new List<Site_Metadata__c>();
            String parentPlantAssetPromptDetail;

            rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(parentSiteMetadataPrompt,plantAssetId);
            
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
                    plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                    insert plantAssetPromptCreateInstance; 
                }
            }

            if(currentSitemetadataCount < Constants.RECORD_COUNT_FOR_EACH_PROMPT){
                if(currentPromptSiteMetadata.size()<=0 ){
                
                    if(rowGeneratorPromptSiteMetadata.size()>0){
                        parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
                    }
                    plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                    insert plantAssetPromptCreateInstance;
    
                    String coreAttributeInfo = Utils.serializeAttribute(coreAttributes);
                    if(rowGeneratorPromptSiteMetadata.size() > 0){
                        for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                            Map<String, String> promptSpecificInfoMap = 
                                (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                        }
                    }  
                }
                
                List<Site_Metadata__c> parentAssets = new List<Site_Metadata__c>(); 
                Integer rowCount = 0;
                
                if(!String.isBlank(rowGeneratorAttrName)){
                    for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                        Map<String, String> promptSpecificInfoMap = 
                            (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                        if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){
                            if(!String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                                for(Integer count = 0; count < Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName)); count++){
                                    parentAssets.add(rowGenMetadata);
                                }
                                rowCount += Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName));
                            }
                        }
                    }
                } 
                
                if(rowCount>0){
                    List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                    if(currentPromptSiteMetadata.size()<=0){
                        for(integer i = 0; i < rowCount; i++){
                            Map<String,String> rowGenPromptSpecificInfoMap = 
                                (Map<String, String>) System.JSON.deserialize(parentAssets[i].Prompt_Specific_Info__c,Map<String, String>.class);
                            String prePopulatecolumnValue = rowGenPromptSpecificInfoMap.containsKey(prepopulateColumnName)?rowGenPromptSpecificInfoMap.get(prepopulateColumnName):'';
                            promptAttributeInfo.put(prepopulateColumnName,parentAssets[i].Id);
                            Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                plantAssetPromptCreateInstance.Id, coreAttributeInfoJSON, parentAssets[i].Id, basetAssetId, promptInfo.Id, '');
                            siteMetadataCreation.add(siteMetadata);
                        }
                        if(siteMetadataCreation.size()>0){
                            //sitemetadata insert in Util method
                            Utils.insertSitemetadata(siteMetadataCreation);
                        }
                        currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName,plantAssetId);
                    } else if(currentPromptSiteMetadata.size() > 0){
                        currentPromptSiteMetadata  =  Utils.newSiteMetadataRecords(prepopulateColumnName, Constants.P5_INVERTS_BUILD_AND_COUNTS, plantAssetId, rowGeneratorAttrName, currentPromptName, parentPlantAssetPromptDetail);
                    }
                } else{
                    String errorMessage = System.Label.P6BValidationErrorMsgForModularInverterCheck;
                    throw new AuraHandledException(errorMessage); 
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

            return JSON.serialize(dataTableInputString);
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
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
    public static Boolean saveSiteMetadataRecords(String siteMetadataRecordsToSave, String plantAssetId, Boolean isKeyToGenerateRows,
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
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }

    @AuraEnabled
    /*
    On click of Next Button,
	a.Saves the Current Site Metadata records, only if any changes occured in the prompt which is tracked by a boolean variable	"attrValueChanged"
    b. Navigates to the appropriate next prompt.
    
    @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
    @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
    @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked
    @param {Boolean} attrValueChanged - Any changes occured in the prompt which is tracked 
    */
    public static String findNextPromptId(String siteMetadataRecordsToSave, String plantAssetId, Boolean isKeyToGenerateRows, 
        Boolean attrValueChanged, String additionalParamsForNext, Boolean finalBatchBoolean){
        try{
            String nextPromptId;
            Boolean saveSiteMetadataOutput = true;
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            Map<String,String> additionalParamsMap  = (Map<String,String>)JSON.deserialize(additionalParamsForNext, Map<String,String>.class); 
            if(!String.isBlank(siteMetadataRecordsToSave) && additionalParamsMap.get('isReadOnly') == 'false'){
                saveSiteMetadataOutput = Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
            }
            if(finalBatchBoolean){
                if(saveSiteMetadataOutput){
                    nextPromptId = PromptNavigationHelper.findPromptId(Constants.P7_INVERTER_SUBARRAY_INFO);
                }
                if(nextPromptId.length() <= 8 && additionalParamsMap.get('isReadOnly') == 'false'){
                    Utils.updateValidateOnPrevious(plantAssetId, currentPromptName);
                }
                Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                return Utils.nextPromptFinderResponse(plantAssetId,PromptNavigationHelper.findPromptId(currentPromptName),nextPromptId,plantAssetPromptDetail.Id);
            }else{
                return 'calling Next Batch';
            }
        }catch(Exception exceptionDetail){
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }  
    } 

    @AuraEnabled
    /*
    * On click of Clear Button, calls "clearPromptInfo" of Prompt Controller 
        a.makes the attribute Info and Prompt specific info field into empty and again calls the getCustomDatatableCompInput method to generate the prompt
    @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
    @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
    */
    public static String  clearPromptInfo(String plantAssetId, String previousPromptName){
        String result = 'false';
        try{
            List<String> retainValuesForPromptAttr = new List<String>{prepopulateColumnName};
            List<String> retainValuesForCoreAttr = new List<String>();
            
            Boolean clearPromptInfoResult = Utils.clearPromptInfo(plantAssetId, currentPromptName, retainValuesForCoreAttr, retainValuesForPromptAttr);
            
            if(clearPromptInfoResult){
                result = getCustomDatatableCompInput(plantAssetId, previousPromptName, '');
            } 

            return result;
        }catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    } 
}