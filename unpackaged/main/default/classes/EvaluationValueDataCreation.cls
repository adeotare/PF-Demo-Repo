/**
 * TODO - Calls from TriggerPEForReports when Finish button is clicked in Asset builder prompt.
 * Evaluation values are created by Definition defined in Evaluation .
 * The Metric Values are used to compare the Metric Definitions in Evaluation.  
 */
public with sharing class EvaluationValueDataCreation {
    public static Map<String,Evaluation__c> dataNotValidateSet = new Map<String,Evaluation__c>();
    public static List<Evaluation_Value__c> evlValueCreationLst = new List<Evaluation_Value__c>();
    public static Map<String, Map<String, Boolean>> evInReport = new Map<String, Map<String, Boolean>>();
    public static Set<String> removalIds = new Set<String>();
    public static Plant_Asset_Prompt_Detail__c pltAstPrtDtl = new Plant_Asset_Prompt_Detail__c();
    public static String plantAssetId;
    public static Map<Id, String> evaluationMap = new Map<Id, String>();
    public static String builderRecordType;
    /*
    * Form map for Metric Definition which matches the TEM Version of Plant Asset.
    * Formation of another map of querying Metric Value from above Metric Definition map.
    * @param {String} plantAssetId - Evaluation Value creation against Plant Asset.
    */
    public static void mapFormationForEvaluationValue(String plantAssetId){
        Savepoint sp;
        try{
            sp = Database.setSavepoint();
            plantAssetId = plantAssetId;
            Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c,Renewable_Type__c FROM  Account_Plant__c WHERE Id=: plantAssetId];
            pltAstPrtDtl = [SELECT Id, Name, Capability_Report_Status__c, Completeness_Report_Status__c, Prompt_Information__c, Account_Plant__c  
                FROM Plant_Asset_Prompt_Detail__c 
                WHERE Account_Plant__c =:plantAsset.Id  AND Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND Is_Deleted__c = FALSE];
            
            Map<String, Metric_Definition__c> metricDefInfo = new Map<String, Metric_Definition__c>();
            Map<String, Metric_Value__c> metricValueInfo = new Map<String, Metric_Value__c>();
            
            for(Metric_Definition__c metricDefIns : [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, 
                                                     Base_Asset_Template__c, Description__c, Id, IsDeleted, Modifer_1__c, Modifer_2_Value__c, Modifer_2__c,
                                                     Name, TEM_Version__c, RecordTypeId FROM Metric_Definition__c 
                                                     WHERE TEM_Version__c =: plantAsset.TEM_Version__c]){
                                                         metricDefInfo.put(metricDefIns.Id, metricDefIns);
                                                     }
            if(metricDefInfo.size() > 0){
                for(Metric_Value__c metricValueIns : [SELECT Id, Metric_Definition__c, External_ID__c, Account_Plant__c, Value__c, Data_Type__c 
                                                      FROM Metric_Value__c 
                                                      WHERE Metric_Definition__c IN: metricDefInfo.keySet() AND Account_Plant__c=: plantAsset.Id]){
                                                          metricValueInfo.put(metricValueIns.Metric_Definition__c, metricValueIns);
                                                      }
            }
            if(metricValueInfo.size()>0){
                insertionOfEvaluationValue(metricDefInfo, metricValueInfo, plantAsset);
            }
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Database.rollback(sp);
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('mapFormationForEvaluationValue',exceptionDetails.getMessage(), 
                                                                 exceptionDetails.getLineNumber(), plantAssetId, '');
            insert errorLogInstance;
            pltAstPrtDtl.Capability_Report_Status__c = 'Completed - Error';
            update pltAstPrtDtl;
        }
    }
    /*
    * Creation of Evaluation Value. Dynamic query is pass to query Evaluation for Evalution Value creation.
    * @param {Map<String, Metric_Definition__c>} metricDefInfo - Metric Definition to identify components of Evaluation.
    * @param {Map<String, Metric_Value__c>} metricValueInfo - Metric Value to compare the components of Evaluation.
    * @param {String} plantAssetId - Evaluation Value creation against Plant Asset.
    */
    public static void insertionOfEvaluationValue(Map<String, Metric_Definition__c> metricDefInfo, Map<String, Metric_Value__c> metricValueInfo, Account_Plant__c plantAsset){
        
        Savepoint sp;
        try{
            sp = Database.setSavepoint();
            String pATemVersion = plantAsset.TEM_Version__c;
            String pARenewable = plantAsset.Renewable_Type__c;
            String query1 = 'SELECT Id,Name,Alias__c,Category__c,Component_1__c,Component_2__c,Component_3__c,Definition__c, Description__c,Evaluation_Notes__c,Group_1__c,Group_2__c,Hidden__c,Imp_Phase__c,Operand_1__c,Operand_2__c,Products__c,Renewable__c,Result__c,Result_Component_1__c,Result_Component_2__c,TEM_Version__c FROM Evaluation__c WHERE TEM_Version__c=:pATemVersion AND (';
            String strLst = plantAsset.Renewable_Type__c;
            query1 += ' Renewable__c LIKE \''+strLst+'%\'';
            query1 += ')';
            
            for(Evaluation__c evlInst : Database.query(query1)){
                String component1 = '', component2 = '', component3 = '', operand1 = '', operand2 = '', component1DT = '', component2DT = '', component3DT = '';
                evaluationMap.put(evlInst.Id, evlInst.Name);
                if(metricValueInfo.containsKey(evlInst.Component_1__c) && String.isNotBlank(metricValueInfo.get(evlInst.Component_1__c).Value__c)){
                    component1 = metricValueInfo.get(evlInst.Component_1__c).Value__c;
                    component1DT = metricValueInfo.get(evlInst.Component_1__c).Data_Type__c;
                    
                    if(String.isNotBlank(evlInst.Component_2__c)){
                        if(metricValueInfo.containsKey(evlInst.Component_2__c) && String.isNotBlank(metricValueInfo.get(evlInst.Component_2__c).Value__c)){
                            component2 = metricValueInfo.get(evlInst.Component_2__c).Value__c;
                            component2DT = metricValueInfo.get(evlInst.Component_2__c).Data_Type__c;
                        }else if (metricDefInfo.containsKey(evlInst.Component_2__c) && String.isNotBlank(metricDefInfo.get(evlInst.Component_2__c).Modifer_2_Value__c)){
                            component2 = metricDefInfo.get(evlInst.Component_2__c).Modifer_2_Value__c;
                            component2DT = metricDefInfo.get(evlInst.Component_2__c).Modifer_2__c;
                        }else{
                            dataNotValidateSet.put(evlInst.Id, evlInst);
                        }
                    }

                    if(String.isNotBlank(evlInst.Component_3__c)){
                        if(metricValueInfo.containsKey(evlInst.Component_3__c)){
                            component3 = metricValueInfo.get(evlInst.Component_3__c).Value__c;
                            component3DT = metricValueInfo.get(evlInst.Component_3__c).Data_Type__c;
                        }else if(metricDefInfo.containsKey(evlInst.Component_3__c) && String.isNotBlank(metricDefInfo.get(evlInst.Component_2__c).Modifer_2_Value__c)){
                            component3 = metricDefInfo.get(evlInst.Component_3__c).Modifer_2_Value__c;
                            component3DT = metricDefInfo.get(evlInst.Component_3__c).Modifer_2__c;
                        }else{
                            dataNotValidateSet.put(evlInst.Id, evlInst);
                        }
                    }
                    if(String.isNotBlank(evlInst.Operand_1__c)){
                        operand1 = evlInst.Operand_1__c;
                    }
                    if(String.isNotBlank(evlInst.Operand_2__c)){
                        operand2 = evlInst.Operand_2__c;
                    }
                    //Combine Components, Data type of Components and Operators for comparision
                    String combinationOfComponents = (String.isNotBlank(evlInst.Component_3__c) && String.isNotBlank(evlInst.Operand_2__c)) ?
                        (component1+'&'+component2+'&'+component3+'&'+operand1+'&'+operand2+'&'+component1DT+'&'+component2DT+'&'+component3DT) 
                        :(component1+'&'+component2+'&'+operand1+'&'+component1DT+'&'+component2DT);
                    Boolean logicResult = evaluationValueLogic(combinationOfComponents, evlInst);
                    
                    String resultFormat = evlInst.Result__c;
                    String formattedValue;

                    //To modify the result format from {0},{1} to the value of Metric Definition
                    if(String.IsNotBlank(evlInst.Result_Component_1__c) && String.IsNotBlank(evlInst.Result_Component_2__c)){
                        String ResultComponent1 = metricValueInfo.get(evlInst.Result_Component_1__c).Value__c;
                        String ResultComponent2 = metricValueInfo.containsKey(evlInst.Result_Component_2__c)? metricValueInfo.get(evlInst.Result_Component_2__c).Value__c:metricDefInfo.get(evlInst.Result_Component_2__c).Modifer_2_Value__c;
                        List<Object> replaceParameter = new List<Object>{ResultComponent1, ResultComponent2};
                            formattedValue = String.format(resultFormat,replaceParameter);
                    }else{
                        formattedValue = resultFormat;
                    }
                    
                    Evaluation_Value__c evalValue = formationOfEvaluationValue(evlInst, formattedValue, logicResult, String.valueOf(plantAsset.Id));
                    
                    showInReportLogic(evlInst, evalValue);
                    
                }else{
                    dataNotValidateSet.put(evlInst.Id, evlInst);
                }
            }
            if(evlValueCreationLst.size()>0){
                for(Evaluation_Value__c evalInst1 : evlValueCreationLst){
                    if (removalIds.size() >0) {
                         //To change other Evaluation value except First True Logic based on the Evaluation name
                        if(evaluationMap.containsKey(evalInst1.Evaluation__c)){
                            String chk = evaluationMap.get(evalInst1.Evaluation__c);
                            if(removalIds.contains(chk)){
                                evalInst1.Show_In_Report__c = FALSE;
                            }
                        }
                    }
                    //To mark Evaluation Value, if Evaluation having improper data
                    if(dataNotValidateSet.size() >0){
                       if(dataNotValidateSet.containsKey(evalInst1.Evaluation__c)){
                            evalInst1.Evaluation_Not_Executed__c = true;
                        }
                    }
                }
                upsert evlValueCreationLst External_ID__c;
            }
            //Update the Plant Asset Prompt Detail to track the creation process
            pltAstPrtDtl.Capability_Report_Status__c = 'Completed'; 
            update pltAstPrtDtl;
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Database.rollback(sp);
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('insertionOfEvaluationValue',exceptionDetails.getMessage(), 
                                                                 exceptionDetails.getLineNumber(), plantAssetId, '');
            insert errorLogInstance;
            pltAstPrtDtl.Capability_Report_Status__c = 'Completed - Error';
            update pltAstPrtDtl;
        }
    }
    /*
    * Splits the component values from above method and compare the data type, pass to another method and receieve a boolean about the comparision.
    * Pass Final comparision value to above method for Evaluation Value creation.
    * @param {String} combinationOfComponents - Combination of Evaluation fields :Component 1, Component 2, Component 3, Operator 1, Operator2.
    * @param {Evaluation__c} evlInst - Particular Evaluation for comparation.
    */
    public static Boolean evaluationValueLogic(String combinationOfComponents, Evaluation__c evlInst){
        String c1,c2,c3,o1,o2,c1DT,c2DT,c3DT;
        Boolean comparitionResult = false, compareResult1 = false, compareResult2;
        try{
            if(combinationOfComponents.contains('&')){
                List<String> strLst = combinationOfComponents.split('&');
                if(strLst.size() == 8){
                    c1 = strLst[0];
                    c2 = strLst[1];
                    c3 = strLst[2];
                    o1 = strLst[3];
                    o2 = strLst[4];
                    c1DT = strLst[5];
                    c2DT = strLst[6];
                    c3DT = strLst[7];
                }else if(strLst.size() == 5){
                    c1 = strLst[0];
                    c2 = strLst[1];
                    o1 = strLst[2];
                    c1DT = strLst[3];
                    c2DT = strLst[4];
                }
            }
            if(c1DT == c2DT){
                if(c1DT == 'Text' || c1DT == 'Picklist' || c1DT == 'Checkbox'){
                    if(o1.equals('<=') || o1.equals('>=') || o1.equals('<') || o1.equals('>')){
                        dataNotValidateSet.put(evlInst.Id, evlInst);
                    }
                    if(o1.equals('=') || o1.equals('<>')){
                        compareResult1 = comparisonOperationLogic(c1, c2, o1, c1DT);
                    }
                }
                if(c1DT == 'Number' || c1DT == 'Decimal' || c1DT == 'Date'){
                    if(c1.equals(null) || c2.equals(null)){
                        dataNotValidateSet.put(evlInst.Id, evlInst);
                    }else{
                        compareResult1 = comparisonOperationLogic(c1, c2, o1, c2DT);
                    }
                }
            }else if(c1DT <> c2DT){
                if(c1DT == 'Number' && c2DT == 'Decimal'){
                    if(c1.equals(null) || c2.equals(null)){
                        dataNotValidateSet.put(evlInst.Id, evlInst);
                    }else{
                        compareResult1 = comparisonOperationLogic(c1, c2, o1, c2DT);
                    }
                }
                if(c1DT == 'Decimal' && c2DT == 'Number'){
                    if(c1.equals(null) || c2.equals(null)){
                        dataNotValidateSet.put(evlInst.Id, evlInst);
                    }else{
                        compareResult1 = comparisonOperationLogic(c1, c2, o1, c1DT);
                    }
                }
                if((c1DT == 'Decimal' && (c2DT =='Date' || c2DT == 'Text' || c2DT == 'Picklist' || c2DT == 'Checkbox')) ||
                   (c1DT == 'Number' && (c2DT =='Date' || c2DT == 'Text' || c2DT == 'Picklist' || c2DT == 'Checkbox'))){
                       dataNotValidateSet.put(evlInst.Id, evlInst);
                   }
            }
            comparitionResult = compareResult1;
            
            if(!dataNotValidateSet.containsKey(evlInst.Id)){
                if(String.isNotBlank(c3) && String.isNotBlank(o2)){
                    compareResult2 = false;
                    if(c1DT == c3DT){
                        if(c1DT == 'Text' || c1DT == 'Picklist' || c1DT == 'Checkbox'){
                            if(o2.equals('<=') || o2.equals('>=') || o2.equals('<') || o2.equals('>')){
                                dataNotValidateSet.put(evlInst.Id, evlInst);
                            }
                            if(o2.equals('=') || o2.equals('<>')){
                                compareResult2 = comparisonOperationLogic(c1, c3, o2, c1DT);
                            }
                        }
                        if(c1DT == 'Number' || c1DT == 'Decimal' || c1DT == 'Date'){
                            if(c1.equals(null) || c2.equals(null)){
                                dataNotValidateSet.put(evlInst.Id, evlInst);
                            }else{
                                compareResult2 = comparisonOperationLogic(c1, c3, o1, c2DT);
                            }
                        }
                    }else if(c1DT <> c3DT){
                        if(c1DT == 'Number' && c3DT == 'Decimal'){
                            if(c1.equals(null) || c2.equals(null)){
                                dataNotValidateSet.put(evlInst.Id, evlInst);
                            }else{
                                compareResult2 = comparisonOperationLogic(c1, c3, o1, c2DT);
                            }
                        }
                        if(c1DT == 'Decimal' && c3DT == 'Number'){
                            if(c1.equals(null) || c2.equals(null)){
                                dataNotValidateSet.put(evlInst.Id, evlInst);
                            }else{
                                compareResult2 = comparisonOperationLogic(c1, c3, o1, c1DT);
                            }
                        }
                        if((c1DT == 'Decimal' && (c3DT == 'Date' || c3DT == 'Text' || c3DT == 'Picklist' || c3DT == 'Checkbox')) ||
                           (c1DT == 'Number' && (c3DT == 'Date' || c3DT == 'Text' || c3DT == 'Picklist' || c3DT == 'Checkbox'))){
                               dataNotValidateSet.put(evlInst.Id, evlInst);
                           }
                    }
                    if(compareResult1 == TRUE && compareResult2 == TRUE){
                        comparitionResult = TRUE;
                    }else{
                        comparitionResult = FALSE;
                    }
                }
            }
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('evaluationValueLogic',exceptionDetails.getMessage(), 
                                                                 exceptionDetails.getLineNumber(), plantAssetId, '');
            insert errorLogInstance;
        }
        return comparitionResult;
    }
    /*
    * Based on the datatype passed from above method, convert the two instance and compare with the operator.
    * @param {String} instance1, instance1 - Value to be compared.
    * @param {String} operator - Operator for comparation.
    * @param {String} dataType - Datatype to convert.
    */
    public static Boolean comparisonOperationLogic(String instance1, String instance2, String operator, String dataType){
        Boolean result = false;
        if(dataType == 'Decimal'){
            Decimal value1 = Decimal.valueOf(instance1);
            Decimal value2 = Decimal.valueOf(instance2);
            if(operator.equals('>')){
                if(value1 > value2){
                    result = true; 
                }
            }
            if(operator.equals('<')){
                if(value1 < value2){
                    result = true; 
                }
            }
            if(operator.equals('>=')){
                if(value1 >= value2){
                    result = true; 
                }
            }
            if(operator.equals('<=')){
                if(value1 <= value2){
                    result = true; 
                }
            }
            if(operator.equals('=')){
                if(value1 == value2){
                    result = true; 
                }
            }
            if(operator.equals('<>')){
                if(value1 <> value2){
                    result = true; 
                }
            }
        }
        
        if(dataType == 'Number'){
            Integer value1 = Integer.valueOf(instance1);
            Integer value2 = Integer.valueOf(instance2); 
            if(operator.equals('>')){
                if(value1 > value2){
                    result = true; 
                }
            }
            if(operator.equals('<')){
                if(value1 < value2){
                    result = true; 
                }
            }
            if(operator.equals('>=')){
                if(value1 >= value2){
                    result = true; 
                }
            }
            if(operator.equals('<=')){
                if(value1 <= value2){
                    result = true; 
                }
            }
            if(operator.equals('=')){
                if(value1 == value2){
                    result = true; 
                }
            }
            if(operator.equals('<>')){
                if(value1 <> value2){
                    result = true; 
                }
            }
        }
        if(dataType == 'Date'){
            Date value1 = Date.valueOf(instance1);
            Date value2 = Date.valueOf(instance2); 
            if(operator.equals('>')){
                if(value1 > value2){
                    result = true; 
                }
            }
            if(operator.equals('<')){
                if(value1 < value2){
                    result = true; 
                }
            }
            if(operator.equals('>=')){
                if(value1 >= value2){
                    result = true; 
                }
            }
            if(operator.equals('<=')){
                if(value1 <= value2){
                    result = true; 
                }
            }
            if(operator.equals('=')){
                if(value1 == value2){
                    result = true; 
                }
            }
            if(operator.equals('<>')){
                if(value1 <> value2){
                    result = true; 
                }
            }
        }
        if(dataType == 'Text' || dataType == 'Picklist' || dataType == 'Checkbox'){
            if(operator.equals('=')){
                if(instance1 == instance2){
                    result = true; 
                }
            }
            if(operator.equals('<>')){
                if(instance1 <> instance2){
                    result = true; 
                }
            }
            
        }
        return result;
    }
    /*
    * Fomation for Evaluation Value Creation
    * @param {Evaluation__c} evlInst - Evaluation Details for Evaluation Value.
    * @param {String} formattedValue - Resultant Format.
    * @param {Boolean} logicResult - Result of comparation.
    * @param {String} plantAsset - Plant Asset.
    */
    public static Evaluation_Value__c formationOfEvaluationValue(Evaluation__c evlInst, String formattedValue, Boolean logicResult, String plantAsset){
        Evaluation_Value__c evalValue = new Evaluation_Value__c();
        evalValue.Evaluation__c= evlInst.Id;
        evalValue.Result__c = formattedValue;
        evalValue.Account_Plant__c=plantAsset;
        evalValue.Logic_Result__c=logicResult;
        evalValue.External_ID__c = plantAsset+'-'+evlInst.Id;
        evalValue.Show_In_Report__c = FALSE;
        String str = evlInst.Name;
        evalValue.Test_Id__c = str.substringBeforeLast('.');
        return evalValue;
    }
    /*
    * Capability Reports needs first true logic of Evaluation Value based on the Test Id/Evaluation Name series.
    * @param {Evaluation__c} evlInst - Evaluation Details for Show In Report Process.
    * @param {Evaluation_Value__c} eval - Evaluation Value for Comparition logic.
    */
    public static void showInReportLogic(Evaluation__c  evlInst, Evaluation_Value__c eval){
        try{
            eval.Show_In_Report__c = FALSE;
            String evalDefName = evlInst.Name;
            List<String> stringNameSplit = evalDefName.split('\\.');
            String thirdVariable = stringNameSplit[stringNameSplit.size()-1];
            List<String> joinLst = new List<String>();
            
            for(Integer i=0; i<stringNameSplit.size()-1; i++){
                joinLst.add(stringNameSplit[i]);
            }
            //Based on the name of Evaluation, mark as "TRUE" in Show In Report field
            String combinedVariable = stringNameSplit[stringNameSplit.size()-1]+'-'+evalDefName;
            String evalName = String.join(joinLst,'.');
            if(evInReport.containsKey(evalName)){
                String checkKey = new List<String>(evInReport.get(evalName).KeySet())[0];
                List<String> splitedValue = checkKey.split('-');
                if(splitedValue[0] <thirdVariable){
                    Boolean b1 = evInReport.get(evalName).get(checkKey);
                    if(b1 == FALSE && eval.Logic_Result__c == TRUE){
                        removalIds.add(splitedValue[1]);
                        eval.Show_In_Report__c = TRUE;
                        evInReport.get(evalName).remove(checkKey);
                        Map<String, Boolean> firstVar = new Map<String, Boolean>();
                        firstVar.put(combinedVariable, eval.Logic_Result__c);
                        evInReport.put(evalName, firstVar);
                    }else if(b1 == TRUE && eval.Logic_Result__c == TRUE){
                        String checkEvalDef = new List<String>(evInReport.get(evalName).keySet())[0];
                        if(!checkEvalDef.equals(combinedVariable)){
                            removalIds.add(evalDefName);
                        }
                    }
                }
            }else{
                Map<String, Boolean> firstVar = new Map<String, Boolean>();
                firstVar.put(combinedVariable, eval.Logic_Result__c);
                evInReport.put(evalName, firstVar);
                if(eval.Logic_Result__c){
                    eval.Show_In_Report__c = TRUE;
                }
            }
            evlValueCreationLst.add(eval); 
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('showInReportLogic',exceptionDetails.getMessage(), 
                                                                 exceptionDetails.getLineNumber(), plantAssetId, '');
            insert errorLogInstance;
        }
    }
}