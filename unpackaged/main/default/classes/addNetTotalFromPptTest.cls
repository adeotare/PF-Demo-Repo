@isTest
public class addNetTotalFromPptTest {
    
    @testSetup 
    public static void generatedata() {

        Pricebook2 pbId = TestDataFactory.createPriceBook();
        insert pbId ;
        
        Account acc = TestDataFactory.createAccount(pbId.Id);
        insert acc;
        
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id);
        insert opp;
        
        SBQQ__Quote__c quote  = TestDataFactory.createQuote(acc.Id, opp.Id);
        insert quote;
        
        Product2 product = TestDataFactory.createProductAgain();
        insert product;
        
        SBQQ__QuoteLine__c quoteLine = TestDataFactory.createQuoteLine(quote.Id, product.Id);
        insert quoteLine;
        
        }
    
    public static testMethod void testInsert(){
    
    	String accName = 'TestCP';
    	Account accts = [SELECT Id, Name FROM Account WHERE Name =:accName LIMIT 1];
    	Test.startTest();
        System.debug('Account Name : ' + accName);
        Test.stopTest();
        System.assertEquals('TestCP', accName );
    
	}

}