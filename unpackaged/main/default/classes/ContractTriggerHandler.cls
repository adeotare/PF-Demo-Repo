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
    
    public static void manageParentAmbedQuote(Map<Id,Contract> newRecordsMap , Map<Id,Contract> oldRecordMap){
        Set<Id> idSetForAmbedmentQuote = new Set<Id>();
        
        for(Contract cnt : newRecordsMap.values()){
            if(oldRecordMap.containsKey(cnt.Id) && !oldRecordMap.get(cnt.Id).Amendment_Quoted__c && cnt.Amendment_Quoted__c ){
                idSetForAmbedmentQuote.add(cnt.Id);
                
            }
         }
        system.debug('idSetForAmbedmentQuote 29th line--'+idSetForAmbedmentQuote);
        
        // only Ambedment Quote's QuoteLine:
        
           List <SBQQ__QuoteLine__c> qlList =  [SELECT Id ,
                                                 	   	SBQQ__Product__c ,
                                                		SBQQ__Quote__r.SBQQ__Account__c,
                                                        SBQQ__ListPrice__c,
                                                
                                                	   (SELECT id FROM Plant_Product_Transactions__r)
            									FROM SBQQ__QuoteLine__c 
             									WHERE SBQQ__Quote__r.SBQQ__Type__c = 'Amendment' 
             										AND SBQQ__Quote__r.SBQQ__MasterContract__c != null 
             										AND SBQQ__Quote__r.SBQQ__MasterContract__c in :idSetForAmbedmentQuote
                                                	AND SBQQ__Product__c != null LIMIT 50000];
        
        
      		
        if(qlList != null && qlList.size() > 0){
            system.debug('qlList---'+qlList);        
        
            AmendmentQuoteProcessHelper.createPPTunderAmbededQL(qlList);
            system.debug('qlList 50 line---'+qlList);  
            
            
        }
    }
}