@isTest
private class CA2_AssetHandlerTest {
    
    @TestSetup
    public static void createData(){
        Test.startTest();
         CA2_CustomerAssetUtil.ActivateTwinFielding = false;
        CA2_TriggerHandler.bypass('CA2_CustomerAssetDetailTriggerHandler');
		Account account = new Account();
        account.Name = 'Test acctName';
        account.BillingCountry = 'United States';
        insert account;
        
        Opportunity opp = new Opportunity();
        opp.CloseDate = System.today().addDays(5);
        opp.Name = 'Test Opportunity';
        opp.StageName = '00 - MQL';
        opp.AccountId = account.Id;
        insert opp;  
        
      
        SBQQ__Quote__c qut = new SBQQ__Quote__c();
        qut.SBQQ__Opportunity2__c = opp.Id;
        insert qut;
        
       	Contract cnt = new Contract();
        cnt.AccountId = account.Id;
        cnt.Status = 'Draft';
        cnt.StartDate = System.today().adddays(-5);
        cnt.ContractTerm = 12;
        cnt.SBQQ__Quote__c = qut.id;
        //insert cnt;
        
        SBQQ__Quote__c qut2 = new SBQQ__Quote__c();
        qut2.SBQQ__Opportunity2__c = opp.Id;
        qut2.SBQQ__Type__c = 'Amendment' ;
        //qut2.SBQQ__MasterContract__c = cnt.Id;
        //insert qut2;
        
        
        
        // Create a product record
        List<Product2> productList = new List<Product2>();
        Product2 product = new Product2();
        product.ProductCode = 'product-1';
        product.Name = 'Hardware Product 1';
        product.Description = 'Hardware Product 1 Description';
        product.Family = 'HardwareFamily';
        product.QS_Generate_Asset__c = false;
        product.IsActive = true;
        product.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product.SBQQ__SubscriptionType__c = 'Renewable';
        product.SBQQ__SubscriptionTerm__c = 12;
        product.SBQQ__QuantityEditable__c = true;
        product.SBQQ__IncludeInMaintenance__c = true;
        product.Product_Line__c='Core';
        product.Product_Category__c = 'Software';
        product.Product_Type__c = 'Recurring';
        product.Product_Services__c = 'Implementation';
        product.Asset_Class__c = 'Hydro';
        product.QS_Generate_Asset__c = true;
        productList.add(product);
        
        Product2 product1 = new Product2();
        product1.ProductCode = 'product-2';
        product1.Name = 'Hardware Product 2';
        product1.Description = 'Hardware Product 2 Description';
        product1.Family = 'HardwareFamily';
        product1.QS_Generate_Asset__c = false;
        product1.IsActive = true;
        product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product1.SBQQ__SubscriptionType__c = 'Renewable';
        product1.SBQQ__SubscriptionTerm__c = 12;
        product1.SBQQ__QuantityEditable__c = true;
        product1.SBQQ__IncludeInMaintenance__c = true;
        product1.Product_Line__c='Core';
        product1.Product_Category__c = 'Software';
        product1.Product_Type__c = 'Recurring';
        product1.Product_Services__c = 'Implementation';
        product1.Asset_Class__c = 'Hydro';
        productList.add(product1);
        insert  productList;     
                
         list<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        for(Integer i = 0 ;  i < 1 ; i++){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Quote__c = qut.Id;
            ql.SBQQ__Product__c = productList[0].Id;
            ql.SBQQ__Quantity__c=10;
            ql.QS_Line_Classification__c = 'Test';
            qlList.add(ql);
            
        }
        for(SBQQ__QuoteLine__c ql : qlList){
            system.debug('-->'+ql);
        }
        insert qlList;
        
        Asset newAsset = new Asset();
        newAsset.AccountId = account.Id;
        newAsset.Name = productList[0].Name;
        newAsset.Product2Id = productList[0].id;
        newAsset.Price = 0;
        newAsset.Quantity = -10;
        
        insert newAsset;
        
        
        
        // Create a subscription record
        List<SBQQ__Subscription__c> lstSubscriptionToInsert = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = productList[0].Id;
        sub.SBQQ__Quantity__c = 0;
        sub.SBQQ__NetPrice__c = 0.00;
        sub.SBQQ__Account__c = account.id;
        sub.QS_Annual_Recurring_Revenue__c = 1.00;
        sub.SBQQ__SubscriptionStartDate__c = System.today();
        sub.SBQQ__QuoteLine__c = qlList[0].id;
        lstSubscriptionToInsert.add(sub);
        
        
        
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c();
        sub1.SBQQ__Quantity__c = 0;
        sub1.SBQQ__NetPrice__c = 1.00;
        sub1.SBQQ__Account__c = account.id;
        sub1.QS_Annual_Recurring_Revenue__c = 1.00;
        sub1.SBQQ__SubscriptionStartDate__c = System.today();
        sub1.SBQQ__QuoteLine__c = qlList[0].id;
        lstSubscriptionToInsert.add(sub1);
        //insert sub1;
        insert lstSubscriptionToInsert;
        
        SBQQ__SubscribedAsset__c sbSubAsset = new SBQQ__SubscribedAsset__c();
        sbSubAsset.SBQQ__Active__c = true;
        sbSubAsset.SBQQ__Asset__c = newAsset.Id;
        sbSubAsset.SBQQ__Subscription__c = lstSubscriptionToInsert[0].Id;
        
        insert sbSubAsset;
        
        
        QS_Customer_Asset__c ca = new QS_Customer_Asset__c(QS_Account__c = account.Id);
        ca.QS_Product__c = productList[0].Id;
        insert ca; 
        
        Quote quote = new Quote(Name = 'devis1' ,
                        OpportunityId=opp.Id,
                        Pricebook2Id =  Test.getStandardPricebookId() );
		insert quote;   
        
        // Insert a Customer Asset Detail with an OLD Start Date and FUTURE End Date
        QS_Customer_Asset_Detail__c cad = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Annual_Recurring_Revenue__c = 2,QS_Quantity__c = 2,QS_Maintain_Line__c = true,QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-365));
        cad.QS_Subscription__c  =   lstSubscriptionToInsert[0].Id;      
        insert cad; 
        
        Test.stopTest();
    }
    
    
    @isTest static void CA2_AssetHandlerTestNegativeQuantity() {
            Test.startTest();
        CA2_TriggerHandler.bypass('CA2_CustomerAssetDetailTriggerHandler');
        CA2_CustomerAssetUtil.ActivateTwinFielding = false;
        Account account = [Select id from Account LIMIT 1];
        
        Opportunity opp = new Opportunity();
        opp.CloseDate = System.today().addDays(5);
        opp.Name = 'Test Opportunity';
        opp.StageName = '00 - MQL';
        opp.AccountId = account.Id;
        insert opp;  
        
      
        SBQQ__Quote__c qut = new SBQQ__Quote__c();
        qut.SBQQ__Opportunity2__c = opp.Id;
        insert qut;
        
       	Contract cnt = new Contract();
        cnt.AccountId = account.Id;
        cnt.Status = 'Draft';
        cnt.StartDate = System.today().adddays(-5);
        cnt.ContractTerm = 12;
        cnt.SBQQ__Quote__c = qut.id;
        //insert cnt;
        
        SBQQ__Quote__c qut2 = new SBQQ__Quote__c();
        qut2.SBQQ__Opportunity2__c = opp.Id;
        qut2.SBQQ__Type__c = 'Amendment' ;
        //qut2.SBQQ__MasterContract__c = cnt.Id;
        //insert qut2;
        
        
        
        // Create a product record
        List<Product2> productList = new List<Product2>();
        Product2 product = new Product2();
        product.ProductCode = 'product-1';
        product.Name = 'Hardware Product 1';
        product.Description = 'Hardware Product 1 Description';
        product.Family = 'HardwareFamily';
        product.QS_Generate_Asset__c = false;
        product.IsActive = true;
        product.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product.SBQQ__SubscriptionType__c = 'Renewable';
        product.SBQQ__SubscriptionTerm__c = 12;
        product.SBQQ__QuantityEditable__c = true;
        product.SBQQ__IncludeInMaintenance__c = true;
        product.Product_Line__c='Core';
        product.Product_Category__c = 'Software';
        product.Product_Type__c = 'Recurring';
        product.Product_Services__c = 'Implementation';
        product.Asset_Class__c = 'Hydro';
        product.QS_Generate_Asset__c = true;
        productList.add(product);
        
        Product2 product1 = new Product2();
        product1.ProductCode = 'product-2';
        product1.Name = 'Hardware Product 2';
        product1.Description = 'Hardware Product 2 Description';
        product1.Family = 'HardwareFamily';
        product1.QS_Generate_Asset__c = false;
        product1.IsActive = true;
        product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product1.SBQQ__SubscriptionType__c = 'Renewable';
        product1.SBQQ__SubscriptionTerm__c = 12;
        product1.SBQQ__QuantityEditable__c = true;
        product1.SBQQ__IncludeInMaintenance__c = true;
        product1.Product_Line__c='Core';
        product1.Product_Category__c = 'Software';
        product1.Product_Type__c = 'Recurring';
        product1.Product_Services__c = 'Implementation';
        product1.Asset_Class__c = 'Hydro';
        productList.add(product1);
        insert  productList;     
        
          //Test.startTest();
        
        list<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        for(Integer i = 0 ;  i < 1 ; i++){
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
            ql.SBQQ__Quote__c = qut.Id;
            ql.SBQQ__Product__c = productList[0].Id;
            ql.SBQQ__Quantity__c=10;
            ql.QS_Line_Classification__c = 'Test';
            qlList.add(ql);
            
        }
        for(SBQQ__QuoteLine__c ql : qlList){
            system.debug('-->'+ql);
        }
        insert qlList;
        
        Asset newAsset = new Asset();
        newAsset.AccountId = account.Id;
        newAsset.Name = productList[0].Name;
        newAsset.Product2Id = productList[0].id;
        newAsset.Price = 0;
        newAsset.Quantity = -10;
        
        insert newAsset;
        
        
        
        // Create a subscription record
        List<SBQQ__Subscription__c> lstSubscriptionToInsert = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = productList[0].Id;
        sub.SBQQ__Quantity__c = 0;
        sub.SBQQ__NetPrice__c = 0.00;
        sub.SBQQ__Account__c = account.id;
        sub.QS_Annual_Recurring_Revenue__c = 1.00;
        sub.SBQQ__SubscriptionStartDate__c = System.today();
        sub.SBQQ__QuoteLine__c = qlList[0].id;
        lstSubscriptionToInsert.add(sub);
        
        
        
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c();
        sub1.SBQQ__Quantity__c = 0;
        sub1.SBQQ__NetPrice__c = 1.00;
        sub1.SBQQ__Account__c = account.id;
        sub1.QS_Annual_Recurring_Revenue__c = 1.00;
        sub1.SBQQ__SubscriptionStartDate__c = System.today();
        sub1.SBQQ__QuoteLine__c = qlList[0].id;
        lstSubscriptionToInsert.add(sub1);
        //insert sub1;
        insert lstSubscriptionToInsert;
        
        SBQQ__SubscribedAsset__c sbSubAsset = new SBQQ__SubscribedAsset__c();
        sbSubAsset.SBQQ__Active__c = true;
        sbSubAsset.SBQQ__Asset__c = newAsset.Id;
        sbSubAsset.SBQQ__Subscription__c = lstSubscriptionToInsert[0].Id;
        
        insert sbSubAsset;
        
        QS_Customer_Asset__c ca = new QS_Customer_Asset__c(QS_Account__c = account.Id);
        ca.QS_Product__c = productList[0].Id;
        insert ca; 
        
        Quote quote = new Quote(Name = 'devis1' ,
                        OpportunityId=opp.Id,
                        Pricebook2Id =  Test.getStandardPricebookId() );
		insert quote;   
        
        // Insert a Customer Asset Detail with an OLD Start Date and FUTURE End Date
        QS_Customer_Asset_Detail__c cad = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Annual_Recurring_Revenue__c = 2,QS_Quantity__c = 2,QS_Maintain_Line__c = true,QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-365));
        cad.QS_Subscription__c  =   lstSubscriptionToInsert[0].Id;      
        insert cad; 
        Map<String,Decimal> mapIdToQuantity = new Map<String,Decimal>();
        mapIdToQuantity.put('Test',12);
        CA2_CustomerAssetUtil.queryCAByUniqueId(new Set<String>{'test'});
        CA2_CustomerAssetUtil.Subscription_CAUniqueId(lstSubscriptionToInsert);
        CA2_CustomerAssetUtil.getMatchingKeys(new List<Asset>{newAsset});
        CA2_CustomerAssetUtil.getMatchingKeys(new List<SBQQ__SubscribedAsset__c>{sbSubAsset});
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(cad,ca,productList[0],mapIdToQuantity);
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(lstSubscriptionToInsert[1],cad,ca,productList[0],mapIdToQuantity);
        
        
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(lstSubscriptionToInsert[0],cad,ca,productList[0],mapIdToQuantity);
        cad.QS_Quantity__c = 0;
        cad.QS_Maintain_Line__c = false;
        cad.QS_Start_Date__c = System.today().addDays(-10);
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(lstSubscriptionToInsert[1],cad,ca,productList[0],mapIdToQuantity);
        cad.QS_Quantity__c = 0;
        lstSubscriptionToInsert[1].SBQQ__RevisedSubscription__c = null;
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(lstSubscriptionToInsert[1],cad,ca,productList[0],mapIdToQuantity);
        
        CA2_AssetTriggerHandler cath = new CA2_AssetTriggerHandler();
        // cath.getAssetDetailStatusFromNegativeQuantity(cad,newAsset);
        CA2_CustomerAssetUtil.ByPassTrigger = false;
        
        cath.afterInsert();
        cath.afterUpdate();
    	 
        //CA2_AssetTriggerHandler.createCustomerAssets(new List<SBQQ__SubscribedAsset__c>{sbSubAsset});        
        //CA2_AssetTriggerHandler.createCustomerAssets(new List<Asset>{newAsset}, new Map<Id, SBQQ__SubscribedAsset__c>{sbSubAsset.Id => sbSubAsset});
        //CA2_AssetTriggerHandler.insertCustomerAssetDetail(new List<Asset>{newAsset}, new List<QS_Customer_Asset__c>{ca}, new Map<Id, Product2>{productList[0].Id => productList[0] , productList[1].Id => productList[1]});
        
        
        Test.stopTest();
    }
    
    @isTest static void CA2_AssetHandlerTestNegativeQuantity02() {
        Test.startTest();
        CA2_TriggerHandler.bypass('CA2_CustomerAssetDetailTriggerHandler');
         QS_Console__mdt currentConsoleSettings = [select Id, QS_Generate_CA_on_Update__c,QS_Expiration_Days__c,
                                                  QS_Contracting_Opp_No_CAD_Creation__c,QS_Enable_Twin_Fielding__c,
                                                  QS_ByPass_Trigger__c 
                                                  from QS_Console__mdt where MasterLabel =: System.Label.QS_Console_Master_Label LIMIT 1 ];
        
             currentConsoleSettings.QS_Enable_Twin_Fielding__c = false;
       
        CA2_CustomerAssetUtil.ByPassTrigger  = true;
        
        
        CA2_CustomerAssetUtil.ActivateTwinFielding = false;
         CA2_TriggerHandler.bypass('CA2_CustomerAssetDetailTriggerHandler');
        SBQQ__SubscribedAsset__c sbSubAsset = [Select id,SBQQ__Active__c,SBQQ__Asset__c,SBQQ__Subscription__c from SBQQ__SubscribedAsset__c LIMIT 1];
         CA2_TriggerHandler.bypass('CA2_CustomerAssetDetailTriggerHandler');
         CA2_CustomerAssetUtil.ActivateTwinFielding = false;
        Asset newAsset = [Select id from Asset LIMIT 1];
        List<Product2> productList = [Select id from Product2];
        QS_Customer_Asset__c ca = [Select id from QS_Customer_Asset__c LIMIT 1];
        CA2_AssetTriggerHandler cath = new CA2_AssetTriggerHandler();
        // cath.getAssetDetailStatusFromNegativeQuantity(cad,newAsset);
        CA2_CustomerAssetUtil.ByPassTrigger = false;
        
        cath.afterInsert();
        cath.afterUpdate();
         CA2_CustomerAssetUtil.ActivateTwinFielding = false;
		CA2_AssetTriggerHandler.createCustomerAssets(new List<SBQQ__SubscribedAsset__c>{sbSubAsset});      
         CA2_CustomerAssetUtil.ActivateTwinFielding = false;
         CA2_TriggerHandler.bypass('CA2_CustomerAssetDetailTriggerHandler');
       CA2_AssetTriggerHandler.createCustomerAssets(new List<Asset>{newAsset}, new Map<Id, SBQQ__SubscribedAsset__c>{sbSubAsset.Id => sbSubAsset});
        CA2_AssetTriggerHandler.insertCustomerAssetDetail(new List<Asset>{newAsset}, new List<QS_Customer_Asset__c>{ca}, new Map<Id, Product2>{productList[0].Id => productList[0] , productList[1].Id => productList[1]});
    	
        Test.stopTest();
    }
    
    @isTest static void CA2_AssetHandlerTestPositiveQuantity() {
        Account account = [Select id from Account LIMIT 1];
        
        // Create a product record
        List<Product2> productList = new List<Product2>();
        Product2 product = new Product2();
        product.ProductCode = 'product-1';
        product.Name = 'Hardware Product 1';
        product.Description = 'Hardware Product 1 Description';
        product.Family = 'HardwareFamily';
        product.QS_Generate_Asset__c = false;
        product.IsActive = true;
        product.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product.SBQQ__SubscriptionType__c = 'Renewable';
        product.SBQQ__SubscriptionTerm__c = 12;
        product.SBQQ__QuantityEditable__c = true;
        product.Product_Line__c='Core';
        product.Product_Category__c = 'Software';
        product.Product_Type__c = 'Recurring';
        product.Product_Services__c = 'Implementation';
        product.Asset_Class__c = 'Solar';
        product.SBQQ__IncludeInMaintenance__c = true;
        productList.add(product);
        
        Product2 product1 = new Product2();
        product1.ProductCode = 'product-2';
        product1.Name = 'Hardware Product 2';
        product1.Description = 'Hardware Product 2 Description';
        product1.Family = 'HardwareFamily';
        product1.QS_Generate_Asset__c = false;
        product1.IsActive = true;
        product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product1.SBQQ__SubscriptionType__c = 'Renewable';
        product1.SBQQ__SubscriptionTerm__c = 12;
        product1.SBQQ__QuantityEditable__c = true;
        product1.Product_Line__c='Core';
        product1.Product_Category__c = 'Software';
        product1.Product_Type__c = 'Recurring';
        product1.Product_Services__c = 'Implementation';
        product1.Asset_Class__c = 'Solar';
        product1.SBQQ__IncludeInMaintenance__c = true;
        productList.add(product1);
        
        insert  productList;       
        
        Asset newAsset = new Asset();
        newAsset.AccountId = account.Id;
        newAsset.Name = productList[0].Name;
        newAsset.Product2Id = productList[0].id;
        newAsset.Price = 0;
        newAsset.Quantity = -10;
        
        insert newAsset;
        
        Test.startTest();
        
        // Create a subscription record
        List<SBQQ__Subscription__c> lstSubscriptionToInsert = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = productList[0].Id;
        sub.SBQQ__Quantity__c = 10;
        sub.SBQQ__NetPrice__c = 0.00;
        sub.SBQQ__Account__c = account.id;
        sub.QS_Annual_Recurring_Revenue__c = 1.00;
        sub.SBQQ__SubscriptionStartDate__c = System.today();
        lstSubscriptionToInsert.add(sub);
        
        insert lstSubscriptionToInsert;
        
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c();
        sub1.SBQQ__Product__c = productList[0].Id;
        sub1.SBQQ__Quantity__c = 10;
        sub1.SBQQ__NetPrice__c = 1.00;
        sub1.SBQQ__Account__c = account.id;
        sub1.QS_Annual_Recurring_Revenue__c = 1.00;
        sub1.SBQQ__SubscriptionStartDate__c = System.today();
        sub1.SBQQ__RevisedSubscription__c = lstSubscriptionToInsert[0].Id;
        insert sub1;
        //sub1.QS_Annual_Recurring_Revenue__c = 2;
        //sub1.QS_Maintain_Line__c = true;
        
        SBQQ__SubscribedAsset__c sbSubAsset = new SBQQ__SubscribedAsset__c();
        sbSubAsset.SBQQ__Active__c = true;
        sbSubAsset.SBQQ__Asset__c = newAsset.Id;
        sbSubAsset.SBQQ__Subscription__c = lstSubscriptionToInsert[0].Id;
        sbSubAsset.QS_Created_By_Apex__c = true;
        insert sbSubAsset;
        
        QS_Customer_Asset__c ca = new QS_Customer_Asset__c(QS_Account__c = account.Id);
        insert ca; 
        
        // Insert a Customer Asset Detail with an OLD Start Date and FUTURE End Date
        QS_Customer_Asset_Detail__c cad = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Annual_Recurring_Revenue__c = 2,QS_Quantity__c = 2,QS_Maintain_Line__c = true,QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-365));
        insert cad; 
        Map<String,Decimal> mapIdToQuantity = new Map<String,Decimal>();
        mapIdToQuantity.put('Test',12);
        CA2_CustomerAssetUtil.queryCAByUniqueId(new Set<String>{'test'});
        CA2_CustomerAssetUtil.Subscription_CAUniqueId(lstSubscriptionToInsert);
        CA2_CustomerAssetUtil.getMatchingKeys(new List<Asset>{newAsset});
        CA2_CustomerAssetUtil.getMatchingKeys(new List<SBQQ__SubscribedAsset__c>{sbSubAsset});
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(cad,ca,productList[0],mapIdToQuantity);
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(sub1,cad,ca,productList[0],mapIdToQuantity);
        
        
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(lstSubscriptionToInsert[0],cad,ca,productList[0],mapIdToQuantity);
        cad.QS_Quantity__c = 0;
        cad.QS_Maintain_Line__c = false;
        cad.QS_Start_Date__c = System.today().addDays(-10);
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(sub1,cad,ca,productList[0],mapIdToQuantity);
        cad.QS_Quantity__c = 0;
        sub1.SBQQ__RevisedSubscription__c = null;
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(sub1,cad,ca,productList[0],mapIdToQuantity);
        
        CA2_AssetTriggerHandler cath = new CA2_AssetTriggerHandler();
        // cath.getAssetDetailStatusFromNegativeQuantity(cad,newAsset);
        
        delete sbSubAsset;
        Test.stopTest();
    }
    
}