public with sharing  class SubmitApproval {

    @AuraEnabled
    public static list<CRM_Project__c> saveRec(string RecId){
        
        system.debug('Id: '+RecId); 
        list<CRM_Project__c> ListDeatils =New list<CRM_Project__c>();
            for(CRM_Project__c appRec : [SELECT Id, Name,Approval_Status__c 
                                        from CRM_Project__c where id =:RecId   ])
            {
                appRec.Approval_Status__c='Pending';
                ListDeatils.add(appRec);
            }
        update ListDeatils; 
        system.debug('Id: '+RecId); 
        Return ListDeatils;
    }
}