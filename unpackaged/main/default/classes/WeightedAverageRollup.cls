/**
 * TODO - Calls from Site Metadata Trigger when Site Metadata is updated.
 * Perform weighted average calculation and rollup the resultant values to higest parent prompts like P1, W1
 * Attribute will roll up to highest parent sitemetadata occurs only if Attribute Master of child sitemetadata matches with Attribute Master of highest parent sitemetadata.
 * Differentiation of Base attribute and other attribute for calculation is, Base attribute is mainly used for calculation and other attributes will mulitplied with base attribute.
 * For eg, For subarray prompt, DC Capacity is base attribute, and TCOEF, GCR and MOUNTING TILT are considered as other attributes.
 * */ 
public with sharing class WeightedAverageRollup {
    public static DateTime lastPromptInitiatedIdRef;
    public static String plantAssetIdRef;
    public static String plantAssetPromptDetailIdRef;
    public static Plant_Asset_Prompt_Detail__c pltAstPrtDtl;
    public static Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail;
    public static Set<String> attrSet;
    /*
    * To get attribute and attribute value relate to base asset template for weighted average calculation
    * @param {List<Id>} promptInfoIds - List of Site prompt infomation needed for rollup process.
    * @param {DateTime} lastPromptInitiatedId - Initiated date and time for track the execution process.
    * @param {String} plantAssetPromptDetail - Track updates of Attribute value Creation/Updation against Plant Asset.
    * @param {String} plantAssetId - Attribute Value against Plant Asset
    */
    public static void formMapForRollup(List<Id> promptInfoIds, DateTime lastPromptInitiatedId, String plantAssetPromptDetail, String plantAssetId){
        pltAstPrtDtl = [SELECT Id, Name, Prompt_Information__r.Name, Last_Rollup_To_P1W1_Process_Initiated_DT__c  FROM Plant_Asset_Prompt_Detail__c WHERE Id =: plantAssetPromptDetail AND Is_Deleted__c = FALSE];
        
        if(pltAstPrtDtl.Prompt_Information__r.Name == Constants.P7_INVERTER_SUBARRAY_INFO){
            g1PlantAssetPromptDetail = [SELECT id,Is_WA_RollUp_Not_Executed__c
                                        FROM Plant_Asset_Prompt_Detail__c
                                        WHERE Account_Plant__c =: plantAssetId AND 
                                        Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND 
                                        Is_Deleted__c = FALSE LIMIT 1];
            
            if(!g1PlantAssetPromptDetail.Is_WA_RollUp_Not_Executed__c){
                g1PlantAssetPromptDetail.Is_WA_RollUp_Not_Executed__c = true;    
                update g1PlantAssetPromptDetail;
            }
        }
        
        try{
            lastPromptInitiatedIdRef = lastPromptInitiatedId;
            plantAssetIdRef = plantAssetId;
            plantAssetPromptDetailIdRef = plantAssetPromptDetail;
            promptInfoIds = promptInfoIds;
            attrSet = new Set<String>();

            Set<Id> baseAssetIdList = new Set<Id>();
            List<Site_Metadata__c> siteMetaLst = new List<Site_Metadata__c>();
            for(Site_Metadata__c siteMetaDataInstance : [SELECT Id,Base_Asset_Template__c,Account_Plant__c,Prompt_Information__c,Plant_Asset_Prompt_Detail__r.Is_Deleted__c FROM Site_Metadata__c  WHERE Prompt_Information__c IN: promptInfoIds AND Account_Plant__c =: plantAssetIdRef AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = FALSE]){
				//To get base asset template               
				if(String.isNotBlank(siteMetaDataInstance.Base_Asset_Template__c)){
					baseAssetIdList.add(siteMetaDataInstance.Base_Asset_Template__c);
				}
				siteMetaLst.add(siteMetaDataInstance);
            }

            Set<String> coreAttrLst = new Set<String>();
            //Get all core attributes related to weighted average 
            for(Core_Attribute__c coreAttributeInstance :  [SELECT Id, Name, Base_Asset_Name__c, Attribute_Master__r.Name, Rollup_To_Parent__c, Attribute_Master__r.Data_Type__c, Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name, Base_Attribute_For_Weighted_Average_Calc__r.Data_Type__c, Base_Attribute_For_Weighted_Average_Calc__c FROM Core_Attribute__c WHERE Is_Rollup_To_P1_W1__c = true AND Base_Asset_Name__c IN: baseAssetIdList]){
                coreAttrLst.add(coreAttributeInstance.Id);
                if(!coreAttrLst.contains(coreAttributeInstance.Base_Attribute_For_Weighted_Average_Calc__c)){
                    coreAttrLst.add(coreAttributeInstance.Base_Attribute_For_Weighted_Average_Calc__c);
                }
            }
            
            Map<String, String> mapBaseAttrWithValue = new Map<String, String> ();//To get base attribute value
            //To get attributes value for calculation,like Map<baseAsset_rollupprompt, Map<baseAttri, Map<siteMetadata, Map<attrName, value>>>>
            Map<String, Map<String, Map<String, Map<String, String>>>> attributeForCalculation = new Map<String, Map<String, Map<String, Map<String, String>>>>();
            Map<String, Map<String, String>> baseAttribute = new Map<String, Map<String, String>>();//To get total sum of base attribute related to base asset template, like Map<baseAssetTemplate, Map<baseAttrName, totalSum>>>
            Set<String> siteMetadataLst = new Set<String>();
            String baseAttr = '';//To store base attribute name
            
            for(Attribute_Value__c attValIns : [SELECT Id, Name, Attribute__r.Is_Rollup_To_P1_W1__c, Site_Metadata__c, Site_Metadata__r.Plant_Asset_Prompt_Detail__r.Is_Deleted__c, Base_Asset_Template__c, Attribute__r.Rollup_To_Parent__c, Attribute__r.Attribute_Master__r.Name, Value__c, Attribute__r.Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name FROM Attribute_Value__c WHERE Account_Plant__c =: plantAssetIdRef AND Prompt_Information__c IN: promptInfoIds AND Attribute__c IN: coreAttrLst
                                                AND Site_Metadata__r.Plant_Asset_Prompt_Detail__r.Is_Deleted__c = FALSE]){
                
                String combinationOfBaseAssetAndPromptToRollup = attValIns.Base_Asset_Template__c+'-'+attValIns.Attribute__r.Rollup_To_Parent__c;
                String siteMetada = String.valueOf(attValIns.Site_Metadata__c);
               
                //to get values of attributes based on base asset and base attribute
                if(String.isNotBlank(attValIns.Attribute__r.Base_Attribute_For_Weighted_Average_Calc__c)){
                    if(!attributeForCalculation.containskey(combinationOfBaseAssetAndPromptToRollup)){
                        attributeForCalculation.put(combinationOfBaseAssetAndPromptToRollup, new Map<String, Map<String, Map<String, String>>>());
                    }   
                    if(!attributeForCalculation.get(combinationOfBaseAssetAndPromptToRollup).containskey(attValIns.Attribute__r.Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name)){
                        attributeForCalculation.get(combinationOfBaseAssetAndPromptToRollup).put(attValIns.Attribute__r.Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name, new Map<String, Map<String, String>>());
                        baseAttr = attValIns.Attribute__r.Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name;
                    }   
                    if(!attributeForCalculation.get(combinationOfBaseAssetAndPromptToRollup).get(attValIns.Attribute__r.Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name).containskey(siteMetada)){
                        attributeForCalculation.get(combinationOfBaseAssetAndPromptToRollup).get(attValIns.Attribute__r.Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name).put(String.valueOf(attValIns.Site_Metadata__c), new Map<String, String>());
                        
                    }
                    if(!attributeForCalculation.get(combinationOfBaseAssetAndPromptToRollup).get(attValIns.Attribute__r.Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name).get(siteMetada).containskey(attValIns.Attribute__r.Attribute_Master__r.Name)){
                        String attrVal = (String.isBlank(attValIns.Value__c)) ? '0.00' : String.valueOf(attValIns.Value__c);
                        attributeForCalculation.get(combinationOfBaseAssetAndPromptToRollup).get(attValIns.Attribute__r.Base_Attribute_For_Weighted_Average_Calc__r.Attribute_Master__r.Name).get(siteMetada).put(attValIns.Attribute__r.Attribute_Master__r.Name, attrVal);
                    }
                } 

                //compate base attribute name and iterating attribute value's attribute
                if(baseAttr == attValIns.Attribute__r.Attribute_Master__r.Name){
                    mapBaseAttrWithValue.put(attValIns.Base_Asset_Template__c+'-'+siteMetada, String.valueOf(attValIns.Value__c));
                }

                //For total calculation of base attribute based on base asset template
                if(!siteMetadataLst.contains(siteMetada) && attValIns.Attribute__r.Is_Rollup_To_P1_W1__c == false){
                    siteMetadataLst.add(siteMetada);
                    if(!baseAttribute.containskey(attValIns.Base_Asset_Template__c)){
                        baseAttribute.put(attValIns.Base_Asset_Template__c, new Map<String, String>());
                    } 
                    if(!baseAttribute.get(attValIns.Base_Asset_Template__c).containskey(attValIns.Attribute__r.Attribute_Master__r.Name)){
                        baseAttribute.get(attValIns.Base_Asset_Template__c).put(attValIns.Attribute__r.Attribute_Master__r.Name, '');
                    } 
                    if(baseAttribute.get(attValIns.Base_Asset_Template__c).containskey(attValIns.Attribute__r.Attribute_Master__r.Name)){
                        if(String.isBlank(baseAttribute.get(attValIns.Base_Asset_Template__c).get(attValIns.Attribute__r.Attribute_Master__r.Name))){
                            String attrVal = (String.isBlank(attValIns.Value__c)) ? '0.00' : String.valueOf(attValIns.Value__c);
                            baseAttribute.get(attValIns.Base_Asset_Template__c).put(attValIns.Attribute__r.Attribute_Master__r.Name, attrVal);
                        }else{
                            Decimal existingValue = Decimal.valueOf(baseAttribute.get(attValIns.Base_Asset_Template__c).get(attValIns.Attribute__r.Attribute_Master__r.Name));
                            Decimal currentValue = (String.isBlank(attValIns.Value__c)) ? 0.00 : Decimal.valueOf(attValIns.Value__c);
                            baseAttribute.get(attValIns.Base_Asset_Template__c).put(attValIns.Attribute__r.Attribute_Master__r.Name, String.valueOf(existingValue + currentValue));
                        }
                    }
                }
            }
            
            //Check the sum of base attribute is greater than 0
            for(String baseAssetTemplate : baseAttribute.keySet()){
                Map<String, Map<String, String>> baseAttributeWithTotalVal = new Map<String, Map<String, String>>();
                baseAttributeWithTotalVal.put(baseAssetTemplate, new Map<String, String>());
                for(String baseAttrName : baseAttribute.get(baseAssetTemplate).keySet()){
                    if(Decimal.valueOf(baseAttribute.get(baseAssetTemplate).get(baseAttrName)) > 0.00){
                        baseAttributeWithTotalVal.get(baseAssetTemplate).put(baseAttr, baseAttribute.get(baseAssetTemplate).get(baseAttrName)); 
                        calculateAttrBasedOnBaseAttr(baseAttributeWithTotalVal, attributeForCalculation, mapBaseAttrWithValue);
                    }
                }
            }
           
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            insert  Utils.catchErrorLogs('formMapForRollup',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetailIdRef);
        }
    }
    /*
    * Calculation of single base attribute value with total sum of base attribute
    * @param {Map<String, Map<String, String>>} baseAttribute - base attribute list with total value
    * @param {Map<String, Map<String, Map<String, String>>>} attributeForCalculation - attributes with their respective values
    */
    public static void calculateAttrBasedOnBaseAttr(Map<String, Map<String, String>> baseAttribute, Map<String, Map<String, Map<String, Map<String, String>>>> attributeForCalculation, Map<String, String> mapBaseAttrWithValue){
        try{
            //to store the final calculated value, like Map<baseAssetTemplate, Map<attributeName, totalValueToRollup>>
            Map<String, Map<String, String>> finalValueToPromptUpdate = new Map<String, Map<String, String>>();
            for(String baseAssetTemplate : baseAttribute.keySet()){
                for(String baseAttrName : baseAttribute.get(baseAssetTemplate).keySet()){
                    //To get sum Of BaseAttribute 
                    Decimal baseAttrTotalVal = Decimal.valueOf(baseAttribute.get(baseAssetTemplate).get(baseAttrName));
                    for(String baseAsset : attributeForCalculation.keySet()){
                        List<String> baseAssetSplit = baseAsset.split('-');
                        if((baseAssetSplit[0] == baseAssetTemplate) && (attributeForCalculation.get(baseAsset).containskey(baseAttrName))){
                            for(String sitemetadata : attributeForCalculation.get(baseAsset).get(baseAttrName).keySet()){
                                //To divide value of single base attribute from sitemetadata with sumOfBaseattribute 
                                String combineVal = baseAssetSplit[0]+'-'+sitemetadata;
                                if(mapBaseAttrWithValue.containskey(combineVal)){
                                    if(String.isNotBlank(mapBaseAttrWithValue.get(combineVal))){
                                        Decimal baseAttrVal = Decimal.valueOf((mapBaseAttrWithValue.get(combineVal)));
                                        Decimal dividedValOfBaseAttr = baseAttrVal/baseAttrTotalVal;
                                        Map<String, String> attrWithValues = attributeForCalculation.get(baseAsset).get(baseAttrName).get(sitemetadata);
                                        finalValueToPromptUpdate = calculateAttributeWithDividedValOfBaseAttr(baseAsset, attrWithValues, dividedValOfBaseAttr, finalValueToPromptUpdate);    
                                    }
                                }
                            }
                        }
                    }

                }
            }
            updateHighestPrompt(finalValueToPromptUpdate);
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            insert Utils.catchErrorLogs('calculateAttrBasedOnBaseAttr',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetIdRef, plantAssetPromptDetailIdRef);
        }
    }
    /*
    * Calculation of other attribute value with divided value of base attribute
    * @param {String} baseAssetTemplate - base asset template to be processed
    * @param {Map<String, String>} attrWithValues - attribue values for calculation 
    * @param {Decimal} dividedValOfBaseAttr - value to be divided with other base attribute value
    * @param {Map<String, Map<String, String>>} finalValueToPromptUpdate - final list for update parent prompt
    */
    public static Map<String, Map<String, String>> calculateAttributeWithDividedValOfBaseAttr(String baseAssetTemplate, Map<String, String> attrWithValues, Decimal dividedValOfBaseAttr, Map<String, Map<String, String>> finalValueToPromptUpdate){
		try{
            for(String attrName : attrWithValues.keySet()){
                if(Decimal.valueOf(attrWithValues.get(attrName)) <= 0){
                    attrSet.add(attrName);
                }
            }
            for(String attrName : attrWithValues.keySet()){
                
                //To multiply the divided value with other attributes
                if(!attrSet.Contains(attrName)){
                    Decimal multipliedValOfSingleAttr = Decimal.valueOf(attrWithValues.get(attrName)) * dividedValOfBaseAttr;
                    if(!finalValueToPromptUpdate.containskey(baseAssetTemplate)){
                        finalValueToPromptUpdate.put(baseAssetTemplate, new Map<String, String>());
                    } 
                    if(!finalValueToPromptUpdate.get(baseAssetTemplate).containsKey(attrName)){
                        finalValueToPromptUpdate.get(baseAssetTemplate).put(attrName, String.valueOf(multipliedValOfSingleAttr));
                    }else{
                        //For sum calculation for other attributes
                        Decimal existingValue = Decimal.valueOf(finalValueToPromptUpdate.get(baseAssetTemplate).get(attrName));
                        Decimal finalValue = multipliedValOfSingleAttr + existingValue;
                        finalValueToPromptUpdate.get(baseAssetTemplate).put(attrName, String.valueOf(finalValue));
                    }
                }else{
                    if(!finalValueToPromptUpdate.containskey(baseAssetTemplate)){
                        finalValueToPromptUpdate.put(baseAssetTemplate, new Map<String, String>());
                    } 
                    finalValueToPromptUpdate.get(baseAssetTemplate).put(attrName, '');
                }
            }
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            insert Utils.catchErrorLogs('calculateAttributeWithDividedValOfBaseAttr',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetIdRef, plantAssetPromptDetailIdRef);
        }
        return finalValueToPromptUpdate;
    }
    /*
    * Updation of caluculated value in higest parent prompts
    * @param {Map<String, Map<String, String>>} finalValueToPromptUpdate - Map of calculated values for attributes
    */
    public static void updateHighestPrompt(Map<String, Map<String, String>> finalValueToPromptUpdate){
		try{
            List<String> promptInforToUpdate = new List<String>();
            for(String combinationOfBaseAssetAndParentPrompt : finalValueToPromptUpdate.keySet()){
                String promptInfoId = combinationOfBaseAssetAndParentPrompt.split('-')[1];
                promptInforToUpdate.add(promptInfoId.trim());
            }

            //get Parent_Site_Metadata__c for value update
            List<Site_Metadata__c> parentSiteMetaData = [SELECT Id, Name, Parent_Site_Metadata__c, Base_Asset_Template__c, Attribute_Info__c, Prompt_Information__c 
            FROM Site_Metadata__c 
            WHERE  Prompt_Information__c IN: promptInforToUpdate AND Account_Plant__c =: plantAssetIdRef];
            for(Site_Metadata__c siteMetadataIns :parentSiteMetaData){
                Map<String, String> parentAttrInfoList = (Map<String, String>)JSON.deserialize(siteMetadataIns.Attribute_Info__c,Map<String, String>.class);
                
                //iterate all final values
                for(String combinationOfBaseAssetAndPrompt : finalValueToPromptUpdate.keySet()){
                    String promptInfo = combinationOfBaseAssetAndPrompt.split('-')[1];
                    //compare the prompt information of parent sitemetadata and prompt information in final list 
                    if(promptInfo == siteMetadataIns.Prompt_Information__c){
                        for(String attrName : finalValueToPromptUpdate.get(combinationOfBaseAssetAndPrompt).keySet()){
                            if(parentAttrInfoList.containskey(attrName)){
                                String currentValue = finalValueToPromptUpdate.get(combinationOfBaseAssetAndPrompt).get(attrName);
                                if(!String.isBlank(currentValue)){
                                    Decimal currentValAsDecimal = Decimal.valueOf(currentValue);
                                    parentAttrInfoList.remove(attrName);
                                    parentAttrInfoList.put(attrName, String.valueOf(currentValAsDecimal.setScale(4)));
                                }else{
                                    parentAttrInfoList.remove(attrName);
                                    parentAttrInfoList.put(attrName, '');
                                }
                                
                            }
                        }
                        siteMetadataIns.Attribute_Info__c = JSON.serialize(parentAttrInfoList); 
                    }
                }

            }

            pltAstPrtDtl.Last_Rollup_To_P1W1_Process_Initiated_DT__c = lastPromptInitiatedIdRef;
            if(parentSiteMetaData.size() > 0){
                update parentSiteMetaData;
                update pltAstPrtDtl;
                if(pltAstPrtDtl.Prompt_Information__r.Name == Constants.P7_INVERTER_SUBARRAY_INFO){
                    g1PlantAssetPromptDetail = [SELECT id,Is_WA_RollUp_Not_Executed__c
                                                FROM Plant_Asset_Prompt_Detail__c
                                                WHERE Account_Plant__c =: plantAssetIdRef AND 
                                                Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND 
                                                Is_Deleted__c = FALSE LIMIT 1];
                    
                    if(g1PlantAssetPromptDetail.Is_WA_RollUp_Not_Executed__c){
                        g1PlantAssetPromptDetail.Is_WA_RollUp_Not_Executed__c = false;    
                        update g1PlantAssetPromptDetail;
                    }
                }
            }
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            insert Utils.catchErrorLogs('updateHighestPrompt',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetIdRef, plantAssetPromptDetailIdRef);
        }
	}
}