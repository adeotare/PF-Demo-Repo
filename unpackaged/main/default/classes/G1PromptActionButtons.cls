public with sharing class G1PromptActionButtons {
    @AuraEnabled
    public static string checkPlantAssetPromptDetail(String plantAssetId, String promptInfo){
        try{
            String result;
            Prompt_Information__c promptInformation = (Prompt_Information__c) JSON.deserialize(promptInfo, Prompt_Information__c.class);
            Account_Plant__c plantAssetDet = Utils.queryPlantAsset(plantAssetId);

            List<Plant_Asset_Prompt_Detail__c> papdLst = new List<Plant_Asset_Prompt_Detail__c>();
            for(Plant_Asset_Prompt_Detail__c papd :  [SELECT Id,Base_Asset__c,Parent_Asset_Prompt_Name__c, Account_Plant__c, Previous_Plant_Asset_Prompt__c, Is_Deleted__c,
                Previous_Plant_Asset_Prompt__r.Prompt_Information__r.Name, Prompt_Information__c, Name, Validate_On_Previous__c, 
                Prompt_Information__r.CSV_Sorting_Order__c, Capability_Report_Status__c, Completeness_Report_Status__c,
                Account_Plant__r.Asset_Builder_Status__c
                FROM Plant_Asset_Prompt_Detail__c 
                WHERE Account_Plant__c =: plantAssetDet.Id 
                AND Is_Deleted__c = false 
                AND Prompt_Information__r.Name =: promptInformation.Name]){
                    papdLst.add(papd);
            }

            if(papdLst.size() > 0){
                result = JSON.serialize(papdLst);
            }else{
                result = 'No Data';
            }
            
            return result;
        }catch(Exception exp){
            System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
            throw new AuraException(' Please Contact Administrator. '+exp.getMessage());
        }
    }
}