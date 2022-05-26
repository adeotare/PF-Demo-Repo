public with sharing class P3PadBuildAndCounts {
    public static String currentPromptName = Constants.P3_PAD_BUILDS_AND_COUNTS;
    public static String prepopulateColumnName = Constants.BLOCK_NAME;// Populate the attribute in each sitemetadata of current prompt

    /*Query Site Metadata record for current prompt name and Plant Asset Id , and check if any record exists,
	if No,
		a. Create a record in Plant Asset Prompt Detail Object  for the current  Prompt 
		b.Create  SIte Metadata record for current Prompt.
		c. Query Site Metadata record of current prompt and return to lwc "assetBuilderCustomDatatable"  for prompt table creation through the current prompt  lwc component

	if yes,
		a. New Site Metadata records are  newly created for the current prompt
		b. Query the Plant Asset Prompt Detail  of current prompt and compares the "Previous_Plant_Asset_Prompt__c" field  with the previous prompt name ,
			if not matched,
					Previous_Plant_Asset_Prompt__c field is updated with previous prompt name.
		c. Query Site Metadata record of current prompt and return to lwc  "assetBuilderCustomDatatable"  for prompt table creation through the current prompt  lwc component
    @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
    @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
        */
    @AuraEnabled
    public static string getCustomDatatableCompInput(String plantAssetId, String previousPromptName, String jsonInputParametersAndValues){      
        String rowGeneratorAttrName = Constants.PAD_COUNT;
        String flatHierarchy;
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
            List<Core_Attribute__c> promptSpecificAttributesList = new List<Core_Attribute__c>();
            
            String coreAttributeInfoJSON = Utils.serializeAttribute(coreAttributes);             
            Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
            
            // Query current prompt site metadata table rows
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName,plantAssetId);
            
            // Query previous prompt site metadata to populate table rows 
            List<Site_Metadata__c> rowGeneratorPromptSiteMetadata = new List<Site_Metadata__c>();
            rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(Constants.P1_PLANT_INFO_PROMPT_SOLAR,plantAssetId);
            
            String parentPlantAssetPromptDetail;
            if(rowGeneratorPromptSiteMetadata.size()>0){
                parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
            }

            /*query the P.1 site metadata and its prompt specific attribute-flat hierarchy,
                if flat hierarchy is yes, 
                    a.query the current prompt specific attribute (BLOCK_NAME) and assign the field ,'Is_Parent_Asset__c' to false, to disable the parent for the current prompt
                if flat hierarchy is No,
                    a. query the P.2 site metadata, and assign its prompt specific attribute's (BLOCK_NAME) field 'Is_Read_Only__c'  to true, to make it read only and the value of BLOCK NAME will be populated from p2 prompt.
            */
            if(rowGeneratorPromptSiteMetadata.size() > 0){
                for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                    Map<String, String> promptSpecificInfoMap = 
                        (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                    flatHierarchy = promptSpecificInfoMap.get(Constants.FLAT_HIERARCHY);
                    if(flatHierarchy == Constants.YES){
                
                        for(Core_Attribute__c promptSpecificAttribute : promptSpecificAttributes){
                            if(promptSpecificAttribute.Attribute_Master__r.Name == Constants.BLOCK_NAME){
                                promptSpecificAttribute.Is_Parent_Asset__c = false;
                            }
                            promptSpecificAttributesList.add(promptSpecificAttribute);
                        }
                    }
                    if(flatHierarchy == Constants.NO){
                        rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS,plantAssetId); 
                        for(Core_Attribute__c promptSpecificAttribute : promptSpecificAttributes){
                            if(promptSpecificAttribute.Attribute_Master__r.Name == Constants.BLOCK_NAME){
                                promptSpecificAttribute.Is_Read_Only__c = true;
                             } 
                            promptSpecificAttributesList.add(promptSpecificAttribute);
                        }
                    }
                    promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributesList);
                } 
            }

            // This currentSitemetadataCount is get the count of current sitemetadata records
            if(!String.isBlank(rowGeneratorAttrName) && flatHierarchy== Constants.NO){
                for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                    Map<String, String> promptSpecificInfoMap = 
                        (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                    if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){
                        if(!String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                            currentSitemetadataCount += Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName));
                        }
                    }
                }
            } else {
                if(rowGeneratorPromptSiteMetadata.size()==1){
                    currentSitemetadataCount = rowGeneratorPromptSiteMetadata.size();
                }
            }

            if(currentSitemetadataCount >= Constants.RECORD_COUNT_FOR_EACH_PROMPT && currentPromptSiteMetadata.size()<=0){
                list<Plant_Asset_Prompt_Detail__c> plantAssetPromptDetailLst = [SELECT Id,Name FROM Plant_Asset_Prompt_Detail__c WHERE 
                Account_Plant__c =: plantAssetId AND Is_Deleted__c = false AND
                    Prompt_Information__r.Name =: currentPromptName];
                if(plantAssetPromptDetailLst.size()<=0){
                    Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                    insert plantAssetPromptCreateInstance; 
                }
            }

            if(currentSitemetadataCount < Constants.RECORD_COUNT_FOR_EACH_PROMPT){
                if(currentPromptSiteMetadata.size() <= 0){
                    Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                    insert plantAssetPromptCreateInstance;
    
                    String coreAttributeInfo = Utils.serializeAttribute(coreAttributes);
                    List<Site_Metadata__c> parentAssets = new List<Site_Metadata__c>(); 
                    Integer rowCount = 0;
                    
                    if(!String.isBlank(rowGeneratorAttrName) && flatHierarchy== Constants.NO){
                        for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                            Map<String, String> promptSpecificInfoMap = 
                                (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                            if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){
                                for(Integer count = 0; count < Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName)); count++){
                                    parentAssets.add(rowGenMetadata);
                                }
                                rowCount += Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName));
                            }
                        }
                    } else {
                        if(rowGeneratorPromptSiteMetadata.size()==1){
                            parentAssets.add(rowGeneratorPromptSiteMetadata[0]);
                            rowCount = rowGeneratorPromptSiteMetadata.size();
                        }
                    }
                    
                    if(rowCount>0){
                        List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                        if(currentPromptSiteMetadata.size()<=0){
                            for(integer i = 0; i < rowCount; i++){
                                Map<String,String> rowGenPromptSpecificInfoMap = 
                                    (Map<String, String>) System.JSON.deserialize(parentAssets[i].Prompt_Specific_Info__c,Map<String, String>.class);
                                String prePopulatecolumnValue = rowGenPromptSpecificInfoMap.containsKey(prepopulateColumnName)?rowGenPromptSpecificInfoMap.get(prepopulateColumnName):'';
                                if(flatHierarchy == Constants.NO){
                                    promptAttributeInfo.put(prepopulateColumnName,parentAssets[i].Id);
                                }
                                Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                                                String.valueOf(plantAssetPromptCreateInstance.Id), coreAttributeInfoJSON,
                                                                                String.valueOf(parentAssets[i].Id), basetAssetId, promptInfo.Id, '');
                       
                                siteMetadataCreation.add(siteMetadata);
                            }
                            if(siteMetadataCreation.size()>0){
                                //sitemetadata insert in Util method
                                Utils.insertSitemetadata(siteMetadataCreation);
                            }
                            currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName,plantAssetId);
                        } else{
                            throw new AuraHandledException('There is no Block Count in P1 Plant Info Prompt - Solar');   
                        }
                    } 
                }else if(currentPromptSiteMetadata.size()>0){
                    currentPromptSiteMetadata  =  Utils.newSiteMetadataRecords(prepopulateColumnName, Constants.P2_BLOCK_INFO_AND_PAD_COUNTS, plantAssetId, rowGeneratorAttrName, currentPromptName, parentPlantAssetPromptDetail);
                }
                currentPromptSiteMetadata.clear();
                currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
            }
            
            Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
            Utils.checkPreviousPlantAsset(plantAssetPromptDetail, previousPromptName);
            //Map<String,Object> customDatatableCompInputsMap = Utils.getDatatableInputsMap(filteredCoreAttributes, promptSpecificAttributes, 
            //    currentPromptSiteMetadata, plantAssetPromptDetail, promptInfo);

            Map<String,Object> customDatatableCompInputsMap = Utils.getDatatableInputsMapWithoutSiteMetadata(filteredCoreAttributes, promptSpecificAttributes, 
                currentSitemetadataCount, plantAssetPromptDetail, promptInfo);

            if(!String.isBlank(csvData) && !String.isBlank(jsonInputParametersAndValues)){
                customDatatableCompInputsMap.put('csvData', csvData);
            }
            customDatatableCompInputsMap.put('p1PromptName', Constants.P1_PLANT_INFO_PROMPT_SOLAR);
            
            String customDatatableCompInputsString = JSON.serialize(customDatatableCompInputsMap);
            return customDatatableCompInputsString;
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
    
   /* On click of Save button,
	a. Pass the modified site metadata records from  lwc  "assetBuilderCustomDatatable" , Plant Asset id, Prompt Information, isKeyToGenerateRows to the "saveSiteMetadataRecords" method of Utils Class
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
            System.debug('Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /*
     * On click of Next Button,
        a.Saves the Current Site Metadata records, only if any changes occured in the prompt which is tracked by a boolean variable "attrValueChanged"
        b. Navigates to the appropriate next prompt.
        @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
        @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked
        @param {Boolean} attrValueChanged - Any changes occured in the prompt which is tracked 
     */
    @AuraEnabled
    public static String findNextPromptId(String plantAssetId, String siteMetadataRecordsToSave, String meterCount, Boolean isKeyToGenerateRows, 
        Boolean attrValueChanged, String additionalParamsForNext, Boolean finalBatchBoolean){
        String nextPromptId;
        try{ 
            Boolean  saveSiteMetadataOutput = true;
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            Map<String,String> additionalParamsMap  = (Map<String,String>)JSON.deserialize(additionalParamsForNext, Map<String,String>.class);
            if(!String.isBlank(siteMetadataRecordsToSave) && additionalParamsMap.get('isReadOnly') == 'false'){ 
                saveSiteMetadataOutput = Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
            }
                
            if(finalBatchBoolean){
                if(saveSiteMetadataOutput){
                    if(Integer.valueOf(meterCount) > 0){  
                        nextPromptId = PromptNavigationHelper.findPromptId(Constants.P4_EQUIPMENT_PAD_METERS_INFO);
                    } else{
                        nextPromptId = PromptNavigationHelper.findPromptId(Constants.P5_INVERTS_BUILD_AND_COUNTS);
                    }
                }
                if(nextPromptId.length()<=8 && additionalParamsMap.get('isReadOnly') == 'false'){
                    Utils.updateValidateOnPrevious(plantAssetId,currentPromptName);
                }
                Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
    
                return Utils.nextPromptFinderResponse(plantAssetId,PromptNavigationHelper.findPromptId(currentPromptName),nextPromptId,plantAssetPromptDetail.Id);        
            }else{
                return 'calling Next Batch';
            }
        } catch (Exception exceptionDetails) {
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
        
    }
    
    /*
     * on click of Clear Button, calls "clearPromptInfo" of Prompt Controller 
		a.makes the attribute Info and Prompt specific info field into empty and again calls the getCustomDatatableCompInput method to generate the prompt
        @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
        */
    @AuraEnabled
    public static String  clearPromptInfo(String plantAssetId,String previousPromptName){
        String result = 'false' ;
        try{
            List<String> retainValuesForPromptAttr = new List<String>{prepopulateColumnName};
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
        } catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }      
    }
}