/**
**/
@istest
public with sharing class P1PlantInfoPromptSolarTest {
    @testSetup
    public static void testDataSetup() {
        
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.777',newTemVersion.Id);
        //newPlantAsset.PF_Service_Product__c = Constants.DRIVE_PLUS;
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert newBaseAssetTemplate;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Type__c = Constants.SOLAR; 
        insert newPromptInfo;

        Prompt_Information__c previousPromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert previousPromptInfo;
        Prompt_Information__c nextPromptInfo = TestDataFactory.createPromptInformation(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS,
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
        list<String>datatypeLst = new list<String>{'Number','Date','Number','Checkbox'};
        list<String>coreAttrNameLst = new list<String>{'AC Curtailment Limit','Date Commercial Operation','AC Capacity','DriveNO'};
        Attribute_Master__c attributeMaster = new Attribute_Master__c();
        attributeMaster.Name = 'attrMaster';
        attributeMaster.Type__c = 'Metadata';
        attributeMaster.TEM_Version__c = newTemVersion.Id;
        attributeMaster.Alias__c = 'AC Capacity';
        insert attributeMaster;

        for(integer i = 0; i < 4; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newBaseAssetTemplate.Id, newTemVersion.Id);
            //coreAttr.Attribute_Master__c = attributeMaster.id; 
           // coreAttr.Plant_Asset_Field_Name__c = 'PF_Service_Product__c';                            
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;
        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 4; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive','Yes',coreAttrLst[i].Id, newTemVersion.Id) ;
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptDataTypeLst = new list<String>{'Text','Text','Picklist'};
        list<String>promptSpecificAttrNameLst = new list<String>{'Plant Name','Plant ID','Flat Hierarchy'};
        
        Attribute_Master__c attributeMasterPrompt = new Attribute_Master__c();
        attributeMasterPrompt.Name = Constants.DRIVE_PLUS;
        attributeMasterPrompt.Type__c = 'Prompt Specific';
        attributeMasterPrompt.TEM_Version__c = newTemVersion.Id;
        attributeMasterPrompt.Alias__c = 'AC Capacity';
        insert attributeMasterPrompt;

        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                'Text',
                                                                                promptCoreAttrRTId,
                                                                                (promptDataTypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newPromptInfo.Id, newTemVersion.Id);
                                                                                
            promptSpecificAttr.Attribute_Master__c=attributeMasterPrompt.id;
            promptSpecificAttr.Plant_Asset_Field_Name__c = 'PF_Service_Product__c'; 
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst;

        List<Attribute_Requirement__c> attrReqLst1  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 1; i++){
            Attribute_Requirement__c attrReq1 = TestDataFactory.createAttributeRequirement('Drive','No',promptSpecificAttrLst[i].Id, newTemVersion.Id);
            attrReqLst1.add(attrReq1);
        }
        insert attrReqLst1;
        
        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;
        
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+previousPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"Switchgear Substation":"3","Metmast":"2","PF Service Product":"Drive;FSM"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Base_Asset_Template__c = newBaseAssetTemplate.Id;
        g1SiteMetaData.Account_Plant__c = newPlantAsset.id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert g1SiteMetaData;
    }

    public static testMethod void p1PlantInfoTest(){
        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        Account_Plant__c  plantAsset1 = [SELECT Id, Name,TEM_Version__r.Status__c  FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'];
        Id plantAssetPromptDetail = [SELECT Id, Name From Plant_Asset_Prompt_Detail__c WHERE Name = 'Test Plant-G.1.0 Plant Info and Renewable Type Prompt'].Id;
        String currentPromptName = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        String previousPromptName = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};   
        map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);


        //Calling P1 getCustomDatatableCompInput
        String dataTableInput = P1PlantInfoPromptSolar.getCustomDatatableCompInput(plantAsset,plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(1, currentPromptSiteMetadata.size());
        
        //Save Site MeteData check
        String plantAttrName = Constants.PLANT_NAME;
        Boolean isKeyToGenerateRows = false;
        String flatHierarchyAttrValue = Constants.FLAT_HIERARCHY;
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(plantAttrName,'Plant Name Test');
        promptSpecificInfoMap.put(flatHierarchyAttrValue,'Yes');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = P1PlantInfoPromptSolar.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String updatedMeterName = promptSpecificInfoMapSaveCheck.containsKey(plantAttrName)?promptSpecificInfoMapSaveCheck.get(plantAttrName):'';
        System.assertEquals('Plant Name Test', updatedMeterName );
         
        //next PromptId p3 check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = P1PlantInfoPromptSolar.findNextPromptId(siteMetadataRecords, plantAsset, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        map<String,String> promptSpecificInfoMapNextP3 = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMapNextP3.put(flatHierarchyAttrValue,'Yes');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMapNextP3);
        String p3PromptNextCheck = JSON.serialize(currentPromptSiteMetadata);
        String p3PromptResFinder = P1PlantInfoPromptSolar.findNextPromptId(p3PromptNextCheck, plantAsset, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponsep3 = 
            (Map<String,String>) JSON.deserialize(p3PromptResFinder, Map<String,String>.class);
        String nextPromptIdP3 = (String)nextPromptResponsep3.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(Constants.P3_PAD_BUILDS_AND_COUNTS), nextPromptIdP3);
        
        //next PromptId p2 check
        map<String,String> promptSpecificInfoMapNextP2 = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        promptSpecificInfoMapNextP2.put(flatHierarchyAttrValue,'');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMapNextP2);
        String p2PromptNextCheck = JSON.serialize(currentPromptSiteMetadata);
        String p2PromptResFinder = P1PlantInfoPromptSolar.findNextPromptId(p2PromptNextCheck, plantAsset, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponsep2 = 
            (Map<String,String>) JSON.deserialize(p2PromptResFinder, Map<String,String>.class);
        String nextPromptIdP2 = (String)nextPromptResponsep2.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS), nextPromptIdP2);
   
        //clear Site MetaData Check
        Test.startTest();
        String clearDataCheck = P1PlantInfoPromptSolar.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        string padNameAttrValue = Constants.PLANT_NAME;
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearedMeterNameCheck = promptSpecificInfoMapClearCheck.containsKey(padNameAttrValue)?promptSpecificInfoMapClearCheck.get(padNameAttrValue):'';
        System.assertEquals('Plant Name Test', clearedMeterNameCheck ); 
        Test.stopTest();
    }
}