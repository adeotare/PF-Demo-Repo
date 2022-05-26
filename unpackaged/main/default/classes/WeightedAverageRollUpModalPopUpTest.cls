@istest
public with sharing class WeightedAverageRollUpModalPopUpTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        newPlantAsset.TEM_Version__c = newTemVersion.Id;
        insert newPlantAsset;

        List<Id> baseAssLst = new List<Id>();
        Base_Asset_Template__c basePvPlant = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert basePvPlant;
        baseAssLst.add(basePvPlant.Id);
        
        Base_Asset_Template__c windBAT = TestDataFactory.createBaseAssetTemplate(Constants.BASE_WIND_PLANT, newTemVersion.Id);
        insert windBAT;
        baseAssLst.add(windBAT.Id);
        
		Base_Asset_Template__c genericSubarray = TestDataFactory.createBaseAssetTemplate(Constants.BASE_SUBARRAY, newTemVersion.Id);
        insert genericSubarray;
        baseAssLst.add(genericSubarray.Id);

        List<Id> promptInfoLst = new List<Id>();
        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR, basePvPlant.Id, newTemVersion.Id);
        p1PromptInfo.Is_Plant_Information_Prompt__c = true;
        p1PromptInfo.Type__c = Constants.SOLAR;
        insert p1PromptInfo;
        promptInfoLst.add(p1PromptInfo.Id);
        
        Prompt_Information__c w1PromptInfo = TestDataFactory.createPromptInformation(Constants.W1_PLANT_INFO_PROMPT_WIND, windBAT.Id, newTemVersion.Id);
        w1PromptInfo.Is_Plant_Information_Prompt__c = true;
        w1PromptInfo.Type__c = Constants.WIND;
        insert w1PromptInfo;
        promptInfoLst.add(w1PromptInfo.Id);
        
        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        basePvPlant.Id, newTemVersion.Id);
        insert g1PromptInfo;
        
        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = basePvPlant.Id;
        insert g1PlantAssetPromptDetail;
        
        Prompt_Information__c p7PromptInfo = TestDataFactory.createPromptInformation(Constants.P7_INVERTER_SUBARRAY_INFO, genericSubarray.Id, newTemVersion.Id);
        insert p7PromptInfo; 
        promptInfoLst.add(p7PromptInfo.Id);
        
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster(Constants.FLAT_HIERARCHY, newTemVersion.Id);

        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Attribute_Master__c attributeMaster = new Attribute_Master__c();
        attributeMaster.Name = 'attrMaster';
        attributeMaster.Type__c = 'Metadata';
        attributeMaster.TEM_Version__c = newTemVersion.Id;
        attributeMaster.Alias__c = 'AC Capacity';
        attributeMaster.Data_Type__c = 'Decimal';
        insert attributeMaster;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c', 'Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records  {"DC_Capacity":"","MODULE_TCOEFF":"","MOUNTING_GCR":"","MOUNTING_TILT":""}
        List<Core_Attribute__c> baseAttrLst  = new List<Core_Attribute__c> ();
        for(integer i = 0; i < 2; i++){
       		Core_Attribute__c baseAttr = TestDataFactory.createCoreAttribute('DC_Capacity',
                                                                             'Metadata',
                                                                             'Decimal',
                                                                             coreAttrRTId,
                                                                             null,
                                                                             baseAssLst[i], newTemVersion.Id);
            baseAttr.Attribute_Master__c = attributeMaster.Id;
            baseAttrLst.add(baseAttr);
        }
        insert baseAttrLst;
        
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Decimal','Decimal'};
        list<String>coreAttrNameLst = new list<String>{'MODULE_TCOEFF','MOUNTING_GCR'};
        for(integer i = 0; i < 2; i++){
            for(integer j = 0; j < coreAttrNameLst.size(); j++){
                Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[j],
                                                                                'Metadata',
                                                                                datatypeLst[j],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[j] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                baseAssLst[i], newTemVersion.Id);
                if(i == 1){
                    coreAttr.Is_Rollup_To_P1_W1__c = true;
                    coreAttr.Rollup_To_Parent__c = promptInfoLst[j];
                    coreAttr.Base_Attribute_For_Weighted_Average_Calc__c = baseAttrLst[1].Id;
                    coreAttr.Attribute_Master__c = attributeMaster.Id;
                }
                coreAttrLst.add(coreAttr);
            }
        }
        insert coreAttrLst;
        coreAttrLst.addAll(baseAttrLst);
        
        //for Prompt Specific records
        List<Core_Attribute__c> promptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptDataTypeLst = new list<String>{'Text','Text','Picklist'};
        list<String>promptSpecificAttrNameLst = new list<String>{'Plant Name','Plant ID','Flat Hierarchy'};
        
        Attribute_Master__c attributeMasterPrompt = new Attribute_Master__c();
        attributeMasterPrompt.Name = Constants.DRIVE_PLUS;
        attributeMasterPrompt.Type__c = 'Prompt Specific';
        attributeMasterPrompt.TEM_Version__c = newTemVersion.Id;
        attributeMasterPrompt.Alias__c = 'AC Capacity';
        insert attributeMasterPrompt;

        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                'Text',
                                                                                promptCoreAttrRTId,
                                                                                (promptDataTypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptInfo.Id, newTemVersion.Id);
                                                                                
            promptSpecificAttr.Attribute_Master__c=attributeMasterPrompt.id;
            promptSpecificAttr.Plant_Asset_Field_Name__c = 'PF_Service_Product__c'; 
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        
        //insert promptSpecificAttrLst;
        
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                'Text',
                                                                                promptCoreAttrRTId,
                                                                                (promptDataTypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                w1PromptInfo.Id, newTemVersion.Id);
            promptSpecificAttr.Attribute_Master__c=attributeMasterPrompt.id;
            promptSpecificAttr.Plant_Asset_Field_Name__c ='PF_Service_Product__c';
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst;
		
        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;
    }
    
    public static testMethod void p1PlantInfoTest(){
        Account_Plant__c plantAsset = [SELECT Id, Name, Asset_Builder_Status__c, AB_Approval_Status__c FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'];
		Id baseAssetTemplate = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_PV_PLANT].Id;
        map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true','isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
		Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = [SELECT id,Is_WA_RollUp_Not_Executed__c
            FROM Plant_Asset_Prompt_Detail__c
            WHERE Account_Plant__c =: plantAsset.Id AND 
            Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND 
            Is_Deleted__c = FALSE LIMIT 1];

        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"Switchgear Substation":"3","Metmast":"2","PF Service Product":"Drive;FSM","Renewable Type":"Solar - PV"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Base_Asset_Template__c = baseAssetTemplate;
        g1SiteMetaData.Account_Plant__c = plantAsset.Id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;
        
        string result = WeightedAverageRollUpModalPopUp.getCustomDatatableCompInput(plantAsset.Id,JSON.serialize(jsonInputParametersAndValuesMap));
    	
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAsset.Id);
        Boolean updatedresult = WeightedAverageRollUpModalPopUp.saveSiteMetadataRecords(JSON.serialize(currentPromptSiteMetadata));
        
        plantAsset.Asset_Builder_Status__c = 'In-Progress';
        plantAsset.AB_Approval_Status__c = '';
        update plantAsset;
        String plantAssetDetail = WeightedAverageRollUpModalPopUp.plantAssetDetails(plantAsset.Id);
        
        plantAsset.Asset_Builder_Status__c = 'Completed';
        plantAsset.AB_Approval_Status__c = '';
        update plantAsset;
        String plantAssetDetailcompleted = WeightedAverageRollUpModalPopUp.plantAssetDetails(plantAsset.Id);
    }
    
    public static testMethod void w1PlantInfoTest(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
		Id baseAssetTemplate = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_PV_PLANT].Id;
        map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'true','isBulkUploadMultipleBAT' => 'false', 'isImpWizUpLoad' => 'false', 'isOverride' => 'false'};
		Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = [SELECT id,Is_WA_RollUp_Not_Executed__c
            FROM Plant_Asset_Prompt_Detail__c
            WHERE Account_Plant__c =: plantAsset AND 
            Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND 
            Is_Deleted__c = FALSE LIMIT 1];

        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"Switchgear Substation":"3","Metmast":"2","PF Service Product":"Drive;FSM","Renewable Type":"Wind - Onshore"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Base_Asset_Template__c = baseAssetTemplate;
        g1SiteMetaData.Account_Plant__c = plantAsset;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;
        
        string result = WeightedAverageRollUpModalPopUp.getCustomDatatableCompInput(plantAsset,JSON.serialize(jsonInputParametersAndValuesMap));
    }
}