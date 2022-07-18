/**
**/
@istest
public with sharing class W1PlantInfoTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_WIND_PLANT, newTemVersion.Id);
        insert newBaseAssetTemplate;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.W1_PLANT_INFO_PROMPT_WIND,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Type__c = Constants.WIND;
        insert newPromptInfo;
        Prompt_Information__c nextPromptInfo = TestDataFactory.createPromptInformation(Constants.W2_STRING_BUILD_INFO,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        nextPromptInfo.Prompt_Id__c='prompt17';                                                                    
        insert nextPromptInfo;
        
        Prompt_Information__c previousPromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert previousPromptInfo;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number','Date','Number','Checkbox'};
        
        Attribute_Master__c attributeMaster = new Attribute_Master__c();
        attributeMaster.Name = Constants.DRIVE_PLUS;
        attributeMaster.Type__c = 'Metadata';
        attributeMaster.TEM_Version__c = newTemVersion.Id;
        attributeMaster.Alias__c = 'AC Capacity';
        insert attributeMaster;
        
        list<String>coreAttrNameLst = new list<String>{'AC Curtailment Limit','Date Commercial Operation','AC Capacity','DriveNO'};
        for(integer i = 0; i < 4; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newBaseAssetTemplate.Id, newTemVersion.Id);
                                                                                coreAttr.Attribute_Master__c = attributeMaster.id; 
                                                                                coreAttr.Plant_Asset_Field_Name__c = 'PF_Service_Product__c';
            coreAttr.Plant_Asset_Field_Name__c = 'Name';
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;
        
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+previousPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"Switchgear Substation":"3","Metmast":"2","PF Service Product":"Drive;FSM","Renewable Type":"Wind - Onshore"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Base_Asset_Template__c = newBaseAssetTemplate.Id;
        g1SiteMetaData.Account_Plant__c = newPlantAsset.id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert g1SiteMetaData;
        
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptDataTypeLst = new list<String>{'Text','Text','Text'};
        list<String>promptSpecificAttrNameLst = new list<String>{'Plant Name','Plant ID','Drive Plus'};
       
        Attribute_Master__c attributeMasterPrompt = new Attribute_Master__c();
        //attributeMasterPrompt.Name = Constants.DRIVE_PLUS;
        attributeMasterPrompt.Name = 'attrMaster';
        attributeMasterPrompt.Type__c = 'Metadata';
        attributeMasterPrompt.TEM_Version__c = newTemVersion.Id;
        attributeMasterPrompt.Alias__c = 'AC Capacity';
        insert attributeMasterPrompt;

        for(integer i = 0; i < 3; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                'Text',
                                                                                promptCoreAttrRTId,
                                                                                (promptDataTypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newPromptInfo.Id, newTemVersion.Id);
                                                                                promptSpecificAttr.Attribute_Master__c=attributeMasterPrompt.id;
            promptSpecificAttr.Plant_Asset_Field_Name__c ='PF_Service_Product__c';
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst;

        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 4; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement(i<2?'Drive':'Drive Plus','Yes',coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;
    }
    public static testMethod void w1PlantInfoTest(){
        //query Account Plant
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id, Name From Plant_Asset_Prompt_Detail__c WHERE Name = 'Test Plant-G.1.0 Plant Info and Renewable Type Prompt'].Id;
        
        //Calling P4 getCustomDatatableCompInput
        String previousPromptName = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        String currentPromptName = Constants.W1_PLANT_INFO_PROMPT_WIND;
        Boolean isKeyToGenerateRows = false;
        map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true','isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
             Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        //DataTable Output check
        String dataTableInput = W1PlantInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(1, currentPromptSiteMetadata.size());

        //Save Site MeteData check
        String plantAttrName = Constants.PLANT_NAME;
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        promptSpecificInfoMap.put(plantAttrName,'Plant Name Test');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck =  W1PlantInfo.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String updatedDeviceName = promptSpecificInfoMapSaveCheck.containsKey(plantAttrName)?promptSpecificInfoMapSaveCheck.get(plantAttrName):'';
        System.assertEquals('Plant Name Test', updatedDeviceName);
        
        //next PromptId check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = W1PlantInfo.findNextPromptId(plantAsset,siteMetadataRecords,isKeyToGenerateRows, true,additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(Constants.W2_STRING_BUILD_INFO),nextPromptId);

        //clear Site MetaData Check
        String clearDataCheck = W1PlantInfo.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String clearedStringNameCheck = promptSpecificInfoMapClearCheck.containsKey(plantAttrName)?promptSpecificInfoMapClearCheck.get(plantAttrName):'';
        System.assertEquals('Plant Name Test', clearedStringNameCheck);
    }
}