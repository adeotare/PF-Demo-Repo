/**
 * TODO - Calls from Generate RFI button in LWC
 * Publish a Platform events for RFI and RFI Item creation.  
 * */ 
public with sharing class TriggerPEForRFICreation {
    public static String plantAssetId;
    /*
    * Publish a Platform Events for RFI and RFI Item creations.
    * @param {String} plantAssetId - Pass Plant Asset for data creation for reports.
    */
    @AuraEnabled
    public static String createPEForRFI(String plantAssetId){
        Savepoint sp = Database.setSavepoint();
        String rfiProcessResult =''; 
        try{
            plantAssetId = plantAssetId;

            RAID__c[] existingRfiRelToPA = [SELECT Id, Account_Plant__c, RFI_Status__c, Account_Plant__r.Asset_Builder_Status__c FROM RAID__c WHERE Account_Plant__c =: plantAssetId AND RFI_Status__c !=: Constants.CLOSED];
            list<RFI_Detail__c> rfiDetailsLst = new list<RFI_Detail__c>();
            if(existingRfiRelToPA.size() > 0){
                list<RFI_Categories__c> rfiCategories = [SELECT Id, Name, RFI_Category_Status__c 
                        FROM RFI_Categories__c WHERE NAME =: System.Label.SubstationRFICategoryName AND RFI_Category_Status__c = 'Active' AND
                        RecordTypeId =: Utils.getRecordTypeInfo('RFI_Categories__c', ConstantsRecordTypes.RFI_CATEGORY_MISSING_INCOMPLETE_INFORMATION).getRecordTypeId() LIMIT 1];
                rfiDetailsLst = [SELECT Id, RAID__c, RFI_Category__c
                        FROM RFI_Detail__c WHERE RAID__c =: existingRfiRelToPA[0].Id AND RFI_Category__c !=: rfiCategories[0].Id
                        AND IsDeleted = false];
            }
            
            //To Check Asset Builder Status in Plant Asset 
            Account_Plant__c plantAsset = Utils.getRfiDetailsFrmPlantAsset(plantAssetId);
            
            //RFI can be generated only when Asset builder status as "Completed" and AB Approval Status as "Approved"
            if((plantAsset.Asset_Builder_Status__c != Constants.COMPLETED || plantAsset.Asset_Builder_Status__c == Constants.COMPLETED) && plantAsset.AB_Approval_Status__c != 'Approved'){
                rfiProcessResult = System.Label.AssetBuilderStatusNeedToComplete+'&Info';
            }else if(plantAsset.Asset_Builder_Status__c != Constants.COMPLETED || rfiDetailsLst.size() > 0){
                rfiProcessResult = System.Label.CannotCreateRfiKindlyDeleteOtherRfiItemsRelatedToReports+'&Info';
            }else if(plantAsset.Asset_Builder_Status__c == Constants.COMPLETED && plantAsset.AB_Approval_Status__c == 'Approved'){
                rfiProcessResult = Utils2.callRFIGeneration(plantAssetId);
            }
        }catch(Exception exceptionDetails){
            Database.rollback(sp);
            rfiProcessResult = exceptionDetails.getMessage()+'&Error';
            insert Utils.catchErrorLogs('createPEForRFI',exceptionDetails.getMessage(), exceptionDetails.getLineNumber(), plantAssetId, '');
        }
        return rfiProcessResult;
    }
}