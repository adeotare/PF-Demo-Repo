public class ContractTriggerHandler {
	
    public static void manageParentRenQuote(Map<Id,Contract> newRecordsMap , Map<Id,Contract> oldRecordMap){
        Set<Id> idSet = new Set<Id> ();
       	Set<Id> contractIdsForAmendmentCloning = new Set<Id> ();
        
        for(Contract cnt : newRecordsMap.values()){
            if(oldRecordMap.containsKey(cnt.Id) && !oldRecordMap.get(cnt.Id).SBQQ__RenewalQuoted__c && cnt.SBQQ__RenewalQuoted__c ){
               	contractIdsForAmendmentCloning.add(cnt.Id);
                idSet.add(cnt.SBQQ__Quote__c);
            }
		}
        
        if(!contractIdsForAmendmentCloning.isEmpty()){
            RenewableQuoteProcessHelper.createChildPPTforRenewQLByAmendOpp(contractIdsForAmendmentCloning , idSet);
        }
    }
    
    public static void manageParentAmbedQuote(Map<Id,Contract> newRecordsMap , Map<Id,Contract> oldRecordMap){
        Set<Id> idSetForAmbedmentQuote = new Set<Id>();
        
        for(Contract cnt : newRecordsMap.values()){
            system.debug(oldRecordMap.get(cnt.Id).Amendment_Quoted__c);
            system.debug(cnt.Amendment_Quoted__c);
            if(oldRecordMap.containsKey(cnt.Id) && !oldRecordMap.get(cnt.Id).Amendment_Quoted__c && cnt.Amendment_Quoted__c ){
                idSetForAmbedmentQuote.add(cnt.Id);
                
            }
         }
        system.debug('idSetForAmbedmentQuote 29th line--'+idSetForAmbedmentQuote);
        
        // only Ambedment Quote's QuoteLine:
        if(idSetForAmbedmentQuote != null && idSetForAmbedmentQuote.size() > 0){
            
            List<Contract> conList = [select id ,(select id,name from SBQQ__AmendmentOpportunities__r order by createddate desc LIMIT 2) from contract where Id In :idSetForAmbedmentQuote ];
            
            Set<Id> idSetForAmbedmentQuote2 = new Set<Id>();
            List<Opportunity> amendemnetOppLsit =  new List<Opportunity>();
            Map<Id, Opportunity> lastOppMap = new Map<Id, Opportunity>();
            Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
            
            for(Contract cont : conList){
                system.debug('contOpp--'+cont.SBQQ__AmendmentOpportunities__r);
                if(cont.SBQQ__AmendmentOpportunities__r != null && cont.SBQQ__AmendmentOpportunities__r.size() > 0 ){
                    if(cont.SBQQ__AmendmentOpportunities__r.size() == 1){
                        idSetForAmbedmentQuote2.add(cont.Id);
                    } else{
                        lastOppMap.put(cont.SBQQ__AmendmentOpportunities__r[1].Id , cont.SBQQ__AmendmentOpportunities__r[0]);
                        newOppMap.put(cont.SBQQ__AmendmentOpportunities__r[0].Id , cont.SBQQ__AmendmentOpportunities__r[1]);
                    }                    
                }
            }
            if(idSetForAmbedmentQuote2 != null && idSetForAmbedmentQuote2.size() > 0){
                List <SBQQ__QuoteLine__c> qlList =  [SELECT Id ,
                                                     SBQQ__Product__c ,
                                                     SBQQ__Quote__r.SBQQ__Account__c,
                                                     SBQQ__ListPrice__c,
                                                     SBQQ__Quote__r.SBQQ__StartDate__c,
                                                     SBQQ__Quote__r.SBQQ__EndDate__c,
                                                     
                                                     (SELECT id FROM Plant_Product_Transactions__r)
                                                     FROM SBQQ__QuoteLine__c 
                                                     WHERE SBQQ__Quote__r.SBQQ__Type__c = 'Amendment'
                                                     //AND SBQQ__Quote__r.SBQQ__Primary__c=true
                                                     AND SBQQ__Quote__r.SBQQ__MasterContract__c != null 
                                                     AND SBQQ__Quote__r.SBQQ__MasterContract__c in :idSetForAmbedmentQuote2
                                                     AND SBQQ__Product__c != null LIMIT 50000];
                if(qlList != null && qlList.size() > 0){
                    system.debug('qlList---'+qlList);        
                    AmendmentQuoteProcessHelper.createPPTunderAmbededQL(qlList);
                 }
            }
            
            if(newOppMap != null && newOppMap.size() > 0){
                system.debug('newOppMap--'+newOppMap);
                system.debug('lastOppMap--'+lastOppMap);
                AmendmentQuoteProcessHelper.createPPTunderAmbededQLRevised(lastOppMap , newOppMap);
            }
            
            
        }
           
    }
    
}