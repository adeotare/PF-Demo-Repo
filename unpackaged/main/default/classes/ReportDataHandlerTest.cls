/**
**/
@istest
public with sharing class ReportDataHandlerTest {
 /*   @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Plant_Asset__c newPlantAsset1 = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset1;

        Plant_Asset__c newPlantAsset2 = TestDataFactory.createPlantAsset(Constants.SOLAR, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset2;

        Base_Asset_Template__c newBaseAssetTemplate1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER_PAD, newTemVersion.Id);
        insert newBaseAssetTemplate1;

        Base_Asset_Template__c newBaseAssetTemplate2 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER_PAD, newTemVersion.Id);
        insert newBaseAssetTemplate2;

        Prompt_Information__c newPromptInfo1 = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                      newBaseAssetTemplate1.Id, newTemVersion.Id);
        insert newPromptInfo1;

        Prompt_Information__c newPromptInfo2 = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                      newBaseAssetTemplate2.Id, newTemVersion.Id);
        insert newPromptInfo2;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;

        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String> datatypeLst = new list<String>{
            'Text','Number','Text','Text',
            'Text','Number','Text','Text',
            'Text','Number','Text','Text'
        };
        list<String> coreAttrNameLst = new list<String>{
            'Manufacturer','AC_Capacity','Tracker','Serial_Number',
            'Manufacturer2','AC_Capacity2','Tracker2','Serial_Number2',
            'Manufacturer3','AC_Capacity3','Tracker3','Serial_Number3'
        };

        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();

        for(integer i = 0; i < coreAttrNameLst.size(); i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newBaseAssetTemplate1.Id, newTemVersion.Id);
            coreAttr.Base_Asset_Name__c = (math.mod(i,2) == 0) ? newBaseAssetTemplate1.Id : newBaseAssetTemplate2.Id;
            coreAttr.Default_Value__c = (math.mod(i,2) == 0) ? '2':'';
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;

        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < coreAttrNameLst.size(); i++){
            Attribute_Requirement__c attrReq1 = TestDataFactory.createAttributeRequirement('Drive','Yes',coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq1);
            Attribute_Requirement__c attrReq2 = TestDataFactory.createAttributeRequirement('Drive','No',coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq2);
            Attribute_Requirement__c attrReq3 = TestDataFactory.createAttributeRequirement('Drive Plus','Yes',coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq3);
            Attribute_Requirement__c attrReq4 = TestDataFactory.createAttributeRequirement('Drive Plus','No',coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq4);
        }
        insert attrReqLst;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail1 = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail1.Name = newPlantAsset1.Name +'-'+ newPromptInfo1.Name;
        p1PlantAssetPromptDetail1.Plant_Asset__c = newPlantAsset1.Id;
        p1PlantAssetPromptDetail1.Prompt_Information__c = newPromptInfo1.Id;
        p1PlantAssetPromptDetail1.Base_Asset__c = newBaseAssetTemplate1.Id;
        insert p1PlantAssetPromptDetail1;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail2 = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail2.Name = newPlantAsset2.Name +'-'+ newPromptInfo2.Name;
        p1PlantAssetPromptDetail2.Plant_Asset__c = newPlantAsset2.Id;
        p1PlantAssetPromptDetail2.Prompt_Information__c = newPromptInfo2.Id;
        p1PlantAssetPromptDetail2.Base_Asset__c = newBaseAssetTemplate2.Id;
        insert p1PlantAssetPromptDetail2;

        Site_Metadata__c siteMetaData1 = new Site_Metadata__c(); 
        siteMetaData1.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        siteMetaData1.Prompt_Specific_Info__c = '{"noOfBlocks":"","Flat Hierarchy":"No","drivePlus":"true"}';
        siteMetaData1.Attribute_Info__c = '{\"Manufacturer\":\"4\",\"AC_Capacity\":\"8\",\"Tracker\":\"8\",\"Serial_Number\":\"8\"}';
        siteMetaData1.Base_Asset_Template__c = newBaseAssetTemplate1.Id;
        siteMetaData1.Plant_Asset__c = newPlantAsset1.id;
        siteMetaData1.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail1.Id;
        insert siteMetaData1;

        Site_Metadata__c siteMetaData2 = new Site_Metadata__c(); 
        siteMetaData2.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        siteMetaData2.Prompt_Specific_Info__c = '{"noOfBlocks":"","Flat Hierarchy":"No","drivePlus":"true"}';
        siteMetaData2.Attribute_Info__c = '{\"Manufacturer\":\"4\",\"AC_Capacity\":\"8\",\"Tracker\":\"8\",\"Serial_Number\":\"8\"}';
        siteMetaData2.Base_Asset_Template__c = newBaseAssetTemplate2.Id;
        siteMetaData2.Plant_Asset__c = newPlantAsset2.id;
        siteMetaData2.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail2.Id;
        insert siteMetaData2;

        List<Attribute_Value__c> attrValueLst = new List<Attribute_Value__c>();
        for(integer i = 0; i < 2; i++){
            for(integer j = 0; j < coreAttrNameLst.size(); j++){
                Attribute_Value__c attributeValue = new Attribute_Value__c();
                attributeValue.Plant_Asset__c = (i == 0) ? newPlantAsset1.Id : newPlantAsset2.Id;
                attributeValue.Site_Metadata__c = (i == 0) ? siteMetaData1.Id : siteMetaData2.Id;
                attributeValue.Prompt_Information__c = (i == 0) ? newPromptInfo1.Id : newPromptInfo2.Id; 
                attributeValue.Base_Asset_Template__c = (i == 0) ? newBaseAssetTemplate1.Id : newBaseAssetTemplate2.Id;
                attributeValue.Value__c = (math.mod(j,2) == 0) ? '3' : '';
                attributeValue.Attribute__c = coreAttrLst[j].Id;
                attrValueLst.add(attributeValue);
            }
        }
        
        if(attrValueLst.size() > 0){
            insert attrValueLst;
        }
    }

    public static testMethod void assetReportCreationTestMtd(){
        Plant_Asset__c plantAsset = [SELECT Id FROM Plant_Asset__c WHERE Renewable_Type__c = :Constants.WIND LIMIT 1];
        List<Id> promptInfo = new List<Id>();
        ReportDataHandler ReportDataHandlerCls = new ReportDataHandler();
        ReportDataHandlerCls.queryExsistingReportData(plantAsset.Id, promptInfo);
    }*/
}