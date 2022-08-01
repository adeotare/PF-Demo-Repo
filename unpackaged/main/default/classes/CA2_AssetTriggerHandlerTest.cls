/**
 * Test Class for Asset Trigger handler.
 *
 * @author: Saketha Angirekula / Advanced Technology Group (www.atginfo.com)
 */
@isTest
private class CA2_AssetTriggerHandlerTest {
    /**
     * Asset Trigger handler test.
     */
	@isTest static void assetTriggerTest() {
        
       Account account = new Account();
        account.Name = 'Test acctName';
        account.BillingCountry = 'United States';
        insert account;
        
        
        
        // Create a product record
        List<Product2> productList = new List<Product2>();       
        
        Product2 product1 = new Product2();
        product1.ProductCode = 'product-2';
        product1.Name = 'Hardware Product 2';
        product1.Description = 'Hardware Product 2 Description';
        product1.Family = 'HardwareFamily';
        product1.QS_Generate_Asset__c = true;
        product1.IsActive = true;
        product1.SBQQ__SubscriptionPricing__c = 'Percent Of Total';
        product1.SBQQ__SubscriptionType__c = 'Renewable';
        product1.Product_Line__c = 'Core'; 
        product1.Product_Category__c = 'Software';
        product1.Product_Type__c = 'SaaS';
        product1.Product_Services__c = 'N/A';
        
       product1.Asset_Class__c = 'Solar';
        product1.SBQQ__SubscriptionTerm__c = 12;
        product1.SBQQ__QuantityEditable__c = true;
        product1.SBQQ__IncludeInMaintenance__c = true;
        productList.add(product1);

		insert  productList; 

        Test.startTest();
        Asset newAsset = new Asset();
        newAsset.AccountId = account.Id;
        newAsset.Name = productList[0].Name;
        newAsset.Product2Id = productList[0].id;
        newAsset.Price = 2;
        newAsset.Quantity = 2;

        insert newAsset;        
        
        
       
		update product1;
        
        newAsset.Price = 3;
        update newAsset;
        
        Test.stopTest();
    }

     /**
     * Subscribed Asset Trigger handler test.
     */   
    @isTest static void subscriptionAssetTriggerTest() {
        
       Account account = new Account();
        account.Name = 'Test acctName';
        account.BillingCountry = 'United States';
        insert account;
        
       
        
        // Create a product record
        List<Product2> productList = new List<Product2>();       
        
        Product2 product1 = new Product2();
        product1.ProductCode = 'product-2';
        product1.Name = 'Hardware Product 2';
        product1.Description = 'Hardware Product 2 Description';
        product1.Family = 'HardwareFamily';
        product1.QS_Generate_Asset__c = true;
        product1.IsActive = true;
        product1.SBQQ__SubscriptionPricing__c = 'Percent Of Total';
        product1.SBQQ__SubscriptionType__c = 'Renewable';
        product1.SBQQ__SubscriptionTerm__c = 12;
        product1.Product_Line__c = 'Core'; 
        product1.Product_Category__c = 'Software';
        product1.Product_Type__c = 'SaaS';
        product1.Product_Services__c = 'N/A';
        
       product1.Asset_Class__c = 'Solar';
        product1.SBQQ__QuantityEditable__c = true;
        product1.SBQQ__IncludeInMaintenance__c = true;
        productList.add(product1);

		insert  productList; 

        Test.startTest();
        Asset newAsset = new Asset();
        newAsset.AccountId = account.Id;
        newAsset.Name = productList[0].Name;
        newAsset.Product2Id = productList[0].id;
        newAsset.Price = 2;
        newAsset.Quantity = 2;

        insert newAsset;
        
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();
        sub.SBQQ__Product__c = productList[0].Id;
        sub.SBQQ__Quantity__c = 1;
        sub.SBQQ__NetPrice__c = 1.00;
        sub.SBQQ__Account__c = account.id;
        sub.QS_Annual_Recurring_Revenue__c = 1.00;
        sub.SBQQ__SubscriptionStartDate__c = System.today();
        insert sub;
        
        SBQQ__SubscribedAsset__c sbSubAsset = new SBQQ__SubscribedAsset__c();
        sbSubAsset.SBQQ__Active__c = true;
        sbSubAsset.SBQQ__Asset__c = newAsset.Id;
        sbSubAsset.SBQQ__Subscription__c = sub.Id;
        insert sbSubAsset;	
        
        sbSubAsset.QS_Created_By_Apex__c =true;
        update sbSubAsset;
        delete sbSubAsset;
        
        AccounttWrapper wrap = new AccounttWrapper(account.Id);
        wrap.refreshAll();
        
        QS_Customer_Asset_Detail__c currentCAT = new QS_Customer_Asset_Detail__c();
       
        if (!wrap.caList.isEmpty()) {
        if(wrap.caList[0] <> null)
            currentCAT = [select Id,QS_New_Asset_Status__c,
                          QS_Terminated_Date__c from QS_Customer_Asset_Detail__c 
                          where QS_Customer_Asset__c =: wrap.caList[0].Id Limit 1];
        }
        
      
        
        Test.stopTest();
    }
    
    /* TODO: Need Amendment Method */ 
    /* TODO: Need Product Generation Method */
    /* TODO: Contracting Method */

    /**
     * Internal class to represent account wrapper.
     */
    public class AccounttWrapper {
        /**
         * Account wrapper constructor
         * @param assId Account ID.
         */
        public AccounttWrapper(String accId) {
            this.accountId = accId;
        }
        
        private Id accountId {get; set;}
        
        /**
         * List of subscriptions.
         */
        public List<SBQQ__Subscription__c> subscriptions {get; set;}
        
        /**
         * List of assets.
         */
        public List<Asset> accountAssets {get; set;}
        
        /**
         * List of Customer Assets.
         */
        public List<QS_Customer_Asset__c> caList {get; set;}
        
        /**
         * Reloads the list of Customer Assets.
         * @return list of queried Customer Assets.
         */
        public List<QS_Customer_Asset__c> refreshCA() {
            caList = [SELECT Id, QS_Quantity__c,QS_New_Asset_Status__c, QS_Product__c, (SELECT Id, QS_New_Asset_Status__c, QS_Product__c FROM QS_Customer_Asset_Details__r) FROM QS_Customer_Asset__c WHERE QS_Account__c =: accountId];
            return caList;
        }
        
        /**
         * Reloads the list of subscriptions.
         * @return list of queried subscriptions.
         */
        public List<SBQQ__Subscription__c> refreshSub() {
            subscriptions = [SELECT Id, SBQQ__Product__c FROM SBQQ__Subscription__c WHERE SBQQ__Account__c =: accountId];
            return subscriptions;
        }
        
        /**
         * Reloads teh list of assets.
         * @return list of queried assets.
         */
        public List<Asset> refreshAsset() {
            accountAssets = [SELECT Id, Quantity FROM Asset WHERE AccountId =: accountId];
            return accountAssets;
        }
        
        /**
         * Refreshes all internal lists.
         */
        public void refreshAll() {
            refreshCA();
            refreshSub();
            refreshAsset();
        }


    }   
    
}