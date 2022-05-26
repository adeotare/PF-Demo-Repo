/*
Author : 
Date : 
Description : 
- The is helper class to have reusable methods across all asset builder controllers.
*/

public inherited sharing class Utils {
    /*
To get Record Type Id
*/
    public static Map<String,SObjectType> sObjectTypeMap = Schema.getGlobalDescribe();
    
    public static Schema.RecordTypeInfo getRecordTypeInfo(String sObjectName, String recordTypeDeveloperName){
        Map<String,Schema.RecordTypeInfo> recordTypeInfoByName = sObjectTypeMap.get(sObjectName).getDescribe().getRecordTypeInfosByDeveloperName();
        return recordTypeInfoByName.get(recordTypeDeveloperName);
    }
    
    /*
Query Plant Asset Record
*/
    public static Account_Plant__c queryPlantAsset(Id plantAssetId){
        return [SELECT Id, Name, Commercial_Operating_Date__c, Latitude__c, Longitude__c, PF_Service_Product__c, 
                Asset_Builder_Status__c, Plant_Name__c, Customer_Plant_Asset_ID__c,
                  Renewable_Type__c, TEM_Version__c
                FROM Account_Plant__c WHERE Id =: plantAssetId];
    }
        /*
Query TEM Version Record
    */
    public static List<TEM_Version__c> queryTemVersion(String status){
        return [SELECT Id, Name, Status__c FROM TEM_Version__c WHERE Status__c =: status];
    }
    /*
Query Prompt Information Record
*/
    public static Prompt_Information__c queryPromptInfo(String currentPromptName, String plantAssetId){
        Account_Plant__c plantAsset = queryPlantAsset(plantAssetId);
        return [SELECT Id, Name, Base_Asset_Template__c, Prompt_Id__c, Confirm_Message_On_Next__c, Show_Popup_On_Next_Button__c, 
                Base_Asset_Template__r.Asset_Short_Name__c, Alias__c, Type__c, Confirm_Message_On_Delete__c, TEM_Version__c
                FROM Prompt_Information__c 
                WHERE Name =: currentPromptName AND TEM_Version__c =: plantAsset.TEM_Version__c];
    }
    
    /*
get core attrbute based on Attribute Requirement record
*/
    public static Map<String, Set<Id>> getCoreAttrIdsBasedOnAttrRequirement(Id plantAssetId){
        Set<Id> coreAttrIds = new Set<Id>();
        Set<Id> allCoreAttrIds = new Set<Id>();

	      Map<String, Set<Id>> setOfIdsMap = new Map<String, Set<Id>>();
        String productAttrName = Constants.PF_SERVICE_PRODUCT;
        List<String> systemNames = new List<String>();
        Account_Plant__c plantAsset = queryPlantAsset(plantAssetId);
        List<String> promptSpecificInfoLst = new List<string>();
        List<site_metadata__c> g1SiteMetadata = 
                                Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);

        if(g1SiteMetadata.size()>0){
            for(site_metadata__c productInfo : g1SiteMetadata){
                Map<String, String> promptSpecificInfoMap =
                                        (Map<String, String>) System.JSON.deserialize(productInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                if(promptSpecificInfoMap.containsKey(productAttrName)){   
                    promptSpecificInfoLst = promptSpecificInfoMap.get(productAttrName).split(';');   
                } 
            }
        }
        else{
            if(!String.isBlank(plantAsset.PF_Service_Product__c)){
                promptSpecificInfoLst = plantAsset.PF_Service_Product__c.split(';');
            }
        }
        
        Map<String,String> pfServiceProductToAttrReqCustomMetadatamap = new Map<String,String>();
        for(PFServiceProductToAttrRequirementMapping__mdt pfServiceProductToAttrReq : [SELECT   Id, DeveloperName, 
                                                                                                AttributeRequirement__c 
                                                                                        FROM  PFServiceProductToAttrRequirementMapping__mdt ]){
            pfServiceProductToAttrReqCustomMetadatamap.put(pfServiceProductToAttrReq.DeveloperName,pfServiceProductToAttrReq.AttributeRequirement__c);
        }

        if(promptSpecificInfoLst.size() > 0){
            for(String pfServiceProductCustomMetadata : pfServiceProductToAttrReqCustomMetadatamap.keySet()){
            
                if(promptSpecificInfoLst.contains(pfServiceProductCustomMetadata)){ 
                    systemNames.add(pfServiceProductToAttrReqCustomMetadatamap.get(pfServiceProductCustomMetadata));
                }
            }
        }
       
        if(systemNames.size()<=0){
            systemNames.addAll(pfServiceProductToAttrReqCustomMetadatamap.values());
        }
        
        for(Attribute_Requirement__c attrRequirement : [SELECT  Id, Name, Core_Attribute__c, Required__c, System__c,TEM_Version__c
                                                        FROM    Attribute_Requirement__c 
                                                        WHERE   System__c IN: systemNames AND TEM_Version__c =: plantAsset.TEM_Version__c]){
            if(attrRequirement.Required__c == Constants.YES || attrRequirement.Required__c == Constants.NO){
                coreAttrIds.add(attrRequirement.Core_Attribute__c);
            }
            allCoreAttrIds.add(attrRequirement.Core_Attribute__c);
        }
        setOfIdsMap.put(Constants.ALL,allCoreAttrIds);
        setOfIdsMap.put(Constants.FILTERED,coreAttrIds);
        return setOfIdsMap;
    }
    
    /*
Query Core Attribute Record
*/
    public static List<Core_Attribute__c> queryCoreAttributes(Id baseAssetId, Set<Id> attributesId){
        return [SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c,Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, Attribute_Master__r.UI_Column_Size__c   
                FROM Core_Attribute__c 
                WHERE Base_Asset_Name__c =: baseAssetId 
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Metadata'
                    AND Id IN: attributesId
                ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name];
    }

    
        /*
    Query Core Attribute Record for P7 Prompt
    */
    public static List<Core_Attribute__c> queryCoreAttributesP7(Id baseAssetId, Set<Id> attributesId, Boolean bifacialModules){
        List<Core_Attribute__c> coreAtt = new List<Core_Attribute__c>();
        if(bifacialModules){
            coreAtt.addAll([SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c,Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, Attribute_Master__r.UI_Column_Size__c, Is_Related_Subarray_Bifacial__c   
                FROM Core_Attribute__c 
                WHERE Base_Asset_Name__c =: baseAssetId 
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Metadata'
                    AND Id IN: attributesId
                ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name]);
        }else{
            coreAtt.addAll([SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c,Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, Attribute_Master__r.UI_Column_Size__c, Is_Related_Subarray_Bifacial__c   
                FROM Core_Attribute__c 
                WHERE Base_Asset_Name__c =: baseAssetId 
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Metadata'
                    AND Id IN: attributesId
                    AND Is_Related_Subarray_Bifacial__c = false AND Attribute_Master__r.Name != 'SUBARRAY_BIFACIAL'
                ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name]);
        }
        return coreAtt;
    }
    
    /*
Query Core Attribute Record Based on BaseAssetId Set
*/
    public static List<Core_Attribute__c> queryAllAttributes(Set<Id> baseAssetIdSet, Set<Id> attributesId){
        return [SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c,Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, Attribute_Master__r.UI_Column_Size__c
                FROM Core_Attribute__c 
                WHERE Base_Asset_Name__c IN: baseAssetIdSet 
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Metadata'
                    AND Id IN: attributesId
                ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name];
    }
    /*
Query Prompt Attribute Record
*/
    public static List<Core_Attribute__c> queryPromptAttributes(Id promptInfoId, String plantAssetId){
        Account_Plant__c plantAsset = queryPlantAsset(plantAssetId);
        return [SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c, Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,Is_Asset_Name__c, Is_Alternate_Parent__c, 
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, TEM_Version__c, Attribute_Master__r.UI_Column_Size__c
                FROM Core_Attribute__c 
                WHERE Prompt_Information__c =: promptInfoId AND TEM_Version__c =: plantAsset.TEM_Version__c
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Prompt Specific'
                ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name];
    }

    /*
    Query Prompt Attribute Record for Bifacial Subarray
    */
    public static List<Core_Attribute__c> queryPromptAttributesM1(Id promptInfoId, String plantAssetId, Boolean isBifacialSubarray){
        Account_Plant__c plantAsset = queryPlantAsset(plantAssetId);
        List<Core_Attribute__c> promptAttrs = new List<Core_Attribute__c>();
        if(isBifacialSubarray){
            promptAttrs.addAll([SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c, Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,Is_Asset_Name__c, Is_Alternate_Parent__c, 
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, TEM_Version__c, Attribute_Master__r.UI_Column_Size__c
                FROM Core_Attribute__c 
                WHERE Prompt_Information__c =: promptInfoId AND TEM_Version__c =: plantAsset.TEM_Version__c
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Prompt Specific'
                ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name]);
        }else{
            promptAttrs.addAll([SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c, Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,Is_Asset_Name__c, Is_Alternate_Parent__c, 
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, TEM_Version__c, Attribute_Master__r.UI_Column_Size__c
                FROM Core_Attribute__c 
                WHERE Prompt_Information__c =: promptInfoId AND TEM_Version__c =: plantAsset.TEM_Version__c
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Prompt Specific'
                    AND Is_Related_Subarray_Bifacial__c = false
                ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name]);
        }
        return promptAttrs;
    }

    /*
Query Asset Name Prompt Attribute Record
*/
    public static String queryAssetNameAttr(Id promptInfoId){
        String assetNameAttr = '';
        for(Core_Attribute__c attrRecord : [SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c, Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c, Required__c,
                    Plant_Asset_Field_Name__c,Customer_Facing_Notes__c,Attribute_Master__r.Customer_Facing_Notes__c, Key_Field_To_Generate_Rows__c
                FROM Core_Attribute__c 
                WHERE Prompt_Information__c =: promptInfoId 
                    AND Is_Asset_Name__c = True
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
                ]){
            assetNameAttr = attrRecord.Attribute_Master__r.Name;
        }

        return assetNameAttr;
    }

    /*
Query Alternate Parent Name Prompt Attribute Record
*/
public static String queryAlternateParentAttr(Id promptInfoId){
    String assetNameAttr = '';
    for(Core_Attribute__c attrRecord : [SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                Base_Asset_Name__c, Prompt_Information__c, Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c, Required__c,
                Plant_Asset_Field_Name__c,Customer_Facing_Notes__c,Attribute_Master__r.Customer_Facing_Notes__c, Key_Field_To_Generate_Rows__c
            FROM Core_Attribute__c 
            WHERE Prompt_Information__c =: promptInfoId 
                AND Is_Alternate_Parent__c = True
                AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
            ]){
        assetNameAttr = attrRecord.Attribute_Master__r.Name;
    }
    return assetNameAttr;
}
    
    /*
Query Site Metadata Record
*/  
    @AuraEnabled
    public static List<Site_Metadata__c> querySiteMetadata(String promptName, Id plantAssetId){
        return [SELECT Id, Name, Attribute_Info__c, Base_Asset_Template__c, Account_Plant__c, Parent_Site_Metadata__r.Asset_Name__c, Account_Plant__r.TEM_Version__r.Name,
                Prompt_Specific_Info__c, Parent_Site_Metadata__c, Parent_Site_Metadata__r.Name, Previous_Prompt_Name__c, Plant_Asset_Prompt_Detail__c, Account_Plant__r.TEM_Version__c,
                Parent_Site_Metadata__r.Alternate_Parent_Site_Metadata__r.Asset_Name__c, Alternate_Parent_Site_Metadata__c, Plant_Asset_Prompt_Detail__r.Is_Deleted__c,
                Plant_Asset_Prompt_Detail__r.Prompt_Information__r.Type__c, Parent_Asset_Short_Name__c, Asset_Short_Name__c, Is_Attribute_Value_Modified_in_Prompt__c, 
                Base_Asset_Template__r.Asset_Short_Name__c, Parent_Site_Metadata__r.Parent_Asset_Short_Name__c,  Account_Plant__r.Plant_Name__c, Plant_Asset_Prompt_Detail__r.Account_Plant__c,
                Parent_Site_Metadata__r.Asset_Short_Name__c,Account_Plant__r.Customer_Plant_Asset_ID__c, Asset_Name__c,Prompt_Information__c FROM Site_Metadata__c 
                WHERE Name =: promptName AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false
                AND Account_Plant__c =: plantAssetId AND Plant_Asset_Prompt_Detail__r.Account_Plant__c <> NULL ORDER BY Asset_Name__c ASC];
    }

    /*
Query Site Metadata Record
*/
@AuraEnabled
public static List<Site_Metadata__c> querySortedSiteMetadata(String promptName, Id plantAssetId){
    return [SELECT Id, Name, Attribute_Info__c, Base_Asset_Template__c, Account_Plant__c, Parent_Site_Metadata__r.Asset_Name__c,
            Prompt_Specific_Info__c, Parent_Site_Metadata__c, Parent_Site_Metadata__r.Name, Previous_Prompt_Name__c, Plant_Asset_Prompt_Detail__c,
            Parent_Site_Metadata__r.Alternate_Parent_Site_Metadata__r.Asset_Name__c, Alternate_Parent_Site_Metadata__c, Plant_Asset_Prompt_Detail__r.Is_Deleted__c,
            Plant_Asset_Prompt_Detail__r.Prompt_Information__r.Type__c, Parent_Asset_Short_Name__c, Asset_Short_Name__c, Is_Attribute_Value_Modified_in_Prompt__c,
            Base_Asset_Template__r.Asset_Short_Name__c, Parent_Site_Metadata__r.Parent_Asset_Short_Name__c, Account_Plant__r.Plant_Name__c, Plant_Asset_Prompt_Detail__r.Account_Plant__c,
            Parent_Site_Metadata__r.Asset_Short_Name__c,Account_Plant__r.Customer_Plant_Asset_ID__c FROM Site_Metadata__c 
            WHERE Name =: promptName AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false
            AND Account_Plant__c =: plantAssetId AND Plant_Asset_Prompt_Detail__r.Account_Plant__c <> NULL ORDER BY Parent_Site_Metadata__r.Asset_Name__c, Asset_Name__c ASC];
}
    
    /*
form datatable inputs
*/
    public static Map<String,Object> getDatatableInputsMap(
        List<Core_Attribute__c> coreAttrs,
        List<Core_Attribute__c> promptInfoAttrs,
        List<Site_Metadata__c> siteMetadataRecords,
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail,
        Prompt_Information__c promptInfo
    ){
        Map<String,Map<String,String>> picklistValuesToPicklistMasterMap = new Map<String,Map<String,String>>();
        picklistValuesToPicklistMasterMap = getPicklistValues(plantAssetPromptDetail.Account_Plant__r.TEM_Version__c);
        
        Map<String,Object> customDatatableCompInputsMap = new Map<String,Object>();
        customDatatableCompInputsMap.put('CoreAttributes', coreAttrs);
        customDatatableCompInputsMap.put('PromptSpecificAttributes', promptInfoAttrs);
        customDatatableCompInputsMap.put('SiteMetadataRecords', siteMetadataRecords);
        customDatatableCompInputsMap.put('Picklist', picklistValuesToPicklistMasterMap);  
        customDatatableCompInputsMap.put('PlantAssetPromptDetail', plantAssetPromptDetail);  
        customDatatableCompInputsMap.put('PromptInfo', promptInfo);  

        return customDatatableCompInputsMap;
    }

    public static Map<String,Object> getDatatableInputsMapWithoutSiteMetadata(
        List<Core_Attribute__c> coreAttrs,
        List<Core_Attribute__c> promptInfoAttrs,
        Integer siteMetadataRecords,
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail,
        Prompt_Information__c promptInfo
    ){
        Map<String,Map<String,String>> picklistValuesToPicklistMasterMap = new Map<String,Map<String,String>>();
        picklistValuesToPicklistMasterMap = getPicklistValues(plantAssetPromptDetail.Account_Plant__r.TEM_Version__c);
        
        Map<String,Object> customDatatableCompInputsMap = new Map<String,Object>();
        customDatatableCompInputsMap.put('CoreAttributes', coreAttrs);
        customDatatableCompInputsMap.put('PromptSpecificAttributes', promptInfoAttrs);
        customDatatableCompInputsMap.put('SiteMetadataRecords', siteMetadataRecords);
        customDatatableCompInputsMap.put('Picklist', picklistValuesToPicklistMasterMap);  
        customDatatableCompInputsMap.put('PlantAssetPromptDetail', plantAssetPromptDetail);  
        customDatatableCompInputsMap.put('PromptInfo', promptInfo);  

        return customDatatableCompInputsMap;
    }
    
    /*
JSON serialize - Attribute Info from List of attribute records
*/
    
    public static String serializeAttribute(List<Core_Attribute__c> attributeInfo){
        Map<String,String> attrNamToValueMap = new Map<String,String>();
        for(Core_Attribute__c attrRecord : attributeInfo){
            attrNamToValueMap.put(attrRecord.Attribute_Master__r.Name, attrRecord.Attribute_Master__r.Data_Type__c == 'Checkbox' ? 'false' : '');
        }
        
        return JSON.serialize(attrNamToValueMap);
    }
    
    /*
JSON deserialize - Attribute Info from JSON String
*/
    
    public static Map<String,String> deserializeAttribute(String attributeInfoJSON){
        Map<String,String> attrNamToValueMap = 
            (Map<String,String>) JSON.deserialize(attributeInfoJSON, Map<String,String>.class);
        
        return attrNamToValueMap;
    }
    
    /*
Form Map<String,String> - Attribute Info Name to Attribute Info Value from list of Core Attribute
*/
    
    public static Map<String,String> formAttributeNametoValueMap(List<Core_Attribute__c> attributeInfo){
        Map<String,String> attrNamToValueMap = new Map<String,String>();
        for(Core_Attribute__c attrRecord : attributeInfo){
            attrNamToValueMap.put(attrRecord.Attribute_Master__r.Name, attrRecord.Attribute_Master__r.Data_Type__c == 'Checkbox' ? 'false' : '');
           }
       return attrNamToValueMap;
    }

    
    /*
This methods to fetch all picklist values of picklist master and it returns map of picklist master id and its picklist values in a set
*/
    public static Map<String,Map<String,String>> getPicklistValues(Id temVersion){
        Map<String,Map<String,String>> picklistValuesToPicklistMasterMap = new Map<String,Map<String,String>>();
        for(Picklist_Detail__c picklistDetail : 
            [SELECT Id, Name, Picklist_Master__c, Picklist_Master__r.Name
             FROM Picklist_Detail__c WHERE Is_Active__c = TRUE AND TEM_Version__c =: temVersion ORDER BY Name ASC]){
                 if(!picklistValuesToPicklistMasterMap.containsKey(picklistDetail.Picklist_Master__c)){
                     picklistValuesToPicklistMasterMap.put(picklistDetail.Picklist_Master__c, new  Map <String,String> { picklistDetail.Name => picklistDetail.Name});
                 }
                 picklistValuesToPicklistMasterMap.get(picklistDetail.Picklist_Master__c).put(picklistDetail.Name,picklistDetail.Name);
             }
        return picklistValuesToPicklistMasterMap;
    }
    
    /*
Success and Error - Next Prompt Navigator
*/
    public static String nextPromptFinderResponse(String plantAssetId,
                                                    String currentPromptId,
                                                    String nextPromptId,
                                                    String plantAssetPromptDetailId){//--changed
        Map<String,String> responseMap = new  Map<String,String>();
        
        responseMap.put('plantAssetId',String.isBlank(plantAssetId)?'':plantAssetId);
        responseMap.put('currentPromptId',String.isBlank(currentPromptId)?'':currentPromptId);
        responseMap.put('nextPromptId',String.isBlank(nextPromptId)?'':nextPromptId);
        responseMap.put('plantAssetPromptDetailId',String.isBlank(plantAssetPromptDetailId)?'':plantAssetPromptDetailId);

        return JSON.serialize(responseMap);
    }
    /*
Success and Error - Previous Prompt Navigator
*/
    public static String previousPromptFinderResponse(String plantAssetId,
                                                      String currentPromptId,
                                                      String previousPromptId){
    Map<String,String> responseMap = new  Map<String,String>();
    responseMap.put('plantAssetId',String.isBlank(plantAssetId)?'':plantAssetId);
    responseMap.put('currentPromptId',String.isBlank(currentPromptId)?'':currentPromptId);
    responseMap.put('previousPromptId',String.isBlank(previousPromptId)?'':previousPromptId);
                                                          
        return JSON.serialize(responseMap);
    }
    
    /*
Success and Error - DML
*/
    public static String recordSaveSuccessResponse(String status, 
                                                   String recordId){
        Map<String,String> responseMap = new  Map<String,String>();
        responseMap.put('Status',status);
        responseMap.put('recordId',recordId);
        return JSON.serialize(responseMap);                 
    }

    /* 
This methods to fetch the Next Prompt Id based on previous prompts attribute Count and Renewable values
*/
    @AuraEnabled
    public static String  nextPromptFinder(String currentPromptName,String plantAssetId){
        String nextPromptId;
        try{
            Integer recombinerCount = 0; 
            Integer combinerCount = 0;
            Integer trackerControllerCount = 0;
            Integer tracketMotorCount = 0;
            Integer metMaskCount = 0;
            Integer substationSwitchgearsCount = 0;
            Boolean windCheck = false;
            Boolean w4W5NextPromptCheck = true;
            String otherValue = 'No';
            
            List<Site_Metadata__c> p5PromptSiteMetaData = Utils.querySiteMetadata(Constants.P5_INVERTS_BUILD_AND_COUNTS, plantAssetId);
            for(Site_Metadata__c p5SiteMetadata: p5PromptSiteMetaData){
                Map<String,String> p5PromptSpecificInfoMap = 
                    (Map<String, String>) System.JSON.deserialize(p5SiteMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                if( p5PromptSpecificInfoMap.containsKey(Constants.RECOMBINER_CHANNELS) && p5PromptSpecificInfoMap.get(Constants.RECOMBINER_CHANNELS)!=''){
                    recombinerCount  = + Integer.valueOf(p5PromptSpecificInfoMap.get(Constants.RECOMBINER_CHANNELS));
                }
                if(p5PromptSpecificInfoMap.containsKey(Constants.COMBINER_CHANNELS) && p5PromptSpecificInfoMap.get(Constants.COMBINER_CHANNELS)!=''){
                    combinerCount = +Integer.valueOf(p5PromptSpecificInfoMap.get(Constants.COMBINER_CHANNELS));
                }
            }
            
            List<Site_Metadata__c> p3PromptSiteMetaData = Utils.querySiteMetadata(Constants.P3_PAD_BUILDS_AND_COUNTS, plantAssetId);
            for(Site_Metadata__c p3SiteMetadata: p3PromptSiteMetaData){
                Map<String,String> p3PromptSpecificInfoMap = 
                    (Map<String, String>) System.JSON.deserialize(p3SiteMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                
                if(p3PromptSpecificInfoMap.containsKey(Constants.TRACKER_CONTROLLER) && p3PromptSpecificInfoMap.get(Constants.TRACKER_CONTROLLER) != ''){
                    trackerControllerCount  = + Integer.valueOf(p3PromptSpecificInfoMap.get(Constants.TRACKER_CONTROLLER));
                }
                if(p3PromptSpecificInfoMap.containsKey(Constants.TRACKER_MOTOR) && p3PromptSpecificInfoMap.get(Constants.TRACKER_MOTOR) != ''){
                    tracketMotorCount = +Integer.valueOf(p3PromptSpecificInfoMap.get(Constants.TRACKER_MOTOR));
                }
                
                if(p3PromptSpecificInfoMap.containsKey(Constants.OTHER_ASSETS) && p3PromptSpecificInfoMap.get(Constants.OTHER_ASSETS) != '' ) {
                    if(p3PromptSpecificInfoMap.get(Constants.OTHER_ASSETS) == 'Yes') {
                        otherValue = p3PromptSpecificInfoMap.get(Constants.OTHER_ASSETS);                                                                
                    }
                }
            }
            
            List<Site_Metadata__c> g1PromptSiteMetaData = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);
            for(Site_Metadata__c g1SiteMetadata: g1PromptSiteMetaData){
                Map<String,String> g1PromptSpecificInfoMap = 
                    (Map<String, String>) System.JSON.deserialize(g1SiteMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                
                if(g1PromptSpecificInfoMap.containsKey(Constants.MET_MAST) && g1PromptSpecificInfoMap.get(Constants.MET_MAST) != ''){
                    metMaskCount  = + Integer.valueOf(g1PromptSpecificInfoMap.get(Constants.MET_MAST));
                }
                if(g1PromptSpecificInfoMap.containsKey(Constants.SWITCHGEAR_SUBSTATION) && g1PromptSpecificInfoMap.get(Constants.SWITCHGEAR_SUBSTATION) != ''){
                    substationSwitchgearsCount = +Integer.valueOf(g1PromptSpecificInfoMap.get(Constants.SWITCHGEAR_SUBSTATION));
                }
                if(g1PromptSpecificInfoMap.containsKey(Constants.RENEWABLE_TYPE)){
                    String renewableType  = g1PromptSpecificInfoMap.get(Constants.RENEWABLE_TYPE);
                    windCheck = renewableType.contains(Constants.WIND);
                }
            }
            
            Map<String,Integer> promptMap = new Map<String,Integer>();
            promptMap.put(Constants.RECOMBINER_CHANNELS, recombinerCount);
            promptMap.put(Constants.COMBINER_CHANNELS, combinerCount);
            promptMap.put(Constants.TRACKER_CONTROLLER,trackerControllerCount);
            promptMap.put(Constants.TRACKER_MOTOR, tracketMotorCount);
            
            if(currentPromptName == Constants.P8A_INVERTERS_RECOMBINERS_INFO){
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
            } else if(currentPromptName == Constants.P8B_INVERTERS_COMBINERS_INFO){
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
            } else if(currentPromptName == Constants.P9A_TRACKER_CONTROLLER_INFO){
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
                promptMap.remove(Constants.TRACKER_CONTROLLER);
            } else if(currentPromptName == Constants.P9B_TRACKER_MOTOR_INFO){
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
                promptMap.remove(Constants.TRACKER_CONTROLLER);
                promptMap.remove(Constants.TRACKER_MOTOR);
           } else if(currentPromptName == Constants.P10B_OTHER_ASSET_BUILD_AND_INFO ){
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
                promptMap.remove(Constants.TRACKER_CONTROLLER);
                promptMap.remove(Constants.TRACKER_MOTOR);
                otherValue = 'No';
         } else if(currentPromptName == Constants.W4_TURBINE_BUILD_AND_INFO){
                String windNextPromptResponse = W4TurbineBuildAndInfo.windNextPromptFinder(plantAssetId, currentPromptName);
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
                promptMap.remove(Constants.TRACKER_CONTROLLER);
                promptMap.remove(Constants.TRACKER_MOTOR);
                windCheck = false;
                otherValue = 'No';
                if(!String.isBlank(windNextPromptResponse)){
                  if(windNextPromptResponse.length() < 9){
                        w4W5NextPromptCheck = false;
                        return windNextPromptResponse;
                    } 
                }
            } else if(currentPromptName == Constants.W5A_TURBINE_BUILD_SUBSYSTEMS){
                String windNextPromptResponse = W4TurbineBuildAndInfo.windNextPromptFinder(plantAssetId, currentPromptName);
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
                promptMap.remove(Constants.TRACKER_CONTROLLER);
                promptMap.remove(Constants.TRACKER_MOTOR);
                windCheck = false;
                otherValue = 'No';
                if(!String.isBlank(windNextPromptResponse)){
                    if(windNextPromptResponse.length() < 9){
                        w4W5NextPromptCheck = false;
                        return windNextPromptResponse;
                    }
                }
            } else if(currentPromptName == Constants.M2_METMAST_STATION_BUILD){
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
                promptMap.remove(Constants.TRACKER_CONTROLLER);
                promptMap.remove(Constants.TRACKER_MOTOR);
                windCheck = false;
                otherValue = 'No';
                metMaskCount=0;
           } else if(currentPromptName == Constants.W5B_TURBINE_BUILD_PROMPT_WIND_SPEED){
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
                promptMap.remove(Constants.TRACKER_CONTROLLER);
                promptMap.remove(Constants.TRACKER_MOTOR);
                windCheck = false;
                otherValue = 'No';
            }
            else if(currentPromptName == Constants.M1_MET_MAST_STATION_BUILD){
                String metMastNextPromptResponse = M1MetMastStationBuild.metMastNextPromptFinder(plantAssetId, currentPromptName);
                promptMap.remove(Constants.RECOMBINER_CHANNELS);
                promptMap.remove(Constants.COMBINER_CHANNELS);
                promptMap.remove(Constants.TRACKER_CONTROLLER);
                promptMap.remove(Constants.TRACKER_MOTOR);
                windCheck = false;
                otherValue = 'No';
                metMaskCount=0;
                if(!String.isBlank(metMastNextPromptResponse)){
                    if(metMastNextPromptResponse.length() < 9){
                       return metMastNextPromptResponse;
                    }
                }
            }
            
            if(w4W5NextPromptCheck){
                if(promptMap.containsKey(Constants.RECOMBINER_CHANNELS) && promptMap.get(Constants.RECOMBINER_CHANNELS) > 0){
                    nextPromptId = PromptNavigationHelper.findPromptId(Constants.P8A_INVERTERS_RECOMBINERS_INFO);
                } else if(promptMap.containsKey(Constants.COMBINER_CHANNELS) && promptMap.get(Constants.COMBINER_CHANNELS) > 0){
                    nextPromptId =  PromptNavigationHelper.findPromptId(Constants.P8B_INVERTERS_COMBINERS_INFO);
                } else if(promptMap.containsKey(Constants.TRACKER_CONTROLLER) && promptMap.get(Constants.TRACKER_CONTROLLER) > 0 ){
                    nextPromptId =  PromptNavigationHelper.findPromptId(Constants.P9A_TRACKER_CONTROLLER_INFO);
                } else if(promptMap.containsKey(Constants.TRACKER_MOTOR) && promptMap.get(Constants.TRACKER_MOTOR) > 0 ){
                   nextPromptId =   PromptNavigationHelper.findPromptId(Constants.P9B_TRACKER_MOTOR_INFO);
                } else if(otherValue == 'Yes'){
                    nextPromptId =  PromptNavigationHelper.findPromptId(Constants.P10A_OTHER_ASSET_BUILD);
                } else if(windCheck){
                    nextPromptId =  PromptNavigationHelper.findPromptId(Constants.W1_PLANT_INFO_PROMPT_WIND);
                } else if(metMaskCount > 0){
                    nextPromptId =   PromptNavigationHelper.findPromptId(Constants.M1_MET_MAST_STATION_BUILD);
                } else if(substationSwitchgearsCount > 0){
                    nextPromptId = PromptNavigationHelper.findPromptId(Constants.S1_SUBSTATION_SWITCHGEAR_BUILD);
                } else {
                    nextPromptId = 'finish';
                }
            }
            return nextPromptId;
        }catch (Exception exceptionDetails) {
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /*
        This method is used to show the Confirmation Next Popup Message for the respective prompts.
    */
    @AuraEnabled
    public static Prompt_Information__c getConfirmationMessageOnNext(String promptName) {
        Prompt_Information__c promptInfo;
        try{
            String status = 'Active';
            List<TEM_Version__c> temVersion = utils.queryTemVersion(status);
            system.debug('----temVersion[0].Id---'+temVersion[0].Id + '---promptName---'+promptName);
            promptInfo = [SELECT Id, Name, Base_Asset_Template__c, Prompt_Id__c, Confirm_Message_On_Next__c, Show_Popup_On_Next_Button__c, 
            Base_Asset_Template__r.Asset_Short_Name__c, Type__c, TEM_Version__c, Alias__c
            FROM Prompt_Information__c 
            WHERE Name =: promptName AND TEM_Version__c =: temVersion[0].Id];
        }catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
        return promptInfo;
    }

    /**
     * This method is used to get the Drive Plus category from the PFServiceProductToAttrRequirementMapping__mdt Custom Metadata Type. 
     */
    public static string drivePlusCategoryFinder(String pfServiceProduct){
        String drivePlus = System.Label.DrivePlusCategoryDefaultValue;
        Map<String,String> pfServiceProductToAttrReqCustomMetadatamap = new Map<String,String>();
        for(PFServiceProductToAttrRequirementMapping__mdt pfServiceProductToAttrReq : [SELECT   Id, DeveloperName,
                                                                                                IsDrive_Plus_Category__c, 
                                                                                                AttributeRequirement__c 
                                                                                        FROM    PFServiceProductToAttrRequirementMapping__mdt ]){
            pfServiceProductToAttrReqCustomMetadatamap.put(pfServiceProductToAttrReq.DeveloperName,pfServiceProductToAttrReq.IsDrive_Plus_Category__c);                                                                                
        }
        if(!String.isBlank(pfServiceProduct)){
            for(String pfServiceProductCustomMetadata : pfServiceProductToAttrReqCustomMetadatamap.keySet()){
                if(pfServiceProduct.contains(pfServiceProductCustomMetadata)){ 
                    drivePlus = pfServiceProductToAttrReqCustomMetadatamap.get(pfServiceProductCustomMetadata);
                }
            }
        }
        return drivePlus;
    }
  
     /*
    Create new Plant Asset Prompt Asset - using Plant Asset and Current Prompt Name
    */

    public static Plant_Asset_Prompt_Detail__c createPlantAssetPromptDetail(String plantAssetInstanceId, String currentPromptName,
                                                                           String previousPromptName, String parentAssetPromptName){
        Account_Plant__c plantAsset = Utils.queryPlantAsset(plantAssetInstanceId);
        Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAsset.Id);                                                         
        Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = new Plant_Asset_Prompt_Detail__c();
        String concat = plantAsset.Name +'-'+ currentPromptName;
        plantAssetPromptCreateInstance.Name = (concat.length() > 80) ? concat.substring(0, 80) : concat;
        plantAssetPromptCreateInstance.Account_Plant__c = plantAsset.Id;
        plantAssetPromptCreateInstance.Prompt_Information__c = promptInfo.Id;
        plantAssetPromptCreateInstance.Base_Asset__c = promptInfo.Base_Asset_Template__c;
        if(!String.isBlank(parentAssetPromptName)){
            plantAssetPromptCreateInstance.Parent_Asset_Prompt_Name__c = parentAssetPromptName;
        }
        if(!String.isBlank(previousPromptName)){
            plantAssetPromptCreateInstance.Previous_Plant_Asset_Prompt__c  = previousPromptName;
        }

        return plantAssetPromptCreateInstance;
    }

     /*
    Create new Site Meta Data - using Plant Asset,Prompt Specific attributes and Current Prompt Name
    */
    public static Site_Metadata__c createSiteMetaData(String plantAssetInstanceId, String currentPromptName,
                                                String promptSpecificInfoJSON, String plantAssetPromptCreateInstanceId,
                                                String coreAttributeInfoJSON, String parentSiteMetadata, 
                                                String baseAssetTempId, String promptInfoId, String assetName){
        Site_Metadata__c siteMetadata = new Site_Metadata__c();
        siteMetadata.Account_Plant__c = plantAssetInstanceId;
        siteMetadata.Name = currentPromptName;
        siteMetadata.Prompt_Information__c = promptInfoId;
        siteMetadata.Prompt_Specific_Info__c = promptSpecificInfoJSON;
        siteMetadata.Plant_Asset_Prompt_Detail__c = plantAssetPromptCreateInstanceId;
        if(!String.isBlank(baseAssetTempId)){
            siteMetadata.Base_Asset_Template__c = baseAssetTempId;
        }
        if(!String.isBlank(parentSiteMetadata)){
            siteMetadata.Parent_Site_Metadata__c = parentSiteMetadata;
        }
        if(!String.isBlank(coreAttributeInfoJSON)){
            coreAttributeInfoJSON = coreAttributeInfoJSON.replaceAll('"false"', 'false');
            siteMetadata.Attribute_Info__c = coreAttributeInfoJSON;
        }
        if(!String.isBlank(assetName)){
            sitemetadata.Asset_Name__c = assetName;
        }
        return siteMetadata;
    }

    /**
     * This method is used to query the Plant Asset Prompt Detail based on the Plant Asset Id and the Current Prompt Name.
     */
    public static Plant_Asset_Prompt_Detail__c queryPlantAssetPromptDetail(Id plantAssetInstanceId, String currentPromptName){
        return [SELECT Id,Base_Asset__c,Parent_Asset_Prompt_Name__c, Account_Plant__c, Account_Plant__r.TEM_Version__c, Account_Plant__r.Asset_Builder_Status__c, Prompt_Information__r.Type__c, Previous_Plant_Asset_Prompt__c, Is_Deleted__c,
            Previous_Plant_Asset_Prompt__r.Prompt_Information__r.Name, Prompt_Information__c, Name, Validate_On_Previous__c, 
            Prompt_Information__r.CSV_Sorting_Order__c, Capability_Report_Status__c, Completeness_Report_Status__c
            FROM Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c =: plantAssetInstanceId AND Is_Deleted__c = false AND
            Prompt_Information__r.Name =: currentPromptName];
        
    }

    /**
     * This method is used to find the Previous Prompt Id based on the plant Asset Id , Site Metadata records and the Prompt Info Record.
     */
    @AuraEnabled
    public static String findPreviousPromptId(String plantAssetId, String siteMetadataRecordsToSave, String promptInfo, 
        Boolean isKeyToGenerateRows, Boolean attrValueChanged,  String addtionalParamsForPrevious, Boolean finalBatchBoolean){
        try {
            Prompt_Information__c promptInfoRecord = (Prompt_Information__c)
                System.JSON.deserialize(promptInfo,Prompt_Information__c.class);

            String previousPromptId;
            Boolean saveSiteMetadataOutput = true;
            Map<String,String> additionalParamsMap  = (Map<String,String>)JSON.deserialize(addtionalParamsForPrevious, Map<String,String>.class);
            if(!String.isBlank(siteMetadataRecordsToSave) && additionalParamsMap.get('isReadOnly') == 'false'){
                saveSiteMetadataOutput = saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfoRecord, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
            }
            if(finalBatchBoolean){
                if(saveSiteMetadataOutput){
                    List<Plant_Asset_Prompt_Detail__c> plantAssetPromptDetail = 
                        new List<Plant_Asset_Prompt_Detail__c> {
                            Utils.queryPlantAssetPromptDetail(plantAssetId, promptInfoRecord.Name)
                        };
                    if(plantAssetPromptDetail.size()>0){
                        previousPromptId = PromptNavigationHelper.findPromptId(plantAssetPromptDetail[0].Previous_Plant_Asset_Prompt__r.Prompt_Information__r.Name);
                    }
                }
                return Utils.previousPromptFinderResponse(plantAssetId, PromptNavigationHelper.findPromptId(promptInfoRecord.Name), 
                    previousPromptId);
            }else{
                return 'calling Next Batch';
            }
        }catch(Exception exceptionDetail){
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug(' Error Message -> ' + exceptionDetail.getMessage() + ' Line # ' + exceptionDetail.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }  
    }

    /**
     * This method is used to update the Validate_On_Previous__c equals to true based on the Plant Asset Id and Current Prompt Name.
     */
    public static void updateValidateOnPrevious(String plantAssetId, String currentPromptName){
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId,currentPromptName);
        plantAssetPromptDetail.Validate_On_Previous__c = true;
        update plantAssetPromptDetail;
    }

    /**
     * This method is used to save the records of the Site Metadata records Based on the Plant Asset Id, Prompt Information and Key Field to Generate Rows.
     */
    public static Boolean saveSiteMetadataRecords(String siteMetadataRecordsToSave, String plantAssetId, 
                                                    Prompt_Information__c promptInfo, Boolean isKeyToGenerateRows, 
                                                    Boolean attrValueChanged, Boolean finalBatchBoolean){
        Boolean result = false;
        String currentPromptName = '';
        String assetAttrName = Utils.queryAssetNameAttr(promptInfo.Id);
        String alternateParentAttrName = Utils.queryAlternateParentAttr(promptInfo.Id);
        List<Site_Metadata__c> siteMetadataRecordsToUpdate = new List<Site_Metadata__c>();
        if(!String.isBlank(siteMetadataRecordsToSave)){
            for(Site_Metadata__c sitemetadata : (List<Site_Metadata__c>)
                    System.JSON.deserialize(siteMetadataRecordsToSave,List<Site_Metadata__c>.class)){
                String promptSiteMetadata = sitemetadata.Prompt_Specific_Info__c;
                map<String,String> promptSpecificInfoMap = Utils.deserializeAttribute(promptSiteMetadata);
                currentPromptName = siteMetadata.Name;
                sitemetadata.Prompt_Information__c = promptInfo.Id;
                sitemetadata.Is_Attribute_Value_Modified_in_Prompt__c = attrValueChanged;
                
                if(!String.isBlank(alternateParentAttrName)){
                    String alternateParentAttrNameValue = promptSpecificInfoMap.get(alternateParentAttrName); 
                    sitemetadata.Alternate_Parent_Site_Metadata__c = (String.isBlank(alternateParentAttrNameValue) || (alternateParentAttrNameValue == '--None--')) ? null : alternateParentAttrNameValue;
                }

                if(!String.isBlank(assetAttrName)){
                    String assetNameValue = promptSpecificInfoMap.get(assetAttrName);
                    sitemetadata.Asset_Name__c = String.isBlank(assetNameValue) ? null : assetNameValue;
                }
                siteMetadataRecordsToUpdate.add(sitemetadata);
            }

            if(siteMetadataRecordsToUpdate.size()>0){
                update siteMetadataRecordsToUpdate;
            }

            if(isKeyToGenerateRows && siteMetadataRecordsToUpdate.size()>0 && finalBatchBoolean){
                Boolean IsUpdateCheck = Utils.plantAssetPromptDetailIsDeleteUpdate(
                    siteMetadataRecordsToUpdate[0].Plant_Asset_Prompt_Detail__r.Id,
                    siteMetadataRecordsToUpdate[0].Plant_Asset_Prompt_Detail__r.Prompt_Information__r.Type__c);
            }
            
            if(finalBatchBoolean){
                Set<Id> alternateParentSiteMetadataRecordIdSet = new Set<Id>();
                siteMetadataRecordsToUpdate = new List<Site_Metadata__c>();
                siteMetadataRecordsToUpdate = Utils.querySiteMetadata(currentPromptName, plantAssetId);
                for(Site_Metadata__c sitemetadata : siteMetadataRecordsToUpdate){
                    alternateParentSiteMetadataRecordIdSet.add(sitemetadata.Alternate_Parent_Site_Metadata__c);
                }
                
                if(siteMetadataRecordsToUpdate.size()>0){
                    result = Utils.saveParentNameInSiteMetadataRecords(alternateParentSiteMetadataRecordIdSet, siteMetadataRecordsToUpdate, attrValueChanged);
                }
            }
            
            /*if(result){
                Account_Plant__c plantAsset = Utils.queryPlantAsset(plantAssetId);
                if(plantAsset.Asset_Builder_Status__c === 'Completed'){
                    plantAsset.Asset_Builder_Status__c = 'In-Progress';
                }
                update plantAsset;
            }*/
        }
        return result;
    }

    /**
     * This method is used to Update the Is Delete Checkbox in the Plant Asset Prompt Detail Based on the Prompt Type and Plant Asset Prompt Detail. 
     */
    public static Boolean plantAssetPromptDetailIsDeleteUpdate(String plantAssetPromptDetailUpdatedId, String promptType){
        Boolean result = false;
        Plant_Asset_Prompt_Detail__c plantassetPrompt = [SELECT Prompt_Information__r.CSV_Sorting_Order__c, Account_Plant__c
                                                            FROM Plant_Asset_Prompt_Detail__c
                                                            WHERE Id =: plantAssetPromptDetailUpdatedId];
        Decimal csvOrderValue = plantassetPrompt.Prompt_Information__r.CSV_Sorting_Order__c;
        String plantAssetId = plantassetPrompt.Account_Plant__c;
        List<Plant_Asset_Prompt_Detail__c> updateCheckboxInPlantAssetPromptDetail = new List<Plant_Asset_Prompt_Detail__c>();
        if(promptType != ''){
            for(Plant_Asset_Prompt_Detail__c plantAssetPromptDetailIsDeleteUpdate : [SELECT Id, Is_Deleted__c, Prompt_Information__r.Type__c, Account_Plant__c,
                                                                                        Prompt_Information__r.CSV_Sorting_Order__c FROM Plant_Asset_Prompt_Detail__c
                                                                                        WHERE Prompt_Information__r.Type__c =: promptType AND 
                                                                                        Account_Plant__c =: plantAssetId AND
                                                                                        Prompt_Information__r.CSV_Sorting_Order__c >: csvOrderValue]){
                plantAssetPromptDetailIsDeleteUpdate.Is_Deleted__c = true;
                updateCheckboxInPlantAssetPromptDetail.add(plantAssetPromptDetailIsDeleteUpdate);
            }
            
            if(updateCheckboxInPlantAssetPromptDetail.size() > 0){
                update updateCheckboxInPlantAssetPromptDetail;
                result = true; 
            }
        }
        return result;
    }

    /**
     * This method is used to update the Parent Asset Short Name and the Asset Short Name to the Site Metadata records Based on the Alternate Parent Site metadata Record Id
     *      and the Site Metadata Records. This will also query the Custom Metadata Type of AssetBuilderAssetShortName__mdt.
     */
    public static Boolean saveParentNameInSiteMetadataRecords(Set<Id> alternateParentSiteMetadataRecordIdSet, 
                                                                list<Site_Metadata__c> siteMetadataRecordsToUpdate,
                                                                Boolean attrValueChanged){
        Boolean parentNameUpdateResult = false;
        Map<String, Integer> parentAssetNameToCountMap = new Map<String, Integer>();
        List<Site_Metadata__c> siteMetadataUpdateLst = new List<Site_Metadata__c>();
        
        if(siteMetadataRecordsToUpdate.size()>0){
            Map<String, String> assetShortNameMap = new Map<String, String>();
            for(AssetBuilderAssetShortName__mdt assetShortName:[SELECT Id, DeveloperName, Asset_Short_Name__c FROM AssetBuilderAssetShortName__mdt]){
                assetShortNameMap.put(assetShortName.DeveloperName,assetShortName.Asset_Short_Name__c);
            }
            Map<Id, Site_Metadata__c> aternateParentSiteMetedataMap = 
                new Map<Id, Site_Metadata__c>([SELECT Id, Name, Parent_Asset_Short_Name__c, Base_Asset_Template__c, Asset_Short_Name__c
                                            FROM Site_Metadata__c WHERE Id =: alternateParentSiteMetadataRecordIdSet]);
            for(Site_Metadata__c siteMetadataRecord : siteMetadataRecordsToUpdate){
                String currentParentName = '';
                String plantAssetCustomerId = '';
                String currentPlantAssetCustomerId = '';
                String currentParentNameWithBaseShortName = '';
                String currentSitemetadataAltrParentSitemetadata = siteMetadataRecord.Alternate_Parent_Site_Metadata__c;
                if(siteMetadataRecord.Name == Constants.P1_PLANT_INFO_PROMPT_SOLAR || siteMetadataRecord.Name == Constants.W1_PLANT_INFO_PROMPT_WIND){
                    plantAssetCustomerId = siteMetadataRecord.Account_Plant__r.Customer_Plant_Asset_ID__c;
                    List<String> customerAssetIdSplitList = plantAssetCustomerId.split('\\.');
                    if(customerAssetIdSplitList.size()>0){
                        siteMetadataRecord.Parent_Asset_Short_Name__c = customerAssetIdSplitList[0]+'\\'+customerAssetIdSplitList[1];
                        siteMetadataRecord.Asset_Short_Name__c = customerAssetIdSplitList[2];
                        siteMetadataRecord.Asset_Name__c = siteMetadataRecord.Account_Plant__r.Plant_Name__c;   
                    }
                    siteMetadataRecord.Is_Attribute_Value_Modified_in_Prompt__c = attrValueChanged;
                    siteMetadataUpdateLst.add(siteMetadataRecord);
                }else if(currentSitemetadataAltrParentSitemetadata != null &&
                        siteMetadataRecord.Name != Constants.P1_PLANT_INFO_PROMPT_SOLAR &&
                        siteMetadataRecord.Name != Constants.W1_PLANT_INFO_PROMPT_WIND &&
                        siteMetadataRecord.Name != Constants.S1_SUBSTATION_SWITCHGEAR_BUILD){
                    if(aternateParentSiteMetedataMap.containskey(currentSitemetadataAltrParentSitemetadata)){
                        if(aternateParentSiteMetedataMap.get(currentSitemetadataAltrParentSitemetadata).Base_Asset_Template__c != null){
                            currentParentName = aternateParentSiteMetedataMap.get(currentSitemetadataAltrParentSitemetadata).Parent_Asset_Short_Name__c + '\\' + 
                                            aternateParentSiteMetedataMap.get(currentSitemetadataAltrParentSitemetadata).Asset_Short_Name__c;   
                        }else{
                            currentParentName = siteMetadataRecord.Parent_Site_Metadata__r.Parent_Asset_Short_Name__c + '\\' + 
                                            siteMetadataRecord.Parent_Site_Metadata__r.Asset_Short_Name__c;
                        } 
                    }
                    if(aternateParentSiteMetedataMap.get(currentSitemetadataAltrParentSitemetadata).Asset_Short_Name__c != null){
                        currentParentNameWithBaseShortName = aternateParentSiteMetedataMap.get(currentSitemetadataAltrParentSitemetadata).Parent_Asset_Short_Name__c + '\\' + 
                                            aternateParentSiteMetedataMap.get(currentSitemetadataAltrParentSitemetadata).Asset_Short_Name__c +
                                            siteMetadataRecord.Base_Asset_Template__r.Asset_Short_Name__c;    
                    }else{
                        currentParentNameWithBaseShortName = aternateParentSiteMetedataMap.get(currentSitemetadataAltrParentSitemetadata).Parent_Asset_Short_Name__c + '\\' + 
                                            siteMetadataRecord.Parent_Site_Metadata__r.Asset_Short_Name__c +
                                            siteMetadataRecord.Base_Asset_Template__r.Asset_Short_Name__c;
                    }
                    if(!parentAssetNameToCountMap.containsKey(currentParentNameWithBaseShortName)) {
                        parentAssetNameToCountMap.put(currentParentNameWithBaseShortName, 0);
                    }
                    Integer count = integer.valueof(parentAssetNameToCountMap.get(currentParentNameWithBaseShortName));
                    Integer recordNameSequenceNo  = count + 1;
                    parentAssetNameToCountMap.put(currentParentNameWithBaseShortName, recordNameSequenceNo );
                    siteMetadataRecord.Parent_Asset_Short_Name__c = currentParentName;
                    if(siteMetadataRecord.Base_Asset_Template__r.Asset_Short_Name__c == null){
                        siteMetadataRecord.Asset_Short_Name__c = '';
                    }else{
                        siteMetadataRecord.Asset_Short_Name__c = siteMetadataRecord.Base_Asset_Template__r.Asset_Short_Name__c+
                                                                string.valueof(recordNameSequenceNo).leftPad(2, '0');
                    }
                    siteMetadataRecord.Is_Attribute_Value_Modified_in_Prompt__c = attrValueChanged;
                    siteMetadataUpdateLst.add(siteMetadataRecord);
                }else if(siteMetadataRecord.Parent_Site_Metadata__c != null && currentSitemetadataAltrParentSitemetadata == null &&
                         siteMetadataRecord.Name != Constants.P1_PLANT_INFO_PROMPT_SOLAR &&
                         siteMetadataRecord.Name != Constants.W1_PLANT_INFO_PROMPT_WIND &&
                         siteMetadataRecord.Name != Constants.S1_SUBSTATION_SWITCHGEAR_BUILD){
                    if(siteMetadataRecord.Parent_Site_Metadata__r.Asset_Short_Name__c == null){
                        currentParentName = siteMetadataRecord.Parent_Site_Metadata__r.Parent_Asset_Short_Name__c;
                        currentParentNameWithBaseShortName = siteMetadataRecord.Parent_Site_Metadata__r.Parent_Asset_Short_Name__c + 
                                            siteMetadataRecord.Base_Asset_Template__r.Asset_Short_Name__c;
                    }else {
                        currentParentName = siteMetadataRecord.Parent_Site_Metadata__r.Parent_Asset_Short_Name__c + '\\' + 
                                            siteMetadataRecord.Parent_Site_Metadata__r.Asset_Short_Name__c;
                        currentParentNameWithBaseShortName = siteMetadataRecord.Parent_Site_Metadata__r.Parent_Asset_Short_Name__c + '\\' + 
                                            siteMetadataRecord.Parent_Site_Metadata__r.Asset_Short_Name__c +
                                            siteMetadataRecord.Base_Asset_Template__r.Asset_Short_Name__c;
                    }
                    if (!parentAssetNameToCountMap.containsKey(currentParentNameWithBaseShortName)) {
                        parentAssetNameToCountMap.put(currentParentNameWithBaseShortName, 0);
                    }
                    Integer count = integer.valueof(parentAssetNameToCountMap.get(currentParentNameWithBaseShortName));
                    Integer recordNameSequenceNo  = count + 1;
                    parentAssetNameToCountMap.put(currentParentNameWithBaseShortName, recordNameSequenceNo );
                    siteMetadataRecord.Parent_Asset_Short_Name__c = currentParentName;
                    if(siteMetadataRecord.Base_Asset_Template__r.Asset_Short_Name__c == null){
                        siteMetadataRecord.Asset_Short_Name__c = '';
                    }else{
                    siteMetadataRecord.Asset_Short_Name__c = siteMetadataRecord.Base_Asset_Template__r.Asset_Short_Name__c+
                                                                string.valueof(recordNameSequenceNo).leftPad(2, '0');
                    }
                    siteMetadataRecord.Is_Attribute_Value_Modified_in_Prompt__c = attrValueChanged;
                    siteMetadataUpdateLst.add(siteMetadataRecord);
                }else if(currentSitemetadataAltrParentSitemetadata == null && siteMetadataRecord.Parent_Site_Metadata__c != null
                        && siteMetadataRecord.Name != Constants.P1_PLANT_INFO_PROMPT_SOLAR
                        && siteMetadataRecord.Name != Constants.W1_PLANT_INFO_PROMPT_WIND
                        && siteMetadataRecord.Name == Constants.S1_SUBSTATION_SWITCHGEAR_BUILD){
                    currentPlantAssetCustomerId = siteMetadataRecord.Parent_Site_Metadata__r.Parent_Asset_Short_Name__c;
                    Map<String, String> currentPromptSpecificInfoMap = 
                        (Map<String, String>) System.JSON.deserialize(siteMetadataRecord.Prompt_Specific_Info__c,Map<String, String>.class);
                    String subStationSwitchgearName = currentPromptSpecificInfoMap.get(Constants.SUBSTATION_OR_SWITCHGEAR);
                    if (!parentAssetNameToCountMap.containsKey(subStationSwitchgearName)) {
                        parentAssetNameToCountMap.put(subStationSwitchgearName, 0);
                    }
                    Integer count = integer.valueof(parentAssetNameToCountMap.get(subStationSwitchgearName));
                    Integer recordNameSequenceNo  = count + 1;
                    parentAssetNameToCountMap.put(subStationSwitchgearName, recordNameSequenceNo );
                    siteMetadataRecord.Parent_Asset_Short_Name__c = currentPlantAssetCustomerId;
                    if(assetShortNameMap.containsKey(subStationSwitchgearName)){
                        siteMetadataRecord.Asset_Short_Name__c = assetShortNameMap.get(subStationSwitchgearName)+
                                                                string.valueof(recordNameSequenceNo).leftPad(2, '0');
                    }else{
                        siteMetadataRecord.Asset_Short_Name__c = '';
                    }
                    siteMetadataRecord.Is_Attribute_Value_Modified_in_Prompt__c = attrValueChanged;
                    siteMetadataUpdateLst.add(siteMetadataRecord);
                } 
            }
            if(siteMetadataUpdateLst.size()>0){
                StaticVariableForAssetBuilderUtils.platformEventLastProcessedDatetime = System.now(); 
                Update siteMetadataUpdateLst;
                parentNameUpdateResult = true;
            }
        }
        return parentNameUpdateResult;
    }

    /**
     * This method is used to clear the Attribute value based on the Plant Asset Id, Cuurent Prompt Name, List of core Attribute Names and the list of Prompt Specific Name
     *      retainValuesForCoreAttr, retainValuesForPromptAttr - The Attribute Value for the respective list will not clear the attribute Value in this method.
     */
    public static Boolean clearPromptInfo(String plantAssetId, String currentPromptName, 
        List<String> retainValuesForCoreAttr, List<String> retainValuesForPromptAttr
    ){
        Boolean result = false;
        Savepoint sp = Database.setSavepoint();
        try{
            List<Site_Metadata__c> promptSiteMetaData = new List<Site_Metadata__c>();
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);

            for(Site_Metadata__c siteMetadata : currentPromptSiteMetadata){
                if(!String.isBlank(siteMetadata.Attribute_Info__c)){
                    Map<String,String> coreAttrInfoMap = Utils.deserializeAttribute(siteMetadata.Attribute_Info__c);
                    for(String coreAttrInfoName : coreAttrInfoMap.keySet()){
                        if(!retainValuesForCoreAttr.contains(coreAttrInfoName)){
                            coreAttrInfoMap.put(coreAttrInfoName,'');
                        }
                    }
                    siteMetadata.Attribute_Info__c = JSON.serialize(coreAttrInfoMap);
                }
                if(!String.isBlank(siteMetadata.Prompt_Specific_Info__c)){
                    Map<String,String> promptAttrInfoMap = Utils.deserializeAttribute(siteMetadata.Prompt_Specific_Info__c);
                    for(String promptAttrInfoName : promptAttrInfoMap.keySet()){
                        if(!retainValuesForPromptAttr.contains(promptAttrInfoName)){
                            promptAttrInfoMap.put(promptAttrInfoName,'');
                        }
                    }
                    siteMetadata.Prompt_Specific_Info__c = JSON.serialize(promptAttrInfoMap);
                }
                promptSiteMetaData.add(siteMetadata);

            }

            Plant_Asset_Prompt_Detail__c clearValidateOnPrevious = Utils.queryPlantAssetPromptDetail(plantAssetId,currentPromptName);
            if(clearValidateOnPrevious.Validate_On_Previous__c == true){
                clearValidateOnPrevious.Validate_On_Previous__c = false;
            }
            update clearValidateOnPrevious;

            if(promptSiteMetaData.size() >0){
                update promptSiteMetaData;
                result = true;
            } 
            
            return result;
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
  
   /*
     *This method is used to generate new records based on the Prompt Specific Info present in the Parent Site Metadata records.
     * @param prepopulateColumnName - This will have the Prepopulate Column Name of Attribute.
     * @param parentSiteMetadataPrompt - This attribute will have the Parent Site Metadata Record Id.
     * @param plantAssetId - This will have the Current Plant Asset Record Id.
     * @param rowGeneratorAttrName - Thi attribute will have the count for the New Records too be inserted.
     * @param currentPromptName - This attribute will have the Current Prompt Name.
     * @param previousPromptName - This attribute will have the Previous Prompt Name.
    */
    public static List<Site_Metadata__c>  newSiteMetadataRecords(String prepopulateColumnName, String parentSiteMetadataPrompt,  
        String plantAssetId,String rowGeneratorAttrName,String currentPromptName,String previousPromptName){
        Integer rowCount=0;
        List<Site_Metadata__c> parentAssets = new List<Site_Metadata__c>();
        Map<Integer, String> newParentMap = new Map<Integer,String>();
        Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
        Id basetAssetId = promptInfo.Base_Asset_Template__c;
        Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
        Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
        Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
        
        List<Core_Attribute__c> coreAttributes = Utils.queryCoreAttributes(basetAssetId, allAttributesId);
        List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);
        List<Core_Attribute__c> promptSpecificAttributesList = new List<Core_Attribute__c>();
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
        String coreAttributeInfoJSON = Utils.serializeAttribute(coreAttributes);             
        Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
        Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttributes);
        //prepare map for each prepopulated Column name and its count for the existing SiteMetadata 
        Map<String,Integer> prepopulateColumnNameMap = new  Map<String,Integer>();
        for(Site_Metadata__c currentSiteMetadata : currentPromptSiteMetadata){
            Map<String, String> promptSpecificInfoMap = 
                (Map<String, String>) System.JSON.deserialize(currentSiteMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
            if(promptSpecificInfoMap.get(prepopulateColumnName) != null) {
                String prepopulateColumnVal = promptSpecificInfoMap.get(prepopulateColumnName);
                if(prepopulateColumnNameMap.containsKey(promptSpecificInfoMap.get(prepopulateColumnName))){
                    Integer countOfPrepopulateVal = prepopulateColumnNameMap.get(prepopulateColumnVal);
                    prepopulateColumnNameMap.put(prepopulateColumnVal, countOfPrepopulateVal + 1);
                } else {
                    prepopulateColumnNameMap.put(prepopulateColumnVal, 1);
                }
            }
        }
        
        List<Site_Metadata__c> rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(parentSiteMetadataPrompt, plantAssetId);
        String parentPlantAssetPromptDetail;
        if(rowGeneratorPromptSiteMetadata.size()>0){
            parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
        }
        
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
        Map<String,Integer> rowGenMap = new  Map<String,Integer>();
        Integer yesCount = 0;
        for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
            
            Map<String, String> rowPromptSpecificInfoMap = 
                (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
            
            if(!String.isBlank(rowPromptSpecificInfoMap.get(rowGeneratorAttrName))){
                rowGenMap.put(String.valueOf(rowGenMetadata.Id),Integer.valueOf(rowPromptSpecificInfoMap.get(rowGeneratorAttrName)));
            }
            
        }
        //Iterate the new rowGenerator PromptSiteMetadata and prepare the row count by comparing with existing prepopulateColumnNameMap values. 
        for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
            Map<String, String> promptSpecificInfoMap = 
                (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
            if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){
                if(prepopulateColumnNameMap.containsKey(rowGenMetadata.Id)){
                    Integer newRowCount = 0;
                    if(rowGenMap.get(rowGenMetadata.Id) > prepopulateColumnNameMap.get(rowGenMetadata.Id)){
                        newRowCount = rowGenMap.get(rowGenMetadata.Id) - prepopulateColumnNameMap.get(rowGenMetadata.Id);
                    }
                    for(Integer count = 0; count < newRowCount; count++){
                        parentAssets.add(rowGenMetadata);
                    }
                    rowCount += newRowCount;
                } else{
                    if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName) && !String.isBlank(promptSpecificInfoMap.get(rowGeneratorAttrName))){
                        for(Integer i = 0; i < Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName)); i++){
                            parentAssets.add(rowGenMetadata);
                        }  
                        rowCount += Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName));
                    }
                }
            }
        }
        
        //creating the SiteMetadata records 
        List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
        if(rowCount>0){
            for(integer i = 0; i < rowCount; i++){
                Map<String,String> rowGenPromptSpecificInfoMap = 
                    (Map<String, String>) System.JSON.deserialize(parentAssets[i].Prompt_Specific_Info__c,Map<String, String>.class);
                String prePopulatecolumnValue = rowGenPromptSpecificInfoMap.containsKey(prepopulateColumnName)?rowGenPromptSpecificInfoMap.get(prepopulateColumnName):'';
                promptAttributeInfo.put(prepopulateColumnName,parentAssets[i].Id);
                if(currentPromptName == Constants.P8A_INVERTERS_RECOMBINERS_INFO ||currentPromptName == Constants.P8B_INVERTERS_COMBINERS_INFO){
                    coreAttributeInfo.put(prepopulateColumnName,parentAssets[i].Id);
                    coreAttributeInfoJSON = JSON.serialize(coreAttributeInfo);
                }
                Integer shortNameSuffix = i+1;
                Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                                         String.valueOf(plantAssetPromptDetail.Id), coreAttributeInfoJSON,
                                                                         String.valueOf(parentAssets[i].Id), basetAssetId, promptInfo.Id, '');
                
                siteMetadataCreation.add(siteMetadata);
            }

            if(currentPromptName != Constants.P8A_INVERTERS_RECOMBINERS_INFO  && currentPromptName != Constants.P8B_INVERTERS_COMBINERS_INFO){
                if(siteMetadataCreation.size()>0){
                    insert siteMetadataCreation;
                }
                currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
            }
            else{
                currentPromptSiteMetadata = siteMetadataCreation;
            }
        } 
        
        return currentPromptSiteMetadata;
    } 
    
    /*
     * This method is used to generate new records based on the Prompt Specific Info present in the Parent Site Metadata records.
     * @param prepopulateColumnName - This will have the Prepopulate Column Name of Attribute.
     * @param parentSiteMetadataPrompt - This attribute will have the Parent Site Metadata Record Id.
     * @param plantAssetId - This will have the Current Plant Asset Record Id.
     * @param rowGeneratorAttrName - Thi attribute will have the count for the New Records too be inserted.
     * @param currentPromptName - This attribute will have the Current Prompt Name.
     * @param previousPromptName - This attribute will have the Previous Prompt Name.
     * @param isBifacialSubarray - This attribute is used to query attribute related to bifacial subarray.  
     *                              If "true", will query all attributes includes bifacial subarray 
     *                              else query all attributes and not include bifacial subarray.
    */
     public static List<Site_Metadata__c>  newP2SiteMetadataRecords(String prepopulateColumnName, String parentSiteMetadataPrompt, String plantAssetId,String rowGeneratorAttrName,String currentPromptName,String previousPromptName, Boolean isBifacialSubarray){

        Integer rowCount=0;
        List<Site_Metadata__c> parentAssets = new List<Site_Metadata__c>();
        Map<Integer, String> newParentMap = new Map<Integer,String>();
        Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
        Id basetAssetId = promptInfo.Base_Asset_Template__c;
        Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
        Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
        Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
        
        List<Core_Attribute__c> coreAttributes = (isBifacialSubarray) ? Utils.queryCoreAttributes(basetAssetId, allAttributesId) : Utils.queryCoreAttributesP7(basetAssetId, allAttributesId, isBifacialSubarray);
        List<Core_Attribute__c> promptSpecificAttributes = (isBifacialSubarray) ? Utils.queryPromptAttributes(promptInfo.Id, plantAssetId) : Utils.queryPromptAttributesM1(promptInfo.Id, plantAssetId, isBifacialSubarray);
        List<Core_Attribute__c> promptSpecificAttributesList = new List<Core_Attribute__c>(); 
        List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
        String coreAttributeInfoJSON = Utils.serializeAttribute(coreAttributes);             
        Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
        
        Map<String,Integer> prepopulateColumnNameMap = new  Map<String,Integer>();
        Integer existingCount = currentPromptSiteMetadata.size();
        
        List<Site_Metadata__c> rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(parentSiteMetadataPrompt, plantAssetId);
        String parentPlantAssetPromptDetail;
        if(rowGeneratorPromptSiteMetadata.size()>0){
            parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
        }
        
        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
        //prepare map for each prepopulated Column name and its count for the existing SiteMetadata 
        Map<String,Integer> rowGenMap = new  Map<String,Integer>();
        for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
            Map<String, String> rowPromptSpecificInfoMap = 
                (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
            rowGenMap.put(String.valueOf(rowGenMetadata.Id),Integer.valueOf(rowPromptSpecificInfoMap.get(rowGeneratorAttrName)));
        }
        
        if(!String.isBlank(rowGeneratorAttrName)){
            Map<String, Integer> parentAssetIdtoNoofChild = new Map<String, Integer>(); 
            for(Site_Metadata__c rowGenMetadata : rowGeneratorPromptSiteMetadata){
                Map<String, String> promptSpecificInfoMap = 
                    (Map<String, String>) System.JSON.deserialize(rowGenMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                if(promptSpecificInfoMap.containsKey(rowGeneratorAttrName)){
                    Integer addedRecordCount = 0;
                    if(Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName)) > existingCount){
                        //get the row count for the newly added records.
                        addedRecordCount = Integer.valueOf(promptSpecificInfoMap.get(rowGeneratorAttrName)) - existingCount;
                    }
                    for(Integer count = 0; count < addedRecordCount; count++){
                        parentAssets.add(rowGenMetadata);
                    }
                    rowCount += addedRecordCount;
                }
            }
        }
        
        List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
        if(rowCount > 0){
            for(integer i = 0; i < rowCount; i++){
                Map<String,String> rowGenPromptSpecificInfoMap = 
                    (Map<String, String>) System.JSON.deserialize(parentAssets[i].Prompt_Specific_Info__c,Map<String, String>.class);
                String prePopulatecolumnValue = rowGenPromptSpecificInfoMap.containsKey(prepopulateColumnName)?rowGenPromptSpecificInfoMap.get(prepopulateColumnName):'';
                promptAttributeInfo.put(prepopulateColumnName,'');
                Integer shortNameSuffix = i+1;
                Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                                         String.valueOf(plantAssetPromptDetail.Id), coreAttributeInfoJSON,
                                                                         String.valueOf(parentAssets[i].Id), basetAssetId, promptInfo.Id, '');
                
                siteMetadataCreation.add(siteMetadata);
            }
            if(siteMetadataCreation.size()>0){
                insert siteMetadataCreation;
            }
            currentPromptSiteMetadata = Utils.querySiteMetadata(currentPromptName, plantAssetId);
        } 
        return currentPromptSiteMetadata;
    } 

    /**
     * This method is used to update the Previous prompt name for the Current Plant Asset Prompt Details.
     */
    public static void checkPreviousPlantAsset(Plant_Asset_Prompt_Detail__c plantAssetPromptDetailInstance, String previousPromptName){
        if(!String.isBlank(previousPromptName)){
            Plant_Asset_Prompt_Detail__c prevPlantAssetPromptDetail = [SELECT Id, Prompt_Information__r.CSV_Sorting_Order__c
                                                                       FROM Plant_Asset_Prompt_Detail__c WHERE Id =: previousPromptName];
            
            if((previousPromptName != plantAssetPromptDetailInstance.Previous_Plant_Asset_Prompt__c)
               && (plantAssetPromptDetailInstance.Id != previousPromptName)){
                       plantAssetPromptDetailInstance.Previous_Plant_Asset_Prompt__c = previousPromptName;
                       update plantAssetPromptDetailInstance;
            }
        }
    }

    /**
     * This method is used to Clone the Respective object based on the Selected TEM Version Id, Current TEM Version Id and the Object API Name.
     */
    public static List<SObject> cloneAnySobject(String objectAPIName, String selectedTEMVersionId, String currentTemVersionId){
        try{
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            
            Set<String> fieldMap = schemaMap.get(objectAPIName).getDescribe().fields.getMap().keySet();
            String soqlQuery = 'SELECT ' ;
            for (String s :fieldMap){
                if(schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(s).getDescribe().isAccessible()){
                    soqlQuery +=  + s+',';
                }
            }
            
            soqlQuery =  soqlQuery.removeEnd(',');
            soqlQuery += ' FROM ' +objectAPIName +' WHERE TEM_Version__c = \'' + selectedTEMVersionId +'\'' ;
            String listType = 'List<' + objectAPIName + '>';
            List<SObject> recordList = (List<SObject>)Type.forName(listType).newInstance();
            List<SObject> clonedRecordList = (List<SObject>)Type.forName(listType).newInstance();
            recordList = Database.query(soqlQuery);

            if(recordList != null){
                for(SObject objRecord : recordList){
                    SObject obj;
                    obj = objRecord.clone(false, false, false, false);
                    obj.put('External_Id__c',String.valueOf(objRecord.get('Id')));
                    obj.put('TEM_Version__c',currentTemVersionId); 
                    clonedRecordList.add(obj);
                }
            }
    
            if(clonedRecordList.size() > 0){
                return clonedRecordList;
            }else{
                return null;
            }
        }catch(Exception exp){
            System.debug('error message ' + exp.getMessage() + ' line # ' + exp.getLineNumber());
            return null;
        }
    }

    /*
    * Formation of Error Log Object
    @param {String} jobName - Method Name of Error occured class.
    @param {String} errorMsg - Error Message occured.
    @param {String} errorLine - Error occured in particular line.
    @param {String} plantAssetId - Error occured in which Plant Asset.
    @param {String} plantAssetPromptDetailId - Error occured in which Plant Asset Prompt Detail.
    */
    public static Error_Log__c catchErrorLogs(String jobName, String errorMsg, Integer errorLine,
        String plantAssetId, String plantAssetPromptDetailId){
        Error_Log__c errorLogInstance = new Error_Log__c();
        errorLogInstance.Job_Name__c = jobName;
        errorLogInstance.Error_Message__c = errorMsg;
        errorLogInstance.Error_Line__c = errorLine;
        errorLogInstance.Account_Plant__c = plantAssetId;
        if(plantAssetPromptDetailId != '')
        errorLogInstance.Plant_Asset_Prompt_Detail__c = plantAssetPromptDetailId;
        return errorLogInstance;
    }

    /*
    * Get Attribute Reuqirement using Custom Metadata
    */
    @AuraEnabled
    public static String getAttrReqFromCustomMetadata(){
        Set<String> attrReqSet = new Set<String>();
        List<Attribute_Requirement_Valid_Values__mdt> attrReq = [SELECT label, DeveloperName, Requirement__c, System__c FROM Attribute_Requirement_Valid_Values__mdt];
        for(Attribute_Requirement_Valid_Values__mdt attrReqIns : attrReq){
            attrReqSet.add(attrReqIns.System__c);
        }
        List<String> attrReqLst = new List<String>(attrReqSet);

        String theme = UserInfo.getUiThemeDisplayed();
        map<String, object> attrReqWithUserDataMap = new Map<String, Object>();
        attrReqWithUserDataMap.put('attrReqLst', attrReqLst);
        attrReqWithUserDataMap.put('theme', theme);
        return JSON.serialize(attrReqWithUserDataMap);
    }

    /*
    Get the plant Project lifecycle status and license type from custom metadata
    */
    @AuraEnabled
    public static Map<String,List<String>> projectLifecycleStatus(){
        
        Map<String,List<String>> licenseWithStatus = new Map<String,list<String>>();
        for(ProjectLifecycleStatus__mdt plcStatusIns : [SELECT Id, Status__c, License_Type__c FROM ProjectLifecycleStatus__mdt]){
            if(!licenseWithStatus.containsKey(plcStatusIns.License_Type__c)){
                licenseWithStatus.put(plcStatusIns.License_Type__c, new List<String>());        
            }
            licenseWithStatus.get(plcStatusIns.License_Type__c).add(plcStatusIns.Status__c); 
        }
       return licenseWithStatus;
    }
    /*
    * Get default value for required fields related to Asset Build record creation.  
    */
    public static Map<String, String> queryABRequiredFields(String objectAPIName){
        Map<String, String> mapFieldsWithValues = new Map<String, String>();
        for(AB_Required_Fields_Value_Mapping__mdt requiredField : [SELECT DeveloperName, Label, Field_API_Name__c, Object_API_Name__c, Record_type__c, Value_for_Required_field__c FROM AB_Required_Fields_Value_Mapping__mdt WHERE Object_API_Name__c =:objectAPIName]){
            mapFieldsWithValues.put(requiredField.Field_API_Name__c, requiredField.Value_for_Required_field__c);
        }
        return mapFieldsWithValues;
    }

    /*
    get core attrbute based on Attribute Requirement to pf serice product in G1 plant asset prompt detail
    */
    public static List<String> getAttrReqSysNamesFrmG1(Id plantAssetId){

        String productAttrName = Constants.PF_SERVICE_PRODUCT;
        List<String> systemNames = new List<String>();
        Account_Plant__c plantAsset = queryPlantAsset(plantAssetId);
        List<String> pfServiceProduct = new List<string>();
        List<site_metadata__c> g1SiteMetadata =  Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);

        for(site_metadata__c productInfo : g1SiteMetadata){
            Map<String, String> promptSpecificInfoMap = (Map<String, String>) System.JSON.deserialize(productInfo.Prompt_Specific_Info__c, Map<String, String>.class);
            if(promptSpecificInfoMap.containsKey(productAttrName)){   
                if(promptSpecificInfoMap.get(productAttrName).contains(';')){
                    pfServiceProduct.addAll(promptSpecificInfoMap.get(productAttrName).split(';'));   
                }else{
                    pfServiceProduct.add(promptSpecificInfoMap.get(productAttrName));
                }
            }
        }
        
        Map<String,String> pfServiceProductToAttrReqCustomMetadatamap = new Map<String,String>();
        for(PFServiceProductToAttrRequirementMapping__mdt pfServiceProductToAttrReq : [SELECT   Id, DeveloperName, AttributeRequirement__c FROM  PFServiceProductToAttrRequirementMapping__mdt ]){
            pfServiceProductToAttrReqCustomMetadatamap.put(pfServiceProductToAttrReq.DeveloperName, pfServiceProductToAttrReq.AttributeRequirement__c);
        }

        if(pfServiceProduct.size() > 0){
            for(String pfServiceProductCustomMetadata : pfServiceProductToAttrReqCustomMetadatamap.keySet()){
                if(pfServiceProduct.contains(pfServiceProductCustomMetadata)){ 
                    systemNames.add(pfServiceProductToAttrReqCustomMetadatamap.get(pfServiceProductCustomMetadata));
                }
            }
        }
       
        if(systemNames.size()<=0){
            systemNames.addAll(pfServiceProductToAttrReqCustomMetadatamap.values());
        }
        return systemNames;
    }

    /*
    To get rfi item related to plant asset details
    */
    public static Account_Plant__c getRfiDetailsFrmPlantAsset(Id plantAssetId){
        Set<String> closedStatusOfRfiItem = new Set<String>();
        for(Open_RFI_Item_Status_Check__mdt pfServiceProductToAttrReq : [SELECT   Id, label FROM  Open_RFI_Item_Status_Check__mdt]){
            closedStatusOfRfiItem.add(pfServiceProductToAttrReq.label);
        }

        Account_Plant__c plantAsset = [SELECT Id, Name, Asset_Builder_Status__c, AB_Approval_Status__c, PF_Service_Product__c,(SELECT Name, RFI_Item_Status__c FROM RFI_Details__r WHERE  RFI_Item_Status__c NOT IN: closedStatusOfRfiItem AND  RFI_Category__r.RFI_Sub_Type_Filter__c INCLUDES('Asset Builder')) FROM Account_Plant__c WHERE Id =: plantAssetId];
        return plantAsset;
    }

    /*
    To get Plant asset prompt detail related to plant asset
    */
    @AuraEnabled
    public static Plant_Asset_Prompt_Detail__c getG1PlantAssetPromptDetail(Id plantAssetId){
        system.debug('----plantAssetId---'+plantAssetId);
        Plant_Asset_Prompt_Detail__c pltAstPrtDtl = [SELECT Id, Name, Account_Plant__c, Account_Plant__r.TEM_Version__c, Bulk_Import_Type__c, Account_Plant__r.TEM_Version__r.Name, Report_Execution_By_User__r.Name, Report_Generated_Datetime__c FROM Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c =:plantAssetId AND Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND Is_Deleted__c = FALSE];
        return pltAstPrtDtl;
    }

    /*
    To insert sitemetdata
    */
    public static void insertSitemetadata(List<Site_Metadata__c> sitemetadataLst){
        insert sitemetadataLst;
        StaticVariableForAssetBuilderUtils.platformEventLastProcessedDatetime = System.now(); 
    }
  
    public static Set<String> intersectSet(Set<String> set1, Set<String> set2){
        Set<String> intersectRenewableTypeSet = new Set<String>(set1);
        intersectRenewableTypeSet.retainAll(set2);
        return intersectRenewableTypeSet;
    }
  
    /**
     * This Method is used to query the files from G1 PAPD Based on the Plant Asset Id and Prompt Name
     */
    public static String getCSVString(String plantAssetId, String promptName){
        list<String> allfilesRelatedToPAPD = new List<String>();
        String searchString = '%'+Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT+'%';
        for(ContentDocumentLink contentDocument :[SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink WHERE 
            LinkedEntityId IN ( SELECT Id FROM Plant_Asset_Prompt_Detail__c WHERE Account_Plant__c =: plantAssetId  AND 
            name like :searchString AND Is_Deleted__c = false) 
            AND LinkedEntity.Type='Plant_Asset_Prompt_Detail__c']){
                allfilesRelatedToPAPD.add(contentDocument.ContentDocumentId);
            }

        string promptNamewithCSV = promptName+'.csv';
        List<ContentVersion> getCSVData = new list<ContentVersion>([SELECT Id, Title, VersionData FROM ContentVersion
            WHERE ContentDocumentId =: allfilesRelatedToPAPD
            AND Title =: promptNamewithCSV ORDER BY LastModifiedDate DESC LIMIT 1]);
        
        String csvString;
        if(getCSVData.size()>0){
            csvString = Utils.blobToString( getCSVData[0].VersionData,'ISO-8859-1');
        }else{
            csvString = 'No CSV Files Found';    
        }
        return csvString;
    }

    /**
     * This Method is used to convert the Blob into String
     */
    public static String blobToString(Blob input, String inCharset){
        String hex = EncodingUtil.convertToHex(input);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i)
            bytes[i] =  hex.mid(i << 1, 2);
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }
    
    /**
     * This Method is used to get the csv string based on the Prompt Name, Plant Asset Id and Json Input Values
     */
    public static String getBulkUploadCSVFileforPrompts(String jsonInputParametersAndValues, String plantAssetId,
                    String currentPromptName){
        String promptName;
        String csvData = '';
        if(currentPromptName.contains('/')){
            currentPromptName = currentPromptName.replace('/', '-');
        }

        promptName = (currentPromptName.length()>31) ? currentPromptName.substring(0, 31) : currentPromptName;
        Map<String,String> jsonInputParametersAndValuesMap = Utils.deserializeAttribute(jsonInputParametersAndValues);
        Boolean isBulkUploadCheck = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD));
        Boolean isBulkUploadCheckMultipleBAT = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD_MULTIPLE_BAT));

        if(isBulkUploadCheck || isBulkUploadCheckMultipleBAT){
            csvData = Utils.getCSVString(plantAssetId, promptName);
        }
        return csvData;
    }

    @AuraEnabled
    public static string findG1PromptId(){
        String g1PromptId = PromptNavigationHelper.findPromptId(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
        return g1PromptId;
    }

}