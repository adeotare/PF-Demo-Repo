public with sharing class CompletenessReportParent {
    @AuraEnabled
    public Static String getCompletenessReportSection() {
        List<CompletenessReportSectionConfig__mdt> promptTypeLst  = new List<CompletenessReportSectionConfig__mdt>();
        for(CompletenessReportSectionConfig__mdt promptType : 
            [SELECT Id, App_Name__c, Prompt_Type__c, Section_Label__c, Report_Display_Order__c, 
            Summary_Report_First_Column_Label__c
            FROM CompletenessReportSectionConfig__mdt WHERE App_Name__c = 'Asset Builder'
            ORDER BY Report_Display_Order__c ASC]){
                promptTypeLst.add(promptType);
        }

        return JSON.serialize(promptTypeLst);
    }
}