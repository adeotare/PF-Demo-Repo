@isTest
private class LookupWithDynamicFieldFilterContTest {

    @testSetup 
    static void generatedata() {

        Pricebook2 pbId = TestDataFactory.createPriceBook();
        insert pbId ;
        
        Account acc = TestDataFactory.createAccount(pbId.Id);
        insert acc;

    }

    @isTest static void getLookupSearchRecordsTest() {
        Test.startTest();
        String searchString = 'estC';
        String selectedSObject = 'Account';
        Integer recordLimit = 10;
        List<String> fieldsToShowList = new List<String> {'CurrencyIsoCode', 'Name', 'Description'};
        String filterFieldAPIName = 'Name';
        List<Sobject> result = LookupWithDynamicFieldFilterCont.getLookupSearchRecords(searchString, selectedSObject, recordLimit,
      fieldsToShowList, filterFieldAPIName);
        System.debug('Mohit verification');
        Test.stopTest();
        System.assert(result.size()>0);
    }
}