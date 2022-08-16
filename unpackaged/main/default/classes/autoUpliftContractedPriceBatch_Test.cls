@isTest
public class autoUpliftContractedPriceBatch_Test {
	
    public static testMethod void generatedata() {
        
        Product2 product = TestDataFactory.createProductAgain();
        insert product;
        product.IsActive = true;
        update product;
        
		Pricebook2 pbId = TestDataFactory.createPriceBook();
        insert pbId ; 
        
        Account acc = TestDataFactory.createAccount(pbId.Id);
        insert acc;        
        
        MSA_Contract__c msa = TestDataFactory.createMsa(acc.Id);                             
        insert msa;
        msa.ApprovalStatus__c='Approved';
        msa.MSA_Status__c = 'Approved';  
        msa.Annual_Uplift_Percentage__c = 2;
        msa.MSA_Start_Date__c = date.today().addDays(-365);
        update msa;
        
        acc.isContractPriceCreated__c = false;
        acc.Uses_MSA_of__c = msa.id;
        update acc;         	
        
		PricebookEntry standardPBE = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product.Id, UnitPrice = 1000, IsActive = true);
    	insert standardPBE;
        
		PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pbId.Id, Product2Id = product.Id, UnitPrice = 1000, IsActive = true);
    	insert pbe;
           
        SBQQ__ContractedPrice__c contPrice = TestDataFactory.createContractedPrice(acc.Id, product.Id);
        insert contPrice;
        
        User user = TestDataFactory.createNewUser();
        insert user;
        
        Test.startTest();        
       	autoUpliftContractedPriceBatchProcess msaBatch = new autoUpliftContractedPriceBatchProcess ();		
		Database.executebatch(msaBatch);
        Test.stopTest();
        
        }
    
}