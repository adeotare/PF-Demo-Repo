/**
 * 
 */
@IsTest
public class AssetBuilderLocationAPITest {
/*
    @IsTest
    static void testCalloutSuccessMethod() {

        Id customerPlantAssetRT = Utils.getRecordTypeInfo('Account_Plant__c', 'Child_Asset').getRecordTypeId();

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Account_Plant__c pa = new Account_Plant__c();
        pa.Name = 'Plant Asset Test1';
        pa.RecordTypeId = [SELECT id from RecordType where Name = 'Parent Asset'].Id;
//        pa.Plant_Name__c = 'test1';
//        pa.Renewable_Type__c = Constants.WIND;
        pa.Project_Lifecycle_Status__c = 'Pending';
//        pa.Implementation_Status__c = 'Pending Customer Submission';
//        pa.Latitude__c = '45.5017';
//       pa.Longitude__c = '-73.5673';
        pa.Account__c = account.Id;
        insert pa;

        Account_Plant__c plantAsset = new Account_Plant__c();
//        plantAsset.Name = 'Test Plant';
//        plantAsset.Renewable_Type__c = 'Solar - PV';
        plantAsset.PF_Service_Product__c = 'Drive';
        plantAsset.Customer_Plant_Asset_ID__c = '7777.77.777';
        plantAsset.TEM_Version__c = newTemVersion.id;
        plantAsset.RecordTypeId = customerPlantAssetRT;
//        plantAsset.Parent__c = pa.Id;
//        plantAsset.Latitude__c = '45.5017';
//        plantAsset.Longitude__c = '-73.5673';
        plantAsset.Account__c = account.Id;

        insert plantAsset;

        String bodyContent = '{"LOCATION_ELEVATION":"28.48959","LOCATION_COUNTRY":"CA","LOCATION_STATE":"QC","LOCATION_TIMEZONE":"Eastern Standard Time"}';
//        Test.setMock(HttpCalloutMock.class, new ImplementationWizardFormMock(bodyContent, 200));

        Test.startTest();

        Plant_Asset_Prompt_Detail__c plantAssetPD = new Plant_Asset_Prompt_Detail__c();
        AssetBuilderLocationAPI.callLocationAPI(plantAsset.Id,plantAssetPD,false, true);

        Test.stopTest();
    }

    @IsTest
    static void testCalloutErrorMethod() {
        Id customerPlantAssetRT = Utils.getRecordTypeInfo('Account_Plant__c', 'Child_Asset').getRecordTypeId();

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Account_Plant__c pa = new Account_Plant__c();
        pa.Name = 'Plant Asset Test1';
        pa.RecordTypeId = [SELECT id from RecordType where Name = 'Parent Asset'].Id;
        pa.Plant_Name__c = 'test1';
        pa.Renewable_Type__c = Constants.WIND;
        pa.Project_Lifecycle_Status__c = 'Pending';
//        pa.Implementation_Status__c = 'Pending Customer Submission';
        pa.Latitude__c = '45.5017';
        pa.Longitude__c = '-73.5673';
        pa.Account__c = account.Id;
        insert pa;

        Account_Plant__c plantAsset = new Account_Plant__c();
        plantAsset.Name = 'Test Plant';
        plantAsset.Renewable_Type__c = 'Solar - PV';
        plantAsset.PF_Service_Product__c = 'Drive';
        plantAsset.Customer_Plant_Asset_ID__c = '7777.77.777';
        plantAsset.TEM_Version__c = newTemVersion.id;
        plantAsset.RecordTypeId = customerPlantAssetRT;
        plantAsset.Parent__c = pa.Id;
        plantAsset.Latitude__c = '45.5017';
        plantAsset.Longitude__c = '-73.5673';
        plantAsset.Account__c = account.Id;

        insert plantAsset;

        String bodyContent = '{"LOCATION_ELEVATION":"28.48959","LOCATION_COUNTRY":"CA","LOCATION_STATE":"QC","LOCATION_TIMEZONE":"Eastern Standard Time"}';
        Test.setMock(HttpCalloutMock.class, new ImplementationWizardFormMock(bodyContent, 500));

        Test.startTest();
        Plant_Asset_Prompt_Detail__c plantAssetPD = new Plant_Asset_Prompt_Detail__c();
        AssetBuilderLocationAPI.callLocationAPI(plantAsset.Id,plantAssetPD,false, true);
        Test.stopTest();
    }

    @IsTest
    static void testCalloutExceptionMethod() {
        Id customerPlantAssetRT = Utils.getRecordTypeInfo('Account_Plant__c', 'Child_Asset').getRecordTypeId();

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Account_Plant__c pa = new Account_Plant__c();
        pa.Name = 'Plant Asset Test1';
        pa.RecordTypeId = [SELECT id from RecordType where Name = 'Parent Asset'].Id;
        pa.Plant_Name__c = 'test1';
        pa.Renewable_Type__c = Constants.WIND;
        pa.Project_Lifecycle_Status__c = 'Pending';
//        pa.Implementation_Status__c = 'Pending Customer Submission';
        pa.Latitude__c = '45.5017';
        pa.Longitude__c = '-73.5673';
        pa.Account__c = account.Id;
        insert pa;

        Account_Plant__c plantAsset = new Account_Plant__c();
        plantAsset.Name = 'Test Plant';
        plantAsset.Renewable_Type__c = 'Solar - PV';
        plantAsset.PF_Service_Product__c = 'Drive';
        plantAsset.Customer_Plant_Asset_ID__c = '7777.77.777';
        plantAsset.TEM_Version__c = newTemVersion.id;
        plantAsset.RecordTypeId = customerPlantAssetRT;
        plantAsset.Parent__c = pa.Id;
        plantAsset.Latitude__c = '45.5017';
        plantAsset.Longitude__c = '-73.5673';
        plantAsset.Account__c = account.Id;

        insert plantAsset;

        Test.startTest();
        Plant_Asset_Prompt_Detail__c plantAssetPD = new Plant_Asset_Prompt_Detail__c();
        AssetBuilderLocationAPI.callLocationAPI(plantAsset.Id,plantAssetPD,false, true);
        Test.stopTest();
    }

    @IsTest
    static void testLWCMethod() {
        Id customerPlantAssetRT = Utils.getRecordTypeInfo('Account_Plant__c', 'Child_Asset').getRecordTypeId();

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Account_Plant__c pa = new Account_Plant__c();
        pa.Name = 'Plant Asset Test1';
        pa.RecordTypeId = [SELECT id from RecordType where Name = 'Parent Asset'].Id;
        pa.Plant_Name__c = 'test1';
        pa.Renewable_Type__c = Constants.WIND;
        pa.Project_Lifecycle_Status__c = 'Pending';
//        pa.Implementation_Status__c = 'Pending Customer Submission';
        pa.Latitude__c = '45.5017';
        pa.Longitude__c = '-73.5673';
        pa.Account__c = account.Id;
        insert pa;

        Account_Plant__c plantAsset = new Account_Plant__c();
        plantAsset.Name = 'Test Plant';
        plantAsset.Renewable_Type__c = 'Solar - PV';
        plantAsset.PF_Service_Product__c = 'Drive';
        plantAsset.Customer_Plant_Asset_ID__c = '7777.77.777';
        plantAsset.TEM_Version__c = newTemVersion.id;
        plantAsset.RecordTypeId = customerPlantAssetRT;
        plantAsset.Parent__c = pa.Id;
        plantAsset.Latitude__c = '45.5017';
        plantAsset.Longitude__c = '-73.5673';
        plantAsset.Account__c = account.Id;

        insert plantAsset;

        Test.startTest();
        AssetBuilderLocationAPI.callLocationAPIfromLWC(plantAsset.Id, true);
        Test.stopTest();
    }*/
}