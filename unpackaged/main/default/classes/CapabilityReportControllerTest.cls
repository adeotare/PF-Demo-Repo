/**
**/
@istest
public with sharing class CapabilityReportControllerTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        
        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND,'Drive','7777.77.777',newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c p1PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert p1PromptBaseAsset;
        
        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                                                     p1PromptBaseAsset.Id, newTemVersion.Id);
        p1PromptInfo.Prompt_Id__c = 'prompt2';
        insert p1PromptInfo;
        
        Plant_Asset_Prompt_Detail__c newPlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        newPlantAssetPromptDetail.Name = 'Test Plant Asset Prompt Detail';
        newPlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        newPlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        newPlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        insert newPlantAssetPromptDetail;
        
       
        
        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster(Constants.FLAT_HIERARCHY, newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;
        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();
         List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number','Number','Decimal','Decimal','Text','Text','Picklist','Picklist',
        'Date','Date','Checkbox','Checkbox'};
        list<String>coreAttrNameLst = new list<String>{'No1','No2','Decimal1','Decimal2','Text1','Text2','Picklist1','Picklist2'
        ,'Date1','Date2','Checkbox1','Checkbox2'};
        for(integer i = 0; i < 12; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptBaseAsset.Id, newTemVersion.Id);                                                                 
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;
         Id metricDefinition = Utils.getRecordTypeInfo('Metric_Definition__c','Definition').getRecordTypeId();
         List<Metric_Definition__c> metricDefLst = new List<Metric_Definition__c>();
        for(Core_Attribute__c coreAttrIns : coreAttrLst){
                Metric_Definition__c metricDef = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), 'VALUES', '', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef);
        }
        insert metricDefLst;
        
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(newTemVersion.Id),
                                                               String.valueOf(metricDefLst[0].Id), String.valueOf(metricDefLst[1].Id),'',
                                                               '=', '', 'Pass', '', '');
        insert eval1;

        Evaluation_Value__c newEvaluationValue = new Evaluation_Value__c();
        newEvaluationValue.Show_In_Report__c= true;
        newEvaluationValue.Logic_Result__c= true;
        newEvaluationValue.Result__c= 'Pass';
        newEvaluationValue.Evaluation__c= eval1.Id;
        newEvaluationValue.Test_Id__c= 'FDPV.0045';
        newEvaluationValue.Account_Plant__c= newPlantAsset.Id;
        insert newEvaluationValue;
    }
    public static testMethod void capabilityReportTest(){
        Id plantAsset = [SELECT Id, Name FROM Account_Plant__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777'].Id;
        String evaluationValues = CapabilityReportController.getEvaluationValues(plantAsset, 'Data Capability', 'Solar');
		String allEvaluationValues = CapabilityReportController.getallEvaluationValues(plantAsset);
        String allEvaluation = CapabilityReportController.getallEvaluation();
    }
}