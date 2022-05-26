/**
**/
@istest
public with sharing class ReadExcelAsCSVTest {
    @testSetup 
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert newBaseAssetTemplate;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR, newBaseAssetTemplate.Id , newTemVersion.Id);
        insert p1PromptInfo;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        insert p1PlantAssetPromptDetail;
    }
    @isTest
    public static void ReadExcelAsCSVTest1(){
        Account_Plant__c newPlantAsset = [SELECT Id, Name,TEM_Version__c FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c = '777.77.777' LIMIT 1];
        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = [SELECT Id, Name FROM Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c =: newPlantAsset.Id LIMIT 1];
        String csvFile = 'John,Doe,120 jefferson st.,Riverside, NJ, 08075';

        ReadExcelAsCSV.fileUpload(csvFile, String.valueOf(p1PlantAssetPromptDetail.Id), 'Address Sheet 1');
        
        List<ContentDocumentLink> conDocLink = [Select Id, LinkedEntityId, ContentDocumentId, IsDeleted, SystemModstamp, ShareType, Visibility FROM ContentDocumentLink 
            WHERE LinkedEntityId =: p1PlantAssetPromptDetail.Id];
        System.assertEquals(1,conDocLink.size());
    }
    @isTest
    public static void ReadExcelAsCSVTest2(){
        Account_Plant__c newPlantAsset = [SELECT Id, Name,TEM_Version__c FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c = '777.77.777' LIMIT 1];
        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = [SELECT Id, Name FROM Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c =: newPlantAsset.Id LIMIT 1];
        String csvFile = 'John,Doe,120 jefferson st.,Riverside, NJ, 08075';
        
        
        List<String> existingCsv = new List<String>();
        for(integer i = 0; i < 3; i++){
            existingCsv.add(ReadExcelAsCSV.fileUpload(csvFile, String.valueOf(p1PlantAssetPromptDetail.Id), 'Address Sheet'+i));
        }

        ReadExcelAsCSV.deleteContentDocument(existingCsv);
        
        List<ContentDocumentLink> conDocLink = [Select Id, LinkedEntityId, ContentDocumentId, IsDeleted, SystemModstamp, ShareType, Visibility FROM ContentDocumentLink 
            WHERE LinkedEntityId =: p1PlantAssetPromptDetail.Id];
        System.assertEquals(0,conDocLink.size());
    }
}