/**
**/
@istest
public with sharing class P9ATrackerControllerInfoTest{
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive','7777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Tracker', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P9A_TRACKER_CONTROLLER_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;

        Prompt_Information__c p3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert p3PromptInfo;

        Prompt_Information__c newP7PromptInfo = TestDataFactory.createPromptInformation(Constants.P7_INVERTER_SUBARRAY_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP7PromptInfo;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c', 'Prompt_Specific_Attribute').getRecordTypeId();

        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Text', 'Number', 'Text', 'Text'};
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
        
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptSpecificAttrNameLst = new list<String>{'Pad Name', 'Tracker Controller Name'};
        
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                'Text',
                                                                                promptCoreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newPromptInfo.Id, newTemVersion.Id);
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst;

        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 4; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplateG1.Id;
        insert g1PlantAssetPromptDetail;

        Site_Metadata__c newG1SiteMetadata = TestDataFactory.createG1SiteMetadata(newPlantAsset.Id);
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;

        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = p3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{"Transformers":"1","Tracker Motor":"1","Tracker Controller":"2","Relay":"","Pad Name":"J","Other":"","Meter":"","Inverter":"2","Block Name":"B1"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c = newPlantAsset.id;
        p3SiteMetaData.Prompt_Information__c = p3PromptInfo.id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        insert p3SiteMetaData;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ newP7PromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.id;
        plantAssetPromptDetail.Prompt_Information__c = newP7PromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c p7SiteMetaData = new Site_Metadata__c(); 
        p7SiteMetaData.Name = Constants.P7_INVERTER_SUBARRAY_INFO;
        p7SiteMetaData.Prompt_Information__c = newP7PromptInfo.Id;
        p7SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Subarray Name\":\"SubArray01\"}';
        p7SiteMetaData.Attribute_Info__c = '{}';
        p7SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p7SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p7SiteMetaData;
    }

    public static testMethod void P9ATrackerControllerInfoTest(){
        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.7.0 Inverter Subarray Info'].Id;
        String currentPromptName = Constants.P9A_TRACKER_CONTROLLER_INFO;
        String nextPromptName = Constants.P9B_TRACKER_MOTOR_INFO;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
    
        String dataTableInput = P9ATrackerControllerInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(2, currentPromptSiteMetadata.size());

        //Save Site MeteData check
        String trackerAttrName = 'Tracker Controller Name';
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(trackerAttrName,'TrackerName1'); 
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = P9ATrackerControllerInfo.saveSiteMetadataRecords(plantAsset,siteMetadataRecordSaveCheck,isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedAttrName = promptSpecificInfoMapSaveCheck.containsKey(trackerAttrName)?promptSpecificInfoMapSaveCheck.get(trackerAttrName):'';
        System.assertEquals('TrackerName1',updatedAttrName);

        //clear Site MetaData Check
        String clearDataCheck = P9ATrackerControllerInfo.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        String keyValue ='Tracker Controller Name';
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(keyValue);    
        String clearedPromptSpecificInfoCheck 
                        = promptSpecificInfoMapClearCheck.containsKey(keyValue)?promptSpecificInfoMapClearCheck.get(keyValue):'';
        System.assertEquals(clearValue,clearedPromptSpecificInfoCheck );
    }

    public static testmethod void otherAsset(){
        String currentPromptName = Constants.P9A_TRACKER_CONTROLLER_INFO;
        String nextPromptName = Constants.P10A_OTHER_ASSET_BUILD;
        Boolean isKeyToGenerateRows = false;

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        
        Account_Plant__c plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'];
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.7.0 Inverter Subarray Info'].Id;

        Base_Asset_Template__c p3BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base pad', newTemVersion.Id);
        insert p3BaseAssetTemplate;
        
        Prompt_Information__c newP3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                                        p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert newP3PromptInfo;

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;

        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = plantAsset.Name +'-'+ newP3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = plantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = newP3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = p3BaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{\"Tracker Controller\":\"0\",\"Tracker Motor\":\"0\",\"Transformers\":\"\",\"Other Assets\":\"Yes",\"Relay\":\"4\"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c= plantAsset.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        insert p3SiteMetaData;

        Site_Metadata__c p7SiteMetaData = new Site_Metadata__c(); 
        p7SiteMetaData.Name = Constants.P7_INVERTER_SUBARRAY_INFO;
        p7SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Subarray Name\":\"SubArray01\"}';
        p7SiteMetaData.Attribute_Info__c = '{}';
        p7SiteMetaData.Account_Plant__c= plantAsset.Id;
        p7SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert p7SiteMetaData;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
    
        String dataTableInput = P9ATrackerControllerInfo.getCustomDatatableCompInput(plantAsset.Id, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset.Id);
       
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P9ATrackerControllerInfo.findNextPromptId(plantAsset.Id,siteMetadataRecords,isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
    }

    public static testmethod void windTest(){
        String currentPromptName = Constants.P9A_TRACKER_CONTROLLER_INFO;
        String nextPromptName = Constants.W1_PLANT_INFO_PROMPT_WIND;
        Boolean isKeyToGenerateRows = false;

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Base_Asset_Template__c p3BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base pad', newTemVersion.Id);
        insert p3BaseAssetTemplate;
        
        Prompt_Information__c newP3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                                        p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert newP3PromptInfo;
        
        Account_Plant__c plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'];
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.7.0 Inverter Subarray Info'].Id;

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;

        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = plantAsset.Name +'-'+ newP3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = plantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = newP3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = p3BaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{\"Tracker Controller\":\"0\",\"Tracker Motor\":\"0\",\"Transformers\":\"\",\"Other Assets\":\"",\"Relay\":\"\"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c= plantAsset.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        insert p3SiteMetaData;

        Site_Metadata__c p7SiteMetaData = new Site_Metadata__c(); 
        p7SiteMetaData.Name = Constants.P7_INVERTER_SUBARRAY_INFO;
        p7SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Subarray Name\":\"SubArray01\"}';
        p7SiteMetaData.Attribute_Info__c = '{}';
        p7SiteMetaData.Account_Plant__c= plantAsset.Id;
        p7SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert p7SiteMetaData;

        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        String dataTableInput = P9ATrackerControllerInfo.getCustomDatatableCompInput(plantAsset.Id, plantAssetPromptDetail, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset.Id);
       
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P9ATrackerControllerInfo.findNextPromptId(plantAsset.Id,siteMetadataRecords,isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
    }

    public static testmethod void metMaskTest(){
        String currentPromptName = Constants.P9A_TRACKER_CONTROLLER_INFO;
        String nextPromptName = Constants.M1_MET_MAST_STATION_BUILD;
        Boolean isKeyToGenerateRows = false;

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Base_Asset_Template__c p3BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base pad', newTemVersion.Id);
        insert p3BaseAssetTemplate;
        
        Prompt_Information__c newP3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                                        p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert newP3PromptInfo;

        Prompt_Information__c newg1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                                            p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert newg1PromptInfo;

        Account_Plant__c plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'];
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.7.0 Inverter Subarray Info'].Id;

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = plantAsset.Name +'-'+ newg1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = plantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = newg1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = p3BaseAssetTemplate.Id;
        insert g1PlantAssetPromptDetail;

        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{\"Metmast\":\"1\",\"Switchgear Substation\":\"\"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Account_Plant__c= plantAsset.Id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;

        Site_Metadata__c p7SiteMetaData = new Site_Metadata__c(); 
        p7SiteMetaData.Name = Constants.P7_INVERTER_SUBARRAY_INFO;
        p7SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Subarray Name\":\"SubArray01\"}';
        p7SiteMetaData.Attribute_Info__c = '{}';
        p7SiteMetaData.Account_Plant__c= plantAsset.Id;
        p7SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert p7SiteMetaData;

        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
    
        String dataTableInput = P9ATrackerControllerInfo.getCustomDatatableCompInput(plantAsset.Id, plantAssetPromptDetail, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset.Id);
       
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P9ATrackerControllerInfo.findNextPromptId(plantAsset.Id, siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
    }

    public static testmethod void substationTest(){

        String currentPromptName = Constants.P9A_TRACKER_CONTROLLER_INFO;
        String nextPromptName = Constants.S1_SUBSTATION_SWITCHGEAR_BUILD;
        Boolean isKeyToGenerateRows = false;

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Base_Asset_Template__c p3BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base pad', newTemVersion.Id);
        insert p3BaseAssetTemplate;
        
        Prompt_Information__c newP3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                                        p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert newP3PromptInfo;

        Prompt_Information__c newg1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                                            p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert newg1PromptInfo;

        Account_Plant__c plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'];
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.7.0 Inverter Subarray Info'].Id;

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = plantAsset.Name +'-'+ newg1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = plantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = newg1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = p3BaseAssetTemplate.Id;
        insert g1PlantAssetPromptDetail;

        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        p1SiteMetaData.Prompt_Specific_Info__c = '{\"Metmast\":\"\",\"Switchgear Substation\":\"2\"}';
        p1SiteMetaData.Attribute_Info__c = '{}';
        p1SiteMetaData.Account_Plant__c = plantAsset.Id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert p1SiteMetaData;

        Site_Metadata__c p7SiteMetaData = new Site_Metadata__c(); 
        p7SiteMetaData.Name = Constants.P7_INVERTER_SUBARRAY_INFO;
        p7SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Subarray Name\":\"SubArray01\"}';
        p7SiteMetaData.Attribute_Info__c = '{}';
        p7SiteMetaData.Account_Plant__c = plantAsset.Id;
        p7SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert p7SiteMetaData;
    
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        String dataTableInput = P9ATrackerControllerInfo.getCustomDatatableCompInput(plantAsset.Id, plantAssetPromptDetail, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset.Id);
       
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P9ATrackerControllerInfo.findNextPromptId(plantAsset.Id,siteMetadataRecords,isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
    }
}