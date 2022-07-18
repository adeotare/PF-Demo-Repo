/**
 * The Test class for apex AddPPTControllerV2Test.   
 * @param  :  
 * @return :  
 */
@isTest
public class AddPPTControllerV2Test {
    static testmethod void testAddPPT() {
        Product2 pr = TestDataFactory.createProductWithCode('DR-PR-PS-OT-IM-ST-ST-N/A');
        insert pr;
        Pricebook2 pb = TestDataFactory.createPriceBook();
        insert pb;
        Account accnt = TestDataFactory.createAccount(pb.Id);
        insert accnt;
        Plant_Product_Transaction__c ppt1 = TestDataFactory.createPPT('Ordered', accnt.Id, pr.Id);
       
        insert ppt1;
        project_cloud__Project__c projectRecord = TestDataFactory.createCCProjectTemplate('Monitoring Implementation',accnt.Id);
        projectRecord.project_cloud__IsTemplate__c = true;
        insert projectRecord;
        List<string> pptIds = new List<string>();
        pptIds.add(ppt1.Id);
        Test.startTest();
        	AddPPTControllerV2.getExistingPPTList(projectRecord.id);
        	AddPPTControllerV2.addProjects(projectRecord.id, JSON.serialize(pptIds));
        Test.stopTest();
        Plant_Product_Transaction__c pptProcessed = [select Is_Project_Added__c from Plant_Product_Transaction__c where id =:ppt1.Id];
        system.debug('::pptProcessed'+pptProcessed);
        System.assertEquals(true,pptProcessed.Is_Project_Added__c);
    }
}