public with sharing class Utils2 {
    
    /*
     * To update all the plantAssetPromptDetails as Is_Deleted__c = true 
     * @param plantAssetId
    */
    @AuraEnabled
    public static Boolean updatePlantAssetPromptDetail(String plantAssetId){
            Boolean result = false;
            Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = Utils.getG1PlantAssetPromptDetail(plantAssetId);
            List<Plant_Asset_Prompt_Detail__c>  plantAssetPromptDetailLst = new List<Plant_Asset_Prompt_Detail__c>();
            List<ContentDocumentLink> cdList = new List<ContentDocumentLink>();
            String plantAssetPromptDetailId = '';
            try {
                if(g1PlantAssetPromptDetail.Bulk_Import_Type__c == Constants.SINGLE_BASE_ASSET_TEMPLATE_PROMPTS){
                    for(Plant_Asset_Prompt_Detail__c plantAssetPromptDetail: [SELECT Id, Is_Deleted__c, Prompt_Information__r.Name FROM Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c =:plantAssetId AND Is_Deleted__c = false]){
                        if(plantAssetPromptDetail.Prompt_Information__r.Name != Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT){
                            plantAssetPromptDetail.Is_Deleted__c = true ;
                            plantAssetPromptDetailLst.add(plantAssetPromptDetail);
                        } else {
                            plantAssetPromptDetailId = plantAssetPromptDetail.Id;
                        }
                    }
                    if(plantAssetPromptDetailId != ''){
                        for(ContentDocumentLink cd : [SELECT Id,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =: plantAssetPromptDetailId]){
                                cdList.add(cd);
                        }
                    }
                    
                    if(cdList.size() > 0){
                        delete cdList;
                    }
        
                    if(plantAssetPromptDetailLst.size() > 0){
                        update plantAssetPromptDetailLst;
                    }
                }
                result = true;
            } catch(Exception exceptionDetails){
                result = false;
                String errorMessage = System.Label.AssetBuilderExceptionMessage;
                System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
                throw new AuraHandledException(errorMessage);
            }  
            return result;
        }
        /*
        * To generate RFI and updatation RFI related field for tracking purpose
        * @param plantAssetId
        */
        public static String callRFIGeneration(String plantAssetId){
            String rfiProcessResult='';
            try{
                //query all evaluations related against plant asset
                List<Evaluation_Value__c> evalValueLst = new List<Evaluation_Value__c>([SELECT Id, Name, Logic_Result__c, Account_Plant__c, Show_In_Report__c, Result__c, Evaluation__r.Sub_Category__c, Evaluation__r.Category__c,
                    Evaluation__r.Alias__c, Evaluation__r.Group_1__c, Evaluation__r.Group_2__c, Evaluation__r.Evaluation_Notes__c, Evaluation__r.RFI_Category__c, Evaluation__r.Products__c
                    FROM Evaluation_Value__c WHERE Account_Plant__c =: plantAssetId AND Show_In_Report__c = TRUE AND Result__c !=: Constants.PASS]);
                //query all Asset builder report data to know missing attributes related to completeness report
                List<String> systemNames = Utils.getAttrReqSysNamesFrmG1(plantAssetId);
                
                //Get necessary attribute requirement for rfi item creation 
                Map<String, String> attrReqInRD = new Map<String, String>();
                List<Asset_Builder_Report_Data__c> assetBuilderReportDataLst = new List<Asset_Builder_Report_Data__c>();
                
                for(AttributesRequirementForRFIItemCreation__mdt attrReqForRFI : [SELECT DeveloperName, Type__c, Value__c,Label FROM AttributesRequirementForRFIItemCreation__mdt WHERE Label IN: systemNames ORDER BY Label]){
                        attrReqInRD.put(attrReqForRFI.Label, attrReqForRFI.Type__c);
                }
                
                for(Asset_Builder_Report_Data__c abrd : [SELECT Base_Asset_Template__r.RFI_Category__c, Base_Asset_Template__c, Prompt_Information__c, System__c, Type__c, Total_Attribute_Count__c, Total_Completed_Attribute_Count__c, Is_Archived__c, Account_Plant__c FROM Asset_Builder_Report_Data__c 
                                                            WHERE Account_Plant__c =: plantAssetId AND Is_Archived__c = FALSE AND Type__c IN: attrReqInRD.values()]){
                    if(attrReqInRD.containsKey(abrd.System__c)){
                        assetBuilderReportDataLst.add(abrd);
                    }
                }
                
                //To show message based on a condition - if there is no missed attributes during asset builder process and no evaluation value generated - show a information message 
                if(evalValueLst.size() == 0 && assetBuilderReportDataLst.size() == 0){
                    rfiProcessResult = System.Label.NoRfiToBeCreated+'&Error';
                }else if(evalValueLst.size() > 0 || assetBuilderReportDataLst.size() > 0){ //To show message based on a condition - if any missed attributes during asset builder process or any evaluation value generated - show a information message and publish a event for rfi creation
                    //Update RFI Generation status in G1 Plant asset prompt detail against Plant asset
                    Plant_Asset_Prompt_Detail__c pltAstPrtDtl = [SELECT Id, Name, RFI_Generated_for_CA_Report__c, RFI_Generated_for_CO_Report__c, Account_Plant__c,  Account_Plant__r.Asset_Builder_Status__c, RFI_Generated_By_User__c, RFI_Generated_Datetime__c FROM Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c =:plantAssetId AND Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND Is_Deleted__c = FALSE];
                    pltAstPrtDtl.RFI_Generated_for_CA_Report__c = Constants.IN_PROGRESS;
                    pltAstPrtDtl.RFI_Generated_for_CO_Report__c = Constants.IN_PROGRESS;
                    pltAstPrtDtl.RFI_Generated_Datetime__c = System.now();
                    pltAstPrtDtl.RFI_Generated_By_User__c = UserInfo.getUserId(); 
                    pltAstPrtDtl.RFI_PE_Process_Description__c = '';
                    update pltAstPrtDtl;
                    //Call RFI Data Creation class
/*                    String resultFromRFICreation = RFIDataCreation.dataFormationForRFI(plantAssetId);
                    if(resultFromRFICreation == 'true'){
                        rfiProcessResult = System.Label.RFIGeneratedSuccessfully+'&Success';
                    }else{
                        rfiProcessResult = resultFromRFICreation+'&Error';
                    }  */ //Uncomment after Deploying RFI
                }
            }catch(Exception exceptionDetails){
                rfiProcessResult = exceptionDetails.getMessage()+'&Error';
                insert Utils.catchErrorLogs('callRFIGeneration',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetId, '');
            }
            return rfiProcessResult;
        }
        @AuraEnabled
        public static Boolean updateG1PlantAssetPromptDetail(String plantAssetId, String jsonInputParametersAndValues){
            Boolean result = false;
            Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = Utils.getG1PlantAssetPromptDetail(plantAssetId);
            if(!String.isBlank(jsonInputParametersAndValues)){
                Map<String,String> jsonInputParametersAndValuesMap = Utils.deserializeAttribute(jsonInputParametersAndValues);
                Boolean isBulkUploadCheck = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD));
                Boolean isBulkUploadMultipleBATCheck = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD_MULTIPLE_BAT));
                if(isBulkUploadCheck){
                    g1PlantAssetPromptDetail.Bulk_Import_Type__c = Constants.MULTIPLE_BASE_ASSET_TEMPLATE_PROMPTS;
                    result = true;
                }else if(isBulkUploadMultipleBATCheck){
                    g1PlantAssetPromptDetail.Bulk_Import_Type__c = Constants.COMPLETED;
                    result = true;
                }
                update g1PlantAssetPromptDetail;
            }
            return result;
        }
    
    
        /**
         * This Method is used to get the csv string based on the Prompt Name, Plant Asset Id and Json Input Values
         */
        public static String getImpWizCSVFileforPrompts(String jsonInputParametersAndValues, String plantAssetId,
                String currentPromptName){
            String promptName;
            String csvData = '';
            if(currentPromptName.contains('/')){
                currentPromptName = currentPromptName.replace('/', '-');
            }
    
            promptName = (currentPromptName.length()>31) ? currentPromptName.substring(0, 31) : currentPromptName;
            Map<String,String> jsonInputParametersAndValuesMap = Utils.deserializeAttribute(jsonInputParametersAndValues);
            Boolean isImpWizUpLoad = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_IMPWIZ_UPLOAD));
    
            if(isImpWizUpLoad){
                csvData = Utils2.getPlatAssetCSVData(plantAssetId, promptName);
            }
            return csvData;
        }
    
        // To get CSv file from the Plant Asset to populate the values based on the prompt name.
        // This is when user launch AB from IW to load date from the downloaded/ uploaded file.
    
        public static String getPlatAssetCSVData (String plantAssetId, String promptName){
    
            list<String> allfilesRelatedToPA = new List<String>();
            String searchString = promptName;
            Id linkedIWFDId = [SELECT Id FROM Implementation_Wizard_Form_Detail__c WHERE Account_Plant__c =: plantAssetId
                                ORDER BY CreatedDate desc LIMIT 1].Id;
    
            for(ContentDocumentLink contentDocument :[SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink WHERE
                    LinkedEntityId =: linkedIWFDId ]){
                allfilesRelatedToPA.add(contentDocument.ContentDocumentId);
            }
    
            string promptNamewithCSV = promptName+'.csv';
            List<ContentVersion> getCSVData = new list<ContentVersion>([SELECT Id, Title, VersionData FROM ContentVersion
            WHERE ContentDocumentId =: allfilesRelatedToPA
            AND Title =: promptNamewithCSV ORDER BY LastModifiedDate DESC LIMIT 1]);
    
            String csvString;
            if(getCSVData.size()>0){
                csvString = Utils.blobToString( getCSVData[0].VersionData,'ISO-8859-1');
            }else{
                csvString = 'No CSV Files Found';
            }
            return csvString;
        }
    }