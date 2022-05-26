@IsTest
public with sharing class TemplateGenerationControllerTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Account_Plant__c plantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.777.777',newTemVersion.Id);
        insert plantAsset;
        plantAsset.Customer_Plant_Name__c = 'Test Plant1';
        update plantAsset;
        
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
        
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                      newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;
        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                                                     p1BaseAssetTemplate.Id, newTemVersion.Id);
        insert p1PromptInfo;
        Prompt_Information__c p2PromptInfo = TestDataFactory.createPromptInformation(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS,
                                                                                     p2BaseAssetTemplate.Id, newTemVersion.Id);
        insert p2PromptInfo;
        
        Prompt_Information__c nextPromptInfo = TestDataFactory.createPromptInformation(Constants.P4_EQUIPMENT_PAD_METERS_INFO,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        nextPromptInfo.Prompt_Id__c='prompt3';                                                                                      
        insert nextPromptInfo;
        
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
                                                                                null,
                                                                                newBaseAssetTemplate.Id, newTemVersion.Id);
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;
        
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptSpecificAttrNameLst = new list<String>{Constants.PAD_NAME, Constants.METER_NAME,Constants.BLOCK_NAME};
            
        for(integer i = 0; i < 3; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                            'Prompt Specific',
                                                                                            'Text',
                                                                                            promptCoreAttrRTId,
                                                                                            null,
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
        
        //P2 Prompt Specific attribute 

         //for Prompt Specific records
         List<Core_Attribute__c> p2PromptSpecificAttrLst  = new List<Core_Attribute__c> ();
         List<String> p2promptSpecificAttrNameLst = new List<String>{Constants.PAD_NAME, Constants.METER_NAME,Constants.BLOCK_NAME};
             
         for(integer i = 0; i < 3; i++){
             Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                             'Prompt Specific',
                                                                                             'Text',
                                                                                             promptCoreAttrRTId,
                                                                                             null,
                                                                                             p2PromptInfo.Id, newTemVersion.Id);
            p2PromptSpecificAttrLst.add(promptSpecificAttr);
         }
         insert p2PromptSpecificAttrLst;
         
         List<Attribute_Requirement__c> p2AttrReqLst  = new List<Attribute_Requirement__c> ();
         for(integer i = 0; i < 4; i++){
             Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive','Yes',coreAttrLst[i].Id, newTemVersion.Id);
             p2AttrReqLst.add(attrReq);
         }
         insert p2AttrReqLst;

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

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1BaseAssetTemplate.Id;
        insert p1PlantAssetPromptDetail;
        
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+p2PromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = p2PromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = p2BaseAssetTemplate.Id;
        insert plantAssetPromptDetail;
        
        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"noOfBlocks":"","Flat Hierarchy":"Yes","drivePlus":"true"}';
        p1SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p1SiteMetaData.Base_Asset_Template__c = p1BaseAssetTemplate.Id;
        p1SiteMetaData.Account_Plant__c = newPlantAsset.id;
        p1SiteMetaData.Prompt_Information__c = p1PromptInfo.Id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
        insert p1SiteMetaData;
       
        Site_Metadata__c p2SiteMetaData = new Site_Metadata__c(); 
        p2SiteMetaData.Name = Constants.P2_BLOCK_INFO_AND_PAD_COUNTS;
        p2SiteMetaData.Prompt_Specific_Info__c = '{\"Block Name\":\"Test Name\",\"Pad Count\":\"7\",\"Meter\":\"3\",\"Inverter\":\"3\"}';
        p2SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p2SiteMetaData.Base_Asset_Template__c = p1BaseAssetTemplate.Id;
        p2SiteMetaData.Account_Plant__c = newPlantAsset.Id;
        p2SiteMetaData.Prompt_Information__c = p2PromptInfo.Id;
        p2SiteMetaData.Asset_Short_Name__c = 'Short Name';
        p2SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p2SiteMetaData;

        Implementation_Wizard_Form_Detail__c impWiz = new Implementation_Wizard_Form_Detail__c(
            Data_Interface__c = 'Datalogger',
            API_Type__c = 'AQS',
            Plant_API_Id__c = '123',
            Account_Plant__c = newPlantAsset.Id
        );
        insert impWiz;

        ContentVersion cv = new ContentVersion();
        cv.Title = 'Templates';
        cv.PathOnClient = 'Templates' + '.' +'csv';
        cv.VersionData = Blob.valueOf('csvToShow');
        cv.IsMajorVersion = true;
        Insert cv;

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = impWiz.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;
    }

    public static testMethod void piTemplateSitemetadataQueryCheck(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
        String csvOutputsString = TemplateGenerationController.getSiteMetadata(plantAsset);
    }
}