// Test Class for Submit
//
@istest
public class SubmitApprovalTest {
    @istest
    static void saveRecTest(){
        
        CRM_Project__c c= new CRM_Project__c(
            name='Testing1',
            Project_visibility__c='Visible to customer'
             );
        // inserting the project record 
        insert c;
        system.debug('crmId..:' +c);
        // to check the crm project id with the string id 
        string RecId =c.Id;
        SubmitApproval.saveRec(RecId);
        CRM_Project__c cc=[select id,name,Approval_Status__c,Project_visibility__c from CRM_Project__c where id=:RecId ];
        system.assertequals('Pending',cc.Approval_Status__c);
      
    }

}