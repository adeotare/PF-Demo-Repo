/**
**/
@isTest
public class W5ATurbineBuildSubsystemsTest {
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
        
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.W5A_TURBINE_BUILD_SUBSYSTEMS, meterBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Prompt_Id__c='prompt3';
        newPromptInfo.Type__c = Constants.WIND;
        insert newPromptInfo;
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
            promptSpecificAttr.Sensor_Type__c = promptSpecificAttrNameLst[i] == 'Alarm'?Constants.WEATHER_SENSOR:Constants.SUBSYSTEM;
            promptSpecificAttr.Base_Asset_Name__c=meterBaseAssetTemplate.Id;
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
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplateG1.Id;
        insert g1PlantAssetPromptDetail;

        Site_Metadata__c newG1SiteMetadata = TestDataFactory.createG1SiteMetadata(newPlantAsset.Id);
        newG1SiteMetadata.Prompt_Specific_Info__c = '{}';
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;
        
        Plant_Asset_Prompt_Detail__c w3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        w3PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+w3PromptInfo.Name;
        w3PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        w3PlantAssetPromptDetail.Prompt_Information__c = w3PromptInfo.Id;
        w3PlantAssetPromptDetail.Base_Asset__c = meterBaseAssetTemplate.Id;
        insert w3PlantAssetPromptDetail;

        Site_Metadata__c w3SiteMetaData = new Site_Metadata__c(); 
        w3SiteMetaData.Name = Constants.W3_TURBINE_BUILD;
        w3SiteMetaData.Prompt_Specific_Info__c = '{\"Meters\":\"1\",\"Alarm\":\"1\",\"Build Name\":\"V1\"}';
        w3SiteMetaData.Account_Plant__c= newPlantAsset.id;
        w3SiteMetaData.Prompt_Information__c = w3PromptInfo.Id;
        w3SiteMetaData.Plant_Asset_Prompt_Detail__c = w3PlantAssetPromptDetail.Id;
        insert w3SiteMetaData;
        
        Id m3SiteMetadata = [SELECT Id, Name FROM Site_Metadata__c WHERE Name =: Constants.W3_TURBINE_BUILD].Id;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+w4PromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = w4PromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = meterBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c w4SiteMetaData = new Site_Metadata__c(); 
        w4SiteMetaData.Name = Constants.W4_TURBINE_BUILD_AND_INFO;
        w4SiteMetaData.Prompt_Specific_Info__c = '{"Turbine Name":"A-01","Turbine Build":"'+m3SiteMetadata +'"}';
        w4SiteMetaData.Account_Plant__c= newPlantAsset.id;
        w4SiteMetaData.Plant_Asset_Prompt_Detail__c = w3plantAssetPromptDetail.id;
        w4SiteMetaData.Parent_Site_Metadata__c=w3SiteMetaData.id;
        w4SiteMetaData.Prompt_Information__c = w4PromptInfo.Id;
        w4SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert w4SiteMetaData;
    }

    public static testMethod void w5ATurbineBuildTest(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        Id m3SiteMetadata = [SELECT Id, Name FROM Site_Metadata__c WHERE Name =: Constants.W3_TURBINE_BUILD].Id;
        Id plantAssetPromptDetail = [SELECT Id, Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-W.4.0 Turbine Build And Info'].Id;
        String previousPromptName = Constants.W4_TURBINE_BUILD_AND_INFO;
        String currentPromptName = Constants.W5A_TURBINE_BUILD_SUBSYSTEMS;
        Boolean clearAttribute = false;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        
        Prompt_Information__c promptInfo  = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.W3_TURBINE_BUILD];
        Prompt_Information__c w4promptInfo  = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.W4_TURBINE_BUILD_AND_INFO];

        //DataTable Output check
        String dataTableInput = W5ATurbineBuildSubsystems.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(1, currentPromptSiteMetadata.size());
        
        Plant_Asset_Prompt_Detail__c w3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        w3PlantAssetPromptDetail.Name = 'Test Plant' +'-'+promptInfo.Name;
        w3PlantAssetPromptDetail.Account_Plant__c = plantAsset;
        w3PlantAssetPromptDetail.Prompt_Information__c = promptInfo.Id;
        insert w3PlantAssetPromptDetail;
        
        Site_Metadata__c w3SiteMetaData = new Site_Metadata__c(); 
        w3SiteMetaData.Name = Constants.W3_TURBINE_BUILD;
        w3SiteMetaData.Prompt_Specific_Info__c = '{\"Meters\":\"1\",\"Alarm\":\"1\",\"Build Name\":\"V1\"}';
        w3SiteMetaData.Account_Plant__c= plantAsset;
        w3SiteMetaData.Prompt_Information__c = promptInfo.Id;
        w3SiteMetaData.Plant_Asset_Prompt_Detail__c = w3PlantAssetPromptDetail.Id;
        insert w3SiteMetaData; 
        
        Id m3SiteMetadata1 = [SELECT Id, Name FROM Site_Metadata__c WHERE Name =: Constants.W3_TURBINE_BUILD LIMIT 1].Id;

        Plant_Asset_Prompt_Detail__c w4PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        w4PlantAssetPromptDetail.Name = 'Test Plant' +'-'+w4promptInfo.Name;
        w4PlantAssetPromptDetail.Account_Plant__c = plantAsset;
        w4PlantAssetPromptDetail.Prompt_Information__c = w4promptInfo.Id;
        insert w4PlantAssetPromptDetail;

        Site_Metadata__c w4SiteMetaData = new Site_Metadata__c(); 
        w4SiteMetaData.Name = Constants.W4_TURBINE_BUILD_AND_INFO;
        w4SiteMetaData.Prompt_Specific_Info__c = '{"Turbine Name":"A-01","Turbine Build":"'+m3SiteMetadata +'"}';
        w4SiteMetaData.Account_Plant__c = plantAsset;
        w4SiteMetaData.Plant_Asset_Prompt_Detail__c = w3plantAssetPromptDetail.id;
        w4SiteMetaData.Parent_Site_Metadata__c = w3SiteMetaData.id;
        w4SiteMetaData.Prompt_Information__c = w4promptInfo.Id;
        w4SiteMetaData.Plant_Asset_Prompt_Detail__c = w4PlantAssetPromptDetail.Id;
        insert w4SiteMetaData; 
        
        Test.startTest();
        String w5ADataTableInput = W5ATurbineBuildSubsystems.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> w5APromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(3, w5APromptSiteMetadata.size());     
		
        //Save Site MeteData check
        String deviceAttrName = Constants.DEVICE_NAME;
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        promptSpecificInfoMap.put(deviceAttrName,'Device Name Test');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck =  W5ATurbineBuildSubsystems.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String updatedDeviceName = promptSpecificInfoMapSaveCheck.containsKey(deviceAttrName)?promptSpecificInfoMapSaveCheck.get(deviceAttrName):'';
        System.assertEquals('Device Name Test', updatedDeviceName);

        //next PromptId check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = W5ATurbineBuildSubsystems.findNextPromptId(plantAsset,siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals('finish',nextPromptId);
        Test.stopTest();
    
    }
    public static testMethod void w5ATurbineBuildClearTest(){
    	String previousPromptName = Constants.W4_TURBINE_BUILD_AND_INFO;
        String currentPromptName = Constants.W5A_TURBINE_BUILD_SUBSYSTEMS;
        Boolean clearAttribute = false;
        String deviceAttrName = Constants.DEVICE_NAME;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};

        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id, Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-W.4.0 Turbine Build And Info'].Id;
    	String dataTableInput = W5ATurbineBuildSubsystems.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        String clearDataCheck = W5ATurbineBuildSubsystems.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearedStringNameCheck = promptSpecificInfoMapClearCheck.containsKey(deviceAttrName)?promptSpecificInfoMapClearCheck.get(deviceAttrName):'';
        System.assertEquals('A-01-Meters 01',clearedStringNameCheck);
    }
}