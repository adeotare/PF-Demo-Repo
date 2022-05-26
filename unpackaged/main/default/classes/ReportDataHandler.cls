public with sharing class ReportDataHandler {
    Map<String,Integer> attrCompletedCountMap = new Map<String,Integer>();
    Map<String,Integer> attrTotalCountMap = new Map<String,Integer>();

    List<Asset_Builder_Report_Data__c> reportDataCreationList = new List<Asset_Builder_Report_Data__c>();
    Map<String,List<String>> systemMap = new Map<String,List<String>>();
    Map<String,String> requiredMap = new Map<String,String>{
        'Yes' => 'Required',
        'No' => 'Optional'
    };
    public Plant_Asset_Prompt_Detail__c pltAstPrtDtl;
    public static String plantAssetId;

    public Void assetReportDataCreation(Id plantId, List<Id> promptIds) {
        try{
            plantAssetId = plantId;
            systemMap.put('Drive', new List<string>{'Yes','No'});
            systemMap.put('Drive Plus', new List<string>{'Yes','No'});
            List<String> fieldNames = new List<String>{'Is_Completed__c','Is_Value_Defaulted__c'};

            for(String sys : systemMap.keySet()){ 
                for(String requiredSys : systemMap.get(sys)){
                    for(String fieldName : fieldNames){
                        reportDataAggregateQuery(plantId, promptIds, sys, requiredSys, fieldName);
                    }
                }
            }

            if(attrCompletedCountMap.size() > 0){
                reportDataCreation(plantId);
            }
        }catch(Exception exp){
            System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('reportDataCreation',exp.getMessage(), exp.getLineNumber(), plantAssetId, '');
            insert errorLogInstance;
        }
    }

    public void reportDataAggregateQuery(Id plantId, List<Id> promptIds, String sys, String requiredSys, String fieldName){
        try{
            String query = 'SELECT Prompt_Information__c, Base_Asset_Template__c,' + (String.isBlank(fieldName) ? '' : fieldName + ',');
            query += ' Count(Id)cnt FROM Attribute_Value__c';
            query += ' WHERE Plant_Asset__r.Id =: plantId AND Site_Metadata__r.Is_Deleted__c = FALSE';
            if(promptIds.size() > 0){
                query += ' AND Prompt_Information__c IN: promptIds';
            }
            query += ' AND Attribute__c IN (SELECT Core_Attribute__c FROM Attribute_Requirement__c WHERE';
            query += ' System__c =: sys AND Required__c =: requiredSys)';
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
        }catch(Exception exp){
            System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('reportDataCreation',exp.getMessage(), exp.getLineNumber(), plantAssetId, '');
            insert errorLogInstance;
        }
    }

    public void queryExsistingReportData(Id plantId, List<Id> promptIds){
        try{
            String query = 'SELECT Id, Name, Is_Archived__c FROM Asset_Builder_Report_Data__c WHERE Account_Plant__c =: plantId';
            if(promptIds.size()>0){
                query += ' AND Prompt_Information__c IN: promptIds';
            }

            List<Asset_Builder_Report_Data__c> exsistingReportDataArchived = new List<Asset_Builder_Report_Data__c>();
            for(Asset_Builder_Report_Data__c reportData : Database.query(query)){
                reportData.Is_Archived__c = TRUE;
                exsistingReportDataArchived.add(reportData);
            }

            if(exsistingReportDataArchived.size() > 0){
                update exsistingReportDataArchived;
            }
            
            assetReportDataCreation(plantId, promptIds);
        }catch(Exception exp){
            System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('reportDataCreation',exp.getMessage(), exp.getLineNumber(), plantAssetId, '');
            insert errorLogInstance;
        }
    }

    public void reportDataCreation(Id plantId){
        Savepoint sp;
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
                    assetReportCreation.Total_Completed_Attribute_Count__c = cnt;
                    assetReportCreation.Total_Attribute_Count__c = attrTotalCountMap.get(attrCompletedKey);
                    reportDataCreationList.add(assetReportCreation);
                }
            }
            sp = Database.setSavepoint();
            pltAstPrtDtl = [SELECT Id, Name, Capability_Report_Status__c, Completeness_Report_Status__c, Prompt_Information__c, Account_Plant__c  
                    FROM Plant_Asset_Prompt_Detail__c 
                    WHERE Account_Plant__c =:plantId  AND Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND Is_Deleted__c = FALSE];
            pltAstPrtDtl.Completeness_Report_Status__c = 'Completed';
           
            if(reportDataCreationList.size() > 0){
                insert reportDataCreationList;
                update pltAstPrtDtl;
            }
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            System.debug('error message ' + exceptionDetails.getMessage() + ' line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('reportDataCreation',exceptionDetails.getMessage(), 
                                                                 exceptionDetails.getLineNumber(), plantAssetId, '');
            insert errorLogInstance;
            pltAstPrtDtl.Completeness_Report_Status__c = 'Completed - Error';
            update pltAstPrtDtl;
        }
        
    } 
}