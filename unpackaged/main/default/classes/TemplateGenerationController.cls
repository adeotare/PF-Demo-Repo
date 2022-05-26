public with sharing class TemplateGenerationController {
    @AuraEnabled
    public static String getSiteMetadata(String plantAssetId){ 
        list<String> allfilesRelatedToPA = new List<String>();
        String searchString = 'Templates';
        Implementation_Wizard_Form_Detail__c linkedIWFD = [SELECT Id, API_Type__c FROM Implementation_Wizard_Form_Detail__c WHERE Account_Plant__c =: plantAssetId
                            ORDER BY CreatedDate desc LIMIT 1];

        Boolean isAQS = linkedIWFD.API_Type__c == 'AQS' ? true : false;
        for(ContentDocumentLink contentDocument :[SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink WHERE
                LinkedEntityId =: linkedIWFD.Id]){
            allfilesRelatedToPA.add(contentDocument.ContentDocumentId);
        }

        string templateNameWithCSV = searchString+'.csv';
        List<ContentVersion> getCSVData = new list<ContentVersion>([SELECT Id, Title, VersionData FROM ContentVersion
        WHERE ContentDocumentId =: allfilesRelatedToPA
        AND Title =: templateNameWithCSV ORDER BY LastModifiedDate DESC LIMIT 1]);
System.debug('getCSVData --->'+getCSVData);
        String templateCSVString;
        if(getCSVData.size()>0){
            templateCSVString = Utils.blobToString( getCSVData[0].VersionData,'ISO-8859-1');
        }else{
            templateCSVString = 'No CSV Files Found';
        }
		
		String csvInputsString = '';
        List<Site_Metadata__c> siteMetadataLst = [SELECT Parent_Asset_Short_Name__c, Asset_Short_Name__c, Name, Asset_Name__c, 
        Base_Asset_Template__r.Name, Attribute_Info__c, Account_Plant__r.Customer_Plant_Asset_ID__c, Base_Asset_Template__c,
        Account_Plant__r.Plant_Name__c, Prompt_Information__r.Name FROM Site_Metadata__c 
        WHERE Account_Plant__c =: plantAssetId AND Asset_Short_Name__c != null AND Base_Asset_Template__c != null 
        AND Plant_Asset_Prompt_Detail__r.Is_Deleted__c = false
        ORDER BY Plant_Asset_Prompt_Detail__r.Prompt_Information__r.CSV_Sorting_Order__c ASC NULLS last];
        

        String temVersion = [SELECT Id, TEM_Version__c FROM Account_Plant__c WHERE Id =: plantAssetId].TEM_Version__c;

        if(siteMetadataLst.size()>0 && linkedIWFD.API_Type__c == 'AQS'){
            List<Core_Attribute__c> attrLst = [SELECT Id, Name, Attribute_Master__r.Name, Base_Asset_Name__c, 
                Base_Asset_Name__r.Name, Prompt_Information__r.Name, TEM_Version__c, Show_Path_in_CSV_Generation__c,
                Default_value__c FROM Core_Attribute__c WHERE Base_Asset_Name__c != null AND TEM_Version__c =: temVersion];
            Map<String,Object> csvInputsMap = TemplateGenerationController.getCSVInputsMap(attrLst, siteMetadataLst, templateCSVString, isAQS);
			csvInputsString = JSON.serialize(csvInputsMap);
            return csvInputsString;
        }else{
            return csvInputsString;
        }
	}
	
	 @AuraEnabled
    public static Map<String,Object> getCSVInputsMap(
    List<Core_Attribute__c> attrLst,
    List<Site_Metadata__c> siteMetadataLst,
    String templateCSVString,
    Boolean isAQS){
        Map<String,Object> csvInputsMap = new Map<String,Object>();
        csvInputsMap.put('Attributes', attrLst);
        csvInputsMap.put('SiteMetadataRecords', siteMetadataLst);
        csvInputsMap.put('TemplateCSV',templateCSVString);
        csvInputsMap.put('isAQS',isAQS);
        return csvInputsMap;
    }
}