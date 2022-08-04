trigger addNetTotalFromPpt on Plant_Product_Transaction__c(after insert, after update, before delete) {
    Set<Id> QLIds = new Set<Id>();

    List<Plant_Product_Transaction__c> PPTList = Trigger.isDelete ? Trigger.Old : Trigger.New;
    for (Plant_Product_Transaction__c ppt : PPTList) {
        
        if (Trigger.isDelete || Trigger.isInsert || (ppt.Net_Total_Price__c != Trigger.oldMap.get(ppt.Id).Net_Total_Price__c)) {
            QLIds.add(ppt.Quote_Line__c);
        }
    }

    List<SBQQ__QuoteLine__c> QLToUpdate = [SELECT Id, Related_PPT_s_Net_Total__c,(SELECT id,name,Net_Total_Price__c FROM Plant_Product_Transactions__r WHERE Net_Total_Price__c != null) FROM SBQQ__QuoteLine__c WHERE Id IN :QLIds];
    for (SBQQ__QuoteLine__c ql : QLToUpdate) {
        Decimal total = 0;
        for (Plant_Product_Transaction__c ppt : ql.Plant_Product_Transactions__r) {
          
            if (Trigger.isAfter || !Trigger.oldMap.containsKey(ppt.Id)) {
                total += ppt.Net_Total_Price__c;
            }
        }
        ql.Related_PPT_s_Net_Total__c = total; 
    }
    
    update QLToUpdate;
}