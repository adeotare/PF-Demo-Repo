/**
**/
@isTest
public with sharing class ImportAndExportCSVTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        Account_Plant__c pa = new Account_Plant__c();
        pa.Customer_Plant_Name__c = 'Plant Asset Test1';
//        pa.RecordTypeId = [SELECT id from RecordType where Name ='Parent Asset'].Id;
//        pa.Plant_Name__c = 'test1';
        pa.Project_Lifecycle_Status__c = 'Pending';
 //       pa.Implementation_Status__c = 'Pending Customer Submission';
//        pa.Renewable_Type__c = Constants.WIND;
        insert pa;
        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.777',newTemVersion.Id);
//        newPlantAsset.Parent__c = pa.Id;
//        newPlantAsset.Renewable_Type__c = Constants.WIND;
        insert newPlantAsset;
        List<Base_Asset_Template__c> newBaseAssetTemplate = new List<Base_Asset_Template__c>();
        newBaseAssetTemplate.add(TestDataFactory.createBaseAssetTemplate(Constants.BASE_BLOCK, newTemVersion.Id));
        newBaseAssetTemplate.add(TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id));
       
        insert newBaseAssetTemplate;
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS, newBaseAssetTemplate[0].Id, newTemVersion.Id);
        insert newPromptInfo;
        Prompt_Information__c previousPromptInfo = TestDataFactory.createPromptInformation(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS, newBaseAssetTemplate[0].Id, newTemVersion.Id);
        insert previousPromptInfo;
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail.Name = newPlantAsset.Name +'-'+previousPromptInfo.Name;
        plantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        plantAssetPromptDetail.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate[0].Id;
        insert plantAssetPromptDetail;
      }
    
    public static testMethod void ImportExportCSVTest(){
        //query Plant Asset
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777'].Id;
        LIST<Prompt_Information__c> promptInformation = [SELECT Id,Name From Prompt_Information__c where Name =:CONSTANTS.P2_BLOCK_INFO_AND_PAD_COUNTS ];
        Id plantAssetPromptDetail = [SELECT Id,Name From Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c = :plantAsset].Id;
        Site_Metadata__c p2SiteMetaData = new Site_Metadata__c(); 
        p2SiteMetaData.Name = Constants.P2_BLOCK_INFO_AND_PAD_COUNTS;
        p2SiteMetaData.Prompt_Specific_Info__c = '{"Block Name":"b1","Pad Count":"1"}';
        p2SiteMetaData.Attribute_Info__c = '{"DC_Capacity":"123","COMMERCIAL_OPERATOR":"yes"}';
        p2SiteMetaData.Account_Plant__c = plantAsset;
        p2SiteMetaData.Prompt_Information__c = promptInformation[0].Id;
        p2SiteMetaData.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetail;
        insert p2SiteMetaData;
        
        List<Site_Metadata__c> p2SiteMetaDataLst = new List<Site_Metadata__c>();
        p2SiteMetaDataLst.add(p2SiteMetaData);
        
        ImportAndExportCSV.getPromptSiteMetadataRecords(plantAsset, JSON.serialize(promptInformation[0]));
        ImportAndExportCSV.getPlantAssetDetail(plantAsset);
        ImportAndExportCSV.updateSiteMetadata(JSON.serialize(p2SiteMetaDataLst), false, true);
        ImportAndExportCSV.updateSiteMetadata(JSON.serialize(p2SiteMetaDataLst), true, true);
    }
}