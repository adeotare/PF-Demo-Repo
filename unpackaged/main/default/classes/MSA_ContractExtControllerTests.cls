@isTest  
private class MSA_ContractExtControllerTests {  
      
    testMethod static void testSubmit() {  
        MSA_Contract__c MSA_Contract = new MSA_Contract__c();  
        insert MSA_Contract;  
          
        Test.startTest();  
        MSA_ContractExtController con = new MSA_ContractExtController(new ApexPages.StandardController(MSA_Contract));  
        con.onSubmit();  
        MSA_Contract = [SELECT ApprovalStatus__c FROM MSA_Contract__c WHERE Id = :MSA_Contract.Id LIMIT 1];  
        Test.stopTest();  
          
        System.assertEquals('Approved', MSA_Contract.ApprovalStatus__c);  
    }  
      
    testMethod static void testRecall() {  
        MSA_Contract__c MSA_Contract = new MSA_Contract__c();  
        insert MSA_Contract;  
          
        Test.startTest();  
        MSA_ContractExtController con = new MSA_ContractExtController(new ApexPages.StandardController(MSA_Contract));  
        con.onRecall();  
        MSA_Contract = [SELECT ApprovalStatus__c FROM MSA_Contract__c WHERE Id = :MSA_Contract.Id LIMIT 1];  
        Test.stopTest();  
          
        System.assertEquals('Recalled', MSA_Contract.ApprovalStatus__c);  
    }  
}