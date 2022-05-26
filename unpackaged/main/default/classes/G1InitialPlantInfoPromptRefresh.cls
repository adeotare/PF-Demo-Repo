/**
**/
public with sharing class G1InitialPlantInfoPromptRefresh {

    //To check Asset Builder status of the plant asset  
    @AuraEnabled
    public static Boolean checkABStatusOfPlantAsset(String plantAssetId){
        List<String> allowedABStatusForRefreshList = new List<String>();
        for(AB_ABStatusToAllowG1Refresh__mdt allowedABStatusForRefresh : [SELECT Label FROM AB_ABStatusToAllowG1Refresh__mdt]){
            allowedABStatusForRefreshList.add(allowedABStatusForRefresh.Label);
        }
        Account_Plant__c plantAssetABStatus = [SELECT Asset_Builder_Status__C FROM Account_Plant__c WHERE Id =:plantAssetId];
        return allowedABStatusForRefreshList.contains(plantAssetABStatus.Asset_Builder_Status__C) ? true : false;
    }
    
    /*
    * To update the G1 sitemeta data with new prompt specific and renewable type values 
        * If any Prompt specific value is removed, update plant asset prompt detail and asset builder data Is deleted to true
        * If any renewable type value(Solar PV) is removed, update plant asset prompt detail and asset builder data of removed type(Solar PV) Is deleted to true
          and the same for Wind
        * If any new Value is added (Prompt specific or Renewable Type), update only G1 Site Meta data.
    * To update attribute info of P1, W1 sitemeta data with plant asset core attribute values if P1, W1 sitemeta data are available
    */
    @AuraEnabled
    public static Boolean refreshG1SiteMetaData(String plantAssetId){
        try{
            List<Site_Metadata__c> G1SiteMetaDataList = new List<Site_Metadata__c>();
            List<String> plantAssetPFSrvPdtFilteredList = new List<String>();
            List<String>  plantAssetRenewableTypeFilteredList = new List<String>();
            List<String> G1PFSrvPdtFilteredList = new List<String>();
            List<String> G1RenewableTypeFilteredList = new List<String>();
            List<String> pfServiceProductDesiredList = new List<String>{Constants.DRIVE, Constants.FSM};
            List<String> renewableTypeDesiredList = new List<String>{Constants.SOLAR, Constants.WIND, Constants.WIND_OFFSHORE};
            List<String> emptyStringList = new List<String>();
            Boolean isUpdateG1SiteMetadata = false;
            Boolean result = true;
            
            Account_Plant__c plantAssetSO = [SELECT PF_Service_Product__c, Renewable_Type__c FROM Account_Plant__c WHERE Id =: plantAssetId ]; 
            
            String plantAssetPFSrvPdt = plantAssetSO.PF_Service_Product__c;
            if(plantAssetPFSrvPdt != null)
                plantAssetPFSrvPdtFilteredList = getFilteredPickListValues(plantAssetPFSrvPdt.split(';'), pfServiceProductDesiredList);
        
            String plantAssetRenewableType = plantAssetSO.Renewable_Type__c;
            if(plantAssetRenewableType != null)            
                plantAssetRenewableTypeFilteredList = getFilteredPickListValues(plantAssetRenewableType.split(';'), renewableTypeDesiredList);
            
            G1SiteMetaDataList = [SELECT Prompt_Specific_Info__c FROM Site_Metadata__c WHERE Account_Plant__c =: plantAssetId 
                                  AND Prompt_Information__r.Name =: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT
                                  AND Plant_Asset_Prompt_Detail__r.Is_Deleted__C = false];

            Map<String,String> G1PromptSpecificInfoMap = (Map<String,String>)JSON.deserialize(G1SiteMetaDataList[0].Prompt_Specific_Info__c, Map<String,String>.class);  
                
            String G1PFSrvPdt = G1PromptSpecificInfoMap.get('PF Service Product');
            if(G1PFSrvPdt != '')
                G1PFSrvPdtFilteredList = getFilteredPickListValues(G1PFSrvPdt.split(';'), pfServiceProductDesiredList);
                
            String G1RenewableType = G1PromptSpecificInfoMap.get('Renewable Type');
            if( G1RenewableType != '')
                G1RenewableTypeFilteredList = getFilteredPickListValues(G1RenewableType.split(';'), renewableTypeDesiredList);

            Map<String,List<String>> pfSrvPdtAddedRemovedAndExistingValues = getAddedRemovedAndExistingPickListValues(plantAssetPFSrvPdtFilteredList,G1PFSrvPdtFilteredList);
            List<String> addedPFSrvPdtValues = pfSrvPdtAddedRemovedAndExistingValues.get('addedValues');
            List<String> removedPFSrvPdtValues = pfSrvPdtAddedRemovedAndExistingValues.get('removedValues');

            Map<String,List<String>> renewableTypeAddedRemovedAndExistingValues = getAddedRemovedAndExistingPickListValues(plantAssetRenewableTypeFilteredList,G1RenewableTypeFilteredList);
            List<String> existingRenewableTypeValues = renewableTypeAddedRemovedAndExistingValues.get('existingValues');

            if(G1PFSrvPdtFilteredList.size() == 0){
                if(addedPFSrvPdtValues.size() == pfServiceProductDesiredList.size()){
                    //check and update for changes in Renewable Type and update G1 Site Metadata with new prompt specific info           
                     updateRenewableTypeChanges(renewableTypeAddedRemovedAndExistingValues, G1RenewableTypeFilteredList, plantAssetId, renewableTypeDesiredList);
                     isUpdateG1SiteMetadata = true;                        
                }else if (addedPFSrvPdtValues.size() > 0 && addedPFSrvPdtValues.size() < pfServiceProductDesiredList.size()){
                    //update All PAPD and ABRD Is deleted to true and update G1 Site Metadata with new prompt specific info                     
                    updateABDataBasedOnPromptType(plantAssetId, emptyStringList, true);//Null(Drive, FSM considered by default) to 1 , Hence deleting  
                    isUpdateG1SiteMetadata = true;                       
                }else{                        
                    //check and update for changes in Renewable type
                    isUpdateG1SiteMetadata = updateRenewableTypeChanges(renewableTypeAddedRemovedAndExistingValues, G1RenewableTypeFilteredList, plantAssetId, renewableTypeDesiredList);
                }
            }
                                
            if (G1PFSrvPdtFilteredList.size() > 0 && G1PFSrvPdtFilteredList.size() != pfServiceProductDesiredList.size()) {
                if(removedPFSrvPdtValues.size() > 0){
                    updateABDataBasedOnPromptType(plantAssetId, emptyStringList, true);
                    isUpdateG1SiteMetadata = true;
                }
                if(addedPFSrvPdtValues.size() > 0 && removedPFSrvPdtValues.size() == 0){
                    updateRenewableTypeChanges(renewableTypeAddedRemovedAndExistingValues, G1RenewableTypeFilteredList, plantAssetId, renewableTypeDesiredList);
                    isUpdateG1SiteMetadata = true;
                }                        
                if(addedPFSrvPdtValues.size() == 0 && removedPFSrvPdtValues.size() == 0){
                    //check and update for changes in Renewable type
                     //update G1 Site meta data with new prompt specific info based on result from changes in renewable type
                     isUpdateG1SiteMetadata = updateRenewableTypeChanges(renewableTypeAddedRemovedAndExistingValues, G1RenewableTypeFilteredList, plantAssetId, renewableTypeDesiredList);
                }
            }
                                
            if(G1PFSrvPdtFilteredList.size() == pfServiceProductDesiredList.size()){
                if(removedPFSrvPdtValues.size() == pfServiceProductDesiredList.size()){
                    //check and update for changes in Renewable type, because PF Service Product is null and all selected are same
                    updateRenewableTypeChanges(renewableTypeAddedRemovedAndExistingValues, G1RenewableTypeFilteredList, plantAssetId, renewableTypeDesiredList);
                    //update G1 Site meta data with new prompt specific info based on result from changes in renewable type
                    isUpdateG1SiteMetadata = true;
                }
                if(removedPFSrvPdtValues.size() > 0 && removedPFSrvPdtValues.size() != pfServiceProductDesiredList.size()){
                    //update All PAPD and ABRD Is deleted to true and update G1 Site Metadata with new prompt specific info   
                    updateABDataBasedOnPromptType(plantAssetId, emptyStringList, true);     
                    isUpdateG1SiteMetadata = true;                 
                }
                if(removedPFSrvPdtValues.size() == 0){
                    //check and update for changes in Renewable type
                    //update G1 Site meta data with new prompt specific info based on result from changes in renewable type
                    isUpdateG1SiteMetadata = updateRenewableTypeChanges(renewableTypeAddedRemovedAndExistingValues, G1RenewableTypeFilteredList, plantAssetId, renewableTypeDesiredList);                   
                }
            }

            //Updating Core Attribute values from plant asset to P1, w1 Sitemeta data
            List<Site_Metadata__c> siteMetaDataForUpdate = new List<Site_Metadata__c>();
            if(existingRenewableTypeValues.contains(Constants.SOLAR)){
                List<Site_Metadata__c> p1SiteMetaDataLst = [SELECT Id, Base_Asset_Template__c, Attribute_Info__c  FROM Site_Metadata__c WHERE Account_Plant__c =: plantAssetId 
                                                            AND Prompt_Information__r.Name =: Constants.P1_PLANT_INFO_PROMPT_SOLAR
                                                            AND Plant_Asset_Prompt_Detail__r.Is_Deleted__C = false];
                if(p1SiteMetaDataLst.size() > 0){
                    String baseAssetId = p1SiteMetaDataLst[0].Base_Asset_Template__c;
                    String attributeInfo = p1SiteMetaDataLst[0].Attribute_Info__c;
                    String attributeInfoUpdated = formAttrInfoJSONForP1W1SiteMetadata(baseAssetId, attributeInfo, plantAssetId);
                    if(attributeInfoUpdated != 'NoData')
                        siteMetaDataForUpdate.add(new Site_Metadata__c (Id = p1SiteMetaDataLst[0].Id , Attribute_Info__c = attributeInfoUpdated));
                }              
            }

            if(existingRenewableTypeValues.contains(Constants.WIND)){
                List<Site_Metadata__c> w1SiteMetaDataLst = [SELECT Id, Base_Asset_Template__c, Attribute_Info__c  FROM Site_Metadata__c WHERE Account_Plant__c =: plantAssetId 
                                                            AND Prompt_Information__r.Name =: Constants.W1_PLANT_INFO_PROMPT_WIND
                                                            AND Plant_Asset_Prompt_Detail__r.Is_Deleted__C = false];
                                                                
                if(w1SiteMetaDataLst.size() > 0){
                    String baseAssetId = w1SiteMetaDataLst[0].Base_Asset_Template__c;
                    String attributeInfo = w1SiteMetaDataLst[0].Attribute_Info__c;
                    String attributeInfoUpdated = formAttrInfoJSONForP1W1SiteMetadata(baseAssetId, attributeInfo, plantAssetId);
                    if(attributeInfoUpdated != 'NoData')
                        siteMetaDataForUpdate.add(new Site_Metadata__c (Id = w1SiteMetaDataLst[0].Id , Attribute_Info__c = attributeInfoUpdated));
                }
            }

            //Update G1 Site Metadata
            if(isUpdateG1SiteMetadata){
                if(plantAssetPFSrvPdt == null)
                    plantAssetPFSrvPdt = '';
                if(plantAssetRenewableType == null)
                    plantAssetRenewableType = '';
                G1PromptSpecificInfoMap.put('PF Service Product',plantAssetPFSrvPdt);
                G1PromptSpecificInfoMap.put('Renewable Type', plantAssetRenewableType);
                G1SiteMetaDataList[0].Prompt_Specific_Info__c = JSON.serialize(G1PromptSpecificInfoMap);
                update G1SiteMetaDataList;
            }

            // Updating P1, W1 Site Meta data together
            if(siteMetaDataForUpdate.size() > 0)
                StaticVariableForAssetBuilderUtils.platformEventLastProcessedDatetime = System.now(); 
                update siteMetaDataForUpdate; 

            return result;
        }catch(Exception exceptionDetails){
            String errorMessage = 'Please Contact Administrator '+ exceptionDetails.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    }
    
    public static Boolean updateRenewableTypeChanges(Map<String,List<String>> renewableTypeAddedRemovedAndExistingValues, List<String> G1RenewableTypeFilteredList, String plantAssetId, List<String> renewableTypeDesiredList){
        List<String> addedRenewableTypeValues = renewableTypeAddedRemovedAndExistingValues.get('addedValues');
        List<String> removedRenewableTypeValues = renewableTypeAddedRemovedAndExistingValues.get('removedValues');
        Boolean result = false;

        if(G1RenewableTypeFilteredList.size() == 0){
            if(addedRenewableTypeValues.size() > 0){
                result = true; //only update G1
            }else{
                result = false;//No Change
            }
        }
        
        if((G1RenewableTypeFilteredList.size() != renewableTypeDesiredList.size()) && G1RenewableTypeFilteredList.size() > 0){
            if(removedRenewableTypeValues.size() > 0){
                updateABDataBasedOnPromptType(plantAssetId, removedRenewableTypeValues, false);
                result = true;
            }

            if(addedRenewableTypeValues.size() > 0)
                result = true;

            if(removedRenewableTypeValues.size() == 0 && addedRenewableTypeValues.size() == 0)
                result = false;
        }
        
        if(G1RenewableTypeFilteredList.size() == renewableTypeDesiredList.size()){
            if(addedRenewableTypeValues.size() == 0 && removedRenewableTypeValues.size() == 0){                
                result = false;//No change, no need to update G1 from RT
            }else if(removedRenewableTypeValues.size() > 0){                 
                updateABDataBasedOnPromptType(plantAssetId, removedRenewableTypeValues, false);//delete solar or Wind or Both prompt data
                result = true;
            }
        }
        return result;
    }   
  
    public static void updateABDataBasedOnPromptType(String plantAssetId, List<String> promptTypeList, Boolean isAll){
        Account_Plant__c plantAssetSO = new Account_Plant__c();
        if(promptTypeList.size() > 0){
            plantAssetSO =  [SELECT TEM_Version__c,(SELECT Id FROM Plant_Asset_Prompt_Details__r WHERE Is_Deleted__c = false AND Prompt_Information__r.Type__c IN :promptTypeList),  
                             (SELECT Id FROM Asset_Builder_Report_Data__r WHERE Is_Archived__c = false AND Prompt_Information__r.Type__c IN :promptTypeList) 
                             FROM Account_Plant__c WHERE Id =: plantAssetId];  
        }
        else if(isAll){   
            plantAssetSO =  [SELECT TEM_Version__c,(SELECT Id FROM Plant_Asset_Prompt_Details__r 
                             WHERE Is_Deleted__c = false AND Prompt_Information__r.Name !=: Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT),  
                             (SELECT Id FROM Asset_Builder_Report_Data__r WHERE Is_Archived__c = false) 
                             FROM Account_Plant__c WHERE Id =: plantAssetId];                               
        }
        //To update Plant Asset Prompt details Is deleted to true
        if(plantAssetSO.Plant_Asset_Prompt_Details__r.size()>0){
            List<Plant_Asset_Prompt_Detail__c> plantAssetPromptDetailUpdateList = new List<Plant_Asset_Prompt_Detail__c>();
            for (Plant_Asset_Prompt_Detail__c plantAssetPromptDetailSO : plantAssetSO.Plant_Asset_Prompt_Details__r) {
                plantAssetPromptDetailSO.Is_Deleted__c = true;
                plantAssetPromptDetailUpdateList.add(PlantAssetPromptDetailSO);
            }
            update plantAssetPromptDetailUpdateList;
        }
        
        //To update Asset Builder Report Data Is Archived to true
        if(plantAssetSO.Asset_Builder_Report_Data__r.size()>0){
            List<Asset_Builder_Report_Data__c> assetBuilderReportDataUpdateList = new List<Asset_Builder_Report_Data__c>();            
            for(Asset_Builder_Report_Data__c assetBuilderReportDataSO : plantAssetSO.Asset_Builder_Report_Data__r){
                assetBuilderReportDataSO.Is_Archived__c = true;
                assetBuilderReportDataUpdateList.add(assetBuilderReportDataSO);
            }
            update assetBuilderReportDataUpdateList;
        }      
    }
    
    //To get the added and removed values in G1 Prompt Specific Site Metadata by comparing Plant Asset picklist values
    public static Map<String,List<String>> getAddedRemovedAndExistingPickListValues(List<String> plantAssetNewPickListValues, List<String> G1ExistingPickListValues){
        List<String> addedValues = new List<String>();
        List<String> removedValues = new List<String>();
        List<String> existingValues = new List<String>();
        Map<String,List<String>> result = new Map<String, List<String>>();
        
        for(String newPickListValue : plantAssetNewPickListValues){
            if(!G1ExistingPickListValues.contains(newPickListValue)){
                addedValues.add(newPickListValue);
            }
        }

        for(String G1ExistingPickListValue : G1ExistingPickListValues){
            if(!plantAssetNewPickListValues.contains(G1ExistingPickListValue)){
                removedValues.add(G1ExistingPickListValue);
            }else{
                existingValues.add(G1ExistingPickListValue);
            }
        }
        result.put('addedValues',addedValues);
        result.put('removedValues', removedValues);
        result.put('existingValues', existingValues);
        return result;
    }
    
    
    // To filter desired picklist values (Solar PV, Wind)from the all picklist values
    public static List<String> getFilteredPickListValues(List<String> allPickListValues, List<String> desiredValues){
        List<String> filteredPickListValues = new List<String>();
        for(String pickListValue : allPickListValues){
            if(desiredValues.contains(pickListValue)){
                filteredPickListValues.add(pickListValue);
            }
        }
        return filteredPickListValues;
    }

    //To form attribute Info JSON to update P1 and W1 sitemeta data
    public static String formAttrInfoJSONForP1W1SiteMetadata(String baseAssetId, String attributeInfo, String plantAssetId){
        List<String> queryStringList = new List<String>();
        List<Core_Attribute__c> coreAttributes = new List<Core_Attribute__c>();
        Map<String,String> attributeInfoMap = new  Map<String,String>();
        String result = 'NoData';

        coreAttributes = [SELECT Name, Plant_Asset_Field_Name__c FROM Core_Attribute__c 
                            WHERE Base_Asset_Name__c =: baseAssetId AND Plant_Asset_Field_Name__c != null];

        if(coreAttributes.size() > 0){
            attributeInfoMap = (Map<String,String>)JSON.deserialize(attributeInfo, Map<String,String>.class); 

            for(Core_Attribute__c coreAttribute : coreAttributes){
                queryStringList.add(coreAttribute.Plant_Asset_Field_Name__c);
            }

            String dynamicQueryString = 'SELECT Id, '+ String.join(queryStringList, ', ') + ' FROM Account_Plant__c WHERE Id =: plantAssetId';
            Account_Plant__c plantAssetSO = Database.query(dynamicQueryString);

            for(Core_Attribute__c coreAttribute : coreAttributes){
                if(attributeInfoMap.containsKey(coreAttribute.Name)){
                    String attrValue = String.valueOf(plantAssetSO.get(coreAttribute.Plant_Asset_Field_Name__c));
                    if(attrValue == null)
                        attrValue = '';
                    attributeInfoMap.put(coreAttribute.Name, attrValue);
                }
            }        
            result = JSON.serialize(attributeInfoMap);
        }
        return result;
    }
}