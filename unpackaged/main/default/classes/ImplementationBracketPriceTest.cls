@isTest
private class ImplementationBracketPriceTest{

    @testSetup 
    static void generatedata() {
    
        Pricebook2 priceBook= new Pricebook2 (Name = 'Standard Price Book');
        insert priceBook;
        
        Account acc = new Account(Name='TestCP',
                                Account_Price_Book__c = priceBook.Id);
        insert acc;

        
        MSA_Contract__c msa = new MSA_Contract__c(Account_Name__c = acc.Id ,
                                                MSA_Status__c = 'In Negotiation',
                                                CurrencyIsoCode = 'USD');                               
        insert msa;
        
        
        
        Product2 product = new Product2(Name = 'Drive O&M', 
                                    Product_Line__c = 'Core', 
                                    ProductCode = 'GB-AD-PS-OT-IM-WD-ST-EWT',
                                    Product_Category__c = 'Software',
                                    Product_Type__c = 'SaaS',
                                    Product_Services__c = 'N/A',
                                    QuantityUnitOfMeasure = 'MWp',
                                    Asset_Class__c = 'Solar'
                                    );
        insert product;
        
        MSA_Implementation_Bracket_Price__c implementPrice = new MSA_Implementation_Bracket_Price__c(Account__c = acc.Id,
                                        Product__c = product.Id,  
                                        MSA_Contract__c = msa.Id);
                                        //Cross_Orders__c = ,
                                        //Lower_Bound__c = ,
                                        //Upper_Bound__c = ,
                                        //Discount_Amount__c
                                        //Product_List_Price__c = 24, 
                                        //SBQQ__Price__c = 25,
                                        //Same_As_List_Price__c = FALSE);
        insert implementPrice;
        }
        
        
        @isTest static void fetchAccountNameTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<MSA_Contract__c> accName = ImplementationBracketPrice.fetchAccountName(msa);
            String accountName = string.valueOf(accName[0].Account_Name__r.Name);
            System.debug('Account Name : ' + accountName);
            Test.stopTest();
            System.assertEquals('TestCP', accountName );
        }
        
        
        @isTest static void fetchCurrencyTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<MSA_Contract__c> curr = ImplementationBracketPrice.fetchCurrency(msa);
            String currencyName = string.valueOf(curr[0].CurrencyIsoCode);
            System.debug('Currency Name : ' + currencyName);
            Test.stopTest();
            System.assertEquals('USD', currencyName);
        }
        
        
        @isTest static void implementationBracketPriceRecordsTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<MSA_Implementation_Bracket_Price__c> implementList = ImplementationBracketPrice.implementationBracketPriceRecords(msa);
            Test.stopTest();
            System.assert(implementList.size()>0);
        }
        
        
        @isTest static void deleteImplementationPriceRecordTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<MSA_Implementation_Bracket_Price__c> implementList = ImplementationBracketPrice.implementationBracketPriceRecords(msa);
            ImplementationBracketPrice.deleteImplementationPriceRecord(implementList,msa);
            Test.stopTest();
        }

}