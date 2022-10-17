@isTest
public class ContractTriggerHandlerTest {
	@testSetup
    public static void createData(){
        
        Account act = new Account();
		act.Name = 'test';
         act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
		insert act;        
        
        Opportunity opp = new Opportunity();
        opp.CloseDate = System.today().addDays(5);
        opp.Name = 'Test Opportunity';
        opp.StageName = '00 - MQL';
        opp.AccountId = act.Id;
        insert opp;   
        
        Opportunity opp2 = new Opportunity();
        opp2.CloseDate = System.today().addDays(5);
        opp2.Name = 'Test Opportunity';
        opp2.StageName = '00 - MQL';
        opp2.AccountId = act.Id;
        insert opp2;  
        
        
        system.debug('1-->'+opp.id);
        system.debug('2-->'+opp.id);
        
        Product2 prd = new Product2();
        prd.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        prd.Name = 'test';
        prd.Product_Line__c='Core';
        prd.Product_Category__c = 'Software';
        prd.Product_Type__c = 'Recurring';
        prd.Product_Services__c = 'Implementation';
        prd.Asset_Class__c = 'Hydro';
        insert prd;
        
        SBQQ__Quote__c qut = new SBQQ__Quote__c();
        qut.SBQQ__Opportunity2__c = opp.Id;
        insert qut;
        
        MSA_Contract__c msa = new MSA_Contract__c();
        msa.Account_Name__c = act.Id;
        msa.Subsidiary__c = 'Greenbyte AB';
        msa.MSA_Start_Date__c = system.Today();
        msa.MSA_Term_years__c = 2;
        insert msa;
        
        act.Account_Status__c = 'Approved';
        act.Legal_Entity__c = 'Yes';
        act.Theater__c = 'APAC';
        act.Compliance_Designations__c = 'NERC/CIP';
        act.BillingStreet  = 'hb';
        act.BillingCity = 'hb';
        act.BillingPostalCode = '209096';
        act.BillingState  = 'Arizona';
        act.ShippingStreet  = 'test';
        act.ShippingCity  = 'test';
        act.ShippingCountry = 'United States';
        act.ShippingState  = 'Arizona';
        act.Uses_MSA_of__c   = msa.Id;
        
        update act;
        
        
       	Contract cnt = new Contract();
        cnt.AccountId = act.Id;
        //cnt.Status = 'Draft';
        cnt.StartDate = System.today().adddays(-5);
        cnt.ContractTerm = 12;
        cnt.SBQQ__Quote__c = qut.id;
        insert cnt;
        
        SBQQ__Quote__c qut2 = new SBQQ__Quote__c();
        qut2.SBQQ__Opportunity2__c = opp2.Id;
        qut2.SBQQ__Type__c = 'Amendment' ;
        qut2.SBQQ__MasterContract__c = cnt.Id;
        insert qut2;
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.Description='Test Product';
        p.productCode = 'ABC';
        p.isActive = true;
        p.Product_Line__c='Core';
        p.Product_Category__c = 'Software';
        p.Product_Type__c = 'Recurring';
        p.Product_Services__c = 'Implementation';
        p.Asset_Class__c = 'Hydro';
        insert p;
        
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = Test.getStandardPricebookId();
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 100;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
		Test.startTest();
        
        
        Order order = new Order(
            AccountId = act.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            PriceBook2Id = Test.getStandardPricebookId()
        );
        insert order;
        
        OrderItem lineItem = new OrderItem();
        lineItem.OrderId = order.id;
        lineItem.Quantity = 24;
        lineItem.UnitPrice = 240;
        lineItem.Product2id = p.id;
        lineItem.PricebookEntryId=standardPrice.id;
        insert lineItem;
        
       	order.Status = 'Activated';
        update order;
        
        list<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        for(Integer i = 0 ;  i < 1 ; i++){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Quote__c = qut.Id;
            ql.SBQQ__Product__c = prd.Id;
            ql.SBQQ__Quantity__c=10;
            
            qlList.add(ql);
            
        }
        for(SBQQ__QuoteLine__c ql : qlList){
            system.debug('-->'+ql);
        }
        insert qlList;
        
		list<SBQQ__QuoteLine__c> qlList2 = new List<SBQQ__QuoteLine__c>();
        for(Integer i = 0 ;  i < 1 ; i++){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Quote__c = qut2.Id;
            ql.SBQQ__Product__c = prd.Id;
            ql.SBQQ__Quantity__c=10;
             if(qut2!=null){
            
            qlList2.add(ql);
             } 
        }
        insert qlList2;
        
        SBQQ__Subscription__c subs = new SBQQ__Subscription__c();
        subs.SBQQ__Quantity__c = 100;
        subs.SBQQ__Product__c = prd.Id;
        subs.SBQQ__Contract__c = cnt.Id;
        subs.SBQQ__Account__c = act.Id;
        insert subs;
        
        Plant__c plt = new Plant__c();
        //plt.Name = 'test';
        
        insert plt;
        
        Account_Plant__c ap =new Account_Plant__c();
        ap.Status__c = 'Active';
        //ap.Name = 'test';
        ap.Plant__c = plt.Id;
        ap.Account__c = act.Id;
        insert ap;
        
        
        
        List<Plant_Product_Transaction__c> pptList = new List<Plant_Product_Transaction__c>();
        for(SBQQ__QuoteLine__c ql : qlList){
            for(Integer i = 0 ;  i < 1 ; i++){
            	Plant_Product_Transaction__c ppt = new Plant_Product_Transaction__c();
                ppt.Quote_Line__c = ql.Id;
                ppt.Name = 'test-'+i;
                ppt.Status__c = 'Contracted';
                ppt.Contract__c = cnt.Id;
                ppt.Subscription__c = subs.Id;
                ppt.Plant__c = ap.Id;
                ppt.Account__c = act.Id;
                pptList.add(ppt);
            }
        }
        
        insert pptList;
        
        opp.SBQQ__AmendedContract__c = cnt.id;
        update opp;
        
		cnt.SBQQ__RenewalQuoted__c = true;
        cnt.Amendment_Quoted__c = true;
        cnt.Status = 'Activated';
        //update cnt;
        Test.stopTest();
    }
    
    @isTest
    public static void method01(){
        Test.startTest();
        Contract cnt = [SELECT Id FROM Contract LIMIT 1];
        cnt.SBQQ__RenewalQuoted__c = true;
        cnt.Amendment_Quoted__c = true;
       cnt.Status = 'Activated';
        update cnt;
        
        List<Plant_Product_Transaction__c> pptList = [SELECT Id FROM Plant_Product_Transaction__c];
        for(Plant_Product_Transaction__c ppt : pptList){
            ppt.Quote_Line_Quantity__c = 5;
        }
        update pptList;
        list<SBQQ__QuoteLine__c> qlList = [SELECT Id FROM SBQQ__QuoteLine__c];
        RenewableQuoteProcessHelper.updateQuantityOnQuoteLineItem2(qlList);
        Test.stopTest();
    }
    
    @isTest
    public static void method02(){
        Test.startTest();
        Contract cnt = [SELECT Id FROM Contract LIMIT 1];
        List<SBQQ__Quote__c> quoteList = [Select id from SBQQ__Quote__c];
        for (SBQQ__Quote__c qut : quoteList) qut.SBQQ__Type__c = 'Amendment';
        update quoteList;
        /*
        List<Plant_Product_Transaction__c> pptList = [SELECT Id FROM Plant_Product_Transaction__c];
        for(Plant_Product_Transaction__c ppt : pptList){
            ppt.Quote_Line_Quantity__c = 5;
        }
        update pptList;
        list<SBQQ__QuoteLine__c> qlList = [SELECT Id FROM SBQQ__QuoteLine__c];
        RenewableQuoteProcessHelper.updateQuantityOnQuoteLineItem2(qlList);*/
        
        List<Opportunity> oppList = [Select id,Name,recordtype.name From Opportunity limit 2];
        for(Opportunity opp : oppList){
            opp.SBQQ__AmendedContract__c = cnt.id;
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Amendment').getRecordTypeId();
            system.debug('-->>'+opp.RecordType.name);
        } 
        system.debug('opplist==>>>'+oppList);
        update oppList;
        
        cnt.SBQQ__RenewalQuoted__c = true;
        cnt.Amendment_Quoted__c = true;
        cnt.Status = 'Activated';
        update cnt;
        List<Opportunity> oppList2 = [Select id,Name,recordtype.name From Opportunity limit 2];
        for(Opportunity opp : oppList2){
            opp.SBQQ__AmendedContract__c = cnt.id;
            system.debug('-->>'+opp.RecordType.name);
        }
        Test.stopTest();
    }
}