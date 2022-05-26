public with sharing class CompletenessReport {
    @AuraEnabled
    public Static String getCompletenessReportData(String plantAssetId, String promptType) {
        Map<String, Object> reportInputData = new  Map<String, Object>();
 
        List<String> pfServiceProducts = Utils.getAttrReqSysNamesFrmG1(plantAssetId);
        List<Asset_Builder_Report_Data__c> assetBuilderReportData = new List<Asset_Builder_Report_Data__c>();
        Map<String, String> promptInfoAndId = new Map<String, String>();
        Set<Id> promptInfoIds = new Set<Id>();

        for(Asset_Builder_Report_Data__c assetBuilderReportDataRec : [SELECT Id, Name, Base_Asset_Template__r.Name, Is_Archived__c, Account_Plant__c, 
            Prompt_Information__r.Name, System__c, Total_Attribute_Count__c, Total_Completed_Attribute_Count__c, Type__c, 
            Prompt_Information__r.CSV_Sorting_Order__c, Prompt_Information__r.Prompt_Id__c, Prompt_Information__c   
            FROM Asset_Builder_Report_Data__c 
            WHERE Account_Plant__c =: plantAssetId AND Prompt_Information__r.Type__c =: promptType
            AND Is_Archived__c = FALSE ORDER BY Prompt_Information__r.CSV_Sorting_Order__c DESC]){
                promptInfoIds.add(assetBuilderReportDataRec.Prompt_Information__c);
                assetBuilderReportData.add(assetBuilderReportDataRec);
                promptInfoAndId.put(assetBuilderReportDataRec.Prompt_Information__r.Name, assetBuilderReportDataRec.Prompt_Information__r.Prompt_Id__c);
        }
        
        Map<String, Plant_Asset_Prompt_Detail__c> promptInfoAndPapdRec = new Map<String, Plant_Asset_Prompt_Detail__c>();

        for(Plant_Asset_Prompt_Detail__c papdRec : [SELECT Id, Previous_Plant_Asset_Prompt__c, Base_Asset__c, Prompt_Information__r.Name
            FROM Plant_Asset_Prompt_Detail__c 
            WHERE Account_Plant__c =: plantAssetId 
            AND Is_Deleted__c = FALSE
            AND Prompt_Information__c =: promptInfoIds]){
                promptInfoAndPapdRec.put(papdRec.Prompt_Information__r.Name, papdRec);
        }
        
        Map<String, String> baseAssetAndPromptNameToAssetCount = new Map<String, String>();
        List<String> noAssetPromptsInAssetBuilder = new List<String>();
        for(NoAssetPromptsInAssetBuilder__mdt noAssetInPrompt : [SELECT Label FROM  NoAssetPromptsInAssetBuilder__mdt]){
            noAssetPromptsInAssetBuilder.add((noAssetInPrompt.Label));
        }
        
        for(AggregateResult baseAssetNameAndCount : [SELECT Count(Id)assetCount , Base_Asset_Template__r.Name baseAssetName , Prompt_Information__r.Name promptName
            FROM Site_Metadata__c     
            WHERE Account_Plant__c =: plantAssetId 
            AND Is_Deleted__c = FALSE
            AND Prompt_Information__c =: promptInfoIds GROUP BY Base_Asset_Template__r.Name,Prompt_Information__r.Name]){
                if(baseAssetNameAndCount.get('baseAssetName') != NULL && baseAssetNameAndCount.get('promptName') != NULL){
                    if(noAssetPromptsInAssetBuilder.contains(String.valueOf(baseAssetNameAndCount.get('promptName')))) {
                        baseAssetAndPromptNameToAssetCount.put(String.valueOf(String.valueOf(baseAssetNameAndCount.get('promptName'))+'-'+baseAssetNameAndCount.get('baseAssetName')), '');
                    } else{
                        baseAssetAndPromptNameToAssetCount.put(String.valueOf(String.valueOf(baseAssetNameAndCount.get('promptName'))+'-'+baseAssetNameAndCount.get('baseAssetName')), String.valueOf(baseAssetNameAndCount.get('assetCount'))); 
                    }
                }
                }

        reportInputData.put('systemName', pfServiceProducts);
        reportInputData.put('completnessReport', assetBuilderReportData);
        reportInputData.put('promptInfoAndId', promptInfoAndId);
        reportInputData.put('promptInfoAndPapdRec', promptInfoAndPapdRec);
        reportInputData.put('baseAssetAndPromptNameToAssetCount', baseAssetAndPromptNameToAssetCount);
        return JSON.serialize(reportInputData);
    }
}