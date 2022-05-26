/*
Author : 
Date : 
Description : 
            - Controller of P1 Plant Info Prompt - Solar which helps to query to Plant Asset, 
            Core Attributes and Save the Attribute Info in Site Metadata object.
            - Attrbiute Info and Prompt Specific Info are stored in JSON Format

*/

public with sharing class P1PlantInfoPromptSolar {
    //Prompt Name
    public static String currentPromptName = Constants.P1_PLANT_INFO_PROMPT_SOLAR; 
    /*
     * Query Site Metadata record for current prompt name and Plant Asset Id , and check if any record exists,
	if No,
		a. Create a record in Plant Asset Prompt Detail Object  for the current  Prompt 
		b.Create  SIte Metadata record for current Prompt based on the row generation attribute count from the parent site metadata records
		c. Query Site Metadata record of current prompt and return to lwc "assetBuilderCustomDatatable" for prompt table creation through the current prompt lwc component

	if yes,
		a. New Site Metadata records are  newly created for the current prompt.
		b. Query the Plant Asset Prompt Detail  of current prompt and compares the "Previous_Plant_Asset_Prompt__c" field  with the previous prompt name,
			if not matched,
					Previous_Plant_Asset_Prompt__c field is updated with previous prompt name.
		c. Query Site Metadata record of current prompt and return to lwc "assetBuilderCustomDatatable" for prompt table creation through the current prompt lwc component

    @param {String} plantAssetId - Holds the PlantAssetId which is passed from the previous prompt, for which the Site metadata record created.
    @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation
     */
    @AuraEnabled
    public static String getCustomDatatableCompInput(String plantAssetId, String previousPromptName, String jsonInputParametersAndValues){
        Savepoint sp = Database.setSavepoint();
        try {
            Map<String,Object> customDatatableCompInputsMap = new Map<String,Object>();
            Id basetAssetId;
            String csvData;
            List<Core_Attribute__c> filteredCoreAttributes = new List<Core_Attribute__c>();
            List<Core_Attribute__c> coreAttributes = new List<Core_Attribute__c>();
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName,plantAssetId);

            List<Site_Metadata__c> g1PromptSiteMetadata = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);

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

            if(promptInfo.Base_Asset_Template__c != NULL){        
                basetAssetId = promptInfo.Base_Asset_Template__c;
                Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
                Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
                Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
                filteredCoreAttributes = Utils.queryCoreAttributes(basetAssetId, filteredAttributesId);
                coreAttributes = Utils.queryCoreAttributes(basetAssetId, allAttributesId);
            }
            List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
            
            Set<String> queryStringSet = new Set<String>() ;
            if(coreAttributes.size()>0){
                for(Core_Attribute__c coreAttribute : coreAttributes){
                    if(!String.isBlank(coreAttribute.Plant_Asset_Field_Name__c)){
                        queryStringSet.add(coreAttribute.Plant_Asset_Field_Name__c);
                    }
                }
            }
            
            if(promptSpecificAttributes.size()>0){
                for(Core_Attribute__c promptSpecificAttribute : promptSpecificAttributes){
                    if(!String.isBlank(promptSpecificAttribute.Plant_Asset_Field_Name__c)){
                        queryStringSet.add(promptSpecificAttribute.Plant_Asset_Field_Name__c);
                    }
                }
            }
 
            String bifacialModules = 'false';

            if(g1PromptSiteMetadata.size() > 0){
                Map<String, String> promptSpecificInfoMap = 
                            (Map<String, String>) System.JSON.deserialize(g1PromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class); 
                if(promptSpecificInfoMap.containsKey(Constants.BIFACIAL_MODULES)){
                    bifacialModules = promptSpecificInfoMap.get(Constants.BIFACIAL_MODULES);
                }
            }

            if(currentPromptSiteMetadata.size()<=0){
                String dynamicQueryString;
                if(queryStringSet.size() > 0){
                    if(queryStringSet.contains('PF_Service_Product__c')){
                        dynamicQueryString = 'SELECT Id ';
                    }else{
                        dynamicQueryString = 'SELECT Id, PF_Service_Product__c';
                    }
                    dynamicQueryString += ', '+ String.join((Iterable<String>)queryStringSet, ', ');
                }

                dynamicQueryString += ' '+ 'FROM Account_Plant__c WHERE Id =: plantAssetId';
               
                List<Account_Plant__c> plantAsset = new List<Account_Plant__c>();
                plantAsset.add(Database.query(dynamicQueryString));
                if(plantAsset.size()>0){
                    Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName,previousPromptName,'');
                    insert plantAssetPromptCreateInstance;

                    Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttributes);
                    Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
                    String plantAssetFieldEmptyValue = '';
                    
                    for(Core_Attribute__c coreAttr : coreAttributes){
                        if(!String.isBlank(coreAttr.Plant_Asset_Field_Name__c)){
                            if(coreAttributeInfo.containsKey(coreAttr.Attribute_Master__r.Name)){
                                String plantAssetFieldValue = String.valueOf(plantAsset[0].get(coreAttr.Plant_Asset_Field_Name__c)); 
                                if(plantAssetFieldValue != null){
                                    if(coreAttr.Attribute_Master__r.Data_Type__c == 'Date'){
                                        Datetime dT = (Datetime) plantAsset[0].get(coreAttr.Plant_Asset_Field_Name__c);
                                        Date dateVal = dT.dateGmt();
                                        plantAssetFieldValue = String.valueOf(dateVal);
                                    }
                                    coreAttributeInfo.put(coreAttr.Attribute_Master__r.Name,plantAssetFieldValue);
                                }else{
                                    coreAttributeInfo.put(coreAttr.Attribute_Master__r.Name,plantAssetFieldEmptyValue);
                                }
                            }
                        }else if(coreAttr.Attribute_Master__r.Name == Constants.BIFACIAL_ARRAY){
                            coreAttributeInfo.put(coreAttr.Attribute_Master__r.Name, bifacialModules);
                        }
                    }

                    for(Core_Attribute__c promptSpecificAttr : promptSpecificAttributes){
                        if(!String.isBlank(promptSpecificAttr.Plant_Asset_Field_Name__c)){
                            if(promptAttributeInfo.containsKey(promptSpecificAttr.Attribute_Master__r.Name)){
                                String plantAssetFieldValue = String.valueOf(plantAsset[0].get(promptSpecificAttr.Plant_Asset_Field_Name__c)); 
                                if(plantAssetFieldValue != null){
                                    promptAttributeInfo.put(promptSpecificAttr.Attribute_Master__r.Name,plantAssetFieldValue);
                                }else{
                                    promptAttributeInfo.put(promptSpecificAttr.Attribute_Master__r.Name,plantAssetFieldEmptyValue);
                                }
                            }
                        }
                    }

                    String drivePlus = Utils.drivePlusCategoryFinder(plantAsset[0].PF_Service_Product__c);
                    
                    for(String promptAttrName : promptAttributeInfo.keySet()){
                        if(promptAttrName == Constants.DRIVE_PLUS){
                            promptAttributeInfo.put(Constants.DRIVE_PLUS,drivePlus);
                        }  
                    }

                    Site_Metadata__c siteMetadata = 
                        Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                            plantAssetPromptCreateInstance.Id, JSON.serialize(coreAttributeInfo), g1PromptSiteMetadata[0].Id, basetAssetId, promptInfo.Id,'');
                    //sitemetadata insert in Util method
                    List<Site_Metadata__c> siteMetadataLst = new List<Site_Metadata__c>();
                    siteMetadataLst.add(siteMetadata);
                    Utils.insertSitemetadata(siteMetadataLst);
                    
                    currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, Id.valueOf(plantAssetId));
                }
            }else{
                Map<String, String> attrInfoMap = (Map<String, String>)System.JSON.deserialize(currentPromptSiteMetadata[0].Attribute_Info__c, Map<String, String>.class); 
                String bifacialModulesOld = '';
                if(attrInfoMap.containsKey(Constants.BIFACIAL_ARRAY)){
                    bifacialModulesOld = attrInfoMap.get(Constants.BIFACIAL_ARRAY);

                    if(bifacialModulesOld != bifacialModules){
                        attrInfoMap.put(Constants.BIFACIAL_ARRAY, bifacialModules);
                        currentPromptSiteMetadata[0].Attribute_Info__c = JSON.serialize(attrInfoMap);
                        Update currentPromptSiteMetadata[0];
                    }
                }
            }

            Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
            Utils.checkPreviousPlantAsset(plantAssetPromptDetail, previousPromptName);
            Map<String,Object> dataTableInputString = Utils.getDatatableInputsMap(filteredCoreAttributes, promptSpecificAttributes, 
                currentPromptSiteMetadata, plantAssetPromptDetail, promptInfo);
            if(!String.isBlank(csvData) && !String.isBlank(jsonInputParametersAndValues)){
                dataTableInputString.put('csvData', csvData);
            }

            return JSON.serialize(dataTableInputString);
        }catch(Exception exceptionDetail){
            Database.rollback(sp);
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }

    /*
     *  On click of Save button, calls "saveSiteMetadataRecords" of the prompt Controller,
	a. Pass the modified site metadata records from  lwc  "assetBuilderCustomDatatable" , Plant Asset id, Prompt Information, isKeyToGenerateRows to the "saveSiteMetadataRecords" method of Utils Class
    b. Any decrease in the prompt specific attribute in Parent prompt is tracked by a boolean variable "isKeyToGenerateRows".
    @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
    @param {String} plantAssetId - Holds the PlantAssetId which is passed from the previous prompt, for which the Site metadata record created.
    @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked 
    */
    @AuraEnabled
    public static Boolean saveSiteMetadataRecords(String siteMetadataRecordsToSave, String plantAssetId, Boolean isKeyToGenerateRows, 
        Boolean attrValueChanged, Boolean finalBatchBoolean){
        try{ 
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName,plantAssetId);
            return Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
        }catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }

    /*
     * On click of Next Button, calls "findNextPromptId" of the Prompt Controller
	a.Saves the Current Site Metadata records, only if any changes occured in the prompt which is tracked by a boolean variable "attrValueChanged"
	b. Navigates to the appropriate next prompt .
    
    @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
    @param {String} plantAssetId - Holds the PlantAssetId which is passed from the previous prompt, for which the Site metadata record created.
    @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked
    @param {Boolean} attrValueChanged - Any changes occured in the prompt which is tracked 
    */
    
    @AuraEnabled
    public static String findNextPromptId(String siteMetadataRecordsToSave, String plantAssetId, Boolean isKeyToGenerateRows, 
        Boolean attrValueChanged,  String additionalParamsForNext, Boolean finalBatchBoolean){
        try{
            String nextPromptId;
            Boolean saveSiteMetadataOutput = true ;
            Map<String,String> responseMap = new Map<String,String>();
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName,plantAssetId);
            Map<String,String> additionalParamsMap  = (Map<String,String>)JSON.deserialize(additionalParamsForNext, Map<String,String>.class); 
            if(!String.isBlank(siteMetadataRecordsToSave) && additionalParamsMap.get('isReadOnly') == 'false'){
                saveSiteMetadataOutput = Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
            }    

            if(finalBatchBoolean){
                if(saveSiteMetadataOutput){
                    List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
                    if(currentPromptSiteMetadata.size()>0){
                        Map<String,String> promptInfoMap = Utils.deserializeAttribute(currentPromptSiteMetadata[0].Prompt_Specific_Info__c);
                        if(promptInfoMap.containsKey(Constants.FLAT_HIERARCHY)){
                            if(promptInfoMap.get(Constants.FLAT_HIERARCHY) == Constants.YES){
                                nextPromptId = PromptNavigationHelper.findPromptId(Constants.P3_PAD_BUILDS_AND_COUNTS);
                            }else{
                                nextPromptId = PromptNavigationHelper.findPromptId(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS);
                            }
                        }
                        if(nextPromptId.length()<=8 && additionalParamsMap.get('isReadOnly') == 'false'){
                            Utils.updateValidateOnPrevious(plantAssetId,currentPromptName);
                        }
                    }
                }
                Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                return Utils.nextPromptFinderResponse(plantAssetId, PromptNavigationHelper.findPromptId(currentPromptName), nextPromptId, plantAssetPromptDetail.Id);
            }else{
                return 'calling Next Batch';
            }
        }catch(Exception exceptionDetail){
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    } 

    /*
     *  on click of Clear Button, calls "clearPromptInfo" of Prompt Controller 
		a.makes the attribute Info and Prompt specific info field into empty and again calls the getCustomDatatableCompInput method of  Prompt Controller to generate the prompt
        @param {plantAssetId} - Holds the Plant Asset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
        */
    @AuraEnabled
    public static String clearPromptInfo(String plantAssetId, String previousPromptName){
        String result = 'false' ;
        try{
            List<String> retainValuesForPromptAttr = new List<String>{Constants.PLANT_NAME, Constants.PF_PLANT_ID,
                Constants.DRIVE_PLUS,Constants.DESCRIPTION_CUSTOMER_NAME};
            List<String> retainValuesForCoreAttr = new List<String>();
            
            Boolean clearPromptInfoResult = Utils.clearPromptInfo(plantAssetId, currentPromptName, retainValuesForCoreAttr, retainValuesForPromptAttr);
            
            if(clearPromptInfoResult){
                List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
                Boolean IsUpdateCheck = Utils.plantAssetPromptDetailIsDeleteUpdate(
                                            currentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__r.Id,
                                            currentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__r.Prompt_Information__r.Type__c);
                result = getCustomDatatableCompInput(plantAssetId, previousPromptName, '');
            } 
            return result;
        }catch(Exception exceptionDetails){
            String errorMessage = 'Please Contact Administrator'+ exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
}