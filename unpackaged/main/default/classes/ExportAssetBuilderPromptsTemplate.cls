/**
**/
public with sharing class ExportAssetBuilderPromptsTemplate {
    /**
     *  @param {Id} PlantAssetId - Plant Asset Id from the g1PromptActionButtons on change of Plant Asset Name.
     *  Query the g1 site metadata record, if exists return true else false
     */
    @AuraEnabled
    public static Boolean updateG1Prompt(Id plantAssetId){
        Boolean result = false;
        try {
            List<site_metadata__c> g1SiteMetadataLst = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);
            Account_Plant__c plantAssetRecord = [SELECT Id, Asset_Builder_Status__c FROM Account_Plant__c WHERE Id =:plantAssetId];
            if(g1SiteMetadataLst.size() > 0 && (plantAssetRecord.Asset_Builder_Status__c == 'In-Progress'
                                                || plantAssetRecord.Asset_Builder_Status__c == '')){
                result = true;
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     *  @param {Id} PlantAssetId - Plant Asset Id from the g1PromptActionButtons on change of Plant Asset Name.
     *  Query the prompt information and its related attributes based on the plant asset Renewable_Type__c or the renewable type of g1 prompt
     *  Return the attribute to the lwc component
     */
    @AuraEnabled
    public static String checkSiteMetadataRecord(Id plantAssetId){
        try {
            Map<String,Object> siteMetadataCheckMap = new Map<String,Object>();
            Account_Plant__c plantAssetRecord = Utils.queryPlantAsset(plantAssetId);
            Boolean assetBuilderProcessExist = false;
            if((plantAssetRecord.Asset_Builder_Status__c == 'In-Progress' || String.isBlank(plantAssetRecord.Asset_Builder_Status__c))){
                List<site_metadata__c> p1SiteMetadataLst = Utils.querySiteMetadata(Constants.P1_PLANT_INFO_PROMPT_SOLAR, plantAssetId);
                if(p1SiteMetadataLst.size()>0){
                    assetBuilderProcessExist = true;
                }
                else {
                    List<Site_Metadata__c> w1SiteMetadataLst = Utils.querySiteMetadata(Constants.W1_PLANT_INFO_PROMPT_WIND, plantAssetId);
                    if(w1SiteMetadataLst.size()>0){
                        assetBuilderProcessExist = true;
                    }
                }

                if(assetBuilderProcessExist){
                    siteMetadataCheckMap.put('assetBuilderProcessExist', true);
                }
                else{
                    Set<String> renewableTypeConfigSet = new Set<String>();
                    Set<String> intersectRenewableTypeSet = new Set<String>();
                    for(RenewableTypesForBulkUpload_AB__mdt renewableTypeConfig :[SELECT Id, Renewable_Type__c FROM RenewableTypesForBulkUpload_AB__mdt]){
                        renewableTypeConfigSet.add(renewableTypeConfig.Renewable_Type__c);
                    }
                    List<site_metadata__c> g1SiteMetadataLst = Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);
                    
                    if(g1SiteMetadataLst.size()>0){
                        siteMetadataCheckMap.put('g1SiteMedataRecord', true);
                        
                        Map<String,String> promptSpecificInfoMap
                            = (Map<String, String>) System.JSON.deserialize(g1SiteMetadataLst[0].Prompt_Specific_Info__c, Map<String, String>.class);
                        
                        Set<String> renewableTypeSet = new Set<String>();
                        if(promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE).contains(';')){
                            renewableTypeSet.addAll(promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE).split(';'));
                        }
                        else{
                            renewableTypeSet.add(promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE));
                        }
                        intersectRenewableTypeSet = Utils.intersectSet(renewableTypeConfigSet, renewableTypeSet); 
                    }
                    else{
                        if(plantAssetRecord.TEM_Version__c == null){
                            List<TEM_Version__c> activeVersion = Utils.queryTemVersion(Constants.ACTIVE);
                            plantAssetRecord.TEM_Version__c = activeVersion[0].Id;
                            update plantAssetRecord;
                        }
                        siteMetadataCheckMap.put('g1SiteMedataRecord', false);
                        Set<String> plantAssetRenewableTypeSet = new Set<String>();
                        String assetSubClass = plantAssetRecord.Renewable_Type__c;
                        
                        if(assetSubClass.contains(';')){
                            plantAssetRenewableTypeSet.addAll(assetSubClass.split(';'));
                        }
                        else{
                            plantAssetRenewableTypeSet.add(assetSubClass);
                        }
                        intersectRenewableTypeSet = Utils.intersectSet(renewableTypeConfigSet, plantAssetRenewableTypeSet); 
                    }

                    if(intersectRenewableTypeSet.size() != 0){
                        siteMetadataCheckMap.put('plantAssetRecord', plantAssetRecord);
                        siteMetadataCheckMap.put('m1PromptName', Constants.M1_MET_MAST_STATION_BUILD);
                        siteMetadataCheckMap.put('s1PromptName', Constants.S1_SUBSTATION_SWITCHGEAR_BUILD);
                        siteMetadataCheckMap.put('Attributes', ExportAssetBuilderPromptsTemplate.queryAttributes(plantAssetId, intersectRenewableTypeSet));
                    }
                    else{
                        siteMetadataCheckMap.put('RenewableTypesForBulkUpload', false);
                    }
                }
            }else{
                siteMetadataCheckMap.put('AssetBuilderStatusCheck', false);
            }           
            return JSON.serialize(siteMetadataCheckMap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     *  @param {Id} plantAssetId - Plant Asset record Id
     *  @param {Set<String>} renewableType - Based on the renewable type , prompt information are queried.
     */
    public static String queryAttributes(Id plantAssetId, Set<String> renewableType){
        Account_Plant__c plantAssetRecord = [SELECT Id, Renewable_Type__c, TEM_Version__c FROM Account_Plant__c WHERE   Id =: plantAssetId];
        
        Id promptSpecificRecordType = Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId();
        Id coreAttributeRecordType = Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId();
       
        Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
        Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED); 
       
        Map<Id,List<Core_Attribute__c>> promptSpecificAttributeMap = new Map<Id,List<Core_Attribute__c>>();
        Map<Id,List<Core_Attribute__c>> coreAttributeMap = new Map<Id,List<Core_Attribute__c>>();
        List<Id> promptLst = new List<Id>();
       
        List<site_metadata__c> g1SiteMetadataLst =  Utils.querySiteMetadata(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT, plantAssetId);
        
        Set<String> renewableTypeSet = new Set<String>();
        renewableTypeSet.addAll(renewableType);

        if(g1SiteMetadataLst.size()>0 && renewableTypeSet.size()>0){
            Map<String,String> promptSpecificInfoMap
                =   (Map<String, String>) System.JSON.deserialize(g1SiteMetadataLst[0].Prompt_Specific_Info__c, Map<String, String>.class);
            
            if(promptSpecificInfoMap.containsKey(Constants.MET_MAST) && Integer.valueOf(promptSpecificInfoMap.get(Constants.MET_MAST))>0){
                renewableTypeSet.add(Constants.MET_MAST);
            }

            if(promptSpecificInfoMap.containsKey(Constants.SWITCHGEAR_SUBSTATION) && Integer.valueOf(promptSpecificInfoMap.get(Constants.SWITCHGEAR_SUBSTATION))>0){
                renewableTypeSet.add(Constants.SubstationSwitchgear);
            }
        }
        else{
            renewableTypeSet.add(Constants.SubstationSwitchgear);
            renewableTypeSet.add(Constants.MET_MAST);
        }

        //Query Prompt Information based on Plant Asset's TEM Version and its renewable type
        Map<String,String> baseAssetIdMap  = new Map<String,String>();
        
        for(Prompt_Information__c promptId :  [SELECT   Id, Base_Asset_Template__c, Name
                                                FROM    Prompt_Information__c 
                                                WHERE   TEM_Version__c =: plantAssetRecord.TEM_Version__c
                                                AND     Type__c IN:renewableTypeSet
                                                AND     Prompt_Type__c = 'Build Prompt'
                                                ORDER BY Compiled_Excel_Sorting_Order__c DESC]){                                      
            baseAssetIdMap.put(promptId.Base_Asset_Template__c,promptId.Id);
            promptLst.add(promptId.Id);
        }

        for(Core_Attribute__c coreAttributeInstance :   [SELECT Alias__c, Attribute_Master__c, Base_Asset_Name__c, Customer_Facing_Notes__c, 
                                                                Data_Type__c, Design_Notes__c, External_Id__c, Id, Is_Alternate_Parent__c,
                                                                Is_Asset_Name__c, Is_Default_Picklist__c, Is_Parent_Asset__c, Is_Read_Only__c,
                                                                Is_Required__c, Is_Unique__c, Name, Prompt_Information__c, RecordTypeId, TEM_Version__c, 
                                                                Attribute_Master__r.Customer_Facing_Notes__c, Prompt_Information__r.Name,
                                                                Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Alias__c,
                                                                RecordType.Name, Plant_Asset_Field_Name__c
                                                        FROM 	Core_Attribute__c
                                                        WHERE   TEM_Version__c =: plantAssetRecord.TEM_Version__c
                                                        AND     Hide_In_Bulk_Import_Template__c = FALSE
                                                        ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name]){
            //Prompt Specific Attribute
            if(coreAttributeInstance.RecordTypeId == promptSpecificRecordType
                && promptLst.contains(coreAttributeInstance.Prompt_Information__c)){
                if(!promptSpecificAttributeMap.containskey(coreAttributeInstance.Prompt_Information__c)){
                    promptSpecificAttributeMap.put(coreAttributeInstance.Prompt_Information__c, new List<Core_Attribute__c>());
                }
                List<Core_Attribute__c> promptSpecificLst = promptSpecificAttributeMap.get(coreAttributeInstance.Prompt_Information__c);
                promptSpecificLst.add(coreAttributeInstance);
                promptSpecificAttributeMap.put(coreAttributeInstance.Prompt_Information__c, promptSpecificLst);
            }
            //Core Attribute 
            else if(coreAttributeInstance.RecordTypeId == coreAttributeRecordType
                    && filteredAttributesId.contains(coreAttributeInstance.Id)
                    && baseAssetIdMap.containsKey(coreAttributeInstance.Base_Asset_Name__c)){
                    Id promptId = baseAssetIdMap.get(coreAttributeInstance.Base_Asset_Name__c);
                if(!coreAttributeMap.containskey(promptId)){
                    coreAttributeMap.put(promptId, new List<Core_Attribute__c>());
                }
                List<Core_Attribute__c> coreAttributeLst = coreAttributeMap.get(promptId);
                coreAttributeLst.add(coreAttributeInstance);
                coreAttributeMap.put(promptId, coreAttributeLst);
            }
        }
        Map<String,Map<String,Object>> ExcelInputsMap = new  Map<String,Map<String,Object>> ();
        for(Id promptInfo : promptLst){
            ExcelInputsMap.put(promptInfo, getExcelInputsMap(promptSpecificAttributeMap.get(promptInfo),
            coreAttributeMap.get(promptInfo)));
        }
        return JSON.serialize(ExcelInputsMap);
    }

    public static Map<String,Object> getExcelInputsMap(
        list<Core_Attribute__c> promptSpecificattribute,
        list<Core_Attribute__c> allCoreAttrLst){
        Map<String,Object> excelInputsMap = new Map<String,Object>();
        excelInputsMap.put('promptSpecificattribute', promptSpecificattribute);
        excelInputsMap.put('coreAttribute', allCoreAttrLst);
        return excelInputsMap;
    }

    @AuraEnabled
    public static string queryDetailPromptAttributes(Id plantAssetId){
        try {
            Account_Plant__c plantAssetRecord = [SELECT Id, TEM_Version__c FROM Account_Plant__c WHERE Id =: plantAssetId];
            
            List<Id> promptIdLst = new List<Id>(); 
            for(Prompt_Information__c promptId :  [SELECT   Id 
                                                    FROM    Prompt_Information__c 
                                                    WHERE   TEM_Version__c =: plantAssetRecord.TEM_Version__c
                                                    AND     Prompt_Type__c = 'Detail Prompt'
                                                    ORDER BY Compiled_Excel_Sorting_Order__c ]){
                promptIdLst.add(promptId.Id);
            }

            Map<Id,List<site_Metadata__c>> siteMetaListMap = new Map<Id,List<site_Metadata__c>>();
            Map<Id,Map<Id,List<Core_Attribute__c>>> coreAttrBsdPI = new  Map<Id,Map<Id,List<Core_Attribute__c>>>();
            set<Id> baseAssetIdSet = new Set<Id>();
            List<Id> parentSiteMetadataLst = new List<Id>();
            // Query the site metadata related to the prompt information
            for(Site_Metadata__c siteMetadataInstance : [SELECT Id, Alternate_Parent_Site_Metadata__r.Asset_Name__c, Parent_Site_Metadata__c,
                                                                Parent_Site_Metadata__r.Asset_Name__c, Asset_Name__c, Attribute_Info__c, 
                                                                Prompt_specific_info__c, Account_Plant__r.Customer_Plant_Asset_ID__c,
                                                                Base_Asset_Template__c, Prompt_Information__c, 
                                                                Prompt_Information__r.Name 
                                                        FROM    Site_Metadata__c
                                                        WHERE   Account_Plant__c =: plantAssetId 
                                                        AND     Prompt_Information__c IN: promptIdLst
                                                        AND     Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false 
                                                        ORDER BY Prompt_Information__r.Compiled_Excel_Sorting_Order__c  DESC,
                                                                Asset_Name__c ]){
                parentSiteMetadataLst.add(siteMetadataInstance.Parent_Site_Metadata__c);         
                //Store the base asset id of each site metadata record
                baseAssetIdSet.add(siteMetadataInstance.Base_Asset_Template__c);

                if(!siteMetaListMap.containskey(siteMetadataInstance.Prompt_Information__c)){
                    siteMetaListMap.put(siteMetadataInstance.Prompt_Information__c, new List<Site_Metadata__c>());
                }
            
                List<Site_Metadata__c> siteMetadataValueLst = siteMetaListMap.get(siteMetadataInstance.Prompt_Information__c);
                siteMetadataValueLst.add(siteMetadataInstance);
                siteMetaListMap.put(siteMetadataInstance.Prompt_Information__c, siteMetadataValueLst);

                if(!coreAttrBsdPI.containskey(siteMetadataInstance.Prompt_Information__c)){
                    coreAttrBsdPI.put(siteMetadataInstance.Prompt_Information__c, new Map<Id,List<Core_Attribute__c>>());
                }
                if(!coreAttrBsdPI.get(siteMetadataInstance.Prompt_Information__c).containskey(siteMetadataInstance.Base_Asset_Template__c)){
                    coreAttrBsdPI.get(siteMetadataInstance.Prompt_Information__c).put(siteMetadataInstance.Base_Asset_Template__c, new List<Core_Attribute__c>());
                }
            }

            List<Site_Metadata__c> siteMetadataAssetLst = [SELECT Id, Asset_Name__c 
                                                            FROM  Site_Metadata__c 
                                                            WHERE Id IN:parentSiteMetadataLst
                                                            OR    Prompt_Information__r.Name =: constants.W3_TURBINE_BUILD];

            //Query the Core Attribute record  based on the base asset id
            Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
            Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);     
            for(Core_Attribute__c CoreAttrInstance : [SELECT    Id, Attribute_Master__r.Name, Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Is_Unique__c,
                                                                Attribute_Master__r.Data_Type__c, Attribute_Master__r.Alias__c, Attribute_Master__r.Units__c, Is_Read_Only__c,
                                                                Base_Asset_Name__c, Base_Asset_Name__r.Name, Name, RecordType.Name, Sorting_Order__c, Plant_Asset_Field_Name__c
                                                        FROM    Core_Attribute__c 
                                                        WHERE   Base_Asset_Name__c IN: baseAssetIdSet 
                                                        AND     RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                                                        AND     Attribute_Master__r.Type__c = 'Metadata'
                                                        AND     Id IN: filteredAttributesId
                                                        AND     Hide_In_Bulk_Import_Template__c = FALSE
                                                        ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name]){
                for(Id promptInfo : coreAttrBsdPI.keyset()){
                    if(coreAttrBsdPI.get(promptInfo).containskey(CoreAttrInstance.Base_Asset_Name__c)){
                        List<Core_Attribute__c> coreAttrList = coreAttrBsdPI.get(promptInfo).get(CoreAttrInstance.Base_Asset_Name__c);
                        coreAttrList.add(CoreAttrInstance);
                        coreAttrBsdPI.get(promptInfo).put(CoreAttrInstance.Base_Asset_Name__c, coreAttrList);
                    }
                }
            }

            Map<Id,List<Core_Attribute__c>> baseAssetAttrMap = new Map<Id,List<Core_Attribute__c>>(); 
            Map<Id,List<Core_Attribute__c>> coreAttrMap = new Map<Id,List<Core_Attribute__c>>();
            for(Id  ptInfo : coreAttrBsdPI.keyset()){
                baseAssetAttrMap = coreAttrBsdPI.get(ptInfo); 
                List<Core_Attribute__c> coreAttrLst = new List<Core_Attribute__c>();
                for(Id baseAssetInfo : baseAssetAttrMap.keyset()){
                    coreAttrLst.addAll(baseAssetAttrMap.get(baseAssetInfo));
                }
                coreAttrMap.put(ptInfo, coreAttrLst);
            }

            // Query the prompt specific attribute related to the prompt information
            Map<Id,List<Core_Attribute__c>> promptSpecificAttributeMap = new Map<Id,List<Core_Attribute__c>>();
            for(Core_Attribute__c promptSpecificInstance :  [SELECT Alias__c, Attribute_Master__c, Base_Asset_Name__c, Customer_Facing_Notes__c, 
                                                                    Data_Type__c, Design_Notes__c, External_Id__c, Id, Is_Alternate_Parent__c,
                                                                    Is_Asset_Name__c, Is_Default_Picklist__c, Is_Parent_Asset__c, Is_Read_Only__c,
                                                                    Is_Required__c, Is_Unique__c, Name, Prompt_Information__c, RecordTypeId, TEM_Version__c, 
                                                                    Attribute_Master__r.Customer_Facing_Notes__c, Plant_Asset_Field_Name__c,
                                                                    Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Alias__c,
                                                                    RecordType.Name
                                                            FROM 	Core_Attribute__c
                                                            WHERE   TEM_Version__c =: plantAssetRecord.TEM_Version__c
                                                            AND     RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
                                                            AND     (Prompt_Information__c IN:siteMetaListMap.keyset())
                                                            AND     Hide_In_Bulk_Import_Template__c = FALSE
                                                            ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name]){
                if(!promptSpecificAttributeMap.containskey(promptSpecificInstance.Prompt_Information__c)){
                    promptSpecificAttributeMap.put(promptSpecificInstance.Prompt_Information__c, new List<Core_Attribute__c>());
                }
                List<Core_Attribute__c> assetNameLst = promptSpecificAttributeMap.get(promptSpecificInstance.Prompt_Information__c);
                assetNameLst.add(promptSpecificInstance);
                promptSpecificAttributeMap.put(promptSpecificInstance.Prompt_Information__c, assetNameLst);
            }
            Map<String,Object> excelInput = new Map<String,Object>();
            Map<String,Map<String,Object>> ExcelInputsMap = new  Map<String,Map<String,Object>> ();
            for(Id promptInfo : siteMetaListMap.keyset()){
                ExcelInputsMap.put(promptInfo, 
                    getExcelInputs(siteMetaListMap.get(promptInfo), 
                                        promptSpecificAttributeMap.get(promptInfo),
                                        coreAttrMap.get(promptInfo)));
            }
            excelInput.put('ExcelInputsMap', ExcelInputsMap);
            excelInput.put('AssetNameLst', siteMetadataAssetLst);
            return JSON.serialize(excelInput);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static Map<String,Object> getExcelInputs(
    List<Site_Metadata__c> siteMetadataLst,
    list<Core_Attribute__c> promptSpecificattribute,
    list<Core_Attribute__c> allCoreAttrLst){
        Map<String,Object> excelInputsMap = new Map<String,Object>();
        excelInputsMap.put('SiteMetadataRecords', siteMetadataLst);
        excelInputsMap.put('promptSpecificattribute', promptSpecificattribute);
        excelInputsMap.put('allCoreAttrLst', allCoreAttrLst);
        return excelInputsMap;
    }
}