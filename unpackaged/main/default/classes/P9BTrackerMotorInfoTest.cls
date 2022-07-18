/**
**/
@istest
public with sharing class P9BTrackerMotorInfoTest {
    @testSetup
    public static void testDataSetup() {
        Boolean isKeyToGenerateRows = false;
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        String currentPromptName = Constants.P9B_TRACKER_MOTOR_INFO;
        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;
 
        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Tracker Motor', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

        Prompt_Information__c newP9BPromptInfo = TestDataFactory.createPromptInformation(Constants.P9B_TRACKER_MOTOR_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP9BPromptInfo;

        Prompt_Information__c newP9APromptInfo = TestDataFactory.createPromptInformation(Constants.P9A_TRACKER_CONTROLLER_INFO,newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP9APromptInfo;

        Prompt_Information__c newP3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP3PromptInfo;

        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Text','Number','Text','Text'};
        list<String>coreAttrNameLst = new list<String>{'Manufacturer','AC Capacity','Tracker','Serial Number'};
        for(integer i = 0; i < 4; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newBaseAssetTemplate.Id, newTemVersion.Id);
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;

        Core_Attribute__c picklistDependency = TestDataFactory.createPromptSpecificAttr('Pad Name', 'Prompt Specific', 'Text', promptCoreAttrRTId, null, newP3PromptInfo.Id, newTemVersion.Id);       
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c>();
        list<String>promptSpecificAttrNameLst = new list<String>{'Pad Name', 'Tracker Controller Name'};
        list<String> promptDataTypeLst = new list<String>{'Text','Picklist'};
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                promptDataTypeLst[i],
                                                                                promptCoreAttrRTId,
                                                                                (promptDataTypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newP9BPromptInfo.Id, newTemVersion.Id);
            promptSpecificAttr.Picklist_Dependency1__c = (promptSpecificAttrNameLst[i] == 'Tracker Controller Name')?picklistDependency.id:null;                                                                 
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst;
  
        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 4; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive','Yes',coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplateG1.Id;
        insert g1PlantAssetPromptDetail;

        Site_Metadata__c newG1SiteMetadata = TestDataFactory.createG1SiteMetadata(newPlantAsset.Id);
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;

        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ newP3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.id;
        p3PlantAssetPromptDetail.Prompt_Information__c = newP3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{\"Pad Name\":\"Test Name\",\"Tracker Motor\":\"3\"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p3SiteMetaData.Prompt_Information__c = newP3PromptInfo.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        insert p3SiteMetaData;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+ newP9APromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.id;
        plantAssetPromptDetail.Prompt_Information__c = newP9APromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c p9ASiteMetaData = new Site_Metadata__c(); 
        p9ASiteMetaData.Name = Constants.P9A_TRACKER_CONTROLLER_INFO;
        p9ASiteMetaData.Prompt_Specific_Info__c = '{\"Pad Name\":\"Test Name\",\"Tracker Controller Name\":\"TCN 01\"}';
        p9ASiteMetaData.Attribute_Info__c = '{}';
        p9ASiteMetaData.Account_Plant__c= newPlantAsset.id;
        p9ASiteMetaData.Prompt_Information__c = newP9APromptInfo.Id;
        p9ASiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p9ASiteMetaData;

        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
       
        //Row Generation Check
        String dataTableInput = P9BTrackerMotorInfo.getCustomDatatableCompInput(newPlantAsset.id, plantAssetPromptDetail.id,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, newPlantAsset.id);
        System.assertEquals(3, currentPromptSiteMetadata.size());

        //Save SiteMetadata Check
        String trackerMotorName ='Tracker Motor Name';
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(trackerMotorName,'Motor 02');     
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = P9BTrackerMotorInfo.saveSiteMetadataRecords(newPlantAsset.id, siteMetadataRecordSaveCheck, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, newPlantAsset.id);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedTrackerMotorAttrName = promptSpecificInfoMapSaveCheck.containsKey(trackerMotorName)?promptSpecificInfoMapSaveCheck.get(trackerMotorName):'';
        System.assertEquals('Motor 02',updatedTrackerMotorAttrName);

        //clear Site MetaData Check
        String clearDataCheck = P9BTrackerMotorInfo.clearPromptInfo(newPlantAsset.id, plantAssetPromptDetail.id);
        string keyValue = 'Tracker Motor Name';
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(keyValue); 
        String clearedMeterNameCheck = promptSpecificInfoMapClearCheck.containsKey(keyValue)?promptSpecificInfoMapClearCheck.get(keyValue):'';
        System.assertEquals(clearValue, clearedMeterNameCheck );
    }
    public static testmethod void nextPromptTest(){
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c = '7777.77.777'].Id;
        String plantAssetName = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c = '7777.77.777'].Name;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.9.A Tracker Controller Info'].Id;
        String nextPromptName = Constants.P10A_OTHER_ASSET_BUILD;
        String currentPromptName = Constants.P9B_TRACKER_MOTOR_INFO;
        Boolean isKeyToGenerateRows = false;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Tracker Motor', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Prompt_Information__c newP3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP3PromptInfo;

        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;
        
        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = plantAssetName +'-'+ newP3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = plantAsset;
        p3PlantAssetPromptDetail.Prompt_Information__c = newP3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name =  Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{\"Tracker Controller\":\"\",\"Tracker Motor\":\"\",\"Transformers\":\"\",\"Other Assets\":\"Yes\",\"Relay\":\"4\"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c= plantAsset;
        p3SiteMetaData.Prompt_Information__c = newP3PromptInfo.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        insert p3SiteMetaData;
        
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        Test.startTest();
        String nextResponse = P9BTrackerMotorInfo.findNextPromptId(plantAsset,siteMetadataRecords,isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Test.stopTest();
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);        
    }
}