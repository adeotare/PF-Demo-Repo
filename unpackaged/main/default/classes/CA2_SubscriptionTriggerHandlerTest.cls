@isTest
private class CA2_SubscriptionTriggerHandlerTest {
    @isTest static void subscriptionTriggerTest() {
        Account account = new Account();
        account.Name = 'Test acctName';
        account.BillingCountry = 'United States';
        insert account;
        
        // Create a product record
        List<Product2> productList = new List<Product2>();
        Product2 product = new Product2();
        product.ProductCode = 'product-1';
        product.Name = 'Hardware Product 1';
        product.Description = 'Hardware Product 1 Description';
        product.Family = 'HardwareFamily';
        product.QS_Generate_Asset__c = true;
        product.IsActive = true;
        product.SBQQ__SubscriptionPricing__c = 'Percent Of Total';
        product.SBQQ__SubscriptionType__c = 'Renewable';
        product.SBQQ__SubscriptionTerm__c = 12;
        product.SBQQ__QuantityEditable__c = true;
        product.SBQQ__IncludeInMaintenance__c = true;
        product.Product_Line__c = 'Core'; 
        product.Product_Category__c = 'Software';
        product.Product_Type__c = 'SaaS';
        product.Product_Services__c = 'N/A';
        product.Asset_Class__c = 'Solar';
      
        productList.add(product);
        
        Product2 product1 = new Product2();
        product1.ProductCode = 'product-2';
        product1.Name = 'Hardware Product 2';
        product1.Description = 'Hardware Product 2 Description';
        product1.Family = 'HardwareFamily';
        product1.QS_Generate_Asset__c = true;
        product1.IsActive = true;
        product1.SBQQ__SubscriptionPricing__c = null;
        product1.SBQQ__SubscriptionType__c = 'Renewable';
        product1.SBQQ__SubscriptionTerm__c = 12;
        product1.SBQQ__QuantityEditable__c = true;
        product1.SBQQ__IncludeInMaintenance__c = true;
        product1.Product_Line__c = 'Core'; 
        product1.Product_Category__c = 'Software';
        product1.Product_Type__c = 'SaaS';
        product1.Product_Services__c = 'N/A';
        product1.Asset_Class__c = 'Solar';
        
        productList.add(product1);

        insert  productList;   
        
        //productList[0].SBQQ__RequiredByProduct__c = productList[1].Id;
        //update productList[0];
        
        Asset ast = new Asset();
        ast.AccountId = account.id;
        ast.Name = 'Test Asset';
        insert ast;
        
        QS_Customer_Asset__c qcAsset = new QS_Customer_Asset__c ();
        qcAsset.Name = 'Test';
        qcAsset.QS_Account__c = account.id;
        insert qcAsset;
        
        QS_Customer_Asset_Detail__c acAssetDetail = new QS_Customer_Asset_Detail__c();
        acAssetDetail.QS_Customer_Asset__c = qcAsset.Id;
        insert acAssetDetail;
        

        Test.startTest();

        // Create a subscription record
        List<SBQQ__Subscription__c> lstSubscriptionToInsert = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = productList[0].Id;
        sub.SBQQ__RequiredByProduct__c = productList[0].Id;
        sub.SBQQ__Quantity__c = 1;
        sub.SBQQ__NetPrice__c = 1.00;
        sub.SBQQ__Account__c = account.id;
        sub.QS_Annual_Recurring_Revenue__c = 1.00;
        sub.SBQQ__SubscriptionStartDate__c = System.today();
        lstSubscriptionToInsert.add(sub);
        
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c();
        sub1.SBQQ__Product__c = productList[1].Id;
        sub1.SBQQ__Quantity__c = -1;
        sub1.SBQQ__NetPrice__c = 1.00;
        sub1.SBQQ__Account__c = account.id;
        sub1.QS_Annual_Recurring_Revenue__c = 1.00;
        sub1.SBQQ__SubscriptionStartDate__c = System.today();
        lstSubscriptionToInsert.add(sub1);
        
        
        
        insert lstSubscriptionToInsert;
        
        SBQQ__Subscription__c sub3 = new SBQQ__Subscription__c();
        sub3.SBQQ__Product__c = productList[1].Id;
        sub3.SBQQ__Quantity__c = -1;
        sub3.SBQQ__NetPrice__c = 1.00;
        sub3.SBQQ__Account__c = account.id;
        sub3.QS_Annual_Recurring_Revenue__c = 1.00;
        sub3.SBQQ__SubscriptionStartDate__c = System.today();
        sub3.SBQQ__RevisedSubscription__c = lstSubscriptionToInsert[0].Id;
        insert sub3;
        
        // Step1 Check one Customer Assets with Product not equal to Percent Of Total have to be Created
        AccounttWrapper accwrap = new AccounttWrapper(account.Id); 
        List<QS_Customer_Asset__c> lstCustomerAssets = accwrap.refreshCA();//getCustomerAssets(account.Id);
        System.assertEquals(1, lstCustomerAssets.size());
        List<QS_Customer_Asset_Detail__c> lstCustomerAssetDetail = lstCustomerAssets[0].QS_Customer_Asset_Details__r;
        System.assertEquals(1, lstCustomerAssetDetail.size());
        //Checking for Asset Status 
       // System.assertEquals('Pending Activation', lstCustomerAssetDetail[0].QS_Asset_Status__c);
        
        
        // Step 2 Check for existing Customer Assets and no customer assets to be created
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c();
        sub2.SBQQ__Product__c = productList[0].Id;
        sub2.SBQQ__Quantity__c = 1;
        sub2.SBQQ__NetPrice__c = 1.00;
        sub2.SBQQ__Account__c = account.id;
        sub2.QS_Annual_Recurring_Revenue__c = 1.00;
        sub2.SBQQ__SubscriptionStartDate__c = System.today();
        insert sub2;
        
        accwrap.refreshCA();
        List<QS_Customer_Asset__c> lstCustomerAssets1 = accwrap.caList;//getCustomerAssets(account.Id);
         System.assertEquals(1, lstCustomerAssets1.size());
        
         List<QS_Customer_Asset_Detail__c> lstCustomerAssetDetail1 = lstCustomerAssets1[0].QS_Customer_Asset_Details__r;//getCustomerAssetsDetails(lstCustomerAssets1[0].id);
         System.assertEquals(1, lstCustomerAssetDetail1.size());
        
        QS_Customer_Asset_Detail__c cad = new QS_Customer_Asset_Detail__c();
        cad.QS_End_Date__c = System.today().addDays(100);
        cad.QS_Start_Date__c = System.today().addDays(-100);
        cad.QS_Customer_Asset__c = lstCustomerAssets1[0].Id;
        insert cad;
        sub3.SBQQ__TerminatedDate__c = System.today().adddays(-10);
        CA2_SubscriptionTriggerHandler cth = new CA2_SubscriptionTriggerHandler();
        update product1;
        
        
        
        
        
        sub3.SBQQ__TerminatedDate__c = System.today().adddays(10);
        update sub3;
        
        
        sub3.SBQQ__TerminatedDate__c = null;
        update sub3;
        
        
        SBQQ__SubscribedAsset__c subAsset = new SBQQ__SubscribedAsset__c();// this work need to be continued
        
		for( SBQQ__Subscription__c s: lstSubscriptionToInsert){
            system.debug('-->'+s.QS_Product_Subscription_Pricing__c);
            system.debug('-->'+s.QS_Parent_Customer_Asset_Id__c);
        }
        CA2_CustomerAssetUtil.NoCADCreationFromOpp = false;
        CA2_CustomerAssetUtil.ByPassTrigger = false;
        CA2_CustomerAssetUtil.Create_CA_On_Update = true;
        
        List<SBQQ__Subscription__c> lstSubscriptionToInsert2 = [Select id,
									SBQQ__Product__c,
                                   	SBQQ__RequiredByProduct__c,CurrencyIsoCode,
                                   	SBQQ__Quantity__c,SBQQ__NetPrice__c,QS_CA_End_Date__c,
                                   	SBQQ__Account__c,SBQQ__Contract__c,
                                   	QS_Annual_Recurring_Revenue__c,QS_CA_Quantity__c,QS_CA_Start_Date__c,
                                   	SBQQ__SubscriptionStartDate__c ,QS_Customer_Asset_Unique_Id__c,SBQQ__RevisedSubscription__c,
                                   QS_Product_Subscription_Pricing__c,QS_Parent_Customer_Asset_Id__c,QS_Customer_Asset_Account_Id__c,QS_Secondary_Account_Id__c
                                                                
                                   from SBQQ__Subscription__c];
        //lstSubscriptionToInsert*/
        for( SBQQ__Subscription__c s: lstSubscriptionToInsert2){
            system.debug('-->'+s.QS_Product_Subscription_Pricing__c);
            system.debug('-->'+s.QS_Parent_Customer_Asset_Id__c);
        }
        qcAsset.QS_Customer_Asset_Unique_Id__c = lstSubscriptionToInsert[0].QS_Customer_Asset_Unique_Id__c;
        update qcAsset;
        CA2_SubscriptionTriggerHandler handler = new CA2_SubscriptionTriggerHandler();
        handler.createCustomerAssets(lstSubscriptionToInsert2);
        handler.afterInsert();
        handler.afterUpdate();
        
        
       // Map<Id, SBQQ__Subscription__c> tempMap = handler.subsWithRelated;
        //handler.createCustomerAssets(lstSubscriptionToInsert);
        //
        
        //handler.handleReductions(lstSubscriptionToInsert);
        Test.stopTest();
    }
    
     
    /* Need Amendment Method */ 
    /* Need Product Generation Method */
    /* Contracting Method */

    public class AccounttWrapper {
        public AccounttWrapper(String accId) {
            this.accountId = accId;
        }
        
        private Id accountId {get; set;}
        
        public List<SBQQ__Subscription__c> subscriptions {get; set;}
        
        public List<Asset> accountAssets {get; set;}
        
        public List<QS_Customer_Asset__c> caList {get; set;}
        
        public List<QS_Customer_Asset__c> refreshCA() {
            caList = [SELECT Id, QS_Quantity__c, QS_New_Asset_Status__c, QS_Product__c, (SELECT Id, QS_New_Asset_Status__c, QS_Product__c,QS_End_Date__c,QS_Start_Date__c FROM QS_Customer_Asset_Details__r) FROM QS_Customer_Asset__c WHERE QS_Account__c =: accountId];
            return caList;
        }
        
        public List<SBQQ__Subscription__c> refreshSub() {
            subscriptions = [SELECT Id, SBQQ__Product__c FROM SBQQ__Subscription__c WHERE SBQQ__Account__c =: accountId];
            return subscriptions;
        }
        
        public List<Asset> refreshAsset() {
            system.debug('-->'+accountId);
            accountAssets = [SELECT Id, Quantity FROM Asset WHERE AccountId =: accountId];
            system.debug('-->'+accountAssets);
            return accountAssets;
        }
        
        public void refreshAll() {
            refreshCA();
            refreshSub();
            refreshAsset();
        }


    }   
    
}