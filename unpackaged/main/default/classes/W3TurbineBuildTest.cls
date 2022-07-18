/**
**/
@isTest
public with sharing class W3TurbineBuildTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;
        
        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_WIND_STRING, newTemVersion.Id);
        insert newBaseAssetTemplate;
        
        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.W3_TURBINE_BUILD, newBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Prompt_Id__c = 'prompt1';
        newPromptInfo.Type__c = Constants.WIND;
        insert newPromptInfo;
        Prompt_Information__c previousPromptInfo = TestDataFactory.createPromptInformation(Constants.W2_STRING_BUILD_INFO, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert previousPromptInfo;
        Prompt_Information__c nextPromptInfo = TestDataFactory.createPromptInformation(Constants.W4_TURBINE_BUILD_AND_INFO,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        nextPromptInfo.Prompt_Id__c='prompt17';                                                                            
        insert nextPromptInfo;

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplateG1.Id;
        insert g1PlantAssetPromptDetail;
        
        Site_Metadata__c newG1SiteMetadata = TestDataFactory.createG1SiteMetadata(newPlantAsset.Id);
        newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert newG1SiteMetadata;

        Prompt_Information__c w1PromptInfo = TestDataFactory.createPromptInformation(Constants.W1_PLANT_INFO_PROMPT_WIND,newBaseAssetTemplate.Id, newTemVersion.Id);
        insert w1PromptInfo;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+w1PromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = w1PromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;
        
        Site_Metadata__c w1SiteMetaData = new Site_Metadata__c(); 
        w1SiteMetaData.Name = Constants.W1_PLANT_INFO_PROMPT_WIND;
        w1SiteMetaData.Prompt_Specific_Info__c = '{"String Count":"3","Wind Turbine Build Count":"3"}';
        w1SiteMetaData.Account_Plant__c = newPlantAsset.id;
        w1SiteMetaData.Prompt_Information__c = w1PromptInfo.id;
        w1SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert w1SiteMetaData;

        Plant_Asset_Prompt_Detail__c w2PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        w2PlantAssetPromptDetail.Name = 'Test Plant' +'-'+previousPromptInfo.Name;
        w2PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        w2PlantAssetPromptDetail.Prompt_Information__c = previousPromptInfo.Id;
        w2PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert w2PlantAssetPromptDetail;
                
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();
        list<String>promptSpecificAttrNameLst = new list<String>{'Hail','Turbine Build','Build Name'};
        list<String>promptSpecificAttTypeLst = new list<String>{'Number','Text','Number'};

        //for Prompt Specific records
        for(integer i = 0; i < 3; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                promptSpecificAttTypeLst[i],
                                                                                promptCoreAttrRTId,
                                                                                null,
                                                                                newPromptInfo.Id, newTemVersion.Id);
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst;    
        
        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;
    }
    public static testMethod void W3TurbineBuildTest(){ 
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name = 'Test Plant-W.2.0 String Build Info'].Id;
        String currentPromptName = Constants.W3_TURBINE_BUILD;
        String previousPromptName = Constants.W2_STRING_BUILD_INFO;
        Boolean isKeyToGenerateRows = false;
        
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        String dataTableInput = W3TurbineBuild.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(3, currentPromptSiteMetadata.size());

        //Save Site MeteData check
        String blockNameAttrName = Constants.BLOCK_NAME;
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        promptSpecificInfoMap.put(blockNameAttrName,'Block Name Test'); 
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = W3TurbineBuild.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, plantAsset, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedAttrName = promptSpecificInfoMapSaveCheck.containsKey(blockNameAttrName)?promptSpecificInfoMapSaveCheck.get(blockNameAttrName):'';
        System.assertEquals('Block Name Test', updatedAttrName);

        //next PromptId check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
        String nextPromptResFinder = W3TurbineBuild.findNextPromptId(siteMetadataRecords,plantAsset,isKeyToGenerateRows,true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(Constants.W4_TURBINE_BUILD_AND_INFO),nextPromptId); 
 
        //clear Site MetaData Check
        String clearDataCheck = W3TurbineBuild.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String clearedPromptSpecificInfoCheck = promptSpecificInfoMapClearCheck.containsKey(blockNameAttrName)?promptSpecificInfoMapClearCheck.get(blockNameAttrName):'';
        System.assertEquals('Block Name Test', clearedPromptSpecificInfoCheck);
    }
}