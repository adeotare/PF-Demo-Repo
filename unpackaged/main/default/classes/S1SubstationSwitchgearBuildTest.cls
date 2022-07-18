/**
**/
@istest
Public with sharing class S1SubstationSwitchgearBuildTest{
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Tracker', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.S1_SUBSTATION_SWITCHGEAR_BUILD,newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;

        Prompt_Information__c newP9BPromptInfo = TestDataFactory.createPromptInformation(Constants.P9B_TRACKER_MOTOR_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP9BPromptInfo;


        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Substation or Switchgear?', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;

        Picklist_Detail__c picklistDetailValue1= TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue1;

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
            coreAttr.Plant_Asset_Field_Name__c = 'Name';                                                                    
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;

        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptSpecificAttrNameLst = new list<String>{'Substation or Switchgear?', 'SUB/SWG Name', 'Switch'};
        list<String>promptdatatypeLst = new list<String>{'Picklist', 'Text', 'Text'};
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                promptdatatypeLst[i],
                                                                                promptCoreAttrRTId,
                                                                                (promptdatatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
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
        g1PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplateG1.Id;
        insert g1PlantAssetPromptDetail;

        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"Metmast":"2", "Switchgear Substation":"4","PF Service Product":"Drive;FSM" }';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Prompt_Information__c = g1PromptInfo.Id;
        g1SiteMetaData.Account_Plant__c= newPlantAsset.id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+ newP9BPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = newP9BPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c p9BSiteMetaData = new Site_Metadata__c(); 
        p9BSiteMetaData.Name = Constants.P9B_TRACKER_MOTOR_INFO;
        p9BSiteMetaData.Prompt_Specific_Info__c = '{"Tracker Controller Name":"a1oQ0000001gQNkIAM","Tracker Motor Name":"M1","Pad Name":"a1oQ0000001gQNQIA2"}}';
        p9BSiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p9BSiteMetaData.Account_Plant__c= newPlantAsset.id;
        p9BSiteMetaData.Prompt_Information__c = newP9BPromptInfo.Id;
        p9BSiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p9BSiteMetaData;
    }

    public static testMethod void S1SubstationSwitchgearBuildTest(){
         //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;

        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.9.B Tracker Motor Info'].Id;

        String currentPromptName = Constants.S1_SUBSTATION_SWITCHGEAR_BUILD;
        String nextPromptName = Constants.S2_SUBSTATION_SWITCHGEAR_BUILD_INFO;
        Boolean isKeyToGenerateRows = false;
        Boolean attrValueChanged = true;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};        
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
    
        String dataTableInput = S1SubstationSwitchgearBuild.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(4, currentPromptSiteMetadata.size());

        //Save Site MeteData check
        String promptSubstationAttrName = 'Substation or Switchgear';
        String promptSubSwgName ='SUB/SWG Name';

        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(promptSubstationAttrName, 'Yes');
        promptSpecificInfoMap.put(promptSubSwgName, 'Test1');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = S1SubstationSwitchgearBuild.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, attrValueChanged, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedAttrName = promptSpecificInfoMapSaveCheck.containsKey(promptSubSwgName)?promptSpecificInfoMapSaveCheck.get(promptSubSwgName):'';
        System.assertEquals('Test1',updatedAttrName);    

        //clear Site MetaData Check
        String clearDataCheck = S1SubstationSwitchgearBuild.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
             (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(promptSubSwgName);
        String clearedPromptSpecificInfoCheck = promptSpecificInfoMapClearCheck.containsKey(promptSubSwgName)?promptSpecificInfoMapClearCheck.get(promptSubSwgName):'';
        System.assertEquals(clearValue,clearedPromptSpecificInfoCheck); 

        //next PromptId check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = S1SubstationSwitchgearBuild.findNextPromptId(siteMetadataRecords, plantAsset, isKeyToGenerateRows, true,  additionalParamsForFindNextPrompt, false);
        System.assertEquals('calling Next Batch', nextPromptResFinder);       
    }
}