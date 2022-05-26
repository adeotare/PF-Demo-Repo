/**
 * TODO - Calls from SiteMetaDataHandler when Site Metadata is created or updated.
 * Roll Up of values from proceeding child sitemetadata to parent sitemetadata for particular Plant Asset.
 * For eg: Rollup from P3->P1, P5->P3->P1 prompts
 * Attribute will roll up to parent sitemetadata occurs only if Attribute Master of child sitemetadata matches with Attribute Master of parent sitemetadata.
 */
public with sharing class CoreAttrRollUpHdlr {
    public DateTime lastPromptInitiatedId;
    public String plantAssetPromptDetail;
    public String plantAssetId;
    /*
    * Site Metadata update with proceeding child sitemetadata.
    * @param {List<Id>} siteMetaDataIdLst - List of Site Metadata need for roll up in Attributes.
    * @param {DateTime} lastPromptInitiatedId - Initiated date and time for track the execution process.
    * @param {String} plantAssetPromptDetail - Track updates of roll up in Attributes against Plant Asset.
    * @param {String} plantAssetId - Roll up in Attributes against Plant Asset
    */
    public static void afterUpdateSiteMetaData(List<Id> promptInfoIdLst, DateTime lastPromptInitiatedId, String plantAssetPromptDetail, String plantAssetId){
        Plant_Asset_Prompt_Detail__c pltAstPrtDtl = [SELECT Id, Name, Last_Rollup_Process_Initiated_DT__c
                        FROM Plant_Asset_Prompt_Detail__c 
                        WHERE Id =: plantAssetPromptDetail AND Is_Deleted__c = FALSE];
        try{
            lastPromptInitiatedId = lastPromptInitiatedId;
            plantAssetPromptDetail = plantAssetPromptDetail;
            plantAssetId = plantAssetId;

            Set<Id> baseAssetIdList = new Set<Id>();
            Map<String, String> coreAttributeList = new Map<String, String>();
            Map<Id, Map<String, String>> attrCollection = new Map<Id, Map<String, String>>();
            List<Site_Metadata__c> siteMetaDataList = new List<Site_Metadata__c>();
            for(Site_Metadata__c siteMetaDataInstance : [SELECT Id, Name, Attribute_Info__c, Base_Asset_Template__c, Account_Plant__c, Prompt_Specific_Info__c, Parent_Site_Metadata__c, Prompt_Information__c, Plant_Asset_Prompt_Detail__r.Is_Deleted__c 
                                                        FROM Site_Metadata__c 
                                                        WHERE Prompt_Information__c IN: promptInfoIdLst AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = FALSE AND Account_Plant__c =: plantAssetId]){
                if(!String.isBlank(siteMetaDataInstance.Base_Asset_Template__c)){
                    baseAssetIdList.add(siteMetaDataInstance.Base_Asset_Template__c);
                }
                siteMetaDataList.add(siteMetaDataInstance);
            }
           
            for(Core_Attribute__c coreAttributeInstance :  [SELECT Id, Name, Attribute_Master__r.Name, Is_Rollup__c, Attribute_Master__r.Data_Type__c FROM 
                Core_Attribute__c WHERE Is_Rollup__c = true AND Base_Asset_Name__c IN: baseAssetIdList]){
                if(coreAttributeInstance.Attribute_Master__r.Data_Type__c == 'Decimal' || coreAttributeInstance.Attribute_Master__r.Data_Type__c == 'Number'){
                    if(!coreAttributeList.containskey(coreAttributeInstance.Attribute_Master__r.Name)){
                        coreAttributeList.put(coreAttributeInstance.Attribute_Master__r.Name, coreAttributeInstance.Attribute_Master__r.Data_Type__c);
                    }
                }
            }
            
            if(baseAssetIdList.size() > 0){
                for(Site_Metadata__c sitemetadata : siteMetaDataList){
                    if(baseAssetIdList.contains(sitemetadata.Base_Asset_Template__c)){
                        Map<String, String> attrValue = new Map<String, String>();
                        for(String attInstance : coreAttributeList.keySet()){
                            Map<String, String> attrInforList = (Map<String, String>)JSON.deserialize(sitemetadata.Attribute_Info__c,Map<String,String>.class);
                            if(attrInforList.containskey(attInstance)){
                                if(String.isNotBlank(attrInforList.get(attInstance))){
                                    String checkVal = attrInforList.get(attInstance);
                                    if(checkVal.length() > 0){
                                        if(attrCollection.containsKey(sitemetadata.Parent_Site_Metadata__c) && attrInforList.containsKey(attInstance)){
                                            Map<String, String> currentValueMap = attrCollection.get(sitemetadata.Parent_Site_Metadata__c);
                                            //Addition of child Site Metadata values and Parent Site Metadata
                                            if(currentValueMap.containsKey(attInstance)){
                                                if(coreAttributeList.get(attInstance) == 'Decimal'){
                                                    Decimal currentValueInt = Decimal.valueOf(currentValueMap.get(attInstance));
                                                    Decimal sumOfValues = currentValueInt + Decimal.valueOf(checkVal);
                                                    currentValueMap.remove(attInstance);
                                                    currentValueMap.put(attInstance, String.valueOf(sumOfValues));
                                                }
                                                if(coreAttributeList.get(attInstance) == 'Number'){
                                                    Integer currentValueInt = Integer.valueOf(currentValueMap.get(attInstance));
                                                    Integer sumOfValues = currentValueInt + Integer.valueOf(checkVal);
                                                    currentValueMap.remove(attInstance);
                                                    currentValueMap.put(attInstance, String.valueOf(sumOfValues));
                                                }
                                            }else{
                                                attrValue.put(attInstance, checkVal);
                                            }
                                        }else{
                                            if(attrInforList.containsKey(attInstance)){
                                                attrValue.put(attInstance, checkVal);
                                                attrCollection.put(sitemetadata.Parent_Site_Metadata__c, attrValue);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
        
                List<Site_Metadata__c> parentSiteMetaData = [SELECT Id, Name, Parent_Site_Metadata__c, Base_Asset_Template__c, Attribute_Info__c 
                    FROM Site_Metadata__c WHERE Id IN: attrCollection.keySet()];
        
                for(Site_Metadata__c parentsiteMetaDataInstance : parentSiteMetaData){
                    Map<String, String> parentAttrInfoList = (Map<String, String>)JSON.deserialize(parentsiteMetaDataInstance.Attribute_Info__c,Map<String, String>.class);
                    Map<String, String> instanceMap = attrCollection.get(parentsiteMetaDataInstance.Id);
        
                    for(String strInstance : instanceMap.keySet()){
                        if(parentAttrInfoList.containsKey(strInstance)){
                            parentAttrInfoList.remove(strInstance);
                            parentAttrInfoList.put(strInstance, instanceMap.get(strInstance));
                        }
                    }
        
                    parentsiteMetaDataInstance.Attribute_Info__c = JSON.serialize(parentAttrInfoList);        
                }
                //Update the Plant Asset Prompt Detail to track the rollup process
                pltAstPrtDtl.Last_Rollup_Process_Initiated_DT__c = lastPromptInitiatedId;
               
                if(parentSiteMetaData.size() > 0){
                    update parentSiteMetaData;
                    update pltAstPrtDtl;
                }
            }
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('afterUpdateSiteMetaData',exceptionDetails.getMessage(), 
                exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetail);
            insert errorLogInstance;
            pltAstPrtDtl.Last_Rollup_Process_Initiated_DT__c = null;
            update pltAstPrtDtl;
        }
        
    }
}