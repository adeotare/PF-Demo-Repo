/**
**/
@istest
public with sharing class ExportAssetBuildetPromptsTemplateTest {
    @TestSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        //Plant Asset Creation
        Account acc = new account();
        acc.name ='Test';
        Insert acc;


        Account_Plant__c newPlantAssetParent = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);

        insert newPlantAssetParent;

        Plant__c plant = new Plant__c();
        plant.Name = 'Test Plant';
        plant.Renewable_Type__c = Constants.WIND;
        plant.Timezone__c = 'India Standard Time';
        plant.Latitude__c = '45.4543';
        plant.Longitude__c= '70.123';
        insert plant;

        Account_Plant__c newPlantAsset = new Account_Plant__c();        
        newPlantAsset.Asset_Builder_Status__c = '';
        newPlantAsset.plant__c = plant.id;
        newPlantAsset.Drive_Id__c = '7777.77.777';
        newPlantAsset.TEM_Version__c = newTemVersion.Id;
        newPlantAsset.Project_Lifecycle_Status__c = 'Pending';
        newPlantAsset.Asset_Builder_Status__c = '';
        newPlantAsset.Account__c = acc.id;
        insert newPlantAsset;
        
        Plant__c masterPlant = new Plant__c();
        masterPlant.Name = 'Test Account Plant Master';
        masterPlant.Renewable_Type__c = Constants.WIND;
        masterPlant.Timezone__c = 'India Standard Time';
        masterPlant.Latitude__c = '45.4543';
        masterPlant.Longitude__c= '70.123';
        insert masterPlant;

        Account_Plant__c plantAssetCheck = new Account_Plant__c();
        plantAssetCheck.plant__c = masterPlant.id;
        plantAssetCheck.Asset_Builder_Status__c = '';
        plantAssetCheck.Drive_Id__c = '0000.000.002';
        plantAssetCheck.Drive_Id__c = '7777.77.778';
        plantAssetCheck.TEM_Version__c = newTemVersion.Id;
        plantAssetCheck.Project_Lifecycle_Status__c = 'Pending';
        plantAssetCheck.Asset_Builder_Status__c = '';
        plantAssetCheck.Account__c = acc.id;
        insert plantAssetCheck;

        Account_Plant__c plantAssetCheck1 = new Account_Plant__c();
        plantAssetCheck1.Asset_Builder_Status__c = '';
         plantAssetCheck.plant__c = masterPlant.id;
        plantAssetCheck1.Drive_Id__c = '7777.77.779';
        plantAssetCheck1.TEM_Version__c = newTemVersion.Id;
        plantAssetCheck1.Project_Lifecycle_Status__c = 'Pending';
        plantAssetCheck1.Asset_Builder_Status__c = '';
        plantAssetCheck1.Account__c = acc.id;
        insert plantAssetCheck1;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert newBaseAssetTemplate;

        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        p1PromptInfo.Type__c = Constants.SOLAR;
        p1PromptInfo.Prompt_Type__c = 'Build Prompt';
        insert p1PromptInfo;

        Prompt_Information__c g1PromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        g1PromptInfo.Type__c = Constants.SOLAR;
        g1PromptInfo.Prompt_Type__c = 'Build Prompt';
        insert g1PromptInfo;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster('Test Master', newTemVersion.Id);
        insert newPicklistMaster;
    
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Id promptCoreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Prompt_Specific_Attribute').getRecordTypeId();
        
        //for core attribute records
        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number','Date','Number','Checkbox'};
        list<String>coreAttrNameLst = new list<String>{'AC Curtailment Limit','Date Commercial Operation','AC Capacity','DriveNO'};
        Attribute_Master__c attributeMaster = new Attribute_Master__c();
        attributeMaster.Name = 'attrMaster';
        attributeMaster.Alias__c = 'attrMaster';
        attributeMaster.Type__c = 'Metadata';
        attributeMaster.TEM_Version__c = newTemVersion.Id;
        insert attributeMaster;

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
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive','Yes',coreAttrLst[i].Id, newTemVersion.Id) ;
            attrReqLst.add(attrReq);
        }
        insert attrReqLst;

        //for Prompt Specific records
        List<Core_Attribute__c> PromptSpecificAttrLst  = new List<Core_Attribute__c> ();
        list<String>promptDataTypeLst = new list<String>{'Text','Text','Picklist'};
        list<String>promptSpecificAttrNameLst = new list<String>{'Plant Name','Plant ID','Flat Hierarchy'};
        
        Attribute_Master__c attributeMasterPrompt = new Attribute_Master__c();
        attributeMasterPrompt.Name = Constants.DRIVE_PLUS;
        attributeMasterPrompt.Alias__c = Constants.DRIVE_PLUS;
        attributeMasterPrompt.Type__c = 'Prompt Specific';
        attributeMasterPrompt.TEM_Version__c = newTemVersion.Id;
        insert attributeMasterPrompt;

        for(integer i = 0; i < 2; i++){
            Core_Attribute__c promptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                'Text',
                                                                                promptCoreAttrRTId,
                                                                                (promptDataTypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                g1PromptInfo.Id, newTemVersion.Id);                                                                  
            promptSpecificAttr.Attribute_Master__c=attributeMasterPrompt.id;
            promptSpecificAttr.Plant_Asset_Field_Name__c = 'PF_Service_Product__c'; 
            promptSpecificAttrLst.add(promptSpecificAttr);
        }
        insert promptSpecificAttrLst;

        List<Attribute_Requirement__c> attrReqLst1  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 1; i++){
            Attribute_Requirement__c attrReq1 = TestDataFactory.createAttributeRequirement('Drive','No',promptSpecificAttrLst[i].Id, newTemVersion.Id);
            attrReqLst1.add(attrReq1);
        }
        insert attrReqLst1;

        // P1 Prompt Specific Attribute
        List<Core_Attribute__c> p1PromptSpecificAttrLst  = new List<Core_Attribute__c> ();
        for(integer i = 0; i < 2; i++){
            Core_Attribute__c p1PromptSpecificAttr = TestDataFactory.createPromptSpecificAttr(promptSpecificAttrNameLst[i],
                                                                                'Prompt Specific',
                                                                                'Text',
                                                                                promptCoreAttrRTId,
                                                                                (promptDataTypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptInfo.Id, newTemVersion.Id);                       
            p1PromptSpecificAttr.Attribute_Master__c = attributeMasterPrompt.id;
            p1PromptSpecificAttr.Plant_Asset_Field_Name__c = 'PF_Service_Product__c'; 
            p1PromptSpecificAttrLst.add(p1PromptSpecificAttr);
        }
        insert p1PromptSpecificAttrLst;

        List<Attribute_Requirement__c> p1AttrLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 1; i++){
            Attribute_Requirement__c attrReq1 = TestDataFactory.createAttributeRequirement('Drive','No',p1PromptSpecificAttrLst[i].Id, newTemVersion.Id);
            p1AttrLst.add(attrReq1);
        }
        insert p1AttrLst;

        Prompt_Information__c p10bPromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                newBaseAssetTemplate.Id, newTemVersion.Id);
        p10bPromptInfo.Type__c = Constants.SOLAR;
        p10bPromptInfo.Prompt_Type__c ='Detail Prompt';
        insert p10bPromptInfo;
        
        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+g1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1PlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        g1PlantAssetPromptDetail.Report_Execution_By_User__c =  UserInfo.getUserId();
        g1PlantAssetPromptDetail.Report_Generated_Datetime__c = system.today();
        insert g1PlantAssetPromptDetail;
        
        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Information__c = g1PromptInfo.Id;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM;Implementation (Asset Building)","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"2","Metmast":"2"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Base_Asset_Template__c = newBaseAssetTemplate.Id;
        g1SiteMetaData.Account_Plant__c = newPlantAsset.id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;

        Plant_Asset_Prompt_Detail__c p10bPlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p10bPlantAssetPromptDetail.Name = plantAssetCheck1.Name +'-'+p10bPromptInfo.Name;
        p10bPlantAssetPromptDetail.Account_Plant__c = plantAssetCheck1.Id;
        p10bPlantAssetPromptDetail.Prompt_Information__c = p10bPromptInfo.Id;
        p10bPlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        p10bPlantAssetPromptDetail.Report_Execution_By_User__c =  UserInfo.getUserId();
        p10bPlantAssetPromptDetail.Report_Generated_Datetime__c = system.today();
        insert p10bPlantAssetPromptDetail;
        
        Site_Metadata__c p10bSiteMetadata = new Site_Metadata__c(); 
        p10bSiteMetadata.Name = Constants.P10B_OTHER_ASSET_BUILD_AND_INFO;
        p10bSiteMetadata.Prompt_Information__c = p10bPromptInfo.Id;
        p10bSiteMetadata.Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM;Implementation (Asset Building)","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"2","Metmast":"2"}';
        p10bSiteMetadata.Attribute_Info__c = '{}';
        p10bSiteMetadata.Base_Asset_Template__c = newBaseAssetTemplate.Id;
        p10bSiteMetadata.Account_Plant__c = plantAssetCheck1.id;
        p10bSiteMetadata.Plant_Asset_Prompt_Detail__c = p10bPlantAssetPromptDetail.Id;
        insert p10bSiteMetadata;   
    }
    public static testMethod void ExportAssetBuilderTemplate(){
//        Id plantAssetRTId = Utils.getRecordTypeInfo('Account_Plant__c','Child_Asset').getRecordTypeId();
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' limit 1].Id; 
        ExportAssetBuilderPromptsTemplate.checkSiteMetadataRecord(plantAsset);
    }
    
    public static testMethod void ExportABTemplateBsdPlantAsset(){
//        Id plantAssetRTId = Utils.getRecordTypeInfo('Account_Plant__c','Child_Asset').getRecordTypeId();
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.778' ].Id; 
        ExportAssetBuilderPromptsTemplate.checkSiteMetadataRecord(plantAsset);
    }

    public static testMethod void queryDetailPromptAttributes(){
 //       Id plantAssetRTId = Utils.getRecordTypeInfo('Account_Plant__c','Child_Asset').getRecordTypeId();
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.779' ].Id; 
        ExportAssetBuilderPromptsTemplate.queryDetailPromptAttributes(plantAsset);
    }

    public static testMethod void updateG1Prompt(){
//        Id plantAssetRTId = Utils.getRecordTypeInfo('Account_Plant__c','Child_Asset').getRecordTypeId();
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.779'].Id; 
        ExportAssetBuilderPromptsTemplate.updateG1Prompt(plantAsset);    
    }
}