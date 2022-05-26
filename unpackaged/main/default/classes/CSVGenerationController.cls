public with sharing class CSVGenerationController {
    
    @AuraEnabled
    public static String getSiteMetadata(String plantAssetId){ 
        String csvInputsString = '';
        List<Site_Metadata__c> siteMetadataLst = [SELECT Parent_Asset_Short_Name__c, Asset_Short_Name__c, Name, Asset_Name__c, 
        Base_Asset_Template__r.Name, Attribute_Info__c, Account_Plant__r.Customer_Plant_Asset_ID__c, Base_Asset_Template__c,
        Account_Plant__r.Plant_Name__c, Prompt_Information__r.Name FROM Site_Metadata__c 
        WHERE Account_Plant__c =: plantAssetId AND Asset_Short_Name__c != null AND Base_Asset_Template__c != null 
        AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false
        ORDER BY Plant_Asset_Prompt_Detail__r.Prompt_Information__r.CSV_Sorting_Order__c ASC NULLS last];
        

        String temVersion = [SELECT Id, TEM_Version__c FROM Account_Plant__c WHERE Id =: plantAssetId].TEM_Version__c;

        if(siteMetadataLst.size()>0){
            List<Core_Attribute__c> attrLst = [SELECT Id, Name, Attribute_Master__r.Name, Base_Asset_Name__c, 
                Base_Asset_Name__r.Name, Prompt_Information__r.Name, TEM_Version__c, Show_Path_in_CSV_Generation__c,
                Default_value__c, Is_Related_Subarray_Bifacial__c FROM Core_Attribute__c WHERE Base_Asset_Name__c != null AND TEM_Version__c =: temVersion];
            Map<String,Object> csvInputsMap = CSVGenerationController.getCSVInputsMap(attrLst, siteMetadataLst);
            csvInputsString = JSON.serialize(csvInputsMap);
            return csvInputsString;
        }else{
            return csvInputsString;
        }    
    }
    
    @AuraEnabled
    public static Map<String,Object> getCSVInputsMap(
    List<Core_Attribute__c> attrLst,
    List<Site_Metadata__c> siteMetadataLst){
        Map<String,Object> csvInputsMap = new Map<String,Object>();
        csvInputsMap.put('Attributes', attrLst);
        csvInputsMap.put('SiteMetadataRecords', siteMetadataLst);
        return csvInputsMap;
    }
    @AuraEnabled
    public static Boolean fileUpload(String csvString, String plantAssetId, String fileName){
        try{    
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = Blob.valueOf(csvString);
            cv.IsMajorVersion = true;
            Insert cv;

            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = plantAssetId;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            Insert cdl;
            return true;
        }catch(Exception exceptionDetails){
                String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
                System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
                throw new AuraHandledException(errorMessage);
        }
    }
}