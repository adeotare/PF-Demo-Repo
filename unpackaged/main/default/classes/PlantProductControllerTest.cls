@isTest
private class PlantProductControllerTest {

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
        
        Product2 product = new Product2(Name = 'Drive O&M', 
                                    Product_Line__c = 'Core', 
                                    Product_Category__c = 'Software',
                                    Product_Type__c = 'SaaS',
                                    Product_Services__c = 'N/A',
                                    QuantityUnitOfMeasure = 'MWp',
                                    Asset_Class__c = 'Solar'
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
        quoteLineItem.SBQQ__ListPrice__c = 150;
        quoteLineItem.SBQQ__RegularPrice__c = 220.76;
        quoteLineItem.SBQQ__Product__c = product.Id;
        quoteLineItems.add(quoteLineItem);
        
        insert quoteLineItems;
        system.debug('-quoteLineItems--'+quoteLineItems);

        Plant__c plant = new Plant__c();
        plant.Name = 'Oxnard UHSD - Oxnard - Rio Mesa HS';
        plant.Asset_Class__c = 'Solar';
        plant.DC_Capacity_Quoted__c = 75;
        insert plant;

        Account_Plant__c accountPlant = new Account_Plant__c ();
        accountPlant.Account__c = Acnt.id;
        accountPlant.Plant__C = plant.id;
        insert accountPlant;

    }


    @isTest static void fetchPlantProductListTest() {
            
            // PlantProductController ppc = new PlantProductController(); 
            // List<Plant_Product_Transaction__c> = ppc.fetchPlantProductList (String.valueOf(quoteLineItem.Id));

    }

    @isTest static void deletePlantProductTest() {
            // PlantProductController ppc = new PlantProductController(); 
            // List<Plant_Product_Transaction__c> pptList = ppc.fetchPlantProductList (String.valueOf(quoteLineItem.Id));
            // ppc.deletePlantProduct (pptList, String.valueOf(quoteLineItem.Id));

    }

    @isTest static void addPlantProductListTest () {


    }

    @isTest static void updateQuantityOnQuoteLineItemTest () {


    }

    @isTest static void fetchAccountPlantTest () {


    }


}