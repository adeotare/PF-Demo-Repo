public with sharing  class SubmitApproval {

    @AuraEnabled
    public static list<CRM_Project__c> saveRec(string RecId){
        
        system.debug('Id: '+RecId); 
        list<CRM_Project__c> ListDetails =New list<CRM_Project__c>();
            for(CRM_Project__c appRec : [SELECT Id, Name,Approval_Status__c,Project_visibility__c	
                                        from CRM_Project__c where id =:RecId  ])
            {
                appRec.Approval_Status__c='Pending';
                ListDetails.add(appRec);
            }
             
            
        try{  
        update ListDetails; 
        }catch(exception e){
            
            throw new AuraException(e.getMessage());
        }
        system.debug('Id: '+RecId); 
        Return ListDetails;
    }
}