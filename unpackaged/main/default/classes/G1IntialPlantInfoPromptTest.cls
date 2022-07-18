/**
**/
@istest
public with sharing class G1IntialPlantInfoPromptTest {
    @testSetup
    public static void testDataSetup() { 
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        
        Account acc = new account();
        acc.name ='Test';
        Insert acc;
        
        Account_Plant__c newPlantAssetParent = TestDataFactory.createPlantAsset(Constants.SOLAR,'Drive','7777.77.777',newTemVersion.Id);
        
        insert newPlantAssetParent;
        List<Account_Plant__c> plantAssetLst= new List<Account_Plant__c>();

        list<String> renewableType = new list<String>{Constants.SOLAR,Constants.WIND,Constants.SOLAR};
		
        List<Plant__c> plantLst= new List<Plant__c>();
        for(integer i = 0; i<3; i++){
            Plant__c plant = new Plant__c();
            plant.Name = 'Test Plant' ;    
            plant.Renewable_Type__c=renewableType[i];
            plant.Timezone__c= 'India Standard Time';
            plant.Latitude__c='45.5017';
            plant.Longitude__c='-75.123';
            plant.Commercial_Operating_Date__c = system.today();
            plantLst.add(plant);
        }
        insert plantLst;
        
        for(integer i = 0; i<3; i++){
            Account_Plant__c newPlantAsset = new Account_Plant__c();
            newPlantAsset.Plant__c = plantLst[i].id;
            newPlantAsset.Asset_Builder_Status__c = '';
            newPlantAsset.Drive_Id__c = '0000.000.00' + i;
            newPlantAsset.Drive_Id__c = '7777.77.777';
            newPlantAsset.TEM_Version__c = newTemVersion.Id;
            newPlantAsset.Project_Lifecycle_Status__c = 'Pending';
            newPlantAsset.Asset_Builder_Status__c = 'Completed';
//            newPlantAsset.Implementation_Status__c = 'In Progress';
            newPlantAsset.Account__c = acc.id;
            plantAssetLst.add(newPlantAsset);
        }
        insert plantAssetLst;
        Base_Asset_Template__c newBaseAssetTemplate = TestDataFactory.createBaseAssetTemplate(Constants.BASE_INVERTER, newTemVersion.Id);
        insert newBaseAssetTemplate;
        Prompt_Information__c previousPromptInfo = TestDataFactory.createPromptInformation(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        insert previousPromptInfo ; 
        Prompt_Information__c nextPromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                                                        newBaseAssetTemplate.Id, newTemVersion.Id);
        nextPromptInfo.Prompt_Id__c = 'prompt2';                                                                              
        insert nextPromptInfo;

        //update TemVersion status to Active
        newTemVersion.Status__c = 'Active';
        update newTemVersion;
    }
    public static testMethod void g1InitialPlantInfoTest(){
        Boolean fromPlaantAssetLsttrue = true;
        Account_Plant__c plantAssetLst = [SELECT Id, Name, Commercial_Operating_Date__c, Latitude__c, Longitude__c, PF_Service_Product__c,
              Status__c, Plant_Name__c, Drive_Id__c,Account__c,
               Renewable_Type__c, Timezone__c,  TEM_Version__c
                FROM Account_Plant__c ORDER BY Name ASC limit 1];
        string querPlantAsset = G1IntialPlantInfoPrompt.queryPlantAssetList(plantAssetLst.Id,fromPlaantAssetLsttrue);
        string plantassetId=plantAssetLst.id;
        string accountid= plantAssetLst.Account__c;
        string rType=plantAssetLst.Renewable_Type__c;
        string pfServiceProduct=plantAssetLst.PF_Service_Product__c;
        String plantAssetIdNull = '';
        string queryPlantAssetElse = G1IntialPlantInfoPrompt.queryPlantAssetList(plantAssetIdNull,fromPlaantAssetLsttrue);
        list<Account_Plant__c> queryPlantAssetAcc = G1IntialPlantInfoPrompt.queryPlantAssetListAcc(fromPlaantAssetLsttrue,accountid);
        map<String, String> jsonInputParametersAndValuesMap = new Map<String, String>{'isBulkUpload' => 'false', 'isBulkUploadMultipleBAT' => 'false'};
        map<String, String> additionalParamsMap = new Map<String, String>{'isReadOnly' => 'false', 'bifacialModules' => 'true'}; 
        map<String, String> bifacialValuesMap = new Map<String, String>{'bifacialModules' => 'true'};
        Boolean saveDataCheck = G1IntialPlantInfoPrompt.savePlantAsset(plantassetId,'2','3',rType,pfServiceProduct,JSON.serialize(bifacialValuesMap));
        
       // Decimal metMastCount = [SELECT Id, Name,Met_Mast__c FROM Account_Plant__c WHERE Id =: plantAssetLst.Id].Met_Mast__c;
       // System.assertEquals(1, metMastCount);

        String nextPromptResFinder = G1IntialPlantInfoPrompt.findNextPromptId(plantassetId,'2','3',rType,pfServiceProduct,JSON.serialize(additionalParamsMap),JSON.serialize(jsonInputParametersAndValuesMap));
        Map<String,String> nextPromptResponse = 
            (Map<String,String>) JSON.deserialize(nextPromptResFinder, Map<String,String>.class);
        String nextPromptId = (String)nextPromptResponse.get('nextPromptId');
        System.assertEquals(PromptNavigationHelper.findPromptId(Constants.P1_PLANT_INFO_PROMPT_SOLAR),nextPromptId);

        String promptResFinderError = G1IntialPlantInfoPrompt.findNextPromptId(plantassetId,'2','3',rType,pfServiceProduct,JSON.serialize(additionalParamsMap),JSON.serialize(jsonInputParametersAndValuesMap));
        Map<String,String> promptResponseError = 
            (Map<String,String>) JSON.deserialize(promptResFinderError, Map<String,String>.class);
        String nextPromptIdError = (String)promptResponseError.get('nextPromptId');
        string querySite = G1IntialPlantInfoPrompt.getSiteMetadata(plantassetId);
    }
}