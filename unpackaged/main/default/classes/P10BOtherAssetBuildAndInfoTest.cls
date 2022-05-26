/**
**/
@isTest
public with sharing class P10BOtherAssetBuildAndInfoTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Meter', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c p3BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PAD, newTemVersion.Id);
        insert p3BaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;
        
        Prompt_Information__c currentPromptInfo = TestDataFactory.createPromptInformation(Constants.P10B_OTHER_ASSET_BUILD_AND_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert currentPromptInfo;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;
        
        Prompt_Information__c parentPromptInfo = TestDataFactory.createPromptInformation(Constants.P10A_OTHER_ASSET_BUILD, null, newTemVersion.Id);
        insert parentPromptInfo;

        Prompt_Information__c newP3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS, p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert newP3PromptInfo;
        
        Prompt_Information__c nextPromptInfo = TestDataFactory.createPromptInformation(Constants.W1_PLANT_INFO_PROMPT_WIND,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        nextPromptInfo.Prompt_Id__c='prompt3';                                                                                      
        insert nextPromptInfo;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
            list<String>coreAttrNameLst = new list<String>{'Test1','Test2','Test3','Test4'};
                for(integer i = 0; i < 4; i++){
                    Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                    'Metadata',
                                                                                    'Text',
                                                                                    coreAttrRTId,
                                                                                    null,
                                                                                    newBaseAssetTemplate.Id, newTemVersion.Id);
                    coreAttrLst.add(coreAttr);
                }
        insert coreAttrLst;

        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptSpecificAttrNameLst = new list<String>{'Pad Name','Device Type','Device Name'};
       
            for(integer i = 0; i < 3; i++){
                Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                                'Prompt Specific',
                                                                                                'Text',
                                                                                                promptCoreAttrRTId,
                                                                                                null,
                                                                                                currentPromptInfo.Id, newTemVersion.Id);
                promptSpecificAttrLst.add(promptSpecificAttr);
            }
        insert promptSpecificAttrLst;
        
        List<String> parentPromptSpecificAttrName = new List<String>{'PLC','HVAC','Fused Switch'};
        list<String>datatypeLst = new list<String>{'Number','Number','Number'};
        for(integer i = 0; i < 3; i++){
            Core_Attribute__c parentPromptSpecificAttribute = TestDataFactory.createPromptSpecificAttr(parentPromptSpecificAttrName[i],
                                                                                                    'Metadata',
                                                                                                    datatypeLst[i],
                                                                                                    promptCoreAttrRTId,
                                                                                                    null,
                                                                                                    parentPromptInfo.Id, newTemVersion.Id);
            parentPromptSpecificAttribute.Sensor_Type__c = 'Substation switchgear';
            parentPromptSpecificAttribute.Base_Asset_Name__c = newBaseAssetTemplate.Id;
            insert  parentPromptSpecificAttribute;                                                          
        }

        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 2; i++){
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
        newG1SiteMetadata.Prompt_Specific_Info__c= '{"Metmast":"1","Switchgear Substation":"1","Renewable Type":"'+Constants.WIND+'"}';
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;

        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ newP3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = newP3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = p3BaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{\"Tracker Controller\":\"7",\"Tracker Motor\":\"7\",\"Transformers\":\"7\",\"Other Assets\":\"2\",\"Relay\":\"4\"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c= newPlantAsset.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        insert p3SiteMetaData;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ parentPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = parentPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;
    
        Site_Metadata__c p10ASiteMetadata = new Site_Metadata__c(); 
        p10ASiteMetadata.Name = Constants.P10A_OTHER_ASSET_BUILD;
        p10ASiteMetadata.Prompt_Specific_Info__c = '{\"Pad Name\":\"Pad Name1\",\"PLC\":\"2\",\"HVAC\":\"2\",\"Fused Switch\":\"2\"}';
        p10ASiteMetadata.Attribute_Info__c = '{\"Barometric\":\"1\",\"Dew Point\":\"7\"}';
        p10ASiteMetadata.Account_Plant__c= newPlantAsset.id;
        p10ASiteMetadata.Parent_Site_Metadata__c=p3SiteMetaData.id;
        p10ASiteMetadata.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p10ASiteMetadata;
    }

    public static testMethod void P10BOtherAssetBuildAndInfoTest(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id FROM Plant_Asset_Prompt_Detail__c WHERE Name = 'Test Plant-P.10.A Other Asset Build'].Id;
        String currentPromptName = Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        Boolean clearAttribute = false;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        //DataTable Output check
        String dataTableInput = P10BOtherAssetBuildAndInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(6, currentPromptSiteMetadata.size());
       

        //Save Site MeteData check
        String deviceAttrName = 'Device Name';
        String padAttrName = 'Pad Name';
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(deviceAttrName,'Device Name Test');
        promptSpecificInfoMap.put(padAttrName,'Pad Name1');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck =  P10BOtherAssetBuildAndInfo.saveSiteMetadataRecords(siteMetadataRecordSaveCheck,plantAsset,isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedDeviceName = promptSpecificInfoMapSaveCheck.containsKey(deviceAttrName)?promptSpecificInfoMapSaveCheck.get(deviceAttrName):'';
        System.assertEquals('Device Name Test',updatedDeviceName);
        
        //next PromptId check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        Test.startTest();
        String nextPromptResFinder = P10BOtherAssetBuildAndInfo.findNextPromptId(plantAsset,siteMetadataRecords,isKeyToGenerateRows,true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(Constants.W1_PLANT_INFO_PROMPT_WIND),nextPromptId);
    
        //clear Site MetaData Check
        String clearDataCheck = P10BOtherAssetBuildAndInfo.clearPromptInfo(plantAsset,plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearedStringNameCheck = promptSpecificInfoMapClearCheck.containsKey(deviceAttrName)?promptSpecificInfoMapClearCheck.get(deviceAttrName):'';
        System.assertEquals('Device Name Test',clearedStringNameCheck);
        Test.stopTest();
    }

    public static testmethod void windTest(){
        String nextPromptName = Constants.W1_PLANT_INFO_PROMPT_WIND;
        Boolean isKeyToGenerateRows = false;

        TEM_Version__c newTemVersion = [SELECT Id, Name FROM TEM_Version__c ];
   
        //update TemVersion status to Active
        newTemVersion.Status__c = Constants.DRAFT;
        update newTemVersion;
        
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;

        Id plantAssetPromptDetail = [SELECT Id FROM Plant_Asset_Prompt_Detail__c WHERE Name = 'Test Plant-P.10.A Other Asset Build'].Id;

        String currentPromptName = Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        Boolean clearAttribute = true;
        
        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        
        //DataTable Output check
        String dataTableInput = P10BOtherAssetBuildAndInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);

        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = P10BOtherAssetBuildAndInfo.findNextPromptId(plantAsset, siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(Constants.W1_PLANT_INFO_PROMPT_WIND), nextPromptId);
    }

    public static testMethod void P10BOtherAssetBuildAndInfoInsertionLogicCheck(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id FROM Plant_Asset_Prompt_Detail__c WHERE Name = 'Test Plant-P.10.A Other Asset Build'].Id;
        String currentPromptName = Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        Boolean clearAttribute = false;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        
        Site_Metadata__c p10ASiteMetadata = new Site_Metadata__c(); 
        p10ASiteMetadata.Name = Constants.P10A_OTHER_ASSET_BUILD;
        p10ASiteMetadata.Prompt_Specific_Info__c = '{\"Pad Name\":\"Pad Name2\",\"PLC\":\"2\",\"HVAC\":\"2\",\"Fused Switch\":\"2\"}';
        p10ASiteMetadata.Attribute_Info__c = '{\"Barometric\":\"1\",\"Dew Point\":\"7\"}';
        p10ASiteMetadata.Account_Plant__c= plantAsset;
        p10ASiteMetadata.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert p10ASiteMetadata;

        Id promptId = [SELECT Id FROM Prompt_Information__c WHERE Name =: Constants.P10B_OTHER_ASSET_BUILD_AND_INFO].Id; 
        Id batId = [SELECT Id FROM Base_Asset_Template__c WHERE Name = 'Base Meter'].Id;

        Plant_Asset_Prompt_Detail__c p10BPlantAssetPromptDetail1 = new Plant_Asset_Prompt_Detail__c();
        p10BPlantAssetPromptDetail1.Name = 'Plant Asset Name' +'-'+ Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        p10BPlantAssetPromptDetail1.Account_Plant__c = plantAsset;
        p10BPlantAssetPromptDetail1.Prompt_Information__c = promptId;
        p10BPlantAssetPromptDetail1.Base_Asset__c = batId;
        insert p10BPlantAssetPromptDetail1;

        Site_Metadata__c p10BSiteMetaData1 = new Site_Metadata__c(); 
        p10BSiteMetaData1.Name = Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        p10BSiteMetaData1.Prompt_Specific_Info__c = '{"Tracker Controller Name":"a1oQ0000001gQNkIAM","Tracker Motor Name":"M1","Pad Name":"a1oQ0000001gQNQIA2"}}';
        p10BSiteMetaData1.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p10BSiteMetaData1.Account_Plant__c = plantAsset;
        p10BSiteMetaData1.Plant_Asset_Prompt_Detail__c = p10BPlantAssetPromptDetail1.Id;
        insert p10BSiteMetaData1;

        //DataTable Output check
        String dataTableInput1 = P10BOtherAssetBuildAndInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata1 = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(13, currentPromptSiteMetadata1.size());
    }
}