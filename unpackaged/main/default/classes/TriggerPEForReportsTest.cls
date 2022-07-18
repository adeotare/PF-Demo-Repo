/**
**/
@isTest
public with sharing class TriggerPEForReportsTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        RFI_Categories__c newRFICat = new RFI_Categories__c();
        newRFICat.Category_Classification__c = 'General';
        newRFICat.Name = System.Label.SubstationRFICategoryName;
        newRFICat.RFI_Sub_Type_Filter__c = 'Asset Builder';
        newRFICat.RFI_Category_Status__c = 'Active';
        newRFICat.RecordTypeId = Utils.getRecordTypeInfo('RFI_Categories__c', ConstantsRecordTypes.RFI_CATEGORY_MISSING_INCOMPLETE_INFORMATION).getRecordTypeId();
        insert newRFICat;

        Base_Asset_Template__c p1PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert p1PromptBaseAsset;

        Prompt_Information__c g1PromptInfo = new Prompt_Information__c();
        g1PromptInfo.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1PromptInfo.TEM_Version__c = newTemVersion.Id;
        insert g1PromptInfo;

        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                p1PromptBaseAsset.Id, newTemVersion.Id);
        insert p1PromptInfo;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster(Constants.FLAT_HIERARCHY, newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;

        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();

        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number','Number','Decimal','Decimal','Text','Text','Picklist','Picklist',
        'Date','Date','Checkbox','Checkbox'};
        list<String>coreAttrNameLst = new list<String>{'AC_Capacity','DC_Capacity','Decimal1','Decimal2','Text1','Text2','Picklist1','Picklist2'
        ,'Date1','Date2','Checkbox1','Checkbox2'};
        for(integer i = 0; i < coreAttrNameLst.size(); i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptBaseAsset.Id, newTemVersion.Id);                                                                  
            coreAttr.Default_Value__c = (math.mod(i,2) == 0) ? '2':'';
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;
        
        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < coreAttrLst.size(); i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
            Attribute_Requirement__c attrReq2 = TestDataFactory.createAttributeRequirement('Drive Plus', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq2);
        }
		insert attrReqLst;
        
        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        insert g1PlantAssetPromptDetail;
        
        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"SubstationSwitchgear":"0", "Renewable Type":"SOLAR - PV"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Account_Plant__c= newPlantAsset.id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        insert p1PlantAssetPromptDetail;

        String promptSpecificInfoJSON = JSON.serialize('{"No of Blocks":"2","Flat Hierarchy":"No"');
        String coreAttributeInfoJSON = JSON.serialize('{"AC_CAPACITY":""}');

        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"}';
        p1SiteMetaData.Attribute_Info__c = '{"AC_Capacity":"3724918","DC_Capacity":"3724918"}';
        p1SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p1SiteMetaData.Base_Asset_Template__c = p1PromptBaseAsset.id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
        insert p1SiteMetaData;
    }
    @isTest
    public static void triggerPEForReportsTest1(){
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.777'];
        TriggerPEForReports.createPE(plantAsset.Id);
    }   
}