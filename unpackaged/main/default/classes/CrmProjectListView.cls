public with sharing class CrmProjectListView {

        @AuraEnabled
        public static List <CRM_Project__c> fetchDetails() {
            List<CRM_Project__c> ProjectList = new list<CRM_Project__c>();
            Projectlist=[SELECT Id, Name, Project_Name__c   ,Approval_Status__c,Formula_Approval_Status__c,Account__c,Project_Type__c, Program_Name__c,Installation_Commencement_Date__c,
                                        Project_visibility__c,External_Status__c, Product__c  from CRM_Project__c where Project_visibility__c = 'Visible to customer' 

 ];
            system.debug('list:'  + Projectlist);
           
            return ProjectList;
        }
}