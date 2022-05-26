/**
**/
@isTest
public with sharing class WeightedAverageRollupTest {
/*    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Plant_Asset__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        List<Id> baseAssLst = new List<Id>();
        Base_Asset_Template__c basePvPlant = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert basePvPlant;
        baseAssLst.add(basePvPlant.Id);
		
        Base_Asset_Template__c genericSubarray = TestDataFactory.createBaseAssetTemplate(Constants.BASE_SUBARRAY, newTemVersion.Id);
        insert genericSubarray;
        baseAssLst.add(genericSubarray.Id);

        List<Id> promptInfoLst = new List<Id>();
        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR, basePvPlant.Id, newTemVersion.Id);
        p1PromptInfo.Is_Plant_Information_Prompt__c = true;
        insert p1PromptInfo;
        promptInfoLst.add(p1PromptInfo.Id);
        
        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        basePvPlant.Id, newTemVersion.Id);
        insert g1PromptInfo;
        
        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = basePvPlant.Id;
        insert g1PlantAssetPromptDetail;
        
        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"Renewable Type":"Solar - PV"}';
        p1SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p1SiteMetaData.Base_Asset_Template__c = basePvPlant.id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        p1SiteMetaData.Prompt_Information__c = g1PromptInfo.Id;
        insert p1SiteMetaData;
        
        Prompt_Information__c p7PromptInfo = TestDataFactory.createPromptInformation(Constants.P7_INVERTER_SUBARRAY_INFO, genericSubarray.Id, newTemVersion.Id);
        insert p7PromptInfo; 
        promptInfoLst.add(p7PromptInfo.Id);
        
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster(Constants.FLAT_HIERARCHY, newTemVersion.Id);

        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
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
            baseAttrLst.add(baseAttr);
        }
        insert baseAttrLst;

        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Decimal','Decimal','Decimal'};
        list<String>coreAttrNameLst = new list<String>{'MODULE_TCOEFF','MOUNTING_GCR','MOUNTING_TILT'};
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
                    coreAttr.Rollup_To_Parent__c = p1PromptInfo.Id;
                    coreAttr.Base_Attribute_For_Weighted_Average_Calc__c = baseAttrLst[1].Id;
                }
                coreAttrLst.add(coreAttr);
            }
        }
        insert coreAttrLst;
        coreAttrLst.addAll(baseAttrLst);
        
        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < coreAttrLst.size(); i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }
    }
    @isTest
    public static void weightedAvgTest1(){
        //for single base asset template
		Plant_Asset__c plantAssetForWeightedAvg = [SELECT Id, Name,TEM_Version__c FROM Plant_Asset__c WHERE Customer_Plant_Asset_ID__c = '7777.77.777' LIMIT 1];
        Prompt_Information__c p1PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P1_PLANT_INFO_PROMPT_SOLAR AND TEM_Version__c =: plantAssetForWeightedAvg.TEM_Version__c ];
        Prompt_Information__c p7PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P7_INVERTER_SUBARRAY_INFO AND TEM_Version__c =: plantAssetForWeightedAvg.TEM_Version__c];
        List<Id> promptInfoLst = new List<Id>();
        promptInfoLst.add(p7PromptInfo.Id);
        Base_Asset_Template__c basePvPlant = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_PV_PLANT AND TEM_Version__c =: plantAssetForWeightedAvg.TEM_Version__c];
        Base_Asset_Template__c baseSubarray = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =:Constants.BASE_SUBARRAY AND TEM_Version__c =: plantAssetForWeightedAvg.TEM_Version__c];
        List<Core_Attribute__c> coreAttrLst  = [SELECT Id, Name, Base_Attribute_For_Weighted_Average_Calc__c FROM Core_Attribute__c WHERE Base_Asset_Name__c =: baseSubarray.Id AND TEM_Version__c =: plantAssetForWeightedAvg.TEM_Version__c];
        
        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = plantAssetForWeightedAvg.Name +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Plant_Asset__c = plantAssetForWeightedAvg.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = basePvPlant.Id;
        insert p1PlantAssetPromptDetail;

        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '';
        p1SiteMetaData.Attribute_Info__c = '{"DC_Capacity":"","MODULE_TCOEFF":"","MOUNTING_GCR":"","MOUNTING_TILT":""}';
        p1SiteMetaData.Plant_Asset__c= plantAssetForWeightedAvg.id;
        p1SiteMetaData.Base_Asset_Template__c = basePvPlant.id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
        p1SiteMetaData.Prompt_Information__c = p1PromptInfo.Id;
        insert p1SiteMetaData;  
        
        Plant_Asset_Prompt_Detail__c p7PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p7PlantAssetPromptDetail.Name = plantAssetForWeightedAvg.Name +'-'+ p1PromptInfo.Name;
        p7PlantAssetPromptDetail.Plant_Asset__c = plantAssetForWeightedAvg.Id;
        p7PlantAssetPromptDetail.Prompt_Information__c = p7PromptInfo.Id;
        p7PlantAssetPromptDetail.Base_Asset__c = baseSubarray.Id;
        insert p7PlantAssetPromptDetail;
		
        List<Id> siteMetadataLst = new List<Id>();
        Site_Metadata__c p7SiteMetaData1 = new Site_Metadata__c(); 
        p7SiteMetaData1.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p7SiteMetaData1.Prompt_Specific_Info__c = '';
        p7SiteMetaData1.Attribute_Info__c = '{"DC_Capacity":"","MODULE_TCOEFF":"","MOUNTING_GCR":"","MOUNTING_TILT":""}';
        p7SiteMetaData1.Plant_Asset__c= plantAssetForWeightedAvg.id;
        p7SiteMetaData1.Base_Asset_Template__c = baseSubarray.id;
        p7SiteMetaData1.Plant_Asset_Prompt_Detail__c = p7PlantAssetPromptDetail.Id;
        p7SiteMetaData1.Prompt_Information__c = p7PromptInfo.Id;
        insert p7SiteMetaData1;  
        siteMetadataLst.add(p7SiteMetaData1.Id);
        
        Site_Metadata__c p7SiteMetaData2 = new Site_Metadata__c(); 
        p7SiteMetaData2.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p7SiteMetaData2.Prompt_Specific_Info__c = '';
        p7SiteMetaData2.Attribute_Info__c = '{"DC_Capacity":"","MODULE_TCOEFF":"","MOUNTING_GCR":"","MOUNTING_TILT":""}';
        p7SiteMetaData2.Plant_Asset__c= plantAssetForWeightedAvg.id;
        p7SiteMetaData2.Base_Asset_Template__c = baseSubarray.id;
        p7SiteMetaData2.Plant_Asset_Prompt_Detail__c = p7PlantAssetPromptDetail.Id;
        p7SiteMetaData2.Prompt_Information__c = p7PromptInfo.Id;
        insert p7SiteMetaData2; 
        siteMetadataLst.add(p7SiteMetaData2.Id);
        
        Site_Metadata__c p7SiteMetaData3 = new Site_Metadata__c(); 
        p7SiteMetaData3.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p7SiteMetaData3.Prompt_Specific_Info__c = '';
        p7SiteMetaData3.Attribute_Info__c = '{"DC_Capacity":"","MODULE_TCOEFF":"","MOUNTING_GCR":"","MOUNTING_TILT":""}';
        p7SiteMetaData3.Plant_Asset__c= plantAssetForWeightedAvg.id;
        p7SiteMetaData3.Base_Asset_Template__c = baseSubarray.id;
        p7SiteMetaData3.Plant_Asset_Prompt_Detail__c = p7PlantAssetPromptDetail.Id;
        p7SiteMetaData3.Prompt_Information__c = p7PromptInfo.Id;
        insert p7SiteMetaData3; 
		siteMetadataLst.add(p7SiteMetaData3.Id);    
        
        Site_Metadata__c p7SiteMetaData4 = new Site_Metadata__c(); 
        p7SiteMetaData4.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p7SiteMetaData4.Prompt_Specific_Info__c = '';
        p7SiteMetaData4.Attribute_Info__c = '{"DC_Capacity":"","MODULE_TCOEFF":"","MOUNTING_GCR":"","MOUNTING_TILT":""}';
        p7SiteMetaData4.Plant_Asset__c= plantAssetForWeightedAvg.id;
        p7SiteMetaData4.Base_Asset_Template__c = baseSubarray.id;
        p7SiteMetaData4.Plant_Asset_Prompt_Detail__c = p7PlantAssetPromptDetail.Id;
        p7SiteMetaData4.Prompt_Information__c = p7PromptInfo.Id;
        insert p7SiteMetaData4; 
        siteMetadataLst.add(p7SiteMetaData4.Id); 
        
        List<Attribute_Value__c> attrValueLst = new List<Attribute_Value__c>();
        for(Integer i=0; i< siteMetadataLst.size(); i++){
            for(integer j = 0; j < coreAttrLst.size(); j++){
                Attribute_Value__c attributeValue = new Attribute_Value__c();
                attributeValue.Plant_Asset__c = plantAssetForWeightedAvg.Id;
                attributeValue.Site_Metadata__c = siteMetadataLst[i];
                attributeValue.Prompt_Information__c = p7PromptInfo.Id; 
                attributeValue.Base_Asset_Template__c = baseSubarray.id;
                attributeValue.Value__c = (i/2) == 0 ? '3.3' : '1.1';
                attributeValue.Attribute__c = coreAttrLst[j].Id;
                attrValueLst.add(attributeValue);
            }
        }
        insert attrValueLst;
   
        WeightedAverageRollup.formMapForRollup(promptInfoLst, System.now(), String.valueOf(p7PlantAssetPromptDetail.Id), String.valueOf(plantAssetForWeightedAvg.id));
        
    }*/
}