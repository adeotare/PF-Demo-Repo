@isTest
private class CA2_CustomerAssetUtilTest {
  
    @isTest
    private static void method01(){
        Test.startTest();
        
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
        
        SBQQ__SubscribedAsset__c subAsset = new SBQQ__SubscribedAsset__c();
        subAsset.SBQQ__Asset__c = ast.id;
        subAsset.SBQQ__Subscription__c = lstSubscriptionToInsert[0].Id;
        insert subAsset;
        
        Test.stopTest();
        
        List<SBQQ__SubscribedAsset__c> subAssetList = [SELECT Id,QS_Customer_Asset_Unique_Id__c FROM SBQQ__SubscribedAsset__c];
        
        
        CA2_CustomerAssetUtil.queryProductsById(new Set<Id>{productList[0].Id, productList[1].Id});
        
        String uniqueId = qcAsset.QS_Customer_Asset_Unique_Id__c;
        CA2_CustomerAssetUtil.queryCAByUniqueId(new Set<String>{uniqueId});
        
        CA2_CustomerAssetUtil.Subscription_CAUniqueId(lstSubscriptionToInsert);
        
        List<Asset> ast2 = [SELECT Id,QS_Customer_Asset_Unique_Id__c,QS_Customer_Asset_Account_Id__c FROM Asset];
        
        CA2_CustomerAssetUtil.getMatchingKeys(ast2);
        
        CA2_CustomerAssetUtil.getMatchingKeys(subAssetList);
        
        CA2_CustomerAssetUtil.getCurrentlyActiveflagFromCAD(acAssetDetail);
        
        CA2_CustomerAssetUtil.CustomerAssetDetailStatus(acAssetDetail,qcAsset,productList[0],new Map<String,Decimal>{'Test' => 2.0});
        
    }
   
}