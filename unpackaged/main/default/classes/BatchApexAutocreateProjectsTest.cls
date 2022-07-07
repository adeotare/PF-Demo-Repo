/**
 * The Test class for batch apex BatchApexAutocreateProjects.   
 * @param  :  
 * @return :  
 */
@isTest
public with sharing class BatchApexAutocreateProjectsTest {
    static testmethod void testCommissionedProject() {
        //Create product with product having project template
        Product2 pr = TestDataFactory.createProductWithCode('DR-PR-PS-OT-IM-ST-ST-N/A');
        insert pr;
        Pricebook2 pb = TestDataFactory.createPriceBook();
        insert pb;
        Account accnt = TestDataFactory.createAccount(pb.Id);
        insert accnt;
        project_cloud__Project__c commTemplate = TestDataFactory.createCCProjectTemplate('Monitoring Implementation',accnt.Id);
        insert commTemplate;
        project_cloud__Project__c deCommTemplate = TestDataFactory.createCCProjectTemplate('Monitoring Decommissioning',accnt.Id);
        insert deCommTemplate;
        Project_Template__c proTemplate =  TestDataFactory.createProjectTemplate(pr.Id, commTemplate.Id, deCommTemplate.Id);
        insert proTemplate;
        system.debug('::proTemplate::'+proTemplate);
        Plant_Product_Transaction__c ppt1 = TestDataFactory.createPPT('Ordered', accnt.Id, pr.Id);
        insert ppt1;
        Plant_Product_Transaction__c ppt2 = TestDataFactory.createPPT('Contracted', accnt.Id, pr.Id);
        insert ppt2;
        Test.startTest();
            BatchApexAutocreateProjects c = new BatchApexAutocreateProjects();
            Database.executeBatch(c);
        Test.stopTest();
        Plant_Product_Transaction__c pptProcessed = [select Project_Creation_Status__c from Plant_Product_Transaction__c where id =:ppt1.id];
        System.assertEquals('Completed',pptProcessed.Project_Creation_Status__c);
        system.debug('---ppt1---'+ppt1);
    }
    static testmethod void testDecommissionedProject() {
        //Create product with product having project template
        Product2 pr = TestDataFactory.createProductWithCode('DR-PR-PS-OT-IM-ST-ST-N/A');
        pr.Product_Category__c = 'Software';
        pr.Services_Short_Name__c = 'Test Short Name of Product';
        insert pr;
        Pricebook2 pb = TestDataFactory.createPriceBook();
        insert pb;
        Account accnt = TestDataFactory.createAccount(pb.Id);
        insert accnt;
        project_cloud__Project__c commTemplate = TestDataFactory.createCCProjectTemplate('Monitoring Implementation',accnt.Id);
        insert commTemplate;
        project_cloud__Project__c deCommTemplate = TestDataFactory.createCCProjectTemplate('Monitoring Decommissioning',accnt.Id);
        insert deCommTemplate;
        Project_Template__c proTemplate =  TestDataFactory.createProjectTemplate(pr.Id, commTemplate.Id, deCommTemplate.Id);
        insert proTemplate;
        system.debug('::proTemplate2::'+proTemplate);
        Plant_Product_Transaction__c ppt3 = TestDataFactory.createPPT('Decommissioned', accnt.Id, pr.Id);
        insert ppt3;
        
        Test.startTest();
            BatchApexAutocreateProjects c = new BatchApexAutocreateProjects();
            Database.executeBatch(c);
        Test.stopTest();
        Plant_Product_Transaction__c pptProcessed = [select Project_Creation_Status__c from Plant_Product_Transaction__c where id =:ppt3.id];
        System.assertEquals('Completed',pptProcessed.Project_Creation_Status__c);
    }
}