public with sharing class G1BulkImportButtonHndlr {
    @AuraEnabled
    /*
     To check whether selected plant asset is new to asset build or only the G1 record exist ro the build started. 
     Based on which the relevant opration will be done.
     If the G1 record exsit, system allow user to download the asset builder prompt template
     If the no G1 record exsit, system prompt user to click save in G1 prompt and click export button
     If other prompt also exist, system prompt user to delete all the current asset build records and export      
    */
    public static String getG1RecordDetails(String plantAssetId){
         try {
             Integer noOfprompts = 0;
              List<Plant_Asset_Prompt_Detail__c> plantAssetPromptDetailLst = 
                  [SELECT id, Name,Prompt_Information__r.Name, Bulk_Import_Type__c FROM Plant_Asset_Prompt_Detail__c 
                  WHERE Account_Plant__c =:plantAssetId and Is_Deleted__c = False AND 
                  Prompt_Information__r.Name =: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT];
 
             if(plantAssetPromptDetailLst.size() == 0){
                 return 'isNewPlant';
             }else if(plantAssetPromptDetailLst[0].Prompt_Information__r.Name == Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT && 
                         plantAssetPromptDetailLst[0].Bulk_Import_Type__c != Constants.Manual && 
                         plantAssetPromptDetailLst[0].Bulk_Import_Type__c != Constants.COMPLETED){
                 return 'enableBulkImportButton';
             }else if(plantAssetPromptDetailLst[0].Bulk_Import_Type__c == Constants.Manual || 
                         plantAssetPromptDetailLst[0].Bulk_Import_Type__c == Constants.COMPLETED){
                 return 'buildStarted'; 
             }
             
             return null;
         } catch (Exception exceptionDetails) {
             String errorMessage = 'Please Contact Administrator '+ exceptionDetails.getMessage();
             System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
             throw new AuraHandledException(errorMessage);
          }
    }
 }