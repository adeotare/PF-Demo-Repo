/**
**/
@istest
public with sharing class CompletenessReportTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        
        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_METER, newTemVersion.Id);
        insert newBaseAssetTemplate;

        Prompt_Information__c newPromptInfo = TestDataFactory.createPromptInformation(Constants.P4_EQUIPMENT_PAD_METERS_INFO,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        newPromptInfo.Type__c = Constants.SOLAR;
        newPromptInfo.CSV_Sorting_Order__c = 20;
        newPromptInfo.Prompt_Id__c = 'prompt2';
        insert newPromptInfo;
    
        Plant_Asset_Prompt_Detail__c newPlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        newPlantAssetPromptDetail.Name = 'Test Plant Asset Prompt Detail';
        newPlantAssetPromptDetail.Base_Asset__c = newBaseAssetTemplate.Id;
        newPlantAssetPromptDetail.Prompt_Information__c = newPromptInfo.Id;
        newPlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        insert newPlantAssetPromptDetail;
    }
    public static testMethod void completenessReportTest(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777'].Id;
        String completenessReportData = CompletenessReport.getCompletenessReportData(plantAsset, 'Solar');
        String completenessReportSection = CompletenessReportParent.getCompletenessReportSection();
        String completenessReportSummary = CompletenessReportSummary.getCompletenessReportSummary(plantAsset);
	}
}