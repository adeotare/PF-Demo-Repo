/**
**/
@isTest
public with sharing class W5BTurbineBuildSubsystemsTest {
 @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c meterBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_METER, newTemVersion.Id);
        insert meterBaseAssetTemplate;
        Base_Asset_Template__c alarmBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_ALARM, newTemVersion.Id);
        insert alarmBaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;
    
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.W5B_TURBINE_BUILD_PROMPT_WIND_SPEED, meterBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Prompt_Id__c='prompt4';
        newPromptInfo.Type__c = Constants.WIND;
        insert newPromptInfo;
        Prompt_Information__c w5APromptInfo = TestDataFactory.createPromptInformation(Constants.W5A_TURBINE_BUILD_SUBSYSTEMS, meterBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Prompt_Id__c='prompt3';
        insert w5APromptInfo;
        Prompt_Information__c w4PromptInfo = TestDataFactory.createPromptInformation(Constants.W4_TURBINE_BUILD_AND_INFO, meterBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Prompt_Id__c='prompt2';
        insert w4PromptInfo;
        Prompt_Information__c w3PromptInfo = TestDataFactory.createPromptInformation(Constants.W3_TURBINE_BUILD, meterBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Prompt_Id__c='prompt1';
        insert w3PromptInfo;

        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();

        list<String>coreDatatypeLst = new list<String>{'Number','Text','Text','Number'};
        list<String>coreAttrNameLst = new list<String>{'Serial Number','Tracker','Manufacturer','AC Capacity'};
        for(integer i = 0; i < 4; i++){
            Core_Attribute__c coreAttrAlarm = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                coreDatatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (coreDatatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                meterBaseAssetTemplate.Id, newTemVersion.Id);
            coreAttrLst.add(coreAttrAlarm);
        }
        insert coreAttrLst;

        list<String>promptSpecificAttrNameLst = new list<String>{'Turbine Build','Turbine Name','Meters','Device type','Device Name','Alarm'};
        list<String>datatypeLst = new list<String>{'Text','Text','Number','Text','Number','Number'};
        for(integer i = 0; i < 6; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                datatypeLst[i],
                                                                                promptCoreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                (i< 4)? w3PromptInfo.Id : newPromptInfo.Id, newTemVersion.Id);
            promptSpecificAttr.Sensor_Type__c = promptSpecificAttrNameLst[i] == Constants.DEVICE_TYPE?Constants.SUBSYSTEM:Constants.WEATHER_SENSOR;
            promptSpecificAttr.Base_Asset_Name__c = meterBaseAssetTemplate.Id;
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
        newG1SiteMetadata.Prompt_Specific_Info__c = '{}';
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;
        
        Plant_Asset_Prompt_Detail__c w3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        w3PlantAssetPromptDetail.Name = 'Test Plant' +'-'+w3PromptInfo.Name;
        w3PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        w3PlantAssetPromptDetail.Prompt_Information__c = w3PromptInfo.Id;
        w3PlantAssetPromptDetail.Base_Asset__c = meterBaseAssetTemplate.Id;
        insert w3PlantAssetPromptDetail;

        Site_Metadata__c w3SiteMetaData = new Site_Metadata__c(); 
        w3SiteMetaData.Name = Constants.W3_TURBINE_BUILD;
        w3SiteMetaData.Prompt_Specific_Info__c = '{\"Build Name\":\"Vestas\",\"Meters\":\"1\",\"Alarm\":\"1\"}';
        w3SiteMetaData.Account_Plant__c= newPlantAsset.id;
        w3SiteMetaData.Prompt_Information__c = w3PromptInfo.Id;
        w3SiteMetaData.Plant_Asset_Prompt_Detail__c = w3PlantAssetPromptDetail.Id;
        insert w3SiteMetaData;
        
        Id m3SiteMetadata = [SELECT Id, Name FROM Site_Metadata__c WHERE Name =: Constants.W3_TURBINE_BUILD].Id;
        
        Plant_Asset_Prompt_Detail__c w4PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        w4PlantAssetPromptDetail.Name = 'Test Plant' +'-'+w4PromptInfo.Name;
        w4PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        w4PlantAssetPromptDetail.Prompt_Information__c = w4PromptInfo.Id;
        w4PlantAssetPromptDetail.Base_Asset__c = meterBaseAssetTemplate.Id;
        insert w4PlantAssetPromptDetail;

        Site_Metadata__c w4SiteMetaData = new Site_Metadata__c(); 
        w4SiteMetaData.Name = Constants.W4_TURBINE_BUILD_AND_INFO;
        w4SiteMetaData.Prompt_Specific_Info__c = '{"Turbine Name":"A-01","Turbine Build":"'+m3SiteMetadata +'"}';
        w4SiteMetaData.Account_Plant__c= newPlantAsset.id;
        w4SiteMetaData.Plant_Asset_Prompt_Detail__c=w3plantAssetPromptDetail.id;
        w4SiteMetaData.Prompt_Information__c = w4PromptInfo.Id;
        w4SiteMetaData.Plant_Asset_Prompt_Detail__c = w4PlantAssetPromptDetail.Id;
        insert w4SiteMetaData;
        
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+w5APromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = w5APromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = meterBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;
    }

    public static testMethod void w5BTurbineBuildTest(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-W.5.A Turbine Build Subsystems'].Id;
        Id w4PlantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-W.4.0 Turbine Build And Info'].Id;
        String previousPromptName = Constants.W4_TURBINE_BUILD_AND_INFO;
        String currentPromptName = Constants.W5B_TURBINE_BUILD_PROMPT_WIND_SPEED;
        Boolean clearAttribute = false;
        Boolean isKeyToGenerateRows = false;
        Boolean attrValueChanged = true;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        Prompt_Information__c promptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.W3_TURBINE_BUILD];
        Prompt_Information__c w4promptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.W4_TURBINE_BUILD_AND_INFO];

        String dataTableInput = W5BTurbineBuildSubsystems.getCustomDatatableCompInput(plantAsset,plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(1, currentPromptSiteMetadata.size());
        
        Id m3SiteMetadata = [SELECT Id, Name FROM Site_Metadata__c WHERE Name =: Constants.W3_TURBINE_BUILD LIMIT 1].Id;
        
        Site_Metadata__c w4SiteMetaData = new Site_Metadata__c(); 
        w4SiteMetaData.Name = Constants.W4_TURBINE_BUILD_AND_INFO;
        w4SiteMetaData.Prompt_Specific_Info__c = '{"Turbine Name":"A-01","Turbine Build":"'+m3SiteMetadata +'"}';
        w4SiteMetaData.Account_Plant__c = plantAsset;
        w4SiteMetaData.Plant_Asset_Prompt_Detail__c=w4PlantAssetPromptDetail;
        w4SiteMetaData.Prompt_Information__c = w4promptInfo.Id;
        insert w4SiteMetaData; 
        
        String w5BdataTableInput = W5BTurbineBuildSubsystems.getCustomDatatableCompInput(plantAsset,plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> w5BPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(3, w5BPromptSiteMetadata.size());
        
         //Save Site MeteData check
        String deviceAttrName = Constants.DEVICE_NAME;
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        promptSpecificInfoMap.put(deviceAttrName,'Device Name Test');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck =  W5BTurbineBuildSubsystems.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c>
        savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String updatedDeviceName = promptSpecificInfoMapSaveCheck.containsKey(deviceAttrName)?promptSpecificInfoMapSaveCheck.get(deviceAttrName):'';
        System.assertEquals('Device Name Test', updatedDeviceName);
    
        //next PromptId check
        Test.startTest();
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = W5BTurbineBuildSubsystems.findNextPromptId(plantAsset, siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals('finish', nextPromptId);    
        Test.stopTest(); 
    }
    public static testMethod void w5BTurbineBuildClearTest(){
    	String previousPromptName = Constants.W4_TURBINE_BUILD_AND_INFO;
        String currentPromptName = Constants.W5B_TURBINE_BUILD_PROMPT_WIND_SPEED;
        Boolean clearAttribute = false;
        String deviceAttrName = Constants.DEVICE_NAME;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};

        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-W.5.A Turbine Build Subsystems'].Id;
    	String dataTableInput = W5BTurbineBuildSubsystems.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        String clearDataCheck = W5BTurbineBuildSubsystems.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearedStringNameCheck = promptSpecificInfoMapClearCheck.containsKey(deviceAttrName)?promptSpecificInfoMapClearCheck.get(deviceAttrName):'';
        System.assertEquals('A-01-Meters 01',clearedStringNameCheck);
    }
}