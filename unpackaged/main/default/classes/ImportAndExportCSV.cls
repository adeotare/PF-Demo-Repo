public with sharing class ImportAndExportCSV{
    /*
     *To load the prompt SiteMetadataRecords
     *@param1 plantAssetId
     *@param2 PromptInfo
    */
    @AuraEnabled
    public Static Map<String,String> getPromptSiteMetadataRecords(String plantAssetId, String promptInfo){
        Prompt_Information__c promptInfoRecord = (Prompt_Information__c)
                System.JSON.deserialize(promptInfo,Prompt_Information__c.class);
        String promptInfoId = promptInfoRecord.Id;
        Map<String, String> csvDataAndSiteMetadata = new Map<String, String>();
        Map<Id, Site_Metadata__c> IdToSiteMetadata = new Map<Id, Site_Metadata__c>(
            [SELECT id,Attribute_Info__c,Prompt_Specific_Info__c,Asset_Name__c  
            FROM Site_Metadata__c WHERE  Account_Plant__c =: plantAssetId AND Prompt_Information__c =: promptInfoId AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false]);
            if(IdToSiteMetadata.size() > 0)
            csvDataAndSiteMetadata.put('siteMetadata', JSON.serialize(IdToSiteMetadata));
        IdToSiteMetadata.clear();
        return csvDataAndSiteMetadata;
    }

    /*
     *To update the SiteMetadata records 
     *@param1 siteMetadataRecords (List of SiteMetadata records)
    */
    @AuraEnabled
    public static Boolean updateSiteMetadata(String siteMetadataRecords, Boolean isDelete, Boolean isLastBatch){
        Boolean result = false;
        List<Site_Metadata__c> siteMetadataList =  (List<Site_Metadata__c>) System.JSON.deserialize(siteMetadataRecords ,List<Site_Metadata__c>.class);
        for(Site_Metadata__c siteMetadata: siteMetadataList){
            String promptSpecificMap = siteMetadata.Prompt_Specific_Info__c;
            String attrSpecificMap = siteMetadata.Attribute_Info__c;
            attrSpecificMap = attrSpecificMap.replaceAll('"false"', 'false');
            attrSpecificMap = attrSpecificMap.replaceAll('"true"', 'true');
            attrSpecificMap = attrSpecificMap.replaceAll('"FALSE"', 'false');
            attrSpecificMap = attrSpecificMap.replaceAll('"TRUE"', 'true');
            promptSpecificMap = promptSpecificMap.replaceAll('"false"', 'false');
            promptSpecificMap = promptSpecificMap.replaceAll('"true"', 'true');
            promptSpecificMap = promptSpecificMap.replaceAll('"FALSE"', 'false');
            promptSpecificMap = promptSpecificMap.replaceAll('"TRUE"', 'true');
            siteMetadata.Prompt_Specific_Info__c = promptSpecificMap;
            siteMetadata.Attribute_Info__c = attrSpecificMap;
           }

        if(siteMetadataList.size() >0 ){
            update siteMetadataList;
            if(isDelete){
                List<Site_Metadata__c> siteMetadata = [SELECT Id,Plant_Asset_Prompt_Detail__r.Id, Plant_Asset_Prompt_Detail__r.Prompt_Information__r.Type__c from Site_Metadata__c where Id=: siteMetadataList[0].Id];
                Utils.plantAssetPromptDetailIsDeleteUpdate(
                        siteMetadata[0].Plant_Asset_Prompt_Detail__r.Id,
                        siteMetadata[0].Plant_Asset_Prompt_Detail__r.Prompt_Information__r.Type__c);
            }
                    
            result = true;
        }

        if(isLastBatch){
            Set<Id> alternateParentSiteMetadataRecordIdSet = new Set<Id>();
            List<Site_Metadata__c> siteMetadataRecordsToUpdate = new List<Site_Metadata__c>();
            List<Site_Metadata__c> siteMetadata = [SELECT Id, Name, Account_Plant__c from Site_Metadata__c where Id=: siteMetadataList[0].Id];
            siteMetadataRecordsToUpdate = Utils.querySiteMetadata(siteMetadata[0].Name, siteMetadata[0].Account_Plant__c);
            for(Site_Metadata__c sitemetadataSo : siteMetadataRecordsToUpdate){
                alternateParentSiteMetadataRecordIdSet.add(sitemetadataSo.Alternate_Parent_Site_Metadata__c);
            }
            
            if(siteMetadataRecordsToUpdate.size()>0){
                result = Utils.saveParentNameInSiteMetadataRecords(alternateParentSiteMetadataRecordIdSet, siteMetadataRecordsToUpdate, true);
            }
        }
        return result;  
    }
    
    @AuraEnabled
    public static Map<String,Object> getCSVInputsMap(
    List<Attribute_Master__c> attrLst,
    List<Site_Metadata__c> siteMetadataLst,
    list<Core_Attribute__c> assetNameAttr,
    list<Core_Attribute__c> parentAssetNameAttr,
    list<Core_Attribute__c> allCoreAttrLst){
        Map<String,Object> csvInputsMap = new Map<String,Object>();
        csvInputsMap.put('Attributes', attrLst);
        csvInputsMap.put('SiteMetadataRecords', siteMetadataLst);
        csvInputsMap.put('AssetNameAttr', assetNameAttr);
        csvInputsMap.put('ParentAssetAttrName', parentAssetNameAttr);
        csvInputsMap.put('allCoreAttrLst',allCoreAttrLst);
        return csvInputsMap;
    }

    @AuraEnabled
    public static String getPlantAssetDetail(String plantAssetId){
       List<Account_Plant__c> plantasset = [Select Customer_Plant_Asset_ID__c from Account_Plant__c where Id = :plantAssetId];
      return  plantasset[0].Customer_Plant_Asset_ID__c;
    }
}