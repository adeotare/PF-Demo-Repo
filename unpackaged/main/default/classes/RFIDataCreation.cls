/**
 * TODO - Calls from Platform Event trigger when generate RFI Button click.
 * Publish Platform Event for RFI and RFI Item Creations.
 * */ 
public with sharing class RFIDataCreation {
    public static String plantAssetId;
    public static Plant_Asset_Prompt_Detail__c pltAstPrtDtl;
    /*
    * Creation of RFI and RFI Items based on capabality and completeness report.
    * For capabality report - RFI Items created for evaluations which are highlighted as "Red" color which indicates missing values or inproper value.
    * @param {String} plantAssetIdFromBtn - Pass Plant Asset Id for data creation for RFI and RFI Items. 
    */
    public static String dataFormationForRFI(String plantAssetIdFromBtn){
        Map<String, List<Evaluation_Value__c>> rfiCategoryRelToEval = new Map<String, List<Evaluation_Value__c>>();
        String processRFICreation='';
        try{
            plantAssetId = plantAssetIdFromBtn;
            pltAstPrtDtl = [SELECT Id, Name, RFI_PE_Process_Description__c, RFI_Generated_for_CA_Report__c, RFI_Generated_for_CO_Report__c, Account_Plant__r.Asset_Builder_Status__c FROM Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c =:plantAssetId AND Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND Is_Deleted__c = FALSE];
            Boolean processCompletedCAReport = true;
            RFI__c[] existingRfiRelToPA = [SELECT Id, Account_Plant__c, RFI_Status__c, Account_Plant__r.Asset_Builder_Status__c FROM RFI__c WHERE Account_Plant__c =: plantAssetId AND RFI_Status__c !=: Constants.CLOSED];
            RFI__c rfiInstance; 
            SObjectType rfiObj = Schema.getGlobalDescribe().get('RFI__c');
            Map<String,Schema.SObjectField> rfiFields = rfiObj.getDescribe().fields.getMap();
        
            if(existingRfiRelToPA.size() == 0){
                Map<String, String> mappingForRequiredFields = Utils.queryABRequiredFields('RFI__c');
                rfiInstance = new RFI__c();

                for(String rfiRequiredFields : mappingForRequiredFields.keySet()){
                    if(rfiFields.containskey(rfiRequiredFields.toLowerCase())){
                        rfiInstance.put(rfiRequiredFields, mappingForRequiredFields.get(rfiRequiredFields));
                    }
                } 

                rfiInstance.Account_Plant__c = plantAssetId;
                insert rfiInstance;
            }else{
                rfiInstance = existingRfiRelToPA[0];
            }

            if(String.isNotBlank(rfiInstance.Id)){

                //Form map for capability report
                    for(Evaluation_Value__c evalValIns : [SELECT Id, Name, Logic_Result__c, Account_Plant__c, Show_In_Report__c, Result__c, Evaluation__r.Sub_Category__c, Evaluation__r.Category__c, Evaluation__r.Alias__c, Evaluation__r.Group_1__c, Evaluation__r.Group_2__c, Evaluation__r.Evaluation_Notes__c, Evaluation__r.RFI_Category__c, Evaluation__r.Products__c FROM Evaluation_Value__c WHERE Account_Plant__c =: plantAssetId AND Show_In_Report__c = TRUE AND Result__c !=: Constants.PASS ORDER BY Evaluation__r.Group_1__c ASC, Evaluation__r.Group_2__c ASC, Evaluation__r.Category__c ASC, Evaluation__r.Sub_Category__c ASC]){
                    String evalDefKeyCombination = evalValIns.Evaluation__r.RFI_Category__c +'-'+evalValIns.Evaluation__r.Group_1__c+'-'+evalValIns.Evaluation__r.Group_2__c;
                    if(!rfiCategoryRelToEval.containsKey(evalDefKeyCombination)){
                        List<Evaluation_Value__c> evalValLst = new List<Evaluation_Value__c>();
                        rfiCategoryRelToEval.put(evalDefKeyCombination, evalValLst);
                    }
                    List<Evaluation_Value__c> evalValLst = rfiCategoryRelToEval.get(evalDefKeyCombination);
                    evalValLst.add(evalValIns);
                    rfiCategoryRelToEval.put(evalDefKeyCombination, evalValLst);
                }

                if(rfiCategoryRelToEval.size()>0){
                    processCompletedCAReport = createRFILineItemForCapabilityReport(rfiInstance, rfiCategoryRelToEval);
                    pltAstPrtDtl.RFI_PE_Process_Description__c = String.isNotBlank(pltAstPrtDtl.RFI_PE_Process_Description__c) ? pltAstPrtDtl.RFI_PE_Process_Description__c+'-CA REPORT-'+Constants.RECORDS_PRESENT : 'CA REPORT-'+ Constants.RECORDS_PRESENT;
                }else{
                    pltAstPrtDtl.RFI_PE_Process_Description__c = String.isNotBlank(pltAstPrtDtl.RFI_PE_Process_Description__c) ? pltAstPrtDtl.RFI_PE_Process_Description__c+'-CA REPORT-'+Constants.RECORDS_NOT_PRESENT : 'CA REPORT-'+ Constants.RECORDS_NOT_PRESENT;
                }

                //Form map for completeness report
                Boolean processCompletedCOReport = true;

                //query all Asset builder report data to know missing attributes related to completeness report
                List<String> systemNames = Utils.getAttrReqSysNamesFrmG1(plantAssetId);

                Map<String, String> attrReqInRD = new Map<String, String>();
                Map<String, String> toQueryAttrReq = new Map<String, String>();

                //Form a map to have attribute list related base asset template with attribute requirement fields 
                //First string - CombinationOfBaseAssetTemplate_PromptInformation_RfiCategory, Second string - System field in Attribute Requirement, third string - Required field in attribute requirement, fourth element - List of attributes
                Map<String, Map<String, Map<String, List<String>>>> missingAttributes = new Map<String, Map<String, Map<String, List<String>>>>();
                for(AttributesRequirementForRFIItemCreation__mdt attrReqForRFI : [SELECT DeveloperName, Type__c, Value__c,Label FROM AttributesRequirementForRFIItemCreation__mdt WHERE Label IN: systemNames ORDER BY Label]){
                    attrReqInRD.put(attrReqForRFI.Label, attrReqForRFI.Type__c);
                    toQueryAttrReq.put(attrReqForRFI.Label, attrReqForRFI.Value__c);
                }

                for(Asset_Builder_Report_Data__c rdIns : [SELECT Base_Asset_Template__r.RFI_Category__c, Base_Asset_Template__c, Prompt_Information__c, System__c, Type__c, Total_Attribute_Count__c, Total_Completed_Attribute_Count__c, Is_Archived__c, Account_Plant__c FROM Asset_Builder_Report_Data__c WHERE Account_Plant__c =: plantAssetId AND Is_Archived__c = FALSE AND Type__c IN: attrReqInRD.values()]){
                    if(attrReqInRD.containsKey(rdIns.System__c)){
                        if((rdIns.Total_Attribute_Count__c != rdIns.Total_Completed_Attribute_Count__c)){
                            String combination_BAT_PI_RFICat = rdIns.Base_Asset_Template__c+'-'+rdIns.Prompt_Information__c+'-'+rdIns.Base_Asset_Template__r.RFI_Category__c;
                            if(!missingAttributes.containsKey(combination_BAT_PI_RFICat)){
                                missingAttributes.put(combination_BAT_PI_RFICat, new Map<String, Map<String, List<String>>>()); 
                            }
                        }
                    }   
                }
            
                if(missingAttributes.size()>0){
                    processCompletedCOReport = createRFILineItemForCompletenessReport(rfiInstance, missingAttributes, toQueryAttrReq);
                    pltAstPrtDtl.RFI_PE_Process_Description__c =  String.isNotBlank(pltAstPrtDtl.RFI_PE_Process_Description__c) ? pltAstPrtDtl.RFI_PE_Process_Description__c+'-CO REPORT-'+Constants.RECORDS_PRESENT : 'CO REPORT-'+Constants.RECORDS_PRESENT;
                }else{
                    pltAstPrtDtl.RFI_PE_Process_Description__c =  String.isNotBlank(pltAstPrtDtl.RFI_PE_Process_Description__c) ? pltAstPrtDtl.RFI_PE_Process_Description__c+'-CO REPORT-'+Constants.RECORDS_NOT_PRESENT : 'CO REPORT-'+Constants.RECORDS_NOT_PRESENT;
                }

                //To update plant asset and plant asset prompt detail
                if(processCompletedCAReport == true && processCompletedCOReport == true){
                    Account_Plant__c plantAssets = [SELECT Id, Asset_Builder_Status__c FROM Account_Plant__c WHERE Id =: plantAssetId];
                    plantAssets.Asset_Builder_Status__c = Constants.CLOSED;
                    update plantAssets;
                    pltAstPrtDtl.RFI_Generated_for_CA_Report__c = Constants.COMPLETED;
                    pltAstPrtDtl.RFI_Generated_for_CO_Report__c = Constants.COMPLETED;
                    processRFICreation = 'true';
                }else if(processCompletedCAReport == false){
                    pltAstPrtDtl.RFI_Generated_for_CA_Report__c = Constants.COMPLETED_ERROR;
                    processRFICreation = System.Label.PleaseContactAdministrator+' Error in RFI creation for capability report';
                }else if(processCompletedCOReport == false){
                    pltAstPrtDtl.RFI_Generated_for_CO_Report__c = Constants.COMPLETED_ERROR;
                    processRFICreation = System.Label.PleaseContactAdministrator+' Error in RFI creation for completeness report';
                }
                update pltAstPrtDtl;
            }
        }catch(Exception exceptionDetails){
            processRFICreation = exceptionDetails.getMessage();
            insert Utils.catchErrorLogs('dataFormationForRFI',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetId, '');
            System.debug('Error in '+exceptionDetails.getLineNumber()+'-'+exceptionDetails.getMessage());
        }
        return processRFICreation;
    }

     /*
    * RFI Item/Detail insertion based on RFI category and evaluation
    * @param {RFI__c} rfiInstance - RFI Item need to create against RFI
    * @param {Map<String, List<Evaluation_Value__c>>} rfiCategoryRelToEval - Evaluation value grouped based on RFI Category.
    */
    public static Boolean createRFILineItemForCapabilityReport(RFI__c rfiInstance, Map<String, List<Evaluation_Value__c>> rfiCategoryRelToEval){
        Map<String, RFI_Detail__c> rfiItemList = new Map<String, RFI_Detail__c>();
        Savepoint sp = Database.setSavepoint();
        Boolean processCompleted = true;
        try{
            Map<String, String> mappingForRequiredFields = Utils.queryABRequiredFields('RFI_Detail__c');
            SObjectType rfiDetObj = Schema.getGlobalDescribe().get('RFI_Detail__c');
            Map<String,Schema.SObjectField> rfiDetFields = rfiDetObj.getDescribe().fields.getMap();

            for(String rfiCat : rfiCategoryRelToEval.keySet()){
                String rfiCatId = rfiCat.split('-')[0];
                if(!rfiItemList.containsKey(rfiCatId)){
                    //RFI Item Formation based on RFI Category
                    RFI_Detail__c rfiItemIns = new RFI_Detail__c();
                    rfiItemIns.RFI_Number__c = rfiInstance.Id;
                    rfiItemIns.RFI_Category__c = rfiCatId;
                    rfiItemIns.Missing_Incomplete_Category__c = rfiCatId;
                    
                    //Mapping required fields for RFI Item Object
                    for(String rfiRequiredFields : mappingForRequiredFields.keySet()){
                        if(rfiDetFields.containskey(rfiRequiredFields.toLowerCase())){
                            rfiItemIns.put(rfiRequiredFields, mappingForRequiredFields.get(rfiRequiredFields));
                        }
                    }
                    rfiItemList.put(rfiCatId, rfiItemIns);
                }
                RFI_Detail__c rfiItemIns = rfiItemList.get(rfiCatId);
                
                //value for RFI Item Description field     
                List<Evaluation_Value__c> evalValList = rfiCategoryRelToEval.get(rfiCat);
                String valueToShow = '';

                for(Integer evalValIns = 0; evalValIns<evalValList.size(); evalValIns++){
                    if(String.isBlank(valueToShow)){
                        valueToShow = evalValList[evalValIns].Evaluation__r.Group_1__c+' -- ';
                        valueToShow += evalValList[evalValIns].Evaluation__r.Group_2__c == null ? System.Label.Group2NullValue : evalValList[evalValIns].Evaluation__r.Group_2__c;
                    }
                    valueToShow += '\n\n'+System.Label.Alias+' - '+evalValList[evalValIns].Evaluation__r.Alias__c+'\n'+System.Label.Products+' - '+evalValList[evalValIns].Evaluation__r.Products__c+'\n'+System.Label.Result+' - '+evalValList[evalValIns].Result__c+'\n'+System.Label.EvaluationNotes+' - ';
                    valueToShow += evalValList[evalValIns].Evaluation__r.Group_2__c == null ? System.Label.EvaluationNotesNullValue : evalValList[evalValIns].Evaluation__r.Evaluation_Notes__c;
                }

                String rfiItemDes = rfiItemIns.RFI_Detail_Description__c;
                rfiItemDes = (String.isBlank(rfiItemDes)) ? valueToShow : rfiItemDes+'\n\n'+ valueToShow;

                //To control overflow contents in RFI Item Description
                rfiItemIns = controlOverFlowOfRfiItemDes(rfiItemIns, rfiItemDes);

                rfiItemList.put(rfiCatId, rfiItemIns);
            }

            if(rfiItemList.size() > 0){
                insert rfiItemList.values();
            }
        }catch(Exception exceptionDetails){
            processCompleted = false;
            Database.rollback(sp);
            insert Utils.catchErrorLogs('createRFILineItemForCapabilityReport',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetId, '');
            System.debug('Error in '+exceptionDetails.getLineNumber()+'-'+exceptionDetails.getMessage());
        }
        return processCompleted;
    }
    /*
    * RFI Item/Detail insertion based on RFI category and Base asset template
    * @param {RFI__c} rfiInstance - RFI Item need to create against RFI
    * @param {Map<String, Map<String, Map<String, List<String>>>>} missingAttributes - Attributes related to base asset template, prompt information, Attribute Requirement.
    * @param {Map<String, String>} toQueryAttrReq - Attribute requirements relate to core attribute
    */
    public Static Boolean createRFILineItemForCompletenessReport(RFI__c rfiInstance, Map<String, Map<String, Map<String, List<String>>>> missingAttributes, Map<String, String> toQueryAttrReq){
        Boolean processCompleted = true;
        try{
            List<String> BAT = new List<String>();
            List<RFI_Detail__c> rfiItemInsertion = new List<RFI_Detail__c>();
            List<String> coreAttr = new List<String>();
            Map<String, Map<String, Map<String, Attribute_Value__c>>> attributeValueOfMissingAttributes = new Map<String, Map<String, Map<String, Attribute_Value__c>>>();
            Map<String, String> mappingForRequiredFields = Utils.queryABRequiredFields('RFI_Detail__c');
            
            //To get all base asset template
            for(String strIns : missingAttributes.keyset()){
                BAT.add(strIns.split('-')[0]);
            }
            
            // get all attributes based on attribute requirement from plant asset and custom metadata
            Map<String, String> resultantMap = getAttrReqRelToBaseAsset(missingAttributes, toQueryAttrReq);
        //    (Map<String, Map<String, Map<String, List<String>>>>)JSON.deserialize(resultantMap.get('missingAttributes'), Map<String, Map<String, Map<String, List<String>>>>.class);
        //    (List<String>)JSON.deserialize(resultantMap.get('coreAttr'), List<String>.class);
            missingAttributes = (Map<String, Map<String, Map<String, List<String>>>>)JSON.deserialize(resultantMap.get('missingAttributes'), Map<String, Map<String, Map<String, List<String>>>>.class);
            coreAttr.addAll((List<String>)JSON.deserialize(resultantMap.get('coreAttr'), List<String>.class));

            // To get all empty attribute value related to base asset template
            attributeValueOfMissingAttributes = formAttrValMap(coreAttr);

            //loop all combination of base asset template and prompt information
            for(String conCatVal : missingAttributes.keyset()){
                String rfiItemDes = '';
                RFI_Detail__c rfiItemIns = new RFI_Detail__c();
                rfiItemIns.RFI_Number__c = rfiInstance.Id;
                rfiItemIns.RFI_Category__c = conCatVal.split('-')[2]; 
                rfiItemIns.Missing_Incomplete_Category__c = conCatVal.split('-')[2];

                for(String rfiRequiredFields : mappingForRequiredFields.keySet()){
                    rfiItemIns.put(rfiRequiredFields, mappingForRequiredFields.get(rfiRequiredFields));
                }
                
                String BATIns = conCatVal.split('-')[0];
                Integer count = 0;
                //loop all sitemetadata related to base asset template
                for(String siteMetadata : attributeValueOfMissingAttributes.get(BATIns).keySet()){
                    count++;
                    String baseAssetName='', productToShow='', valuesToShow='', defaultValToShow='' , combin_Product_Value='';

                    if(attributeValueOfMissingAttributes.get(BATIns).get(siteMetadata).size() > 0 ){
                        Integer existsAttrVal =0;

                        //Iterate all product and required value from combination of base asset template and prompt information
                        for(String product : missingAttributes.get(conCatVal).keySet()){
                            for(String required : missingAttributes.get(conCatVal).get(product).keySet()){

                               //To show all products and Pf serice product
                                productToShow = '\n\n'+System.Label.PfServiceProduct+' - '+product+' - '+required+'\n';
                                
                                //Iterate all attribute value related to base asset template and prompt information
                                for(String attribute : attributeValueOfMissingAttributes.get(BATIns).get(siteMetadata).keySet()){
                                    if(missingAttributes.get(conCatVal).get(product).get(required).contains(attribute)){
                                        existsAttrVal++;
                                        Attribute_Value__c attrValue = attributeValueOfMissingAttributes.get(BATIns).get(siteMetadata).get(attribute);
                                        
                                        baseAssetName = System.Label.AssetName+' - ';
                                        baseAssetName += (attrValue.Site_Metadata__r.Asset_Name__c != null)? attrValue.Site_Metadata__r.Asset_Name__c : System.Label.AssetNameMissing;    
                                        
                                        String attributeName = String.isNotBlank(attrValue.Attribute__r.Attribute_Master__r.Alias__c) ? '\n'+attrValue.Attribute__r.Attribute_Master__r.Alias__c : '\n'+attrValue.Attribute__r.Name;
                                        
                                        if(attrValue.Is_Value_Defaulted__c == true){
                                            if(String.isNotBlank(defaultValToShow)){
                                                defaultValToShow += attributeName + ' - '+attrValue.Attribute__r.Default_value__c;
                                            }else{
                                                defaultValToShow = attributeName + ' - '+attrValue.Attribute__r.Default_value__c;
                                            }
                                        }else{
                                            if(String.isNotBlank(valuesToShow)){
                                                valuesToShow += attributeName;
                                            }else{
                                                valuesToShow = attributeName;
                                            }
                                        }
                                    }
                                }
                            }

                            //To combine product value and default value
                            if(existsAttrVal > 0){
                                combin_Product_Value = String.isNotBlank(combin_Product_Value) ? combin_Product_Value + productToShow : productToShow;
                                
                                if(String.isNotBlank(valuesToShow)){
                                    combin_Product_Value += System.Label.MissingAttributes+':'+ valuesToShow;
                                }
                                if(String.isNotBlank(defaultValToShow)){
                                    combin_Product_Value += '\n\n'+System.Label.DefaultValue+':'+defaultValToShow;
                                }
                            }
                        }
                        
                    }
                    rfiItemDes = String.isNotBlank(rfiItemDes) ? rfiItemDes + '\n\n' + baseAssetName + combin_Product_Value: baseAssetName + combin_Product_Value;
                }

               /// To control overflow of rfi item description field
                rfiItemIns = controlOverFlowOfRfiItemDes(rfiItemIns, rfiItemDes);

                rfiItemInsertion.add(rfiItemIns);
            }
            
            if(rfiItemInsertion.size() > 0){
                insert rfiItemInsertion;
                mappingForRequiredFields.clear();
            }

        }catch(Exception exceptionDetails){
            processCompleted = false;
            insert Utils.catchErrorLogs('createRFILineItemForCompletenessReport',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetId, '');
            System.debug('Error in '+exceptionDetails.getLineNumber()+'-'+exceptionDetails.getMessage());
        }
        return processCompleted;
    }
    /*
    * To get all empty attribute value related to base asset template
    * @param {List<String>} coreAttr - List of core attributes
    */
    public static Map<String, Map<String, Map<String, Attribute_Value__c>>> formAttrValMap(List<String> coreAttr){
        Map<String, Map<String, Map<String, Attribute_Value__c>>> attributeValueOfMissingAttributes = new Map<String, Map<String, Map<String, Attribute_Value__c>>>();
        for(Attribute_Value__c atValIns : [SELECT Name, Base_Asset_Template__r.Name, Base_Asset_Template__r.RFI_Category__r.Name, Site_Metadata__c, Is_Value_Defaulted__c, Base_Asset_Template__r.RFI_Category__c, Attribute__c, Attribute__r.Name, Attribute__r.Attribute_Master__r.Alias__c, Value__c, Base_Asset_Template__c, Prompt_Information__c, Site_Metadata__r.Plant_Asset_Prompt_Detail__r.Is_Deleted__c, Site_Metadata__r.Asset_Name__c, Attribute__r.Default_value__c FROM Attribute_Value__c WHERE Site_Metadata__r.Plant_Asset_Prompt_Detail__r.Is_Deleted__c = FALSE AND Attribute__c IN: coreAttr AND Account_Plant__c =: plantAssetId AND Value__c = null ORDER BY  Site_Metadata__r.Asset_Name__c ASC, Attribute__r.Name ASC]){
            if(!attributeValueOfMissingAttributes.containsKey(atValIns.Base_Asset_Template__c)){
                attributeValueOfMissingAttributes.put(atValIns.Base_Asset_Template__c, new Map<String, Map<String, Attribute_Value__c>>());
            } 
            if(!attributeValueOfMissingAttributes.get(atValIns.Base_Asset_Template__c).containsKey(atValIns.Site_Metadata__c)){
                attributeValueOfMissingAttributes.get(atValIns.Base_Asset_Template__c).put(atValIns.Site_Metadata__c, new Map<String, Attribute_Value__c>());
            }   
            if(!attributeValueOfMissingAttributes.get(atValIns.Base_Asset_Template__c).get(atValIns.Site_Metadata__c).containsKey(atValIns.Attribute__c)){
                attributeValueOfMissingAttributes.get(atValIns.Base_Asset_Template__c).get(atValIns.Site_Metadata__c).put(atValIns.Attribute__c, atValIns);
            }
        }
        return attributeValueOfMissingAttributes;
    }
    /*
    * To get all attributes based on attribute requirement from plant asset and custom metadata
    * @param {List<String>} coreAttr - List of core attributes
    */
    public static Map<String, String> getAttrReqRelToBaseAsset(Map<String, Map<String, Map<String, List<String>>>> missingAttributes, Map<String, String> toQueryAttrReq){
        List<String> coreAttr = new List<String>();
        Map<String, String> resultantMap = new Map<String, String>();
        for(Attribute_Requirement__c attrReqIns : [SELECT Core_Attribute__r.Name, Core_Attribute__r.Attribute_Master__r.Alias__c, Core_Attribute__r.Base_Asset_Name__c, Core_Attribute__c, System__c, Required__c FROM Attribute_Requirement__c WHERE System__c IN: toQueryAttrReq.keyset() AND Required__c IN: toQueryAttrReq.values() ORDER BY System__c ASC, Core_Attribute__r.Attribute_Master__r.Alias__c ASC, Core_Attribute__r.Name ASC]){
            for(String strIns : missingAttributes.keyset()){
                if(attrReqIns.Core_Attribute__r.Base_Asset_Name__c == strIns.split('-')[0]){
                    if(toQueryAttrReq.get(attrReqIns.System__c) == attrReqIns.Required__c){
                        if(!missingAttributes.get(strIns).containsKey(attrReqIns.System__c)){
                            missingAttributes.get(strIns).put(attrReqIns.System__c, new Map<String, List<String>>());
                        }
                        if(!missingAttributes.get(strIns).get(attrReqIns.System__c).containsKey(attrReqIns.Required__c)){
                            missingAttributes.get(strIns).get(attrReqIns.System__c).put(attrReqIns.Required__c, new List<String>());
                        }
                        List<String> coreAttrLst = missingAttributes.get(strIns).get(attrReqIns.System__c).get(attrReqIns.Required__c);
                        coreAttrLst.add(attrReqIns.Core_Attribute__c);
                        missingAttributes.get(strIns).get(attrReqIns.System__c).put(attrReqIns.Required__c, coreAttrLst);
                        coreAttr.add(attrReqIns.Core_Attribute__c);
                    }
                }
            }
        }
        resultantMap.put('missingAttributes', JSON.serialize(missingAttributes));
        resultantMap.put('coreAttr', JSON.serialize(coreAttr));
        return resultantMap;
    }
     /*
    * To control overflow of rfi item description field
    * @param {List<String>} coreAttr - List of core attributes
    */
    public static RFI_Detail__c controlOverFlowOfRfiItemDes(RFI_Detail__c rfiItemIns, String rfiItemDes){

        Integer lenOfItemDes = rfiItemDes.length();
        Integer totalLenForItemDes = RFI_Detail__c.RFI_Detail_Description__c.getDescribe().getLength();
        Integer totalLenForAdditionalItemDes = RFI_Detail__c.Additional_RFI_Item_Description__c.getDescribe().getLength();
        Integer totalLenForAdditionalItemDes2 = RFI_Detail__c.Additional_RFI_Item_Description_2__c.getDescribe().getLength();

        String description = rfiItemDes;
        String itemField = '';
        String additional ='';
        String additionalField2 = '';
    
        if(lenOfItemDes > totalLenForItemDes){
            itemField = description.substring(0, totalLenForItemDes);//Data content for RFI Item Description field
            Integer calculatedValue = lenOfItemDes - totalLenForItemDes;//To know balance characters after split
            Integer additionRfiItemDesCheckPoint = totalLenForItemDes+totalLenForAdditionalItemDes;//To split based on the length of Additional RFI ITem Description field 
            //Data content for Additional RFI Item Description field
            additional = (calculatedValue > totalLenForAdditionalItemDes) ? description.substring(totalLenForItemDes+1, additionRfiItemDesCheckPoint) : description.substring(totalLenForItemDes+1, lenOfItemDes);
            Integer totalDesCal = totalLenForItemDes + totalLenForAdditionalItemDes;//To know total characters splitted above
            if(totalDesCal < lenOfItemDes){
                calculatedValue = lenOfItemDes - totalDesCal;//To know balance characters after second split
                Integer additionRfiItemDes2CheckPoint = totalDesCal+totalLenForAdditionalItemDes2;
                additionalField2 = (calculatedValue > totalLenForAdditionalItemDes2) ? description.substring(totalDesCal+1, additionRfiItemDes2CheckPoint) : description.substring(totalDesCal+1, lenOfItemDes);
            }
        }else{
           itemField = description;
        }
    
        if(String.isNotBlank(additional)){
            rfiItemIns.Additional_RFI_Item_Description__c = additional;
        }
        if(String.isNotBlank(additionalField2)){
            rfiItemIns.Additional_RFI_Item_Description_2__c = additionalField2;
        }
        rfiItemIns.RFI_Detail_Description__c = itemField;

        return rfiItemIns;
    }

    public static boolean abSubstationRFICreation(String plantAssetId){
        Savepoint sp = Database.setSavepoint();
        Boolean processCompleted = false;
        try{
            Map<String, RFI_Detail__c> rfiItemList = new Map<String, RFI_Detail__c>();
            RFI__c[] existingRfiRelToPA = [SELECT Id, Account_Plant__c, RFI_Status__c, Account_Plant__r.Asset_Builder_Status__c FROM RFI__c WHERE Account_Plant__c =: plantAssetId AND RFI_Status__c !=: Constants.CLOSED];
            list<RFI_Categories__c> rfiCategories = [SELECT Id, Name, RFI_Category_Status__c 
                        FROM RFI_Categories__c WHERE NAME =: System.Label.SubstationRFICategoryName AND RFI_Category_Status__c = 'Active' AND
                        RecordTypeId =: Utils.getRecordTypeInfo('RFI_Categories__c', ConstantsRecordTypes.RFI_CATEGORY_MISSING_INCOMPLETE_INFORMATION).getRecordTypeId() LIMIT 1];
            List<RFI_Detail__c> rfiDetailsLst = new List<RFI_Detail__c> ();
            RFI__c rfiInstance;
            
            Integer substationSwitchgearCount = 0;
            String renewableType = '';
            
            List<Site_Metadata__c> g1PromptSiteMetadata = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);
            for(Site_Metadata__c g1SiteMetadataSo : g1PromptSiteMetadata){
                Map<String, String> promptSpecificInfoMap = 
                        (Map<String, String>) System.JSON.deserialize(g1SiteMetadataSo.Prompt_Specific_Info__c, Map<String, String>.class);
                if(promptSpecificInfoMap.containsKey(Constants.SWITCHGEAR_SUBSTATION)){        
                    if(!String.isBlank(promptSpecificInfoMap.get(Constants.SWITCHGEAR_SUBSTATION))){
                        substationSwitchgearCount += Integer.valueOf(promptSpecificInfoMap.get(Constants.SWITCHGEAR_SUBSTATION));  
                    }
                }
                
                if(promptSpecificInfoMap.containsKey(Constants.RENEWABLE_TYPE)){        
                    if(!String.isBlank(promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE))){
                        renewableType = promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE);  
                    }
                }
            }

            Integer acCapacity = 0;
            Integer dcCapacity = 0;

            if(substationSwitchgearCount <= 0){
                List<Id> metricList = new list<Id>();
                List<Site_Metadata__c> promptSiteMetadata = new list<Site_Metadata__c>();
                if(renewableType == Constants.SOLAR){
                    promptSiteMetadata = Utils.querySiteMetadata(Constants.P1_PLANT_INFO_PROMPT_SOLAR, plantAssetId);
                }else if(renewableType == Constants.WIND){
                    promptSiteMetadata = Utils.querySiteMetadata(Constants.W1_PLANT_INFO_PROMPT_WIND, plantAssetId);
                }
                if(promptSiteMetadata.size() > 0){
                    for(Site_Metadata__c sitemetadataSO : promptSiteMetadata){
                        Map<String, String> AttributeInfoMap = 
                            (Map<String, String>) System.JSON.deserialize(sitemetadataSO.Attribute_Info__c, Map<String, String>.class);
                        if(AttributeInfoMap.containsKey(Constants.AC_CAPACITY)){
                            if(!String.isBlank(AttributeInfoMap.get(Constants.AC_CAPACITY))){
                                acCapacity = Integer.valueOf(AttributeInfoMap.get(Constants.AC_CAPACITY));  
                            } 
                        }
                        if(AttributeInfoMap.containsKey(Constants.DC_CAPACITY)){
                            if(!String.isBlank(AttributeInfoMap.get(Constants.DC_CAPACITY))){
                                dcCapacity = Integer.valueOf(AttributeInfoMap.get(Constants.DC_CAPACITY));  
                            } 
                        }
                    }
                }
                
                if((acCapacity > Integer.valueOf(System.Label.ACCapacityUnitCheckForSubstationRFI)) || (dcCapacity > Integer.valueOf(System.Label.DCCapacityUnitCheckForSubstationRFI))){
                    Map<String, String> mappingForRequiredFieldsForRFIDetail = Utils.queryABRequiredFields('RFI_Detail__c');
                    SObjectType rfiDetObj = Schema.getGlobalDescribe().get('RFI_Detail__c');
                    Map<String,Schema.SObjectField> rfiDetFields = rfiDetObj.getDescribe().fields.getMap();
                    
                    if(rfiCategories.size() > 0){
                        if(existingRfiRelToPA.size() == 1){
                            rfiDetailsLst = [SELECT Id, RFI_Number__c, RFI_Category__c
                                FROM RFI_Detail__c WHERE RFI_Number__c =: existingRfiRelToPA[0].Id AND RFI_Category__c =: rfiCategories[0].Id
                                AND IsDeleted = false];
                        }

                        if(existingRfiRelToPA.size() == 0){
                            Map<String, String> mappingForRequiredFields = Utils.queryABRequiredFields('RFI__c');
                            SObjectType rfiObj = Schema.getGlobalDescribe().get('RFI__c');
                            Map<String,Schema.SObjectField> rfiFields = rfiObj.getDescribe().fields.getMap();
                            rfiInstance = new RFI__c();

                            for(String rfiRequiredFields : mappingForRequiredFields.keySet()){
                                if(rfiFields.containskey(rfiRequiredFields.toLowerCase())){
                                    rfiInstance.put(rfiRequiredFields, mappingForRequiredFields.get(rfiRequiredFields));
                                }
                            } 

                            rfiInstance.Account_Plant__c = plantAssetId;
                            insert rfiInstance;
                        }else{
                            rfiInstance = existingRfiRelToPA[0];
                        }

                        if(String.isNotBlank(rfiInstance.Id) && (existingRfiRelToPA.size() == 0 || (existingRfiRelToPA.size() == 1 && rfiDetailsLst.size() == 0))){
                            RFI_Detail__c rfiItemIns = new RFI_Detail__c();
                            rfiItemIns.RFI_Number__c = rfiInstance.Id;
                            rfiItemIns.RFI_Category__c = rfiCategories[0].Id;
                            rfiItemIns.Missing_Incomplete_Category__c = rfiCategories[0].Id;
                            rfiItemIns.RFI_Detail_Description__c= System.Label.SubstationRFIItemDescription;
                        
                            //Mapping required fields for RFI Item Object
                            for(String rfiRequiredFields : mappingForRequiredFieldsForRFIDetail.keySet()){
                                if(rfiDetFields.containskey(rfiRequiredFields.toLowerCase())){
                                    rfiItemIns.put(rfiRequiredFields, mappingForRequiredFieldsForRFIDetail.get(rfiRequiredFields));
                                }
                            }
                            rfiItemList.put(rfiCategories[0].Id, rfiItemIns);
                        }
                    }
                }
            }

            if(rfiItemList.size() > 0){
                insert rfiItemList.values();
            }
            processCompleted = true;
        }catch(Exception exceptionDetails){
            processCompleted = false;
            Database.rollback(sp);
            insert Utils.catchErrorLogs('createRFILineItemSubstation',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetId, '');
            System.debug('Error in '+exceptionDetails.getLineNumber()+'-'+exceptionDetails.getMessage());
        }
        return processCompleted;
    }
}