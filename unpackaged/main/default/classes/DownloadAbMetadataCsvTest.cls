/**
**/
@isTest
public class DownloadAbMetadataCsvTest {
     @testSetup static void methodName() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        
        Plant__c plant = new Plant__c();
        plant.Name = 'Asset Builder Plant' ;    
        plant.Renewable_Type__c=Constants.WIND;
        plant.Timezone__c= 'India Standard Time';
        plant.Latitude__c='45.5017';
        plant.Longitude__c='-75.123';
        insert plant;
        
        Account_Plant__c plantAsset = new Account_Plant__c();
        plantAsset.Customer_Plant_Name__c = 'Customer Plant Asset';
        plantAsset.PF_Service_Product__c = Constants.DRIVE_PRO;
        plantAsset.Drive_Id__c  = '21.21.21.1';
        plantAsset.TEM_Version__c = newTemVersion.id;
        plantAsset.Project_Lifecycle_Status__c = 'Pending';
        plantAsset.Plant__c = plant.id;
        insert plantAsset;
        
        Account_Plant__c newPlantAsset1 = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','21.21.21',newTemVersion.Id);
        newPlantAsset1.Project_Lifecycle_Status__c = 'Pending';
        
        insert newPlantAsset1;
        plantAsset.Plant__c = plant.id;
        update plantAsset;
    }
    

     
}