/**
 * TODO - Calls from Finish button in LWC
 * Publish Two Platform events for Capability and Completeness Reports.  
 * */ 
public with sharing class TriggerPEForReports {
    public static String plantAssetId;
    /*
    * Publish Platform Events for Capability and Completeness report Platform Events.
    @param {String} plantAssetId - Pass Plant Asset for data creation for reports.
    */
    @AuraEnabled
    public static String createPE(String plantAssetId){
        Map<String, Object> responseMap = new Map<String, Object>();
        Savepoint sp = Database.setSavepoint();
        try{
            plantAssetId = plantAssetId;
            Plant_Asset_Prompt_Detail__c pltAstPrtDtl = [SELECT Id, Name, Capability_Report_Status__c,Completeness_Report_Status__c, 
                    Prompt_Information__c, Account_Plant__c,  Account_Plant__r.Asset_Builder_Status__c, Report_Generated_Datetime__c 
                    FROM Plant_Asset_Prompt_Detail__c 
                    WHERE Account_Plant__c =:plantAssetId AND Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT
                    AND Is_Deleted__c = false ];
                    
            if(pltAstPrtDtl.Account_Plant__r.Asset_Builder_Status__c == ConstantsPicklistValues.PLANT_ASSET_ASSET_BUILDER_STATUS_IN_PROGRESS){
                Account_Plant__c plantAsset= new Account_Plant__c (id = pltAstPrtDtl.Account_Plant__c);
                plantAsset.Asset_Builder_Status__c = ConstantsPicklistValues.PLANT_ASSET_ASSET_BUILDER_STATUS_COMPLETED;
                update plantAsset;
            }

            //Evaluation Value Creation
            Asset_Builder_Async_Job__e asyncEV = new Asset_Builder_Async_Job__e(); 
            asyncEV.Job_Type__c = Constants.CAPABILITY_REPORT; 
            asyncEV.Plant_Asset_Id__c = plantAssetId; 
            EventBus.publish(asyncEV);
            pltAstPrtDtl.Capability_Report_Status__c = ConstantsPicklistValues.PLANT_ASSET_PROMPT_DETAIL_REPORT_STATUS_IN_PROGRESS;
            pltAstPrtDtl.Report_Execution_By_User__c = UserInfo.getUserId(); 

            //Report Data Handler - Completeness report
            Asset_Builder_Async_Job__e asyncRDHdlr = new Asset_Builder_Async_Job__e(); 
            asyncRDHdlr.Job_Type__c = Constants.COMPLETENESS_REPORT; 
            asyncRDHdlr.Plant_Asset_Id__c = plantAssetId; 
            EventBus.publish(asyncRDHdlr);
            pltAstPrtDtl.Completeness_Report_Status__c = ConstantsPicklistValues.PLANT_ASSET_PROMPT_DETAIL_REPORT_STATUS_IN_PROGRESS;
            pltAstPrtDtl.Report_Execution_By_User__c = UserInfo.getUserId();
            pltAstPrtDtl.Report_Generated_Datetime__c = System.now();
            update pltAstPrtDtl;

            String g1PromptId = PromptNavigationHelper.findPromptId(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
            Boolean substationRFICreation = RFIDataCreation.abSubstationRFICreation(plantAssetId);
            responseMap.put('result', true);
            responseMap.put('g1PromptId', g1PromptId);
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            insert Utils.catchErrorLogs('createPE',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetId, '');
            responseMap.put('result', false);
            responseMap.put('g1PromptId', 'None');
        }
        return JSON.serialize(responseMap);
    }
}