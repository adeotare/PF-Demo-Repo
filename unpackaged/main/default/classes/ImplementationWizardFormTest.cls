@IsTest
private class ImplementationWizardFormTest {
/*    @TestSetup
    static void setupData(){
        Implementation_Wizard_Form_Detail__c impWiz = new Implementation_Wizard_Form_Detail__c(
            Data_Interface__c = 'API',
            API_Type__c = 'AlsoEnergy',
            Plant_API_Id__c = '123'
        );
        insert impWiz;

        String title = 'PiBuilder-New-1';
        String extension = 'xlsx';
        String fileContent = 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxMaWdodG5pbmdDb21wb25lbnRCdW5kbGUgeG1sbnM9Imh0dHA6Ly9zb2FwLnNmb3JjZS5jb20vMjAwNi8wNC9tZXRhZGF0YSI+DQogICAgPGFwaVZlcnNpb24+NDguMDwvYXBpVmVyc2lvbj4NCiAgICA8aXNFeHBvc2VkPmZhbHNlPC9pc0V4cG9zZWQ+DQo8L0xpZ2h0bmluZ0NvbXBvbmVudEJ1bmRsZT4='; 
        
        ContentVersion cv = new ContentVersion();
        cv.Title = title;
        cv.PathOnClient = title + '.' +extension;
        cv.VersionData = EncodingUtil.base64Decode(fileContent);
        cv.IsMajorVersion = true;
        Insert cv;

        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = impWiz.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        Insert cdl;

        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        Plant_Asset__c newPlantAsset = TestDataFactory.createPlantAsset('Solar - PV', 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;
    }

    @IsTest
    static void testCalloutSuccessMethod(){
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        String bodyContent = '{"status":"success","details":{"fileContent":"PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxMaWdodG5pbmdDb21wb25lbnRCdW5kbGUgeG1sbnM9Imh0dHA6Ly9zb2FwLnNmb3JjZS5jb20vMjAwNi8wNC9tZXRhZGF0YSI+DQogICAgPGFwaVZlcnNpb24+NDguMDwvYXBpVmVyc2lvbj4NCiAgICA8aXNFeHBvc2VkPmZhbHNlPC9pc0V4cG9zZWQ+DQo8L0xpZ2h0bmluZ0NvbXBvbmVudEJ1bmRsZT4="}}';
        Test.setMock(HttpCalloutMock.class, new ImplementationWizardFormMock(bodyContent, 200));
        Plant_Asset__c newPlantAsset = [SELECT Id From Plant_Asset__c LIMIT 1];

        Test.startTest();
        ImplementationWizardForm.queryInformation();

        Map<String, String> requestParametersMap = new Map<String, String>{
            'controllingPicklistValue' => 'API',
            'dependentPicklistValue' => 'AlsoEnergy',
            'plantIdPf' => '123',
            'plantIdApi' => '154',
            'plantAssetId' => String.valueOf(newPlantAsset.Id)
        };

        String jsonStr = JSON.serialize(requestParametersMap);
        ImplementationWizardForm.sendRequest(jsonStr);
        Test.stopTest();
    }

    @IsTest
    static void testCalloutErrorMethod(){
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        String bodyContent = '{"status": "error","details": {"code": "TenantNotFound","devMessage": "","userMessage": "Unable to retrieve tenant for customer name : 1452"}}';
        Test.setMock(HttpCalloutMock.class, new ImplementationWizardFormMock(bodyContent, 200));
        Plant_Asset__c newPlantAsset = [SELECT Id From Plant_Asset__c LIMIT 1];

        Test.startTest();
        ImplementationWizardForm.queryInformation();

        Map<String, String> requestParametersMap = new Map<String, String>{
            'controllingPicklistValue' => 'API',
            'dependentPicklistValue' => 'AlsoEnergy',
            'plantIdPf' => '123',
            'plantIdApi' => '154',
            'plantAssetId' => String.valueOf(newPlantAsset.Id)
        };

        String jsonStr = JSON.serialize(requestParametersMap);
        ImplementationWizardForm.sendRequest(jsonStr);
        Test.stopTest();
    }
    
    @IsTest
    static void testCalloutError500Method(){
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        String bodyContent = '{"code": "TenantNotFound","devMessage": "","userMessage": "Unable to retrieve tenant for customer name : 1452"}';
        Test.setMock(HttpCalloutMock.class, new ImplementationWizardFormMock(bodyContent, 500));
        Plant_Asset__c newPlantAsset = [SELECT Id From Plant_Asset__c LIMIT 1];

        Test.startTest();
        ImplementationWizardForm.queryInformation();

        Map<String, String> requestParametersMap = new Map<String, String>{
            'controllingPicklistValue' => 'API',
            'dependentPicklistValue' => 'AlsoEnergy',
            'plantIdPf' => '123',
            'plantIdApi' => '154',
            'plantAssetId' => String.valueOf(newPlantAsset.Id)
        };

        String jsonStr = JSON.serialize(requestParametersMap);
        ImplementationWizardForm.sendRequest(jsonStr);
        Test.stopTest();
    }
    
    @IsTest
    static void testCalloutError601Method(){
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        String bodyContent = '{"code": "TenantNotFound","devMessage": "","userMessage": "Unable to retrieve tenant for customer name : 1452"}';
        Test.setMock(HttpCalloutMock.class, new ImplementationWizardFormMock(bodyContent, 601));
        Plant_Asset__c newPlantAsset = [SELECT Id From Plant_Asset__c LIMIT 1];

        Test.startTest();
        ImplementationWizardForm.queryInformation();

        Map<String, String> requestParametersMap = new Map<String, String>{
            'controllingPicklistValue' => 'API',
            'dependentPicklistValue' => 'AlsoEnergy',
            'plantIdPf' => '123',
            'plantIdApi' => '154',
            'plantAssetId' => String.valueOf(newPlantAsset.Id)
        };

        String jsonStr = JSON.serialize(requestParametersMap);
        ImplementationWizardForm.sendRequest(jsonStr);
        Test.stopTest();
    }
    
    @IsTest
    static void fileUploadCheck(){
        Implementation_Wizard_Form_Detail__c impwFormDetail = [SELECT Id, API_Type__c, Plant_API_Id__c FROM Implementation_Wizard_Form_Detail__c
                                                              WHERE Plant_API_Id__c = '123'];
    	ImplementationWizardForm.fileUpload('csvToShow', impwFormDetail.Id, 'testName');    
    }
    
    @IsTest
    static void createImpWizFormDetailCheck(){
        Plant_Asset__c newPlantAsset = [SELECT Id From Plant_Asset__c LIMIT 1];
        Map<String,String> jsonInputParametersAndValuesMap = new Map<String, String>();
        jsonInputParametersAndValuesMap.put('plantAssetId', String.valueOf(newPlantAsset.Id));
        jsonInputParametersAndValuesMap.put('plantIdPf', '123');
        ImplementationWizardForm.createImpWizFormDetail(JSON.serialize(jsonInputParametersAndValuesMap));
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;
        Plant_Asset__c newPlantAssetCustomer = TestDataFactory.createPlantAsset('Solar - PV', 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAssetCustomer;
        ImplementationWizardForm.plantAssetStatus(newPlantAssetCustomer.Id);
        ImplementationWizardForm.plantAssetStatus(newPlantAsset.Id);
    }*/
}