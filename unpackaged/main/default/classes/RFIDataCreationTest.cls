/**
**/
@isTest
public with sharing class RFIDataCreationTest {
/*    @testSetup
    public static void testDataSetup() {
        TEM_Version__c newTemVersion = TestDataFactory.createTemVersion(Constants.DRAFT);
        insert newTemVersion;

        Plant_Asset__c newPlantAsset = TestDataFactory.createPlantAsset(Constants.WIND, 'Drive', '7777.77.777', newTemVersion.Id);
        insert newPlantAsset;
        
        
        Account newAcc = new Account();
        newAcc.Name = 'Test ACC RFI Check';
        insert newAcc;
        
        Id parentPlantAssetRT = Utils.getRecordTypeInfo('Plant_Asset__c','Parent_Asset').getRecordTypeId();
        
        Plant_Asset__c parentPlantAsset = new Plant_Asset__c();
        parentPlantAsset.Name = 'Parent Plant Asset';
        parentPlantAsset.Plant_Name__c = 'Plant Asset';
        parentPlantAsset.Renewable_Type__c = Constants.WIND;
        parentPlantAsset.RecordTypeId = parentPlantAssetRT;
        insert parentPlantAsset;
        
        Id fleetPlantAssetRT = Utils.getRecordTypeInfo('Plant_Asset__c','Fleet_Asset').getRecordTypeId();
        Plant_Asset__c newFleetPlantAsset = new Plant_Asset__c();
        newFleetPlantAsset.Name = 'Test Plant';
        newFleetPlantAsset.Renewable_Type__c = Constants.WIND;
        newFleetPlantAsset.PF_Service_Product__c = 'Drive';
        newFleetPlantAsset.Customer_Plant_Asset_ID__c  = '7777.77.888';
        newFleetPlantAsset.RecordTypeId = fleetPlantAssetRT;
        newFleetPlantAsset.Account__c = newAcc.Id;
        newFleetPlantAsset.Parent__c = parentPlantAsset.Id;
        insert newFleetPlantAsset;
        
        RFI__c newFleetRFI = new RFI__c();
        newFleetRFI.Name = 'New';
        newFleetRFI.Sub_Type__c = 'Customer';
        newFleetRFI.Plant_Asset__c = newFleetPlantAsset.Id;
        insert newFleetRFI;
        
        newFleetRFI.skipValidation__c=True;
        newFleetRFI.RFI_Status__c = 'Closed';
        update newFleetRFI;
        
        RFI__c newFleetRFI1 = new RFI__c();
        newFleetRFI1.Name = 'New';
        newFleetRFI1.Sub_Type__c = 'Customer';
        newFleetRFI1.Plant_Asset__c = newFleetPlantAsset.Id;
        insert newFleetRFI1;
        
		RFI_Categories__c newRFICat = new RFI_Categories__c();
        newRFICat.Category_Classification__c = 'General';
        newRFICat.Name = System.Label.SubstationRFICategoryName;
        newRFICat.RFI_Sub_Type_Filter__c = 'Asset Builder';
        newRFICat.RFI_Category_Status__c = 'Active';
        newRFICat.RecordTypeId = Utils.getRecordTypeInfo('RFI_Categories__c', ConstantsRecordTypes.RFI_CATEGORY_MISSING_INCOMPLETE_INFORMATION).getRecordTypeId();
        insert newRFICat;
        
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
        list<String>datatypeLst = new list<String>{'Number','Number','Decimal','Decimal','Text','Text','Picklist','Picklist',
        'Date','Date','Checkbox','Checkbox'};
        list<String>coreAttrNameLst = new list<String>{'AC_Capacity','DC_Capacity','Decimal1','Decimal2','Text1','Text2','Picklist1','Picklist2'
        ,'Date1','Date2','Checkbox1','Checkbox2'};
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
        g1PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        g1PlantAssetPromptDetail.Prompt_Information__c = g1PromptInfo.Id;
        insert g1PlantAssetPromptDetail;
        
        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"Switchgear Substation":"0", "Renewable Type":"SOLAR - PV"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Plant_Asset__c= newPlantAsset.id;
        g1SiteMetaData.Plant_Asset_Prompt_Detail__c = g1PlantAssetPromptDetail.Id;
        insert g1SiteMetaData;

        Plant_Asset_Prompt_Detail__c p1PlantAssetPromptDetail = new Plant_Asset_Prompt_Detail__c();
        p1PlantAssetPromptDetail.Name = newPlantAsset.Name +'-'+ p1PromptInfo.Name;
        p1PlantAssetPromptDetail.Plant_Asset__c = newPlantAsset.Id;
        p1PlantAssetPromptDetail.Prompt_Information__c = p1PromptInfo.Id;
        p1PlantAssetPromptDetail.Base_Asset__c = p1PromptBaseAsset.Id;
        insert p1PlantAssetPromptDetail;

        String promptSpecificInfoJSON = JSON.serialize('{"No of Blocks":"2","Flat Hierarchy":"No"');
        String coreAttributeInfoJSON = JSON.serialize('{"AC_CAPACITY":""}');

        Site_Metadata__c p1SiteMetaData = new Site_Metadata__c(); 
        p1SiteMetaData.Name = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
        p1SiteMetaData.Prompt_Specific_Info__c = '{"No of Blocks":"2","Flat Hierarchy":"No"}';
        p1SiteMetaData.Attribute_Info__c = '{"AC_Capacity":"3724918","DC_Capacity":"3724918"}';
        p1SiteMetaData.Plant_Asset__c= newPlantAsset.id;
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
        for(Metric_Definition__c metricDefIn : [SELECT Attribute__c, Attribute__r.Attribute_Master__r.Data_Type__c, Base_Asset_Template__c, Description__c, Id, IsDeleted, Modifer_1__c, Modifer_2_Value__c, Modifer_2__c, Name FROM Metric_Definition__c  WHERE TEM_Version__c =: newPlantAsset.TEM_Version__c]){
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
        Evaluation__c eval4 = TestDataFactory.createEvaluation('TEST.0001.04', 'Data Capability', 'Drive', 'Solar - PV', 'Feature','', '', String.valueOf(newPlantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefLst[0].Id), String.valueOf(metricDefLst[1].Id),'',
                                                               '<', '', 'Pass', '', '');
        insert eval4;
        Evaluation__c eval5 = TestDataFactory.createEvaluation('TEST.0001.05', 'Data Capability', 'Drive', 'Solar - PV', 'Plant','', '', String.valueOf(newPlantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefLst[0].Id), String.valueOf(metricDefLst[1].Id),'',
                                                               '>=', '', 'Pass', '', '');
        insert eval5;
        Evaluation__c eval6 = TestDataFactory.createEvaluation('TEST.0001.06', 'Data Capability', 'Drive', 'Solar - PV', 'Solar - PV','', '', String.valueOf(newPlantAsset.TEM_Version__c),
                                                               String.valueOf(metricDefLst[0].Id), String.valueOf(metricDefLst[1].Id),'',
                                                               '<=', '', 'Pass', '', '');
        insert eval6;
    }
    
    public static testMethod void capabilityTest1(){
        //RFI Item creation check Without existing RFI against plant asset
        List<Plant_Asset__c> plantAssetLst = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Plant_Asset__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777'];
		Plant_Asset__c plantAsset =  plantAssetLst[0];
        List<Evaluation__c> evaluationLst = [SELECT Id, Name,RFI_Category__r.Name FROM Evaluation__c WHERE TEM_Version__c =: plantAsset.TEM_Version__c];
        
        List<Evaluation_Value__c> evalValLst = new List<Evaluation_Value__c>();
        for(integer evalIns = 0; evalIns < evaluationLst.size(); evalIns++){
            Evaluation_Value__c evalValIns = new Evaluation_Value__c();
            evalValIns.Evaluation_Not_Executed__c = false;
            evalValIns.Logic_Result__c = true;
            evalValIns.Result__c = 'Missing';
            evalValIns.Show_In_Report__c = true;
            evalValIns.Plant_Asset__c = plantAsset.Id;
            evalValIns.Evaluation__c = evaluationLst[evalIns].Id;
            evalValLst.add(evalValIns);
        }
        insert evalValLst;
        RFIDataCreation.abSubstationRFICreation(plantAsset.Id);
        RFIDataCreation.dataFormationForRFI(plantAsset.Id);
        
		Set<String> evalValChkLst = new Set<String>();
        for(Evaluation_Value__c evalValIns :[SELECT Id, Name, Evaluation__r.RFI_Category__c, Evaluation_Not_Executed__c, Logic_Result__c, Result__c, Show_In_Report__c FROM Evaluation_Value__c WHERE Plant_Asset__c =: plantAsset.Id AND Show_In_Report__c = TRUE AND Result__c !=: Constants.PASS ]){
        	evalValChkLst.add(evalValIns.Evaluation__r.RFI_Category__c);
        }
        List<RFI_Detail__c> rfiItemLst = [SELECT Id, Name FROM RFI_Detail__c WHERE Plant_Asset__c =: plantAsset.Id];
        System.assertEquals(4, rfiItemLst.size());  
    } 

    public static testMethod void capabilityTest2(){
        //To check process works with existing RFI against Plant Asset
        List<Plant_Asset__c> plantAssetLst = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Plant_Asset__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777'];
		Plant_Asset__c plantAsset =  plantAssetLst[0];
        List<Evaluation__c> evaluationLst = [SELECT Id, Name,RFI_Category__r.Name FROM Evaluation__c WHERE TEM_Version__c =: plantAsset.TEM_Version__c];
        
        RFI__c rfiInstance = new RFI__c();
        rfiInstance.Name = 'RfiTest';
        rfiInstance.Plant_Asset__c = plantAsset.Id;
        insert rfiInstance;
        List<Evaluation_Value__c> evalValLst = new List<Evaluation_Value__c>();
        for(integer evalIns = 0; evalIns < evaluationLst.size(); evalIns++){
            Evaluation_Value__c evalValIns = new Evaluation_Value__c();
            evalValIns.Evaluation_Not_Executed__c = false;
            evalValIns.Logic_Result__c = true;
            evalValIns.Result__c = 'Missing';
            evalValIns.Show_In_Report__c = true;
            evalValIns.Plant_Asset__c = plantAsset.Id;
            evalValIns.Evaluation__c = evaluationLst[evalIns].Id;
            evalValLst.add(evalValIns);
        }
        insert evalValLst;
        RFIDataCreation.dataFormationForRFI(plantAsset.Id);
        Set<String> evalValChkLst = new Set<String>();
        for(Evaluation_Value__c evalValIns :[SELECT Id, Name, Evaluation__r.RFI_Category__c, Evaluation_Not_Executed__c, Logic_Result__c, Result__c, Show_In_Report__c FROM Evaluation_Value__c WHERE Plant_Asset__c =: plantAsset.Id AND Show_In_Report__c = TRUE AND Result__c !=: Constants.PASS ]){
        	evalValChkLst.add(evalValIns.Evaluation__r.RFI_Category__c);
        }
        List<RFI_Detail__c> rfiItemLst = [SELECT Id, Name, RFI_Number__c FROM RFI_Detail__c WHERE Plant_Asset__c =: plantAsset.Id AND RFI_Category__c IN: evalValChkLst];
        System.assertEquals(rfiInstance.Id, rfiItemLst[0].RFI_Number__c);
    }
    public static testMethod void completenessTest1(){
        List<Plant_Asset__c> plantAssetLst = [SELECT Id, Name, TEM_Version__c, Renewable_Type__c FROM Plant_Asset__c WHERE Customer_Plant_Asset_ID__c ='7777.77.777'];
		Plant_Asset__c plantAsset =  plantAssetLst[0];
        List<Core_Attribute__c> coreAttrLst  = [SELECT Id, Name FROM Core_Attribute__c WHERE TEM_Version__c =: plantAsset.TEM_Version__c];
        Prompt_Information__c p1PromptInfo = [SELECT Id, Name FROM Prompt_Information__c WHERE TEM_Version__c =: plantAsset.TEM_Version__c LIMIT 1];
        List<Base_Asset_Template__c> p1PromptBaseAsset = [SELECT Id, Name FROM Base_Asset_Template__c WHERE TEM_Version__c =: plantAsset.TEM_Version__c];
        Site_Metadata__c p1SiteMetaData = [SELECT Id, Name, Attribute_Info__c FROM Site_Metadata__c WHERE Plant_Asset__c =: plantAsset.Id AND Base_Asset_Template__c =: p1PromptBaseAsset[0].id LIMIT 1];
      	
        List<Attribute_Value__c> attrValueLst = new List<Attribute_Value__c>();
        for(integer j = 0; j < coreAttrLst.size(); j++){
            Attribute_Value__c attributeValue = new Attribute_Value__c();
            attributeValue.Plant_Asset__c = plantAsset.Id;
            attributeValue.Site_Metadata__c = p1SiteMetaData.Id;
            attributeValue.Prompt_Information__c = p1PromptInfo.Id; 
            attributeValue.Base_Asset_Template__c = p1PromptBaseAsset[0].id;
            attributeValue.Value__c = (math.mod(j,2) == 0) ? '3' : '';
            attributeValue.Attribute__c = coreAttrLst[j].Id;
            attrValueLst.add(attributeValue);
        }
        insert attrValueLst;
        
		List<Attribute_Value__c> attrValueLst1 = [SELECT Id, Name FROM Attribute_Value__c WHERE Plant_Asset__c =: plantAsset.Id];
        
        List<Id> promptInfo = new List<Id>();
        ReportDataHandler ReportDataHandlerCls = new ReportDataHandler();
        ReportDataHandlerCls.queryExsistingReportData(plantAsset.Id, promptInfo);
        
        List<Asset_Builder_Report_Data__c> reportDataHldr1 = [SELECT Id, Name FROM Asset_Builder_Report_Data__c WHERE Plant_Asset__c =: plantAsset.Id];
        RFIDataCreation.dataFormationForRFI(plantAsset.Id);
        
        Set<String> baseAssetChkLst = new Set<String>();
        for(Base_Asset_Template__c baseAssetIns :[SELECT Id, Name, RFI_Category__c FROM Base_Asset_Template__c WHERE TEM_Version__c =: plantAsset.TEM_Version__c AND Name LIKE 'Base P%']){
            baseAssetChkLst.add(baseAssetIns.RFI_Category__c);
        }
        List<RFI_Detail__c> rfiItemLst = [SELECT Id, Name FROM RFI_Detail__c WHERE Plant_Asset__c =: plantAsset.Id];
    }*/
}