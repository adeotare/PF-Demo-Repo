/**
 * @description       :
 * @author            : 
 * @group             :
 * @last modified on  : 
 * @last modified by  : 
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   ?                                    Initial Version
 **/
public class inlineRfiDetail {
    //for rfi category
    @AuraEnabled
    public static List<wrapperClassNew> getMissingCat(
      sObject objectNeeded,
      String fieldNeeded,
      String recordTypeName,
      String recordId
    ) {
      List<RFI_Detail__c> existingDet = [
        SELECT RFI_Category__r.Name, RFI_Item_Status__c, Account_Plant__c
        FROM RFI_Detail__c
        WHERE
        RAID__c = :recordId
          AND RFI_Item_Status__c != 'Closed'
          AND RFI_Item_Status__c != 'Canceled'
          AND RFI_Item_Status__c != 'Cannot Complete'
      ];
  
      //to get picklist
      List<String> pickList = new List<String>();
      Schema.sObjectType objType = objectNeeded.getSObjectType();
      Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
      MAP<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
      List<Schema.PicklistEntry> values = fieldMap.get(fieldNeeded).getDescribe().getPickListValues();
      for (Schema.PicklistEntry a : values) {
        pickList.add(a.getValue());
      }
      pickList.sort();
  
      Set<String> existingCat = new Set<String>();
      if (existingDet.size() > 0) {
        for (RFI_Detail__c rfi : existingDet) {
          if (rfi.RFI_Category__r != null) {
            existingCat.add(rfi.RFI_Category__r.Name);
          }
        }
      }
      System.debug('existingCat' + existingCat.size());
      List<RFI_Categories__c> listMissingCat = [
        SELECT
          Id,
          Name,
          RecordType.Name,
          Description__c,
          Category_Classification__c,
          RFI_Category_Status__c,
          Request_Type__c,
          Default_To_Blocker__c
        FROM RFI_Categories__c
        WHERE Name NOT IN :existingCat AND RFI_Category_Status__c = 'Active'
        ORDER BY NAME ASC
      ];
      List<wrapperClassNew> returnwrapperClass = new List<wrapperClassNew>();
  
      // Assign Values
      if (listMissingCat.size() > 0) {
        for (RFI_Categories__c cat : listMissingCat) {
          wrapperClassNew ins = new wrapperClassNew();
          ins.lstRfiCat = cat;
          ins.description = cat.Description__c;
          ins.onsitePicklist = pickList;
          ins.selOption = (cat.Name == 'Combiner Box Information') ? 'Yes' : '';
          ins.onsiteDescription = '';
          ins.implementationBlock = cat.Default_To_Blocker__c;
          ins.categoryType = (String) RFI_Detail__c.sObjectType.newSObject(null, true).get('Category_Type__c');
          returnwrapperClass.add(ins);
        }
      }
      return returnwrapperClass;
    }
  
    @AuraEnabled
    public static List<wrapperClassNew> getCategoriesForRfi(Id recordId) {
      Map<Id, List<wrapperClassNew>> rfiDetail = getCategoriesForRfis(new List<Id>{ recordId });
      return rfiDetail.get(recordId);
    }
  
    @AuraEnabled
    public static Map<Id, List<wrapperClassNew>> getCategoriesForRfis(List<Id> recordIds) {
      // Map Variables
      Map<Id, List<wrapperClassNew>> itemMap = new Map<Id, List<wrapperClassNew>>();
  
      // Get Plant Asset Fields for Query
      Set<String> fields = new Set<String>{ 'Renewable_Type__c' };
      List<Schema.PicklistEntry> fieldOptions = RFI_Categories__c.Plant_Asset_Filter_Field__c.getDescribe().getPickListValues();
      for (Schema.PicklistEntry f : fieldOptions) {
        fields.add(f.getValue());
      }
  
      // Query RFI and related Items with plant asset fields
      String rfiSoql = 'SELECT Id, Account_Plant__c, Sub_Type__c ';
      for (String f : fields) {
        system.debug('--f--'+f);
        rfiSoql += ', Account_Plant__r.' + f;
        system.debug('--rfiSoql--'+rfiSoql);
      }
      rfiSoql += ', (SELECT Id, RFI_Category__c, RFI_Category__r.Name, RFI_Item_Status__c FROM RFI_Detail__r WHERE RFI_Item_Status__c != \'Canceled\') ';
      rfiSoql += 'FROM RAID__c WHERE Id in :recordIds ';
      List<RAID__c> rfis = (List<RAID__c>) Database.query(rfiSoql);
  
      for (RAID__c rfi : rfis) {
        itemMap.put(rfi.Id, new List<wrapperClassNew>());
      }
  
      // Get RFI Categories
      List<RFI_Categories__c> categories = new List<RFI_Categories__c>(
        [
          SELECT
            Id,
            Name,
            RecordType.Name,
            Description__c,
            Category_Classification__c,
            RFI_Category_Status__c,
            Request_Type__c,
            Default_To_Blocker__c,
            Plant_Asset_Filter_Field__c,
            Plant_Asset_Filter_Value__c,
            Renewable_Type_Filter__c,
            RFI_Sub_Type_Filter__c
          FROM RFI_Categories__c
          WHERE RFI_Category_Status__c = 'Active'
          ORDER BY NAME ASC
        ]
      );
  
      for (RAID__c rfi : rfis) {
        Account_Plant__c plantAsset = rfi.Account_Plant__r;
        String subType = rfi.Sub_Type__c;
  
        // Get Existing if already an RFI
        Set<Id> existingCat = new Set<Id>();
        for (RFI_Detail__c item : rfi.RFI_Detail__r) {
          existingCat.add(item.RFI_Category__c);
        }
  
        List<wrapperClassNew> wrapperClass = new List<wrapperClassNew>();
  
        for (RFI_Categories__c cat : categories) {
          if (existingCat.contains(cat.Id)) continue;
          // Filter by Plant Asset Values
          Boolean selected =
            meetsFilter(cat.RFI_Sub_Type_Filter__c, subType, false) &&
            meetsFilter(cat.Renewable_Type_Filter__c, plantAsset.Renewable_Type__c, false);
          if (cat.Plant_Asset_Filter_Field__c != null)
            selected =
              selected &&
              meetsFilter(
                cat.Plant_Asset_Filter_Value__c,
                (String) plantAsset.get(cat.Plant_Asset_Filter_Field__c),
                true
              );
  
          wrapperClassNew ins = new wrapperClassNew();
          ins.lstRfiCat = cat;
          ins.description = cat.Description__c;
          //ins.onsitePicklist = pickList;
          ins.selected = selected;
          ins.implementationBlock = cat.Default_To_Blocker__c;
          ins.categoryType = (String) RFI_Detail__c.sObjectType.newSObject(null, true).get('Category_Type__c');
          wrapperClass.add(ins);
        }
        wrapperClass.sort();
        itemMap.put(rfi.Id, wrapperClass);
      }
  
      return itemMap;
    }
  
    private static Boolean meetsFilter(String filter, String value, Boolean allowBlank) {
      if (allowBlank && String.isBlank(filter) && String.isBlank(value))
        return true;
      if (String.isBlank(filter) || String.isBlank(value))
        return false;
      Set<String> filterSet = new Set<String>(filter.split(';'));
      Set<String> valueSet = new Set<String>(value.split(';'));
      for (String v : valueSet) {
        if (filterSet.contains(v))
          return true;
      }
      return false;
    }
  
    //for two category
    @AuraEnabled
    public static String processCatValues(Map<String, String> selectedCategory, String recordId) {
      List<RFI_Detail__c> lstMissingDetail = new List<RFI_Detail__c>();
      List<RFI_Detail__c> lstIncorrectDetail = new List<RFI_Detail__c>();
      String value;
  
      //RFI__c rfiVariable = [SELECT Id, Account_Plant__c FROM RFI__c WHERE Id = :recordId LIMIT 1];
  
      for (RFI_Categories__c rfi : [
        SELECT Id, RecordType.Name
        FROM RFI_Categories__c
        WHERE Id = :selectedCategory.keySet()
      ]) {
        wrapperClassNew wrpCls = (wrapperClassNew) JSON.deserialize(selectedCategory.get(rfi.Id), wrapperClassNew.class);
        lstMissingDetail.add(wrpCls.convertToRFIItem(rfi, recordId));
      }
  
      try {
        system.debug('---lstMissingDetail--'+lstMissingDetail);
        upsert lstMissingDetail;
        value = 'success';
        //RFIBatchProcess be = new RFIBatchProcess(lstMissingDetail);
        //value = Database.executeBatch(be, 25);
      } catch (Exception e) {
        System.debug('Error in insert');
      }
      return value;
    }
  
    //to get rfi detail
    // getCheckRfi
    @AuraEnabled
    public static Integer getCheckRfi(string recordId) {
      System.debug('recordId');
      List<Account_Plant__c> listOfPlantAsset = new List<Account_Plant__c>();
      RAID__c instatVariable = [SELECT Id, RFI_Status__c FROM RAID__c WHERE Id = :recordId];
      System.debug(
        'instatVariable' +
        recordId +
        'instatVariable' +
        instatVariable.Id +
        'instatVariable' +
        instatVariable.RFI_Status__c
      );
      Integer proceed = 0;
      if (instatVariable.RFI_Status__c != 'Closed') {
        proceed++;
      }
      return proceed;
    }
  
    //for Plant asset tag component
    @AuraEnabled
    public static List<Account_Plant__c> getListOfPlantAsset(String accountFilter, String subType) {

      
      List<Account_Plant__c> listOfPlantAsset = new List<Account_Plant__c>();
      
      system.debug('---subType--'+subType);
  
      String soql = 'SELECT Id, Name,Account__r.Name,Customer_Plant_Name__c,Plant__r.Name,Active_RFI__c FROM Account_Plant__c where ';
/*  
      if(subType == 'Customer'){
        soql += 'RecordType.Name = \'Fleet Asset\' ';
      }else{
        soql += 'RecordType.Name = \'Customer Asset\' ';
      }
      */
      if (subType == 'Initial' || subType == 'Customer') {
        soql += ' Active_RFI__c = 0 AND Project_Lifecycle_Status__c = \'Pending\'';
      }
 else {
        soql += ' Active_RFI__c = 0 AND (Project_Lifecycle_Status__c != \'Pending\')';
      }
  
      if (!String.isBlank(accountFilter))
        soql += ' AND Account__r.Name like \'%' + String.escapeSingleQuotes(accountFilter) + '%\'';
      soql += ' ORDER BY NAME ASC ';
      List<Account_Plant__c> plantAssets = (List<Account_Plant__c>) Database.query(soql);
  
      for (Account_Plant__c var : plantAssets) {
        listOfPlantAsset.add(var);
      }
      return listOfPlantAsset;
    }
  
    //add RFI with RFI detail
    @AuraEnabled
    public static Map<String, String> processRfiWithRfiDetail(
      Map<String, String> selectedCategory,
      String subType,
      String status,
      List<String> selectedPlant
    ) {
      // return selectedMissingCat.size()+'-'+selectedIncorrectCat.size();
      List<RFI_Detail__c> lstMissingDetail = new List<RFI_Detail__c>();
      List<RFI_Detail__c> lstIncorrectDetail = new List<RFI_Detail__c>();
      List<RAID__c> lstRFI = new List<RAID__c>();
      String value;
      String error = '';
      Map<String, String> resultantValue = new Map<String, String>();
  
      Id RFI_RT = Utils.getRecordTypeInfo('RAID__c', 'RFI').getRecordTypeId();
      list<Account_Plant__c>lstAccountPlant = [Select id,Name from Account_Plant__c where id IN: selectedPlant];

      for (Account_Plant__c plantVar : lstAccountPlant) {
        system.debug('---plantVar---'+plantVar.Name);
        RAID__c rfiVar = new RAID__c();
        rfiVar.Account_Plant__c = plantVar.id;
        rfiVar.Sub_Type__c = subType;        
        rfiVar.RFI_Status__c = status;

        rfiVar.recordtypeId = RFI_RT;
        rfiVar.Priority__c= 'Low';
        rfiVar.Title__c=plantVar.Name;
        rfiVar.Status__c= 'In Progress';
        rfiVar.Type__c= 'Process';
        lstRFI.add(rfiVar);
      }
  
      try {
        system.debug('INSERT ' + lstRFI);
        insert lstRFI;
      } catch (Exception e) {
        System.debug('Error in insert');
        error = e.getMessage();
        System.debug('error: ' + error);
      }
      if (error == '') {
        List<Id> rfiIds = new List<Id>();
        for (RAID__c rfi : lstRFI) {
          rfiIds.add(rfi.Id);
        }
  
        Map<Id, List<wrapperClassNew>> rfiItemsMap = getCategoriesForRfis(rfiIds);
  
        for (RAID__c rfi : lstRFI) {
          for (wrapperClassNew wrpClass : rfiItemsMap.get(rfi.Id)) {
            if (wrpClass.selected) {
              wrpClass.status = status;
              lstMissingDetail.add(wrpClass.convertToRFIItem(wrpClass.lstRfiCat, rfi.Id));
            }
          }
        }
  
        /*//    return value;
        List<RFI__c> rfiList = new List<RFI__c>();
        if (lstRFI != null) {
          for (RFI__c idVar : [SELECT Id, Name, Account_Plant__c FROM RFI__c WHERE Id IN :lstRFI]) {
            rfiList.add(idVar);
          }
        }
  
        List<RFI_Categories__c> rfiCat = new List<RFI_Categories__c>();
        if (selectedCategory.keySet() != null) {
          for (RFI_Categories__c rfi : [
            SELECT Id, RecordType.Name
            FROM RFI_Categories__c
            WHERE Id = :selectedCategory.keySet()
          ]) {
            rfiCat.add(rfi);
          }
        }
  
        if (lstRFI.size() > 0) {
          for (RFI__c idVar : rfiList) {
            for (RFI_Categories__c rfi : rfiCat) {
              wrapperClassNew wrpCls = (wrapperClassNew) JSON.deserialize(
                selectedCategory.get(rfi.Id),
                wrapperClassNew.class
              );
              RFI_Detail__c rfiDetial = new RFI_Detail__c();
              if (rfi.RecordType.Name == 'Incorrect Information') {
                rfiDetial.Incorrect_Category__c = rfi.Id;
              } else if (rfi.RecordType.Name == 'Missing/Incomplete Information') {
                rfiDetial.Missing_Incomplete_Category__c = rfi.Id;
              }
              rfiDetial.RAID__c = idVar.Id; //record Id
              rfiDetial.RFI_Detail_Description__c = wrpCls.description;
              rfiDetial.RFI_Item_Status__c = 'Submitted – Pending Customer Review';
              rfiDetial.Account_Plant__c = idVar.Account_Plant__c;
              rfiDetial.Onsite_Remediation_Required__c = wrpCls.selOption;
              rfiDetial.Implementation_Blocked__c = wrpCls.implementationBlock;
              if (wrpCls.selOption == 'Yes') {
                rfiDetial.Onsite_Remediation_Description__c = wrpCls.onsiteDescription;
              }
              lstMissingDetail.add(rfiDetial);
            }
          }
        }*/
        try {
          System.debug('lstMissingDetail' + lstMissingDetail);
          RFIBatchProcess be = new RFIBatchProcess(lstMissingDetail);
          value = Database.executeBatch(be, 25);
        } catch (Exception e) {
          System.debug('Error in insert');
        }
        resultantValue.put('Success', value);
  
        return resultantValue;
      }
      resultantValue.put('Error in RFI', error);
      return resultantValue;
      // return error;
    }
  
    //for Mass Change PF owner component
    //load active rfi
  
    @AuraEnabled
    public static List<wrapperForChangeMassPF> loadRfiItem(Id recordId) {
      System.debug('recordId:---' + recordId);
      List<RFI_Detail__c> lstOfRFIdetails = [
        SELECT
          Id,
          Name,
          RFI_Detail_Description__c,
          Assigned_Customer_Contact__c,
          Assigned_Customer_Contact__r.Name,
          IE_Owner__c,
          IE_Owner__r.Name
        FROM RFI_Detail__c
        WHERE RAID__c = :recordId
      ];
      System.debug('lstOfRFIdetails:---' + lstOfRFIdetails);
  
      List<wrapperForChangeMassPF> returnwrapperClass = new List<wrapperForChangeMassPF>();
  
      // Assign Values
      if (lstOfRFIdetails.size() > 0) {
        for (RFI_Detail__c detail : lstOfRFIdetails) {
          wrapperForChangeMassPF ins = new wrapperForChangeMassPF();
          ins.lstRfiDetails = detail;
          ins.selOptionOwner = detail.IE_Owner__c;
          returnwrapperClass.add(ins);
        }
      }
      return returnwrapperClass;
    }
  
    @AuraEnabled
    public static Integer updateRfiItems(String listRfiUpdated) {
      String value2;
  
      System.debug('totalListRfiItem' + listRfiUpdated);
      List<RFI_Detail__c> rfiListValues = (List<RFI_Detail__c>) JSON.deserialize(
        listRfiUpdated,
        List<RFI_Detail__c>.class
      );
      // List<wrapperForChangeMassPF> wrpCls	= (List<wrapperForChangeMassPF>)JSON.deserialize(totalListRfiItem, wrapperForChangeMassPF.class);
      System.debug('wrpCls' + rfiListValues);
  
      List<RFI_Detail__c> rfiListUpdate = new List<RFI_Detail__c>();
  
      for (RFI_Detail__c wrapperVariable : rfiListValues) {
        System.debug('wrapperVariable.selOptionOwner' + wrapperVariable.IE_Owner__c);
        RFI_Detail__c rfiVar = new RFI_Detail__c();
        rfiVar.Id = wrapperVariable.Id;
        rfiVar.IE_Owner__c = wrapperVariable.IE_Owner__c;
        rfiVar.Assigned_Customer_Contact__c = wrapperVariable.Assigned_Customer_Contact__c;
        rfiListUpdate.add(rfiVar);
      }
  
      try {
        System.debug('lstMissingDetail' + rfiListUpdate);
        RFIBatchProcess rfiBathVar = new RFIBatchProcess(rfiListUpdate);
        value2 = Database.executeBatch(rfiBathVar, 25);
  
        //update rfiListUpdate;
      } catch (Exception e) {
        System.debug('Error in Update');
      }
  
      return rfiListUpdate.size();
    }
  
    @AuraEnabled
    public static List<String> getSelectOptions(sObject objObject, string fld) {
      return InlineEditHandler.getselectOptions(objObject, fld);
    }
  
    @AuraEnabled
    public static Boolean getCustomPermissionAccess() {
      return FeatureManagement.checkPermission('Customer_Level_RFI');
    }
  
  }