public with sharing class M2MetMastStationBuild {
    public Static String currentPromptName = Constants.M2_METMAST_STATION_BUILD;
    public Static String m1PromptName = Constants.M1_MET_MAST_STATION_BUILD;
    public Static String m1tAttrName = Constants.STATION_NAME;
    
    /*
    * Query prompt specific Attribute with Base Asset Template based on  M1 prompt  with Sensor type as "Met Mast"
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
            Boolean isBulkUploadCheck = false;
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

            Prompt_Information__c promptInfo = Utils.queryPromptInfo(currentPromptName, plantAssetId);
            String baseAssetShortName = promptInfo.Base_Asset_Template__r.Asset_Short_Name__c;
            Id basetAssetId = promptInfo.Base_Asset_Template__c;
            //Query M1 Prompt Information
            Prompt_Information__c promptInfoM1 = Utils.queryPromptInfo(m1PromptName, plantAssetId);
            
            //Query Prompt Specific Attributes
            List<Core_Attribute__c> promptSpecificAttributes = Utils.queryPromptAttributes(promptInfo.Id, plantAssetId);
            
            // Query current prompt site metadata table rows
            List<Site_Metadata__c> currentPromptSiteMetadata = Utils.querySortedSiteMetadata(currentPromptName, plantAssetId);
            
            //Query Core Attributes
            List<Core_Attribute__c> allCoreAttrLst = new List<Core_Attribute__c>();
            List<Core_Attribute__c> coreAttributes = new List<Core_Attribute__c>();
            list<Core_Attribute__c> coreAttrLst = new List<Core_Attribute__c>();
            
            Map<String, Id> m1PromptAttrNameBaseAssetIdMap = new Map<String,Id>(); 
            
            Map<String,String> promptAttributeInfo = Utils.formAttributeNametoValueMap(promptSpecificAttributes);
            
            //Query Prompt Specific Attributes
            List<Core_Attribute__c> m1PromptSpecificAttribute =[SELECT Id, Name, Type__c, Picklist_Master__c, Attribute_Master__r.Name,
                                                                Alias__c, RecordtypeId, Picklist_Dependency1__c,
                                                                Base_Asset_Name__c, Prompt_Information__c, Is_Unique__c, 
                                                                Picklist_Dependency1__r.Name, Is_Read_Only__c,Wind_Prompt_Attribute_Type__c
                                                                FROM Core_Attribute__c 
                                                                WHERE Prompt_Information__c =: promptInfoM1.Id 
                                                                AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_PROMPT_SPECIFIC_ATTRIBUTE).getRecordTypeId()
                                                                AND TEM_Version__c =: promptInfoM1.TEM_Version__c
                                                                AND Sensor_Type__c= :Constants.MET_MAST ORDER BY Name ASC];
            
            
            for(Core_Attribute__c m1PromptAttr : m1PromptSpecificAttribute){
                m1PromptAttrNameBaseAssetIdMap.put(m1PromptAttr.Attribute_Master__r.Name, m1PromptAttr.Base_Asset_Name__c);
            }
            
            Map<Id,Base_Asset_Template__c> baseAssetIdtoRecord = new Map<Id,Base_Asset_Template__c>(
                [Select Id, Asset_Short_Name__c FROM Base_Asset_Template__c WHERE Id =: m1PromptAttrNameBaseAssetIdMap.values()]);

            Set<Id> baseAssetIdSet = new Set<Id>();
               
            Map<String,Map<String,Integer>> buildNameWithM1PromptattrValueMap = new Map<String, Map<String,Integer>>(); 
            List<Site_Metadata__c> m1PromptSiteMetadata = Utils.querySiteMetadata(m1PromptName, plantAssetId);
            
            if(m1PromptSpecificAttribute.size()>0){
                // Loop throught the M1 Site MetaData Records
                for(Site_Metadata__c m1PromptSpecifiInfo: m1PromptSiteMetadata){
                    Map<String,Integer> m1PromptAttrValueMap =new Map<String, Integer>();
                    Map<String, String> promptSpecificInfoMapM2 = 
                        (Map<String, String>) System.JSON.deserialize(m1PromptSpecifiInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                    
                    // Loop to form Map with M1 Attribute Name and Count of the Attribute and also get the Base Asset Id Set
                    for(Core_Attribute__c attrName : m1PromptSpecificAttribute){
                        if(promptSpecificInfoMapM2.containsKey(attrName.Attribute_Master__r.Name)){
                            if(!String.isBlank(promptSpecificInfoMapM2.get(attrName.Attribute_Master__r.Name))){    
                                m1PromptAttrValueMap.put(attrName.Attribute_Master__r.Name,Integer.valueOf(promptSpecificInfoMapM2.get(attrName.Attribute_Master__r.Name)));
                                
                                // This currentSitemetadataCount is get the count of current sitemetadata records
                                currentSitemetadataCount += Integer.valueOf(promptSpecificInfoMapM2.get(attrName.Attribute_Master__r.Name));
                                
                                if(m1PromptAttrNameBaseAssetIdMap.containsKey(attrName.Attribute_Master__r.Name)){
                                    baseAssetIdSet.add(m1PromptAttrNameBaseAssetIdMap.get(attrName.Attribute_Master__r.Name));
                                }
                            }
                        }
                    }
                    if(!m1PromptAttrValueMap.isEmpty()){
                        buildNameWithM1PromptattrValueMap.put(promptSpecificInfoMapM2.get(m1tAttrName),m1PromptAttrValueMap);
                    }
                }
            }else{
                throw new AuraHandledException(System.Label.M2ErrorMessageSubSystemCount);
            }
            
            Map<Id,list<Core_Attribute__c>> baseAssetIdwithCoreAttrLstMap = new Map<Id,list<Core_Attribute__c>>();
            Map<String,Core_Attribute__c> m1CoreAttrWithoutDupeMap = new  Map<String,Core_Attribute__c>();
            if(baseAssetIdSet.size()>0){
                Map<String, Set<Id>> setOfIdsMap = Utils.getCoreAttrIdsBasedOnAttrRequirement(plantAssetId);
                Set<Id> filteredAttributesId = setOfIdsMap.get(Constants.FILTERED);
                Set<Id> allAttributesId = setOfIdsMap.get(Constants.ALL);
                allCoreAttrLst = Utils.queryAllAttributes(baseAssetIdSet, allAttributesId);
                
                if(allCoreAttrLst.size()>0){     
                    // To form Map from List of core Attributes too the relevant BaseAssetId                    
                    for(Core_Attribute__c attrNameCheck: allCoreAttrLst){
                        if(filteredAttributesId.contains(attrNameCheck.Id)){
                            m1CoreAttrWithoutDupeMap.put(attrNameCheck.Attribute_Master__r.Name,attrNameCheck);
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
                coreAttributes = m1CoreAttrWithoutDupeMap.values();
            }

            if(currentSitemetadataCount >= Constants.RECORD_COUNT_FOR_EACH_PROMPT && currentPromptSiteMetadata.size()<=0){
                String parentPlantAssetPromptDetail;
                if(m1PromptSiteMetadata.size()>0){
                    parentPlantAssetPromptDetail = m1PromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
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
                    if(m1PromptSiteMetadata.size()>0){
                        parentPlantAssetPromptDetail = m1PromptSiteMetadata[0].Plant_Asset_Prompt_Detail__c;
                    }
                    Plant_Asset_Prompt_Detail__c plantAssetPromptCreateInstance = Utils.createPlantAssetPromptDetail(plantAssetId, currentPromptName, previousPromptName, parentPlantAssetPromptDetail);
                    insert plantAssetPromptCreateInstance;
    
                    list<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                    
                    //To create M2 Site Metadata Records based on the M1 Site Metadata Records
                    for(Site_Metadata__c m1PromptSpecificInfo: m1PromptSiteMetadata){
                        Map<String, String> promptSpecificInfoMapM2 = 
                            (Map<String, String>) System.JSON.deserialize(m1PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                             String stationName = promptSpecificInfoMapM2.get(Constants.STATION_NAME);
                        
                        if(buildNameWithM1PromptattrValueMap.containsKey(stationName)){
                            Map<String, Integer> promptAttributNameToCountMap = buildNameWithM1PromptattrValueMap.get(stationName);
                            
                            //To get the core attribute list based on baseasset Id in the m1PromptAttrNameBaseAssetIdMap
                            for(String m1PromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                Id baseAssetId;
                                if(m1PromptAttrNameBaseAssetIdMap.containsKey(m1PromptSpecificAttrName)){
                                    baseAssetId =m1PromptAttrNameBaseAssetIdMap.get(m1PromptSpecificAttrName); 
                                    if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                        coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                    }    
                                }   
                                Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                Integer value = promptAttributNameToCountMap.get(m1PromptSpecificAttrName);
                                
                                //Get the count based on the Prompt Specific Attributes with type met station sensor present in m1 Prompt 
                                for(integer i = 1; i<=value;i++){
                                    promptAttributeInfo.put(Constants.STATION_NAME,m1PromptSpecificInfo.Id);
                                    promptAttributeInfo.put(Constants.DEVICE_TYPE,m1PromptSpecificAttrName);
                                    String deviceName = stationName +'-'+m1PromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                    promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
    
                                    Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                String.valueOf(plantAssetPromptCreateInstance.Id), JSON.serialize(coreAttributeInfo),
                                                String.valueOf(m1PromptSpecificInfo.Id), baseAssetId, promptInfo.Id, deviceName);
                                    if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                        siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                        if(m1PromptSpecificInfo.Asset_Short_Name__c !=null){
                                            siteMetadata.Parent_Asset_Short_Name__c = m1PromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +m1PromptSpecificInfo.Asset_Short_Name__c;
                                        }else{
                                            siteMetadata.Parent_Asset_Short_Name__c = m1PromptSpecificInfo.Parent_Asset_Short_Name__c;
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
                } else if(isExecuteClear){
                    List<Site_Metadata__c> rowGenPromptSiteMetaData = Utils.querySiteMetadata(m1PromptName, plantAssetId);
                    Map<String,String> siteMetadataIdtoAttrMap = new  Map<String,String>();
                    for(Site_Metadata__c m1PromptSpecificInfo: rowGenPromptSiteMetaData){
                        Map<String, String> promptSpecificInfoMapM2 = 
                            (Map<String, String>) System.JSON.deserialize(m1PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                            siteMetadataIdtoAttrMap.put(m1PromptSpecificInfo.Id, promptSpecificInfoMapM2.get(Constants.STATION_NAME));
                    }
                    Map<String, Integer> currentSiteMetadataReadOnlyFieldValuesToCount = new Map<String, Integer>();
                    List<Site_Metadata__c> updatepromptSiteMetaData = new List<Site_Metadata__c>();
                    
                    for(Site_Metadata__c siteMetadata: currentPromptSiteMetadata) {
                        Map <String,String> currentPromptSpecificInfoMap =
                            (Map<String, String > ) System.JSON.deserialize(siteMetadata.Prompt_Specific_Info__c, Map < String, String > .class);
                        String StationNameId = currentPromptSpecificInfoMap.get(Constants.STATION_NAME);
                        String StationNameValue ='';
                        if(siteMetadataIdtoAttrMap.containsKey(StationNameId)){
                            StationNameValue = siteMetadataIdtoAttrMap.get(StationNameId);
                        }
                        String deviceTypeValue = currentPromptSpecificInfoMap.get(Constants.DEVICE_TYPE);
                        String readOnlyAttrValues =StationNameValue+deviceTypeValue;
                        if (!currentSiteMetadataReadOnlyFieldValuesToCount.containsKey(readOnlyAttrValues)) {
                            currentSiteMetadataReadOnlyFieldValuesToCount.put(readOnlyAttrValues, 0);
                        }
                        Integer count = integer.valueof(currentSiteMetadataReadOnlyFieldValuesToCount.get(readOnlyAttrValues));
                        Integer recordNameSequenceNo  = count + 1;
                        currentSiteMetadataReadOnlyFieldValuesToCount.put(readOnlyAttrValues, recordNameSequenceNo );
                        if (String.isBlank(currentPromptSpecificInfoMap.get(Constants.DEVICE_NAME))) {
                            String deviceNameAttrValue = StationNameValue +'-'+deviceTypeValue + ' ' +string.valueof(recordNameSequenceNo).leftPad(2, '0');
                            currentPromptSpecificInfoMap.put(Constants.DEVICE_NAME, deviceNameAttrValue);
                            siteMetadata.Prompt_Specific_Info__c = JSON.serialize(currentPromptSpecificInfoMap);
                            updatepromptSiteMetaData.add(siteMetadata);
                        }
                    }
                    
                    if(updatepromptSiteMetaData.size()>0){
                        update updatepromptSiteMetaData;
                    }
                } else if(currentPromptSiteMetadata.size() > 0) {
                    Set<String> StationNameIds = new Set<String>();
                    for(Site_Metadata__c siteMetaData : currentPromptSiteMetadata){
                        Map<String, String> w5aPromptAttrValueMap = 
                            (Map<String, String>) System.JSON.deserialize(siteMetaData.Prompt_Specific_Info__c,Map<String, String>.class);
                        StationNameIds.add(w5aPromptAttrValueMap.get(Constants.STATION_NAME));
                      }
                    //get the newly added M1 SiteMetadata records
                    List<Site_Metadata__c> m1NewSiteMetadataLst = [SELECT Id, Name, Attribute_Info__c, Base_Asset_Template__c, Account_Plant__c, Parent_Site_Metadata__r.Asset_Name__c,
                                Prompt_Specific_Info__c, Parent_Site_Metadata__c, Parent_Site_Metadata__r.Name, Previous_Prompt_Name__c, Plant_Asset_Prompt_Detail__c,
                                Parent_Site_Metadata__r.Alternate_Parent_Site_Metadata__r.Asset_Name__c, Alternate_Parent_Site_Metadata__c,Asset_Short_Name__c,Parent_Asset_Short_Name__c
                                FROM Site_Metadata__c 
                                WHERE Name =: m1PromptName AND Id NOT IN:StationNameIds
                                AND Account_Plant__c =: plantAssetId AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false];
                    
                   Map<String,Map<String,Integer>> currentBuildMap = new Map<String,Map<String,Integer>>();
                    for(String StationNameId: StationNameIds){
                        Map<String,Integer> attrMap = new  Map<String,Integer>();
                        for(Site_Metadata__c siteMetaData : currentPromptSiteMetadata){
                            Map<String, String> m2PromptAttrValueMap = 
                                (Map<String, String>) System.JSON.deserialize(siteMetaData.Prompt_Specific_Info__c,Map<String, String>.class);
                            if(m2PromptAttrValueMap.get(Constants.STATION_NAME) == StationNameId){
                                String attrName = m2PromptAttrValueMap.get(Constants.DEVICE_TYPE);
                                if(attrMap.containsKey(attrName)){
                                    Integer attCount = attrMap.get(attrName); 
                                    attrMap.put(attrName,attCount+1);
                                } else {
                                    attrMap.put(attrName, 1);
                                }
                            }
                         }
                        currentBuildMap.put(StationNameId,attrMap);
                      }
                     //To create M2 Site Metadata Records based on the M1 Site Metadata Records
                     List<Site_Metadata__c> siteMetadataCreation = new List<Site_Metadata__c>();
                    for(Site_Metadata__c m1PromptSpecificInfo: m1PromptSiteMetadata){
                        Map<String, String> promptSpecificInfoMapM1 = 
                            (Map<String, String>) System.JSON.deserialize(m1PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                             String stationName = promptSpecificInfoMapM1.get(Constants.STATION_NAME);
                         Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                        if(buildNameWithM1PromptattrValueMap.containsKey(stationName)){
                            Map<String,Integer> attributeMap = new  Map<String,Integer>();
                            Map<String, Integer> promptAttributNameToCountMap = buildNameWithM1PromptattrValueMap.get(stationName);
                            if(currentBuildMap.containsKey(m1PromptSpecificInfo.Id)){
                                attributeMap = currentBuildMap.get(m1PromptSpecificInfo.Id);
                            //To get the core attribute list based on baseasset Id in the m1PromptAttrNameBaseAssetIdMap
                            for(String m1PromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                Id baseAssetId;
                                if(m1PromptAttrNameBaseAssetIdMap.containsKey(m1PromptSpecificAttrName)){
                                    baseAssetId =m1PromptAttrNameBaseAssetIdMap.get(m1PromptSpecificAttrName); 
                                    if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                        coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                    }    
                                }   
                                Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                Integer newvalue = promptAttributNameToCountMap.get(m1PromptSpecificAttrName);
                                 
                                        Integer currentVal=0;
                                        Integer value =0;
                                        if(attributeMap.containsKey(m1PromptSpecificAttrName)){
                                             currentVal = attributeMap.get(m1PromptSpecificAttrName);
                                            if(newvalue > currentVal){
                                              value = (newvalue - currentVal);
                                            }
                                        } else{
                                             currentVal = 0;
                                             newvalue = promptAttributNameToCountMap.get(m1PromptSpecificAttrName);
                                        }
                                
                                //Get the count based on the Prompt Specific Attributes with type met station sensor present in m1 Prompt 
                                 for(integer i = currentVal+1; i<= newvalue; i++){
                                    promptAttributeInfo.put(Constants.STATION_NAME,m1PromptSpecificInfo.Id);
                                    promptAttributeInfo.put(Constants.DEVICE_TYPE,m1PromptSpecificAttrName);
                                    String deviceName = stationName +'-'+m1PromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                    promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
    
                                    Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                String.valueOf(plantAssetPromptDetail.Id), JSON.serialize(coreAttributeInfo),
                                                String.valueOf(m1PromptSpecificInfo.Id), baseAssetId, promptInfo.Id, deviceName);
                                    if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                        siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                        if(m1PromptSpecificInfo.Asset_Short_Name__c !=null){
                                            siteMetadata.Parent_Asset_Short_Name__c = m1PromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +m1PromptSpecificInfo.Asset_Short_Name__c;
                                        }else{
                                            siteMetadata.Parent_Asset_Short_Name__c = m1PromptSpecificInfo.Parent_Asset_Short_Name__c;
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
                    
                    if(m1NewSiteMetadataLst.size()>0){
                        list<Site_Metadata__c> newSiteMetadataCreation = new List<Site_Metadata__c>();
                        Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                        //To create M2 Site Metadata Records based on the M1 Site Metadata Records
                        for(Site_Metadata__c m1PromptSpecificInfo: m1NewSiteMetadataLst){
                            Map<String, String> promptSpecificInfoMapM2 = 
                                (Map<String, String>) System.JSON.deserialize(m1PromptSpecificInfo.Prompt_Specific_Info__c,Map<String, String>.class);
                                String stationName = promptSpecificInfoMapM2.get(Constants.STATION_NAME);
                            
                            if(buildNameWithM1PromptattrValueMap.containsKey(stationName)){
                                Map<String, Integer> promptAttributNameToCountMap = buildNameWithM1PromptattrValueMap.get(stationName);
                                
                                //To get the core attribute list based on baseasset Id in the m1PromptAttrNameBaseAssetIdMap
                                for(String m1PromptSpecificAttrName : promptAttributNameToCountMap.keyset()){
                                    Id baseAssetId;
                                    if(m1PromptAttrNameBaseAssetIdMap.containsKey(m1PromptSpecificAttrName)){
                                        baseAssetId =m1PromptAttrNameBaseAssetIdMap.get(m1PromptSpecificAttrName); 
                                        if(baseAssetIdwithCoreAttrLstMap.containsKey(baseAssetId)){    
                                            coreAttrLst = baseAssetIdwithCoreAttrLstMap.get(baseAssetId);
                                        }    
                                    }   
                                    Map<String,String> coreAttributeInfo = Utils.formAttributeNametoValueMap(coreAttrLst);
                                    Integer value = promptAttributNameToCountMap.get(m1PromptSpecificAttrName);
                                    
                                    //Get the count based on the Prompt Specific Attributes with type met station sensor present in m1 Prompt 
                                    for(integer i = 1; i<=value;i++){
                                        promptAttributeInfo.put(Constants.STATION_NAME,m1PromptSpecificInfo.Id);
                                        promptAttributeInfo.put(Constants.DEVICE_TYPE,m1PromptSpecificAttrName);
                                        String deviceName = stationName +'-'+m1PromptSpecificAttrName + ' ' +string.valueof(i).leftPad(2, '0');
                                        promptAttributeInfo.put(Constants.DEVICE_NAME,deviceName);
        
                                        Site_Metadata__c siteMetadata = Utils.createSiteMetaData(plantAssetId, currentPromptName, JSON.serialize(promptAttributeInfo),
                                                    String.valueOf(plantAssetPromptDetail.Id), JSON.serialize(coreAttributeInfo),
                                                    String.valueOf(m1PromptSpecificInfo.Id), baseAssetId, promptInfo.Id, deviceName);
                                        
                                        if(baseAssetIdtoRecord.containsKey(baseAssetId)){
                                            siteMetadata.Asset_Short_Name__c = baseAssetIdtoRecord.get(baseAssetId).Asset_Short_Name__c+string.valueof(i).leftPad(2, '0');
                                            if(m1PromptSpecificInfo.Asset_Short_Name__c !=null){
                                                siteMetadata.Parent_Asset_Short_Name__c = m1PromptSpecificInfo.Parent_Asset_Short_Name__c+ '\\' +m1PromptSpecificInfo.Asset_Short_Name__c;
                                            }else{
                                                siteMetadata.Parent_Asset_Short_Name__c = m1PromptSpecificInfo.Parent_Asset_Short_Name__c;
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
            //This condition is to get the next prompt response either to navigate to Next or Finish.
            if(isBulkUploadCheck || isBulkUploadCheckMultipleBAT){
                String nextPromptFinderResponse = Utils.nextPromptFinder(currentPromptName, plantAssetId);
                customDatatableCompInputsMap.put('nextPromptFinderResponse', nextPromptFinderResponse);
            }

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
        * On click of Next Button,
            a.  Saves the Current Site Metadata records, only if any changes occured in the prompt which is tracked by a boolean variable "attrValueChanged"
            b.  Based on the next available prompt attribute count, the nextPromptFinder method in the utils class navigates to the next prompt. 
        
        @param {Map<String,Object>} siteMetadataRecordsToSave - Holds the core attribute, prompt specific attribute, site metadata record, plant asset prompt detail record to save.
        @param {String} plantAssetId - Holds the PlantAsset Id which is passed from the previous prompt, for which the Site metadata record created.
        @param {Boolean} isKeyToGenerateRows - Any decrease in the prompt specific attribute in Parent prompt is tracked
        @param {Boolean} attrValueChanged - Any changes occured in the prompt which is tracked 
    */	
    @AuraEnabled
    public static String findNextPromptId(String plantAssetId,String siteMetadataRecordsToSave, Boolean isKeyToGenerateRows, 
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
                if(nextPromptId.length() <= 8 && additionalParamsMap.get('isReadOnly') == 'false'){
                    Utils.updateValidateOnPrevious(plantAssetId, currentPromptName);
                }
                Plant_Asset_Prompt_Detail__c plantAssetPromptDetail = Utils.queryPlantAssetPromptDetail(plantAssetId, currentPromptName);
                return Utils.nextPromptFinderResponse(plantAssetId,PromptNavigationHelper.findPromptId(currentPromptName), nextPromptId,
                    plantAssetPromptDetail.Id);
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
            
            List<String> retainValuesForPromptAttr = new List<String>{Constants.STATION_NAME,Constants.DEVICE_TYPE};
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