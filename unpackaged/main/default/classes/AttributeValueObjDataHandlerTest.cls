/**
**/
@isTest
public with sharing class AttributeValueObjDataHandlerTest {
 /*   @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Plant_Asset__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c p1PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert p1PromptBaseAsset;
        
        Base_Asset_Template__c p2PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_BLOCK, newTemVersion.Id);
        insert p2PromptBaseAsset;
        
        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                p1PromptBaseAsset.Id, newTemVersion.Id);
        insert p1PromptInfo;

        Prompt_Information__c p2PromptInfo = TestDataFactory.createPromptInformation(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS,
                                                p2PromptBaseAsset.Id, newTemVersion.Id);
        insert p2PromptInfo;
        
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster(Constants.FLAT_HIERARCHY, newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c', 'Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number','Decimal','Decimal','Date','Checkbox'};
        list<String>coreAttrNameLst = new list<String>{'AC_CAPACITY','DC_CAPACITY','Latitude','DOJ','Hidden'};
        for(integer i = 0; i < 4; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptBaseAsset.Id, newTemVersion.Id);                                                            
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;

        
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLstPrompt = new list<String>{'Picklist','Number'};
        list<String>promptSpecificAttrNameLst = new list<String>{'Flat Hierarchy', 'No of Blocks'};
        
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                datatypeLstPrompt[i],
                                                                                promptCoreAttrRTId,
                                                                                (datatypeLstPrompt[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptInfo.Id, newTemVersion.Id);
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst;

        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 4; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        insert p1PlantAssetPromptDetail;

        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"Yes"}';
        p1SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"100","DC_CAPACITY":"2.73"}';
        p1SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p1SiteMetaData.Base_Asset_Template__c = p1PromptBaseAsset.id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
        p1SiteMetaData.Prompt_Information__c = p1PromptInfo.Id;
        insert p1SiteMetaData;
    }

    @isTest
    public static void attrValueTest1(){
        Plant_Asset__c newPlantAsset = [SELECT Id, Name FROM Plant_Asset__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777' LIMIT 1];
        Prompt_Information__c p1PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P1_PLANT_INFO_PROMPT_SOLAR LIMIT 1];
        Prompt_Information__c p2PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P2_BLOCK_INFO_AND_PAD_COUNTS LIMIT 1];
        Base_Asset_Template__c p1PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_PV_PLANT LIMIT 1];
        Base_Asset_Template__c p2PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =:Constants.BASE_BLOCK LIMIT 1];
        Site_Metadata__c p1SiteMetaData = [SELECT Id, Name, Attribute_Info__c FROM Site_Metadata__c WHERE Name =: p1PromptInfo.Name LIMIT 1];
        String name = 'Test Plant'+'-'+ p1PromptInfo.Name;
        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = [SELECT Id, Name FROM Plant_Asset_Prompt_Detail__c WHERE Name =: name LIMIT 1];
        List<Site_Metadata__c> allSiteMetaData = Utils.querySiteMetadata(p1PromptInfo.Name, newPlantAsset.Id);
        List<Id> siteMetaDataIdLst = new List<Id>();
        for(Site_Metadata__c siteMetaDataInstance : allSiteMetaData){
            siteMetaDataIdLst.add(siteMetaDataInstance.Id);
        }
        AttributeValueObjDataHandler.createOrUpdateAttrValueRecs(siteMetaDataIdLst, System.now(), String.valueOf(p1PlantAssetPromptDetail.Id), String.valueOf(newPlantAsset.id));
    }*/
}