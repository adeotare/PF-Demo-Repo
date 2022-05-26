/**
**/
@isTest
public with sharing class M2MetMastStationBuildTest {
    
    public static testMethod void M2MetMastStaionBuildTests() {
        String currentPromptName = Constants.M2_METMAST_STATION_BUILD;
        String nextPromptName = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;
        
        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Meter', newTemVersion.Id);
        insert newBaseAssetTemplate;

        Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplateG1;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplateG1.Id, newTemVersion.Id);
        insert g1PromptInfo ;
        
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.M1_MET_MAST_STATION_BUILD, newBaseAssetTemplate.Id, newTemVersion.Id);
        insert newPromptInfo;
        
        Prompt_Information__c newPromptInfo1 = TestDataFactory.createPromptInformation(Constants.M2_METMAST_STATION_BUILD, null, newTemVersion.Id);
        newPromptInfo1.Type__c = Constants.MET_MAST;
        insert newPromptInfo1;
        
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Text','Number','Text','Text'};
            list<String>coreAttrNameLst = new list<String>{'Test','t1','t2','t4'};
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
        list<String>promptSpecificAttrNameLst = new list<String>{'Station Name','Device Type','Device Name'};
            
            for(integer i = 0; i < 3; i++){
                Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                                'Prompt Specific',
                                                                                                'Text',
                                                                                                promptCoreAttrRTId,
                                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                                newPromptInfo1.Id, newTemVersion.Id);
                promptSpecificAttrLst.add(promptSpecificAttr);
            }
        insert promptSpecificAttrLst;
        
        Core_Attribute__c promptSpecificAttributeAlarm = TestDataFactory.createPromptSpecificAttr('Hail',
                                                                                                  'Metadata',
                                                                                                  'Text',
                                                                                                  promptCoreAttrRTId,
                                                                                                  null,
                                                                                                  newPromptInfo.Id, newTemVersion.Id);
        promptSpecificAttributeAlarm.Sensor_Type__c = 'Metmast';
        promptSpecificAttributeAlarm.Base_Asset_Name__c = newBaseAssetTemplate.Id;
        insert promptSpecificAttributeAlarm;
        
        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 2; i++){
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
        newG1SiteMetadata.Prompt_Specific_Info__c = '{\"Met Mast\":\"0\",\"Switchgear Substation\":\"2\"}';
        newG1SiteMetadata.Attribute_Info__c = '{}';
        insert newG1SiteMetadata;

        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ newPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = newPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        insert plantAssetPromptDetail;

        Site_Metadata__c m1SiteMetaData = new Site_Metadata__c(); 
        m1SiteMetaData.Name = Constants.M1_MET_MAST_STATION_BUILD;
        m1SiteMetaData.Prompt_Specific_Info__c = '{\"Station Name\":\"Station Name1\",\"Hail\":\"1\",\"Dew Point\":\"1\",\"Inverter\":\"3\"}';
        m1SiteMetaData.Attribute_Info__c = '{\"Barometric\":\"1\",\"Dew Point\":\"7\"}';
        m1SiteMetaData.Account_Plant__c= newPlantAsset.id;
        m1SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert m1SiteMetaData;

        Boolean isKeyToGenerateRows = false;

        Map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'true', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
        Map<String, String> additionalParmsForFindNextPromptMap= new Map<String, String>{'isReadOnly' => 'false'};
        String additionalParamsForFindNextPrompt = JSON.serialize(additionalParmsForFindNextPromptMap);

        //Row Generation Check
        String dataTableInput = M2MetMastStationBuild.getCustomDatatableCompInput(newPlantAsset.Id, plantAssetPromptDetail.Id, False, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, newPlantAsset.Id);
        System.assertEquals(1, currentPromptSiteMetadata.size());
        
        Site_Metadata__c m1SiteMetaDataAdd = new Site_Metadata__c(); 
        m1SiteMetaDataAdd.Name = Constants.M1_MET_MAST_STATION_BUILD;
        m1SiteMetaDataAdd.Prompt_Specific_Info__c = '{\"Station Name\":\"Station Name1\",\"Hail\":\"1\",\"Dew Point\":\"1\",\"Inverter\":\"3\"}';
        m1SiteMetaDataAdd.Attribute_Info__c = '{\"Barometric\":\"1\",\"Dew Point\":\"7\"}';
        m1SiteMetaDataAdd.Account_Plant__c= newPlantAsset.id;
        m1SiteMetaDataAdd.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail.Id;
        insert m1SiteMetaDataAdd;
        
        String m2DataTableInput = M2MetMastStationBuild.getCustomDatatableCompInput(newPlantAsset.Id, plantAssetPromptDetail.Id, False, JSON.serialize(jsonInputParametersAndValuesMap));
        List<Site_Metadata__c> m2PromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, newPlantAsset.Id);
        System.assertEquals(2, m2PromptSiteMetadata.size());
        
        //Next Prompt Id Check
        String siteMetadataRecords = JSON.serialize(currentPromptSiteMetadata);
                String nextResponse = M2MetMastStationBuild.findNextPromptId(newPlantAsset.Id, siteMetadataRecords, isKeyToGenerateRows, true, additionalParamsForFindNextPrompt, true);
        Map<String,String> nextPromptResponse = (Map<String,String>) JSON.deserialize(nextResponse, Map<String,String>.class);
        String nextPrompt = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals('The Next or Previous prompt is not found, Please contact admnistrator.', nextPrompt);

        //Save SiteMetaData Check 
        
        String barometricAttrName = 'Barometric';
        map<String,String> promptSpecificInfoMap = 
                    (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        promptSpecificInfoMap.put(barometricAttrName,'1');
        currentPromptSiteMetadata[0].Prompt_Specific_Info__c = JSON.serialize(promptSpecificInfoMap);
        String siteMetadataRecordSaveCheck = JSON.serialize(currentPromptSiteMetadata);
        Test.startTest();
        Boolean saveDataCheck = M2MetMastStationBuild.saveSiteMetadataRecords(siteMetadataRecordSaveCheck, newPlantAsset.Id, isKeyToGenerateRows, true, true);
        List<Site_Metadata__c> savedPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, newPlantAsset.Id);
        map<String,String> promptSpecificInfoMapSaveCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c,Map<String, String>.class);
        String updatedBarometricName = promptSpecificInfoMapSaveCheck.containsKey(barometricAttrName)?promptSpecificInfoMapSaveCheck.get(barometricAttrName):'';
        System.assertEquals('1', updatedBarometricName);
       
        //Clear SiteMetadata Check
        String clearDataCheck = M2MetMastStationBuild.clearPromptInfo(newPlantAsset.Id, plantAssetPromptDetail.Id);
        map<String,String> promptSpecificInfoMapClearCheck = 
            (Map<String, String>) System.JSON.deserialize(currentPromptSiteMetadata[0].Prompt_Specific_Info__c, Map<String, String>.class);
        String clearValue = promptSpecificInfoMapClearCheck.get(barometricAttrName);
        String clearedstationNameCheck = promptSpecificInfoMapClearCheck.containsKey(barometricAttrName)?promptSpecificInfoMapClearCheck.get(barometricAttrName):'';
        System.assertEquals('1', clearedstationNameCheck); 
        Test.stopTest();

    }
}