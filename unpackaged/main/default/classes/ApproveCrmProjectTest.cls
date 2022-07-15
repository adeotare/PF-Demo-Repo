@istest
public class ApproveCrmProjectTest {
@istest
    static void ApproveTest()
    {
        CRM_Project__c  c= new CRM_Project__c(
        name='Testing',
        Approval_Status__c='Pending'
        );
        insert c;
         string RecId=c.id;
        ApproveCrmProject.AppRec(RecId);
        CRM_Project__c cc=[select id,name,Approval_Status__c from CRM_Project__c where id=:RecId];
        
        system.assertEquals('Approved', cc.Approval_Status__c);
    }
    
    // Test for Reject Method
    @istest
    static void RejectTest()
    {
        CRM_Project__c  c= new CRM_Project__c(
        name='Testing',
        Approval_Status__c='Pending'
        );
        insert c;
         string RecId=c.id;
        ApproveCrmProject.RejRec(RecId);
        CRM_Project__c cc=[select id,name,Approval_Status__c from CRM_Project__c where id=:RecId];
        
        system.assertEquals('Rejected', cc.Approval_Status__c);
        
    }
        
         
}