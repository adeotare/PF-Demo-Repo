/**
**/
@isTest
public with sharing class G1InitialPlantInfoPromptRefreshTest {
    @TestSetup
    static void testDataSetup(){
        TEM_Version__c temVersion =TestDataFactory.createTemVersion('Draft');
        insert temVersion;

        Account_Plant__c plantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive;FSM','7777.77.777',temVersion.Id);
        insert plantAsset;   

        List<Base_Asset_Template__c> BaseAssetSOs = new List<Base_Asset_Template__c>();
        BaseAssetSOs.add(TestDataFactory.createBaseAssetTemplate('Base Solar PV', temVersion.Id));
        BaseAssetSOs.add(TestDataFactory.createBaseAssetTemplate('Base Wind', temVersion.Id));
        insert BaseAssetSOs;

        List<Core_Attribute__c> coreAttList = new List<Core_Attribute__c>();
        Id coreAttributeRecordTypeId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
        Core_Attribute__c acCapacityForSolar = TestDataFactory.createCoreAttribute('LOCATION_COUNTRY', 'Metadata', 'Text', coreAttributeRecordTypeId, null, BaseAssetSOs[0].Id, temVersion.Id);
        acCapacityForSolar.Plant_Asset_Field_Name__c = 'Project_Lifecycle_Status__c';
        coreAttList.add(acCapacityForSolar);

        Core_Attribute__c dcCapacityForSolar = TestDataFactory.createCoreAttribute('Zip/Postal Code', 'Metadata', 'Text', coreAttributeRecordTypeId, null, BaseAssetSOs[0].Id, temVersion.Id);
        dcCapacityForSolar.Plant_Asset_Field_Name__c = 'Asset_Builder_Status__c';
        coreAttList.add(dcCapacityForSolar);

        Core_Attribute__c acCapacityForWind = TestDataFactory.createCoreAttribute('LOCATION_COUNTRY', 'Metadata', 'Text', coreAttributeRecordTypeId, null, BaseAssetSOs[1].Id, temVersion.Id);
        acCapacityForWind.Plant_Asset_Field_Name__c = 'Project_Lifecycle_Status__c';
        coreAttList.add(acCapacityForWind);

        Core_Attribute__c dcCapacityForWind = TestDataFactory.createCoreAttribute('Zip/Postal Code', 'Metadata', 'Text', coreAttributeRecordTypeId, null, BaseAssetSOs[1].Id, temVersion.Id);
        dcCapacityForWind.Plant_Asset_Field_Name__c = 'Asset_Builder_Status__c';
        coreAttList.add(dcCapacityForWind);
        insert coreAttList;

        List<Prompt_Information__c> promptInformationSOs= new List<Prompt_Information__c>();
        promptInformationSOs.add(TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, null, temVersion.Id));

        Prompt_Information__c p1SolarPrompt = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR, BaseAssetSOs[0].Id , temVersion.Id);
        p1SolarPrompt.Type__c = Constants.SOLAR;
        promptInformationSOs.add(p1SolarPrompt);

       Prompt_Information__c w1WindPrompt = TestDataFactory.createPromptInformation(Constants.W1_PLANT_INFO_PROMPT_WIND, BaseAssetSOs[1].Id, temVersion.Id);
       w1WindPrompt.Type__c = Constants.WIND;
       promptInformationSOs.add(w1WindPrompt);
       insert promptInformationSOs;

        //Plant Asset 7777.77.777 - null
        createG1PAPDAndSiteMetadata(plantAsset.Id, promptInformationSOs[0].Id );
        // Removed because no longer supported multiple renewable types
        //createP1W1PapdAndSiteMetadataAndABRD(plantAsset.Id, promptInformationSOs[1].Id, BaseAssetSOs[0].Id, 'P1');
        createP1W1PapdAndSiteMetadataAndABRD(plantAsset.Id, promptInformationSOs[2].Id, BaseAssetSOs[1].Id, 'W1');

        //Plant Asset with Renewable Type Solar Used for G1 RT Size 0
        Account_Plant__c plantAssetSolar1 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive;FSM','8888.88.888',temVersion.Id);
        insert plantAssetSolar1;

        Id PlantAssetSolar1SMDId = createG1PAPDAndSiteMetadata(plantAssetSolar1.Id, promptInformationSOs[0].Id );
        Site_Metadata__c PlantAssetSolar1SMDUpdate = new Site_Metadata__c();
        PlantAssetSolar1SMDUpdate.Id = PlantAssetSolar1SMDId;
        PlantAssetSolar1SMDUpdate.Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM","Renewable Type":"","Switchgear Substation":"0","Metmast":"0"}';
        update PlantAssetSolar1SMDUpdate;

        //Plant Asset with Renewable Type Solar Used for G1 RT Size 1
        //Plant Asset With RenewableType Solar and G1, P1, ABRD for solar

        Account_Plant__c plantAssetSolar2 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive;FSM','5555.55.555',temVersion.Id);
        insert plantAssetSolar2;

        Id PlantAssetSolar2SMDId = createG1PAPDAndSiteMetadata(plantAssetSolar2.Id, promptInformationSOs[0].Id );
        Site_Metadata__c PlantAssetSolar2SMDUpdate = new Site_Metadata__c();
        PlantAssetSolar2SMDUpdate.Id = PlantAssetSolar2SMDId;
        PlantAssetSolar2SMDUpdate.Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM","Renewable Type":"'+Constants.SOLAR+'","Switchgear Substation":"0","Metmast":"0"}';
        update PlantAssetSolar2SMDUpdate;

        createP1W1PapdAndSiteMetadataAndABRD(plantAssetSolar2.Id, promptInformationSOs[1].Id, BaseAssetSOs[0].Id, 'P1');


        //Plant Asset With RenewableType Solar and G1, P1, W1, ABRD
        Account_Plant__c plantAssetSolarWind = TestDataFactory.createPlantAsset(Constants.WIND,'Drive;FSM','4444.44.444',temVersion.Id);
        insert plantAssetSolarWind;

        Id plantAssetSolarWindSMDId = createG1PAPDAndSiteMetadata(plantAssetSolarWind.Id, promptInformationSOs[0].Id );
        Site_Metadata__c plantAssetSolarWindSMDUpdate = new Site_Metadata__c();
        plantAssetSolarWindSMDUpdate.Id = plantAssetSolarWindSMDId;
        plantAssetSolarWindSMDUpdate.Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"0","Metmast":"0"}';
        update plantAssetSolarWindSMDUpdate;

        //createP1W1PapdAndSiteMetadataAndABRD(plantAssetSolarWind.Id, promptInformationSOs[1].Id, BaseAssetSOs[0].Id, 'P1');
        createP1W1PapdAndSiteMetadataAndABRD(plantAssetSolarWind.Id, promptInformationSOs[2].Id, BaseAssetSOs[1].Id, 'W1');

        Account_Plant__c plantAssetABCompleted = TestDataFactory.createPlantAsset(Constants.WIND,'Drive;FSM','999.999.999',temVersion.Id);
        insert plantAssetABCompleted;  

        //Updating AB Status of all Plant assets to In-Progress
        Account_Plant__c plantAssetSoInProgress = new Account_Plant__c(Asset_Builder_Status__c = 'In-Progress', Id = plantAsset.Id);
        update plantAssetSoInProgress;

        //Update TEM Version to active
        temVersion.Status__c = 'Active';
        update temVersion;
    }

    public static List<Site_Metadata__c> getSiteMetaDataList(String plantAssetId, String promptName){
        List<Site_Metadata__c> siteMetaDataList = new List<Site_Metadata__c>();
        system.debug('---plantAssetId--'+plantAssetId);
        system.debug('----promptName----'+promptName);
        if(promptName == Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT){
            siteMetaDataList = [SELECT Prompt_Specific_Info__c FROM Site_Metadata__c WHERE Account_Plant__c =: plantAssetId
                                AND Prompt_Information__r.Name =:promptName
                                AND Plant_Asset_Prompt_Detail__r.Is_Deleted__C = false];
        }else{
            siteMetaDataList = [SELECT Id FROM Site_Metadata__c WHERE Account_Plant__c =: plantAssetId
                                AND Plant_Asset_Prompt_Detail__r.Is_Deleted__C = false];
        }
        return siteMetaDataList;
    }

    // G1 Prompt specific Info PFService Product size is 0
    @isTest
    static void verifyG1PFSrvPdtNullAndPltAssetPFSrvPdt2(){
        //PF Service product in G1 Site Metadata is null
        Account_Plant__c plantAsset = [SELECT Id,PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);        
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class); 
        System.assertEquals('Drive;Drive Pro;Implementation (Asset Building)', G1PromptSpecificInfoMap.get('PF Service Product'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation = [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
//        System.assertEquals(2, ABRptDataAfterUpdation.size());
    } 

    @isTest
    static void verifyG1PFSrvPdtNullAndPltAssetPFSrvPdt1(){
        Account_Plant__c plantAsset = [SELECT Id,PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        plantAsset.PF_Service_Product__c = 'Drive';
        update plantAsset;
        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
        String G1PFSrvPdt = G1PromptSpecificInfoMap.get('PF Service Product');
        System.assertEquals('Drive;Drive Pro;Implementation (Asset Building)', G1PromptSpecificInfoMap.get('PF Service Product'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
        System.assertEquals(0, ABRptDataAfterUpdation.size());
    }

    @isTest
    static void verifyG1PFSrvPdtNullAndPltAssetPFSrvNull(){
        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        plantAsset.PF_Service_Product__c = null;
        update plantAsset;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
//        System.assertEquals('', G1PromptSpecificInfoMap.get('PF Service Product'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
//        System.assertEquals(2, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
//        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }
    
    // G1 Prompt specific Info PFService Product size is 1
    @isTest
    static void verifyG1PFSrvPdt1PltAssetPFSrvRemoved1(){

        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        plantAsset.PF_Service_Product__c = null;
        update plantAsset;

        List<Site_Metadata__c> G1SiteMetaDataListForUpdate = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        G1SiteMetaDataListForUpdate[0].Prompt_Specific_Info__c = '{"PF Service Product":"Drive","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"0","Metmast":"0"}';
        update G1SiteMetaDataListForUpdate;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
        System.assertEquals('Drive', G1PromptSpecificInfoMap.get('PF Service Product'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(2, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }

    
    @isTest
    static void verifyG1PFSrvPdt1PltAssetPFSrvRemoved1AndAdded1(){

        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        plantAsset.PF_Service_Product__c = 'FSM';
        update plantAsset;

        List<Site_Metadata__c> G1SiteMetaDataListForUpdate = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        G1SiteMetaDataListForUpdate[0].Prompt_Specific_Info__c = '{"PF Service Product":"Drive","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"0","Metmast":"0"}';
        update G1SiteMetaDataListForUpdate;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
//        System.assertEquals('FSM', G1PromptSpecificInfoMap.get('PF Service Product'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(2, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }

    @isTest
    static void verifyG1PFSrvPdt1PltAssetPFSrvAdded1(){

        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        plantAsset.PF_Service_Product__c = 'Drive;FSM';
        update plantAsset;

        List<Site_Metadata__c> G1SiteMetaDataListForUpdate = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        G1SiteMetaDataListForUpdate[0].Prompt_Specific_Info__c = '{"PF Service Product":"Drive","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"0","Metmast":"0"}';
        update G1SiteMetaDataListForUpdate;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
        System.assertEquals('Drive', G1PromptSpecificInfoMap.get('PF Service Product'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(2, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }

    // G1 Prompt specific Info PFService Product size is 2
    @isTest
    static void verifyG1PFSrvPdt2PltAssetPFSrvRemoved1(){

        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        plantAsset.PF_Service_Product__c = 'Drive';
        update plantAsset;

        List<Site_Metadata__c> G1SiteMetaDataListForUpdate = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        G1SiteMetaDataListForUpdate[0].Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"0","Metmast":"0"}';
        update G1SiteMetaDataListForUpdate;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
//        System.assertEquals('Drive', G1PromptSpecificInfoMap.get('PF Service Product'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
        System.assertEquals(0, ABRptDataAfterUpdation.size());
    }

    @isTest
    static void verifyG1PFSrvPdt2PltAssetPFSrvRemoved2(){

        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        plantAsset.PF_Service_Product__c = null;
        update plantAsset;

        List<Site_Metadata__c> G1SiteMetaDataListForUpdate = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        G1SiteMetaDataListForUpdate[0].Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"0","Metmast":"0"}';
        update G1SiteMetaDataListForUpdate;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
//        System.assertEquals('', G1PromptSpecificInfoMap.get('PF Service Product'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
//        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }

    
    //To check Renewable Type Scenarios

    @isTest
    static void verifyG1RTNullPlantAssetRTAdded1(){
        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '8888.88.888'];

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
        System.assertEquals(Constants.SOLAR, G1PromptSpecificInfoMap.get('Renewable Type'));
    }

    @isTest
    static void verifyG1RTSolarPlantAssetRTAdded1(){
        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '8888.88.888'];
//        plantAsset.Renewable_Type__c = Constants.WIND;
//        update plantAsset;

        List<Site_Metadata__c> G1SiteMetaDataListForUpdate = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        G1SiteMetaDataListForUpdate[0].Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM","Renewable Type":"'+Constants.SOLAR+'","Switchgear Substation":"0","Metmast":"0"}';
        update G1SiteMetaDataListForUpdate;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
        //System.assertEquals(Constants.WIND, G1PromptSpecificInfoMap.get('Renewable Type'));
    }

    
    @isTest
    static void verifyG1RTSolarPlantAssetRTRemoved1(){
        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '5555.55.555'];
//        plantAsset.Renewable_Type__c = Constants.SOLAR;
//        update plantAsset;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
//        System.assertEquals(Constants.SOLAR, G1PromptSpecificInfoMap.get('Renewable Type'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        //System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
//        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }
    @isTest
    static void verifyG1RT2PlantAssetRTRemoved1(){
        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '5555.55.555'];
//        plantAsset.Renewable_Type__c = Constants.SOLAR;
//        update plantAsset;

        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
        //System.assertEquals('', G1PromptSpecificInfoMap.get('Renewable Type'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation= [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
//        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }

    
    @isTest
    static void verifyG1RT2AndPltAssetRemoved2(){

        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '4444.44.444'];
//        plantAsset.Renewable_Type__c = Constants.SOLAR;
//        update plantAsset;

        //PF Service product in G1 Site Metadata is null
        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);        
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class); 
        //System.assertEquals('', G1PromptSpecificInfoMap.get('Renewable Type'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation = [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
//        System.assertEquals(2, ABRptDataAfterUpdation.size());
    } 

    @isTest
    static void verifyG1RT2AndPltAssetRemovedWind(){
        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '4444.44.444'];
//        plantAsset.Renewable_Type__c = Constants.SOLAR;
//        update plantAsset;

        //PF Service product in G1 Site Metadata is null
        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);        
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class); 
        //System.assertEquals(Constants.SOLAR, G1PromptSpecificInfoMap.get('Renewable Type'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation = [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
//        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }

    @isTest
    static void verifyG1RT2AndPltAssetRemovedSolar(){
        Account_Plant__c plantAsset = [SELECT Id, PF_Service_Product__c from Account_Plant__c WHERE Drive_Id__c = '4444.44.444'];
//        plantAsset.Renewable_Type__c = Constants.WIND;
//        update plantAsset;

        //PF Service product in G1 Site Metadata is null
        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        List<Site_Metadata__c> G1SiteMetaDataList = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);        
        Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class); 
        System.assertEquals(Constants.WIND, G1PromptSpecificInfoMap.get('Renewable Type'));

        List<Site_Metadata__c> siteMetadataAfterUpdation =  getSiteMetaDataList(plantAsset.Id, null);
        System.assertEquals(1, siteMetadataAfterUpdation.size());

        List<Asset_Builder_Report_Data__c> ABRptDataAfterUpdation = [SELECT Id FROM Asset_Builder_Report_Data__c WHERE Is_Archived__c = false AND Account_Plant__c =: plantAsset.Id];
//        System.assertEquals(2, ABRptDataAfterUpdation.size());
    }
    
    public static String createG1PAPDAndSiteMetadata(String plantAssetId, String promptInfoId){
        //To create G1 Plant asset prompt detail
        Plant_Asset_Prompt_Detail__c g1PlantAssetPromtDetail = TestDataFactory.createPlantAssetPromptDetail('G1 Plant Asset Prompt detail', plantAssetId, promptInfoId);
        insert g1PlantAssetPromtDetail;

        system.debug('---plantAssetId---'+plantAssetId);
        system.debug('---promptInfoId---'+promptInfoId);
        system.debug('---g1PlantAssetPromtDetail---'+g1PlantAssetPromtDetail);
        //To create G1 Site Meta data
        Site_Metadata__c g1SiteMetaDataForPlantAsset = TestDataFactory.createSiteMetadata('G1 Site Metadata', plantAssetId, promptInfoId, '{"PF Service Product":"","Renewable Type":"'+Constants.SOLAR+'","Switchgear Substation":"0","Metmast":"0"}',
                                                                                            g1PlantAssetPromtDetail.Id, '', null);
        insert g1SiteMetaDataForPlantAsset;
        return g1SiteMetaDataForPlantAsset.Id;
    }

    public static void createP1W1PapdAndSiteMetadataAndABRD(Id plantAssetId, Id promptInfoId, Id baseAssetId, String name){
        String papdName = name + 'Plant Asset Prompt Detail';
        String siteMetadataName = name + 'Site Metadata';
        //TO create P1 Plant Asset Prompt Detail
        Plant_Asset_Prompt_Detail__c plantAssetPromtDetail = TestDataFactory.createPlantAssetPromptDetail(papdName, plantAssetId, promptInfoId);
        insert plantAssetPromtDetail;

        //To create P1 Site Meta data
        Site_Metadata__c siteMetaData = TestDataFactory.createSiteMetadata(siteMetadataName, plantAssetId , promptInfoId , '', plantAssetPromtDetail.Id,  
                                                                                            '{"LOCATION_COUNTRY":"","Zip/Postal Code":"","AC_Capacity":"","AC_CURTAILMENT_LIMIT":"","DC_Capacity":""}', baseAssetId);
        insert siteMetaData;

        //To create ABRD
         List<Asset_Builder_Report_Data__c> assetBuilderReportDataSOs = new List<Asset_Builder_Report_Data__c>();
         assetBuilderReportDataSOs.add(new Asset_Builder_Report_Data__c(Account_Plant__c = plantAssetId, Prompt_Information__c = promptInfoId));
         assetBuilderReportDataSOs.add(new Asset_Builder_Report_Data__c(Account_Plant__c = plantAssetId, Prompt_Information__c = promptInfoId));
         insert assetBuilderReportDataSOs;
    }
    @isTest
    public static void checkAttributesInP1W1SMD(){
       Account_Plant__c plantAsset = [SELECT Id, Asset_Builder_Status__c  FROM Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        
        plantAsset.Asset_Builder_Status__c = 'In-Progress	';
        
        update plantAsset;
               
		system.debug('---plantAsset-before---'+plantAsset);
        List<Site_Metadata__c> G1SiteMetaDataListForUpdate = getSiteMetaDataList(plantAsset.Id, Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        system.debug('---G1SiteMetaDataListForUpdate--'+G1SiteMetaDataListForUpdate);
        G1SiteMetaDataListForUpdate[0].Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM","Renewable Type":"'+Constants.WIND+'","Switchgear Substation":"0","Metmast":"0"}';
        update G1SiteMetaDataListForUpdate;
  
        G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData(plantAsset.Id);
        Set<String> types = new Set<String> { Constants.SOLAR, Constants.WIND };
        List<Site_Metadata__c> siteMetaData = [SELECT Attribute_Info__c FROM Site_Metadata__c WHERE Account_Plant__c =: plantAsset.Id
                                                    AND Prompt_Information__r.Type__c In :types];                                 
                                                        
        /*Map<String,String> siteMetaDataSolarMap = (Map<String,String>)JSON.deserialize(siteMetaData[0].Attribute_Info__c, Map<String,String>.class); 
        System.assertEquals('INDIA', siteMetaDataSolarMap.get('LOCATION_COUNTRY'));
        System.assertEquals('635653', siteMetaDataSolarMap.get('Zip/Postal Code'));*/

        Map<String,String> siteMetaDataWindMap = (Map<String,String>)JSON.deserialize(siteMetaData[0].Attribute_Info__c, Map<String,String>.class); 
//        System.assertEquals('INDIA', siteMetaDataWindMap.get('LOCATION_COUNTRY'));
//        System.assertEquals('635653', siteMetaDataWindMap.get('Zip/Postal Code'));
    }

    @isTest
    public static void checkABStatusInProgress(){
        Account_Plant__c plantAssetSO = [SELECT Id,Name,Asset_Builder_Status__c from Account_Plant__c WHERE Drive_Id__c = '7777.77.777'];
        Boolean result = G1InitialPlantInfoPromptRefresh.checkABStatusOfPlantAsset(plantAssetSO.Id);
        System.assertEquals(true, result);
    }

}