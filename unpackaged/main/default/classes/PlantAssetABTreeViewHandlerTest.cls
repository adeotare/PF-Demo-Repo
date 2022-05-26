/**
**/
@isTest
public with sharing class PlantAssetABTreeViewHandlerTest {
   @TestSetup
   static void testDataSetup(){
    TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
    insert newTemVersion;
     
    Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
    insert newPlantAsset;
    
     
    List<Base_Asset_Template__c> baseAssetTemplateLst = new List<Base_Asset_Template__c>();
     
    Base_Asset_Template__c p1BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_BLOCK, newTemVersion.Id);
    p1BaseAssetTemplate.Asset_Short_Name__c = 'PAD';
    baseAssetTemplateLst.add(p1BaseAssetTemplate);
     
    Base_Asset_Template__c w1BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_WIND_STRING, newTemVersion.Id);
    w1BaseAssetTemplate.Asset_Short_Name__c = 'WIND';
    baseAssetTemplateLst.add(w1BaseAssetTemplate);
     
    Base_Asset_Template__c m1BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base Meter', newTemVersion.Id);
    m1BaseAssetTemplate.Asset_Short_Name__c = 'METMAST';
    baseAssetTemplateLst.add(m1BaseAssetTemplate);
     
    Base_Asset_Template__c s1BaseAssetTemplate = TestDataFactory.createBaseAssetTemplate('Base SubMeter', newTemVersion.Id);
    s1BaseAssetTemplate.Asset_Short_Name__c = 'SUB';
    baseAssetTemplateLst.add(s1BaseAssetTemplate);

    Base_Asset_Template__c newBaseAssetTemplateG1 = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
    baseAssetTemplateLst.add(newBaseAssetTemplateG1);
    insert baseAssetTemplateLst;
     
    List<Prompt_Information__c> promptInfoLst = new list<Prompt_Information__c>();
    promptInfoLst.add(TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR, baseAssetTemplateLst[0].Id, newTemVersion.Id));
    promptInfoLst.add(TestDataFactory.createPromptInformation(Constants.W1_PLANT_INFO_PROMPT_WIND, baseAssetTemplateLst[1].Id, newTemVersion.Id));
    promptInfoLst.add(TestDataFactory.createPromptInformation(Constants.M1_MET_MAST_STATION_BUILD, baseAssetTemplateLst[2].Id, newTemVersion.Id));
    promptInfoLst.add(TestDataFactory.createPromptInformation(Constants.S1_SUBSTATION_SWITCHGEAR_BUILD, baseAssetTemplateLst[3].Id, newTemVersion.Id));
    promptInfoLst.add(TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, baseAssetTemplateLst[3].Id, newTemVersion.Id));
    insert promptInfoLst;

    newTemVersion.Status__c = 'Active';
    update newTemVersion;

    Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
    g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ promptInfoLst[4].Name;
    g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
    g1PlantAssetPromptDetail.Prompt_Information__c = promptInfoLst[4].Id;
    g1PlantAssetPromptDetail.Base_Asset__c = baseAssetTemplateLst[4].Id;
    insert g1PlantAssetPromptDetail;

    Site_Metadata__c newG1SiteMetadata = TestDataFactory.createG1SiteMetadata(newPlantAsset.Id);
    newG1SiteMetadata.Prompt_Information__c = promptInfoLst[4].Id;
    newG1SiteMetadata.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
    insert newG1SiteMetadata;

    Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
    p1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ promptInfoLst[0].Name;
    p1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
    p1PlantAssetPromptDetail.Prompt_Information__c = promptInfoLst[0].Id;
    p1PlantAssetPromptDetail.Base_Asset__c = baseAssetTemplateLst[0].Id;
    insert p1PlantAssetPromptDetail;

    Plant_Asset_Prompt_Detail__c w1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
    w1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ promptInfoLst[1].Name;
    w1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
    w1PlantAssetPromptDetail.Prompt_Information__c = promptInfoLst[1].Id;
    w1PlantAssetPromptDetail.Base_Asset__c = baseAssetTemplateLst[1].Id;
    insert w1PlantAssetPromptDetail;

    Plant_Asset_Prompt_Detail__c m1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
    m1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ promptInfoLst[2].Name;
    m1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
    m1PlantAssetPromptDetail.Prompt_Information__c = promptInfoLst[2].Id;
    m1PlantAssetPromptDetail.Base_Asset__c = baseAssetTemplateLst[2].Id;
    insert m1PlantAssetPromptDetail;

    Plant_Asset_Prompt_Detail__c s1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
    s1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ promptInfoLst[2].Name;
    s1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
    s1PlantAssetPromptDetail.Prompt_Information__c = promptInfoLst[2].Id;
    s1PlantAssetPromptDetail.Base_Asset__c = baseAssetTemplateLst[2].Id;
    insert s1PlantAssetPromptDetail;

    list<Site_Metadata__c> siteMetadataLst = new list<Site_Metadata__c>();

    Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
    p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
    p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"3","flat Hierarchy":"false","drivePlus":"true"}';
    p1SiteMetaData.Attribute_Info__c = '{{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}}';
    p1SiteMetaData.Base_Asset_Template__c = baseAssetTemplateLst[0].Id;
    p1SiteMetaData.Account_Plant__c = newPlantAsset.id;
    p1SiteMetaData.Prompt_Information__c = promptInfoLst[0].Id;
    p1SiteMetaData.Asset_Name__c = 'P1';
    p1SiteMetaData.Asset_Short_Name__c = 'PAD';
    p1SiteMetaData.Parent_Site_Metadata__c = newG1SiteMetadata.Id;
    p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
    siteMetadataLst.add(p1SiteMetaData);
     
    Site_Metadata__c w1SiteMetaData = new Site_Metadata__c(); 
    w1SiteMetaData.Name = Constants.W1_PLANT_INFO_PROMPT_WIND;
    w1SiteMetaData.Prompt_Specific_Info__c = '{"String Count":"3","flat Hierarchy":"false","drivePlus":"true"}';
    w1SiteMetaData.Attribute_Info__c = '{\"Tracker_Controller\":\"4\",\"Tracker_Motor\":\"8\"}';
    w1SiteMetaData.Base_Asset_Template__c = baseAssetTemplateLst[1].Id;
    w1SiteMetaData.Account_Plant__c= newPlantAsset.id;
    w1SiteMetaData.Prompt_Information__c = promptInfoLst[1].Id;
    w1SiteMetaData.Asset_Name__c = 'W1';
    w1SiteMetaData.Asset_Short_Name__c = 'WIND';
    w1SiteMetaData.Parent_Site_Metadata__c = newG1SiteMetadata.Id;
    w1SiteMetaData.Plant_Asset_Prompt_Detail__c = w1PlantAssetPromptDetail.Id;
    siteMetadataLst.add(w1SiteMetaData);
     
    Site_Metadata__c m1SiteMetaData = new Site_Metadata__c(); 
    m1SiteMetaData.Name = Constants.M1_MET_MAST_STATION_BUILD;
    m1SiteMetaData.Prompt_Specific_Info__c = '{\"Station Name\":\"Station Name1\",\"Hail\":\"1\",\"Dew Point\":\"1\",\"Inverter\":\"3\"}';
    m1SiteMetaData.Attribute_Info__c = '{\"Barometric\":\"1\",\"Dew Point\":\"7\"}';
    m1SiteMetaData.Account_Plant__c= newPlantAsset.id;
    m1SiteMetaData.Prompt_Information__c = promptInfoLst[2].Id;
    m1SiteMetaData.Base_Asset_Template__c = baseAssetTemplateLst[2].Id;
    m1SiteMetaData.Asset_Name__c = 'M1';
    m1SiteMetaData.Asset_Short_Name__c = 'METMAST';
    m1SiteMetaData.Parent_Site_Metadata__c = newG1SiteMetadata.Id;
    m1SiteMetaData.Plant_Asset_Prompt_Detail__c = m1PlantAssetPromptDetail.Id;
    siteMetadataLst.add(m1SiteMetaData);
     
    Site_Metadata__c s1SiteMetadata = new Site_Metadata__c(); 
    s1SiteMetadata.Name = Constants.S1_SUBSTATION_SWITCHGEAR_BUILD;
    s1SiteMetadata.Prompt_Specific_Info__c = '{\"Substation or Switchgear?\":\"Switchgear\",\"SUB/SWG Name\":\"switch 4\",\"Meters\":\"2\",\"Battery Banks\":\"2\",\"Battery Bank Controllers\":\"2\"}';
    s1SiteMetadata.Attribute_Info__c = '{\"Meters CA\":\"1\",\"Battery Bank CA\":\"7\"}';
    s1SiteMetadata.Prompt_Information__c = promptInfoLst[3].Id;
    s1SiteMetadata.Account_Plant__c= newPlantAsset.id;
    s1SiteMetadata.Base_Asset_Template__c = baseAssetTemplateLst[3].Id;
    s1SiteMetadata.Asset_Name__c = 'S1';
    s1SiteMetadata.Asset_Short_Name__c = 'SUB';
    s1SiteMetadata.Parent_Site_Metadata__c = newG1SiteMetadata.Id;
    s1SiteMetaData.Plant_Asset_Prompt_Detail__c = s1PlantAssetPromptDetail.Id;
    siteMetadataLst.add(s1SiteMetadata);
    insert siteMetadataLst;
   }

   public static testMethod void hierarchyTest(){
    Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c  = '7777.77.777'].Id;
    String hierarchyResult = PlantAssetABTreeViewHandler.formTreeView(plantAsset);
   }
}