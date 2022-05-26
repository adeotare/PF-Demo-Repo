public with sharing class WeightedAverageRollUpModalPopUp {
    public static String g1PromptName = Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT ;
    public static String p1PromptName = Constants.P1_PLANT_INFO_PROMPT_SOLAR;
    public static String w1PromptName = Constants.W1_PLANT_INFO_PROMPT_WIND;
    
    @AuraEnabled
    public static String getCustomDatatableCompInput(String plantAssetId, String jsonInputParametersAndValues){
        String renewableType = '';
        List<Site_Metadata__c> g1SiteMetadataSOS = Utils.querySiteMetadata(g1PromptName, plantAssetId);
        List<Core_Attribute__c> weightedAverageRollupAttributesLst = new list<Core_Attribute__c>();
        list<Core_Attribute__c> filteredWeightedAverageAttributeLst = new List<Core_Attribute__c>();
        list<Core_Attribute__c> promptSpecificAttributeLst = new List<Core_Attribute__c>();
        Map<String, Object> dataTableInputMap = new Map<String, Object>();

        if(g1SiteMetadataSOS.size() > 0){
            for(site_metadata__c g1SiteMetadataSo : g1SiteMetadataSOS){
                Map<String, String> promptSpecificInfoMap = 
                                (Map<String, String>) System.JSON.deserialize(g1SiteMetadataSo.Prompt_Specific_Info__c,Map<String, String>.class);
                if(promptSpecificInfoMap.containsKey(Constants.RENEWABLE_TYPE)){        
                    if(!String.isBlank(promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE))){
                        renewableType = promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE);  
                    }
                }
            }
        }
        
        Account_Plant__c plantAssetRecord = [SELECT Id, TEM_Version__c FROM Account_Plant__c WHERE Id =: plantAssetId];

        if(renewableType == Constants.SOLAR){
            weightedAverageRollupAttributesLst = [SELECT Id, Attribute_Master__r.Name, Base_Attribute_For_Weighted_Average_Calc__c,
                Attribute_Master__r.Type__c, Attribute_Master__c,
                TEM_Version__c, Rollup_To_Parent__r.Type__c, Is_Rollup_To_P1_W1__c   
                FROM Core_Attribute__c 
                WHERE Rollup_To_Parent__r.Type__c =: Constants.SOLAR
                    AND Is_Rollup_To_P1_W1__c = true 
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Metadata'
                    AND Base_Attribute_For_Weighted_Average_Calc__c != NULL
                    AND TEM_Version__c =: plantAssetRecord.TEM_Version__c];
            
            if(weightedAverageRollupAttributesLst.size() > 0){
                set<Id> attributeMasterSet = new Set<Id>();
                for(Core_Attribute__c attributeSo : weightedAverageRollupAttributesLst){
                    attributeMasterSet.add(attributeSo.Attribute_Master__c);   
                }

                if(attributeMasterSet.size() > 0){
                    filteredWeightedAverageAttributeLst = [SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c,Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, Attribute_Master__r.UI_Column_Size__c   
                    FROM Core_Attribute__c 
                    WHERE Base_Asset_Name__r.Name =: Constants.BASE_PV_PLANT 
                        AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                        AND Attribute_Master__r.Type__c = 'Metadata'
                        AND Attribute_Master__c IN: attributeMasterSet
                    ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name];
                }

                if(filteredWeightedAverageAttributeLst.size() > 0){
                    String dataTableInput = P1PlantInfoPromptSolar.getCustomDatatableCompInput(plantAssetId ,'', jsonInputParametersAndValues);
                    dataTableInputMap = (Map<String, Object>)JSON.deserializeUntyped(dataTableInput);
                    dataTableInputMap.remove('CoreAttributes');
                    dataTableInputMap.remove('PromptSpecificAttributes');
                    dataTableInputMap.put('PromptSpecificAttributes', promptSpecificAttributeLst);
                    dataTableInputMap.put('CoreAttributes', filteredWeightedAverageAttributeLst);
                }
            }
        }else if(renewableType == Constants.WIND){
            weightedAverageRollupAttributesLst = [SELECT Id, Attribute_Master__r.Name, Base_Attribute_For_Weighted_Average_Calc__c,
                Attribute_Master__r.Type__c, Attribute_Master__c,
                TEM_Version__c, Rollup_To_Parent__r.Type__c, Is_Rollup_To_P1_W1__c   
                FROM Core_Attribute__c 
                WHERE Rollup_To_Parent__r.Type__c =: Constants.WIND
                    AND Is_Rollup_To_P1_W1__c = true 
                    AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                    AND Attribute_Master__r.Type__c = 'Metadata'
                    AND Base_Attribute_For_Weighted_Average_Calc__c != NULL
                    AND TEM_Version__c =: plantAssetRecord.TEM_Version__c];
            
            if(weightedAverageRollupAttributesLst.size() > 0){
                set<Id> attributeMasterSet = new Set<Id>();
                for(Core_Attribute__c attributeSo : weightedAverageRollupAttributesLst){
                    attributeMasterSet.add(attributeSo.Attribute_Master__c);   
                }

                if(attributeMasterSet.size() > 0){
                    filteredWeightedAverageAttributeLst = [SELECT Id, Attribute_Master__r.Name, Attribute_Master__r.Data_Type__c, Attribute_Master__r.Type__c, Attribute_Master__r.Picklist_Master__c, Attribute_Master__r.Alias__c, RecordtypeId, Picklist_Dependency1__c,
                    Base_Asset_Name__c, Prompt_Information__c,Is_Unique__c, Picklist_Dependency1__r.Name, Is_Read_Only__c,
                    Plant_Asset_Field_Name__c, Is_Parent_Asset__c, Show_Alternate_Parent_in_Prompt__c,
                    Customer_Facing_Notes__c, Attribute_Master__r.Customer_Facing_Notes__c, Required__c,
                    Attribute_Master__r.Units__c, Key_Field_To_Generate_Rows__c, Attribute_Master__r.UI_Column_Size__c   
                    FROM Core_Attribute__c 
                    WHERE Base_Asset_Name__r.Name =: Constants.BASE_WIND_PLANT 
                        AND RecordTypeId =: Utils.getRecordTypeInfo('Core_Attribute__c', ConstantsRecordTypes.CORE_ATTRIBUTE_CORE_ATTRIBUTE).getRecordTypeId()
                        AND Attribute_Master__r.Type__c = 'Metadata'
                        AND Attribute_Master__c IN: attributeMasterSet
                    ORDER BY Sorting_Order__c ASC NULLS last, Attribute_Master__r.Name];
                }

                if(filteredWeightedAverageAttributeLst.size() > 0 && !Test.isRunningtest()){
                    String dataTableInput = W1PlantInfo.getCustomDatatableCompInput(plantAssetId ,'', jsonInputParametersAndValues);
                    dataTableInputMap = (Map<String, Object>)JSON.deserializeUntyped(dataTableInput);
                    dataTableInputMap.remove('CoreAttributes');
                    dataTableInputMap.remove('PromptSpecificAttributes');
                    dataTableInputMap.put('PromptSpecificAttributes', promptSpecificAttributeLst);
                    dataTableInputMap.put('CoreAttributes', filteredWeightedAverageAttributeLst);
                }
            }
        }

        if(dataTableInputMap.size() > 0){
            return JSON.serialize(dataTableInputMap);
        }else{
            return 'call Finish Popup';
        }
    }

    @AuraEnabled
    public static Boolean saveSiteMetadataRecords(String siteMetadataRecordsToSave){
        List<Site_Metadata__c> siteMetadataRecordsToUpdate = new List<Site_Metadata__c>();
        if(!String.isBlank(siteMetadataRecordsToSave)){
            for(Site_Metadata__c sitemetadata : (List<Site_Metadata__c>)
                    System.JSON.deserialize(siteMetadataRecordsToSave,List<Site_Metadata__c>.class)){
                siteMetadataRecordsToUpdate.add(sitemetadata);
            }

            if(siteMetadataRecordsToUpdate.size()>0){
                update siteMetadataRecordsToUpdate;
            }
        }
        return true;
    }

    @AuraEnabled
    public static String plantAssetDetails(String plantAssetId){
        String result = '';
        String renewableType = '';
        List<Site_Metadata__c> g1SiteMetadataSOS = Utils.querySiteMetadata(g1PromptName, plantAssetId);
        Account_Plant__c plantAssetDetails = [SELECT Id, Name, Asset_Builder_Status__c, AB_Approval_Status__c 
            FROM Account_Plant__c
            WHERE Id =: plantAssetId];
        
        List<Plant_Asset_Prompt_Detail__c> plantAssetPromptDetailSOS = [SELECT id,Is_WA_RollUp_Not_Executed__c
            FROM Plant_Asset_Prompt_Detail__c
            WHERE Account_Plant__c =: plantAssetId AND 
            Prompt_Information__r.Name=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT AND 
            Is_Deleted__c = FALSE LIMIT 1];
        
        if(plantAssetDetails.AB_Approval_Status__c == null || plantAssetDetails.AB_Approval_Status__c == 'Rejected'){
            if(plantAssetDetails.Asset_Builder_Status__c == Constants.COMPLETED){
            
                if(g1SiteMetadataSOS.size() > 0){
                    for(site_metadata__c g1SiteMetadataSo : g1SiteMetadataSOS){
                        Map<String, String> promptSpecificInfoMap = 
                                        (Map<String, String>) System.JSON.deserialize(g1SiteMetadataSo.Prompt_Specific_Info__c,Map<String, String>.class);
                        if(promptSpecificInfoMap.containsKey(Constants.RENEWABLE_TYPE)){        
                            if(!String.isBlank(promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE))){
                                renewableType = promptSpecificInfoMap.get(Constants.RENEWABLE_TYPE);  
                            }
                        }
                    }
                }
            }
    
            if(plantAssetPromptDetailSOS.size() > 0){
                if(plantAssetDetails.Asset_Builder_Status__c == Constants.COMPLETED && renewableType == Constants.SOLAR
                    && plantAssetPromptDetailSOS[0].Is_WA_RollUp_Not_Executed__c){
                    result = 'weighted Average Not calculated';
                }else if(plantAssetDetails.Asset_Builder_Status__c == Constants.COMPLETED && renewableType == Constants.SOLAR
                    && !plantAssetPromptDetailSOS[0].Is_WA_RollUp_Not_Executed__c){
                    result = 'open Modal Popup';
                }else if(plantAssetDetails.Asset_Builder_Status__c == Constants.COMPLETED && renewableType == Constants.WIND){
                    result = 'rollup is for Solar Prompts';
                }else{
                    result = plantAssetDetails.Asset_Builder_Status__c;
                }
            }
        }else{
            result = 'Read Only Prompts';
        }
        return result;
    }
}