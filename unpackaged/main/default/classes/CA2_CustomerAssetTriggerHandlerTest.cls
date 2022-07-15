@isTest
private class CA2_CustomerAssetTriggerHandlerTest {    
    @isTest static void customerAssetTriggerTest() {
        
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
        product1.SBQQ__QuantityEditable__c = true;
        product1.SBQQ__IncludeInMaintenance__c = true;
        product1.Product_Line__c = 'Core'; 
        product1.Product_Category__c = 'Software';
        product1.Product_Type__c = 'SaaS';
        product1.Product_Services__c = 'N/A';
        product1.Asset_Class__c = 'Solar';    
        productList.add(product1);

        insert  productList; 

        Test.startTest();
          QS_Customer_Asset__c ca = new QS_Customer_Asset__c(QS_Account__c = account.Id);
        insert ca; 
        
        // Insert a Customer Asset Detail with an OLD Start Date and FUTURE End Date
        QS_Customer_Asset_Detail__c cad = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-365),QS_End_Date__c = System.today().addDays(+5));
        insert cad;        
        update ca;
        AccounttWrapper accWrap = new AccounttWrapper(account.id);
        accWrap.refreshCA();
        system.assertEquals(1, accWrap.caList.size());
        
        //test Cad Status Decommissioned
       
        update cad;
        //ca.QS_Quantity__c = 0;
        update ca;
        accWrap.refreshCA();
        
        //Test CAD Status Active
       
        cad.QS_Quantity__c = 2;
        update cad;        
        update ca;
        accWrap.refreshCA();
       
        cad.QS_Quantity__c = 2;
        update cad;        
        update ca;
        accWrap.refreshCA();
       
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
            caList = [SELECT Id, QS_Quantity__c, QS_New_Asset_Status__c, QS_Product__c, (SELECT Id, QS_New_Asset_Status__c, QS_Product__c FROM QS_Customer_Asset_Details__r) FROM QS_Customer_Asset__c WHERE QS_Account__c =: accountId];
            return caList;
        }
        
        public List<SBQQ__Subscription__c> refreshSub() {
            subscriptions = [SELECT Id, SBQQ__Product__c FROM SBQQ__Subscription__c WHERE SBQQ__Account__c =: accountId];
            return subscriptions;
        }
        
        public List<Asset> refreshAsset() {
            accountAssets = [SELECT Id, Quantity FROM Asset WHERE AccountId =: accountId];
            return accountAssets;
        }
        
        public void refreshAll() {
            refreshCA();
            refreshSub();
            refreshAsset();
        }


    }   
    
}