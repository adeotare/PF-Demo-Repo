public with sharing class CapabilityReportController {
    
    @AuraEnabled
    public static String getEvaluationValues(String plantAssetId, String categoryName, String subCategory) {
        List<String> pfServiceProducts = Utils.getAttrReqSysNamesFrmG1(plantAssetId);
        String evaluationValueString = '';
        list<Evaluation_Value__c> evaluationValueLst = [SELECT Id, Test_Id__c, Evaluation__r.Category__c, Result__c,
            Evaluation__r.Alias__c, Evaluation__r.Evaluation_Notes__c, Account_Plant__c, Evaluation__r.Name, Evaluation__r.Group_2__c,
            Evaluation__r.Group_1__c, Evaluation__r.Result__c, Evaluation__r.Sub_Category__c, Evaluation__r.Prompt_Information__r.Id, Evaluation__r.Prompt_Information__r.Prompt_Id__c FROM Evaluation_Value__c WHERE
            Logic_Result__c = true AND Evaluation__r.Category__c =: categoryName AND 
            Account_Plant__c =: plantAssetId AND Evaluation__r.Group_1__c != null AND Evaluation__r.Alias__c != null AND
            Evaluation__r.Sub_Category__c =: subCategory AND Show_In_Report__c = true AND Evaluation__r.Products__c IN :pfServiceProducts ORDER BY Evaluation__r.Group_1__c ASC, Test_Id__c ASC];

        if(evaluationValueLst.size()>0){
            Map<String,Object> evaluationValueMap = CapabilityReportController.getEvaluationValueMap(evaluationValueLst);
            evaluationValueString = JSON.serialize(evaluationValueMap);
            return evaluationValueString;
        }else{
            return evaluationValueString;
        }
    }
    @AuraEnabled
    public static Map<String,Object> getEvaluationValueMap(list<Evaluation_Value__c> evaluationValueLst){
        Map<String,Object> evaluationValueMap = new Map<String,Object>();
        evaluationValueMap.put('evaluationValue',evaluationValueLst);
        Map<String,String> promptIdToPreviousPlantAssetDetail = new Map<String,String>();
        Map<String,String> promptToPromptId = new Map<String,String>();
        
        List<Id> promptInfoIds = new List<Id>();
        for( Evaluation_Value__c evaluationValue : evaluationValueLst){
            if(evaluationValue.Evaluation__r.Prompt_Information__r.Id != NULL && evaluationValue.Evaluation__r.Prompt_Information__r.Prompt_Id__c !=NULL) {
            promptToPromptId.put(evaluationValue.Evaluation__r.Prompt_Information__r.Id, evaluationValue.Evaluation__r.Prompt_Information__r.Prompt_Id__c );
            promptInfoIds.add(evaluationValue.Evaluation__r.Prompt_Information__r.Id);
            }
        }
        
        evaluationValueMap.put('promptToPromptId',promptToPromptId);
        List<Plant_Asset_Prompt_Detail__c> plantAssetPromptDetails = [SELECT Id,Previous_Plant_Asset_Prompt__c,Prompt_Information__c from Plant_Asset_Prompt_Detail__c where Prompt_Information__c IN: promptInfoIds and is_Deleted__c= FALSE];
        for(Plant_Asset_Prompt_Detail__c plantAssetPromptDetail :plantAssetPromptDEtails){
            if(plantAssetPromptDetail.Prompt_Information__c != NULL && plantAssetPromptDetail.Previous_Plant_Asset_Prompt__c  != NULL){
            promptIdToPreviousPlantAssetDetail.put(plantAssetPromptDetail.Prompt_Information__c,plantAssetPromptDetail.Previous_Plant_Asset_Prompt__c );
            }
        }
       evaluationValueMap.put('promptIdToPreviousPlantAssetDetail',promptIdToPreviousPlantAssetDetail);
       return evaluationValueMap;
    }

    @AuraEnabled
    public static String getallEvaluationValues(String plantAssetId){
        List<String> pfServiceProducts = Utils.getAttrReqSysNamesFrmG1(plantAssetId);
        String evaluationValueString = '';
        list<Evaluation_Value__c> evaluationValueLst = [SELECT Id, Test_Id__c, Evaluation__r.Category__c, Result__c,
        Account_Plant__c, Evaluation__r.Name, Evaluation__r.Group_1__c, 
            Evaluation__r.Result__c, Evaluation__r.Sub_Category__c, Evaluation__r.Prompt_Information__r.Id, Evaluation__r.Prompt_Information__r.Prompt_Id__c FROM Evaluation_Value__c WHERE
            Logic_Result__c = true AND Account_Plant__c =: plantAssetId AND Evaluation__r.Sub_Category__c != null
            AND Evaluation__r.Category__c != null AND Show_In_Report__c = true AND Evaluation__r.Group_1__c != null AND Evaluation__r.Products__c IN :pfServiceProducts];
        if(evaluationValueLst.size()>0){
            Map<String,Object> evaluationValueMap = CapabilityReportController.getEvaluationValueMap(evaluationValueLst);
            evaluationValueString = JSON.serialize(evaluationValueMap);
            return evaluationValueString;
        }else{
            return evaluationValueString;
        }
    }

    @AuraEnabled
    public static String getallEvaluation(){ 
        String evaluationString = NULL;
        Map<String,Set<String>> evaluationMapLsts = new Map<String,Set<String>>();
        for(Evaluation__c evaluationRecord : [SELECT Id, Category__c, Sub_Category__c 
                            FROM Evaluation__c WHERE
                            Category__c != null AND Sub_Category__c != null]){
            String CategoryName = evaluationRecord.Category__c;
            if (!evaluationMapLsts.containsKey(CategoryName)){
                evaluationMapLsts.put(CategoryName, new Set<String>());
            }
            evaluationMapLsts.get(CategoryName).add(evaluationRecord.Sub_Category__c);
        }
        if(evaluationMapLsts.size()>0){
            Map<String,Object> evaluationMap = new Map<String,Object>();
            evaluationMap.put('evaluation',evaluationMapLsts);
            evaluationString = JSON.serialize(evaluationMap);
            return evaluationString;
        }else{
            return evaluationString;
        }
    }
}