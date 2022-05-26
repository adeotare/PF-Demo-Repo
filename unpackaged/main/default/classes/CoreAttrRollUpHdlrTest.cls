/**
**/
@isTest
public with sharing class CoreAttrRollUpHdlrTest {
/*    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Plant_Asset__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c p1PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert p1PromptBaseAsset;

        Base_Asset_Template__c p2PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_BLOCK, newTemVersion.Id);
        insert p2PromptBaseAsset;

        Prompt_Information__c p2PromptInfo = TestDataFactory.createPromptInformation(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS,
                                                p2PromptBaseAsset.Id, newTemVersion.Id);
        insert p2PromptInfo;
		
        Prompt_Information__c g1PromptInfo = new Prompt_Information__c();
        g1PromptInfo.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT  ;
        g1PromptInfo.TEM_Version__c = newTemVersion.Id;
        insert g1PromptInfo;
        
        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                p1PromptBaseAsset.Id, newTemVersion.Id);
        insert p1PromptInfo;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster(Constants.FLAT_HIERARCHY, newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        g1PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        insert g1PlantAssetPromptDetail;

        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c', 'Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number','Decimal'};
        list<String>coreAttrNameLst = new list<String>{'AC_CAPACITY','DC_CAPACITY'};
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptBaseAsset.Id, newTemVersion.Id);
            coreAttr.Is_Rollup__c = true;                                                                    
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;

        List<Core_Attribute__c> coreAttrLstP2  = new List<Core_Attribute__c> ();
        list<String>datatypeLstP2 = new list<String>{'Number','Decimal'};
        list<String>coreAttrNameLstP2 = new list<String>{'AC_CAPACITY','DC_CAPACITY'};
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLstP2[i],
                                                                                'Metadata',
                                                                                datatypeLstP2[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLstP2[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p2PromptBaseAsset.Id, newTemVersion.Id);
            coreAttr.Is_Rollup__c = true; 
            coreAttrLstP2.add(coreAttr);
        }
        insert coreAttrLstP2;
        
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
        //for second prompt
        List<Core_Attribute__c> promptSpecificAttrLst2  = new List<Core_Attribute__c> ();
        list<String>datatypeLstPrompt2 = new list<String>{'Text','Number'};
        list<String>promptSpecificAttrNameLst2 = new list<String>{'Block Name', 'Pad Count'};
        
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst2[i],
                                                                                'Prompt Specific',
                                                                                datatypeLstPrompt2[i],
                                                                                promptCoreAttrRTId,
                                                                                (datatypeLstPrompt2[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p2PromptInfo.Id, newTemVersion.Id);                                                            
            promptSpecificAttrLst2.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst2;

        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 2; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;
        List<Attribute_Requirement__c> attrReqLst2  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 2; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLstP2[i].Id, newTemVersion.Id);
            attrReqLst2.add(attrReq);
        }
        insert attrReqLst2;

        String promptSpecificInfoJSON = JSON.serialize('{"No of Blocks":"2","Flat Hierarchy":"No"');
        String coreAttributeInfoJSON = JSON.serialize('{"AC_CAPACITY":"","DC_CAPACITY":""}');

       
    }
    @isTest
    public static void rollUpTest1(){
		
        Plant_Asset__c newPlantAsset = [SELECT Id, Name FROM Plant_Asset__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777' LIMIT 1];
        Prompt_Information__c p1PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P1_PLANT_INFO_PROMPT_SOLAR LIMIT 1];
        Prompt_Information__c p2PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P2_BLOCK_INFO_AND_PAD_COUNTS LIMIT 1];
        Base_Asset_Template__c p1PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_PV_PLANT LIMIT 1];
        Base_Asset_Template__c p2PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =:Constants.BASE_BLOCK LIMIT 1];
        
        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        insert p1PlantAssetPromptDetail;
        
        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p1SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"","DC_CAPACITY":""}';
        p1SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p1SiteMetaData.Base_Asset_Template__c = p1PromptBaseAsset.id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
        insert p1SiteMetaData;
        
        Plant_Asset_Prompt_Detail__c p2PlantAssetPromptDetailA = new Plant_Asset_Prompt_Detail__c();
        p2PlantAssetPromptDetailA.Plant_Asset__c = newPlantAsset.Id;
        p2PlantAssetPromptDetailA.Prompt_Information__c = p2PromptInfo.Id;
        p2PlantAssetPromptDetailA.Base_Asset__c = p2PromptBaseAsset.Id;
        insert p2PlantAssetPromptDetailA;

        Site_Metadata__c p2SiteMetaDataA = new Site_Metadata__c(); 
        p2SiteMetaDataA.Name = Constants.P2_BLOCK_INFO_AND_PAD_COUNTS;
        p2SiteMetaDataA.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p2SiteMetaDataA.Attribute_Info__c = '{"AC_CAPACITY":"100","DC_CAPACITY":"100.19"}';
        p2SiteMetaDataA.Plant_Asset__c= newPlantAsset.id;
        p2SiteMetaDataA.Base_Asset_Template__c = p2PromptBaseAsset.id;
        p2SiteMetaDataA.Parent_Site_Metadata__c = p1SiteMetaData.id;
        p2SiteMetaDataA.Plant_Asset_Prompt_Detail__c = p2PlantAssetPromptDetailA.Id;
        insert p2SiteMetaDataA;

        Plant_Asset_Prompt_Detail__c p2PlantAssetPromptDetailB = new Plant_Asset_Prompt_Detail__c();
        p2PlantAssetPromptDetailB.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        p2PlantAssetPromptDetailB.Plant_Asset__c = newPlantAsset.Id;
        p2PlantAssetPromptDetailB.Prompt_Information__c = p2PromptInfo.Id;
        p2PlantAssetPromptDetailB.Base_Asset__c = p2PromptBaseAsset.Id;
        insert p2PlantAssetPromptDetailB;


        Site_Metadata__c p2SiteMetaDataB = new Site_Metadata__c(); 
        p2SiteMetaDataB.Name = Constants.P2_BLOCK_INFO_AND_PAD_COUNTS;
        p2SiteMetaDataB.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p2SiteMetaDataB.Attribute_Info__c = '{"AC_CAPACITY":"100","DC_CAPACITY":"100.19"}';
        p2SiteMetaDataB.Plant_Asset__c= newPlantAsset.id;
        p2SiteMetaDataB.Base_Asset_Template__c = p2PromptBaseAsset.id;
        p2SiteMetaDataB.Parent_Site_Metadata__c = p1SiteMetaData.id;
        p2SiteMetaDataB.Plant_Asset_Prompt_Detail__c = p2PlantAssetPromptDetailB.Id;
        insert p2SiteMetaDataB;

        //updation
        List<Site_Metadata__c> allSiteMetaData = Utils.querySiteMetadata(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS, newPlantAsset.Id);
        List<Id> promptInfoIdLst = new List<Id>();
        for(Site_Metadata__c siteMetaDataInstance : allSiteMetaData){
            promptInfoIdLst.add(siteMetaDataInstance.Prompt_Information__c); 
        } 
        //Check the rollup using insert sitemetadata
        CoreAttrRollUpHdlr.afterUpdateSiteMetaData(promptInfoIdLst, System.now(), String.valueOf(p2PlantAssetPromptDetailA.Id), String.valueOf(newPlantAsset.id) );
        
        List<Site_Metadata__c> parentSiteMetaData = Utils.querySiteMetadata(Constants.P1_PLANT_INFO_PROMPT_SOLAR, newPlantAsset.Id);
        Map<String,String> attrInforList2 = (Map<String,String>)JSON.deserialize(parentSiteMetaData[0].Attribute_Info__c,Map<String,String>.class);
        if(attrInforList2.containsKey('AC_CAPACITY')){
            System.debug(attrInforList2.get('AC_CAPACITY'));
            System.assertEquals(attrInforList2.get('AC_CAPACITY'),'200');
            System.assertEquals(attrInforList2.get('DC_CAPACITY'),'200.38');
        }
    }*/
}