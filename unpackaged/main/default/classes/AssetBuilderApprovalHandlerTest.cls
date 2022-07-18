/**
**/
@isTest
public class AssetBuilderApprovalHandlerTest {
    @testSetup static void methodName() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        
        Plant__c plant = new Plant__c();
        plant.Name = 'Asset Builder Plant' ;    
        plant.Renewable_Type__c=Constants.WIND;
        plant.Timezone__c= 'India Standard Time';
        plant.Latitude__c='45.5017';
        plant.Longitude__c='-75.123';
        insert plant;
        
        Account_Plant__c plantAsset = new Account_Plant__c();
        plantAsset.Customer_Plant_Name__c = 'Customer Plant Asset';
		plantAsset.PF_Service_Product__c = Constants.DRIVE_PRO;
        plantAsset.Drive_Id__c  = '21.21.21.1';
        plantAsset.TEM_Version__c = newTemVersion.id;
        plantAsset.Project_Lifecycle_Status__c = 'Pending';
        insert plantAsset;

        Account_Plant__c newPlantAsset1 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','21.21.21',newTemVersion.Id);
		newPlantAsset1.Project_Lifecycle_Status__c = 'Pending';
        insert newPlantAsset1;
        
    }
    
    @isTest static void setSubmitForApprovalTest(){
        Account_Plant__c plantAsset1 = [SELECT Id, Name,AB_Approval_Status__c,Asset_Builder_Status__c FROM Account_Plant__c WHERE Drive_Id__c ='21.21.21'];
        plantAsset1.AB_Approval_Status__c = '';
        plantAsset1.Asset_Builder_Status__c = 'Completed';
        update plantAsset1;
        AssetBuilderApprovalHandler.setSubmitForApproval(plantAsset1.Id);
        Account_Plant__c plantAsset2 = [SELECT Id, Name,AB_Approval_Status__c,Asset_Builder_Status__c FROM Account_Plant__c WHERE Drive_Id__c ='21.21.21.1'];
        
        Account newAcc = new Account();
        newAcc.Name = 'Test ACC';
        insert newAcc;
        
        Contact c = new Contact();
        c.firstName = 'Contact';
        c.LastName = 'Test Name';
        c.AccountId = newAcc.Id;
        c.Email='Kranthi.d@congruentindai.com';
        insert c;
          
//        newAcc.Primary_Contact__c = c.Id;
        update newAcc;
    UserRole r = new UserRole(DeveloperName = 'CustomerAccountCustomerUser', Name = 'My Role');
	insert r;
        User u = new User(
          ProfileId = [SELECT Id FROM Profile WHERE Name = 'PF Community User'].Id,
          LastName = 'last',
          Email = 'puser000@cittest.com',
          Username = 'puser000@cittest.com' + System.currentTimeMillis(),
          CompanyName = 'TEST',
          Title = 'title',
          Alias = 'alias',
          TimeZoneSidKey = 'America/Los_Angeles',
          EmailEncodingKey = 'UTF-8',
          LanguageLocaleKey = 'en_US',
          LocaleSidKey = 'en_US',
          ContactId = c.Id,
            UserRoleId = r.Id
        );
        insert u;
        System.runAs(u) {
        	AssetBuilderApprovalHandler.setSubmitForApproval(plantAsset2.Id);
        }
    }
    
    
    @isTest static void processStepTest(){
        Account_Plant__c plantAsset2 = [SELECT Id, Name,AB_Approval_Status__c,Asset_Builder_Status__c FROM Account_Plant__c WHERE Drive_Id__c ='21.21.21.1'];
        plantAsset2.AB_Approval_Status__c = '';
        plantAsset2.Asset_Builder_Status__c = 'Completed';
        update plantAsset2;
        Asset_Builder_Approval__c abaRecord = 
            [SELECT Id, Approval_Status__c FROM Asset_Builder_Approval__c WHERE Account_Plant__c =: plantAsset2.Id];
        
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(abaRecord.id);

        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        AssetBuilderApprovalHandler.getApprovalHistory(abaRecord.Id);
        AssetBuilderApprovalHandlerUtils.SubmitForApproval(abaRecord.Id,'Comments','Asset_Builder_Approval_Process',false); 
        AssetBuilderApprovalHandler.processStep(abaRecord.Id, 'comments', 'Reject');
        AssetBuilderApprovalHandlerUtils.SubmitForApproval(abaRecord.Id,'Comments','Asset_Builder_Approval_Process',false); 
        AssetBuilderApprovalHandler.processStep(abaRecord.Id, 'comments', 'Removed');
        AssetBuilderApprovalHandlerUtils.SubmitForApproval(abaRecord.Id,'Comments','Asset_Builder_Approval_Process',false); 
        AssetBuilderApprovalHandler.processStep(abaRecord.Id, 'comments', 'Approve');
        //AssetBuilderApprovalHandlerUtils.SubmitForApproval(plantAsset2.Id,'Comments','Asset_Builder_Approval_Process',false); 
   }
}