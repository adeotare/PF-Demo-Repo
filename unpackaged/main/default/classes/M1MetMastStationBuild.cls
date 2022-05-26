public with sharing class M1MetMastStationBuild {
    public static String currentPromptName = Constants.M1_MET_MAST_STATION_BUILD;
    public static String parentSiteMetadataPrompt = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
    public static String rowGeneratorAttrName = Constants.MET_MAST;
    public static String nextPromptname = Constants.M2_METMAST_STATION_BUILD;
    
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
    public static String getCustomDatatableCompInput(String plantAssetId, String previousPromptName, String jsonInputParametersAndValues){
        Savepoint sp = Database.setSavepoint();
        try {   
            Id basetAssetId;
            String baseAssetShortName;
            String csvData;
            List<Core_Attribute__c> filteredCoreAttributes = new List<Core_Attribute__c>();
            List<Core_Attribute__c> coreAttributes = new List<Core_Attribute__c>();
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            
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
                baseAssetShortName = promptInfo.Base_Asset_Template__r.Asset_Short_Name__c;

                Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
                Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
                Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
                filteredCoreAttributes = Utils.queryCoreAttributes(basetAssetId, filteredAttributesId);
                coreAttributes = Utils.queryCoreAttributes(basetAssetId, allAttributesId);
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
            
            List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributesM1(promptInfo.Id, plantAssetId, bifacialModules);
            String coreAttributeInfoJSON = Utils.serializeAttribute(coreAttributes);                
            Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);       
        
            // Query current prompt site metadata table rows
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName,plantAssetId);  
            //List<Site_Metadata__c> g1PromptSiteMetadata = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);     

            List<Site_Metadata__c> rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(parentSiteMetadataPrompt,plantAssetId);
            String parentPlantAssetPromptDetail;
            
            // Query previous prompt site metadata to populate table rows 
            if(rowGeneratorPromptSiteMetadata.size()>0){
                parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
            }

            if(currentPromptSiteMetadata.size()<=0){
                // Query previous prompt site metadata to populate table rows 
                Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                insert plantAssetPromptCreateInstance;
                List<Site_Metadata__c> parentAssets = new List<Site_Metadata__c>(); 
                Integer rowCount = 0;

                if(!String.isBlank(rowGeneratorAttrName)){
                    Map<String, Integer> parentAssetIdtoNoofChild = new Map<String, Integer>(); 
                    
                    for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                        Map<String, String> promptSpecificInfoMap = 
                                            (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                        if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){
                            if(!String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                                for(Integer count = 0; count < Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName)); count++){
                                    parentAssets.add(rowGenMetadata);
                                }
                            }
                            rowCount += Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName));
                        }
                    }
                }
 
                if(rowCount>0){
                    //Create 'n' number of  site metadata records based on the Met Mast Count from the G1 G2 Plant Info and Renewable Type Prompt
                    List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                    for(integer i = 0; i < rowCount; i++){
                        Map<String,String> rowGenPromptSpecificInfoMap = Utils.deserializeAttribute(parentAssets[i].Prompt_Specific_Info__c);
                                
                            Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, Utils.serializeAttribute(promptSpecificAttributes),
                                        String.valueOf(plantAssetPromptCreateInstance.Id), coreAttributeInfoJSON,
                                        g1PromptSiteMetadata[0].Id, basetAssetId, promptInfo.Id,'');
                            siteMetadataCreation.add(siteMetadata);
                        }
                        if(siteMetadataCreation.size()>0){ 
                           // sitemetadata insert in Util method
                           Utils.insertSitemetadata(siteMetadataCreation);
                        }
                        currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName,plantAssetId);
                }else{
                    String errorMessage = System.Label.M1AValidCheckMetMast;
                    throw new AuraHandledException(errorMessage);   
                }
            } else if(currentPromptSiteMetadata.size()>0){
                currentPromptSiteMetadata  =  Utils.newP2SiteMetadataRecords('', Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId, rowGeneratorAttrName, currentPromptName, parentPlantAssetPromptDetail, bifacialModules);
            }

            Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
            Utils.checkPreviousPlantAsset(plantAssetPromptDetail, previousPromptName);
            Map<String,Object> customDatatableCompInputsMap = Utils.getDatatableInputsMap(filteredCoreAttributes, promptSpecificAttributes, 
                currentPromptSiteMetadata, plantAssetPromptDetail, promptInfo);
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
        * On click of Clear Button, calls "clearPromptInfo" of Prompt Controller 
            a.makes the attribute Info and Prompt specific info field into empty and again calls the getCustomDatatableCompInput method to generate the prompt
        @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
    */
    public static String  clearPromptInfo(String plantAssetId, String previousPromptName){
       try{
            String result = 'false';
            List<String> retainValuesForPromptAttr = new List<String>{};
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
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }

    /*
    * On click of Next Button,
        a.  Saves the Current Site Metadata records, only if any changes occured in the prompt which is tracked by a boolean variable "attrValueChanged"
        b.  Based on the next available prompt attribute count, the metMastNextPromptFinder method navigates to the next prompt. 
    @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
    @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
    @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked
    @param {Boolean} attrValueChanged - Any changes occured in the prompt which is tracked
    */	
    @AuraEnabled
    public static String findNextPromptId(String plantAssetId, String siteMetadataRecordsToSave, Boolean isKeyToGenerateRows, 
        Boolean attrValueChanged, String additionalParamsForNext, Boolean finalBatchBoolean){
        String nextPromptId;
        Boolean saveSiteMetadataOutput = true;
        try{
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            Map<String,String> additionalParamsMap  = (Map<String,String>)JSON.deserialize(additionalParamsForNext, Map<String,String>.class);
            if(!String.isBlank(siteMetadataRecordsToSave)  && additionalParamsMap.get('isReadOnly') == 'false'){ 
                saveSiteMetadataOutput = Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
            }
            if(finalBatchBoolean){
                if(saveSiteMetadataOutput){  
                    nextPromptId = Utils.nextPromptFinder(currentPromptName, plantAssetId);
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
        } catch (Exception exceptionDetails) {
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug('Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }

    public static String  metMastNextPromptFinder(String plantAssetId, String PromptName){
        String nextPromptId;
        Set<String> metMastAttributeNames = new Set<String>();
        Integer metMastCount = 0;
        
        List<Core_Attribute__c> metMastAttributes =  [select Name, Sensor_Type__c, Attribute_Master__r.Name from Core_Attribute__c where Prompt_Information__r.Name =: currentPromptName AND Sensor_Type__c = 'Metmast'];
        if(metMastAttributes.size() >0){
            for(Core_Attribute__c attribute : metMastAttributes){
                metMastAttributeNames.add(attribute.Attribute_Master__r.Name);
            }
        }
        List<Site_Metadata__c> m1MetMastStationBuildSiteMetaData = Utils.querySiteMetadata(currentPromptName, plantAssetId);
        for(Site_Metadata__c m1MetMastStationBuild : m1MetMastStationBuildSiteMetaData){
            Map<String,String> m1PromptSpecificInfoMap = 
                (Map<String, String>) System.JSON.deserialize(m1MetMastStationBuild.Prompt_Specific_Info__c, Map<String, String>.class);
            for(String metMastAttributeName : metMastAttributeNames){
                if(m1PromptSpecificInfoMap.containsKey(metMastAttributeName)){
                    if(!String.isBlank(m1PromptSpecificInfoMap.get(metMastAttributeName)) ){
                        metMastCount = metMastCount + Integer.valueOf(m1PromptSpecificInfoMap.get(metMastAttributeName));
                        if(metMastCount>0){
                            break;
                        }
                    }
                }
            }
        }      
        if(metMastCount > 0  && PromptName == currentPromptName){
            nextPromptId = PromptNavigationHelper.findPromptId(nextPromptname);
        }
        return nextPromptId;
    }
}