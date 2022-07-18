/**
**/
@isTest
public class UpdaterfidetailTest {
      @testSetup static void  setup(){
         Product2 pr = TestDataFactory.createProductWithCode('DR-PR-PS-OT-IM-ST-ST-N/A');
        insert pr;
        Pricebook2 pb = TestDataFactory.createPriceBook();
        insert pb;
        Account accnt = TestDataFactory.createAccount(pb.Id);
        insert accnt;
          
        Contact c = TestDataFactory.createContact(accnt.id);
        insert c;
      
        system.debug('contact--->'+ c);
        
       Plant__c plant = new Plant__c();       
       plant.Renewable_Type__c = Constants.WIND;
       plant.Timezone__c = 'India Standard Time';
       plant.Latitude__c = '45.4543';
       plant.Longitude__c= '70.123';
       insert plant;
          
        Account_Plant__c palntAsset = new Account_Plant__c();
        palntAsset.plant__c = plant.id;       
        palntAsset.Project_Lifecycle_Status__c = 'Pending';        
        
        insert palntAsset;
        
        Account_Plant__c palntAsst = new Account_Plant__c();
        
        palntAsst.plant__c = plant.id;        
        palntAsst.Drive_Id__c = '123';        
        palntAsst.Account__c = accnt.Id;
        palntAsst.Assigned_Customer_Contact__c = c.Id;
        
        insert palntAsst;
          
        palntAsst.Project_Lifecycle_Status__c = 'Pending';
        
        Update palntAsst;
        
        RAID__c newrfi = new RAID__c();
        newrfi.Account_Plant__c = palntAsst.Id;
        newrfi.Priority__c= 'Low';
        newrfi.Status__c= 'In Progress';
        newrfi.Title__c = 'Test Controller';
        newrfi.Type__c = 'Process';
        insert newrfi;
        system.debug('--RFI RAID:-' +newrfi);
        
        RFI_Categories__c newRFICat = new RFI_Categories__c();
        newRFICat.Category_Classification__c = 'General';
        newRFICat.Name = 'Test missing';
        newRFICat.RecordTypeId = [SELECT id from RecordType where Name ='Missing/Incomplete Information'].Id;
        insert newRFICat;
        
        RFI_Categories__c newRFICat1 = new RFI_Categories__c();
        newRFICat1.Category_Classification__c = 'General';
        newRFICat1.Name = 'Test Incorrect';
        newRFICat1.RecordTypeId = [SELECT id from RecordType where Name ='Incorrect Information'].Id;
        insert newRFICat1;
        RFI_Categories__c newRFICat2 = new RFI_Categories__c();
        newRFICat2.Category_Classification__c = 'General';
        newRFICat2.Name = 'Test Incorrect 1';
        newRFICat2.RecordTypeId = [SELECT id from RecordType where Name ='Incorrect Information'].Id;
        insert newRFICat2;
          
        list<RFI_Detail__c> rfiitemlst = new list<RFI_Detail__c> ();  
		RFI_Detail__c newrfiItem = new RFI_Detail__c();
        newrfiItem.RFI_Item_Status__c = 'Requested';
        newrfiItem.RAID__c = newrfi.Id;
        newrfiItem.Missing_Incomplete_Category__c = newRFICat.id;
        newrfiItem.RFI_Category__c = newRFICat.id;
        newrfiItem.Implementation_Blocked__c = false;
        rfiitemlst.add(newrfiItem);
          
        RFI_Detail__c newrfiItem1 = new RFI_Detail__c();
        newrfiItem1.RFI_Item_Status__c = 'Needs Detail';
        newrfiItem1.RAID__c = newrfi.Id;
        newrfiItem1.Missing_Incomplete_Category__c = newRFICat1.id;
        newrfiItem1.RFI_Category__c = newRFICat1.id;
        newrfiItem1.Implementation_Blocked__c = false;
        rfiitemlst.add(newrfiItem1);
        RFI_Detail__c newrfiItem2 = new RFI_Detail__c();
        newrfiItem2.RFI_Item_Status__c = 'Requested';
        newrfiItem2.RAID__c = newrfi.Id;
        newrfiItem2.Missing_Incomplete_Category__c = newRFICat2.id;
        newrfiItem2.RFI_Category__c = newRFICat2.id;
        newrfiItem2.Implementation_Blocked__c = false;
        rfiitemlst.add(newrfiItem2);  
        insert rfiitemlst;  
    }
    @isTest static void testMethod2() {
        list<RFI_Detail__c> rfiitemlstupdate = new list<RFI_Detail__c> ();
        RFI_Detail__c updaterfiItem2 = [SELECT Id FROM RFI_Detail__c WHERE Name='Test Incorrect 1' LIMIT 1];
        updaterfiItem2.RFI_Item_Status__c = 'Canceled';
        updaterfiItem2.Cancel_Cannot_Complete_Description__c = 'test';
		updaterfiItem2.Implementation_Blocked__c = true;
        rfiitemlstupdate.add(updaterfiItem2);
        RFI_Detail__c updaterfiItem = [SELECT Id FROM RFI_Detail__c WHERE Name='Test Incorrect' LIMIT 1];
        updaterfiItem.RFI_Item_Status__c = 'Requested';
        updaterfiItem.Implementation_Blocked__c = false;
        rfiitemlstupdate.add(updaterfiItem);
        RFI_Detail__c updaterfiItem1 = [SELECT Id FROM RFI_Detail__c WHERE Name='Test missing' LIMIT 1];
        updaterfiItem1.RFI_Item_Status__c = 'In Progress';
        updaterfiItem1.Implementation_Blocked__c = false;
        rfiitemlstupdate.add(updaterfiItem1);
        Test.startTest();
        update rfiitemlstupdate;
        Test.stopTest();
    }
}