/**
**/
@istest
public with sharing class P10AOtherAssetBuildTest { 
    @TestSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Tracker', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c p3BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PAD, newTemVersion.Id);
        insert p3BaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P10A_OTHER_ASSET_BUILD, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;

        Prompt_Information__c newP9BPromptInfo = TestDataFactory.createPromptInformation(Constants.P9B_TRACKER_MOTOR_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP9BPromptInfo;

        Prompt_Information__c newP3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS, p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert newP3PromptInfo;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c', 'Prompt_Specific_Attribute').getRecordTypeId();

        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Text', 'Number', 'Number', 'Text'};
        list<String>coreAttrNameLst = new list<String>{'Manufacturer', 'AC Capacity', 'Tracker', 'Serial Number'};
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
        list<String>promptSpecificAttrNameLst = new list<String>{'Pad Name', 'Sensor', 'PLC', 'asset'};
        
        for(integer i = 0; i < 4; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                datatypeLst[i],
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

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+ newP9BPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = newP9BPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ newP3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = newP3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = p3BaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{"Transformers":"1","Tracker Motor":"1","Tracker Controller":"2","Relay":"","Pad Name":"J","Other Assets":"Yes","Meter":"","Inverter":"2","Block Name":"B1"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        insert p3SiteMetaData;

        Site_Metadata__c p9BSiteMetaData = new Site_Metadata__c(); 
        p9BSiteMetaData.Name = Constants.P9B_TRACKER_MOTOR_INFO;
        p9BSiteMetaData.Prompt_Specific_Info__c = '{"Tracker Controller Name":"a1oQ0000001gQNkIAM","Tracker Motor Name":"M1","Pad Name":"a1oQ0000001gQNQIA2"}}';
        p9BSiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p9BSiteMetaData.Account_Plant__c= newPlantAsset.id;
        p9BSiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p9BSiteMetaData;
    }

    public static testMethod void P10AOtherAssetBuildTest(){
        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.9.B Tracker Motor Info'].Id;
        String nextPromptName = Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        String currentPromptName = Constants.P10A_OTHER_ASSET_BUILD;
        Boolean isKeyToGenerateRows = false;
        map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};

        String dataTableInput = P10AOtherAssetBuild.getCustomDatatableCompInput(plantAssetPromptDetail, plantAsset,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(1, currentPromptSiteMetadata.size());

        //Save Site MeteData check
        String assetInfo ='PLC';
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(assetInfo,'1');     
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = P10AOtherAssetBuild.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedAttrName = promptSpecificInfoMapSaveCheck.containsKey(assetInfo)?promptSpecificInfoMapSaveCheck.get(assetInfo):'';
        System.assertEquals('1',updatedAttrName);

        //clear Site MetaData Check
        String clearDataCheck = P10AOtherAssetBuild.clearPromptInfo(plantAssetPromptDetail, plantAsset);
        String keyValue ='PLC';
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(keyValue);    
        String clearedPromptSpecificInfoCheck = promptSpecificInfoMapClearCheck.containsKey(keyValue)?promptSpecificInfoMapClearCheck.get(keyValue):'';
        System.assertEquals(clearValue,clearedPromptSpecificInfoCheck );
    }

    public static testMethod void P10AOtherAssetBuildTestInsertionLogicCheck(){
        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.9.B Tracker Motor Info'].Id;
        Id p3PlantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.3.0 Pad Builds and Counts'].Id;
        String nextPromptName = Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        String currentPromptName = Constants.P10A_OTHER_ASSET_BUILD;
        Boolean isKeyToGenerateRows = false;
        map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{"Transformers":"1","Tracker Motor":"1","Tracker Controller":"2","Relay":"","Pad Name":"J","Other Assets":"Yes","Meter":"","Inverter":"2","Block Name":"B1"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c= plantAsset;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail;
        insert p3SiteMetaData;
        String dataTableInput1 = P10AOtherAssetBuild.getCustomDatatableCompInput(plantAssetPromptDetail, plantAsset,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata1 = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(2, currentPromptSiteMetadata1.size());

        String siteMetadataStr = JSON.serialize(currentPromptSiteMetadata1);
        Map<String, String> strAdditionalParams = new Map<String, String>();
        P10AOtherAssetBuild.findNextPromptId(siteMetadataStr, plantAsset, false, false, JSON.serialize(strAdditionalParams), true);
    }

    public static testMethod void ExistingSiteMetadata(){
        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.9.B Tracker Motor Info'].Id;
        Id p3PlantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.3.0 Pad Builds and Counts'].Id;
        String nextPromptName = Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        String currentPromptName = Constants.P10A_OTHER_ASSET_BUILD;
        Boolean isKeyToGenerateRows = false;
        map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{"Transformers":"1","Tracker Motor":"1","Tracker Controller":"2","Relay":"","Pad Name":"J","Other Assets":"Yes","Meter":"","Inverter":"2","Block Name":"B1"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c= plantAsset;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail;
        insert p3SiteMetaData;

        Id promptId = [SELECT Id FROM Prompt_Information__c WHERE Name =: Constants.P10A_OTHER_ASSET_BUILD].Id; 
        Id batId = [SELECT Id FROM Base_Asset_Template__c WHERE Name = 'Base Tracker'].Id;

        Plant_Asset_Prompt_Detail__c p10APlantAssetPromptDetail1 = new Plant_Asset_Prompt_Detail__c();
        p10APlantAssetPromptDetail1.Name = 'Plant Asset Name' +'-'+ Constants.P10A_OTHER_ASSET_BUILD;
        p10APlantAssetPromptDetail1.Account_Plant__c = plantAsset;
        p10APlantAssetPromptDetail1.Prompt_Information__c = promptId;
        p10APlantAssetPromptDetail1.Base_Asset__c = batId;
        insert p10APlantAssetPromptDetail1;

        Site_Metadata__c p10ASiteMetaData = new Site_Metadata__c(); 
        p10ASiteMetaData.Name = Constants.P10A_OTHER_ASSET_BUILD;
        p10ASiteMetaData.Prompt_Specific_Info__c = '{"Tracker Controller Name":"a1oQ0000001gQNkIAM","Tracker Motor Name":"M1","Pad Name":"a1oQ0000001gQNQIA2"}}';
        p10ASiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p10ASiteMetaData.Account_Plant__c = plantAsset;
        p10ASiteMetaData.Plant_Asset_Prompt_Detail__c = p10APlantAssetPromptDetail1.Id;
        insert p10ASiteMetaData;

        String dataTableInput1 = P10AOtherAssetBuild.getCustomDatatableCompInput(plantAssetPromptDetail, plantAsset,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata1 = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(3, currentPromptSiteMetadata1.size());

        String siteMetadataStr = JSON.serialize(currentPromptSiteMetadata1);
        Map<String, String> strAdditionalParams = new Map<String, String>();
        P10AOtherAssetBuild.findNextPromptId(siteMetadataStr, plantAsset, false, false, JSON.serialize(strAdditionalParams), true);
    }
}