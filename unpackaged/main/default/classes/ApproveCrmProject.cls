public with sharing class ApproveCrmProject {
    
   @AuraEnabled
        public static list <CRM_Project__c> AppRec(string RecId) {
            list <CRM_Project__c> ProjectList = new list<CRM_Project__c>();
            system.debug('Recordid  : ' +RecId);
            for(CRM_Project__c PPlist : [SELECT Id, Name,Approval_Status__c
                                         from CRM_Project__c where id =:RecId AND Approval_Status__c = 'Pending'] )
            
            {  PPlist.Approval_Status__c='Approved';
               ProjectList.add(PPlist);
                                             
                                         }

             update ProjectList;
            system.debug('list:'  + Projectlist);
           
            return ProjectList;
        } 
     @AuraEnabled
        public static list <CRM_Project__c> RejRec(string RecId) {
            list <CRM_Project__c> ProjectList1 = new list<CRM_Project__c>();
            system.debug('Recordid  : ' +RecId);
            for(CRM_Project__c PPlist1 : [SELECT Id, Name,Approval_Status__c
                                         from CRM_Project__c where id =:RecId AND Approval_Status__c = 'Pending'] )
            
            {  PPlist1.Approval_Status__c='Rejected';
               ProjectList1.add(PPlist1);
                                             
                                         }

             update ProjectList1;
            system.debug('list:'  + Projectlist1);
           
            return ProjectList1;
        } 
}