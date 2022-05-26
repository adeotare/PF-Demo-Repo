/**
 * Created by karthikeyan.k on 11/17/2021.
 */

public with sharing class AssetBuilderLocationAPI {

    @AuraEnabled
    public static Map<String, String> callLocationAPIfromLWC(String plantAssetID, Boolean locationAPIfromLWC) {
        Map<String, String> locationFromLWC =  new Map<String, String>();

        try {

            Plant_Asset_Prompt_Detail__c plantAssetPD = new Plant_Asset_Prompt_Detail__c();
            locationFromLWC = callLocationAPI(plantAssetID, plantAssetPD, false, true);
            return locationFromLWC;

        }catch(Exception exceptionDetails){

            String errorMessage = ' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber();
            System.debug(errorMessage);
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('PlantAssetLocationAPI', exceptionDetails.getMessage(),
                    exceptionDetails.getLineNumber(), plantAssetID, '');
            insert errorLogInstance;
            locationFromLWC.put('true',exceptionDetails.getMessage());
            return locationFromLWC;
        }
    }

    public static Map<String, String> callLocationAPI(String plantAssetID, Plant_Asset_Prompt_Detail__c plantAssetPD, Boolean fetchLocationButton, Boolean fromLWC){
        Map<String, String> locationAPImap = new Map<String, String>();
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = plantAssetPD;
        try{

            String GroupId = System.Label.ABLocationAPIGroupId;
            String CustomerId = System.Label.ABLocationAPICustomerId;
            String LocationUpdated = System.Label.ABLocationAPIUpdatedMessage;
            String LocationNotUpdated = System.Label.ABLocationAPINotUpdatedMessage;

            Account_Plant__c platAssetLocation = new Account_Plant__c();
            Account_Plant__c parentAsset = new Account_Plant__c();
            platAssetLocation = [SELECT Id,Plant_Country__c,Latitude__c,Longitude__c,State_Province__c,TimeZone__c
            FROM Account_Plant__c
            WHERE Id =:plantAssetID ];

            if(platAssetLocation.Latitude__c != null && platAssetLocation.Longitude__c != null) {

/*                if(platAssetLocation.Parent__c != null){
                    parentAsset = [SELECT Id, Plant_Country__c, State_Province__c, TimeZone__c, Parent__c
                    FROM Account_Plant__c
                    WHERE Id =:platAssetLocation.Parent__c ];
                }
*/
                String endPoint = 'callout:ImpWizFormAPIDetails/location?latitude={0}&longitude={1}';

                endPoint = String.format(endPoint, new String[]{
                        platAssetLocation.Latitude__c, platAssetLocation.Longitude__c
                });
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(endPoint);
                request.setMethod('GET');
                request.setHeader('Content-Type', 'application/json; charset=UTF-8');
                request.setHeader('Ocp-Apim-Subscription-Key', '{!$Credential.Password}');
                request.setHeader('GroupId', GroupId);
                request.setHeader('CustomerId', CustomerId);

                request.setTimeout(120000);
                HttpResponse response = http.send(request);
                String jsonStream;
                jsonStream = response.getBody();
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonStream);
                if (response.getStatusCode() == 200) {

/*Removing Parent field from Account Plant obje
                    if (parentAsset != null) {
                        parentAsset.Plant_Country__c = String.valueOf(jsonMap.get('LOCATION_COUNTRY'));
                        parentAsset.State_Province__c = String.valueOf(jsonMap.get('LOCATION_STATE'));
                        parentAsset.TimeZone__c = String.valueOf(jsonMap.get('LOCATION_TIMEZONE'));
                        update parentAsset;
                    }
Below field is formula field can't update
                    platAssetLocation.Plant_Country__c = String.valueOf(jsonMap.get('LOCATION_COUNTRY'));
                    platAssetLocation.State_Province__c = String.valueOf(jsonMap.get('LOCATION_STATE'));
                    platAssetLocation.Timezone__c = String.valueOf(jsonMap.get('LOCATION_TIMEZONE'));
 */
//                    update platAssetLocation;

                    if (!fromLWC) {
                        if (plantAssetPromptDetail != null) {
                            plantAssetPromptDetail.Is_Location_Fetched__c = true;
                            update plantAssetPromptDetail;
                        }
                    }
                    locationAPImap.put('true',LocationUpdated);
                } else {

                    Error_Log__c errorLogInstance = Utils.catchErrorLogs('PlantAssetLocationAPI', response.getStatus(),
                            response.getStatusCode(), plantAssetID, '');
                    insert errorLogInstance;

                }
            } else {
                locationAPImap.put('true',LocationNotUpdated);
            }

            return locationAPImap;

        }catch(Exception exceptionDetails){
            String errorMessage = ' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber();
            System.debug(errorMessage);
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('PlantAssetLocationAPI', exceptionDetails.getMessage(),
                    exceptionDetails.getLineNumber(), plantAssetID, '');
            insert errorLogInstance;
            locationAPImap.put('true',exceptionDetails.getMessage());
            return locationAPImap;
        }
    }
}