@isTest
private class TestAccountHierarchy {
    @isTest static void testAccountHierarchyScenario1() {
		Test.StartTest(); 
		
		Id prospectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
		Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
		
		Account testParentAccount = new Account();
		testParentAccount.Name='Test Parent Account';
		testParentAccount.RecordTypeId = prospectRecordTypeId;
		insert testParentAccount;
		
		Account testChildAccount = new Account();
		testChildAccount.Name='Test Child Account';
		testChildAccount.RecordTypeId = prospectRecordTypeId;
		testChildAccount.ParentId = testParentAccount.id;
		insert testChildAccount;
		
		
		testChildAccount.RecordTypeId = customerRecordTypeId;
		update testChildAccount;
		//System.assertEquals(testChildAccount.Account_in_Hierarchy_is_Customer__c,false);
		Test.StopTest();
		
    }
}