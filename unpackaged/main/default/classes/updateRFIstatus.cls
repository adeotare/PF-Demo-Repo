/**
 * @description       :
 * @author            : 
 * @group             :
 * @last modified on  : 
 * @last modified by  : 
 * Modifications Log
 * Ver   Date         Author                   
 * 1.0   ?            
 * 1.1         Changed Picklist Status values, refactored for bulkification
 **/
public class updateRFIstatus {
  public static void getrfidetails(List<RFI_Detail__c> rfiDetailsLst) {
    Set<Id> rfiId = new Set<Id>();
    System.debug('rfiDetailsLst' + rfiDetailsLst.size());
    for (RFI_Detail__c a : rfiDetailsLst) {
      rfiId.add(a.RAID__c);
    }

    List<RAID__c> rfis = new List<RAID__c>(
      [
        SELECT
          Id,
          Account_Plant__c,
          Manual_Submission_DateTime__c ,
          Account_Plant__r.Project_Lifecycle_Status__c,
          RFI_Status__c,          
          (
            SELECT Id, RAID__c, RFI_Item_Status__c, Implementation_Blocked__c
            FROM RFI_Detail__r
            WHERE RFI_Item_Status__c != 'Drafting'
          )
        FROM RAID__c
        WHERE Id IN :rfiId
      ]
    );

    List<RAID__c> updateRFIs = new List<RAID__c>();
    List<Account_Plant__c> updatePlantAssets = new List<Account_Plant__c>();

    for (RAID__c rfi : rfis) {
      Boolean inProgress = false;
      Boolean submitted = false;
      Boolean closed = false;
      Boolean blocked = false;
      Boolean requested = false;
      Boolean drafting = false;

      for (RFI_Detail__c rfiVar : rfi.RFI_Detail__r) {
        if (rfiVar.RFI_Item_Status__c == 'Drafting') {
          drafting = true;
        } else if (
          rfiVar.RFI_Item_Status__c == 'Closed' ||
          rfiVar.RFI_Item_Status__c == 'Canceled' ||
          rfiVar.RFI_Item_Status__c == 'Cannot Complete'
        ) {
          closed = true;
        } else if (rfiVar.RFI_Item_Status__c == 'In Progress' || rfiVar.RFI_Item_Status__c == 'Needs Detail') {
          inProgress = true;
        } else if (rfiVar.RFI_Item_Status__c == 'Submitted') {
          submitted = true;
        } else if (rfiVar.RFI_Item_Status__c == 'Requested') {
          requested = true;
        }
        if (
          rfiVar.Implementation_Blocked__c == true &&
          (rfiVar.RFI_Item_Status__c == 'In Progress' ||
          rfiVar.RFI_Item_Status__c == 'Needs Detail' ||
          rfiVar.RFI_Item_Status__c == 'Requested')
        ) {
          blocked = true;
        }
      }

      if (drafting) {
        rfi.RFI_Status__c = 'Drafting';
      } else if (inProgress && rfi.Manual_Submission_DateTime__c == null) {
        rfi.RFI_Status__c = 'In Progress';
      } else if (requested && rfi.Manual_Submission_DateTime__c == null) {
        rfi.RFI_Status__c = 'Requested';
      } else if (submitted) {
        rfi.RFI_Status__c = 'Submitted';
      } else if (closed && !inProgress && !requested) {
        rfi.RFI_Status__c = 'Closed';
      }
      rfi.Implementation_Blocked__c = blocked;
      updateRFIs.add(rfi);
/*
      Account_Plant__c plantAsset = rfi.Account_Plant__r;
      if (plantAsset.Project_Lifecycle_Status__c != 'Pending') {
        if (blocked && plantAsset.Implementation_Status__c != 'Blocked') {
          plantAsset.Implementation_Status__c = 'Blocked';
          updatePlantAssets.add(plantAsset);
        } else if (!blocked && plantAsset.Implementation_Status__c != 'In Progress') {
          plantAsset.Implementation_Status__c = 'In Progress';
          updatePlantAssets.add(plantAsset);
        }
      }*/
    }

    update updateRFIs;
    if (!updatePlantAssets.isEmpty())
      update updatePlantAssets;
  }
}