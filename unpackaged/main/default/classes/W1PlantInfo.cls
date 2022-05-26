public with sharing class W1PlantInfo {
    public Static String currentPromptName = Constants.W1_PLANT_INFO_PROMPT_WIND; 
    /*
        * If the plant Asset record's renewable_type__c includes "Wind", 
        * Query core attribute , prompt specific attribute an creates a plant asset prompt detail record and creates a site metadata record.
        @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
    */
    @AuraEnabled
    public static String getCustomDatatableCompInput(String plantAssetId, String previousPromptName, String jsonInputParametersAndValues){
        Savepoint sp;
        try {
            String csvData;
            Map<String,Object> customDatatableCompInputsMap = new Map<String,Object>();
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            
            Id basetAssetId = promptInfo.Base_Asset_Template__c;

            system.debug('----jsonInputParametersAndValues---'+jsonInputParametersAndValues);
            system.debug('----previousPromptName---'+previousPromptName);
            
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

            if(String.isBlank(basetAssetId)){
                throw new AuraHandledException(System.Label.W1BasedAssetTemplateIsNotLinked);
            }

            Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
            Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
            Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
            List<Core_Attribute__c> filteredCoreAttributes = Utils.queryCoreAttributes(basetAssetId, filteredAttributesId);
            List<Core_Attribute__c> coreAttributes = Utils.queryCoreAttributes(basetAssetId, allAttributesId);

            if(allAttributesId.size()<=0){
                throw new AuraHandledException(System.Label.W1AttributesNotConfiguredForProductServices);
            }
            List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);

            if(coreAttributes.isEmpty() && promptSpecificAttributes.isEmpty()){
                throw new AuraHandledException(System.Label.W1NoAttributesFound); 
            }

            // Query current prompt site metadata table rows -
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
            Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
            List<Site_Metadata__c> g1PromptSiteMetadata = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);

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

            if(currentPromptSiteMetadata.size()<=0){
                String dynamicQueryString = 'SELECT Id, PF_Service_Product__c';
                if(queryStringSet.size() > 0){
                    dynamicQueryString += ', '+ String.join((Iterable<String>)queryStringSet, ', ');
                }
                dynamicQueryString += ' '+ 'FROM Account_Plant__c WHERE Id =: plantAssetId';
                List<Account_Plant__c> plantAsset = new List<Account_Plant__c>(); 
                plantAsset.add(Database.query(dynamicQueryString));
                if(plantAsset.size()>0){
                    Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttributes);
                    Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
                    String plantAssetFieldEmptyValue = '';

                    for(Core_Attribute__c coreAttr : coreAttributes){
                        if(!String.isBlank(coreAttr.Plant_Asset_Field_Name__c)){
                            if(coreAttributeInfo.containsKey(coreAttr.Attribute_Master__r.Name)){
                                String plantAssetFieldValue = String.valueOf(plantAsset[0].get(coreAttr.Plant_Asset_Field_Name__c)); 
                                if(plantAssetFieldValue != null){
                                    coreAttributeInfo.put(coreAttr.Attribute_Master__r.Name,plantAssetFieldValue);
                                }else{
                                    coreAttributeInfo.put(coreAttr.Attribute_Master__r.Name,plantAssetFieldEmptyValue);
                                }
                            }
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
                            promptAttributeInfo.put(Constants.DRIVE_PLUS, drivePlus);
                        }  
                    } 

                    sp = Database.setSavepoint();                    

                    plantAssetPromptDetail = Utils.createPlantAssetPromptDetail(
                        plantAssetId, currentPromptName, previousPromptName, ''
                    );
                    insert plantAssetPromptDetail;

                    Site_Metadata__c siteMetadata = Utils.createSiteMetaData(
                        plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                        plantAssetPromptDetail.Id, JSON.serialize(coreAttributeInfo), g1PromptSiteMetadata[0].Id, basetAssetId, promptInfo.Id, ''
                    );
                    //sitemetadata insert in Util method
                    List<Site_Metadata__c> siteMetadataLst = new List<Site_Metadata__c>();
                    siteMetadataLst.add(siteMetadata);
                    Utils.insertSitemetadata(siteMetadataLst);

                    currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
                }else{
                    throw new AuraHandledException(System.Label.PlantRecordNotFound);
                }
            }

            plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
            Utils.checkPreviousPlantAsset(plantAssetPromptDetail, previousPromptName);
            Map<String,Object> dataTableInputString = Utils.getDatatableInputsMap(filteredCoreAttributes, promptSpecificAttributes, 
                currentPromptSiteMetadata, plantAssetPromptDetail, promptInfo);
            if(!String.isBlank(csvData) && !String.isBlank(jsonInputParametersAndValues)){
                dataTableInputString.put('csvData', csvData);
            }
            return JSON.serialize(dataTableInputString);
        }catch(Exception exceptionDetail){
            Database.rollback(sp);
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetail.getMessage();
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }

    /*
     * On click of Save button,
        a. Pass the modified site metadata records from  lwc  "assetBuilderCustomDatatable" , Plant Asset id, Prompt Information, isKeyToGenerateRows to the "saveSiteMetadataRecords" method of Utils Class
        @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
        @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked 
    */
	
    @AuraEnabled
    public static Boolean saveSiteMetadataRecords(String siteMetadataRecordsToSave, String plantAssetId, Boolean isKeyToGenerateRows,
        Boolean attrValueChanged, Boolean finalBatchBoolean){
        try{
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            return Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
        }catch(Exception exceptionDetail){
            String errorMessage =  System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetail.getMessage();
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }

    /*
     * On click of Next Button,
        a.Saves the Current Site Metadata records, only if any changes occured in the prompt which is tracked by a boolean variable	"attrValueChanged"
        b. Navigates to the appropriate next prompt.

    @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
    @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
    @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked
    @param {Boolean} attrValueChanged - Any changes occured in the prompt which is tracked 
    */
	
    @AuraEnabled
    public static String findNextPromptId(String plantAssetId, String siteMetadataRecordsToSave, Boolean isKeyToGenerateRows, 
        Boolean attrValueChanged, String additionalParamsForNext, Boolean finalBatchBoolean){        
        try{
            String nextPromptId;
            Boolean saveSiteMetadataOutput = true ;
            Map<String,String> responseMap = new Map<String,String>();
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            Map<String,String> additionalParamsMap  = (Map<String,String>)JSON.deserialize(additionalParamsForNext, Map<String,String>.class);
            if(!String.isBlank(siteMetadataRecordsToSave) && additionalParamsMap.get('isReadOnly') == 'false'){
                saveSiteMetadataOutput = Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
            }
            if(finalBatchBoolean){
                if(saveSiteMetadataOutput){
                    nextPromptId = PromptNavigationHelper.findPromptId(Constants.W2_STRING_BUILD_INFO);
                }
                if(nextPromptId.length()<=8 && additionalParamsMap.get('isReadOnly') == 'false'){
                    Utils.updateValidateOnPrevious(plantAssetId, currentPromptName);
                }
                Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                return Utils.nextPromptFinderResponse(plantAssetId, PromptNavigationHelper.findPromptId(currentPromptName), nextPromptId, plantAssetPromptDetail.Id);
            }else{
                return 'calling Next Batch';
            }
        }catch(Exception exceptionDetail){
            String errorMessage =  System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetail.getMessage();
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
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
    public static String clearPromptInfo(String plantAssetId, String previousPromptName){
        String result = 'false';
        try{
            List<String> retainValuesForPromptAttr = new List<String>{Constants.PLANT_NAME, Constants.PF_PLANT_ID, Constants.DRIVE_PLUS,  Constants.DESCRIPTION_CUSTOMER_NAME};
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
        }catch(Exception exceptionDetail){
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetail.getMessage();
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
}