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
        insert newPlantAsset1;
        insert newPlantAsset2;
        insert newPlantAsset3;
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
      }
    @isTest
    public static void getG1RecordDetailsTest(){
         Id plantAsset1 = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset1);
         Id plantAsset2 = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c ='7777.77.778'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset2);
         Id plantAsset3 = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c ='7777.77.779'].Id;
         G1BulkImportButtonHndlr.getG1RecordDetails(plantAsset3);
        
    }

}