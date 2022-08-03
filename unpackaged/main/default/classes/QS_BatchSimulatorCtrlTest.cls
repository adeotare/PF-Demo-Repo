@isTest
public class QS_BatchSimulatorCtrlTest {
	
    @TestSetup
    public static void testData(){
        Account account = new Account();
        account.Name = 'Test acctName';
        account.BillingCountry = 'United States';
        insert account;
        
        QS_Customer_Asset__c qcAsset = new QS_Customer_Asset__c ();
        qcAsset.Name = 'Test';
        qcAsset.QS_Account__c = account.id;
        insert qcAsset;
        
        QS_Customer_Asset_Detail__c acAssetDetail = new QS_Customer_Asset_Detail__c();
        acAssetDetail.QS_Customer_Asset__c = qcAsset.Id;
        //acAssetDetail.QS_New_Asset_Status__c = 'Expired';
        insert acAssetDetail;
        
    }
    @isTest
    public static void method01(){
        Test.startTest();
        
		QS_Customer_Asset__c qcAsset = [SELECT Id FROM QS_Customer_Asset__c LIMIT 1];
        
        QS_BatchSimulatorCtrl.initializeData(qcAsset.id);
        
        QS_BatchSimulatorCtrl.runBatchProcessByDate(qcAsset.id , system.today());
        
        QS_Customer_Asset_Detail__c qac = [SELECT Id FROM QS_Customer_Asset_Detail__c LIMIT 1];
        
        qac.QS_End_Date__c = system.today().addDays(-10);
        update qac;
        QS_BatchSimulatorCtrl.runBatchProcessByDate(qcAsset.id , system.today());
        
        qac.QS_End_Date__c = system.today().addDays(10);
        qac.QS_Start_Date__c = system.today().addDays(10);
        update qac;
        QS_BatchSimulatorCtrl.runBatchProcessByDate(qcAsset.id , system.today());
        
		qac.QS_End_Date__c = system.today().addDays(10);
        qac.QS_Start_Date__c = system.today().addDays(-10);
        update qac;
        QS_BatchSimulatorCtrl.runBatchProcessByDate(qcAsset.id , system.today());        
        
        Test.stopTest();
    }
}