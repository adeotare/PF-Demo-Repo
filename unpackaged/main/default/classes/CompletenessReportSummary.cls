public with sharing class CompletenessReportSummary {
    @AuraEnabled
    public Static String getCompletenessReportSummary(String plantAssetId) {
        Map<String, Object> reportInputData = new  Map<String, Object>();

        List<String> pfServiceProducts = Utils.getAttrReqSysNamesFrmG1(plantAssetId);
        List<Asset_Builder_Report_Data__c> assetBuilderReportData = [SELECT Id, Name, Base_Asset_Template__r.Name, Is_Archived__c, Account_Plant__c, Prompt_Information__r.Name, System__c,
        Total_Attribute_Count__c, Total_Completed_Attribute_Count__c, Type__c, Prompt_Information__r.CSV_Sorting_Order__c,
        Prompt_Information__r.Type__c    
        FROM Asset_Builder_Report_Data__c 
        WHERE Account_Plant__c =: plantAssetId
        AND Is_Archived__c = FALSE ORDER BY Prompt_Information__r.CSV_Sorting_Order__c DESC];
            
        List<CompletenessReportSectionConfig__mdt> promptTypeLst  = new List<CompletenessReportSectionConfig__mdt>();
        for(CompletenessReportSectionConfig__mdt promptType : 
            [SELECT Id, App_Name__c, Prompt_Type__c, Section_Label__c, Report_Display_Order__c,
            Summary_Report_First_Column_Label__c
            FROM CompletenessReportSectionConfig__mdt WHERE App_Name__c = 'Asset Builder'
            ORDER BY Report_Display_Order__c ASC]){
                promptTypeLst.add(promptType);
        }

        reportInputData.put('systemName', pfServiceProducts);
        reportInputData.put('completnessReport', assetBuilderReportData);
        reportInputData.put('promptType', promptTypeLst);

        return JSON.serialize(reportInputData);
    }
}