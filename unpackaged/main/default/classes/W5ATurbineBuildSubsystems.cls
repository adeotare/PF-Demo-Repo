public with sharing class W5ATurbineBuildSubsystems {
    public Static String currentPromptName = Constants.W5A_TURBINE_BUILD_SUBSYSTEMS;
    public Static String w3PromptName =  Constants.W3_TURBINE_BUILD;
    public Static String w3tAttrName = Constants.BUILD_NAME;
    public Static String w4PromptName = Constants.W4_TURBINE_BUILD_AND_INFO;

    /*
	* Query prompt specific Attribute with Base Asset Template based on  W3 prompt  with Sensor type as "subsystem"  
    * Query Core Attribute based on set of Base asset template
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
    @param {String} jsonInputParametersAndValues - Holds the BulkImport Boolean variable as true or false. 
    */

    @AuraEnabled
    public static String getCustomDatatableCompInput(String plantAssetId, String previousPromptName, Boolean isExecuteClear, String jsonInputParametersAndValues) {
        Savepoint sp;
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

            if(isImpWizUpLoad && isOverride) {
                csvData = Utils2.getImpWizCSVFileforPrompts(jsonInputParametersAndValues, plantAssetId, currentPromptName);
            }
            
            if(isBulkUploadCheckMultipleBAT){
                csvData = Utils.getBulkUploadCSVFileforPrompts(jsonInputParametersAndValues, plantAssetId, currentPromptName);
            }

            Map<String,Object> customDatatableCompInputsMap = new Map<String,Object>();
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
                        
            //Query W3 Prompt Information
            Prompt_Information__c promptInfoW3 = Utils.queryPromptInfo(w3PromptName, plantAssetId);
            
            //Query Prompt Specific Attributes
            List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);
            
            // Query current prompt site metadata table rows
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
            
            //Query Core Attributes
            List<Core_Attribute__c> allCoreAttrLst = new List<Core_Attribute__c>();
            List<Core_Attribute__c> coreAttributes = new List<Core_Attribute__c>();
            list<Core_Attribute__c> coreAttrLst = new List<Core_Attribute__c>();
            
            Map<String, Id> w3PromptAttrNameBaseAssetIdMap = new Map<String,Id>(); 
            
            Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);

            //Query Prompt Specific Attributes
            List<Core_Attribute__c> w3PromptSpecificAttribute = [SELECT Id, Name, Base_Asset_Name__c, Attribute_Master__r.Name
                                            FROM Core_Attribute__c 
                                            WHERE Prompt_Information__c =: promptInfoW3.Id AND Sensor_Type__c =: Constants.SUBSYSTEM
                                            AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
                                            AND TEM_Version__c =: promptInfo.TEM_Version__c
                                            ORDER BY Name ASC];
            for(Core_Attribute__c w3PromptAttr : w3PromptSpecificAttribute){
                w3PromptAttrNameBaseAssetIdMap.put(w3PromptAttr.Attribute_Master__r.Name,w3PromptAttr.Base_Asset_Name__c);
            }

            Map<Id,Base_Asset_Template__c> baseAssetIdtoRecord = new Map<Id,Base_Asset_Template__c>(
                [Select Id, Asset_Short_Name__c FROM Base_Asset_Template__c WHERE Id =: w3PromptAttrNameBaseAssetIdMap.values()]);

            Set<Id> baseAssetIdSet = new Set<Id>();

            Map<String, Integer> w3PromptWithCountOfAttributeMap = new Map<String, Integer>();
            
            Map<String,Map<String,Integer>> buildNameWithW3PromptattrValueMap = new Map<String, Map<String,Integer>>(); 
            List<Site_Metadata__c> w3PromptSiteMetadata = Utils.querySiteMetadata(w3PromptName, plantAssetId);
            
            if(w3PromptSpecificAttribute.size()>0){

                // Loop throught the W3 Site MetaData Records
                for(Site_Metadata__c w3PromptSpecifiInfo: w3PromptSiteMetadata){
                    Map<String,Integer> w3PromptAttrValueMap =new Map<String, Integer>();
                    Map<String, String> promptSpecificInfoMapW3 = 
                        (Map<String, String>) System.JSON.deserialize(w3PromptSpecifiInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                        
                        // Loop to form Map with W3 Attribute Name and Count of the Attribute and also get the Base Asset Id Set
                        for(Core_Attribute__c attrName : w3PromptSpecificAttribute){
                            if(promptSpecificInfoMapW3.containsKey(attrName.Attribute_Master__r.Name)){
                                if(!String.isBlank(promptSpecificInfoMapW3.get(attrName.Attribute_Master__r.Name))){    
                                    w3PromptAttrValueMap.put(attrName.Attribute_Master__r.Name,Integer.valueOf(promptSpecificInfoMapW3.get(attrName.Attribute_Master__r.Name)));
                                    
                                    if(!w3PromptWithCountOfAttributeMap.containsKey(w3PromptSpecifiInfo.Id)){
                                        w3PromptWithCountOfAttributeMap.put(w3PromptSpecifiInfo.Id, 0);
                                    }
                                    Integer countOfRecordsForEachRow = w3PromptWithCountOfAttributeMap.get(w3PromptSpecifiInfo.Id) + Integer.valueOf(promptSpecificInfoMapW3.get(attrName.Attribute_Master__r.Name));
                                    w3PromptWithCountOfAttributeMap.put(w3PromptSpecifiInfo.Id, countOfRecordsForEachRow);
                                    
                                    if(w3PromptAttrNameBaseAssetIdMap.containsKey(attrName.Attribute_Master__r.Name)){
                                        baseAssetIdSet.add(w3PromptAttrNameBaseAssetIdMap.get(attrName.Attribute_Master__r.Name));
                                    }
                                }
                            }
                        }
                    if(!w3PromptAttrValueMap.isEmpty()){
                        buildNameWithW3PromptattrValueMap.put(w3PromptSpecifiInfo.Id,w3PromptAttrValueMap);
                    }
                }
            }else{
                throw new AuraHandledException(System.Label.W5AErrorMessageSubSystemCount);
            }
            
            Map<Id,list<Core_Attribute__c>> baseAssetIdwithCoreAttrLstMap = new Map<Id,list<Core_Attribute__c>>();
            Map<String,Core_Attribute__c> w3CoreAttrWithoutDupeMap = new  Map<String,Core_Attribute__c>();
            if(baseAssetIdSet.size()>0){
                Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
                Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
                Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);

                allCoreAttrLst = Utils.queryAllAttributes(baseAssetIdSet, allAttributesId);
                
                if(allCoreAttrLst.size()>0){     
                    
                    // To form Map from List of core Attributes too the relevant BaseAssetId                    
                    for(Core_Attribute__c attrNameCheck: allCoreAttrLst){
                        if(filteredAttributesId.contains(attrNameCheck.Id)){
                            w3CoreAttrWithoutDupeMap.put(attrNameCheck.Attribute_Master__r.Name,attrNameCheck);
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
                coreAttributes = w3CoreAttrWithoutDupeMap.values();
            }

            List<Site_Metadata__c> rowGeneratorPromptSiteMetadata = Utils.querySiteMetadata(w4PromptName, plantAssetId);
            Map<String, Integer> altenateParentSMWithCountMap = new Map<String, Integer>();
            for(Site_Metadata__c w4PromptInfoRecord : rowGeneratorPromptSiteMetadata){
                if(!altenateParentSMWithCountMap.containsKey(w4PromptInfoRecord.Alternate_Parent_Site_Metadata__c)){
                    altenateParentSMWithCountMap.put(w4PromptInfoRecord.Alternate_Parent_Site_Metadata__c, 0);
                }
                Integer countOfAlternateParentInW4 = altenateParentSMWithCountMap.get(w4PromptInfoRecord.Alternate_Parent_Site_Metadata__c) + 1;
                altenateParentSMWithCountMap.put(w4PromptInfoRecord.Alternate_Parent_Site_Metadata__c, countOfAlternateParentInW4);
            }

            // The currentSitemetadataCount is get the count of current sitemetadata records
            for(String alternateParentSiteMetadata : altenateParentSMWithCountMap.keySet()){
                if(w3PromptWithCountOfAttributeMap.containsKey(alternateParentSiteMetadata)){
                    Integer w4AltenateParentSMCount = Integer.valueOf(altenateParentSMWithCountMap.get(alternateParentSiteMetadata));
                    Integer w3attibuteValueInARow = Integer.valueOf(w3PromptWithCountOfAttributeMap.get(alternateParentSiteMetadata));
                    currentSitemetadataCount +=  (w4AltenateParentSMCount * w3attibuteValueInARow);
                }
            }
            
            if(currentSitemetadataCount >= Constants.RECORD_COUNT_FOR_EACH_PROMPT && currentPromptSiteMetadata.size()<=0){
                String parentPlantAssetPromptDetail;
                if(rowGeneratorPromptSiteMetadata.size()>0){
                    parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
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
                    if(rowGeneratorPromptSiteMetadata.size()>0){
                        parentPlantAssetPromptDetail = rowGeneratorPromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
                    }
                    Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, 
                        previousPromptName, parentPlantAssetPromptDetail);
                    insert plantAssetPromptCreateInstance;
                    list<Site_Metadata__c>siteMetadataCreation = new List<Site_Metadata__c>();
                    
                    //To create W5A Site Metadata Records based on the W4 Site Metadata Records
                    for(Site_Metadata__c w4PromptSpecificInfo: rowGeneratorPromptSiteMetadata){
                        Map<String, String> promptSpecificInfoMapW4 = 
                            (Map<String, String>) System.JSON.deserialize(w4PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                        String turbineBuild = promptSpecificInfoMapW4.get(Constants.TURBINE_BUILD);
                        
                        if(buildNameWithW3PromptattrValueMap.containsKey(turbineBuild)){
                            Map<String, Integer> promptAttributNameToCountMap = buildNameWithW3PromptattrValueMap.get(turbineBuild);
                            String turbineName = promptSpecificInfoMapW4.get(Constants.TURBINE_NAME);
                            String turbineBuildName = promptSpecificInfoMapW4.get(Constants.TURBINE_BUILD);
                            
                            //To get the core attribute list based on baseasset Id in the w3PromptAttrNameBaseAssetIdMap
                            for(String w3PromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                Id baseAssetId;
                                if(w3PromptAttrNameBaseAssetIdMap.containsKey(w3PromptSpecificAttrName)){
                                    baseAssetId =w3PromptAttrNameBaseAssetIdMap.get(w3PromptSpecificAttrName);
                                    if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                        coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                    }    
                                }   
                                Map<String,String>coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                Integer value = promptAttributNameToCountMap.get(w3PromptSpecificAttrName);
                                
                                for(integer i = 1; i<=value;i++){
                                    promptAttributeInfo.put(Constants.TURBINE_BUILD,w4PromptSpecificInfo.Alternate_Parent_Site_Metadata__c);
                                    promptAttributeInfo.put(Constants.TURBINE_NAME,w4PromptSpecificInfo.Id);
                                    promptAttributeInfo.put(Constants.DEVICE_TYPE,w3PromptSpecificAttrName);
                                    String deviceName = turbineName +'-'+w3PromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                    promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
                                    
                                    Site_Metadata__c siteMetadata = Utils.createSiteMetaData(
                                        plantAssetId, currentPromptName,
                                        JSON.serialize(promptAttributeInfo),
                                        plantAssetPromptCreateInstance.Id, JSON.serialize(coreAttributeInfo),
                                        w4PromptSpecificInfo.Id, baseAssetId, promptInfo.Id, deviceName
                                    );
                                    if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                        siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                        siteMetadata.Parent_Asset_Short_Name__c = w4PromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +w4PromptSpecificInfo.Asset_Short_Name__c;
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
                    Map<String, Integer> currentSiteMetadataReadOnlyFieldValuesToCount = new Map<String, Integer>();
                    List<Site_Metadata__c> updatepromptSiteMetaData = new List<Site_Metadata__c>();
                    map<String,String> turbineNameIdToNameMap = new Map<String, String>();
                    for(Site_Metadata__c parentSiteMetadata : rowGeneratorPromptSiteMetadata){
                        Map <String,String> parentPromptSpecificInfoMap =
                            (Map<String, String > ) System.JSON.deserialize(parentSiteMetadata.Prompt_Specific_Info__c, Map < String, String > .class);
                        turbineNameIdToNameMap.put(string.valueof(parentSiteMetadata.Id),parentPromptSpecificInfoMap.get(Constants.TURBINE_NAME));
                    }
                    
                    for(Site_Metadata__c siteMetadata: currentPromptSiteMetadata) {
                        Map <String,String> currentPromptSpecificInfoMap =
                            (Map<String, String > ) System.JSON.deserialize(siteMetadata.Prompt_Specific_Info__c, Map < String, String > .class);
                        String TurbineNameValue = currentPromptSpecificInfoMap.get(Constants.TURBINE_NAME);
                        Id TurbineBuildValue = currentPromptSpecificInfoMap.get(Constants.TURBINE_BUILD);
                        String deviceTypeValue = currentPromptSpecificInfoMap.get(Constants.DEVICE_TYPE);
                        String readOnlyAttrValues =TurbineNameValue+TurbineBuildValue+deviceTypeValue;
                        if (!currentSiteMetadataReadOnlyFieldValuesToCount.containsKey(readOnlyAttrValues)) {
                            currentSiteMetadataReadOnlyFieldValuesToCount.put(readOnlyAttrValues, 0);
                        }
                        Integer count = integer.valueof(currentSiteMetadataReadOnlyFieldValuesToCount.get(readOnlyAttrValues));
                        Integer recordNameSequenceNo  = count + 1;
                        String turbineName = '';
                        if(turbineNameIdToNameMap.containsKey(TurbineNameValue)){
                            turbineName = turbineNameIdToNameMap.get(TurbineNameValue);
                        }
                        currentSiteMetadataReadOnlyFieldValuesToCount.put(readOnlyAttrValues, recordNameSequenceNo );
                        if (String.isBlank(currentPromptSpecificInfoMap.get(Constants.DEVICE_NAME))) {
                            String deviceNameAttrValue = turbineName +'-'+deviceTypeValue + ' ' +string.valueof(recordNameSequenceNo).leftPad(2, '0');
                            currentPromptSpecificInfoMap.put(Constants.DEVICE_NAME, deviceNameAttrValue);
                            siteMetadata.Prompt_Specific_Info__c = JSON.serialize(currentPromptSpecificInfoMap);
                            updatepromptSiteMetaData.add(siteMetadata);
                        }
                    }
                    
                    if(updatepromptSiteMetaData.size()>0){
                        update updatepromptSiteMetaData;
                    }
                }  else if(currentPromptSiteMetadata.size() > 0){
                    Set<String> turbineBuildIds = new Set<String>();
                    Set<Id> turbineNameIdSet = new Set<Id>();
                    for(Site_Metadata__c siteMetaData : currentPromptSiteMetadata){
                        Map<String, String> w5aPromptAttrValueMap = 
                            (Map<String, String>) System.JSON.deserialize(siteMetaData.Prompt_Specific_Info__c,Map<String, String>.class);
                        turbineBuildIds.add(w5aPromptAttrValueMap.get(Constants.TURBINE_BUILD));
                        turbineNameIdSet.add(w5aPromptAttrValueMap.get(Constants.TURBINE_NAME));
                    }
                    //get the newly added list of W4 Prompt SiteMetadata Records.
                    list<Site_Metadata__c> w4NewSiteMetadataLst = [SELECT Id, Name, Attribute_Info__c, Base_Asset_Template__c, Account_Plant__c, Parent_Site_Metadata__r.Asset_Name__c,
                                Prompt_Specific_Info__c, Parent_Site_Metadata__c, Parent_Site_Metadata__r.Name, Previous_Prompt_Name__c, Plant_Asset_Prompt_Detail__c,
                                Parent_Site_Metadata__r.Alternate_Parent_Site_Metadata__r.Asset_Name__c, Alternate_Parent_Site_Metadata__c, Parent_Asset_Short_Name__c, Asset_Short_Name__c
                                FROM Site_Metadata__c 
                                WHERE Name =: w4PromptName AND Id NOT IN:turbineNameIdSet
                                AND Account_Plant__c =: plantAssetId AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false];
                    Map<String,Map<String,Integer>> currentBuildMap = new Map<String,Map<String,Integer>>();
                    for(String turbineBuildId: turbineBuildIds){
                        Map<String,Integer> attrMap = new  Map<String,Integer>();
                        for(Site_Metadata__c siteMetaData : currentPromptSiteMetadata){
                            
                            Map<String, String> w5aPromptAttrValueMap = 
                                (Map<String, String>) System.JSON.deserialize(siteMetaData.Prompt_Specific_Info__c,Map<String, String>.class);
                            if(w5aPromptAttrValueMap.get(Constants.TURBINE_BUILD) == turbineBuildId){
                                String attrName = w5aPromptAttrValueMap.get('Device Type');
                                if(attrMap.containsKey(attrName)){
                                    Integer attCount = attrMap.get(attrName); 
                                    attrMap.put(attrName,attCount+1);
                                } else {
                                    attrMap.put(attrName, 1);
                                }
                            }     
                        }
                        currentBuildMap.put(turbineBuildId,attrMap);  
                    }
                    
                    //To create W5A Site Metadata Records based on the W4 Site Metadata Records
                    list<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                    Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                    for(Site_Metadata__c w4PromptSpecificInfo: rowGeneratorPromptSiteMetadata){
                        Map<String, String> promptSpecificInfoMapW4 = 
                            (Map<String, String>) System.JSON.deserialize(w4PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                             String turbineBuild = promptSpecificInfoMapW4.get(Constants.TURBINE_BUILD);
                                Map<String,Integer> attributeMap = new  Map<String,Integer>();
                                if(buildNameWithW3PromptattrValueMap.containsKey(turbineBuild)){
                                    Map<String, Integer> promptAttributNameToCountMap = buildNameWithW3PromptattrValueMap.get(turbineBuild);
                                    String turbineName = promptSpecificInfoMapW4.get(Constants.TURBINE_NAME);
                                    String turbineBuildName = promptSpecificInfoMapW4.get(Constants.TURBINE_BUILD);
                                    if(currentBuildMap.containsKey(turbineBuildName)){
                                        attributeMap = currentBuildMap.get(turbineBuildName);
                                    }
                                    
                                    //To get the core attribute list based on baseasset Id in the w3PromptAttrNameBaseAssetIdMap
                                    for(String w3PromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                        Id baseAssetId;
                                        if(w3PromptAttrNameBaseAssetIdMap.containsKey(w3PromptSpecificAttrName)){
                                            baseAssetId =w3PromptAttrNameBaseAssetIdMap.get(w3PromptSpecificAttrName);
                                            if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                                coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                            }    
                                        }   
                                        Map<String,String>coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                        Integer newvalue = promptAttributNameToCountMap.get(w3PromptSpecificAttrName);
                                        Integer currentVal=0;
                                        Integer value =0;
                                        if(attributeMap.containsKey(w3PromptSpecificAttrName)){
                                             currentVal = attributeMap.get(w3PromptSpecificAttrName);
                                            if(newvalue > currentVal){
                                              value = (newvalue - currentVal);
                                            }
                                        } else{
                                             currentVal = 0;
                                             newvalue = promptAttributNameToCountMap.get(w3PromptSpecificAttrName);
                                        }
                                       
                                        for(integer i = currentVal+1; i<= newvalue; i++){
                                            promptAttributeInfo.put(Constants.TURBINE_BUILD,w4PromptSpecificInfo.Alternate_Parent_Site_Metadata__c);
                                            promptAttributeInfo.put(Constants.TURBINE_NAME,w4PromptSpecificInfo.Id);
                                            promptAttributeInfo.put(Constants.DEVICE_TYPE,w3PromptSpecificAttrName);
                                            String deviceName = turbineName +'-'+w3PromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                            promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
                                            
                                            Site_Metadata__c siteMetadata = Utils.createSiteMetaData(
                                                plantAssetId, currentPromptName,
                                                JSON.serialize(promptAttributeInfo),
                                                plantAssetPromptDetail.Id, JSON.serialize(coreAttributeInfo),
                                                w4PromptSpecificInfo.Id, baseAssetId, promptInfo.Id, deviceName
                                            );
                                            if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                                siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                                siteMetadata.Parent_Asset_Short_Name__c = w4PromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +w4PromptSpecificInfo.Asset_Short_Name__c;
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
    
                    List<Site_Metadata__c>  existingPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
                    List<String> deviceNameLst = new List<String>();
                        for(Site_Metadata__c siteMetadata:existingPromptSiteMetadata ){
                            Map<String, String> promptSpecificInfoMap = 
                            (Map<String, String>) System.JSON.deserialize(siteMetadata.Prompt_Specific_Info__c,Map<String, String>.class);
                            deviceNameLst.add(promptSpecificInfoMap.get(Constants.DEVICE_NAME));
                        }
                    
                    if(w4NewSiteMetadataLst.size()>0){
                        list<Site_Metadata__c> newsiteMetadataCreation = new List<Site_Metadata__c>();
                        //To create W5A Site Metadata Records based on the W4 Site Metadata Records
                        for(Site_Metadata__c w4PromptSpecificInfo: w4NewSiteMetadataLst){
                            Map<String, String> promptSpecificInfoMapW4 = 
                                (Map<String, String>) System.JSON.deserialize(w4PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                            String turbineBuild = promptSpecificInfoMapW4.get(Constants.TURBINE_BUILD);
                           
                            if(buildNameWithW3PromptattrValueMap.containsKey(turbineBuild)){
                                Map<String, Integer> promptAttributNameToCountMap = buildNameWithW3PromptattrValueMap.get(turbineBuild);
                                String turbineName = promptSpecificInfoMapW4.get(Constants.TURBINE_NAME);
                                String turbineBuildName = promptSpecificInfoMapW4.get(Constants.TURBINE_BUILD);
                                
                                //To get the core attribute list based on baseasset Id in the w3PromptAttrNameBaseAssetIdMap
                                for(String w3PromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                    Id baseAssetId;
                                    if(w3PromptAttrNameBaseAssetIdMap.containsKey(w3PromptSpecificAttrName)){
                                        baseAssetId =w3PromptAttrNameBaseAssetIdMap.get(w3PromptSpecificAttrName);
                                        if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                            coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                        }    
                                    }   
                                    Map<String,String>coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                    Integer value = promptAttributNameToCountMap.get(w3PromptSpecificAttrName);
                                    
                                    for(integer i = 1; i<=value;i++){
                                        promptAttributeInfo.put(Constants.TURBINE_BUILD,w4PromptSpecificInfo.Alternate_Parent_Site_Metadata__c);
                                        promptAttributeInfo.put(Constants.TURBINE_NAME,w4PromptSpecificInfo.Id);
                                        promptAttributeInfo.put(Constants.DEVICE_TYPE,w3PromptSpecificAttrName);
                                        String deviceName = turbineName +'-'+w3PromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                        promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
                                        if(!(deviceNameLst.contains(deviceName))){
                                        Site_Metadata__c siteMetadata = Utils.createSiteMetaData(
                                            plantAssetId, currentPromptName,
                                            JSON.serialize(promptAttributeInfo),
                                            plantAssetPromptDetail.Id, JSON.serialize(coreAttributeInfo),
                                            w4PromptSpecificInfo.Id, baseAssetId, promptInfo.Id, deviceName
                                        );
                                        if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                            siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                            siteMetadata.Parent_Asset_Short_Name__c = w4PromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +w4PromptSpecificInfo.Asset_Short_Name__c;
                                        }
                                        newsiteMetadataCreation.add(siteMetadata);
                                        }
                                    }
                                }
                                coreAttrLst = new List<Core_Attribute__c>();
                            }   
                        }
                        if(newsiteMetadataCreation.size()>0){
                            //sitemetadata insert in Util method
                            Utils.insertSitemetadata(newsiteMetadataCreation);
                        }
                    }
                    currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
                }
            }
            
            Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
            Utils.checkPreviousPlantAsset(plantAssetPromptDetail, previousPromptName);
            //Map<String,Object> dataTableInputString = Utils.getDatatableInputsMap(coreAttributes, promptSpecificAttributes, 
                //currentPromptSiteMetadata, plantAssetPromptDetail, promptInfo);

            Map<String,Object> dataTableInputString = Utils.getDatatableInputsMapWithoutSiteMetadata(coreAttributes, promptSpecificAttributes, 
                currentSitemetadataCount, plantAssetPromptDetail, promptInfo);

            //This condition is to get the next prompt response either to navigate to Next or Finish.
            if(isBulkUploadCheck || isBulkUploadCheckMultipleBAT){
                String nextPromptFinderResponse = Utils.nextPromptFinder(currentPromptName, plantAssetId);
                dataTableInputString.put('nextPromptFinderResponse', nextPromptFinderResponse);
            }

            if(!String.isBlank(csvData) && isBulkUploadCheckMultipleBAT || (isImpWizUpLoad && isOverride)){
                dataTableInputString.put('csvData', csvData);
            }
            return JSON.serialize(dataTableInputString);
        }catch(Exception exceptionDetails){
            sp = Database.setSavepoint();
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
        * On click of Next Button,
            a.  Saves the Current Site Metadata records, only if any changes occured in the prompt which is tracked by a boolean variable "attrValueChanged"
            b.  Based on the next available prompt attribute count, the nextPromptFinder method in the utils class navigates to the next prompt. 
        @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
        @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked
        @param {Boolean} attrValueChanged - Any changes occured in the prompt which is tracked
    */	
    @AuraEnabled
    public static String findNextPromptId(String plantAssetId, String siteMetadataRecordsToSave, Boolean isKeyToGenerateRows, 
        Boolean attrValueChanged, String additionalParamsForNext, Boolean finalBatchBoolean){        
        String nextPromptId;
        try{
            Boolean saveSiteMetadataOutput = true;
            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            Map<String,String> additionalParamsMap  = (Map<String,String>)JSON.deserialize(additionalParamsForNext, Map<String,String>.class); 
            if(!String.isBlank(siteMetadataRecordsToSave)  && additionalParamsMap.get('isReadOnly') == 'false'){ 
                saveSiteMetadataOutput = Utils.saveSiteMetadataRecords(siteMetadataRecordsToSave, plantAssetId, promptInfo, isKeyToGenerateRows, attrValueChanged, finalBatchBoolean);
            }
            if(finalBatchBoolean){
                if(saveSiteMetadataOutput){  
                    nextPromptId = Utils.nextPromptFinder(currentPromptName, plantAssetId);
                } 
                if(nextPromptId.length()<=8 && additionalParamsMap.get('isReadOnly') == 'false'){
                    Utils.updateValidateOnPrevious(plantAssetId,currentPromptName);
                }                
                Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                return Utils.nextPromptFinderResponse(plantAssetId,PromptNavigationHelper.findPromptId(currentPromptName),nextPromptId,plantAssetPromptDetail.Id);
            }else{
                return 'calling Next Batch';
            }
        } catch (Exception exceptionDetails) {
            String errorMessage = System.Label.AssetBuilderExceptionMessage;
            System.debug('Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
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
    public static String  clearPromptInfo(String plantAssetId, String previousPromptName){
        try{
            String result = 'false';
            List<String> retainValuesForPromptAttr = new List<String>{Constants.TURBINE_NAME, Constants.DEVICE_TYPE, Constants.TURBINE_BUILD};
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