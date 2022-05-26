/**
 * TODO - Calls from SiteMetaDataHandler when Site Metadata is created or updated.
 * Create or update Attribute Value against Site Metadata for particular Plant Asset.
 */
public with Sharing class AttributeValueObjDataHandler {
    public DateTime lastPromptInitiatedId;
    public String plantAssetId;
    public String plantAssetPromptDetail;
    /*
    * Attribute Value is created based on the Attribute in Base Asset Template from Site Metadata. 
    * @param {List<Id>} siteMetaDataIdLst - List of Site Metadata need for creation or updation of Attribute Value.
    * @param {DateTime} lastPromptInitiatedId - Initiated date and time for track the execution process.
    * @param {String} plantAssetPromptDetail - Track updates of Attribute value Creation/Updation against Plant Asset.
    * @param {String} plantAssetId - Attribute Value against Plant Asset
    */
    public static void createOrUpdateAttrValueRecs(List<Id> siteMetaDataIdLst, DateTime lastPromptInitiatedId, 
        String plantAssetPromptDetail, String plantAssetId){
        Plant_Asset_Prompt_Detail__c pltAstPrtDtl = [SELECT Id, Name, Last_Attr_Value_Process_Initiated_DT__c 
                    FROM Plant_Asset_Prompt_Detail__c 
                    WHERE Id =: plantAssetPromptDetail AND Is_Deleted__c = FALSE];
        try{
            lastPromptInitiatedId = lastPromptInitiatedId;
            plantAssetId = plantAssetId;
            plantAssetPromptDetail = plantAssetPromptDetail;

            Set<Id> baseAssetId = new Set<Id>();
            Set<Id> promptInfoId = new Set<Id>();
            List<Site_Metadata__c> siteMetaData = new List<Site_Metadata__c>();
    		
            for(Site_Metadata__c strInstance : [SELECT Id, Name, Attribute_Info__c, Base_Asset_Template__c, Account_Plant__c, 
                                                Prompt_Specific_Info__c, Prompt_Information__c, Plant_Asset_Prompt_Detail__r.Is_Deleted__c
                                                FROM Site_Metadata__c 
                                                WHERE Id IN: siteMetaDataIdLst AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = FALSE]){
                baseAssetId.add(strInstance.Base_Asset_Template__c);
                promptInfoId.add(strInstance.Prompt_Information__c);
                siteMetaData.add(strInstance);
            }
            Map<String, Core_Attribute__c> attrNameToAttrInfo = new Map<String, Core_Attribute__c>();
    
            if(baseAssetId.size() > 0){
                for(Core_Attribute__c attrInfo : [SELECT  Id, Alias__c, Base_Asset_Name__c, Attribute_Master__r.Name,
                                                    Attribute_Master__r.Data_Type__c,Default_value__c, Prompt_Information__c
                                                FROM    Core_Attribute__c
                                                WHERE   (Base_Asset_Name__c IN:baseAssetId OR Prompt_Information__c IN:promptInfoId)]){   
                    String attributeUniqueCheck = String.isNotBlank(attrInfo.Base_Asset_Name__c) ? attrInfo.Base_Asset_Name__c+'-'+attrInfo.Attribute_Master__r.Name : attrInfo.Prompt_Information__c+'-'+attrInfo.Attribute_Master__r.Name;
                    attrNameToAttrInfo.put(attributeUniqueCheck, attrInfo);
                } 
            }
    
            List<Attribute_Value__c> attrValueCreateOrUpdateList = new List<Attribute_Value__c>();
            for(Site_Metadata__c siteMetaDataInstance : siteMetaData){
                Map<String,String> coreAttributeInfoMap = 
                            (Map<String, String>) System.JSON.deserialize(siteMetaDataInstance.Attribute_Info__c,Map<String, String>.class);
                Map<String,String> promptSpecificInfoMap = 
                            (Map<String, String>) System.JSON.deserialize(siteMetaDataInstance.Prompt_Specific_Info__c,Map<String, String>.class);     
                for(String attrName : coreAttributeInfoMap.keySet()){
                    //Formed unique value to conform Attribute related to specific Base Asset Template
                    String baseAstNameAttrName = siteMetaDataInstance.Base_Asset_Template__c+'-'+attrName;
                    if(attrNameToAttrInfo.containsKey(baseAstNameAttrName)){
                        Attribute_Value__c attrValue = attributeValueFormation(siteMetaDataInstance, coreAttributeInfoMap, baseAstNameAttrName, attrNameToAttrInfo);
                        attrValueCreateOrUpdateList.add(attrValue);
                    }
                }
                for(String attrName : promptSpecificInfoMap.keySet()){
                    //Formed unique value to conform Attribute related to specific Prompt information
                    String promptInfoNameAttrName = siteMetaDataInstance.Prompt_Information__c+'-'+attrName;
                    if(attrNameToAttrInfo.containsKey(promptInfoNameAttrName)){
                        Attribute_Value__c attrValue = attributeValueFormation(siteMetaDataInstance, promptSpecificInfoMap, promptInfoNameAttrName, attrNameToAttrInfo);
                        attrValueCreateOrUpdateList.add(attrValue);
                    }
                }
            }
            //Update the Plant Asset Prompt Detail to track the creation process
            pltAstPrtDtl.Last_Attr_Value_Process_Initiated_DT__c = lastPromptInitiatedId;
            if(attrValueCreateOrUpdateList.size()>0){
                upsert attrValueCreateOrUpdateList External_ID__c;
                update pltAstPrtDtl;
            }
            
        }catch(Exception exceptionDetails){
            pltAstPrtDtl.Last_Attr_Value_Process_Initiated_DT__c = null;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('createOrUpdateAttrValueRecs',exceptionDetails.getMessage(), 
                exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetail);
            insert errorLogInstance;
            update pltAstPrtDtl;
        }
        
    }
	/*
    * Form attribute value based on site metadata and attribute
    * @param {Site_Metadata__c} siteMetaDataInstance - Site Metadata needed for creation or updation of Attribute Value.
    * @param {Map<String,String>} infoMap - Set of information, it may be attribute info or prompt specific info.
    * @param {String} AttrName - Attribute name that needed to create attribute value.
    * @param {Map<String, Core_Attribute__c>} attrNameToAttrInfo - Attribute Value against Plant Asset
    */
    public static Attribute_Value__c attributeValueFormation(Site_Metadata__c siteMetaDataInstance, Map<String,String> infoMap, String AttrName, Map<String, Core_Attribute__c> attrNameToAttrInfo){
        Attribute_Value__c attrValue = new Attribute_Value__c();
        attrValue.Account_Plant__c = siteMetaDataInstance.Account_Plant__c;
        attrValue.Site_Metadata__c = siteMetaDataInstance.Id;
        attrValue.Prompt_Information__c = siteMetaDataInstance.Prompt_Information__c; 
        attrValue.Base_Asset_Template__c = siteMetaDataInstance.Base_Asset_Template__c;
        String attrNameWithoutBAT = AttrName.split('-')[1];
        attrValue.Value__c = String.isNotBlank(infoMap.get(attrNameWithoutBAT)) ? infoMap.get(attrNameWithoutBAT) : attrNameToAttrInfo.get(AttrName).Default_value__c;
        Core_Attribute__c coreAttr = attrNameToAttrInfo.get(AttrName);
        attrValue.Attribute__c = coreAttr.Id;
        attrValue.External_ID__c = attrValue.Account_Plant__c+'-'+attrValue.Site_Metadata__c+'-'+attrValue.Attribute__c;
        String dataType = attrNameToAttrInfo.get(AttrName).Attribute_Master__r.Data_Type__c;
        if(String.isNotBlank(attrValue.Value__c)){
            String valueToCheck = attrValue.Value__c;
            if(dataType == 'Decimal'){
                attrValue.Value_Floating__c = valueToCheck.isNumeric()? Decimal.valueOf(attrValue.Value__c) : null; 
            }else if(dataType == 'Date'){
                attrValue.Value_Date__c = Date.valueOf(attrValue.Value__c);
            }else if(dataType == 'Checkbox'){
                attrValue.Value_Checkbox__c = Boolean.valueOf(attrValue.Value__c);
            }else if(dataType == 'Number'){
                attrValue.Value_Number__c = valueToCheck.isNumeric()? Integer.valueOf(attrValue.Value__c) : null;
            }                                            
        }
        return attrValue;
    }
}