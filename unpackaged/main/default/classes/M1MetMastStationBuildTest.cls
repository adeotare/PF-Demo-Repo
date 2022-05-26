/**
**/
@istest
public with sharing class M1MetMastStationBuildTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        
        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Recombiner', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.M1_MET_MAST_STATION_BUILD,newBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Type__c = Constants.MET_MAST;
        insert newPromptInfo;

        Prompt_Information__c newP9BPromptInfo = TestDataFactory.createPromptInformation(Constants.P9B_TRACKER_MOTOR_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP9BPromptInfo; 
        
        Prompt_Information__c newS1PromptInfo = TestDataFactory.createPromptInformation(Constants.S1_SUBSTATION_SWITCHGEAR_BUILD, newBaseAssetTemplate.Id, newTemVersion.Id);
        newS1PromptInfo.Prompt_Id__c='prompt3';
        insert newS1PromptInfo;    

        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
       
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number','Date','Number','Checkbox'};
        list<String>coreAttrNameLst = new list<String>{'AC Curtailment Limit','Date Commercial Operation','AC Capacity','DriveNO'};
        for(integer i = 0; i < 4; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newBaseAssetTemplate.Id, newTemVersion.Id);
            coreAttr.Plant_Asset_Field_Name__c = 'Name';
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;
        
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptDataTypeLst = new list<String>{'Text','Text','Text'};
        list<String>promptSpecificAttrNameLst = new list<String>{'Station Name','Plant ID','Drive Plus'};
        
        for(integer i = 0; i < 3; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                'Text',
                                                                                promptCoreAttrRTId,
                                                                                (promptDataTypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newPromptInfo.Id, newTemVersion.Id);
            promptSpecificAttr.Sensor_Type__c = 'Metmast';
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

        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"Metmast":"3", "Switchgear Substation":"4","PF Service Product":"Drive;FSM" }';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Account_Plant__c= newPlantAsset.id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ newP9BPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = newP9BPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c p9BSiteMetaData = new Site_Metadata__c(); 
        p9BSiteMetaData.Name = Constants.P9B_TRACKER_MOTOR_INFO;
        p9BSiteMetaData.Prompt_Specific_Info__c = '{"Tracker Controller Name":"a1oQ0000001gQNkIAM","Tracker Motor Name":"M1","Pad Name":"a1oQ0000001gQNQIA2"}}';
        p9BSiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p9BSiteMetaData.Account_Plant__c= newPlantAsset.id;
        p9BSiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p9BSiteMetaData;
    }

    public static testMethod void M1MetMastStationBuildTest(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.9.B Tracker Motor Info'].Id;
        String currentPromptName = Constants.M1_MET_MAST_STATION_BUILD;
        String nextPromptName = Constants.M2_METMAST_STATION_BUILD;
        Boolean isKeyToGenerateRows = false;
        map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        
        String dataTableInput = M1MetMastStationBuild.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(3,currentPromptSiteMetadata.size());        

        //Save SiteMetadata
        String promptSubstationAttrName = 'Station Name';

        map<String,String> promptSpecificInfoMap = (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(promptSubstationAttrName, 'Station Name 1');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);

        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = M1MetMastStationBuild.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedAttrName = promptSpecificInfoMapSaveCheck.containsKey(promptSubstationAttrName)?promptSpecificInfoMapSaveCheck.get(promptSubstationAttrName):'';
        System.assertEquals('Station Name 1',updatedAttrName); 
        
        //clear Site MetaData Check
        String clearDataCheck = M1MetMastStationBuild.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
           (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(promptSubstationAttrName);
        String clearedStationNameCheck = promptSpecificInfoMapClearCheck.containsKey(promptSubstationAttrName)?promptSpecificInfoMapClearCheck.get(promptSubstationAttrName):'';
        System.assertEquals(clearValue, clearedStationNameCheck); 

        //Next Prompt Navigation
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = M1MetMastStationBuild.findNextPromptId(plantAsset,siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(Constants.S1_SUBSTATION_SWITCHGEAR_BUILD), nextPromptId); 
    }      
}