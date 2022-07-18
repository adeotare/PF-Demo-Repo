/**
**/
@istest
public with sharing class P8BInvertersCombinerInfoTest {
    @testSetup
    public static void testDataSetup() {
        String currentPromptName = Constants.P8B_INVERTERS_COMBINERS_INFO;

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        
        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Recombiner', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P8B_INVERTERS_COMBINERS_INFO,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;

        Prompt_Information__c p3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert p3PromptInfo;

        Prompt_Information__c p7PromptInfo = TestDataFactory.createPromptInformation(Constants.P7_INVERTER_SUBARRAY_INFO,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert p7PromptInfo;

        Prompt_Information__c new8APromptInfo = TestDataFactory.createPromptInformation(Constants.P8A_INVERTERS_RECOMBINERS_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert new8APromptInfo;

        Prompt_Information__c p5PromptInfo = TestDataFactory.createPromptInformation(Constants.P5_INVERTS_BUILD_AND_COUNTS,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert p5PromptInfo;

        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
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

        Core_Attribute__c p5PromptSpecificAttr = TestDataFactory.createPromptSpecificAttr('Inverter Name',
                                                                                        'Prompt Specific',
                                                                                        'Text',
                                                                                        promptCoreAttrRTId,
                                                                                        null,
                                                                                        p5PromptInfo.Id, newTemVersion.Id);
        insert p5PromptSpecificAttr;

        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptSpecificAttrNameLst = new list<String>{'Combiner Name', 'Recombiner Name', 'Subarray Name'};
        list<String>promptDatatypeLst = new list<String>{'Text','Picklist','Picklist'};
        for(integer i = 0; i < 3; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                promptDatatypeLst[i],
                                                                                promptCoreAttrRTId,
                                                                                (promptDatatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                newPromptInfo.Id, newTemVersion.Id);
            promptSpecificAttr.Picklist_Dependency1__c = (promptDatatypeLst[i] == 'Picklist')? p5PromptSpecificAttr.Attribute_Master__r.Id : null; 
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

        Plant_Asset_Prompt_Detail__c p5PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p5PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p5PromptInfo.Name;
        p5PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p5PlantAssetPromptDetail.Prompt_Information__c = p5PromptInfo.Id;
        p5PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert p5PlantAssetPromptDetail;

        Site_Metadata__c p5SiteMetaData = new Site_Metadata__c(); 
        p5SiteMetaData.Name = Constants.P5_INVERTS_BUILD_AND_COUNTS;
        p5SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Combiner Name\":\"3\",\"Recombiner Channel(s)\":\"3\",\"Combiner Channel(s)\":\"3\"}';
        p5SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p5SiteMetaData.Account_Plant__c = newPlantAsset.id;
        p5SiteMetaData.Prompt_Information__c = p5PromptInfo.Id;
        p5SiteMetaData.Plant_Asset_Prompt_Detail__c = p5PlantAssetPromptDetail.Id;
        insert p5SiteMetaData;
        
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+ new8APromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = new8APromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c p8SiteMetaData = new Site_Metadata__c(); 
        p8SiteMetaData.Name = Constants.P8A_INVERTERS_RECOMBINERS_INFO;
        p8SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Recombiner Name\":\"Rec01\"}';
        p8SiteMetaData.Attribute_Info__c = '{}';
        p8SiteMetaData.Account_Plant__c = newPlantAsset.id;
        p8SiteMetaData.Prompt_Information__c = new8APromptInfo.id;
        p8SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p8SiteMetaData;   

        Plant_Asset_Prompt_Detail__c p7PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p7PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p7PromptInfo.Name;
        p7PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p7PlantAssetPromptDetail.Prompt_Information__c = p7PromptInfo.Id;
        p7PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert p7PlantAssetPromptDetail;

        Site_Metadata__c p7SiteMetaData = new Site_Metadata__c(); 
        p7SiteMetaData.Name = Constants.P7_INVERTER_SUBARRAY_INFO;
        p7SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Subarray Name\":\"SubArray01\"}';
        p7SiteMetaData.Attribute_Info__c = '{}';
        p7SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p7SiteMetaData.Prompt_Information__c = p7PromptInfo.Id;
        p7SiteMetaData.Plant_Asset_Prompt_Detail__c = p7PlantAssetPromptDetail.Id;
        insert p7SiteMetaData;

        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p3PromptInfo.Name;
        p3PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = p3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{\"Tracker Controller\":\"7",\"Tracker Motor\":\"\",\"Transformers\":\"\",\"Other Assets\":\"No\",\"Relay\":\"\"}';
        p3SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p3SiteMetaData.Account_Plant__c = newPlantAsset.id;
        p3SiteMetaData.Prompt_Information__c = p3PromptInfo.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        insert p3SiteMetaData;

        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        
        //DataTable Output check
        String dataTableInput = P8BInvertersCombinerInfo.getCustomDatatableCompInput(newPlantAsset.id, plantAssetPromptDetail.Id,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, newPlantAsset.id);
        System.assertEquals(3, currentPromptSiteMetadata.size());

        //Save SiteMetadata 
        String recombinerAttrName = 'Combiner Name';
        Boolean isKeyToGenerateRows = false;
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(recombinerAttrName ,'Recombiner 01');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = P8BInvertersCombinerInfo.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, newPlantAsset.id, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, newPlantAsset.id);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedrecombinerAttrName = promptSpecificInfoMapSaveCheck.containsKey(recombinerAttrName)?promptSpecificInfoMapSaveCheck.get(recombinerAttrName):'';
        System.assertEquals('Recombiner 01', updatedrecombinerAttrName );

        //clear Site MetaData Check
        String clearDataCheck = P8BInvertersCombinerInfo.clearPromptInfo(newPlantAsset.id, plantAssetPromptDetail.Id);
        String keyValue ='Combiner Name';
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(keyValue);    
        String clearedPromptSpecificInfoCheck  = promptSpecificInfoMapClearCheck.containsKey(keyValue)?promptSpecificInfoMapClearCheck.get(keyValue):'';
        System.assertEquals(clearValue,clearedPromptSpecificInfoCheck ); 
    }

    public static testMethod void testTrackerController(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.8.A Inverters Recombiner Info'].Id;
        String nextPromptName = Constants.P9A_TRACKER_CONTROLLER_INFO;
        String currentPromptName = Constants.P8B_INVERTERS_COMBINERS_INFO;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};        
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        Test.startTest();
        String dataTableInput = P8BInvertersCombinerInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
       
        //Next Prompt Check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P8BInvertersCombinerInfo.findNextPromptId(plantAsset, siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
        Test.stopTest();        
    }
    
    public static testMethod void testTrackerMotor(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.8.A Inverters Recombiner Info'].Id;
        String nextPromptName = Constants.P9B_TRACKER_MOTOR_INFO;
        String currentPromptName = Constants.P8B_INVERTERS_COMBINERS_INFO;
        Boolean isKeyToGenerateRows = false;

        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        Test.startTest();
        String dataTableInput = P8BInvertersCombinerInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        
        //Next Prompt Check       
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P8BInvertersCombinerInfo.findNextPromptId(plantAsset, siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
        Test.stopTest();
    } 
    
    public static testMethod void testOtherAsset(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.8.A Inverters Recombiner Info'].Id;
        String nextPromptName = Constants.P10A_OTHER_ASSET_BUILD;
        String currentPromptName = Constants.P8B_INVERTERS_COMBINERS_INFO;
        Boolean isKeyToGenerateRows = false;

        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};  
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        Test.startTest();
        String dataTableInput = P8BInvertersCombinerInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        
        //Next Prompt Check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P8BInvertersCombinerInfo.findNextPromptId(plantAsset, siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
        Test.stopTest();
    }      
}