/**
 * TODO - Calls when Site Metadata inserted or updated or deleted
 * */
trigger SiteMetaDataTrigger on Site_Metadata__c (after update, after insert) {
    if(trigger.isAfter){
        if(trigger.isUpdate){
            /*
            * To pass new data or data's to triggerPlatformEvents if Site Metadata is updated. 
            @param {List<Site_Metadata__c>} errorMsg - Pass new Site Metadata.
            @param {Boolean} true - Site Metadata need to update.
            @param {Boolean} false - Site Metadata need to insert.
            */
            SiteMetaDataHandler.triggerPlatformEvents(Trigger.new, true, false);
        }
        if(trigger.isInsert){
            /*
            * To pass new data or data's to triggerPlatformEvents if Site Metadata is inserted. 
            @param {List<Site_Metadata__c>} errorMsg - Pass new Site Metadata.
            @param {Boolean} false - Site Metadata need to update.
            @param {Boolean} true - Site Metadata need to insert.
            */
            SiteMetaDataHandler.triggerPlatformEvents(Trigger.new, false, true);
        }
    }
}