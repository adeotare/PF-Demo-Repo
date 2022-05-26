/**
**/
@istest
public with sharing class TestDataFactory {
    public static Account_Plant__c createPlantAsset(String renewableType, String pfServiceProduct, String customerPlantAsset, id temVersionid ){
        Id customerPlantAssetRT = Utils.getRecordTypeInfo('Account_Plant__c','Child_Asset').getRecordTypeId();
        Id parentPlantAssetRT = Utils.getRecordTypeInfo('Account_Plant__c','Parent_Asset').getRecordTypeId();
        
        Account_Plant__c parentPlantAsset = new Account_Plant__c();
//        parentPlantAsset.Name = 'Parent Plant Asset';
//        parentPlantAsset.Plant_Name__c = 'Plant Asset';
//        parentPlantAsset.Renewable_Type__c = renewableType;
//        parentPlantAsset.RecordTypeId = parentPlantAssetRT;
        insert parentPlantAsset;
        
        Account_Plant__c plantAsset = new Account_Plant__c();
//        plantAsset.Name = 'Test Plant';
//        plantAsset.Renewable_Type__c = renewableType;
//        plantAsset.PF_Service_Product__c = pfServiceProduct;
//        plantAsset.Customer_Plant_Asset_ID__c  = customerPlantAsset;
        plantAsset.TEM_Version__c = temVersionid;
//        plantAsset.RecordTypeId = customerPlantAssetRT;
//        plantAsset.Parent__c = parentPlantAsset.Id;
        return plantAsset;
    }

    public static Site_Metadata__c createG1SiteMetadata(Id plantAssetId){
        Site_Metadata__c g1SiteMetaData = new Site_Metadata__c(); 
        g1SiteMetaData.Name = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT;
        g1SiteMetaData.Prompt_Specific_Info__c = '{"Switchgear Substation":"3","Metmast":"2","PF Service Product":"Drive;FSM"}';
        g1SiteMetaData.Attribute_Info__c = '{}';
        g1SiteMetaData.Account_Plant__c = plantAssetId;
        return g1SiteMetaData;
    }
    
    public static Base_Asset_Template__c createBaseAssetTemplate(String baseAssetName, Id temVersionId){
        Base_Asset_Template__c baseAssettemplate = new Base_Asset_Template__c();
        baseAssettemplate.Name = baseAssetName;
        baseAssettemplate.TEM_Version__c = temVersionId;
        baseAssettemplate.RFI_Category_Name__c = baseAssetName;
        return baseAssettemplate;
    }
    
    public static Prompt_Information__c createPromptInformation(String promptName, Id baseAssetId, Id temVersionId){
        Prompt_Information__c promptInformation = new Prompt_Information__c();
        promptInformation.Name = promptName;
        promptInformation.Base_Asset_Template__c = baseAssetId;
        promptInformation.TEM_Version__c = temVersionId;
        return promptInformation;
    }
    
    public static Core_Attribute__c createCoreAttribute(String attributeName, String type, String dataType, 
                                                        Id recordTypeId, Id picklistMasterId, Id baseAssetId, Id temVersionId){
        Attribute_Master__c attrMaster = new Attribute_Master__c();
        attrMaster.Name = attributeName;
        attrMaster.Alias__c = attributeName; 
        attrMaster.Data_Type__c = dataType;
        attrMaster.Units__c = 'ampere';
        attrMaster.Type__c = type;
        attrMaster.TEM_Version__c = temVersionId;
        insert attrMaster;
        
        Core_Attribute__c coreAttribute = new Core_Attribute__c();
        coreAttribute.Name = attributeName;                                                
        coreAttribute.Attribute_Master__c = attrMaster.Id;
        coreAttribute.RecordTypeId = recordTypeId;
        if(picklistMasterId != null){
            coreAttribute.Picklist_Master__c = picklistMasterId;
            }
        coreAttribute.Base_Asset_Name__c = baseAssetId;
        coreAttribute.TEM_Version__c = temVersionId;
        return coreAttribute;
    }
    
    public static Core_Attribute__c createPromptSpecificAttr(String attributeName, String type, String dataType, 
                                                            Id recordTypeId, Id picklistMasterId, Id promptInfoId, Id temVersionId){
        Attribute_Master__c attrMaster = new Attribute_Master__c();
        attrMaster.Name = attributeName;
        attrMaster.Alias__c = attributeName; 
        attrMaster.Data_Type__c = dataType;
        attrMaster.Units__c = 'ampere';
        attrMaster.Type__c = type;
        attrMaster.TEM_Version__c = temVersionId;
        insert attrMaster;

        Core_Attribute__c coreAttribute = new Core_Attribute__c();
        coreAttribute.Attribute_Master__c = attrMaster.Id;
        coreAttribute.RecordTypeId = recordTypeId;
        if(picklistMasterId != null){
            coreAttribute.Picklist_Master__c = picklistMasterId;
            }
        coreAttribute.Prompt_Information__c = promptInfoId;
        coreAttribute.TEM_Version__c = temVersionId;
        return coreAttribute;
    }

    public static Attribute_Requirement__c createAttributeRequirement(String systemValue, String requiredValue, Id coreAttrId, Id temVersionId){
        Attribute_Requirement__c attrbuteReq = new Attribute_Requirement__c();
        attrbuteReq.Required__c = requiredValue;
        attrbuteReq.System__c = systemValue;
        attrbuteReq.Core_Attribute__c = coreAttrId;
        attrbuteReq.TEM_Version__c = temVersionId;
        return attrbuteReq;
    }

    public static Picklist_Master__c createPicklistMaster(String masterName, Id temVersion){
        Picklist_Master__c picklistMaster = new Picklist_Master__c();
        picklistMaster.Name = masterName;
        picklistMaster.TEM_Version__c = temVersion;
        return picklistMaster;
    }

    public static Picklist_Detail__c createPicklistValue(Id picklistMaster, Id temVersion){
        Picklist_Detail__c picklistValue = new Picklist_Detail__c();
        picklistValue.Name = 'Yes';
        picklistValue.Is_Active__c = true;
        picklistValue.TEM_Version__c = temVersion;
        picklistValue.Picklist_Master__c = picklistMaster;
        return picklistValue;
    }

    public static TEM_Version__c createTemVersion(String status){
        TEM_Version__c temVersion = new TEM_Version__c();
        temVersion.Status__c = status;
        return temVersion;
    }

    public static Metric_Definition__c createMetricDef(String baseAssetTemplate, String attr, String mod1, String mod2, String mod2Value, String temVersion, String recordType){
        Metric_Definition__c metricDef = new Metric_Definition__c();
        if(String.isNotBlank(baseAssetTemplate)){
            metricDef.Base_Asset_Template__c = baseAssetTemplate;
        }
        if(String.isNotBlank(attr)){
            metricDef.Attribute__c = attr;
        }
        metricDef.TEM_Version__c = temVersion;
        metricDef.Modifer_1__c = mod1;
        if(String.isNotBlank(mod2)){
            metricDef.Modifer_2__c = mod2;
            metricDef.Modifer_2_Value__c = mod2Value;
        }
        metricDef.RecordTypeId = recordType;
        return metricDef;
    }

    public static Metric_Value__c createMetricValue(String metricDef, String plantAsset, String value, String dataType){
        Metric_Value__c metricValue = new Metric_Value__c();
        metricValue.Metric_Definition__c = metricDef;
        metricValue.Account_Plant__c = plantAsset;
        if(dataType == 'Number'){
            metricValue.Value__c = String.valueOf(123456);
        }else if(dataType == 'Decimal'){
            metricValue.Value__c = String.valueOf(100.05);
        }else if(dataType == 'Date'){
            metricValue.Value__c = String.valueOf(Date.newInstance(2016, 12, 9));
        }else if(dataType == 'Checkbox'){
            metricValue.Value__c = String.valueOf(TRUE);        
        }else {
            metricValue.Value__c = 'TEXT'; 
        }
        metricValue.Data_Type__c = dataType;
        return metricValue;
    }
    
    public static Evaluation__c createEvaluation(String name, String category, String products, String renewable, String subCategory, 
                                                 String group1, String group2, String temVersion, String component1, String component2, 
                                                 String component3, String operand1, String operand2, String result, 
                                                 String resultComponent1, String resultComponent2){
                                                Base_Asset_Template__c p2PromptBaseAsset = TestDataFactory.createBaseAssetTemplate(Constants.BASE_BLOCK, temVersion);
                                                    insert p2PromptBaseAsset;
                                                Prompt_Information__c p2PromptInfo = TestDataFactory.createPromptInformation(Constants.P2_BLOCK_INFO_AND_PAD_COUNTS,
                                                                                            p2PromptBaseAsset.Id, temVersion);
                                                    insert p2PromptInfo;
        
        Evaluation__c eval1 = new Evaluation__c();
        eval1.Name = name;
        eval1.Category__c = category;
        eval1.Component_1__c = component1;
        eval1.Component_2__c = component2;
        eval1.Prompt_Information__c = p2PromptInfo.Id;
        if(String.isNotBlank(component3)){                                            
        	eval1.Component_3__c = component3;
        }
        eval1.Products__c = products;
        eval1.Renewable__c = renewable;
        eval1.Operand_1__c = operand1;
       	if(String.isNotBlank(operand2)){
        	eval1.Operand_2__c = operand2;
        }
        eval1.Result__c = result;
        if(String.isNotBlank(resultComponent1)){
        	eval1.Result_Component_1__c = resultComponent1;
        }
        if(String.isNotBlank(resultComponent2)){
        	eval1.Result_Component_2__c = resultComponent2;
        }
        eval1.Sub_Category__c = subCategory;
        eval1.TEM_Version__c = temVersion;
        eval1.Group_1__c = 'Missing or Invalid Metadata - Inverter';
        eval1.Group_2__c = 'Other Miscellaneous';
        return eval1;
    }

    public static Plant_Asset_Prompt_Detail__c createPlantAssetPromptDetail(String name, String plantAssetId, String promptInformationId){
        return new Plant_Asset_Prompt_Detail__c(Name = name, Account_Plant__c = plantAssetId, Prompt_Information__c = promptInformationId);
    }

    public static Site_Metadata__c createSiteMetadata(String name, Id plantAssetId, Id promptInformationId, String promptSpecificInfo, Id plantAssetPrmptDtlId, String attributeInfo, String baseAssetId){
        return new Site_Metadata__c(Name = name,
        Account_Plant__c = plantAssetId, 
                    Prompt_Information__c = promptInformationId,
                    Prompt_Specific_Info__c = promptSpecificInfo, 
                    Attribute_Info__c = attributeInfo,
                    Plant_Asset_Prompt_Detail__c = plantAssetPrmptDtlId,
                    Base_Asset_Template__c = baseAssetId);
    }
    
    public static Asset_Builder_Report_Data__c createCompletenessReportData(String plantAssetId, String promptInformationId, String baseAssetId,
                                                                           Integer completedAttrCount){
        return new Asset_Builder_Report_Data__c(Account_Plant__c = plantAssetId, 
                                                Prompt_Information__c = promptInformationId,
                                                Base_Asset_Template__c = baseAssetId,
                                                Type__c = 'Required',
                                                System__c = 'Drive',
                                                Total_Attribute_Count__c = 9,
                                                Total_Completed_Attribute_Count__c = completedAttrCount);
    }
}