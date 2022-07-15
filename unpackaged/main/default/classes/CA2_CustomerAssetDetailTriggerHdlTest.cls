@isTest
private class CA2_CustomerAssetDetailTriggerHdlTest {
        @isTest static void CA2_CustomerAssetDetailTriggerHandlerTest() {
        
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
        CA2_CustomerAssetUtil.Create_CA_On_Update = true;
            
        cad.QS_Start_Date__c = System.today().addDays(-100);
        cad.QS_End_Date__c = System.today().addDays(110);
        update cad;   
            
            
        cad.QS_End_Date__c = System.today().addDays(-10);
        update cad;    
        
        cad.QS_Start_Date__c = System.today().addDays(100);
        cad.QS_End_Date__c = System.today().addDays(110);
        update cad;      
            
        cad.QS_End_Date__c = null;
        update cad;       
       
    }
    
    @isTest static void CA2_CustomerAssetDetailStatusbatchableTest() {
        
       Account account = new Account();
        account.Name = 'Test acctName';
        account.BillingCountry = 'United States';
        insert account;
        
        // Create a product record
        List<Product2> productList = new List<Product2>();       
        Product2 product = new Product2();
        product.ProductCode = 'product-2';
        product.Name = 'Hardware Product 2';
        product.Description = 'Hardware Product 2 Description';
        product.Family = 'HardwareFamily';
        product.QS_Generate_Asset__c = true;
        product.IsActive = true;
        product.Product_Line__c = 'Core'; 
        product.Product_Category__c = 'Software';
        product.Product_Type__c = 'SaaS';
        product.Product_Services__c = 'N/A';
        
       product.Asset_Class__c = 'Solar';
        product.SBQQ__SubscriptionPricing__c = 'Percent Of Total';
        product.SBQQ__SubscriptionType__c = 'Renewable';
        product.SBQQ__SubscriptionTerm__c = 12;
        product.SBQQ__QuantityEditable__c = true;
        product.SBQQ__IncludeInMaintenance__c = true;
        productList.add(product);
        
        
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
        product1.Product_Line__c = 'Core'; 
        product1.Product_Category__c = 'Software';
        product1.Product_Type__c = 'SaaS';
        product1.Product_Services__c = 'N/A';
        
       product1.Asset_Class__c = 'Solar';
        product1.SBQQ__IncludeInMaintenance__c = true;
        productList.add(product1);
        
        
        Product2 product2 = new Product2();
        product2.ProductCode = 'product-3';
        product2.Name = 'Hardware Product 3';
        product2.Description = 'Hardware Product 3 Description';
        product2.Family = 'HardwareFamily';
        product2.QS_Generate_Asset__c = true;
        product2.IsActive = true;
        product2.SBQQ__SubscriptionPricing__c = 'Percent Of Total';
        product2.SBQQ__SubscriptionType__c = 'Renewable';
        product2.SBQQ__SubscriptionTerm__c = 12;
        product2.SBQQ__QuantityEditable__c = true;
        product2.SBQQ__IncludeInMaintenance__c = true;
        product2.Product_Line__c = 'Core'; 
        product2.Product_Category__c = 'Software';
        product2.Product_Type__c = 'SaaS';
        product2.Product_Services__c = 'N/A';
        
       product2.Asset_Class__c = 'Solar';
        productList.add(product2);

        insert  productList; 
        //===========================================
        Opportunity newOPp = new Opportunity();
        newOPp.Name = 'Test Opp';
        newOPp.AccountId = account.Id;
        newOpp.StageName = '00 - MQL';
        newOpp.CloseDate = Date.today();
        newOpp.QS_Sales_Forecast_Category__c = 'Commit';
        newOpp.QS_Order_Type__c = 'Commit';
        newOpp.Type ='New';
        newOpp.QS_Order_Type__c = 'New Customer';
        insert newOPp;
        
        
        Opportunity closeLostRenewalOpp = new Opportunity();
        closeLostRenewalOpp.Name = 'Test Opp';
        closeLostRenewalOpp.AccountId = account.Id;
        closeLostRenewalOpp.StageName = '00 - MQL';
        closeLostRenewalOpp.CloseDate = Date.today();
        closeLostRenewalOpp.QS_Sales_Forecast_Category__c = 'Commit';
        closeLostRenewalOpp.QS_Order_Type__c = 'Commit';
        closeLostRenewalOpp.Type ='Existing Customer';
        closeLostRenewalOpp.QS_Order_Type__c = 'Subscription Renewal';
        insert closeLostRenewalOpp;
        
        Contract cont = new Contract();
        cont.AccountId = account.Id;
        cont.SBQQ__Opportunity__c = newOPp.Id;
        cont.SBQQ__RenewalOpportunity__c = closeLostRenewalOpp.Id;
        cont.StartDate = Date.today().addDays(-380);
        cont.ContractTerm = 12;
        insert cont;
        
            
        //====================================================
        QS_Customer_Asset__c ca = new QS_Customer_Asset__c(QS_Account__c = account.Id);
        insert ca; 
        
        // Insert a Customer Asset Detail with an OLD Start Date and FUTURE End Date
        List<QS_Customer_Asset_Detail__c> lstCadToInsert = new List<QS_Customer_Asset_Detail__c>();
        QS_Customer_Asset_Detail__c cad = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-365),QS_End_Date__c = System.today().addDays(-10));
        lstCadToInsert.add(cad);
        
        QS_Customer_Asset_Detail__c cad1 = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Product__c = productList[0].id, QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-365),QS_End_Date__c = System.today().addDays(+10));
        lstCadToInsert.add(cad1);
        
        QS_Customer_Asset_Detail__c cad2 = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Product__c = productList[1].id, QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-30),QS_End_Date__c = System.today().addDays(+15));
        lstCadToInsert.add(cad2);
        
        
        QS_Customer_Asset_Detail__c cad3 = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Product__c = productList[2].id, QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-30),QS_End_Date__c = System.today().addDays(+15));
        lstCadToInsert.add(cad3);
        
        QS_Customer_Asset_Detail__c cad4 = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Product__c = productList[2].id, QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-30),QS_End_Date__c = System.today().addDays(+15));
        lstCadToInsert.add(cad4);
        
        QS_Customer_Asset_Detail__c cadWithRenewal = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Product__c = productList[2].id, QS_Currently_Active__c=False,QS_Start_Date__c = System.today(),QS_End_Date__c = System.today().addDays(-16));
        cadWithRenewal.QS_Contract__c = cont.Id;                
        lstCadToInsert.add(cadWithRenewal);
        QS_Customer_Asset_Detail__c cadReducedCurrent = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Product__c = productList[2].id, QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-30),QS_End_Date__c = System.today().addDays(+15));
        lstCadToInsert.add(cadReducedCurrent);
        
        QS_Customer_Asset_Detail__c cadReducedExpired = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Product__c = productList[2].id, QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-90),QS_End_Date__c = System.today().addDays(-35));
        lstCadToInsert.add(cadReducedExpired);
        
        QS_Customer_Asset_Detail__c cadPendingRenewal = new QS_Customer_Asset_Detail__c(QS_Customer_Asset__c = ca.id,QS_Product__c = productList[1].id, QS_Currently_Active__c=False,QS_Start_Date__c = System.today().addDays(-30),QS_End_Date__c = System.today().addDays(+15));
        cadPendingRenewal.QS_Contract__c = cont.Id;
        lstCadToInsert.add(cadPendingRenewal);
        insert lstCadToInsert; 
        
       
       
         DateTime future = system.now().addMinutes(1);
        Integer year = future.year();
        Integer month = future.month();
        Integer day = future.day();
        Integer hour = future.hour();
        Integer minute = future.minute();
        Integer second = future.second();
         String cron_exp = second + ' ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;            

        Test.startTest();

        // Create an instance of CA2_CustomerAssetDetailStatusbatchable
        CA2_CustomerAssetDetailStatusSchedule scheduler = new CA2_CustomerAssetDetailStatusSchedule();

        // Schedule the job using System's scheduler
        String jobId = System.schedule('testBasicScheduledApex', cron_exp, scheduler);
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals(cron_exp, ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Force scheduler execution
        //scheduler.execute(null);
        
       // cad.QS_End_Date__c = 
        Test.stopTest();
    }  
}