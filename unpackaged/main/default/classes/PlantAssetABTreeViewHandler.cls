public with sharing class PlantAssetABTreeViewHandler {

    @AuraEnabled
    public static String formTreeView(String plantAssetId){
        String result;
        List<String> assetShortNameEmptyPrompts = new List<String>{Constants.P10A_OTHER_ASSET_BUILD , Constants.W3_TURBINE_BUILD};
        List<Site_Metadata__c> siteMetadataSOs = [SELECT Id, Asset_Name__c, Asset_Short_Name__c , Parent_Site_Metadata__c, Alternate_Parent_Site_Metadata__c, Prompt_Information__r.Name, Account_Plant__r.Name
                                                    FROM Site_Metadata__c WHERE Account_Plant__c =: plantAssetId
                                                    AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false
                                                    AND Prompt_Information__r.Name NOT IN : assetShortNameEmptyPrompts 
                                                    ORDER BY Prompt_Information__r.Compiled_Excel_Sorting_Order__c, Asset_Name__c ASC];
        if(siteMetadataSOs.size() > 0){
            Map<String, List<Id>> promptNameAndRecordIdsMap = new Map<String, List<Id>>();
            Map<Id,SiteMetadataWrapper> siteMetadataWrapperMap = new Map<Id,SiteMetadataWrapper>();
    
            /*
                * To create PromptName and its related site metadata Ids Map
                * To create SiteMetadataWrapperMap with site metadata Id as Key and wrapper (empty items) has its value 
            */
            for (Site_Metadata__c siteMetadataSO : siteMetadataSOs) {
                String promptName = siteMetadataSO.Prompt_Information__r.Name;
                if(!promptNameAndRecordIdsMap.containsKey(promptName)){
                    promptNameAndRecordIdsMap.put(promptName, new List<Id>());
                }
                promptNameAndRecordIdsMap.get(promptName).add(siteMetadataSO.Id);
    
                SiteMetadataWrapper siteMetadataWrapperSO = new SiteMetadataWrapper();
                siteMetadataWrapperSO.Id = siteMetadataSO.Id;
                siteMetadataWrapperSO.label = siteMetadataSO.Asset_Short_Name__c + ' - '+ siteMetadataSO.Asset_Name__c;
                siteMetadataWrapperSO.promptName = siteMetadataSO.Prompt_Information__r.Name;
                siteMetadataWrapperSO.items = new List<SiteMetadataWrapper>();
                siteMetadataWrapperMap.put(siteMetadataSO.Id, siteMetadataWrapperSO);
            }
    
            //To add the site metadata wrapper into the alternate parent if exists or parent site metadata items list
            String ParentOrAltParentId;
            for(Site_Metadata__c siteMetadataSO : siteMetadataSOs){
                if(siteMetadataWrapperMap.containsKey(siteMetadataSO.Parent_Site_Metadata__c)){
                    SiteMetadataWrapper siteMetadataWrapperSO = siteMetadataWrapperMap.get(siteMetadataSO.Id);
                    String siteMetadataSOAltParentId = siteMetadataSO.Alternate_Parent_Site_Metadata__c;
                    if(siteMetadataSOAltParentId != null && siteMetadataWrapperMap.containsKey(siteMetadataSOAltParentId)){
                        ParentOrAltParentId = siteMetadataSOAltParentId;
                    }else{
                        ParentOrAltParentId = siteMetadataSO.Parent_Site_Metadata__c;
                    }
                    SiteMetadataWrapper parentSiteMetadata = siteMetadataWrapperMap.get(ParentOrAltParentId);
                    parentSiteMetadata.items.add(siteMetadataWrapperSO);
                }
            }
    
            // To form the Wrapper(Used in Lwc) which contains P1 items, w1 items, Metmast record and Substation record
            SiteMetadataWrapper plantAssetSitemetaWrapper = new SiteMetadataWrapper();
            plantAssetSitemetaWrapper.Id = plantAssetId;
            plantAssetSitemetaWrapper.label = siteMetadataSOs[0].Account_Plant__r.Name;
            plantAssetSitemetaWrapper.items = new List<SiteMetadataWrapper>();
    
            List<Id> g1Id  =  promptNameAndRecordIdsMap.get(Constants.G1_G2_PLANT_INFO_AND_RENEWABLE_TYPE_PROMPT);
            SiteMetadataWrapper g1SiteMetadataWrapper = siteMetadataWrapperMap.get(g1Id[0]);
            for(SiteMetadataWrapper g1SiteMetadataItem : g1SiteMetadataWrapper.items){
                if(g1SiteMetadataItem.promptName == Constants.P1_PLANT_INFO_PROMPT_SOLAR || g1SiteMetadataItem.promptName == Constants.W1_PLANT_INFO_PROMPT_WIND){
                    plantAssetSitemetaWrapper.items.addAll(g1SiteMetadataItem.items);
                }else{
                    plantAssetSitemetaWrapper.items.add(g1SiteMetadataItem);
                }
            }
    
            List<SiteMetadataWrapper> resultList = new List<SiteMetadataWrapper>();
            resultList.add(plantAssetSitemetaWrapper);
            result = JSON.serialize(resultList);
        }else{
            result = 'NoData';  //This is used for checking condition in JS so custom label is not required  
        }
        return result;
    }

    public class SiteMetadataWrapper{
        public String Id;
        public String label;
        public String promptName;
        public List<SiteMetadataWrapper> items;
    }
}