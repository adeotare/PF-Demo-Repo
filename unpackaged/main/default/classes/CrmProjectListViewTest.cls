/**
 * The Test class for apex CrmProjectListView.   
 * @param  :  
 * @return :  
 */
@isTest
public class CrmProjectListViewTest {
    static testmethod void testAddProgram() {
        Pricebook2 pb = TestDataFactory.createPriceBook();
        insert pb;
        
        Account accnt = TestDataFactory.createAccount(pb.Id);
        insert accnt;
        
        project_cloud__Project__c projectRecord = TestDataFactory.createCCProjectTemplate('Monitoring Implementation',accnt.Id);
        insert projectRecord;
        Test.startTest();
        	CrmProjectListView.fetchDetails();
        Test.stopTest();
        CRM_Project__c crmProcessed = [select Related_Projects__c from CRM_Project__c where Related_Projects__c =:projectRecord.Id];
        System.assertEquals(crmProcessed.Related_Projects__c,projectRecord.Id);
    }
}