public with sharing class P10AOtherAssetBuild {
    public static String currentPromptName = Constants.P10A_OTHER_ASSET_BUILD;
    public static String parentSiteMetadataPrompt = Constants.P3_PAD_BUILDS_AND_COUNTS;
    public static String rowGeneratorAttrName = Constants.OTHER_ASSETS;
    public static String prepopulateColumnName = Constants.PAD_NAME;

    /*
    * Query Site Metadata record for current prompt name and Plant Asset Id , and check if any record exists,
        if No,
            a. Create a record in Plant Asset Prompt Detail Object for the current Prompt 
            b. Create Site Metadata record for current Prompt the count of row generate atttribute name
            c. Query Parent Prompt sitemetadata and fetch the alternate prompt specific attribute and query Site Metadata record
                of current prompt and return to lwc "assetBuilderCustomDatatable" for prompt table creation through the current prompt lwc component

        if yes,
            a. New Site Metadata records are  newly created for the current prompt
            b. Query the Plant Asset Prompt Detail  of current prompt and compares the "Previous_Plant_Asset_Prompt__c" field  with	the previous prompt name.
                if not matched,
                        Previous_Plant_Asset_Prompt__c field is updated with previous prompt name.
            c. Query Site Metadata record of current prompt and return to lwc  "assetBuilderCustomDatatable"  for prompt table creation
            through the current prompt  lwc component
    
    @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
    @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.        
     */
    @AuraEnabled
    public static String getCustomDatatableCompInput(String previousPromptName, String plantAssetId, String jsonInputParametersAndValues){
        Savepoint sp = Database.setSavepoint();
        try{
            Id basetAssetId;
            String baseAssetShortName;
            String csvData;
            List<Core_Attribute__c> filteredCoreAttributes = new List<Core_Attribute__c>();
            List<Core_Attribute__c> coreAttributes = new List<Core_Attribute__c>();
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
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
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
            List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
            List<Site_Metadata__c> rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(parentSiteMetadataPrompt, plantAssetId);
            String parentPlantAssetPromptDetail;

            // The currentSitemetadataCount is get the count of current sitemetadata records
            for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                Map<String, String> promptSpecificInfoMap = 
                        (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){        
                    if(!String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                        if(promptSpecificInfoMap.get(rowGeneratorAttrName) == Constants.YES){
                            currentSitemetadataCount = currentSitemetadataCount + 1;
                        }  
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
                   List<Site_Metadata__c> parentAssets = new List<Site_Metadata__c>(); 
                   Integer rowCount = 0;
                   if(rowGeneratorPromptSiteMetadata.size()>0){
                       parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
                   }
                   Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                   insert plantAssetPromptCreateInstance;
   
                   if(rowGeneratorPromptSiteMetadata.size() > 0){
                       if(!String.isBlank(rowGeneratorAttrName)){
                           for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                               Map<String, String> promptSpecificInfoMap = 
                                       (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                               if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){        
                                   if(!String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                                       if(promptSpecificInfoMap.get(rowGeneratorAttrName) == Constants.YES){
                                           parentAssets.add(rowGenMetadata);
                                           rowCount = rowCount + 1;
                                       }  
                                   }    
                               }
                           }
                       }
                       if(rowCount>0){
                           //Create 'n' number of  site metadata records based on the Tracker Controller from the W.3.0 Turbine Build
                           for(integer i = 0; i < rowCount; i++){
                               Map<String,String> rowGenPromptSpecificInfoMap = Utils.deserializeAttribute(parentAssets[i].Prompt_Specific_Info__c);
                               String prepopulateColumnValue = rowGenPromptSpecificInfoMap.containsKey(prepopulateColumnName)?
                                                       rowGenPromptSpecificInfoMap.get(prepopulateColumnName):'';
                               promptAttributeInfo.put(prepopulateColumnName,parentAssets[i].Id);
       
                               Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                                                   String.valueOf(plantAssetPromptCreateInstance.Id), coreAttributeInfoJSON,
                                                                                   String.valueOf(parentAssets[i].Id), basetAssetId, promptInfo.Id, '');
                                
                               siteMetadataCreation.add(siteMetadata);
                           }  
                           if(siteMetadataCreation.size()>0){
                               //sitemetadata insert in Util method
                               Utils.insertSitemetadata(siteMetadataCreation);
                           }
                           currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName,plantAssetId);
                       }else{
                           throw new AuraHandledException(System.Label.P10ANoOtherAssetFound);   
                       }
                   }
                }  else if(currentPromptSiteMetadata.size() > 0){
                   Set<String> parentSiteMetaIds = new Set<String>();
                   
                   for(Site_Metadata__c siteData: currentPromptSiteMetadata){
                       parentSiteMetaIds.add(siteData.Parent_Site_Metadata__c);
                   }
                   
                   List<Site_Metadata__c> p3ANewSiteMetadataLst = [SELECT Id, Name, Attribute_Info__c, Base_Asset_Template__c, Account_Plant__c, Parent_Site_Metadata__r.Asset_Name__c,
                               Prompt_Specific_Info__c, Parent_Site_Metadata__c, Parent_Site_Metadata__r.Name, Previous_Prompt_Name__c, Plant_Asset_Prompt_Detail__c,
                               Parent_Site_Metadata__r.Alternate_Parent_Site_Metadata__r.Asset_Name__c, Alternate_Parent_Site_Metadata__c
                               FROM Site_Metadata__c 
                               WHERE Name =:parentSiteMetadataPrompt AND ID NOT IN: parentSiteMetaIds
                               AND Account_Plant__c =: plantAssetId AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false];
                   
                   if(p3ANewSiteMetadataLst.size()>0){
                       Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                        List<Site_Metadata__c> parentAssets = new List<Site_Metadata__c>();
                       List<Site_Metadata__c> newSiteMetadataRecords = new List<Site_Metadata__c>();
                       Integer rowCount = 0;
                       if(!String.isBlank(rowGeneratorAttrName)){
                           for(Site_Metadata__c rowGenMetadata : p3ANewSiteMetadataLst){
                               Map<String, String> promptSpecificInfoMap = 
                                       (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                               if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){        
                                   if(!String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                                       if(promptSpecificInfoMap.get(rowGeneratorAttrName) == Constants.YES){
                                           parentAssets.add(rowGenMetadata);
                                           rowCount = rowCount + 1;
                                       }  
                                   }    
                               }
                           }
                       }
                       if(rowCount>0){
                           //Create 'n' number of  site metadata records based on the Tracker Controller from the W.3.0 Turbine Build
                           for(integer i = 0; i < rowCount; i++){
                               Map<String,String> rowGenPromptSpecificInfoMap = Utils.deserializeAttribute(parentAssets[i].Prompt_Specific_Info__c);
                               String prepopulateColumnValue = rowGenPromptSpecificInfoMap.containsKey(prepopulateColumnName)?
                                                       rowGenPromptSpecificInfoMap.get(prepopulateColumnName):'';
                               promptAttributeInfo.put(prepopulateColumnName,parentAssets[i].Id);
       
                               Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                                                   String.valueOf(plantAssetPromptDetail.Id), coreAttributeInfoJSON,
                                                                                   String.valueOf(parentAssets[i].Id), basetAssetId, promptInfo.Id,'');
                                
                               newSiteMetadataRecords.add(siteMetadata);
                           }  
                           if(newSiteMetadataRecords.size()>0){
                               //sitemetadata insert in Util method
                               Utils.insertSitemetadata(newSiteMetadataRecords);
                           }
                           currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
                       }
                   }
               }
            }
            
            Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
            Utils.checkPreviousPlantAsset(plantAssetPromptDetail, previousPromptName);
            //Map<String,Object> customDatatableCompInputsMap = Utils.getDatatableInputsMap(filteredCoreAttributes, promptSpecificAttributes, 
                //currentPromptSiteMetadata, plantAssetPromptDetail, promptInfo);

            Map<String,Object> customDatatableCompInputsMap = Utils.getDatatableInputsMapWithoutSiteMetadata(filteredCoreAttributes, promptSpecificAttributes, 
                currentSitemetadataCount, plantAssetPromptDetail, promptInfo);
            if(!String.isBlank(csvData) && !String.isBlank(jsonInputParametersAndValues)){
                customDatatableCompInputsMap.put('csvData', csvData);
            }           
           
                return JSON.serialize(customDatatableCompInputsMap);
        }catch(Exception exceptionDetail){
            Database.rollback(sp);
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }    
    }

    /*
    * On click of Save button,
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
        } catch(Exception exceptionDetail){
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
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
                    nextPromptId = PromptNavigationHelper.findPromptId(Constants.P10B_OTHER_ASSET_BUILD_AND_INFO);
                }
                if(nextPromptId.length() <= 8 && additionalParamsMap.get('isReadOnly') == 'false'){
                    Utils.updateValidateOnPrevious(plantAssetId,currentPromptName);
                }
                
                Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                
                return Utils.nextPromptFinderResponse(plantAssetId, PromptNavigationHelper.findPromptId(currentPromptName), nextPromptId, 
                    plantAssetPromptDetail.Id);
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
    * On click of Clear Button, calls "clearPromptInfo" of Prompt Controller 
		a.makes the attribute Info and Prompt specific info field into empty and again calls the getCustomDatatableCompInput method to generate the prompt
        
        @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
    */
    @AuraEnabled
    public static String  clearPromptInfo(String previousPromptName, String plantAssetId){
        String result = 'false';
        try{
            List<String> retainValuesForPromptAttr = new List<String>{prepopulateColumnName};
            List<String> retainValuesForCoreAttr = new List<String>();
            
            Boolean clearPromptInfoResult = Utils.clearPromptInfo(plantAssetId, currentPromptName, retainValuesForCoreAttr, retainValuesForPromptAttr);
            
            if(clearPromptInfoResult){
                List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
                Boolean IsUpdateCheck = Utils.plantAssetPromptDetailIsDeleteUpdate(
                                            currentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__r.Id,
                                            currentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__r.Prompt_Information__r.Type__c);
                result = getCustomDatatableCompInput( previousPromptName ,plantAssetId, '');
            } 
            return result;
        }catch(Exception exceptionDetails){
            String errorMessage = 'Please Contact Administrator'+ exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
}