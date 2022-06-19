@isTest
private class AccountForMSAContractedPricesTest {

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
        
        
        
         SBQQ__ContractedPrice__c contPrice = new SBQQ__ContractedPrice__c(SBQQ__Account__c = acc.Id,
                                        SBQQ__Product__c = product.Id, 
                                        //SBQQ__Product__r.ProductCode = 'CodeXYZ', 
                                        Product_List_Price__c = 24, 
                                        SBQQ__Price__c = 25,
                                        Same_As_List_Price__c = FALSE);
        insert contPrice;
        
        }
        
        @isTest static void fetchAccountNameTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<MSA_Contract__c> accName = AccountForMSAContractedPrices.fetchAccountName(msa);
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
            List<MSA_Contract__c> curr = AccountForMSAContractedPrices.fetchCurrency(msa);
            String currencyName = string.valueOf(curr[0].CurrencyIsoCode);
            System.debug('Currency Name : ' + currencyName);
            Test.stopTest();
            System.assertEquals('USD', currencyName);
            

        }
        
        @isTest static void fetchPriceBookTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<MSA_Contract__c> pb = AccountForMSAContractedPrices.fetchPriceBook(msa);
            String priceBook = string.valueOf(pb[0].Account_Name__r.Account_Price_Book__r.Name);
            System.debug('Price Book Name : ' + priceBook);
            Test.stopTest();
            System.assertEquals('Standard Price Book', priceBook);
            

        }
        
        @isTest static void contractedPricesRecordTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<SBQQ__ContractedPrice__c> cpList = AccountForMSAContractedPrices.contractedPricesRecord(msa);
            Test.stopTest();
            System.assert(cpList.size()>0);
            
        }
        
        @isTest static void priceBookRecordsTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<SBQQ__ContractedPrice__c> cpList = AccountForMSAContractedPrices.priceBookRecords(msa);
            System.debug('Cp List : '+ cpList);
            Test.stopTest();
            System.assert(cpList.size()==0);
            

        }
        
       @isTest static void updateContractedPricesTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<SBQQ__ContractedPrice__c> cpList = AccountForMSAContractedPrices.contractedPricesRecord(msa);
            String msg = AccountForMSAContractedPrices.updateContractedPrices(cpList);
            System.debug('Message : '+ msg);
            Test.stopTest();
            System.assertEquals('Success: Contracted Prices updated successfully', msg);

        }
        
        @isTest static void deleteContractedPriceTest() {
            Test.startTest();
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<SBQQ__ContractedPrice__c> cpList = AccountForMSAContractedPrices.contractedPricesRecord(msa);
            AccountForMSAContractedPrices.deleteContractedPrice(cpList , msa);
            Test.stopTest();
           // System.assert(deleteList.size()==0);
           
        }
        
}