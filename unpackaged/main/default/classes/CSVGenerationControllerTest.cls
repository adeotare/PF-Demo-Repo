@isTest
private with sharing class CSVGenerationControllerTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c p3BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PAD, newTemVersion.Id);
        insert p3BaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;
        
        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

        Prompt_Information__c p3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                        p3BaseAssetTemplate.Id, newTemVersion.Id);
        insert p3PromptInfo;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P5_INVERTS_BUILD_AND_COUNTS,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Type__c = Constants.SOLAR;
        insert newPromptInfo;
        
        Prompt_Information__c previousPromptInfo = TestDataFactory.createPromptInformation(Constants.P4_EQUIPMENT_PAD_METERS_INFO,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert previousPromptInfo ;
        
        Prompt_Information__c nextPromptInfo = TestDataFactory.createPromptInformation(Constants.P6_MODULAR_INVERTER_MODULE_INFO,
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
        list<String>promptSpecificAttrNameLst = new list<String>{Constants.PAD_NAME, Constants.INVERTER_NAME};
        
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
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplateG1.Id;
        insert g1PlantAssetPromptDetail;

        Site_Metadata__c newG1SiteMetadata = TestDataFactory.createG1SiteMetadata(newPlantAsset.Id);
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;

        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+p3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = p3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = p3BaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{\"Block Name\":\"Test Name\",\"Pad Name\":\"Pad Name Test\",\"Meter\":\"3\",\"Inverter\":\"3\"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Base_Asset_Template__c = p3BaseAssetTemplate.Id;
        p3SiteMetaData.Account_Plant__c = newPlantAsset.id;
        p3SiteMetaData.Prompt_Information__c = p3PromptInfo.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        p3SiteMetaData.Asset_Short_Name__c = 'AST1';
        insert p3SiteMetaData;
        
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+previousPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;
        
        Site_Metadata__c p4SiteMetaData = new Site_Metadata__c(); 
        p4SiteMetaData.Name = Constants.P4_EQUIPMENT_PAD_METERS_INFO;
        p4SiteMetaData.Prompt_Specific_Info__c = '{\"Block Name\":\"Test Name\",\"Pad Name\":\"Pad Name Test\",\"Meter\":\"3\",\"Inverter\":\"3\"}';
        p4SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p4SiteMetaData.Base_Asset_Template__c = p3BaseAssetTemplate.Id;
        p4SiteMetaData.Account_Plant__c = newPlantAsset.id;
        p4SiteMetaData.Prompt_Information__c = previousPromptInfo.id;
        p4SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        p4SiteMetaData.Asset_Short_Name__c = 'AST2';
        insert p4SiteMetaData;
    }

    private static testMethod void p5InvertersBuildTest(){
        Id plantAssetId = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        CSVGenerationController.getSiteMetadata(plantAssetId);       
        
        CSVGenerationController.fileUpload('Test', plantAssetId, 'Test File');
    }
}