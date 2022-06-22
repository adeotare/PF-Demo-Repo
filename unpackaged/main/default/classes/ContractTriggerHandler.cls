public class ContractTriggerHandler {
	
    public static void manageParentRenQuote(Map<Id,Contract> newRecordsMap , Map<Id,Contract> oldRecordMap){
        Set<Id> idSet = new Set<Id> ();
        
        for(Contract cnt : newRecordsMap.values()){
            if(oldRecordMap.containsKey(cnt.Id) && !oldRecordMap.get(cnt.Id).SBQQ__RenewalQuoted__c && cnt.SBQQ__RenewalQuoted__c ){
                idSet.add(cnt.SBQQ__Quote__c);
            }
        }
        
        if(!idSet.isEmpty()){
            system.debug('idSet--'+idSet);
            RenewableQuoteProcessHelper.createChildPPTunderRenewableQL(idSet);
        }
    }
}