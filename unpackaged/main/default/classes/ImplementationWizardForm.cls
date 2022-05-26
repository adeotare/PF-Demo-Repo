public with sharing class ImplementationWizardForm {
    
    @AuraEnabled
    public static string queryInformation(){
        Map<String, Object> outputMap = new  Map<String, Object>();

        try {
            List<APITypeAndFileFormatMapping__mdt> apiTypeAndFileFormatLst = new List<APITypeAndFileFormatMapping__mdt>();
            apiTypeAndFileFormatLst = [SELECT Id, File_Format__c, DeveloperName FROM APITypeAndFileFormatMapping__mdt];
            outputMap.put('apiTypeAndFileFormat', apiTypeAndFileFormatLst);

            List<Implementation_Wizard_Form_Detail__c> impWizDetails = new List<Implementation_Wizard_Form_Detail__c>();
            List<Id> impWizDetailsId = new List<Id>();

            for(Implementation_Wizard_Form_Detail__c imp : [SELECT Id, API_Type__c, Data_Interface__c, Plant_API_Id__c, Function_To_On_Screen__c,
            Account_Plant__c, Name, CreatedById, CreatedDate, Status__c, Response_Message__c, Plant_Id_PF_Text__c, Is_Created_in_CSV_Conversion__c 
                        FROM Implementation_Wizard_Form_Detail__c 
                        WHERE CreatedDate = LAST_90_DAYS
                        ORDER BY CreatedDate DESC]){
                impWizDetails.add(imp);
                impWizDetailsId.add(imp.Id);
            }
            outputMap.put('impWizDetailsList', impWizDetails);
            List<ContentDocumentLink> contentDocumentList = new List<ContentDocumentLink>();

            if(impWizDetailsId.size() > 0){
                /*contentDocumentList = [SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title,
                                                            ContentDocument.FileType 
                                                        FROM   ContentDocumentLink 
                                                        WHERE  LinkedEntityId IN: impWizDetailsId 
                                                        AND ContentDocument.FileType = 'EXCEL_X' 
                                                        ORDER BY SystemModstamp DESC];*/

                Map<Id, ContentDocumentLink> contentDocIdToCDLMap= new Map<Id, ContentDocumentLink>();

                for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title, 
                    ContentDocument.FileType FROM ContentDocumentLink WHERE 
                    LinkedEntityId IN: impWizDetailsId 
                    AND ContentDocument.FileType = 'EXCEL_X'
                    ORDER BY SystemModstamp DESC]){
                        contentDocIdToCDLMap.put(cdl.ContentDocumentId, cdl);
                }

                for(ContentVersion cv : [SELECT Imp_Wiz_CSV_Files__c, ContentDocumentId FROM ContentVersion 
                    WHERE (ContentDocumentId IN: contentDocIdToCDLMap.keySet()) and Imp_Wiz_CSV_Files__c = FALSE]){
                    if(contentDocIdToCDLMap.containsKey(cv.ContentDocumentId)){
                        contentDocumentList.add(contentDocIdToCDLMap.get(cv.ContentDocumentId));
                    }
                }
            }

            outputMap.put('contentDocLink', contentDocumentList);
            String sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
            String userType = UserInfo.getUserType();
            
            outputMap.put('baseURL', sfdcBaseURL);
            outputMap.put('userType', userType);
            outputMap.put('isSandbox', ([SELECT Id, OrganizationType, IsSandbox FROM Organization LIMIT 1].IsSandbox) ? 'true' : 'false');

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return JSON.serialize(outputMap);
    }

    @AuraEnabled
    public static String sendRequest(String requestParameters){
        Map<String, Object> outputJSON = new Map<String, Object>();

        Map<String, String> requestParametersMap = (Map<String, String>)JSON.deserialize(requestParameters, Map<String, String>.class);

        String jsonStream = '';
        HttpResponse response;

        if(requestParametersMap.get('controllingPicklistValue') == 'Datalogger'){
            response = callPFAPI(requestParametersMap);
            outputJSON = workWithAPIResponse(response, requestParametersMap);
        }else if(requestParametersMap.get('controllingPicklistValue') == 'API'){
            response = callPFAPI(requestParametersMap);
            outputJSON = workWithAPIResponse(response, requestParametersMap);
        }

        return JSON.serialize(outputJSON);
    }

    public static Map<String, Object> workWithAPIResponse(HttpResponse response, Map<String, String> requestParametersMap){
        String jsonStream;
        Map<String, Object> outputJSON = new Map<String, Object>();

        if(response.getStatusCode() == 200){
            jsonStream = response.getBody();
            outputJSON = parseResponse(jsonStream, requestParametersMap);
        }else if(response.getStatusCode() == 500){
            jsonStream = response.getBody();
            JSONParser parser = JSON.createParser(jsonStream);
            String errorMessage = null;
            String errorMessageToSaveInRecord = null;

            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                    (parser.getText() == 'userMessage')) {
                    parser.nextToken();
                    errorMessage = parser.getText();
                }
            }

            if(errorMessage.contains('NotFound')){
                errorMessage = Label.EnterValidPlantAPIId;
            }   

            errorMessage = (errorMessage != null) ? errorMessage : response.getStatus() + ' ' + Label.ErrorInImpWizAPIRequest; 
            errorMessageToSaveInRecord = (errorMessage != null) ? jsonStream : response.getStatus();

            outputJSON.put('status', 'error');
            outputJSON.put('errorMesage', errorMessage);
            String impWizStatus = createAPIFormDetails('error', errorMessageToSaveInRecord, requestParametersMap, jsonStream);
        }else{
            String impWizStatus = createAPIFormDetails('error', response.getStatus(), requestParametersMap, jsonStream);
            outputJSON.put('status', 'error');
            outputJSON.put('errorMesage', response.getStatus() + ' ' + Label.ErrorInImpWizAPIRequest);
        }

        return outputJSON;
    }

    public static HttpResponse callPFAPI(Map<String, String> requestParametersMap){
        try{
            String restURI = 'callout:ImpWizFormAPIDetails/apitype/{0}?plantApiId={1}&elementPath={2}&startTimeUtc={3}&endTimeUtc={4}&runPreSAT={5}';
            String apiType, plantIdApi, plantAssetId, plantIdPf, fromDate, toDate, runPreSAT;

            if(requestParametersMap.containsKey('plantIdApi') && 
                requestParametersMap.containsKey('plantAssetId') &&
                requestParametersMap.containsKey('dependentPicklistValue')){
                    apiType = requestParametersMap.get('dependentPicklistValue');
                    plantIdApi = requestParametersMap.get('plantIdApi');
                    plantAssetId = requestParametersMap.get('plantAssetId'); 
                    plantIdPf = requestParametersMap.get('plantIdPf');
                    // To run Pre-SAT validation
                    runPreSAT = requestParametersMap.get('runPreSAT');
                    fromDate = requestParametersMap.get('fromDate');
                    toDate = requestParametersMap.get('toDate');
            }

            restURI = String.format(restURI, new String[]{apiType, plantIdApi, plantIdPf, fromDate, toDate, runPreSAT});

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(restURI);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json; charset=UTF-8');
            request.setHeader('Ocp-Apim-Subscription-Key', '{!$Credential.Password}');

            if(requestParametersMap.get('controllingPicklistValue') == 'API'){
                request.setBody('""');
            }else if(requestParametersMap.get('controllingPicklistValue') == 'Datalogger'){
                String fileContent = requestParametersMap.get('fileContentBlob');
                request.setBody('"'+fileContent+'"'); //
            }

            request.setTimeout(120000);
            HttpResponse response = http.send(request);
            return response;

        }catch(Exception exceptionDetails){
            String errorMessage = ' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber();
            System.debug(errorMessage);
            throw new AuraHandledException(errorMessage);
        }
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
                String impWizStatus = createAPIFormDetails(resStatus, '', requestParametersMap, jsonStream);

                if(impWizStatus.length() == 18){
                    ContentDocumentLink cdl = createContentVersion(fileContent, fileName, fileExtension, impWizStatus, requestParametersMap);
                    outputJSON.put('cdl', cdl );
                    outputJSON.put('impWizStatus', impWizStatus); 
                }else{
                    outputJSON.put('status', 'error');
                    outputJSON.put('errorMesage', Label.ErrorInAPIFormRecordCreation);
                }
            }else if(resStatus == 'error'){
                Map<String, Object> jsonMapError = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(jsonMap.get('details')));
                String code = (String)jsonMapError.get('code');
                String userMessage = (String)jsonMapError.get('userMessage');
                String devMessage = (String)jsonMapError.get('devMessage');

                String resMes = code + ' \n ';
                resMes += (userMessage != null && userMessage != '') ? userMessage + ' \n ' : '';
                resMes += (devMessage != null && devMessage != '') ? devMessage : '';
                
                String impWizStatus = createAPIFormDetails(resStatus, resMes, requestParametersMap, jsonStream);
                if(code.contains('CustomerConfigNotFound')){
                    userMessage = Label.PlantIdPFNotFound;
                }
                outputJSON.put('errorMesage', userMessage );
            }
        }

        return outputJSON;
    }

    public static String createAPIFormDetails(String Status, String resMessage, Map<String, String> requestParametersMap, String jsonStream){
        try{
            String apiType, plantIdApi, plantAssetId, dataInterface, plantIdPf;

            dataInterface = requestParametersMap.get('controllingPicklistValue');
            apiType = requestParametersMap.get('dependentPicklistValue');
            plantIdApi = requestParametersMap.get('plantIdApi');
            plantAssetId = requestParametersMap.get('plantAssetId');
            plantIdPf = requestParametersMap.get('plantIdPf');

            List<Account_Plant__c> plantAsset = [SELECT Id FROM Account_Plant__c WHERE Id =: plantAssetId];
            
            Implementation_Wizard_Form_Detail__c impWiz = new Implementation_Wizard_Form_Detail__c(
                API_Type__c = apiType,
                Data_Interface__c = dataInterface,
                Plant_API_Id__c = plantIdApi,
                Account_Plant__c = (plantAsset.size() > 0) ? plantAsset[0].Id : null,
                Status__c = Status,
                Response_Message__c = (Status == 'success') ? '' : resMessage,
                Plant_Id_PF_Text__c = plantIdPf
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

    @AuraEnabled
    public static String getContentVersion(String contentDocumnetLink){
        list<ContentDocumentLink> ContentDocumentLinkLst = [SELECT Id, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.Title 
                                                                FROM ContentDocumentLink WHERE Id =: contentDocumnetLink];
    
        Blob xlsxFileBody =ContentDocumentLinkLst[0].ContentDocument.LatestPublishedVersion.VersionData;
        String xlsxAsString= Utils.blobToString( xlsxFileBody,'ISO-8859-1');
        map<String, Object> contentVersionMap = new Map<String, Object>();
        contentVersionMap.put('contentVersion', ContentDocumentLinkLst[0]);
        contentVersionMap.put('xlsxAsString', xlsxAsString);
        return JSON.serialize(contentVersionMap);
    }

    /*
    * Upload the csv files to Implementation Wizard Form Details
    * @param {String} plantAssetIdFromBtn - csv file to upload
    * @param {String} plantAssetId - Plant Asset Id
    * @param {String} plantApiId - Plant Api Id
    * @param {String} fileName - Name of file should be uploaded
    */
    @AuraEnabled
    public static String fileUpload(String csvToShow, String impWizStatus, String fileName){
        String returnValue = '';
        try{    
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = Blob.valueOf(csvToShow);
            cv.IsMajorVersion = true;
            cv.Imp_Wiz_CSV_Files__c	= true;
            Insert cv;

            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = impWizStatus;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            Insert cdl;

            returnValue = String.valueOf(conDocId);
        }catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
        return returnValue;
    }

    @AuraEnabled  
    public static string createImpWizFormDetail( String impWizFormDetailParam) {
        String returnValue = '';
            if(!String.isBlank(impWizFormDetailParam)){
                Map<String,String> jsonInputParametersAndValuesMap = Utils.deserializeAttribute(impWizFormDetailParam);
                Implementation_Wizard_Form_Detail__c impWiz = new Implementation_Wizard_Form_Detail__c(
                    Account_Plant__c = jsonInputParametersAndValuesMap.get('plantAssetId'),
                Plant_Id_PF_Text__c = jsonInputParametersAndValuesMap.get('plantIdPf'),
                Is_Created_in_CSV_Conversion__c = TRUE
            );
            
            insert impWiz;
            returnValue = String.valueOf(impWiz.Id);
        }
        return returnValue; 
    }

    @AuraEnabled
    public static String plantAssetStatus(String plantAssetId) {
        string plantAssetCheck = '';
        List<Account_Plant__c> plantAssetLst = [SELECT Asset_Builder_Status__c, PF_Service_Product__c,
                                    Project_Lifecycle_Status__c, AB_Approval_Status__c  FROM Account_Plant__c WHERE Id =: plantAssetId /*AND
                                    RecordType.DeveloperName = 'Child_Asset'*/];
        if(plantAssetLst.size()>0){
            Map<String,List<string>> licenseToPLCStatusMetadata = Utils.projectLifecycleStatus();
            String pfServiceProduct = Constants.IMPLEMENTATION_ASSET_BUILDING; 
            String partnerImplementationScopeValue = Constants.ASSET_BUILD; 
            User userSO = [Select Id, Name, Profile.UserLicense.Name, Contact.Account.Type From User WHERE Id=: UserInfo.getUserId()];
            String userLicenseName = userSO.Profile.UserLicense.Name;
            String userAccountType = userSO.Contact.Account.Type;
            List<String> abApprovalStatusLst = new List<String>();
            for(PAVisibilityInCommBOABApprovalStatus__mdt abApprovalStatus : [SELECT Label FROM  PAVisibilityInCommBOABApprovalStatus__mdt]){
                abApprovalStatusLst.add((abApprovalStatus.Label));
            }

            if(licenseToPLCStatusMetadata.containskey(userLicenseName)){
                List<string> plcStatusList  = new List<String>();
                if(userAccountType == Constants.PARTNER){
                    plcStatusList = licenseToPLCStatusMetadata.get(Constants.SALESFORCE) ;
                    if(plcStatusList.contains(plantAssetLst[0].Project_Lifecycle_Status__c)){
//                        if(plantAssetLst[0].PF_Service_Product__c.contains(pfServiceProduct) && plantAssetLst[0].Partner_Implementation_Scope__c.contains (partnerImplementationScopeValue)){
                        if(plantAssetLst[0].PF_Service_Product__c.contains(pfServiceProduct) ){   
                            if(plantAssetLst[0].Asset_Builder_Status__c != null){
                                return 'Navigate to AB - Partner with AB Initiated';    
                            }else{
                                return 'Navigate to AB - Partner with AB Not Initiated';    
                            }
                        }else{
                            return 'PF Service Not Contains - Partner';
                        }
                    }else{
                        return 'PLCS not contains - Partner User';
                    }
                }else{
                    plcStatusList = licenseToPLCStatusMetadata.get(userLicenseName) ;
                    if(plcStatusList.contains(plantAssetLst[0].Project_Lifecycle_Status__c)){
                        if(userLicenseName == Constants.SALESFORCE){
                            if(plantAssetLst[0].PF_Service_Product__c.contains(pfServiceProduct)){
                                if(plantAssetLst[0].Asset_Builder_Status__c != null){
                                    return 'Navigate to AB - PF Service  - Salesforce with AB Initiated';
                                }else{
                                    return 'Navigate to AB - PF Service  - Salesforce with AB Not Initiated';
                                }
                            }else{
                                return 'PF Service not contains - Salesforce';
                            }
                        }else if(userAccountType != Constants.PARTNER && userLicenseName == Constants.SALESFORCE){
                            if(abApprovalStatusLst.contains(plantAssetLst[0].AB_Approval_Status__c)){
                                return 'Submitted For Approval';
                            }else{
                                if(plantAssetLst[0].Asset_Builder_Status__c != null){
                                    return 'Navigate to AB - PF Service  - Community with AB Initiated';
                                }else{
                                    return 'Navigate to AB - PF Service  - Community with AB Not Initiated';
                                }
                            }
                        }
                    }else{
                        return 'PLCS not Applicable';
                    }
                } 
            }
        }else{
            plantAssetCheck = 'No Customer Plant Asset Available';
        }
        return plantAssetCheck;
    }

    @AuraEnabled
    public static String plantAssetStatusCompleted(String plantAssetId) {
        string plantAssetStatus = '';
        plantAssetStatus = [SELECT Asset_Builder_Status__c, PF_Service_Product__c, Project_Lifecycle_Status__c, AB_Approval_Status__c
                            FROM Account_Plant__c WHERE Id =: plantAssetId].Asset_Builder_Status__c;
        return plantAssetStatus;
    }

    @AuraEnabled
    public static String showHideImpWizBanner() {
        List<ImpWiz_Banner_Setting__mdt> imWizBanner = new List<ImpWiz_Banner_Setting__mdt>();
        Map<String, Object> imWizBannerMap = new Map<String, Object>();

        imWizBanner = [SELECT Banner_Content__c, Banner_End_Date__c, Banner_Start_Date__c, Banner_Title__c, IsActive__c
                        FROM ImpWiz_Banner_Setting__mdt WHERE IsActive__c = true LIMIT 1];

        if(!imWizBanner.isEmpty() && imWizBanner.size() > 0 &&
                imWizBanner[0].Banner_Start_Date__c <= system.today() &&
                imWizBanner[0].Banner_End_Date__c >= system.today()) {

            imWizBannerMap.put('showBanner', imWizBanner[0]);
            return JSON.serialize(imWizBannerMap);
        } else {
            return JSON.serialize('hidebanner');
        }
    }
}