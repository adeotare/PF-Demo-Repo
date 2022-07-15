@IsTest 
private class CA2_TwinFieldTest {
   
    
    
    
    @isTest
        public static void testOverrideBeforeInsert() {
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
            
        Test.startTest();
          QS_Customer_Asset__c ca = new QS_Customer_Asset__c(QS_Account__c = account.Id);
        insert ca; 
        
        // Insert a Customer Asset Detail with an OLD Start Date and FUTURE End Date
        QS_Customer_Asset_Detail__c cad = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-365),QS_End_Date__c = System.today().addDays(+5));
        insert cad; 
    
            List<sObject> lstSobjects = (List<sObject>)[select QS_Customer_Asset__c ,id,QS_Currently_Active__c,QS_Start_Date__c,QS_End_Date__c from QS_Customer_Asset_Detail__c];
            //List<Contact> contactList = new List<Contact>{c};
            CA2_TwinField.runTwinHelper(lstSobjects);
    
            //System.assert(c.AccountId == a.Id); //test standard same name / same type twinning
            //System.assert(c.Phone == a.Phone, c.Phone); //test standard same name / same type twinning
            //System.assert(c.LastName == a.Name, c.LastName); //override mapping
        } 
}