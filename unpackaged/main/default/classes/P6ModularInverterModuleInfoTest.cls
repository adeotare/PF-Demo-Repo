/**
**/
@istest
public with sharing class P6ModularInverterModuleInfoTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;
        
        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Inverter', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c p5BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base pad', newTemVersion.Id);
        insert p5BaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;
        
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P6_MODULAR_INVERTER_MODULE_INFO,newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;

        Prompt_Information__c newP5PromptInfo = TestDataFactory.createPromptInformation(Constants.P5_INVERTS_BUILD_AND_COUNTS,newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP5PromptInfo;
        
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
        list<String>promptSpecificAttrNameLst = new list<String>{'Inverter Name','Modular Inverter Name'};
            
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
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;
 
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+ newP5PromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = newP5PromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = p5BaseAssetTemplate.Id;
        insert plantAssetPromptDetail;
        
        Site_Metadata__c p5SiteMetaData = new Site_Metadata__c();
        p5SiteMetaData.Name = Constants.P5_INVERTS_BUILD_AND_COUNTS;
        p5SiteMetaData.Prompt_Specific_Info__c = '{\"Modular Inverter\":\"2\",\"drivePlus\":\"false\",\"Inverter Name\":\"Inv1\"}';
        p5SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p5SiteMetaData.Base_Asset_Template__c = newBaseAssetTemplate.Id;
        p5SiteMetaData.Prompt_Information__c = newP5PromptInfo.Id;
        p5SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p5SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p5SiteMetaData;
    }
    public static testMethod void P6BModularInverterTest(){
        String currentPromptName = Constants.P6_MODULAR_INVERTER_MODULE_INFO;
        String nextPromptName = Constants.P7_INVERTER_SUBARRAY_INFO;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.5.0 Inverters Build and Counts'].Id;

        String dataTableInput = P6ModularInverterModuleInfo.getCustomDatatableCompInput(plantAsset,plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(2, currentPromptSiteMetadata.size());

        //Save Site MeteData check
        String stringNameAttrName = 'Inverter Name';
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(stringNameAttrName,'Inverter Name Test');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck =  P6ModularInverterModuleInfo.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c>
        savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedStringName = promptSpecificInfoMapSaveCheck.containsKey(stringNameAttrName)?promptSpecificInfoMapSaveCheck.get(stringNameAttrName):'';
        System.assertEquals('Inverter Name Test',updatedStringName );  

        //next PromptId check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = P6ModularInverterModuleInfo.findNextPromptId(siteMetadataRecords, plantAsset, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId );
        
        //clear Site MetaData Check
        String clearDataCheck = P6ModularInverterModuleInfo.clearPromptInfo(plantAsset,plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearedStringNameCheck = promptSpecificInfoMapClearCheck.containsKey(stringNameAttrName)?promptSpecificInfoMapClearCheck.get(stringNameAttrName):'';
        System.assertEquals('Inverter Name Test',clearedStringNameCheck );  
    }   
}