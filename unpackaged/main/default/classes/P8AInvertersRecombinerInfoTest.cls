/**Constants.WIND
**/
@istest
public with sharing class P8AInvertersRecombinerInfoTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.777',newTemVersion.Id);
//        newPlantAsset.Met_Mast__c = 7;
//        newPlantAsset.Substation_Switchgears__c = 4; 
        insert newPlantAsset;
        
        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Recombiner', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;
        
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P8A_INVERTERS_RECOMBINERS_INFO,
                                                                                      newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;
        
        Prompt_Information__c newP5PromptInfo = TestDataFactory.createPromptInformation(Constants.P5_INVERTS_BUILD_AND_COUNTS,
                                                                                    newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP5PromptInfo;

        Prompt_Information__c newP7PromptInfo = TestDataFactory.createPromptInformation(Constants.P7_INVERTER_SUBARRAY_INFO,
                                                                                    newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newP7PromptInfo;
       
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
        
        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 4; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive','Yes',coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;

        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptSpecificAttrNameLst = new list<String>{'Recombiner Name', 'Inverter Name'};
        
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

        Plant_Asset_Prompt_Detail__c p5plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p5plantAssetPromptDetail.Name = 'Test Plant' +'-'+ newP5PromptInfo.Name;
        p5plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p5plantAssetPromptDetail.Prompt_Information__c = newP5PromptInfo.Id;
        p5plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert p5plantAssetPromptDetail;
        
        Site_Metadata__c p5SiteMetaData = new Site_Metadata__c(); 
        p5SiteMetaData.Name = Constants.P5_INVERTS_BUILD_AND_COUNTS;
        p5SiteMetaData.Prompt_Specific_Info__c = '{"Sub Array":"3","Recombiner Channel(s)":"1","Pad Name":"Equip Pad","Meter Name":"M1","Inverter Name":"Test1","Inverter Module(s)":"2","Drive+ Re/Combiner(s)":"2","Combiner Channel(s)":"2"}';
        p5SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
        p5SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p5SiteMetaData.Prompt_Information__c = newP5PromptInfo.Id;
        p5SiteMetaData.Plant_Asset_Prompt_Detail__c = p5plantAssetPromptDetail.Id;
        insert p5SiteMetaData;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = 'Test Plant' +'-'+ newP7PromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = newP7PromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;
        
        Site_Metadata__c p7SiteMetaData = new Site_Metadata__c(); 
        p7SiteMetaData.Name = Constants.P7_INVERTER_SUBARRAY_INFO;
        p7SiteMetaData.Prompt_Specific_Info__c = '{\"Inverter Name\":\"Test Name\",\"Subarray Name\":\"SubArray01\"}';
        p7SiteMetaData.Attribute_Info__c = '{}';
        p7SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p7SiteMetaData.Prompt_Information__c = newP7PromptInfo.Id;
        p7SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert p7SiteMetaData;
    }
    
    public static testMethod void p8AInvertersRecombinerTest(){

        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777'].Id;
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Name ='Test Plant-P.7.0 Inverter Subarray Info'].Id;
        String currentPromptName = Constants.P8A_INVERTERS_RECOMBINERS_INFO;
        String nextPromptName = Constants.P8B_INVERTERS_COMBINERS_INFO;
        Boolean isKeyToGenerateRows = false;
        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true', 'isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);
        
        String dataTableInput = P8AInvertersRecombinerInfo.getCustomDatatableCompInput(plantAsset, plantAssetPromptDetail,JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        System.assertEquals(1, currentPromptSiteMetadata.size());
        
        //clear Site MetaData Check
        String clearDataCheck = P8AInvertersRecombinerInfo.clearPromptInfo(plantAsset, plantAssetPromptDetail);
        string inverterNameAttrValue = Constants.INVERTER_NAME;
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(inverterNameAttrValue); 
        String clearedPromptSpecificInfoCheck = promptSpecificInfoMapClearCheck.containsKey(inverterNameAttrValue)?promptSpecificInfoMapClearCheck.get(inverterNameAttrValue):'';
        System.assertEquals(clearValue, clearedPromptSpecificInfoCheck);

        //Save SiteMetadata 
        String recombinerAttrName = 'Recombiner Name';
        map<String,String> promptSpecificInfoMap = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(recombinerAttrName ,'Recombiner 01');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Boolean saveDataCheck = P8AInvertersRecombinerInfo.saveSiteMetadataRecords(plantAsset,siteMetadataRecordSaveCheck,isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAsset);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedRecombinerName = promptSpecificInfoMapSaveCheck.containsKey(recombinerAttrName)?promptSpecificInfoMapSaveCheck.get(recombinerAttrName):'';
        System.assertEquals('Recombiner 01',updatedRecombinerName ); 
        
        String siteMetadataStr = JSON.serialize(savedPromptSiteMetadata);
        Map<String, String> strAdditionalParams = new Map<String, String>();
        P8AInvertersRecombinerInfo.findNextPromptId(plantAsset, siteMetadataStr, false, false, JSON.serialize(strAdditionalParams), true);
    }
}