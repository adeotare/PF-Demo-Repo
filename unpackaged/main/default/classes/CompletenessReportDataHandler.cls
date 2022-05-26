public with sharing class CompletenessReportDataHandler {
    public static Map<String,Integer> attrCompletedCountMap = new Map<String,Integer>();
    public static Map<String,Integer> attrTotalCountMap = new Map<String,Integer>();
    public static List<Asset_Builder_Report_Data__c> reportDataCreationList = new List<Asset_Builder_Report_Data__c>();
    public static Map<String,List<String>> systemMap = new Map<String,List<String>>();
    public static Map<String,String> requiredMap = new Map<String,String>{
        'Yes' => 'Required',
        'No' => 'Optional'
    };
    public static Plant_Asset_Prompt_Detail__c pltAstPrtDtl = new Plant_Asset_Prompt_Detail__c(); 
    public static void completenessReportDataCreation(String plantId, List<Id> promptIds, Map<String,List<String>> systemMap, String plantAssetPromptDetailId) {
        pltAstPrtDtl = [SELECT Id, Name, Is_Capability_Report_Generated__c, Is_Completeness_Report_Generated__c 
                    FROM Plant_Asset_Prompt_Detail__c 
                    WHERE Id =: plantAssetPromptDetailId];
        try{
            Account_Plant__c plantAsset = [SELECT Id, TEM_Version__c FROM Account_Plant__c WHERE Id=: plantId];
            if(systemMap.size() <= 0){
                for(Attribute_Requirement_Valid_Values__mdt attrVal : [SELECT Id, DeveloperName,Requirement__c,System__c FROM Attribute_Requirement_Valid_Values__mdt]){
                    if(!systemMap.containsKey(attrVal.System__c)){
                        List<String> strValue = new List<String>();
                        strValue.add(attrVal.Requirement__c);
                        systemMap.put(attrVal.System__c, strValue);
                    }else{
                        List<String> strValue = systemMap.get(attrVal.System__c);
                        strValue.add(attrVal.Requirement__c);
                    }
                }
                System.debug('strValue-->'+systemMap);
            }else{
                systemMap = systemMap;
            }
            
            List<String> fieldNames = new List<String>{'Is_Completed__c','Is_Value_Defaulted__c'};
            for(String sys : systemMap.keySet()){ 
                for(String requiredSys : systemMap.get(sys)){
                    for(String fieldName : fieldNames){
                        reportDataAggregateQuery(plantId, promptIds, sys, requiredSys, fieldName, String.valueOf(plantAsset.TEM_Version__c));
                    }
                }
            }
            if(attrCompletedCountMap.size() > 0){
                reportDataCreation(plantId);
            }
        }catch(Exception exceptionDetails){
            System.debug('error message ' + exceptionDetails.getMessage() + ' line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('assetReportDataCreation',exceptionDetails.getMessage(),
                exceptionDetails.getLineNumber(), plantId, '');
            insert errorLogInstance;
        }
    }
    public static void reportDataAggregateQuery(Id plantId, List<Id> promptIds, String sys, String requiredSys, String fieldName, String TEMVersion){
        try{
            String query = 'SELECT Prompt_Information__c, Base_Asset_Template__c,' + (String.isBlank(fieldName) ? '' : fieldName + ',');
            query += ' Count(Id)cnt FROM Attribute_Value__c';
            query += ' WHERE Account_Plant__r.Id =: plantId AND Site_Metadata__r.Is_Deleted__c = FALSE';
            if(promptIds.size() > 0){
                query += ' AND Prompt_Information__c IN: promptIds';
            }
            query += ' AND Attribute__c IN (SELECT Core_Attribute__c FROM Attribute_Requirement__c WHERE';
            query += ' System__c =: sys AND Required__c =: requiredSys AND TEM_Version__c =: TEMVersion)';
            query += ' GROUP BY ROLLUP(Prompt_Information__c, Base_Asset_Template__c' + (String.isBlank(fieldName) ? '' : ',' + fieldName) +')'; 
            query += ' ORDER BY Base_Asset_Template__c NULLS last ' + (String.isBlank(fieldName) ? '' : ',' + fieldName) + ' NULLS last';
            for(AggregateResult agrResultRow : Database.query(query)){                    
                if(agrResultRow.get('Prompt_Information__c') != NULL && agrResultRow.get('Base_Asset_Template__c') != NULL){
                    String promptId = (String)agrResultRow.get('Prompt_Information__c');
                    String baseAssetId = (String)agrResultRow.get('Base_Asset_Template__c');
                    Integer cnt = (Integer)agrResultRow.get('cnt');
                    String mapKey = promptId + '-' + baseAssetId + '-' + sys + '-' + requiredMap.get(requiredSys) + ((fieldName == 'Is_Value_Defaulted__c')?' (Default)':'');
                
                    if(agrResultRow.get(fieldName) != NULL){
                        Integer recCount;
                        if((Boolean)agrResultRow.get(fieldName)){
                            recCount = cnt;
                        }else{
                            recCount = 0;
                        }
                        attrCompletedCountMap.put(mapKey, recCount);
                    }else if(agrResultRow.get(fieldName) == NULL){
                        attrTotalCountMap.put(mapKey, cnt);
                    }
                }
            }
        }catch(Exception exceptionDetails){
            System.debug('error message ' + exceptionDetails.getMessage() + ' line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('reportDataAggregateQuery',exceptionDetails.getMessage(),
                exceptionDetails.getLineNumber(), plantId, '');
            insert errorLogInstance;
        }
    }
    public static void reportDataCreation(Id plantId){
        try{
            if(attrCompletedCountMap.size() > 0){
                for(String attrCompletedKey : attrCompletedCountMap.keySet()){
                    List<String> attrCompletedKeySplit = attrCompletedKey.split('-');
                    String promptId, baseAssetId, systemName, requiredSys;
                    Integer cnt;
                    if(attrCompletedKeySplit.size() == 4){
                        promptId = attrCompletedKeySplit[0];
                        baseAssetId = attrCompletedKeySplit[1];
                        systemName = attrCompletedKeySplit[2];
                        requiredSys = attrCompletedKeySplit[3];
                        cnt = attrCompletedCountMap.get(attrCompletedKey);
                    }
                    Asset_Builder_Report_Data__c assetReportCreation = new Asset_Builder_Report_Data__c();
                    assetReportCreation.Account_Plant__c = plantId; 
                    assetReportCreation.Prompt_Information__c = promptId;
                    assetReportCreation.Base_Asset_Template__c = baseAssetId;
                    assetReportCreation.System__c = systemName;
                    assetReportCreation.Type__c = requiredSys;
                    assetReportCreation.External_Id__c = plantId+'-'+promptId+'-'+baseAssetId+'-'+systemName+'-'+requiredSys;
                    assetReportCreation.Total_Completed_Attribute_Count__c = cnt;
                    assetReportCreation.Total_Attribute_Count__c = attrTotalCountMap.get(attrCompletedKey);
                    reportDataCreationList.add(assetReportCreation);
                }
            }
            if(reportDataCreationList.size() > 0){
                upsert reportDataCreationList External_Id__c;
                pltAstPrtDtl.Is_Completeness_Report_Generated__c = true;
            }
        }catch(Exception exceptionDetails){
            pltAstPrtDtl.Is_Completeness_Report_Generated__c = false;
            System.debug('error message ' + exceptionDetails.getMessage() + ' line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('reportDataCreation',exceptionDetails.getMessage(),
                exceptionDetails.getLineNumber(), plantId, '');
            insert errorLogInstance;
        }
        update pltAstPrtDtl;
    }    
}