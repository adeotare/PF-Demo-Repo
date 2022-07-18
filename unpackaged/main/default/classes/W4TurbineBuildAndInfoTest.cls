/**
**/
@isTest
public class W4TurbineBuildAndInfoTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;
//        newPlantAsset.Renewable_Type__c = Constants.SOLAR;
        
        update newPlantAsset;
                
        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER_PAD, newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c p1BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert p1BaseAssetTemplate;

        Base_Asset_Template__c p2BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_BLOCK, newTemVersion.Id);
        insert p2BaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;
        
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.W4_TURBINE_BUILD_AND_INFO,
                                                                                      newBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Type__c = Constants.WIND;
        insert newPromptInfo;
        Prompt_Information__c w3PromptInfo = TestDataFactory.createPromptInformation(Constants.W3_TURBINE_BUILD,
                                                                                     p1BaseAssetTemplate.Id, newTemVersion.Id);
        //w3PromptInfo.Wind_Prompt_Attribute_Type__c =Constants.SUBSYSTEM;                                                                            
        insert w3PromptInfo;
        Prompt_Information__c w2PromptInfo = TestDataFactory.createPromptInformation(Constants.W2_STRING_BUILD_INFO,
                                                                                     p2BaseAssetTemplate.Id, newTemVersion.Id);
        insert w2PromptInfo;
        
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();
        
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
        
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptSpecificAttrNameLst = new list<String>{'Build Count','String Name','Wind Turbine Counts','SubSystem'};
            
        for(integer i = 0; i < 4; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                            'Prompt Specific',
                                                                                            'Text',
                                                                                            promptCoreAttrRTId,
                                                                                            (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                            w3PromptInfo.Id, newTemVersion.Id);
            promptSpecificAttr.Sensor_Type__c = i<2?Constants.WEATHER_SENSOR:Constants.SUBSYSTEM;                                                                              
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
        newG1SiteMetadata.Prompt_Specific_Info__c='{}';
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;
           
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+w3PromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = w3PromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = p1BaseAssetTemplate.Id;
        insert plantAssetPromptDetail;
        
        Site_Metadata__c w3SiteMetaData = new Site_Metadata__c(); 
        w3SiteMetaData.Name = Constants.W3_TURBINE_BUILD;
        w3SiteMetaData.Prompt_Specific_Info__c = '{"Build Name":"pick1","SubSystem":"6","Wind Turbine Counts":"6","Build Count":"6"}}';
        w3SiteMetaData.Attribute_Info__c = '{"test1":"test2"}';
        w3SiteMetaData.Base_Asset_Template__c = p1BaseAssetTemplate.Id;
        w3SiteMetaData.Prompt_Information__c = w3PromptInfo.Id;
        w3SiteMetaData.Account_Plant__c = newPlantAsset.id;
        w3SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert w3SiteMetaData;

        Plant_Asset_Prompt_Detail__c w2PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        w2PlantAssetPromptDetail.Name = 'Test Plant' +'-'+w2PromptInfo.Name;
        w2PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        w2PlantAssetPromptDetail.Prompt_Information__c = w2PromptInfo.Id;
        w2PlantAssetPromptDetail.Base_Asset__c = p1BaseAssetTemplate.Id;
        insert w2PlantAssetPromptDetail;
        
        Site_Metadata__c w2SiteMetaData = new Site_Metadata__c(); 
        w2SiteMetaData.Name = Constants.W2_STRING_BUILD_INFO;
        w2SiteMetaData.Prompt_Specific_Info__c = '{"Wind Turbine Counts": "6","String Name": "String1"}';
        w2SiteMetaData.Attribute_Info__c = '{"Test":"Test"}';
        w2SiteMetaData.Base_Asset_Template__c = p1BaseAssetTemplate.Id;
        w2SiteMetaData.Plant_Asset_Prompt_Detail__c=plantAssetPromptDetail.id;
        w2SiteMetaData.Account_Plant__c= newPlantAsset.id;
        w2SiteMetaData.Prompt_Information__c = w2PromptInfo.id;
        w2SiteMetaData.Plant_Asset_Prompt_Detail__c = w2PlantAssetPromptDetail.Id;
        insert w2SiteMetaData;
    }
    public static testMethod void w4GetCustomDatatableCompInputAndSaveTest(){
        //query Plant Asset
        String currentPromptName = Constants.W4_TURBINE_BUILD_AND_INFO;
        Id  plantAsset = [SELECT Id, Name FROM Account_Plant__c where Drive_Id__c  = '7777.77.777' ].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-W.3.0 Turbine Build'].Id;
        Id newBaseAssetTemplate = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_INVERTER_PAD].Id;
        Boolean clearAttribute = false;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};        
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        Test.startTest();
        //DataTable Output check
        String dataTableInput = W4TurbineBuildAndInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(6, currentPromptSiteMetadata.size());
		
        //Save Site MeteData check
        String deviceAttrName = Constants.DEVICE_NAME;
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(deviceAttrName,'Device Name Test');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck =  W4TurbineBuildAndInfo.saveSiteMetadataRecords(siteMetadataRecordSaveCheck,plantAsset,isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedDeviceName = promptSpecificInfoMapSaveCheck.containsKey(deviceAttrName)?promptSpecificInfoMapSaveCheck.get(deviceAttrName):'';
        System.assertEquals('Device Name Test',updatedDeviceName);

        //next PromptId check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = W4TurbineBuildAndInfo.findNextPromptId(plantAsset, siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals('finish',nextPromptId);
    
        //clear Site MetaData Check
        String clearDataCheck = W4TurbineBuildAndInfo.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearedStringNameCheck = promptSpecificInfoMapClearCheck.containsKey(deviceAttrName)?promptSpecificInfoMapClearCheck.get(deviceAttrName):'';
        System.assertEquals('Device Name Test',clearedStringNameCheck);
        Test.stopTest();
    } 
 }