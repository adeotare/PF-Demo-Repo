/**
 * TODO - Calls from SiteMetaDataHandler when Site Metadata is created or updated.
 * Metric Value is created based on Metric Definition
 * */
public with sharing class MetricValueDataCreation {
    public static DateTime lastPromptInitiatedId;
    public static String plantAssetPromptDetail;
    public static String plantAssetId;
    public static Plant_Asset_Prompt_Detail__c pltAstPrtDtl;
    /*
    * Metric Definition and Attributes is queried based on the base asset template. A string is form with combination of Modifiers.
    * The queried information pass to mapFormationForMetricValue method to form map
    * @param {List<Id>} siteMetaDataIdLst - List of Site Metadata need for creation or updation of Attribute Value.
    * @param {DateTime} lastPromptInitiatedId - Initiated date and time for track the process execute after insertion/updation of Site Metadata.
    * @param {String} plantAssetPromptDetail - Track updates of Attribute value and store in G1 Plant Asset Prompt Detail Plant Asset.
    * @param {String} plantAssetId - Attribute Value against Plant Asset.
    */
    public static void queryBaseAssetCoreAttrBasedOnMetricDef(List<Id> metricDefId,  DateTime lastPromptInitiatedId, 
        String plantAssetPromptDetail, String plantAssetId){
        Map<String, List<Id>> bat_caLst = new Map<String, List<Id>>();
        Set<String> mod1_mod2Lst = new Set<String>();
        Boolean result = true;
        Savepoint sp;

        try{
            lastPromptInitiatedId = lastPromptInitiatedId;
            plantAssetPromptDetail = plantAssetPromptDetail;
            plantAssetId = plantAssetId;
           
			pltAstPrtDtl = [SELECT Id, Name,Last_Metric_Value_Process_Initiated_DT__c
                    FROM Plant_Asset_Prompt_Detail__c 
                    WHERE Id =: plantAssetPromptDetail AND Is_Deleted__c = FALSE];
            

            List<Metric_Definition__c> metricList = new List<Metric_Definition__c>([SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
                WHERE Id IN: metricDefId]);
            
                if(metricList.size() >0){
                for(Metric_Definition__c metricInstance : metricList){
                    if(!bat_caLst.containsKey(metricInstance.Base_Asset_Template__c)){
                        List<Id> coreAttrList = new List<Id>();
                        coreAttrList.add(metricInstance.Attribute__c);
                        bat_caLst.put(String.valueOf(metricInstance.Base_Asset_Template__c), coreAttrList);
                    }else if(!bat_caLst.get(metricInstance.Base_Asset_Template__c).contains(metricInstance.Attribute__c)) {
                        List<Id> coreAttrList = bat_caLst.get(metricInstance.Base_Asset_Template__c);
                        coreAttrList.add(metricInstance.Attribute__c);
                    }
                    //To calculate multiple aggregate combination for Metric Definition
                    String str = (!String.isBlank(metricInstance.Modifer_1__c) && String.isBlank(metricInstance.Modifer_2__c))? metricInstance.Modifer_1__c:(metricInstance.Modifer_1__c+'-'+metricInstance.Modifer_2__c+'-'+metricInstance.Modifer_2_Value__c);
                    mod1_mod2Lst.add(str);
                }

                List<String> baseAssetIdLst = new List<String>(bat_caLst.keySet());
                List<Id> coreAttrId = new List<Id>();
        
                for(List<Id> idInst : bat_caLst.values()){
                    coreAttrId.addAll(idInst);
                }
                
                result = mapFormationForMetricValue(baseAssetIdLst, coreAttrId, plantAssetId, mod1_mod2Lst, metricList);
                
            }
            //Update the Plant Asset Prompt Detail to track the creation process
            pltAstPrtDtl.Last_Metric_Value_Process_Initiated_DT__c =(result) ? lastPromptInitiatedId : null;
            update pltAstPrtDtl;
        }catch(Exception exceptionDetails){
            
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('queryBaseAssetCoreAttrBasedOnMetricDef',exceptionDetails.getMessage(), 
                exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetail);
            insert errorLogInstance;
        }
    }
    /*
    * Metric Definition and Attributes is queried based on the base asset template. A string is form with combination of Modifiers.
    * The queried information pass to mapFormationForMetricValue method to form map.
    * @param {List<Id>} baseAssetIdLst - List of Base Assets need for creation or updation of Metric Value.
    * @param {List<Id>} coreAttrId - List of Attribute need for specific Metric Definition.
    * @param {String} plantAssetId - Metric Value against Plant Asset.
    * @param {Set<String>} mod1_mod2Lst - Combination of modifiers combination.
    * @param {List<Metric_Definition__c>} metricList - Metric Definition for particular Base Asset Template.
    */
    public static Boolean mapFormationForMetricValue(List<Id> baseAssetIdLst, List<Id> coreAttrId, String plantAssetId, Set<String> mod1_mod2Lst, List<Metric_Definition__c> metricList){
        Savepoint sp = Database.setSavepoint();
        Boolean result = false;
        try{
            List<Attribute_Value__c> attrLst = new List<Attribute_Value__c>([SELECT Id,Attr_Name__c,Attribute__c,Attribute__r.Attribute_Master__r.Data_Type__c,Name,Base_Asset_Template__c,
                Is_Completed__c, Is_Value_Defaulted__c,Account_Plant__c,Prompt_Information__c,Site_Metadata__c,Value__c,Value_Checkbox__c,Value_Date__c,Site_Metadata__r.Plant_Asset_Prompt_Detail__r.Is_Deleted__c,
                Value_Floating__c,Value_Number__c FROM Attribute_Value__c 
                WHERE Base_Asset_Template__c IN: baseAssetIdLst AND  Attribute__c IN: coreAttrId AND Account_Plant__c =:plantAssetId AND Site_Metadata__r.Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false ORDER BY Base_Asset_Template__c, Attribute__c]);
            
            Map<String, Map<String,Map<String, String>>> mapForMetricValueCreation = new Map<String, Map<String,Map<String, String>>>();
            Map<String, Map<String,Map<String, List<String>>>> mapForMetricValueCreationLst = new Map<String, Map<String,Map<String, List<String>>>>();
            List<String> strLst = new List<String>();

            for(Attribute_Value__c attrValueInstance : attrLst){
                
                for(String mod1_mod2 : mod1_mod2Lst){
                    if(!mapForMetricValueCreation.containsKey(attrValueInstance.Base_Asset_Template__c)){
                        mapForMetricValueCreation.put(String.valueOf(attrValueInstance.Base_Asset_Template__c), new Map<String,Map<String,String>>());
                        mapForMetricValueCreationLst.put(String.valueOf(attrValueInstance.Base_Asset_Template__c), new Map<String,Map<String,List<String>>>());
                    }
                    //Form a map contains attribute related to specific base asset template
                    if(!mapForMetricValueCreation.get(attrValueInstance.Base_Asset_Template__c).containsKey(attrValueInstance.Attribute__c)){
                        mapForMetricValueCreation.get(attrValueInstance.Base_Asset_Template__c).put(String.valueOf(attrValueInstance.Attribute__c), new Map<String,String>());
                        mapForMetricValueCreationLst.get(attrValueInstance.Base_Asset_Template__c).put(String.valueOf(attrValueInstance.Attribute__c),new Map<String, List<String>>());
                    }
                    //Form a map contains aggregate result value related to specific modifiers
                    if(!mapForMetricValueCreation.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).containsKey(mod1_mod2)){
                        if(mod1_mod2.startsWith('VALUES')|| mod1_mod2.startsWith('MIN') || mod1_mod2.startsWith('MAX')){
                            //Add Attribute Value as value in Map to find MIN, MAX and VALUES
                            mapForMetricValueCreation.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).put(mod1_mod2, attrValueInstance.Value__c);
                            mapForMetricValueCreationLst.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).put(mod1_mod2, new List<String>());
                        }else{
                            //Add 0 as value in Map to find number of count
                            mapForMetricValueCreation.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).put(mod1_mod2, '0');
                            mapForMetricValueCreationLst.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).put(mod1_mod2, new List<String>());
                        }
                    }
                    
                    List<String > strlstValue = mapForMetricValueCreationLst.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).get(mod1_mod2);
                    strlstValue.add(attrValueInstance.Value__c);
                    //Add list of Values to find AVG and Count of Unique value
                    mapForMetricValueCreationLst.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).put(mod1_mod2,strlstValue);
                    String modValue = mapForMetricValueCreation.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).get(mod1_mod2);
                    String finalValue = aggregateFunctions(attrValueInstance, mod1_mod2, modValue, strlstValue);
                    //Update the resultant value to the map for metric value creation
                    mapForMetricValueCreation.get(attrValueInstance.Base_Asset_Template__c).get(attrValueInstance.Attribute__c).put(mod1_mod2,finalValue);
                }
            }
            result = insertionOfMetricValue(metricList, mapForMetricValueCreation, plantAssetId);
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            result = false;
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('mapFormationForMetricValue',exceptionDetails.getMessage(), 
                exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetail);
            insert errorLogInstance;
        }
        return result;
    }
    /*
    * Creation/Updation of Metric Value.
    * @param {List<Metric_Definition__c>} metricList - List of Metric Definition for creation or updation of Metric Value.
    * @param {Map<String, Map<String,Map<String, String>>>} mapForMetricValueCreation - Combination of Base Asset, Attributes and Metric Definiton.
    * @param {String} plantAssetId - Metric Value against Plant Asset.
    */
    public static Boolean insertionOfMetricValue(List<Metric_Definition__c> metricList, 
        Map<String, Map<String,Map<String, String>>> mapForMetricValueCreation, String plantAssetId){
        Savepoint sp;
        Boolean result = false;
        try{
            List<Metric_Value__c> metricValueLst = new List<Metric_Value__c>();
    
            for(Metric_Definition__c metricDefIns : metricList){
                String modifier = (!String.isBlank(metricDefIns.Modifer_1__c) && String.isBlank(metricDefIns.Modifer_2__c))? metricDefIns.Modifer_1__c:(metricDefIns.Modifer_1__c+'-'+metricDefIns.Modifer_2__c+'-'+metricDefIns.Modifer_2_Value__c);
                if(mapForMetricValueCreation.containsKey(metricDefIns.Base_Asset_Template__c)){
                    if(mapForMetricValueCreation.get(metricDefIns.Base_Asset_Template__c).containsKey(metricDefIns.Attribute__c)){
                        if(mapForMetricValueCreation.get(metricDefIns.Base_Asset_Template__c).get(metricDefIns.Attribute__c).containsKey(modifier)){
                            String finalValues = mapForMetricValueCreation.get(metricDefIns.Base_Asset_Template__c).get(metricDefIns.Attribute__c).get(modifier);
                            Metric_Value__c metricValue = new Metric_Value__c();
                            metricValue.Metric_Definition__c = metricDefIns.Id;
                            metricValue.External_ID__c = plantAssetId+'-'+metricDefIns.Id+'-'+metricDefIns.Base_Asset_Template__c+'-'+metricDefIns.Attribute__c+'-'+modifier;
                            metricValue.Account_Plant__c = plantAssetId;
                            metricValue.Data_Type__c= metricDefIns.Attribute__r.Attribute_Master__r.Data_Type__c;
                            metricValue.Value__c = finalValues;
                            metricValueLst.add(metricValue);
                        }
                    }
                }
            }
            if(metricValueLst.size()>0){
               Upsert metricValueLst External_ID__c;
               result = true;
            }
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('insertionOfMetricValue',exceptionDetails.getMessage(), 
                exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetail);
            insert errorLogInstance;
        }
        return result;
    }
    /*
    * Execution of Aggregrate Logic. 
    * @param {Attribute_Value__c} attrValue - Attribute Value for comparision.
    * @param {String} mod1_mod2 - Combination of Modifiers.
    * @param {String} modValue - Existing Value for the combinations.
    * @param {List<String>} stringLst - List of Values for calculation.
    */
    public static String aggregateFunctions(Attribute_Value__c attrValue, String mod1_mod2, String modValue, List<String> stringLst){
        String finalValue = '';
        String mod1;
        String mod2;
        String mod3;
        try{
            if(mod1_mod2.contains('-')){
                List<String> str = mod1_mod2.split('-');
                if(str.size() == 3){
                    mod1 = str[0];
                    mod2 = str[1];
                    mod3 = str[2];
                }else{
                    mod1 = str[0];
                    mod2 = str[1];
                }
            }else{
                mod1 = mod1_mod2;
            }
            if(mod1 == 'VALUES'){
                finalValue = attrValue.Value__c;
            }
            if(mod1 == 'SUM'){
                finalValue = findSum(attrValue, modValue);
            }
            if(mod1 == 'COUNT'){
                finalValue = findCount(attrValue, modValue, mod2, mod3, stringLst);
            }
            if(mod1 == 'MIN'){
                finalValue = findMin(attrValue, modValue, stringLst);
            }
            if(mod1 == 'MAX'){
                finalValue = findMax(attrValue, modValue, stringLst);
            }
            if(mod1 == 'AVG'){
                finalValue = findAvg(attrValue, modValue, stringLst);
            }
            
        }catch(Exception exceptionDetails){
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('insertionOfMetricValue',exceptionDetails.getMessage(), 
                exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetail);
            insert errorLogInstance;
        }
        return finalValue;
    }
    
    /*
    * For SUM aggregate funtion 
    * @param {Attribute_Value__c} attrValue - Attribute Value for comparision.
    * @param {String} modValue - Existing value for logic.
    */
    public static String findSum(Attribute_Value__c attrValue, String modValue){
        String finalValue;
        Decimal sumOfValues = 0.0 ;
        if(attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Decimal'){
            if((String.isNotBlank(modValue)) && (modValue != null)&&(attrValue.Value_Floating__c != null)){
                sumOfValues = Decimal.valueOf(modValue);
                sumOfValues = sumOfValues + attrValue.Value_Floating__c;
                finalValue = String.valueOf(sumOfValues);
            }else{
                finalValue = modValue;
            } 
        }else if(attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Number'){
            if( String.isNotBlank(modValue) && (modValue != null)&&(attrValue.Value_Number__c != null)){
                sumOfValues = Decimal.valueOf(modValue);
                sumOfValues = sumOfValues + attrValue.Value_Number__c; 
                finalValue = String.valueOf(sumOfValues);
            }else {
                finalValue = modValue;
            }
        }
        return finalValue;
    }
    /*
    * For AVG aggregate funtion 
    * @param {Attribute_Value__c} attrValue - Attribute Value for comparision.
    * @param {String} modValue - Existing value for logic.
    * @param {List<String>} stringLst - List of Value.
    */
    public static String findAvg(Attribute_Value__c attrValue, String modValue, List<String> stringLst){
        String finalValue;
        Integer totalCount=0;
        Decimal sum=0;
        for(String str : stringLst){
            if(str != null && ((attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Number') || (attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Decimal'))){
                sum = sum + Decimal.valueOf(str);
                totalCount++;
            }else{
                finalValue = modValue;
            } 
        }
        if(totalCount > 0){
            finalValue = String.valueOf(sum/totalCount);
        }
        return finalValue;
    }
    /*
    * For COUNT aggregate funtion 
    * @param {Attribute_Value__c} attrValue - Attribute Value for comparision.
    * @param {String} modValue - Existing value for logic.
    * @param {String} mod2 - Value of Modifier 2 field.
    * @param {String} mod3 - Value of Modifier 2 Value field.
    * @param {List<String>} stringLst - List of Value.
    */
    public static String findCount(Attribute_Value__c attrValue, String modValue, String mod2, String mod3, List<String> stringLst){
        String finalValue;
        Integer countValues=0;
        if(mod2 == 'NULL'){
            countValues=Integer.valueOf(modValue);
            if(String.isBlank(attrValue.Value__c)){
                countValues++;
            }
            finalValue = String.valueOf(countValues);
        }
       	if(mod2 == 'VALUE'){            
            String mod2Value = mod3;
            countValues=Integer.valueOf(modValue);
            if(attrValue.Value__c == mod2Value){
                countValues++;
            }
            finalValue = String.valueOf(countValues);
        }
        if(mod2 == 'UNIQUE'){
            countValues=Integer.valueOf(modValue);
            List<String> str = new List<String>();
            for(Integer i=0;i<stringLst.size()-1; i++){
                str.add(stringLst[i]);
            }
            if(!str.contains(attrValue.Value__c) && (attrValue.Value__c!= null)){
                countValues++;
            }
            finalValue = String.valueOf(countValues);
        }
        if(mod2 == 'TOTAL'){
            countValues=Integer.valueOf(modValue);
            countValues++;
            finalValue = String.valueOf(countValues);
        }
        return finalValue;
    }
    /*
    * For MINIMUM aggregate funtion
    * @param {Attribute_Value__c} attrValue - Attribute Value for comparision.
    * @param {String} modValue - Existing value for logic.
    * @param {List<String>} stringLst - List of Value.
    */
    public static String findMin(Attribute_Value__c attrValue, String modValue, List<String> stringLst){
        String finalValue;
        if((attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Decimal') && ((String.isNotBlank(modValue)) && (modValue != null)&&(attrValue.Value_Floating__c != null))){
            Decimal minValue = Decimal.valueOf(modValue);
            if(attrValue.Value_Floating__c<minValue){
                minValue = attrValue.Value_Floating__c;
            }
            finalValue = String.valueOf(minValue);
        }else if(attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Decimal'){
            finalValue = modValue;
        }
        if((attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Number') && ((String.isNotBlank(modValue)) && (modValue != null)&&(attrValue.Value_Number__c != null))){
            Decimal minValue = Decimal.valueOf(modValue);
            if(attrValue.Value_Number__c<minValue){
                minValue = attrValue.Value_Number__c;
            }
            finalValue = String.valueOf(minValue);
        }else if(attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Number'){
            finalValue = modValue;
        }
        if((attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Date') && ((String.isNotBlank(modValue)) && (modValue != null)&&(attrValue.Value_Date__c != null))){
            Date dateValue;
            if(stringLst.size()==1){
                dateValue =  Date.parse(modValue);
            }else{
                dateValue =  Date.valueOf(modValue);
            }
            
            if(attrValue.Value_Date__c<dateValue){
                dateValue = attrValue.Value_Date__c;
            }
            finalValue = String.valueOf(dateValue);
        }else if(attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Date'){
            finalValue = modValue;
        }
        return finalValue;
    }
    /*
    * For MAXIMUM aggregate funtion
    * @param {Attribute_Value__c} attrValue - Attribute Value for comparision.
    * @param {String} modValue - Existing value for logic.
    * @param {List<String>} stringLst - List of Value.
    */
    public static String findMax(Attribute_Value__c attrValue, String modValue, List<String> stringLst){
        String finalValue;
        if((attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Decimal') && ((String.isNotBlank(modValue)) && (modValue != null)&&(attrValue.Value_Floating__c != null))){
            Decimal maxValue = Decimal.valueOf(modValue);
            if(attrValue.Value_Floating__c>maxValue){
                maxValue = attrValue.Value_Floating__c;
            }
            finalValue = String.valueOf(maxValue);
        }else if(attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Decimal'){
            finalValue = modValue;
        }
        if((attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Number') && ((String.isNotBlank(modValue)) && (modValue != null)&&(attrValue.Value_Number__c != null))){
            Decimal maxValue = Decimal.valueOf(modValue);
            if(attrValue.Value_Number__c>maxValue){
                maxValue = attrValue.Value_Number__c;
            }
            finalValue = String.valueOf(maxValue);
        }else if(attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Number'){
            finalValue = modValue;
        }
         if((attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Date') && ((String.isNotBlank(modValue)) && (modValue != null)&&(attrValue.Value_Date__c != null))){
            Date dateValue;
            if(stringLst.size()==1){
                dateValue =  Date.parse(modValue);
            }else{
                dateValue =  Date.valueOf(modValue);
            }
            
            if(attrValue.Value_Date__c>dateValue){
                dateValue = attrValue.Value_Date__c;
            }
            finalValue = String.valueOf(dateValue);
        }else if(attrValue.Attribute__r.Attribute_Master__r.Data_Type__c == 'Date'){
            finalValue = modValue;
        }
        return finalValue;
    }
}