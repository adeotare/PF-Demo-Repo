/**
**/
@isTest
public class P7InverterSubarrayInfoTest {
      @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Subarray', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c p5BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base pad', newTemVersion.Id);
        insert p5BaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;
        
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P7_INVERTER_SUBARRAY_INFO,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;

        Prompt_Information__c newP5PromptInfo = TestDataFactory.createPromptInformation(Constants.P5_INVERTS_BUILD_AND_COUNTS,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP5PromptInfo;
        
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c', 'Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Text', 'Number', 'Text', 'Text'};
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
        list<String>promptSpecificAttrNameLst = new list<String>{'Sub Array', 'Inverter Name'};
        
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
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
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
        p5SiteMetaData.Prompt_Specific_Info__c = '{"Sub Array":"3","Recombiner Channel(s)":"1","Pad Name":"Equip Pad","Meter Name":"M1","Inverter Name":"Test1","Inverter Modules(s)":"2","Drive+ Re/Combiner(s)":"2","Combiner Channels(s)":"2"}';
        p5SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p5SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p5SiteMetaData.Prompt_Information__c = newP5PromptInfo.Id;
        p5SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p5SiteMetaData;
    }

    public static testMethod void P7InverterSubarrayInfoTest(){
        String currentPromptName = Constants.P7_INVERTER_SUBARRAY_INFO;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};

        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.5.0 Inverters Build and Counts'].Id;
        Boolean isClearExecute = False;

        //DataTable Output check
        String dataTableInput = P7InverterSubarrayInfo.getCustomDatatableCompInput(plantAsset,plantAssetPromptDetail,isClearExecute,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(3, currentPromptSiteMetadata.size());
      
        //DataTable Output check
        String p7DataTableInput = P7InverterSubarrayInfo.getCustomDatatableCompInput(plantAsset,plantAssetPromptDetail,isClearExecute,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> p7PromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(3, p7PromptSiteMetadata.size());

        //clear Site MetaData Check
        Test.startTest();
        String clearDataCheck = P7InverterSubarrayInfo.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        String keyValue ='Subarray Name';
        Map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(keyValue);    
        String clearedPromptSpecificInfoCheck  = promptSpecificInfoMapClearCheck.containsKey(keyValue)?promptSpecificInfoMapClearCheck.get(keyValue):'';
        System.assertEquals(clearValue,clearedPromptSpecificInfoCheck );

        //Save SiteMetadata 
        
        String subArrayAttrName = 'Subarray Name';
        Map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(subArrayAttrName ,'Subarray 01');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = P7InverterSubarrayInfo.saveSiteMetadataRecords(plantAsset,siteMetadataRecordSaveCheck,isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        Map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedSubarrayName = promptSpecificInfoMapSaveCheck.containsKey(subArrayAttrName)?promptSpecificInfoMapSaveCheck.get(subArrayAttrName):'';
        System.assertEquals('Subarray 01', updatedSubarrayName );
        Test.stopTest();
    }

    public static testmethod void testNextPromptID(){
        Boolean isClearExecute = False;
        String currentPromptName = Constants.P7_INVERTER_SUBARRAY_INFO;
        String nextPromptName = Constants.P8A_INVERTERS_RECOMBINERS_INFO;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.5.0 Inverters Build and Counts'].Id;

        Site_Metadata__c p5SiteMetaData = new Site_Metadata__c(); 
        p5SiteMetaData.Name = Constants.P5_INVERTS_BUILD_AND_COUNTS;
        p5SiteMetaData.Prompt_Specific_Info__c = '{\"Recombiner Channel(s)\":\"2\",\"Combiner Channel(s)\":\"7\",\"Sub Array\":\"5\"}';
        p5SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p5SiteMetaData.Account_Plant__c= plantAsset;
        p5SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert p5SiteMetaData;

        Test.startTest();
        String dataTableInput = P7InverterSubarrayInfo.getCustomDatatableCompInput(plantAsset,plantAssetPromptDetail,isClearExecute,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);

        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P7InverterSubarrayInfo.findNextPromptId(plantAsset,siteMetadataRecords,isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
        Test.stopTest();
    }

    public static testmethod void testNextCombinerChannel(){
        Boolean isClearExecute = False;
        String currentPromptName = Constants.P7_INVERTER_SUBARRAY_INFO;
        String nextPromptName = Constants.P8B_INVERTERS_COMBINERS_INFO;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.5.0 Inverters Build and Counts'].Id;

        Site_Metadata__c p5SiteMetaData = new Site_Metadata__c(); 
        p5SiteMetaData.Name = Constants.P5_INVERTS_BUILD_AND_COUNTS;
        p5SiteMetaData.Prompt_Specific_Info__c = '{\"Recombiner Channel(s)\":\"",\"Combiner Channel(s)\":\"7\"}';
        p5SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p5SiteMetaData.Account_Plant__c= plantAsset;
        p5SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert p5SiteMetaData;

        String dataTableInput = P7InverterSubarrayInfo.getCustomDatatableCompInput(plantAsset,plantAssetPromptDetail,isClearExecute,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);

        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextResponse = P7InverterSubarrayInfo.findNextPromptId(plantAsset,siteMetadataRecords,isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPromptId1 = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(nextPromptName),nextPromptId1);
    }
}