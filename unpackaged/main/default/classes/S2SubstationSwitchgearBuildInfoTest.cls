/**
**/
@isTest
public with sharing class S2SubstationSwitchgearBuildInfoTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;
        
        List<Base_Asset_Template__c > newBaseAssetTemplate =new List<Base_Asset_Template__c>();
        newBaseAssetTemplate.add(TestDataFactory.createBaseAssetTemplate('Base Meter', newTemVersion.Id));
        newBaseAssetTemplate.add(TestDataFactory.createBaseAssetTemplate('Base Battery Bank Controllers', newTemVersion.Id));
        newBaseAssetTemplate.add(TestDataFactory.createBaseAssetTemplate('Base Battery Banks', newTemVersion.Id));
        insert newBaseAssetTemplate;
        
        List<Prompt_Information__c> newPromptInfo = new List<Prompt_Information__c>();
        newPromptInfo.add(TestDataFactory.createPromptInformation(Constants.S1_SUBSTATION_SWITCHGEAR_BUILD, newBaseAssetTemplate[0].Id, newTemVersion.Id));
        newPromptInfo.add (TestDataFactory.createPromptInformation(Constants.S2_SUBSTATION_SWITCHGEAR_BUILD_INFO, newBaseAssetTemplate[0].Id, newTemVersion.Id));
        insert newPromptInfo;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

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
                                                                            newBaseAssetTemplate[0].Id, newTemVersion.Id);
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;

        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptSpecificAttrNameLst = new list<String>{'Meters','Battery Bank Controllers','Battery Banks','SUB/SWG Name','Device Type','Device Name'};

        for(integer i = 0; i < 6; i++){ 
            Core_Attribute__c promptSpecificAttr = new Core_Attribute__c ();
        
            if(i<=2){
                promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],'Prompt Specific','Number',promptCoreAttrRTId,null,newPromptInfo[0].Id, newTemVersion.Id);
                promptSpecificAttr.Sensor_Type__c = 'Substation switchgear';
                promptSpecificAttr.Base_Asset_Name__c = newBaseAssetTemplate[i].Id;
            }else{                                                                                     
                promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],'Prompt Specific','Text',promptCoreAttrRTId,null,newPromptInfo[1].Id, newTemVersion.Id);
            }                                                                                                                                                                                                                                                                        
            promptSpecificAttrLst.add(promptSpecificAttr);  
        }
        insert promptSpecificAttrLst;

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
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ newPromptInfo[0].Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = newPromptInfo[0].Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate[0].Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c s1SiteMetadata = new Site_Metadata__c(); 
        s1SiteMetadata.Name = Constants.S1_SUBSTATION_SWITCHGEAR_BUILD;
        s1SiteMetadata.Prompt_Specific_Info__c = '{\"Substation or Switchgear?\":\"Switchgear\",\"SUB/SWG Name\":\"switch 4\",\"Meters\":\"2\",\"Battery Banks\":\"2\",\"Battery Bank Controllers\":\"2\"}';
        s1SiteMetadata.Attribute_Info__c = '{\"Meters CA\":\"1\",\"Battery Bank CA\":\"7\"}';
        s1SiteMetadata.Prompt_Information__c = newPromptInfo[0].Id;
        s1SiteMetadata.Account_Plant__c= newPlantAsset.id;
        s1SiteMetadata.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert s1SiteMetadata;
    }

    public static testMethod void S2SubstationSwitchgearBuildTest(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-S.1.0 Substation/Switchgear Build'].Id;

        String currentPromptName = Constants.S2_SUBSTATION_SWITCHGEAR_BUILD_INFO;
        Boolean clearAttribute = false;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};

        Test.startTest();
        //DataTable Output check
        String dataTableInput = S2SubstationSwitchgearBuildInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(6, currentPromptSiteMetadata.size());
        
        Site_Metadata__c s1SiteMetadata = new Site_Metadata__c(); 
        s1SiteMetadata.Name = Constants.S1_SUBSTATION_SWITCHGEAR_BUILD;
        s1SiteMetadata.Prompt_Specific_Info__c = '{\"Substation or Switchgear?\":\"Switchgear\",\"SUB/SWG Name\":\"switch 4\",\"Meters\":\"2\",\"Battery Banks\":\"2\",\"Battery Bank Controllers\":\"2\"}';
        s1SiteMetadata.Attribute_Info__c = '{\"Meters CA\":\"1\",\"Battery Bank CA\":\"7\"}';
        s1SiteMetadata.Account_Plant__c= plantAsset;
        s1SiteMetadata.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert s1SiteMetadata;
        
        String s2DataTableInput = S2SubstationSwitchgearBuildInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail, clearAttribute, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> s2PromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(12, s2PromptSiteMetadata.size());

        //Save Site MeteData check
        String deviceAttrName = 'Device Name';
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        promptSpecificInfoMap.put(deviceAttrName,'Device Name Test');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck =  S2SubstationSwitchgearBuildInfo.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String updatedDeviceName = promptSpecificInfoMapSaveCheck.containsKey(deviceAttrName)?promptSpecificInfoMapSaveCheck.get(deviceAttrName):'';
        System.assertEquals('Device Name Test', updatedDeviceName);

        //clear Site MetaData Check
        String clearDataCheck = S2SubstationSwitchgearBuildInfo.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String clearedStringNameCheck = promptSpecificInfoMapClearCheck.containsKey(deviceAttrName)?promptSpecificInfoMapClearCheck.get(deviceAttrName):'';
        System.assertEquals('Device Name Test', clearedStringNameCheck);
        Test.stopTest();
    }
}