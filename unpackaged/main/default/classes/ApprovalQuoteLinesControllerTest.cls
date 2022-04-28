@isTest
public class ApprovalQuoteLinesControllerTest {

     @testSetup 
    static void generatedata() {
        Account Acnt = new Account(name='Test11 Account1');
        insert Acnt;
        
        Contact cont = new Contact();
        cont.FirstName='Test';
        cont.LastName='Test';
        cont.Accountid= Acnt.id;
        insert cont;
        
        Opportunity opp = new Opportunity();
        opp.name = 'Test';
        opp.AccountId = Acnt.Id;
        opp.StageName = '00 - MQL';
        opp.CloseDate = date.today();    
        insert opp;
        
        Product2 product = new Product2(Name = 'Service Internet sur Fibre', 
                                    Product_Line__c = 'Core', 
                                    Product_Category__c = 'Software',
                                    Product_Type__c = 'Recurring',
                                    Product_Services__c = 'Implementation',
                                    Asset_Class__c = 'Hydro'
                                    );
        insert product;
        
        SBQQ__Cost__c cost = new SBQQ__Cost__c();
        cost.SBQQ__Product__c = product.Id;
        cost.SBQQ__UnitCost__c = 100;
        insert cost;
        
        PriceBookEntry pre = new PriceBookEntry(
        IsActive = true,
        PriceBook2Id = Test.getStandardPricebookId(), 
        Product2Id = product.Id , 
        UnitPrice=123);
        insert pre;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = Acnt.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__PrimaryContact__c = cont.Id;
        quote.SBQQ__Primary__c = TRUE;
        //quote.Final_Signature_Date__c = Date.today();
        insert quote;
        
        List<SBQQ__QuoteLine__c> quoteLineItems = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLineItem = new SBQQ__QuoteLine__c();
        quoteLineItem.SBQQ__Quote__c = quote.Id;
        quoteLineItem.SBQQ__Quantity__c = 1;
        quoteLineItem.SBQQ__RegularPrice__c = 100;
        quoteLineItem.SBQQ__CustomerPrice__c = 50;
        quoteLineItem.SBQQ__Cost__c = cost.Id;
        quoteLineItem.SBQQ__Product__c = product.Id;
        quoteLineItems.add(quoteLineItem);
        
        insert quoteLineItems;
        system.debug('-quoteLineItems--'+quoteLineItems);
         
      }
   
    @isTest static void testQuoteLines() {
      ApprovalQuoteLinesController classInstance = new ApprovalQuoteLinesController();
        ApprovalQuoteLinesController.quoteId = [select id from SBQQ__Quote__c limit 1].id;
        system.debug('-quote.Id--'+ApprovalQuoteLinesController.quoteId);
        system.debug('-ddddd--'+ApprovalQuoteLinesController.quotelines);
        system.assert(ApprovalQuoteLinesController.quotelines.size()>0);
      }
}