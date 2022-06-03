/**
**/
@isTest
public class SiteMetaDataHandlerTest {
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
        
        Base_Asset_Template__c p3PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER_PAD, newTemVersion.Id);
        insert p3PromptBaseAsset;
        
        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                p1PromptBaseAsset.Id, newTemVersion.Id);
        insert p1PromptInfo;

        Prompt_Information__c p2PromptInfo = TestDataFactory.createPromptInformation(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS,
                                                p2PromptBaseAsset.Id, newTemVersion.Id);
        insert p2PromptInfo; 
        
        Prompt_Information__c p3PromptInfo = TestDataFactory.createPromptInformation(Constants.P3_PAD_BUILDS_AND_COUNTS,
                                                p3PromptBaseAsset.Id, newTemVersion.Id);
        insert p3PromptInfo;
        
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster(Constants.FLAT_HIERARCHY, newTemVersion.Id);

        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c', 'Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number'};
        list<String>coreAttrNameLst = new list<String>{'AC_CAPACITY'};
        for(integer i = 0; i < 1; i++){
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
        list<String>datatypeLstP2 = new list<String>{'Number'};
        list<String>coreAttrNameLstP2 = new list<String>{'AC_CAPACITY'};
        for(integer i = 0; i < 1; i++){
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
        for(integer i = 0; i < 1; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;
        List<Attribute_Requirement__c> attrReqLst2  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 1; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLstP2[i].Id, newTemVersion.Id);
            attrReqLst2.add(attrReq);
        }
        insert attrReqLst2;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        insert p1PlantAssetPromptDetail;

        String promptSpecificInfoJSON = JSON.serialize('{"No of Blocks":"2","Flat Hierarchy":"No"');
        String coreAttributeInfoJSON = JSON.serialize('{"AC_CAPACITY":""}');

        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p1SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":""}';
        p1SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p1SiteMetaData.Base_Asset_Template__c = p1PromptBaseAsset.id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
        p1SiteMetaData.Prompt_Information__c = p1PromptInfo.Id;
        insert p1SiteMetaData;      
        
    }
    @isTest
    public static void siteMetaDataTriggerTest1(){
		//for single base asset template
        Plant_Asset__c newPlantAsset = [SELECT Id, Name,TEM_Version__c FROM Plant_Asset__c WHERE Customer_Plant_Asset_ID__c = '7777.77.777' LIMIT 1];
        Prompt_Information__c p1PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P1_PLANT_INFO_PROMPT_SOLAR AND TEM_Version__c =: newPlantAsset.TEM_Version__c ];
        Prompt_Information__c p2PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P2_BLOCK_INFO_AND_PAD_COUNTS AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        Prompt_Information__c p3PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P3_PAD_BUILDS_AND_COUNTS AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        Base_Asset_Template__c p1PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_PV_PLANT AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        Base_Asset_Template__c p2PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =:Constants.BASE_BLOCK AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        Base_Asset_Template__c p3PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =:Constants.BASE_INVERTER_PAD AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        String name = 'Test Plant'+'-'+ p1PromptInfo.Name;
        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = [SELECT Id, Name FROM Plant_Asset_Prompt_Detail__c WHERE Name =: name LIMIT 1];
        
        Plant_Asset_Prompt_Detail__c p2PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p2PlantAssetPromptDetail.Name = 'Test Plant'+'-'+p2PromptInfo.Id;
        p2PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        p2PlantAssetPromptDetail.Prompt_Information__c = p2PromptInfo.Id;
        p2PlantAssetPromptDetail.Base_Asset__c = p2PromptBaseAsset.Id;
        insert p2PlantAssetPromptDetail;

        Site_Metadata__c p2SiteMetaData = new Site_Metadata__c(); 
        p2SiteMetaData.Name = Constants.P2_BLOCK_INFO_AND_PAD_COUNTS;
        p2SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p2SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"100"}';
        p2SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p2SiteMetaData.Base_Asset_Template__c = p2PromptBaseAsset.Id;
        p2SiteMetaData.Plant_Asset_Prompt_Detail__c = p2PlantAssetPromptDetail.Id;
        p2SiteMetaData.Prompt_Information__c = p2PromptInfo.Id;
        insert p2SiteMetaData;
        
        
        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p3PromptInfo.Name;
        p3PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = p3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = p3PromptBaseAsset.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p3SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"1200"}';
        p3SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p3SiteMetaData.Base_Asset_Template__c = p3PromptBaseAsset.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        p3SiteMetaData.Prompt_Information__c = p3PromptInfo.Id;
        insert p3SiteMetaData;
        
        Site_Metadata__c p4SiteMetaData = new Site_Metadata__c(); 
        p4SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p4SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p4SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"1300"}';
        p4SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p4SiteMetaData.Base_Asset_Template__c = p3PromptBaseAsset.Id;
        p4SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        p4SiteMetaData.Prompt_Information__c = p3PromptInfo.Id;
        insert p4SiteMetaData;
        
        Site_Metadata__c p5SiteMetaData = new Site_Metadata__c(); 
        p5SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p5SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p5SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"1400"}';
        p5SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p5SiteMetaData.Base_Asset_Template__c = p3PromptBaseAsset.Id;
        p5SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        p5SiteMetaData.Prompt_Information__c = p3PromptInfo.Id;
        insert p5SiteMetaData;
        
        List<Site_Metadata__c> allSiteMetaData = Utils.querySiteMetadata(p3PromptInfo.Name, newPlantAsset.Id);
        System.debug(allSiteMetaData.size());
        List<Id> siteMetaDataIdLst = new List<Id>();

        for(Site_Metadata__c siteMetaDataInstance : allSiteMetaData){
            siteMetaDataInstance.Is_Attribute_Value_Modified_in_Prompt__c = true;
            Map<String,String> attrInforList = (Map<String,String>)JSON.deserialize(siteMetaDataInstance.Attribute_Info__c,Map<String,String>.class);
            for(String strInstance : attrInforList.keyset()){
                    attrInforList.remove(strInstance);
                    attrInforList.put(strInstance,String.valueOf(400));
            }
            siteMetaDataInstance.Attribute_Info__c = JSON.serialize(attrInforList);  
            siteMetaDataIdLst.add(siteMetaDataInstance.Id);
        }
        update allSiteMetaData;
    }
    @isTest
    public static void siteMetaDataTriggerTest2(){
		//For multiple base asset template
        Plant_Asset__c newPlantAsset = [SELECT Id, Name,TEM_Version__c FROM Plant_Asset__c WHERE Customer_Plant_Asset_ID__c = '7777.77.777' LIMIT 1];
        Prompt_Information__c p1PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P1_PLANT_INFO_PROMPT_SOLAR AND TEM_Version__c =: newPlantAsset.TEM_Version__c ];
        Prompt_Information__c p2PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P2_BLOCK_INFO_AND_PAD_COUNTS AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        Prompt_Information__c p3PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE Name =: Constants.P3_PAD_BUILDS_AND_COUNTS AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        Base_Asset_Template__c p1PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =: Constants.BASE_PV_PLANT AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        Base_Asset_Template__c p2PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =:Constants.BASE_BLOCK AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        Base_Asset_Template__c p3PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE Name =:Constants.BASE_INVERTER_PAD AND TEM_Version__c =: newPlantAsset.TEM_Version__c];
        String name = 'Test Plant'+'-'+ p1PromptInfo.Name;
        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = [SELECT Id, Name FROM Plant_Asset_Prompt_Detail__c WHERE Name =: name LIMIT 1];
        
        Plant_Asset_Prompt_Detail__c p2PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p2PlantAssetPromptDetail.Name = 'Test Plant'+'-'+p2PromptInfo.Id;
        p2PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        p2PlantAssetPromptDetail.Prompt_Information__c = p2PromptInfo.Id;
        p2PlantAssetPromptDetail.Base_Asset__c = p2PromptBaseAsset.Id;
        insert p2PlantAssetPromptDetail;

        Site_Metadata__c p2SiteMetaData = new Site_Metadata__c(); 
        p2SiteMetaData.Name = Constants.P2_BLOCK_INFO_AND_PAD_COUNTS;
        p2SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p2SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"100"}';
        p2SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p2SiteMetaData.Base_Asset_Template__c = p2PromptBaseAsset.Id;
        p2SiteMetaData.Plant_Asset_Prompt_Detail__c = p2PlantAssetPromptDetail.Id;
        p2SiteMetaData.Prompt_Information__c = p2PromptInfo.Id;
        insert p2SiteMetaData;
        
        
        Plant_Asset_Prompt_Detail__c p3PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p3PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p3PromptInfo.Name;
        p3PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        p3PlantAssetPromptDetail.Prompt_Information__c = p3PromptInfo.Id;
        p3PlantAssetPromptDetail.Base_Asset__c = p3PromptBaseAsset.Id;
        insert p3PlantAssetPromptDetail;

        Site_Metadata__c p3SiteMetaData = new Site_Metadata__c(); 
        p3SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p3SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p3SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"1200"}';
        p3SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p3SiteMetaData.Base_Asset_Template__c = p3PromptBaseAsset.Id;
        p3SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        p3SiteMetaData.Prompt_Information__c = p3PromptInfo.Id;
        insert p3SiteMetaData;
        
        Site_Metadata__c p4SiteMetaData = new Site_Metadata__c(); 
        p4SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p4SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p4SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"1300"}';
        p4SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p4SiteMetaData.Base_Asset_Template__c = p3PromptBaseAsset.Id;
        p4SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        p4SiteMetaData.Prompt_Information__c = p3PromptInfo.Id;
        insert p4SiteMetaData;
        
        Site_Metadata__c p5SiteMetaData = new Site_Metadata__c(); 
        p5SiteMetaData.Name = Constants.P3_PAD_BUILDS_AND_COUNTS;
        p5SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p5SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":"1400"}';
        p5SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        p5SiteMetaData.Base_Asset_Template__c = p3PromptBaseAsset.Id;
        p5SiteMetaData.Plant_Asset_Prompt_Detail__c = p3PlantAssetPromptDetail.Id;
        p5SiteMetaData.Prompt_Information__c = p3PromptInfo.Id;
        insert p5SiteMetaData;
        
        List<Site_Metadata__c> allSiteMetaData = [SELECT Id, Name, Attribute_Info__c,Base_Asset_Template__c FROM Site_Metadata__c WHERE Plant_Asset__c =: newPlantAsset.Id];
        System.debug('test 2'+allSiteMetaData.size());

        for(Site_Metadata__c siteMetaDataInstance : allSiteMetaData){
            siteMetaDataInstance.Is_Attribute_Value_Modified_in_Prompt__c = true;
            Map<String,String> attrInforList = (Map<String,String>)JSON.deserialize(siteMetaDataInstance.Attribute_Info__c,Map<String,String>.class);
            for(String strInstance : attrInforList.keyset()){
                    attrInforList.remove(strInstance);
                    attrInforList.put(strInstance,String.valueOf(400));
            }
            siteMetaDataInstance.Attribute_Info__c = JSON.serialize(attrInforList); 
        }
        update allSiteMetaData;
    }*/
}