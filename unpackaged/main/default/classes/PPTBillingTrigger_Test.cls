@isTest
public class PPTBillingTrigger_Test {
    static testmethod void testAddPPT() {
        Product2 pr = TestDataFactory.createProductWithCode('DR-PR-PS-OT-IM-ST-ST-N/A');        
        insert pr;
        Product2 pr1 = TestDataFactory.createProductWithCode('DR-PR-PS-OT-IM-ST-ST-N/A');  
        pr1.Product_Category__c = 'Professional Services';
        pr1.Product_Line__c = 'Add-ons';
        pr1.Family = 'Greenbyte';
        insert pr1;
        
        Product2 pr2 = TestDataFactory.createProductWithCode('DR-PR-PS-OT-IM-ST-ST-N/A');        
        pr2.Product_Category__c = 'Software';
        pr2.Product_Line__c = 'Ekho';
        pr2.Family = 'Ekhosoft';
        insert pr2;
        Product2 pr3 = TestDataFactory.createProductWithCode('DR-PR-PS-OT-IM-ST-ST-N/A');        
        pr3.Product_Category__c = 'Software';
        pr3.Product_Line__c = 'Core Lite';
        pr3.Family = 'Drive';
        insert pr3;
        
        Pricebook2 pb = TestDataFactory.createPriceBook();
        insert pb;
        Account accnt = TestDataFactory.createAccount(pb.Id);
        insert accnt;
        
        Plant_Product_Transaction__c ppt1 = TestDataFactory.createPPT('Ordered', accnt.Id, pr.Id);
        insert ppt1;
        
        Plant_Product_Transaction__c ppt2 = TestDataFactory.createPPT('Ordered', accnt.Id, pr1.Id);
        Insert ppt2;
            
        Plant_Product_Transaction__c ppt3 = TestDataFactory.createPPT('Ordered', accnt.Id, pr2.Id);
        Insert ppt3;
       
        Plant_Product_Transaction__c ppt4 = TestDataFactory.createPPT('Ordered', accnt.Id, pr3.Id);
        Insert ppt4;
            
        project_cloud__Project__c projectRecord = TestDataFactory.createCCProjectTemplate('Monitoring Implementation',accnt.Id);
        projectRecord.project_cloud__IsTemplate__c = true;
        insert projectRecord;
        List<string> pptIds = new List<string>();
        pptIds.add(ppt1.Id);
        Test.startTest();
        PPTBillingTriggerBatchApex msaBatch = new PPTBillingTriggerBatchApex ();		
		Database.executebatch(msaBatch);
        Test.stopTest();
        Plant_Product_Transaction__c pptProcessed = [select Is_Project_Added__c from Plant_Product_Transaction__c where id =:ppt1.Id];
        system.debug('::pptProcessed'+pptProcessed);
        
    }
    
}