/*
Author : 
Date : 
Description : 
            - Controller of G1 Intial Plant Info Prompt which helps to query Plant Asset, 
                save the Prompt Specific Info in Site Metadata object.
            - Prompt Specific Info are stored in JSON Format

*/
public with sharing class G1IntialPlantInfoPrompt {
    public Static String currentPromptName = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT ;
    /*
    * Query Account records and Plant Asset records of child Asset record type based on the salesforce licence type and return it to the lwc component
    @param {String} recordId - Holds the record id of the plant asset record when we utilize the quick action from the plant asset record
    @param {Boolean} fromPlantAssetList - If the component loads from the plant asset record, the boolean is set to true. 
    */
    @AuraEnabled
    public static string queryPlantAssetList(String recordId, Boolean fromPlantAssetList) {
        List<Account_Plant__c> plantAssets = new List<Account_Plant__c>();
        List<Account> accountList = new List<Account>();
        accountList = [SELECT id, Name from Account  where OwnerId = :UserInfo.getUserId() ORDER BY Name ASC];
        
        String plantAssetRecordsQryStr = formPlantAssetQryString();

        plantAssetRecordsQryStr +=' ORDER BY Name ASC'; 
        system.debug('---plantAssetRecordsQryStr----'+plantAssetRecordsQryStr);     
        plantAssets = (List<Account_Plant__c>)Database.query(plantAssetRecordsQryStr);
        
        Map<String, Object> accountAndPlantAssetMap = new Map<String,Object>();
        accountAndPlantAssetMap.put('Account', accountList);
        accountAndPlantAssetMap.put('PlantAssetList', plantAssets);
        return JSON.serialize(accountAndPlantAssetMap);   
    }
   /*
    * Query Account records and Plant Asset records of child Asset record type based on the salesforce licence type and return it to the lwc component
    @param {String} accId - Holds the record id of the account record when we utilize the quick action from the account record
    @param {Boolean} fromPlantAssetList - If the component loads from the plant asset record, the boolean is set to true. 
    */
    @AuraEnabled
    public static List<Account_Plant__c> queryPlantAssetListAcc(Boolean fromPlantAssetList, String accId) {
        List<Account_Plant__c> plantAssets = new List<Account_Plant__c>();        
      
        String plantAssetRecordsQryStr = formPlantAssetQryString();  

        if(!string.isBlank(accId) && accId != 'None'){
            plantAssetRecordsQryStr += ' where Account__c =: accId';  
        }
        plantAssetRecordsQryStr +=' ORDER BY Name ASC';

        plantAssets = (List<Account_Plant__c>)Database.query(plantAssetRecordsQryStr);   
        return plantAssets;
    }

    /*
     * update switchgear & metmast count in the appropriate plant asset record and creates a plant asset prompt detail record and site metadata record for the current prompt.
     * @param {Account_Plant__c} plantAsset - Plant Asset that user selected in the component.
     * @param {Integer} metMastCount - To create Met Mast Count based on this value later.
     * @param {Integer} switchgearsSubstationCount - To Create switch gear and substation prompt based on this value later.
     */
    @AuraEnabled
    public static Boolean savePlantAsset(String plantAssetId, String metMastCount, String switchgearsSubstationCount, 
        String renewableType, String pfServiceProduct, String bifacialModules){
        try {
            Boolean plantAssetUpdateRet;
            Boolean retValue = false;
            if(plantAssetId != null){
                plantAssetUpdateRet = plantAssetUpdate(plantAssetId, (metMastCount != null) ? metMastCount : '0',
                    (switchgearsSubstationCount != null) ? switchgearsSubstationCount : '0', renewableType, pfServiceProduct, bifacialModules);
                if(plantAssetUpdateRet){
                    retValue = true;
                }
            }
            return retValue;
        } catch (Exception exp) {
            System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
            throw new AuraException(' Please Contact Administrator. '+exp.getMessage());
        }   
    }

    /*Navigates to the next prompt, 
     * on click of next button in component,calls this method and saves the metmastcount & switchgearsubstation count in the plant asset record and site metadata record.
     * @param {Account_Plant__c} plantAsset record from the component, which is passed to the next prompt 
     * @param {Integer} metMastCount - To create Met Mast Count based on this value later.
     * @param {Integer} switchgearsSubstationCount - To Create switch gear and substation prompt based on this value later.
     */
    @AuraEnabled
    public static String findNextPromptId(String plantAssetId, String metMastCount, 
        String switchgearsSubstationCount,String renewableType, String pfServiceProduct, 
        String additionalParamsForNext, String jsonInputParametersAndValues){
        try {
            system.debug('----plantAssetId-----'+plantAssetId+'---metMastCount---'+metMastCount+'--switchgearsSubstationCount--'+switchgearsSubstationCount);
            system.debug('---renewableType----'+renewableType+'---pfServiceProduct--'+pfServiceProduct+'---additionalParamsForNext--'+additionalParamsForNext);
            // call location api
            List<Plant_Asset_Prompt_Detail__c> plantAssetPD = new List<Plant_Asset_Prompt_Detail__c>();

            plantAssetPD = [SELECT id,Is_Location_Fetched__c
                                        FROM Plant_Asset_Prompt_Detail__c
                                        WHERE Account_Plant__c =: plantAssetId AND Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND Is_Deleted__c = FALSE LIMIT 1];
            Map<String, String> locationAPImap =  new Map<String, String>();
            Boolean locationFetched = true;
/*            if(plantAssetPD.size() > 0 && !plantAssetPD[0].Is_Location_Fetched__c) {
                locationAPImap = AssetBuilderLocationAPI.callLocationAPI(plantAssetId, plantAssetPD[0], false, false);
            } else{
                Plant_Asset_Prompt_Detail__c plantAssetPrompt = new Plant_Asset_Prompt_Detail__c();
                locationAPImap = AssetBuilderLocationAPI.callLocationAPI(plantAssetId, plantAssetPrompt, false, false);
            }
*/
            if(locationFetched) {
                String nextPromptId;
                Boolean plantAssetUpdateOutput = true;
                Map<String, String> additionalParamsMap = (Map<String, String>) JSON.deserialize(additionalParamsForNext, Map<String, String>.class);
                if (plantAssetId != null) {
                    if (additionalParamsMap.get('isReadOnly') == 'false') {
                        plantAssetUpdateOutput = plantAssetUpdate(plantAssetId,
                        (metMastCount != null) ? metMastCount : '0',
                        (switchgearsSubstationCount != null) ? switchgearsSubstationCount : '0', 
                        renewableType, pfServiceProduct, additionalParamsMap.get('bifacialModules'));
                    }
                    List<Account_Plant__c> plantAsset = [
                            SELECT Id, Name, Commercial_Operating_Date__c, Latitude__c, Longitude__c,
                                    Plant_Name__c, Drive_Id__c,
                                      Renewable_Type__c, TEM_Version__c,
                                    Asset_Builder_Status__c, PF_Service_Product__c
                            FROM Account_Plant__c
                            WHERE Id = :plantAssetId
                    ];

                    List<Site_Metadata__c> g1SiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
                    Map<String, String> promptSpecificInfoMap =
                            (Map<String, String>) System.JSON.deserialize(g1SiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);

                    Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();

                    if (!String.isBlank(jsonInputParametersAndValues)) {
                        Map<String, String> jsonInputParametersAndValuesMap = Utils.deserializeAttribute(jsonInputParametersAndValues);
                        Boolean isBulkUploadCheck = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD));
                        Boolean isBulkUploadMultipleBATCheck = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD_MULTIPLE_BAT));
                        if (!isBulkUploadCheck && !isBulkUploadMultipleBATCheck) {
                            Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = Utils.getG1PlantAssetPromptDetail(plantAssetId);
                            if (g1PlantAssetPromptDetail.Bulk_Import_Type__c != Constants.MULTIPLE_BASE_ASSET_TEMPLATE_PROMPTS) {
                                g1PlantAssetPromptDetail.Bulk_Import_Type__c = Constants.Manual;
                                update g1PlantAssetPromptDetail;
                            }
                        }
                    }

                    if (plantAssetUpdateOutput) {
                        system.debug('---promptSpecificInfoMap--'+promptSpecificInfoMap);
                        if (promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE).contains(Constants.SOLAR)) {
                            nextPromptId = PromptNavigationHelper.findPromptId(Constants.P1_PLANT_INFO_PROMPT_SOLAR);
                        } else if (promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE).contains(Constants.WIND)) {
                            nextPromptId = PromptNavigationHelper.findPromptId(Constants.W1_PLANT_INFO_PROMPT_WIND);
                        }
                        if (nextPromptId.length() <= 8 && additionalParamsMap.get('isReadOnly') == 'false') {
                            plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAsset[0].Id, currentPromptName);
                            plantAssetPromptDetail.Validate_On_Previous__c = true;
                            update plantAssetPromptDetail;
                        }
                    }
                    return Utils.nextPromptFinderResponse(String.valueOf(plantAsset[0].Id), PromptNavigationHelper.findPromptId(currentPromptName), nextPromptId, String.valueOf(plantAssetPromptDetail.Id));
                }
                return null;
            }
            return null;
        } catch (Exception exp) {
            System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
            throw new AuraException(' Please Contact Administrator. '+exp.getMessage());
        }
    }

    /*
     * On Click of save button, call this method , update the switchgear and metmast count in the plant Asset record
     * @param {Account_Plant__c} - Plant Asset record to update 
     * @param {Integer} metMastCount - To create Met Mast Count based on this value later.
     * @param {Integer} switchgearsSubstationCount - To Create switch gear and substation prompt based on this value later.
     */
    private static Boolean plantAssetUpdate(String plantAssetId, String metMastCount, String switchgearsSubstationCount, 
        String renewableType, String pfServiceProduct, String bifacialModules){
        Savepoint sp = Database.setSavepoint();   
        Boolean retValue = false;
        try {
            Boolean isDelete = false;
            Boolean isDeleteCheck = false;
            String promptTypeMetMast = '';
            String promptType = '';
            String promptTypeSolar = '';
            String status = 'Active';

            Map<String, String> g1PromptInfo = new Map<String, String>();
            List<Site_Metadata__c> g1SiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
            for(Site_Metadata__c g1SiteMetadataObj : g1SiteMetadata){
                g1PromptInfo = 
                      (Map<String, String>) System.JSON.deserialize(g1SiteMetadataObj.Prompt_Specific_Info__c,Map<String, String>.class);
            }

            List<Account_Plant__c> plantAsset = [SELECT Id, Name, Commercial_Operating_Date__c, Latitude__c, Longitude__c,
                Plant_Name__c, Drive_Id__c,
                 Renewable_Type__c, TEM_Version__c,
                Asset_Builder_Status__c, PF_Service_Product__c
                FROM Account_Plant__c WHERE Id =: plantAssetId];
            
            List<TEM_Version__c> versionInfo = Utils.queryTemVersion('Active');
            if(g1PromptInfo.size()>0){
                if(!String.isBlank(g1PromptInfo.get(Constants.MET_MAST))){
                    if(Integer.valueOf(g1PromptInfo.get(Constants.MET_MAST)) > Integer.valueOf(metMastCount)){
                        isDelete = true;
                        promptTypeMetMast = Constants.MET_MAST;
                    }
                }

                if(!String.isBlank(g1PromptInfo.get(Constants.SWITCHGEAR_SUBSTATION))){
                    if(Integer.valueOf(g1PromptInfo.get(Constants.SWITCHGEAR_SUBSTATION)) > Integer.valueOf(switchgearsSubstationCount)){
                        isDelete = true;
                        promptType = Constants.SUBSTATIONSWITCHGEAR;
                    }
                }

                if(!String.isBlank(g1PromptInfo.get(Constants.BIFACIAL_MODULES))){
                    if(Boolean.valueOf(g1PromptInfo.get(Constants.BIFACIAL_MODULES)) != Boolean.valueOf(bifacialModules)){
                        isDelete = true;
                        promptTypeSolar = Constants.SOLAR;
                        promptTypeMetMast = Constants.MET_MAST;
                    }
                } 
            }
            
            if(versionInfo.size() > 0 && plantAsset[0].TEM_Version__c == NULL){
                plantAsset[0].TEM_Version__c = versionInfo[0].Id;
            }
            plantAsset[0].Asset_Builder_Status__c = Constants.IN_PROGRESS_ABS;
            update plantAsset;
            try { 
                Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
                List<Plant_Asset_Prompt_Detail__c> plantAssetPromptCreateList = new List<Plant_Asset_Prompt_Detail__c>();
                List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName,plantAssetId);
                Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(String.valueOf(plantAssetId),currentPromptName,'','');
                if(currentPromptSiteMetadata.size() < = 0){    
                    insert plantAssetPromptCreateInstance;
                    retValue = true;
                    Map<String,String> promptSpecificInfo = new Map<String,String>();
                    promptSpecificInfo.put(Constants.MET_MAST, String.valueOf(metMastCount));
                    promptSpecificInfo.put(Constants.SWITCHGEAR_SUBSTATION, String.valueOf(switchgearsSubstationCount));
                    promptSpecificInfo.put(Constants.RENEWABLE_TYPE, (renewableType != NULL) ? renewableType : '');
                    promptSpecificInfo.put(Constants.PF_SERVICE_PRODUCT, (PFServiceProduct != NULL) ? PFServiceProduct :'');
                    promptSpecificInfo.put(Constants.BIFACIAL_MODULES, (bifacialModules != NULL) ? bifacialModules :'');
                    String promptSpecificInfoJSON = JSON.serialize(promptSpecificInfo);

                    // to get prompt attribute info
                    List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);
                    Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
                    String promptAttributeInfoJSON = JSON.serialize(promptAttributeInfo);

                    Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId,currentPromptName,promptSpecificInfoJSON,
                                                                            plantAssetPromptCreateInstance.Id,'{}','','',promptInfo.Id,'');
                    String plantAssetCustomerId = plantAsset[0].Drive_Id__c;
                    List<String> customerAssetIdSplitList = plantAssetCustomerId.split('\\.');
                    if(customerAssetIdSplitList.size()>0){
                        siteMetadata.Parent_Asset_Short_Name__c = customerAssetIdSplitList[0]+'\\'+customerAssetIdSplitList[1]+'\\'+
                                                                customerAssetIdSplitList[2];
                    }
                    insert siteMetadata;
                }else{
                    Map<String,String> coreAttrInfoMap = Utils.deserializeAttribute(currentPromptSiteMetadata[0].Prompt_Specific_Info__c);
                    coreAttrInfoMap.put(Constants.MET_MAST,String.valueOf(metMastCount));
                    coreAttrInfoMap.put(Constants.SWITCHGEAR_SUBSTATION,String.valueOf(switchgearsSubstationCount));
                    coreAttrInfoMap.put(Constants.BIFACIAL_MODULES, (bifacialModules != NULL) ? bifacialModules :'');

                    currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(coreAttrInfoMap);
                    update currentPromptSiteMetadata;
                    retValue = true;
                }
                if(isDelete = true && promptTypeSolar != ''){
                    isDeleteCheck = Utils.plantAssetPromptDetailIsDeleteUpdate(currentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__r.Id, promptTypeSolar);
                }

                if(isDelete = true && promptTypeMetMast != ''){
                    isDeleteCheck = Utils.plantAssetPromptDetailIsDeleteUpdate(currentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__r.Id, promptTypeMetMast);
                }
                
                if(isDelete = true && promptType != ''){
                    isDeleteCheck = Utils.plantAssetPromptDetailIsDeleteUpdate(currentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__r.Id, promptType);
                }
            } catch (Exception exp) {
                System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
                throw new AuraException(' Please Contact Administrator. '+exp.getMessage());
            }   
            
            return retValue;
        } catch (Exception exp) {
            Database.rollback(sp);
            System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
            throw new AuraException(' Please Contact Administrator. '+exp.getMessage());
        }   
    }
        // Query current prompt site metadata record of Prompt specific info details and return it to the lwc component
    @AuraEnabled
    public static string getSiteMetadata(String plantId){
        if((!string.isBlank(plantId) )&& plantId != 'None' ){
            Map<String,String> g1PromptSpecificInfo = new Map<String, String>();
            List<Site_Metadata__c> g1SiteMetadata = Utils.querySiteMetadata(currentPromptName, plantId);
            for(Site_Metadata__c g1SiteMetadataObj : g1SiteMetadata){
                g1PromptSpecificInfo = (Map<String, String>) System.JSON.deserialize(g1SiteMetadataObj.Prompt_Specific_Info__c,Map<String, String>.class);
                g1PromptSpecificInfo.put('plantTemVersion', g1SiteMetadata[0].Account_Plant__r.TEM_Version__r.Name);
            }

            return JSON.serialize(g1PromptSpecificInfo);
        }   
        return null;
    } 

    public static String formPlantAssetQryString(){
        String pfServiceProduct = Constants.IMPLEMENTATION_ASSET_BUILDING; 
        String partnerImplementationScopeValue = Constants.ASSET_BUILD; 
        String plantAssetRecordsQryStr = '';

        List<String> abApprovalStatusLst = new List<String>();
        List<String> renewableTypeLst = new List<String>();

        for(PAVisibilityInCommBOABApprovalStatus__mdt abApprovalStatus : [SELECT Label FROM  PAVisibilityInCommBOABApprovalStatus__mdt]){
            abApprovalStatusLst.add((abApprovalStatus.Label));
        }

        for(RenewableTypesForPlantListAB__mdt renewableType : [SELECT Renewable_Type__c FROM RenewableTypesForPlantListAB__mdt]) {
            renewableTypeLst.add(renewableType.Renewable_Type__c);
        }

        Map<String,List<string>> licenseToPLCStatusMetadata = Utils.projectLifecycleStatus();

//        String customerAssetRecordTypeId = Utils.getRecordTypeInfo('Account_Plant__c','Child_Asset').getRecordTypeId();

        plantAssetRecordsQryStr += 'SELECT Id, Name,Account__c,Plant__r.Name, Commercial_Operating_Date__c, Latitude__c, Longitude__c,Plant_Name__c, Drive_Id__c, TEM_Version__r.Name,';
        plantAssetRecordsQryStr += 'Renewable_Type__c, TEM_Version__c,Asset_Builder_Status__c, AB_Approval_Status__c, Project_Lifecycle_Status__c , PF_Service_Product__c';
        plantAssetRecordsQryStr += ' FROM Account_Plant__c ';
/*
        User userSO = [Select Id, Name, Profile.UserLicense.Name, Contact.Account.Type From User WHERE Id=: UserInfo.getUserId()];
        String userLicenseName = userSO.Profile.UserLicense.Name;
        String userAccountType = userSO.Contact.Account.Type;

        if(licenseToPLCStatusMetadata.containskey(userLicenseName)){
            List<string> plcStatusList  = new List<String>();
            if(userAccountType == Constants.PARTNER){
                plcStatusList = licenseToPLCStatusMetadata.get(Constants.SALESFORCE) ;
            }else{
                plcStatusList = licenseToPLCStatusMetadata.get(userLicenseName) ;
            }
            plantAssetRecordsQryStr += ' Project_Lifecycle_Status__c in (\'' +String.join((Iterable<String>)plcStatusList, '\',\'')+ '\')'; 
        }
        if(!renewableTypeLst.isEmpty() && renewableTypeLst.size() > 0){
            plantAssetRecordsQryStr += '  AND Renewable_Type__c  IN (\'' +String.join((Iterable<String>)renewableTypeLst, '\',\'')+ '\')';
        }

        if(userLicenseName == Constants.SALESFORCE){
            plantAssetRecordsQryStr +=' AND PF_Service_Product__c  INCLUDES ( \'' +pfServiceProduct+ '\')';
        }
        else if(userAccountType == Constants.PARTNER){
            plantAssetRecordsQryStr +=' AND PF_Service_Product__c  INCLUDES ( \'' +pfServiceProduct+ '\')';
            plantAssetRecordsQryStr +=' AND Partner_Implementation_Scope__c INCLUDES ( \'' +partnerImplementationScopeValue+ '\')';
        }
        else{
            plantAssetRecordsQryStr +=' AND (PF_Service_Product__c  EXCLUDES (\'' +pfServiceProduct+ '\')';
            plantAssetRecordsQryStr += ' OR (PF_Service_Product__c  INCLUDES (\'' +pfServiceProduct+ '\')';
            plantAssetRecordsQryStr += '  AND AB_Approval_Status__c  IN (\'' +String.join((Iterable<String>)abApprovalStatusLst, '\',\'')+ '\')))';
        }*/
        return plantAssetRecordsQryStr;
    }
}