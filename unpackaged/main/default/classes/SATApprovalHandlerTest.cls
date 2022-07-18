/**
**/
@isTest
public class SATApprovalHandlerTest {
    @testSetup static void methodName() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        Account_Plant__c pa = new Account_Plant__c();
//        pa.Name = 'Plant Asset Test1';
//        pa.RecordTypeId = [SELECT id from RecordType where Name ='Parent Asset'].Id;
//        pa.Plant_Name__c = 'test1';
        pa.Project_Lifecycle_Status__c = 'Pending';
//        pa.Implementation_Status__c = 'Pending Customer Submission';
//        pa.Renewable_Type__c = Constants.WIND;
        insert pa;
        Account_Plant__c newPlantAsset1 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','21.21.21',newTemVersion.Id);
//        newPlantAsset1.Parent__c = pa.Id;
        insert newPlantAsset1;
        newPlantAsset1.Project_Lifecycle_Status__c = 'Data Validation';
 //       newPlantAsset1.Implementation_Status__c = 'In Progress';
        newPlantAsset1.AB_Approval_Status__c = 'Approved';
        update newPlantAsset1;
        Account_Plant__c newPlantAsset2 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','21.21.21.1',newTemVersion.Id);
//        newPlantAsset2.Parent__c = pa.Id;
        insert newPlantAsset2;
        
        //Create first SAT
        list<Sat__c> newsatlst = new list <Sat__c>();
        Sat__c firstSAT1 = new Sat__c();
        firstSAT1.Name = 'firstSAT';
        firstSAT1.Account_Plant__c = newPlantAsset1.Id;
        insert firstSAT1;
    }
    
    @isTest static void setSubmitForApprovalTest(){
        User u = new User(
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
        LastName = 'last',
        Email = 'puser000@cittest.com',
        Username = 'puser000@cittest.com' + System.currentTimeMillis(),
        CompanyName = 'TEST',
        Title = 'title',
        Alias = 'alias',
        TimeZoneSidKey = 'America/Los_Angeles',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US');
        insert u;
        
        SAT__C sat = [SELECT Id, Customer_Acceptance_Status__c, Account_Plant__r.Drive_Id__c, SAT_Approval_Status__c,
                      SAT_Status__c, Customer_User__c FROM Sat__c WHERE 
                      Account_Plant__r.Drive_Id__c ='21.21.21' LIMIT 1];
        sat.Customer_User__c = u.Id;
        sat.SAT_Approval_Status__c  = '';
        update sat;
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		    app.setObjectId(sat.id);
        Approval.ProcessResult result = Approval.process(app);
        SATApprovalHandler.setSubmitForApproval(sat.Id);
        SATApprovalHandler.getApprovalHistory(sat.Id);
        SATApprovalHandler.reassignApproval(sat.Id, u.Id, 'Reassign');
        SATApprovalHandler.processStep(sat.Id, 'Approve', 'Approve');
    }
}