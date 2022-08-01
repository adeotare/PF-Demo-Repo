/**
 * The Test class for apex ProgramController.   
 * @param  :  
 * @return :  
 */
@isTest
public class ProgramControllerTest {
	static testmethod void testAddProgram() {
        Pricebook2 pb = TestDataFactory.createPriceBook();
        insert pb;
        
        Account accnt = TestDataFactory.createAccount(pb.Id);
        insert accnt;
        
        Program__c progm = TestDataFactory.createProgram(accnt.Id);
        insert progm;
        
        project_cloud__Project__c projectRecord = TestDataFactory.createCCProjectTemplate('Monitoring Implementation',accnt.Id);
        insert projectRecord;
        List<string> projectIds = new List<string>();
        projectIds.add(projectRecord.Id);
        Test.startTest();
        	ProgramController.fetchData(progm.Id);
        	ProgramController.addProjects(progm.Id, JSON.serialize(projectIds));
        Test.stopTest();
        project_cloud__Project__c projectProcessed = [select Program_Name__c from project_cloud__Project__c where id =:projectRecord.Id];
        system.debug('::projectProcessed'+projectProcessed);
        System.assertEquals(progm.Id,projectProcessed.Program_Name__c);
    }
}