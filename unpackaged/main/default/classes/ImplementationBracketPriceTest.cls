@isTest
private class ImplementationBracketPriceTest{

    @testSetup 
    static void generatedata() {

        Pricebook2 pbId = TestDataFactory.createPriceBook();
        insert pbId ;
        
        Account acc = TestDataFactory.createAccount(pbId.Id);
        insert acc;
        
        MSA_Contract__c msa = TestDataFactory.createMsa(acc.Id);                             
        insert msa;
        
        Product2 product = TestDataFactory.createProductAgain();
        insert product;

        MSA_Implementation_Bracket_Price__c implPrice = TestDataFactory.createImplementationBracketTier(acc.Id, product.Id, msa.Id);
        insert implPrice;
    
        User user = TestDataFactory.createNewUser();
        insert user;
        
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

        @isTest static void deleteImplementationPriceRecordTestCatchException() {
            User testUser = [SELECT Id FROM User WHERE alias = 'testmark'];
            List<MSA_Contract__c> msaId = [Select Id from MSA_Contract__c where Account_Name__r.Name = 'TestCP' LIMIT 1];
            Id msa = string.valueOf(msaId[0].Id);
            System.debug('MSA Id : ' + msa);
            List<MSA_Implementation_Bracket_Price__c> implementList = ImplementationBracketPrice.implementationBracketPriceRecords(msa);
            Test.startTest();
            System.runAs(testUser){   
            try {        
                ImplementationBracketPrice.deleteImplementationPriceRecord(implementList,msa);
                //System.debug('Message : '+ msg);
            }
            catch(DmlException ex) {
                System.debug('Error Message is : '+ ex.getMessage());
            }
            Test.stopTest();
            }
            //System.assertEquals('Success: Contracted Prices updated successfully', msg);

        }        

}