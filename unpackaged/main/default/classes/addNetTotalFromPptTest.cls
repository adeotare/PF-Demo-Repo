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
        
        MSA_Contract__c msa = TestDataFactory.createMsa(acc.Id);                             
        insert msa;
        
        Product2 product = TestDataFactory.createProductAgain();
        insert product;

        MSA_Software_Discount_Tier_Price__c softPrice = TestDataFactory.createSoftwareDiscountTier(acc.Id, product.Id, msa.Id);
        insert softPrice;
        
        User user = TestDataFactory.createNewUser();
        insert user;
        
        }
    
    public static testMethod void testInsert(){
 
    
    
	}

}