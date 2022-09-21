/**
**/
@isTest
public with sharing class TriggerPEForRFICreationTest {
    @testSetup
    public static void testDataSetup() {
     
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Account_Plant__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;

        Base_Asset_Template__c p1PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_PV_PLANT, newTemVersion.Id);
        insert p1PromptBaseAsset;
		
        Prompt_Information__c g1PromptInfo = new Prompt_Information__c();
        g1PromptInfo.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
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
        list<String>datatypeLst = new list<String>{'Number','Number'};
        list<String>coreAttrNameLst = new list<String>{'No1','No2'};
        for(integer i = 0; i < coreAttrNameLst.size(); i++){
            Core_Attribute__c coreAttr = TestDataFactory.createCoreAttribute(coreAttrNameLst[i],
                                                                                'Metadata',
                                                                                datatypeLst[i],
                                                                                coreAttrRTId,
                                                                                (datatypeLst[i] == 'Picklist')? newPicklistMaster.Id : null,
                                                                                p1PromptBaseAsset.Id, newTemVersion.Id);                                                                  
            coreAttr.Default_Value__c = (math.mod(i,2) == 0) ? '2':'';
            coreAttrLst.add(coreAttr);
        }
        insert coreAttrLst;
        
        List<Attribute_Requirement__c> attrReqLst  = new List<Attribute_Requirement__c> ();
        for(integer i = 0; i < coreAttrLst.size(); i++){
            Attribute_Requirement__c attrReq = TestDataFactory.createAttributeRequirement('Drive', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq);
            Attribute_Requirement__c attrReq2 = TestDataFactory.createAttributeRequirement('Drive Plus', 'Yes', coreAttrLst[i].Id, newTemVersion.Id);
            attrReqLst.add(attrReq2);
        }
		insert attrReqLst;
        
        Id metricDefinition = Utils.getRecordTypeInfo('Metric_Definition__c','Definition').getRecordTypeId();
        Id metricConst = Utils.getRecordTypeInfo('Metric_Definition__c','Constants').getRecordTypeId();

        Plant_Asset_Prompt_Detail__c g1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        g1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        g1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        insert g1PlantAssetPromptDetail;
        
        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"PF Service Product":"Drive;FSM","No of Blocks":"2","Flat Hierarchy":"No"}';
        g1SiteMetaData.Attribute_Info__c = '{"AC_CAPACITY":""}';
        g1SiteMetaData.Account_Plant__c= newPlantAsset.id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Account_Plant__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        insert p1PlantAssetPromptDetail;

        String promptSpecificInfoJSON = JSON.serialize('{"No of Blocks":"2","Flat Hierarchy":"No"}');
        String coreAttributeInfoJSON = JSON.serialize('{"AC_CAPACITY":""}');

        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"}';
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
        for(Metric_Definition__c metricDefIn : [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c, Id, IsDeleted, Modifer_1__c, Modifer_2_Value__c, Modifer_2__c, Name FROM Metric_Definition__c  WHERE TEM_Version__c =: newPlantAsset.TEM_Version__c]){
                Metric_Value__c metricValue = TestDataFactory.createMetricValue(String.valueOf(metricDefIn.Id), String.valueOf(newPlantAsset.Id), '', metricDefIn.Attribute__r.Attribute_Master__r.Data_Type__c);  
                metricValueLst.add(metricValue);
        }
        insert metricValueLst;
        
        Metric_Definition__c metricDefCnst = TestDataFactory.createMetricDef('', '', 'CONSTANT', 'NUMBER', '300', String.valueOf(newTemVersion.Id), metricConst);
        insert metricDefCnst;
        
        List<Evaluation__c> evalLst = new List<Evaluation__c>();
        Evaluation__c eval1 = TestDataFactory.createEvaluation('TEST.0001.01', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(newPlantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefLst[0].Id), String.valueOf(metricDefLst[1].Id),'',
                                                               '=', '', 'Pass', '', '');
        insert eval1;
        Evaluation__c eval2 = TestDataFactory.createEvaluation('TEST.0001.02', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(newPlantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefLst[0].Id), String.valueOf(metricDefLst[1].Id),'',
                                                               '<>', '', 'Pass', '', '');
        insert eval2;
        Evaluation__c eval3 = TestDataFactory.createEvaluation('TEST.0001.03', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(newPlantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefLst[0].Id), String.valueOf(metricDefLst[1].Id),'',
                                                               '>', '', 'Pass', '', '');
        insert eval3;
      // }
    }
    @isTest
    public static void triggerPEForRFICreationTest1(){
        
        //With Evaluation 
        List<Account_Plant__c> plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c,Asset_Builder_Status__c,AB_Approval_Status__c FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.777'];
        plantAsset[0].Asset_Builder_Status__c = Constants.COMPLETED;
        update plantAsset[0];
        
        List<Evaluation__c> evaluationLst = [SELECT Id, Name,RFI_Category__r.Name FROM Evaluation__c WHERE TEM_Version__c =: plantAsset[0].TEM_Version__c];
        List<Evaluation_Value__c> evalValLst = new List<Evaluation_Value__c>();
        for(integer evalIns = 0; evalIns < evaluationLst.size(); evalIns++){
            Evaluation_Value__c evalValIns = new Evaluation_Value__c();
            evalValIns.Evaluation_Not_Executed__c = false;
            evalValIns.Logic_Result__c = true;
            evalValIns.Result__c = 'Missing';
            evalValIns.Show_In_Report__c = true;
            evalValIns.Account_Plant__c = plantAsset[0].Id;
            evalValIns.Evaluation__c = evaluationLst[evalIns].Id;
            evalValLst.add(evalValIns);
        }
        insert evalValLst;
        
        TriggerPEForRFICreation.createPEForRFI(plantAsset[0].Id);
    } 
    
    @isTest
    public static void triggerPEForRFICreationTest2(){
    
        //Completness Report Data
        List<Account_Plant__c> plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.777'];
        List<Core_Attribute__c> coreAttrLst  = [SELECT Id, Name FROM Core_Attribute__c WHERE TEM_Version__c =: plantAsset[0].TEM_Version__c];
        Prompt_Information__c p1PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE TEM_Version__c =: plantAsset[0].TEM_Version__c LIMIT 1];
        Base_Asset_Template__c p1PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE TEM_Version__c =: plantAsset[0].TEM_Version__c LIMIT 1];
        Site_Metadata__c p1SiteMetaData = [SELECT Id, Name, Attribute_Info__c FROM Site_Metadata__c WHERE Account_Plant__c =: plantAsset[0].Id AND Base_Asset_Template__c =: p1PromptBaseAsset.id LIMIT 1];
        
        List<Attribute_Value__c> attrValueLst = new List<Attribute_Value__c>();
        for(integer j = 0; j < coreAttrLst.size(); j++){
            Attribute_Value__c attributeValue = new Attribute_Value__c();
            attributeValue.Account_Plant__c = plantAsset[0].Id;
            attributeValue.Site_Metadata__c = p1SiteMetaData.Id;
            attributeValue.Prompt_Information__c = p1PromptInfo.Id; 
            attributeValue.Base_Asset_Template__c = p1PromptBaseAsset.id;
            attributeValue.Value__c = (math.mod(j,2) == 0) ? '3' : '';
            attributeValue.Attribute__c = coreAttrLst[j].Id;
            attrValueLst.add(attributeValue);
        }
        insert attrValueLst;
        List<Id> promptInfo = new List<Id>();
        ReportDataHandler ReportDataHandlerCls = new ReportDataHandler();
        ReportDataHandlerCls.queryExsistingReportData(plantAsset[0].Id, promptInfo);
        List<Asset_Builder_Report_Data__c> reportDataHldr1 = [SELECT Id, Name FROM Asset_Builder_Report_Data__c WHERE Account_Plant__c =: plantAsset[0].Id];
        TriggerPEForRFICreation.createPEForRFI(plantAsset[0].Id);
    }
    @isTest
    public static void triggerPEForRFICreationTest3(){
        //With status check 
        List<Account_Plant__c> plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c,Asset_Builder_Status__c,AB_Approval_Status__c FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.777'];
        plantAsset[0].Asset_Builder_Status__c = Constants.IN_PROGRESS_ABS;
        update plantAsset[0];
        String expectedData1 = TriggerPEForRFICreation.createPEForRFI(plantAsset[0].Id);
        System.assertEquals(expectedData1.split('&')[0], 'Asset Builder Status should be completed, and approved before RFI\'s can be generated');
        plantAsset[0].Asset_Builder_Status__c = Constants.COMPLETED;
        plantAsset[0].AB_Approval_Status__c = 'Approved';
        update plantAsset[0];
        String expectedData2 = TriggerPEForRFICreation.createPEForRFI(plantAsset[0].Id);
        System.assertEquals(expectedData2.split('&')[0], 'Please contact your administrator, No RFI to be created.');
    }
    /*@isTest
    public static void triggerPEForRFICreationTest4(){
         
        List<Account_Plant__c> plantAsset = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c,Asset_Builder_Status__c,AB_Approval_Status__c FROM Account_Plant__c WHERE Drive_Id__c ='7777.77.777'];
        plantAsset[0].Asset_Builder_Status__c = Constants.COMPLETED;
        plantAsset[0].AB_Approval_Status__c = 'Approved';
        update plantAsset[0];
        
        List<Evaluation__c> evaluationLst = [SELECT Id, Name,RFI_Category__r.Name FROM Evaluation__c WHERE TEM_Version__c =: plantAsset[0].TEM_Version__c];
        List<Evaluation_Value__c> evalValLst = new List<Evaluation_Value__c>();
        for(integer evalIns = 0; evalIns < evaluationLst.size(); evalIns++){
            Evaluation_Value__c evalValIns = new Evaluation_Value__c();
            evalValIns.Evaluation_Not_Executed__c = false;
            evalValIns.Logic_Result__c = true;
            evalValIns.Result__c = 'Missing';
            evalValIns.Show_In_Report__c = true;
            evalValIns.Account_Plant__c = plantAsset[0].Id;
            evalValIns.Evaluation__c = evaluationLst[evalIns].Id;
            evalValLst.add(evalValIns);
        }
        insert evalValLst;
        
        TriggerPEForRFICreation.createPEForRFI(plantAsset[0].Id);
    }*/
}