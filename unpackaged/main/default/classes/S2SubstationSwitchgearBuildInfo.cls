public with sharing class S2SubstationSwitchgearBuildInfo {
    public Static String currentPromptName = Constants.S2_SUBSTATION_SWITCHGEAR_BUILD_INFO;
    public Static String parentPromptName = Constants.S1_SUBSTATION_SWITCHGEAR_BUILD;
    public Static String parentAttrName = Constants.SUB_SWG_NAME;
    
    /*
     * Query prompt specific Attribute with Base Asset Template based on  S1 prompt  with Sensor type as "Substation switchgear"
     * Query Core Attribute based on above set of Base asset template
     * Query Site Metadata record for current prompt name and Plant Asset Id , and check if any record exists,
        if No,
            a. Create a record in Plant Asset Prompt Detail Object for the current Prompt 
            b. Create Site Metadata record for current Prompt the count of row generate atttribute name
            c. Query Parent Prompt sitemetadata and fetch the alternate prompt specific attribute and query Site Metadata record
                of current prompt and return to lwc "assetBuilderCustomDatatable" for prompt table creation through the current prompt lwc component

        if yes,
            a. New Site Metadata records are  newly created for the curent prompt
            b. Query the Plant Asset Prompt Detail  of current prompt and compares the "Previous_Plant_Asset_Prompt__c" field  with	the previous prompt name.
                if not matched,
                        Previous_Plant_Asset_Prompt__c field is updated with previous prompt name.
            c. Query Site Metadata record of current prompt and return to lwc  "assetBuilderCustomDatatable"  for prompt table creation
                through the current prompt  lwc component
        @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
    */
    @AuraEnabled
    public static String getCustomDatatableCompInput(String plantAssetId, String previousPromptName, Boolean isExecuteClear, String jsonInputParametersAndValues) {
        Savepoint sp = Database.setSavepoint();
        try{
            String csvData; 
            Boolean isBulkUploadCheck = false; //This attibute holds whether the prompt navigates based on BulkImport or User Guided Navigation
            Boolean isBulkUploadCheckMultipleBAT = false; // This attribute  holds whether the prompt navigates based on BulkImport or User Guided Navigation for Multiple Base Asset Template Import
            Boolean isImpWizUpLoad = false;
            Boolean isOverride = false;
            Integer currentSitemetadataCount = 0;

            if(!String.isBlank(jsonInputParametersAndValues)){
                Map<String,String> jsonInputParametersAndValuesMap = Utils.deserializeAttribute(jsonInputParametersAndValues);
                isBulkUploadCheck = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD));
                isBulkUploadCheckMultipleBAT = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_BULK_UPLOAD_MULTIPLE_BAT));
                isImpWizUpLoad = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_IMPWIZ_UPLOAD));
                isOverride = Boolean.valueOf(jsonInputParametersAndValuesMap.get(Constants.IS_OVERRIDE));
            }

            if(isImpWizUpLoad  && isOverride) {
                csvData = Utils2.getImpWizCSVFileforPrompts(jsonInputParametersAndValues, plantAssetId, currentPromptName);
            }
            
            if(isBulkUploadCheckMultipleBAT){
                csvData = Utils.getBulkUploadCSVFileforPrompts(jsonInputParametersAndValues, plantAssetId, currentPromptName);
            }


            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            //Query parent Prompt Information
            Prompt_Information__c promptInfoparent = Utils.queryPromptInfo(parentPromptName, plantAssetId);
            String baseAssetShortName = promptInfo.Base_Asset_Template__r.Asset_Short_Name__c;
            Id basetAssetId = promptInfo.Base_Asset_Template__c;
            //Query Prompt Specific Attributes
            List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);
            
            // Query current prompt site metadata table rows
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
            
            //Query Core Attributes
            List<Core_Attribute__c> allCoreAttrLst = new List<Core_Attribute__c>();
            list<Core_Attribute__c> coreAttributes = new List<Core_Attribute__c>();
            list<Core_Attribute__c> coreAttrLst = new List<Core_Attribute__c>();
            
            Map<String, Id> parentPromptAttrNameBaseAssetIdMap = new Map<String,Id>(); 
            
            Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
            
            //Query Prompt Specific Attributes
            List<Core_Attribute__c> parentPromptSpecificAttribute =[SELECT Id, Name, Type__c, Picklist_Master__c,Attribute_Master__r.name,	 
                                                                    Alias__c, RecordtypeId, Picklist_Dependency1__c,
                                                                    Base_Asset_Name__c, Prompt_Information__c, Is_Unique__c, 
                                                                    Picklist_Dependency1__r.Name, Is_Read_Only__c,Wind_Prompt_Attribute_Type__c
                                                                    FROM Core_Attribute__c 
                                                                    WHERE Prompt_Information__c =: promptInfoparent.Id 
                                                                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
                                                                    AND TEM_Version__c =: promptInfo.TEM_Version__c
                                                                    AND Sensor_Type__c='Substation switchgear' ORDER BY Name ASC];
            
            for(Core_Attribute__c parentPromptAttr : parentPromptSpecificAttribute){
                parentPromptAttrNameBaseAssetIdMap.put(parentPromptAttr.Attribute_Master__r.Name,parentPromptAttr.Base_Asset_Name__c);
            }

            Map<Id,Base_Asset_Template__c> baseAssetIdtoRecord = new Map<Id,Base_Asset_Template__c>(
                [Select Id, Asset_Short_Name__c FROM Base_Asset_Template__c WHERE Id =: parentPromptAttrNameBaseAssetIdMap.values()]);
            
            Set<Id> baseAssetIdSet = new Set<Id>();
            
            Map<String,Map<String,Integer>> buildNameWithparentPromptattrValueMap = new Map<String, Map<String,Integer>>(); 
            List<Site_Metadata__c> parentPromptSiteMetadata = Utils.querySiteMetadata(parentPromptName, plantAssetId);
            
            if(parentPromptSpecificAttribute.size()>0){
                // Loop throught the parent Site MetaData Records
                for(Site_Metadata__c parentPromptSpecifiInfo: parentPromptSiteMetadata){
                    Map<String,Integer> parentPromptAttrValueMap =new Map<String, Integer>();
                    Map<String, String> currentPromptSpecificInfoMap = 
                        (Map<String, String>) System.JSON.deserialize(parentPromptSpecifiInfo.Prompt_Specific_Info__c, Map<String, String>.class);
                    
                    // Loop to form Map with parent Attribute Name and Count of the Attribute and also get the Base Asset Id Set
                    for(Core_Attribute__c attrName : parentPromptSpecificAttribute){
                        if(currentPromptSpecificInfoMap.containsKey(attrName.Attribute_Master__r.Name)){
                            if(!String.isBlank(currentPromptSpecificInfoMap.get(attrName.Attribute_Master__r.Name))){    
                                parentPromptAttrValueMap.put(attrName.Attribute_Master__r.Name,Integer.valueOf(currentPromptSpecificInfoMap.get(attrName.Attribute_Master__r.Name)));
                                
                                // The currentSitemetadataCount is get the count of current sitemetadata records
                                currentSitemetadataCount += Integer.valueOf(currentPromptSpecificInfoMap.get(attrName.Attribute_Master__r.Name));
                                
                                if(parentPromptAttrNameBaseAssetIdMap.containsKey(attrName.Attribute_Master__r.Name)){
                                    baseAssetIdSet.add(parentPromptAttrNameBaseAssetIdMap.get(attrName.Attribute_Master__r.Name));
                                }
                            }
                        }
                    }
                    if(!parentPromptAttrValueMap.isEmpty()){
                        buildNameWithparentPromptattrValueMap.put(currentPromptSpecificInfoMap.get(parentAttrName),parentPromptAttrValueMap);
                    }
                }
            }else{
                throw new AuraHandledException(System.Label.S2ErrorMessageSwitchGearAndSubSystemCount);
            }
            
            Map<Id,list<Core_Attribute__c>> baseAssetIdwithCoreAttrLstMap = new Map<Id,list<Core_Attribute__c>>();
            Map<String,Core_Attribute__c> parentCoreAttrWithoutDupeMap = new Map<String,Core_Attribute__c>();
            if(baseAssetIdSet.size()>0){
                Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
                Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
                Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
                allCoreAttrLst = Utils.queryAllAttributes(baseAssetIdSet, allAttributesId);
                
                if(allCoreAttrLst.size()>0){     
                    // To form Map from List of core Attributes to the relevant BaseAssetId                    
                    for(Core_Attribute__c attrNameCheck: allCoreAttrLst){
                        if(filteredAttributesId.contains(attrNameCheck.Id)){
                            parentCoreAttrWithoutDupeMap.put(attrNameCheck.Attribute_Master__r.Name,attrNameCheck);
                        }
                        Id baseAssetId = attrNameCheck.Base_Asset_Name__c;
                        if (!baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){
                            baseAssetIdwithCoreAttrLstMap.put(baseAssetId, new List<Core_Attribute__c>());
                        }  
                        baseAssetIdwithCoreAttrLstMap.get(baseAssetId).add(attrNameCheck);
                    }
                }
            }
            if(allCoreAttrLst.size()>0){
                coreAttributes = parentCoreAttrWithoutDupeMap.values();
            }

            if(currentSitemetadataCount >= Constants.RECORD_COUNT_FOR_EACH_PROMPT && currentPromptSiteMetadata.size()<=0){
                String parentPlantAssetPromptDetail;
                if(parentPromptSiteMetadata.size()>0){
                    parentPlantAssetPromptDetail = parentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
                }
                list<Plant_Asset_Prompt_Detail__c> plantAssetPromptDetailLst = [SELECT Id,Name FROM Plant_Asset_Prompt_Detail__c WHERE 
                    Account_Plant__c =: plantAssetId AND Is_Deleted__c = false AND
                    Prompt_Information__r.Name =: currentPromptName];
                if(plantAssetPromptDetailLst.size()<=0){
                    Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                    insert plantAssetPromptCreateInstance; 
                }
            }

            if(currentSitemetadataCount < Constants.RECORD_COUNT_FOR_EACH_PROMPT){
                if(currentPromptSiteMetadata.size()<=0){
                    String parentPlantAssetPromptDetail;
                    if(parentPromptSiteMetadata.size()>0){
                        parentPlantAssetPromptDetail = parentPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
                    }
                    Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                    insert plantAssetPromptCreateInstance;
    
                    list<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                    
                    //To create Current Site Metadata Records based on the parent Site Metadata Records
                    for(Site_Metadata__c parentPromptSpecificInfo: parentPromptSiteMetadata){
                        Map<String, String> currentPromptSpecificInfoMap = 
                            (Map<String, String>) System.JSON.deserialize(parentPromptSpecificInfo.Prompt_Specific_Info__c, Map<String, String>.class);
                        String subSwgName = currentPromptSpecificInfoMap.get(Constants.SUB_SWG_NAME);
                        
                        if(buildNameWithparentPromptattrValueMap.containsKey(subSwgName)){
                            Map<String, Integer> promptAttributNameToCountMap = buildNameWithparentPromptattrValueMap.get(subSwgName);
                            
                            //To get the core attribute list based on baseasset Id in the parentPromptAttrNameBaseAssetIdMap
                            for(String parentPromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                Id baseAssetId;
                                if(parentPromptAttrNameBaseAssetIdMap.containsKey(parentPromptSpecificAttrName)){
                                    baseAssetId = parentPromptAttrNameBaseAssetIdMap.get(parentPromptSpecificAttrName); 
                                    if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                        coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                    }    
                                }   
                                Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                Integer value = promptAttributNameToCountMap.get(parentPromptSpecificAttrName);
                                
                                //Get the count based on the Prompt Specific Attributes with type met Substation switchgear sensor present in parent Prompt 
                                for(integer i = 1; i<=value;i++){
                                    promptAttributeInfo.put(Constants.SUB_SWG_NAME,parentPromptSpecificInfo.Id);
                                    promptAttributeInfo.put(Constants.DEVICE_TYPE,parentPromptSpecificAttrName);
                                    String deviceName = subSwgName +'-'+parentPromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                    promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
                                    
                                    Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                                                             String.valueOf(plantAssetPromptCreateInstance.Id), JSON.serialize(coreAttributeInfo),
                                                                                             String.valueOf(parentPromptSpecificInfo.Id), baseAssetId, promptInfo.Id, deviceName);
                                    if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                        siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                        if(parentPromptSpecificInfo.Asset_Short_Name__c !=null){
                                            siteMetadata.Parent_Asset_Short_Name__c = parentPromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +parentPromptSpecificInfo.Asset_Short_Name__c;
                                        }else{
                                            siteMetadata.Parent_Asset_Short_Name__c = parentPromptSpecificInfo.Parent_Asset_Short_Name__c;
                                        }
                                    }
                                    siteMetadataCreation.add(siteMetadata);
                                }
                            }
                            coreAttrLst = new List<Core_Attribute__c>();
                        }   
                    }
                    if(siteMetadataCreation.size()>0){
                        //sitemetadata insert in Util method
                        Utils.insertSitemetadata(siteMetadataCreation);
                    }
                    currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
                }else if(isExecuteClear){
                    List<Site_Metadata__c> rowGenPromptSiteMetaData = Utils.querySiteMetadata(parentPromptName, plantAssetId);
                    Map<String,String> siteMetadataIdtoAttrMap = new  Map<String,String>();
                    for(Site_Metadata__c s1PromptSpecificInfo: rowGenPromptSiteMetaData){
                        Map<String, String> promptSpecificInfoMapS2 = 
                            (Map<String, String>) System.JSON.deserialize(s1PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                        siteMetadataIdtoAttrMap.put(s1PromptSpecificInfo.Id, promptSpecificInfoMapS2.get(Constants.SUB_SWG_NAME));
                    }
                    
                    Map<String, Integer> currentSiteMetadataReadOnlyFieldValuesToCount = new Map<String, Integer>();
                    List<Site_Metadata__c> updatepromptSiteMetaData = new List<Site_Metadata__c>();
                    
                    for(Site_Metadata__c siteMetadata: currentPromptSiteMetadata) {
                        Map <String,String> currentPromptSpecificInfoMap =
                            (Map<String, String>) System.JSON.deserialize(siteMetadata.Prompt_Specific_Info__c, Map<String,String>.class);
                        String subSwgNameId = currentPromptSpecificInfoMap.get(Constants.SUB_SWG_NAME);
                        String subSwgNameValue ='';
                        if(siteMetadataIdtoAttrMap.containsKey(subSwgNameId)){
                            subSwgNameValue = siteMetadataIdtoAttrMap.get(subSwgNameId);
                        }
                        
                        String deviceTypeValue = currentPromptSpecificInfoMap.get(Constants.DEVICE_TYPE);
                        String readOnlyAttrValues =subSwgNameValue+deviceTypeValue;
                        if (!currentSiteMetadataReadOnlyFieldValuesToCount.containsKey(readOnlyAttrValues)) {
                            currentSiteMetadataReadOnlyFieldValuesToCount.put(readOnlyAttrValues, 0);
                        }
                        Integer count = integer.valueof(currentSiteMetadataReadOnlyFieldValuesToCount.get(readOnlyAttrValues));
                        Integer recordNameSequenceNo  = count + 1;
                        currentSiteMetadataReadOnlyFieldValuesToCount.put(readOnlyAttrValues, recordNameSequenceNo );
                        if (String.isBlank(currentPromptSpecificInfoMap.get(Constants.DEVICE_NAME))) {
                            String deviceNameAttrValue = subSwgNameValue +'-'+deviceTypeValue + ' ' +string.valueof(recordNameSequenceNo).leftPad(2, '0');
                            currentPromptSpecificInfoMap.put(Constants.DEVICE_NAME, deviceNameAttrValue);
                            siteMetadata.Prompt_Specific_Info__c = JSON.serialize(currentPromptSpecificInfoMap);
                            updatepromptSiteMetaData.add(siteMetadata);
                        }
                    }
                    
                    if(updatepromptSiteMetaData.size()>0){
                        update updatepromptSiteMetaData;
                    }
                } else if(currentPromptSiteMetadata.size() > 0){
                    Set<String> subSwagNameIds = new Set<String>();
                    for(Site_Metadata__c siteMetaData : currentPromptSiteMetadata){
                        Map<String, String> S2PromptAttrValueMap = 
                            (Map<String, String>) System.JSON.deserialize(siteMetaData.Prompt_Specific_Info__c,Map<String, String>.class);
                        subSwagNameIds.add(S2PromptAttrValueMap.get(Constants.SUB_SWG_NAME));
                        
                    }
                    //get the newly Inserted S1 siteMetadata records
                    List<Site_Metadata__c> s1NewSiteMetadataLst = [SELECT Id, Name, Attribute_Info__c, Base_Asset_Template__c, Account_Plant__c, Parent_Site_Metadata__r.Asset_Name__c,
                                                                   Prompt_Specific_Info__c, Parent_Site_Metadata__c, Parent_Site_Metadata__r.Name, Previous_Prompt_Name__c, Plant_Asset_Prompt_Detail__c,
                                                                   Parent_Site_Metadata__r.Alternate_Parent_Site_Metadata__r.Asset_Name__c, Alternate_Parent_Site_Metadata__c,Asset_Short_Name__c,Parent_Asset_Short_Name__c
                                                                   FROM Site_Metadata__c 
                                                                   WHERE Name =: parentPromptName AND Id NOT IN:subSwagNameIds
                                                                   AND Account_Plant__c =: plantAssetId AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false];
                    Map<String,Map<String,Integer>> currentBuildMap = new Map<String,Map<String,Integer>>();
                    for(String subSwagNameId: subSwagNameIds){
                        Map<String,Integer> attrMap = new  Map<String,Integer>();
                        for(Site_Metadata__c siteMetaData : currentPromptSiteMetadata){
                            Map<String, String> m2PromptAttrValueMap = 
                                (Map<String, String>) System.JSON.deserialize(siteMetaData.Prompt_Specific_Info__c,Map<String, String>.class);
                            if(m2PromptAttrValueMap.get(Constants.SUB_SWG_NAME) == subSwagNameId){
                                String attrName = m2PromptAttrValueMap.get(Constants.DEVICE_TYPE);
                                if(attrMap.containsKey(attrName)){
                                    Integer attCount = attrMap.get(attrName); 
                                    attrMap.put(attrName,attCount+1);
                                } else {
                                    attrMap.put(attrName, 1);
                                }
                            }
                        }
                        currentBuildMap.put(subSwagNameId,attrMap);
                    }
                    
                    
                    //To create S2 Site Metadata Records based on the SS1 Site Metadata Records
                    List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                    for(Site_Metadata__c s1PromptSpecificInfo: parentPromptSiteMetadata){
                        Map<String, String> promptSpecificInfoMapS1 = 
                            (Map<String, String>) System.JSON.deserialize(s1PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                        String subSwagName = promptSpecificInfoMapS1.get(Constants.SUB_SWG_NAME);
                        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                        if(buildNameWithparentPromptattrValueMap.containsKey(subSwagName)){
                            Map<String,Integer> attributeMap = new  Map<String,Integer>();
                            Map<String, Integer> promptAttributNameToCountMap = buildNameWithparentPromptattrValueMap.get(subSwagName);
                            if(currentBuildMap.containsKey(s1PromptSpecificInfo.Id)){
                                attributeMap = currentBuildMap.get(s1PromptSpecificInfo.Id);
                                //To get the core attribute list based on baseasset Id in the s1PromptAttrNameBaseAssetIdMap
                                for(String parentPromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                    Id baseAssetId;
                                    if(parentPromptAttrNameBaseAssetIdMap.containsKey(parentPromptSpecificAttrName)){
                                        baseAssetId =parentPromptAttrNameBaseAssetIdMap.get(parentPromptSpecificAttrName); 
                                        if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                            coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                        }    
                                    }   
                                    Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                    Integer newvalue = promptAttributNameToCountMap.get(parentPromptSpecificAttrName);
                                    Integer currentVal=0;
                                    Integer value =0;
                                    if(attributeMap.containsKey(parentPromptSpecificAttrName)){
                                        currentVal = attributeMap.get(parentPromptSpecificAttrName);
                                        if(newvalue > currentVal){
                                            value = (newvalue - currentVal);
                                        }
                                    } else{
                                        currentVal = 0;
                                        newvalue = promptAttributNameToCountMap.get(parentPromptSpecificAttrName);
                                    }
                                    
                                    //Get the count based on the Prompt Specific Attributes with type met station sensor present in m1 Prompt 
                                    for(integer i = currentVal+1; i<= newvalue; i++){
                                        promptAttributeInfo.put(Constants.SUB_SWG_NAME,s1PromptSpecificInfo.Id);
                                        promptAttributeInfo.put(Constants.DEVICE_TYPE,parentPromptSpecificAttrName);
                                        String deviceName = subSwagName +'-'+parentPromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                        promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
                                        
                                        Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                                                                 String.valueOf(plantAssetPromptDetail.Id), JSON.serialize(coreAttributeInfo),
                                                                                                 String.valueOf(s1PromptSpecificInfo.Id), baseAssetId, promptInfo.Id, deviceName);
                                        
                                        if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                            siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                            if(s1PromptSpecificInfo.Asset_Short_Name__c !=null){
                                                siteMetadata.Parent_Asset_Short_Name__c = s1PromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +s1PromptSpecificInfo.Asset_Short_Name__c;
                                            }else{
                                                siteMetadata.Parent_Asset_Short_Name__c = s1PromptSpecificInfo.Parent_Asset_Short_Name__c;
                                            }
                                        }
                                        siteMetadataCreation.add(siteMetadata);
                                    }
                                }
                                coreAttrLst = new List<Core_Attribute__c>();
                            }
                        }   
                    }
                    
                    if(siteMetadataCreation.size()>0){
                        //sitemetadata insert in Util method
                        Utils.insertSitemetadata(siteMetadataCreation);
                    }
        
                    if(s1NewSiteMetadataLst.size()>0){
                        list<Site_Metadata__c> newSiteMetadataCreation = new List<Site_Metadata__c>();
                        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                        //To create Current Site Metadata Records based on the parent Site Metadata Records
                        for(Site_Metadata__c parentPromptSpecificInfo: s1NewSiteMetadataLst){
                            Map<String, String> currentPromptSpecificInfoMap = 
                                (Map<String, String>) System.JSON.deserialize(parentPromptSpecificInfo.Prompt_Specific_Info__c, Map<String, String>.class);
                            String subSwgName = currentPromptSpecificInfoMap.get(Constants.SUB_SWG_NAME);
                            
                            if(buildNameWithparentPromptattrValueMap.containsKey(subSwgName)){
                                Map<String, Integer> promptAttributNameToCountMap = buildNameWithparentPromptattrValueMap.get(subSwgName);
                                
                                //To get the core attribute list based on baseasset Id in the parentPromptAttrNameBaseAssetIdMap
                                for(String parentPromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                    Id baseAssetId;
                                    if(parentPromptAttrNameBaseAssetIdMap.containsKey(parentPromptSpecificAttrName)){
                                        baseAssetId = parentPromptAttrNameBaseAssetIdMap.get(parentPromptSpecificAttrName); 
                                        if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                            coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                        }    
                                    }   
                                    Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                    Integer value = promptAttributNameToCountMap.get(parentPromptSpecificAttrName);
                                    
                                    //Get the count based on the Prompt Specific Attributes with type met Substation switchgear sensor present in parent Prompt 
                                    for(integer i = 1; i<=value;i++){
                                        promptAttributeInfo.put(Constants.SUB_SWG_NAME,parentPromptSpecificInfo.Id);
                                        promptAttributeInfo.put(Constants.DEVICE_TYPE,parentPromptSpecificAttrName);
                                        String deviceName = subSwgName +'-'+parentPromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                        promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
                                        
                                        Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                                                                 String.valueOf(plantAssetPromptDetail.Id), JSON.serialize(coreAttributeInfo),
                                                                                                 String.valueOf(parentPromptSpecificInfo.Id), baseAssetId, promptInfo.Id, deviceName);
                                        if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                            siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                            if(parentPromptSpecificInfo.Asset_Short_Name__c !=null){
                                                siteMetadata.Parent_Asset_Short_Name__c = parentPromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +parentPromptSpecificInfo.Asset_Short_Name__c;
                                            }else{
                                                siteMetadata.Parent_Asset_Short_Name__c = parentPromptSpecificInfo.Parent_Asset_Short_Name__c;
                                            }
                                        }
                                        newSiteMetadataCreation.add(siteMetadata);
                                    }
                                }
                                coreAttrLst = new List<Core_Attribute__c>();
                            }   
                        }
                        if(newSiteMetadataCreation.size()>0){
                            //sitemetadata insert in Util method
                            Utils.insertSitemetadata(newSiteMetadataCreation);
                        }
                    }
                    currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
                }
            }
            
            Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
            Utils.checkPreviousPlantAsset(plantAssetPromptDetail, previousPromptName);
            //Map<String,Object> customDatatableCompInputsMap = Utils.getDatatableInputsMap(coreAttributes, promptSpecificAttributes, 
                //currentPromptSiteMetadata, plantAssetPromptDetail, promptInfo);
            
            Map<String,Object> customDatatableCompInputsMap = Utils.getDatatableInputsMapWithoutSiteMetadata(coreAttributes, promptSpecificAttributes, 
                currentSitemetadataCount, plantAssetPromptDetail, promptInfo);
            if(!String.isBlank(csvData) && isBulkUploadCheckMultipleBAT || (isImpWizUpLoad && isOverride)){
                customDatatableCompInputsMap.put('csvData', csvData);
            }

            return JSON.serialize(customDatatableCompInputsMap);
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /*
        * On click of Save button, calls "saveSiteMetadataRecords" of the prompt Controller,
            a. Pass the modified site metadata records from  lwc  "assetBuilderCustomDatatable" , Plant Asset id, Prompt Information, isKeyToGenerateRows to the "saveSiteMetadataRecords" method of Utils Class.
            b. Any decrease in the prompt specific attribute in Parent prompt is tracked by a boolean variable "isKeyToGenerateRows".
        @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
        @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked  
    */
    @AuraEnabled
    public static Boolean saveSiteMetadataRecords(String siteMetadataRecordsToSave, String plantAssetId, Boolean isKeyToGenerateRows,
        Boolean attrValueChanged, Boolean finalBatchBoolean){
        try{
            if(!String.isBlank(siteMetadataRecordsToSave)){
                Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
                return Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
            }else{
                return true;
            }
        }catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    }
    
    /*
        * On click of Clear Button, calls "clearPromptInfo" of Prompt Controller 
            a.makes the attribute Info and Prompt specific info field into empty and again calls the getCustomDatatableCompInput method to generate the prompt
        @param {String} plantAssetId - Holds the PlantAsset  Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {String} previousPromptName - Holds the name of the previous prompt, stored in the site metadata records for the previous navigation.
    */
    @AuraEnabled
    public static String clearPromptInfo(String plantAssetId, String previousPromptName){
        try{
            String result = 'false';
            List<String> retainValuesForPromptAttr = new List<String>{Constants.SUB_SWG_NAME, Constants.DEVICE_TYPE};
                List<String> retainValuesForCoreAttr = new List<String>();
            
            Boolean clearPromptInfoResult = Utils.clearPromptInfo(plantAssetId, currentPromptName, retainValuesForCoreAttr, retainValuesForPromptAttr);
            
            if(clearPromptInfoResult){
                result = getCustomDatatableCompInput(plantAssetId, previousPromptName, true, '');
            }
            return result;
        }catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
    } 
}