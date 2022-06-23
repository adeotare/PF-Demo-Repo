/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 10-05-2020
 * @last modified by  : Justin Smith @cyberjus
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   09-21-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
 **/
public with sharing class wrapperClassNew implements Comparable {
    @AuraEnabled
    public RFI_Categories__c lstRfiCat { get; set; }
    @AuraEnabled
    public RFI_Detail__c lstRfiDetails { get; set; }
    @AuraEnabled
    public String description { get; set; }
    @AuraEnabled
    public String selOption { get; set; }
    @AuraEnabled
    public List<String> onsitePicklist { get; set; }
    @AuraEnabled
    public String onsiteDescription { get; set; }
    @AuraEnabled
    public Boolean implementationBlock { get; set; }
    @AuraEnabled
    public String categoryType { get; set; }
    @AuraEnabled
    public Boolean filtered { get; set; }
    @AuraEnabled
    public Boolean selected { get; set; }
    @AuraEnabled
    public String status { get; set; }
  
    public wrapperClassNew() {
      lstRfiCat = new RFI_Categories__c();
      onsitePicklist = new List<String>();
      onsiteDescription = '';
      filtered = false;
      selected = false;
    }
  
    public Integer compareTo(Object compareTo) {
      wrapperClassNew compareToW = (wrapperClassNew) compareTo;
      if (selected && !compareToW.selected)
        return -1;
      if (!selected && compareToW.selected)
        return 1;
      if (lstRfiCat.Name < compareToW.lstRfiCat.Name)
        return -1;
      if (lstRfiCat.Name > compareToW.lstRfiCat.Name)
        return 1;
      return 0;
    }
  
    public RFI_Detail__c convertToRFIItem(RFI_Categories__c category, Id rfiId) {
      RFI_Detail__c rfiDetail = new RFI_Detail__c();
      if (category.RecordType.Name == 'Incorrect Information') {
        rfiDetail.Incorrect_Category__c = category.Id;
      } else if (category.RecordType.Name == 'Missing/Incomplete Information') {
        rfiDetail.Missing_Incomplete_Category__c = category.Id;
      }
      rfiDetail.RFI_Category__c = category.Id;
      rfiDetail.RAID__c = rfiId; //record Id
      rfiDetail.RFI_Detail_Description__c = this.description;
      if (this.status != null)
        rfiDetail.RFI_Item_Status__c = this.status;
      //rfiDetial.RFI_Item_Status__c = 'Submitted – Pending Customer Review';
      //rfiDetial.Account_Plant__c = rfiVariable.Account_Plant__c;
      rfiDetail.Category_Type__c = this.categoryType;
      //rfiDetial.Onsite_Remediation_Required__c = wrpCls.selOption;
      rfiDetail.Implementation_Blocked__c = this.implementationBlock;
      //if (wrpCls.selOption == 'Yes') {
      //  rfiDetial.Onsite_Remediation_Description__c = wrpCls.onsiteDescription;
      //}
      return rfiDetail;
    }
  }