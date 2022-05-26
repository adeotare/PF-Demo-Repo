/**
 * Created by karthikeyan.k on 6/23/2021.
 */

public with sharing class SendNeuronTemplateDetail {

    @AuraEnabled
    public static Map<String, Object> callNeuronAPI(String requestParameters, String assetModelBase64, String templatesBase64){

        String plantAssetId;
        String customerPlantAssetID;
        String jsonStream;
        Map<String, Object> outputJSON = new Map<String, Object>();

        Map<String, String> requestParametersMap = (Map<String, String>) json.deserialize(requestParameters, Map<String, String>.class);

        plantAssetId = requestParametersMap.get('plantAssetId');
        customerPlantAssetID = [SELECT Customer_Plant_Asset_ID__c FROM Account_Plant__c WHERE id =: plantAssetId].Customer_Plant_Asset_ID__c;
        //String restURI = 'callout:ImpWizFormAPIDetails/apitype/AQS/assetbuilder?elementPath={0}';
        String restURI = 'callout:NeuronTemplateAPIDetail?elementPath={0}';

        restURI = String.format(restURI, new String[]{customerPlantAssetID});
        
        String requestBody = '{'+
                '"assetModelBase64": "'+assetModelBase64+'",'+ // assetModelBase64
                '"templatesBase64": "'+templatesBase64+'"'+'}'; // templatesBase64

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(restURI);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Ocp-Apim-Trace', 'true');
        request.setHeader('Ocp-Apim-Subscription-Key', '{!$Credential.Password}');
        request.setBody(requestBody);
        request.setTimeout(120000);
        HttpResponse response = http.send(request);
        jsonStream = response.getBody();
        outputJSON = parseResponse(jsonStream, requestParametersMap);
        return outputJSON;
    }

    public static Map<String, Object> parseResponse(String jsonStream, Map<String, String> requestParametersMap){
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonStream);
        Map<String, Object> outputJSON = new Map<String, Object>();

        String resStatus = '';
        if(jsonMap.containsKey('status')){
            resStatus = ((String)jsonMap.get('status')).toLowercase();
        }

        outputJSON.put('status', resStatus );

        if(jsonMap.containsKey('details')){
            if(resStatus == 'success'){
                Map<String, Object> jsonMapSuccess = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(jsonMap.get('details')));
                String fileContent = (String)jsonMapSuccess.get('fileContent');
                String fileName = (String)jsonMapSuccess.get('fileName');
                String fileExtension = (String)jsonMapSuccess.get('fileExtension');
                String impWizStatus = createImpWizFormDetails(resStatus, '', requestParametersMap, jsonStream);

                if(impWizStatus.length() == 18){
                    ContentDocumentLink cdl = createContentVersion(fileContent, fileName, fileExtension, impWizStatus, requestParametersMap);
                    outputJSON.put('cdID', cdl.ContentDocumentId );
                    outputJSON.put('status', 'success');
                    outputJSON.put('impWizStatus', impWizStatus);
                }else{
                    outputJSON.put('status', 'error');
                    outputJSON.put('errorMessage',System.Label.ImplementationWizFormDetailNotCreated);
                }
            }else if(resStatus == 'error'){
                Map<String, Object> jsonMapError = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(jsonMap.get('details')));
                String code = (String)jsonMapError.get('code');
                String userMessage = (String)jsonMapError.get('userMessage');
                String devMessage = (String)jsonMapError.get('devMessage');

                String resMes = code + ' \n ';
                resMes += (userMessage != null && userMessage != '') ? userMessage + ' \n ' : '';
                resMes += (devMessage != null && devMessage != '') ? devMessage : '';

                String impWizStatus = createImpWizFormDetails(resStatus, resMes, requestParametersMap, jsonStream);
                outputJSON.put('errorMessage', userMessage );
            }
        } else if(jsonMap.containsKey('errors')) {

            outputJSON.put('status', 'error');
            outputJSON.put('errorMessage', 'The input is not valid' );
        }

        return outputJSON;
    }

    public static String createImpWizFormDetails(String Status, String resMessage, Map<String, String> requestParametersMap, String jsonStream){
        try{
            String plantAssetId;

            plantAssetId = requestParametersMap.get('plantAssetId');

            List<Account_Plant__c> plantAsset = [SELECT Id FROM Account_Plant__c WHERE Id =: plantAssetId];

            Implementation_Wizard_Form_Detail__c impWiz = new Implementation_Wizard_Form_Detail__c(
                    Account_Plant__c = (plantAsset.size() > 0) ? plantAsset[0].Id : null,
                    Status__c = Status,
                    Response_Message__c = (Status == 'success') ? '' : resMessage,
                    Is_Created_in_Neuron_Update__c = true
            );

            insert impWiz;
            return String.valueof(impWiz.Id);

        }catch(exception exceptionDetails){
            String errorMessage = ' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber();
            System.debug(errorMessage);
            throw new AuraHandledException(errorMessage);
        }
    }

    public static ContentDocumentLink createContentVersion(String fileContent, String fileName, String fileExtension,
            String impWizRecId, Map<String, String> requestParametersMap){

        try{
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName + '.' +fileExtension;
            cv.VersionData = EncodingUtil.base64Decode(fileContent);
            cv.IsMajorVersion = true;
            Insert cv;

            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = impWizRecId;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            Insert cdl;

            return cdl;
        }catch(Exception exceptionDetails){
            String errorMessage = ' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber();
            System.debug(errorMessage);
            throw new AuraHandledException(errorMessage);
        }
    }
}