/**
**/
@isTest
public class G1BulkImportButtonHndlrTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        Account_Plant__c pa = new Account_Plant__c();
//        pa.Name = 'Plant Asset Test1';
//        pa.RecordTypeId = [SELECT id from RecordType where Name ='Parent Asset'].Id;
//        pa.Plant_Name__c = 'test1';
        pa.Project_Lifecycle_Status__c = 'Pending';
//        pa.Implementation_Status__c = 'Pending Customer Submission';
//        pa.Renewable_Type__c = Constants.WIND;
        insert pa;
        Account_Plant__c newPlantAsset1 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.777',newTemVersion.Id);
//        newPlantAsset1.Parent__c = pa.Id;
        Account_Plant__c newPlantAsset2 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.778',newTemVersion.Id);
//        newPlantAsset2.Parent__c = pa.Id;
        Account_Plant__c newPlantAsset3 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.779',newTemVersion.Id);
//        newPlantAsset3.Parent__c = pa.Id;
      Account_Plant__c newPlantAsset4 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.780',newTemVersion.Id);
        Account_Plant__c newPlantAsset5 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.781',newTemVersion.Id);
         Account_Plant__c newPlantAsset6 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.782',newTemVersion.Id);
  
        insert newPlantAsset1;
        insert newPlantAsset2;
        insert newPlantAsset3;
        insert newPlantAsset4;
        insert newPlantAsset5;
        insert newPlantAsset6;
        List<Base_Asset_Template__c> newBaseAssetTemplate = new List<Base_Asset_Template__c>();
        newBaseAssetTemplate.add(TestDataFactory.createBaseAssetTemplate(Constants.BASE_BLOCK, newTemVersion.Id));
        newBaseAssetTemplate.add(TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id));
       
        insert newBaseAssetTemplate;
        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, newBaseAssetTemplate[0].Id, newTemVersion.Id);
        insert newPromptInfo;
        Prompt_Information__c previousPromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, newBaseAssetTemplate[0].Id, newTemVersion.Id);
        insert previousPromptInfo;
        Prompt_Information__c nextPromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR, newBaseAssetTemplate[0].Id, newTemVersion.Id);
        insert nextPromptInfo;
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail1 = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail1.Name = newPlantAsset2.Name +'-'+previousPromptInfo.Name;
        plantAssetPromptDetail1.Account_Plant__c = newPlantAsset2.Id;
        plantAssetPromptDetail1.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail1.Base_Asset__c = newBaseAssetTemplate[0].Id;
        insert plantAssetPromptDetail1;
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail2 = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail2.Name = newPlantAsset2.Name +'-'+previousPromptInfo.Name;
        plantAssetPromptDetail2.Account_Plant__c = newPlantAsset2.Id;
        plantAssetPromptDetail2.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail2.Base_Asset__c = newBaseAssetTemplate[0].Id;
        insert plantAssetPromptDetail2;
         Plant_Asset_Prompt_Detail__c plantAssetPromptDetail3 = new Plant_Asset_Prompt_Detail__c();
         plantAssetPromptDetail3.Name = newPlantAsset3.Name +'-'+nextPromptInfo.Name;
         plantAssetPromptDetail3.Account_Plant__c = newPlantAsset3.Id;
         plantAssetPromptDetail3.Prompt_Information__c = previousPromptInfo.Id;
         plantAssetPromptDetail3.Base_Asset__c = newBaseAssetTemplate[0].Id;
         insert plantAssetPromptDetail3; 
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail4 = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail4.Name = newPlantAsset4.Name +'-'+nextPromptInfo.Name;
        plantAssetPromptDetail4.Account_Plant__c = newPlantAsset4.Id;
        plantAssetPromptDetail4.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail4.Base_Asset__c = newBaseAssetTemplate[0].Id;
       plantAssetPromptDetail4.Bulk_Import_Type__c = 'Manual';
        insert plantAssetPromptDetail4; 
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail5 = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail5.Name = newPlantAsset5.Name +'-'+nextPromptInfo.Name;
        plantAssetPromptDetail5.Account_Plant__c = newPlantAsset5.Id;
        plantAssetPromptDetail5.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail5.Base_Asset__c = newBaseAssetTemplate[0].Id;
       plantAssetPromptDetail5.Bulk_Import_Type__c = 'COMPLETED';
        insert plantAssetPromptDetail5; 
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail6 = new Plant_Asset_Prompt_Detail__c();
        plantAssetPromptDetail6.Name = newPlantAsset6.Name +'-'+previousPromptInfo.Name;
        plantAssetPromptDetail6.Account_Plant__c = newPlantAsset6.Id;
        plantAssetPromptDetail6.Prompt_Information__c = previousPromptInfo.Id;
        plantAssetPromptDetail6.Base_Asset__c = newBaseAssetTemplate[0].Id;
        plantAssetPromptDetail6.Bulk_Import_Type__c = 'Multiple Base Asset Template Prompts';
        insert plantAssetPromptDetail6;
      }
    @isTest
    public static void getG1RecordDetailsTest(){
         Id plantAsset1 = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.777'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset1);
         Id plantAsset2 = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.778'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset2);
         Id plantAsset3 = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.779'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset3);
         Id plantAsset4 = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.780'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset4);
         Id plantAsset5 = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.781'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset5);
        Id plantAsset6 = [SELECT Id, Name FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.782'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset6);
        
    }

}