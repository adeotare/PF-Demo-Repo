/**
**/
@isTest
public with sharing class MetricValueDataCreationTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        Account_Plant__c newPlantAsset2 = TestDataFactory.createPlantAsset(Constants.SOLAR, 'Drive', '7777.77.333', newTemVersion.Id);
        insert newPlantAsset2;

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
        list<String>datatypeLst = new list<String>{'Number','Number','Decimal','Date','Checkbox'};
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
        p1PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        insert p1PlantAssetPromptDetail;

        Plant_Asset_Prompt_Detail__c p2PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p2PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p2PromptInfo.Name;
        p2PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p2PlantAssetPromptDetail.Prompt_Information__c = p2PromptInfo.Id;
        p2PlantAssetPromptDetail.Base_Asset__c = p2PromptBaseAsset.Id;
        insert p2PlantAssetPromptDetail;

        String promptSpecificInfoJSON = JSON.serialize('{"No of Blocks":"2","Flat Hierarchy":"No"');
        String coreAttributeInfoJSON = JSON.serialize('{"AC_CAPACITY":"","DC_CAPACITY":"200","Latitude":""}');

        String dDOJ = String.valueOf(System.now());
        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;//,'DC_CAPACITY','Latitude','DOJ','Hidden'
        p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"}';//'Latitude','DOJ','Hidden'
        p1SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"100","DC_CAPACITY":"200","Latitude":"","DOJ":"dDOJ","Hidden":"FALSE"}';
        p1SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p1SiteMetaData.Base_Asset_Template__c = p1PromptBaseAsset.id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
        insert p1SiteMetaData;
        
        String dDOJ1 = String.valueOf(System.now());
        Site_Metadata__c p2SiteMetaData = new Site_Metadata__c(); 
        p2SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;//,'DC_CAPACITY','Latitude','DOJ','Hidden'
        p2SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"}';//'Latitude','DOJ','Hidden'
        p2SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"100","DC_CAPACITY":"200","Latitude":"","DOJ":"dDOJ1","Hidden":"FALSE"}';
        p2SiteMetaData.Account_Plant__c= newPlantAsset2.id;
        p2SiteMetaData.Base_Asset_Template__c = p2PromptBaseAsset.id;
        p2SiteMetaData.Plant_Asset_Prompt_Detail__c = p2PlantAssetPromptDetail.Id;
        insert p2SiteMetaData;

        List<Attribute_Value__c> attrValueLst = new List<Attribute_Value__c>();
        for(integer i = 0; i < 2; i++){
            for(integer j = 0; j < coreAttrLst.size(); j++){
                Attribute_Value__c attributeValue = new Attribute_Value__c();
                attributeValue.Account_Plant__c = (i == 0) ? newPlantAsset.Id : newPlantAsset2.Id;
                attributeValue.Site_Metadata__c = (i == 0) ? p1SiteMetaData.Id : p2SiteMetaData.Id;
                attributeValue.Prompt_Information__c = (i == 0) ? p1PromptInfo.Id : p2PromptInfo.Id; 
                attributeValue.Base_Asset_Template__c = (i == 0) ? p1PromptBaseAsset.Id : p2PromptBaseAsset.Id;
                attributeValue.Value__c = (math.mod(j,2) == 0) ? '3' : '';
                attributeValue.Value_Number__c = (math.mod(j,2) == 0) ? 3 : 2;
                attributeValue.Value_Floating__c = (math.mod(j,2) == 0) ? 3.22 : 2.33;
                attributeValue.Value_Date__c = (math.mod(j,2) == 0) ? System.today():System.today()+3;
                attributeValue.Attribute__c = coreAttrLst[j].Id;
                attrValueLst.add(attributeValue);
            }
        }
        
        if(attrValueLst.size() > 0){
            insert attrValueLst;
        }

        Id metricDefinition = Utils.getRecordTypeInfo('Metric_Definition__c','Definition').getRecordTypeId();
        Id metricConst = Utils.getRecordTypeInfo('Metric_Definition__c','Constants').getRecordTypeId();

        Metric_Definition__c metricDefCnst = TestDataFactory.createMetricDef('', '', 'CONSTANT', 'NUMBER', '300', String.valueOf(newTemVersion.Id), metricConst);
        insert metricDefCnst;

        List<Metric_Definition__c> metricDefLst = new List<Metric_Definition__c>();
        for(Core_Attribute__c coreAttrIns : coreAttrLst){
                Metric_Definition__c metricDef = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'VALUES', '', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef);
                Metric_Definition__c metricDef2 = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'AVG', '', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef2);
                Metric_Definition__c metricDef3 = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'SUM', '', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef3);
                Metric_Definition__c metricDef4 = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'MIN', '', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef4);
                Metric_Definition__c metricDef5 = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'MAX', '', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef5);
                Metric_Definition__c metricDef6 = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'COUNT', 'TOTAL', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef6);
                Metric_Definition__c metricDef7 = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'COUNT', 'UNIQUE', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef7);
                Metric_Definition__c metricDef8 = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'COUNT', 'NULL', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef8);
                Metric_Definition__c metricDef9 = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'COUNT', 'VALUE', 'PV', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef9);
        }
        if(metricDefLst.size() >0){
            insert metricDefLst;
        }
        
        List<Metric_Value__c> metricValueLst = new List<Metric_Value__c>();
        for(Metric_Definition__c metricDefIn : [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: newPlantAsset.TEM_Version__c]){
                Metric_Value__c metricValue = TestDataFactory.createMetricValue(String.valueOf(metricDefIn.Id), String.valueOf(newPlantAsset.Id), '', metricDefIn.Attribute__r.Attribute_Master__r.Data_Type__c);  
                metricValueLst.add(metricValue);
        }
        insert metricValueLst;
    }
    @isTest
    public static void metricValueTest1(){
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.777'];
        Prompt_Information__c p1PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P1_PLANT_INFO_PROMPT_SOLAR LIMIT 1];
        Prompt_Information__c p2PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P2_BLOCK_INFO_AND_PAD_COUNTS LIMIT 1];
        Base_Asset_Template__c p1PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_PV_PLANT LIMIT 1];
        Base_Asset_Template__c p2PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =:Constants.BASE_BLOCK LIMIT 1];
        Site_Metadata__c p1SiteMetaData = [SELECT Id, Name, Attribute_Info__c FROM Site_Metadata__c WHERE Name =: p1PromptInfo.Name LIMIT 1];
        String name = 'Test Plant'+'-'+ p1PromptInfo.Name;
        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = [SELECT Id, Name FROM Plant_Asset_Prompt_Detail__c WHERE Name =: name LIMIT 1];
        List<Site_Metadata__c> allSiteMetaData = Utils.querySiteMetadata(p1PromptInfo.Name, plantAsset.Id);
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
            Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];
        List<Id> baseAssetTemplateIdLst = new List<Id>();

        for(Site_Metadata__c siteMetaDataInstance : allSiteMetaData){
            baseAssetTemplateIdLst.add(siteMetaDataInstance.Base_Asset_Template__c);
        }
        MetricValueDataCreation.queryBaseAssetCoreAttrBasedOnMetricDef(baseAssetTemplateIdLst, System.now(), String.valueOf(p1PlantAssetPromptDetail.Id), String.valueOf(plantAsset.id));
    }
}