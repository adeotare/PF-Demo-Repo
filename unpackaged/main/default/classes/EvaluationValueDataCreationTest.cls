/**
**/
@isTest
public with sharing class EvaluationValueDataCreationTest {
    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.SOLAR, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c p1PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert p1PromptBaseAsset;
		
        Prompt_Information__c g1PromptInfo = new Prompt_Information__c();
        g1PromptInfo.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT  ;
        g1PromptInfo.TEM_Version__c = newTemVersion.Id;
        insert g1PromptInfo;

        Prompt_Information__c p1PromptInfo = TestDataFactory.createPromptInformation(Constants.P1_PLANT_INFO_PROMPT_SOLAR,
                                                p1PromptBaseAsset.Id, newTemVersion.Id);
        insert p1PromptInfo;

        Picklist_Master__c newPicklistMaster = TestDataFactory.createPicklistMaster(Constants.FLAT_HIERARCHY, newTemVersion.Id);
        insert newPicklistMaster;
        
        Picklist_Detail__c picklistDetailValue = TestDataFactory.createPicklistValue(newPicklistMaster.Id, newTemVersion.Id);
        insert picklistDetailValue;

        Id coreAttrRTId = Utils.getRecordTypeInfo('Core_Attribute__c','Core_Attribute').getRecordTypeId();

        List<Core_Attribute__c> coreAttrLst  = new List<Core_Attribute__c> ();
        list<String>datatypeLst = new list<String>{'Number','Number','Decimal','Decimal','Text','Text','Picklist','Picklist',
        'Date','Date','Checkbox','Checkbox'};
        list<String>coreAttrNameLst = new list<String>{'No1','No2','Decimal1','Decimal2','Text1','Text2','Picklist1','Picklist2'
        ,'Date1','Date2','Checkbox1','Checkbox2'};
        for(integer i = 0; i < 12; i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptBaseAsset.Id, newTemVersion.Id);                                                                 
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;
        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < 1; i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
        }

        Id metricDefinition = Utils.getRecordTypeInfo('Metric_Definition__c','Definition').getRecordTypeId();
        Id metricConst = Utils.getRecordTypeInfo('Metric_Definition__c','Constants').getRecordTypeId();

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        insert g1PlantAssetPromptDetail;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = 'Test Plant' +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        insert p1PlantAssetPromptDetail;

        String promptSpecificInfoJSON = JSON.serialize('{"No of Blocks":"2","Flat Hierarchy":"No"');
        String coreAttributeInfoJSON = JSON.serialize('{"AC_CAPACITY":""}');

        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"';
        p1SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":""}';
        p1SiteMetaData.Account_Plant__c= newPlantAsset.id;
        p1SiteMetaData.Base_Asset_Template__c = p1PromptBaseAsset.id;
        p1SiteMetaData.Plant_Asset_Prompt_Detail__c = p1PlantAssetPromptDetail.Id;
        insert p1SiteMetaData;
        
        List<String> metricDefStr = new List<String>();
        String str= 'VALUES';
        List<Metric_Definition__c> metricDefLst = new List<Metric_Definition__c>();
        for(Core_Attribute__c coreAttrIns : coreAttrLst){
                Metric_Definition__c metricDef = TestDataFactory.createMetricDef(String.valueOf(p1PromptBaseAsset.Id), String.valueOf(coreAttrIns.Id), str, '', '', String.valueOf(newTemVersion.Id), metricDefinition);
                metricDefLst.add(metricDef);
        }
        insert metricDefLst;
        
        List<Metric_Value__c> metricValueLst = new List<Metric_Value__c>();
        for(Metric_Definition__c metricDefIn : [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: newPlantAsset.TEM_Version__c]){
                
                Metric_Value__c metricValue = TestDataFactory.createMetricValue(String.valueOf(metricDefIn.Id), String.valueOf(newPlantAsset.Id), '', metricDefIn.Attribute__r.Attribute_Master__r.Data_Type__c);  
                metricValueLst.add(metricValue);
        }
        insert metricValueLst;

        Metric_Definition__c metricDefCnst = TestDataFactory.createMetricDef('', '', 'CONSTANT', 'NUMBER', '300', String.valueOf(newTemVersion.Id), metricConst);
        insert metricDefCnst;
    }
    
    public static testMethod void testMethod1(){
        //Scenario 1 -> When Attribute data type as Number in metric definition, which used for Component 1 and Component 2 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id),'',
                                                               '=', '', 'Pass', '', '');
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id),'',
                                                               '<>', '', 'Pass', '', '');
        evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id),'',
                                                               '>', '', 'Pass', '', '');
        evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id),'',
                                                               '<', '', 'Pass', '', '');
        evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id),'',
                                                               '>=', '', 'Pass', '', '');
        evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id),'',
                                                               '<=', '', 'Pass', '', '');
        evalLst.add(eval6);
       
        
        insert evalLst;
        
       EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    } 
    
     public static testMethod void testMethod2(){
        //Scenario 2 -> When Attribute data type as Number in metric definition, which used for Component 1, Component 2 and Component 3 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
         
         
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id), String.valueOf(metricDefCalLst[1].Id),
                                                               '=', '<=', '{0}/{1}', String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id));
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id), String.valueOf(metricDefCalLst[1].Id),
                                                               '<>', '>=', '{0}/{1}', String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id));
		evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id), String.valueOf(metricDefCalLst[1].Id),
                                                               '>', '<', '{0}/{1}', String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id));
		evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id), String.valueOf(metricDefCalLst[1].Id),
                                                               '<', '>', '{0}/{1}', String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id));
		evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id), String.valueOf(metricDefCalLst[1].Id),
                                                               '>=', '<>', '{0}/{1}', String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id));
		evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id), String.valueOf(metricDefCalLst[1].Id),
                                                               '<=', '=', '{0}/{1}', String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefCalLst[1].Id));
		evalLst.add(eval6);
    insert evalLst;

    EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    public static testMethod void testMethod3(){
        //Scenario 3 -> When Attribute data type as Decimal in metric definition, which used for Component 1 and Component 2 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id),'',
                                                               '=', '', 'Pass', '', '');
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id),'',
                                                               '<>', '', 'Pass', '', '');
        evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id),'',
                                                               '>', '', 'Pass', '', '');
        evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id),'',
                                                               '<', '', 'Pass', '', '');
        evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id),'',
                                                               '>=', '', 'Pass', '', '');
        evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id),'',
                                                               '<=', '', 'Pass', '', '');
        evalLst.add(eval6);
        insert evalLst;
        EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    
     public static testMethod void testMethod4(){
        //Scenario 4 -> When Attribute data type as Decimal in metric definition, which used for Component 1, Component 2 and Component 3 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id), String.valueOf(metricDefCalLst[3].Id),
                                                               '=', '<=', '{0}/{1}', String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[4].Id));
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id), String.valueOf(metricDefCalLst[3].Id),
                                                               '<>', '>=', '{0}/{1}', String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[4].Id));
		evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id), String.valueOf(metricDefCalLst[3].Id),
                                                               '>', '<', '{0}/{1}', String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[4].Id));
		evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id), String.valueOf(metricDefCalLst[3].Id),
                                                               '<', '>', '{0}/{1}', String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[4].Id));
		evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id), String.valueOf(metricDefCalLst[3].Id),
                                                               '>=', '<>', '{0}/{1}', String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[4].Id));
		evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id), String.valueOf(metricDefCalLst[3].Id),
                                                               '<=', '=', '{0}/{1}', String.valueOf(metricDefCalLst[2].Id), String.valueOf(metricDefCalLst[3].Id));
		evalLst.add(eval6);
    insert evalLst;
    EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    public static testMethod void testMethod5(){
        //Scenario 5 -> When Attribute data type as Text in metric definition, which used for Component 1 and Component 2 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[4].Id), String.valueOf(metricDefCalLst[5].Id),'',
                                                               '=', '', 'Pass', '', '');
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[4].Id), String.valueOf(metricDefCalLst[5].Id),'',
                                                               '<>', '', 'Pass', '', '');
        evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[4].Id), String.valueOf(metricDefCalLst[5].Id),'',
                                                               '>', '', 'Pass', '', '');
        evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[4].Id), String.valueOf(metricDefCalLst[5].Id),'',
                                                               '<', '', 'Pass', '', '');
        evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[4].Id), String.valueOf(metricDefCalLst[5].Id),'',
                                                               '>=', '', 'Pass', '', '');
        evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[4].Id), String.valueOf(metricDefCalLst[5].Id),'',
                                                               '<=', '', 'Pass', '', '');
        evalLst.add(eval6);
        insert evalLst;
        EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    
     public static testMethod void testMethod6(){
        //Scenario 6 -> When Attribute data type as Text in metric definition, which used for Component 1, Component 2 and Component 3 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[6].Id), String.valueOf(metricDefCalLst[7].Id), String.valueOf(metricDefCalLst[6].Id),
                                                               '=', '<=', '{0}/{1}', String.valueOf(metricDefCalLst[5].Id), String.valueOf(metricDefCalLst[6].Id));
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[6].Id), String.valueOf(metricDefCalLst[7].Id), String.valueOf(metricDefCalLst[6].Id),
                                                               '<>', '>=', '{0}/{1}', String.valueOf(metricDefCalLst[5].Id), String.valueOf(metricDefCalLst[6].Id));
		evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[6].Id), String.valueOf(metricDefCalLst[7].Id), String.valueOf(metricDefCalLst[6].Id),
                                                               '>', '<', '{0}/{1}', String.valueOf(metricDefCalLst[5].Id), String.valueOf(metricDefCalLst[6].Id));
		evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[6].Id), String.valueOf(metricDefCalLst[7].Id), String.valueOf(metricDefCalLst[6].Id),
                                                               '<', '>', '{0}/{1}', String.valueOf(metricDefCalLst[5].Id), String.valueOf(metricDefCalLst[6].Id));
		evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[6].Id), String.valueOf(metricDefCalLst[7].Id), String.valueOf(metricDefCalLst[6].Id),
                                                               '>=', '<>', '{0}/{1}', String.valueOf(metricDefCalLst[5].Id), String.valueOf(metricDefCalLst[6].Id));
		evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[6].Id), String.valueOf(metricDefCalLst[7].Id), String.valueOf(metricDefCalLst[6].Id),
                                                               '<=', '=', '{0}/{1}', String.valueOf(metricDefCalLst[5].Id), String.valueOf(metricDefCalLst[6].Id));
		evalLst.add(eval6);

        insert evalLst;
        EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    public static testMethod void testMethod7(){
        //Scenario 7 -> When Attribute data type as Picklist in metric definition, which used for Component 1 and Component 2 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id),'',
                                                               '=', '', 'Pass', '', '');
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id),'',
                                                               '<>', '', 'Pass', '', '');
        evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id),'',
                                                               '>', '', 'Pass', '', '');
        evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id),'',
                                                               '<', '', 'Pass', '', '');
        evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id),'',
                                                               '>=', '', 'Pass', '', '');
        evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id),'',
                                                               '<=', '', 'Pass', '', '');
        evalLst.add(eval6);
        insert evalLst;
        EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    
     public static testMethod void testMethod8(){
        //Scenario 8 -> When Attribute data type as picklist in metric definition which used for Component 1, and When Attribute data type as date in metric definition which used for Component 2 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id), String.valueOf(metricDefCalLst[9].Id),
                                                               '=', '<=', '{0}/{1}', String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id));
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id), String.valueOf(metricDefCalLst[9].Id),
                                                               '<>', '>=', '{0}/{1}', String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id));
		evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id), String.valueOf(metricDefCalLst[9].Id),
                                                               '>', '<', '{0}/{1}', String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id));
		evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id), String.valueOf(metricDefCalLst[9].Id),
                                                               '<', '>', '{0}/{1}', String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id));
		evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id), String.valueOf(metricDefCalLst[9].Id),
                                                               '>=', '<>', '{0}/{1}', String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id));
		evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id), String.valueOf(metricDefCalLst[9].Id),
                                                               '<=', '=', '{0}/{1}', String.valueOf(metricDefCalLst[9].Id), String.valueOf(metricDefCalLst[8].Id));
		evalLst.add(eval6);
        insert evalLst;
        EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    public static testMethod void testMethod9(){
        //Scenario 9 -> When Attribute data type as Date in metric definition, which used for Component 1 and Component 2 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id),'',
                                                               '=', '', 'Pass', '', '');
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id),'',
                                                               '<>', '', 'Pass', '', '');
        evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id),'',
                                                               '>', '', 'Pass', '', '');
        evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id),'',
                                                               '<', '', 'Pass', '', '');
        evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id),'',
                                                               '>=', '', 'Pass', '', '');
        evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id),'',
                                                               '<=', '', 'Pass', '', '');
        evalLst.add(eval6);
        insert evalLst;
        EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    
    public static testMethod void testMethod10(){
        //Scenario 10 -> When Attribute data type as Date in metric definition, which used for Component 1, Component 2 and Component 3 field in Evaluation
        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];
        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name FROM Metric_Definition__c 
            WHERE TEM_Version__c =: plantAsset.TEM_Version__c];

        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id), String.valueOf(metricDefCalLst[11].Id),
                                                               '=', '<=', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id), String.valueOf(metricDefCalLst[11].Id),
                                                               '<>', '>=', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
		evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id), String.valueOf(metricDefCalLst[11].Id),
                                                               '>', '<', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
		evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id), String.valueOf(metricDefCalLst[11].Id),
                                                               '<', '>', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
		evalLst.add(eval4);
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id), String.valueOf(metricDefCalLst[11].Id),
                                                               '>=', '<>', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
		evalLst.add(eval5);
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id), String.valueOf(metricDefCalLst[11].Id),
                                                               '<=', '=', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
		evalLst.add(eval6);
    insert evalLst;
    EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
    
    public static testMethod void testMethod11(){
        //Scenario 11 -> When Component1 as metric definition and component 2 as metric constant
        Id metricDefinition = Utils.getRecordTypeInfo('Metric_Definition__c','Definition').getRecordTypeId();
        Id metricConst = Utils.getRecordTypeInfo('Metric_Definition__c','Constants').getRecordTypeId();

        Account_Plant__c plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c  = '7777.77.777' LIMIT 1];

        List<Metric_Definition__c> metricDefCalLst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name,RecordTypeId FROM Metric_Definition__c 
                WHERE TEM_Version__c =: plantAsset.TEM_Version__c AND RecordTypeId=:metricDefinition];
        Metric_Definition__c metricDefConst = [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c,Description__c,
                Id,IsDeleted,Modifer_1__c,Modifer_2_Value__c,Modifer_2__c,Name,RecordTypeId FROM Metric_Definition__c 
                WHERE TEM_Version__c =: plantAsset.TEM_Version__c AND RecordTypeId=:metricConst LIMIT 1];
        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[0].Id), String.valueOf(metricDefConst.Id),'',
                                                               '=', '', 'Pass', '', '');
        evalLst.add(eval1);
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefConst.Id), String.valueOf(metricDefConst.Id),
                                                               '<>', '>=', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
        evalLst.add(eval2);
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                            String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefConst.Id), String.valueOf(metricDefConst.Id),
                                                            '<>', '>=', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
        evalLst.add(eval3);
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(plantAsset.TEM_Version__c),
                                                            String.valueOf(metricDefConst.Id), String.valueOf(metricDefConst.Id), String.valueOf(metricDefConst.Id),

                                                            '<>', '>=', '{0}/{1}', String.valueOf(metricDefCalLst[11].Id), String.valueOf(metricDefCalLst[10].Id));
        evalLst.add(eval4);
        insert evalLst;
        EvaluationValueDataCreation.mapFormationForEvaluationValue(plantAsset.Id);
    }
}