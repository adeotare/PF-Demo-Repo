/**
 * Created by karthikeyan.k on 6/28/2021.
 */

@IsTest
private class SendNeuronTemplateDetailTest {
    @TestSetup
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
        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset('Solar - PV', 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;
    }

    @IsTest
    static void testCalloutSuccessMethod(){
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        String bodyContent = '{"status":"success","details":{"fileContent":"PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4NCjxMaWdodG5pbmdDb21wb25lbnRCdW5kbGUgeG1sbnM9Imh0dHA6Ly9zb2FwLnNmb3JjZS5jb20vMjAwNi8wNC9tZXRhZGF0YSI+DQogICAgPGFwaVZlcnNpb24+NDguMDwvYXBpVmVyc2lvbj4NCiAgICA8aXNFeHBvc2VkPmZhbHNlPC9pc0V4cG9zZWQ+DQo8L0xpZ2h0bmluZ0NvbXBvbmVudEJ1bmRsZT4="}}';
        Test.setMock(HttpCalloutMock.class, new ImplementationWizardFormMock(bodyContent, 200));
        Account_Plant__c newPlantAsset = [SELECT Id From Account_Plant__c LIMIT 1];

        Test.startTest();
        ImplementationWizardForm.queryInformation();

        Map<String, String> requestParametersMap = new Map<String, String>{
                'plantAssetId' => String.valueOf(newPlantAsset.Id)
        };

        String requestParameters = '{"plantAssetId":"'+newPlantAsset.Id+'"}';

        String templateFile = 'templateFile';
        String piTemplateFile = 'piTemplateFile';
        SendNeuronTemplateDetail.callNeuronAPI(requestParameters, templateFile, piTemplateFile);
        Test.stopTest();
    }

    @IsTest
    static void testCalloutErrorMethod(){
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        String bodyContent = '{"status": "error","details": {"code": "TenantNotFound","devMessage": "","userMessage": "Unable to retrieve tenant for customer name : 1452"}}';
        Test.setMock(HttpCalloutMock.class, new ImplementationWizardFormMock(bodyContent, 200));
        Account_Plant__c newPlantAsset = [SELECT Id From Account_Plant__c LIMIT 1];

        Test.startTest();
        ImplementationWizardForm.queryInformation();

        Map<String, String> requestParametersMap = new Map<String, String>{
                'plantAssetId' => String.valueOf(newPlantAsset.Id)
        };

        String requestParameters = '{"plantAssetId":"'+newPlantAsset.Id+'"}';

        String templateFile = 'templateFile';
        String piTemplateFile = 'piTemplateFile';
        SendNeuronTemplateDetail.callNeuronAPI(requestParameters, templateFile, piTemplateFile);
        Test.stopTest();
    }
}