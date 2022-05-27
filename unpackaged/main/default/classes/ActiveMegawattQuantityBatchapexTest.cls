@isTest
private class ActiveMegawattQuantityBatchapexTest {
    
 @testSetup
    static void testBatch()
     {
     Account Acc = new Account(name='Adapture Renewables');
     insert Acc;
         
   Account_plant__c ae = new Account_plant__c();
       ae.Account__c= Acc.id;
        insert ae;
         
       Product2 product = new Product2(Name = 'Drive O&M', 
                                    Product_Line__c = 'Core', 
                                    Product_Category__c = 'Software',
                                    Product_Type__c = 'SaaS',
                                    Product_Services__c = 'N/A',
                                    QuantityUnitOfMeasure = 'MWp',
                                    Asset_Class__c = 'Solar'
                                    );
                                     insert product; 
    
         Plant_Product_Transaction__c pt = new Plant_Product_Transaction__c(
                                    
                                    Product__c=product.Id,
                                    Account__c=Acc.id,
                                    Plant__c=ae.Id,
                                    Status__c ='contracted' 
                                    );
                                insert pt;
     }
         
@isTest static void test(){        
Test.startTest();
ActiveMegawattQuantityBatchapex myBatchObject = new ActiveMegawattQuantityBatchapex(); 
Id batchId = Database.executeBatch(myBatchObject);
Test.stopTest();
 
     }
     }