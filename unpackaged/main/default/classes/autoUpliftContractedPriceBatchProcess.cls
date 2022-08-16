global class autoUpliftContractedPriceBatchProcess implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        // collect the batches of records or objects to be passed to execute
        String query = 'Select Id,Name,Account_Name__c, Account_Name__r.Name,Annual_Uplift_Percentage__c, MSA_Status__c, MSA_Start_Date__c  from MSA_Contract__c  where MSA_Status__c =\'Approved\' AND  Annual_Uplift_Percentage__c != null ';

        system.debug('==soql.Value__c='+query);
       
       
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<MSA_Contract__c> msaContractList) {
        set<id>accountIdSet = new set<id>();
        map<id,MSA_Contract__c>accIdWithMSAContractMap = new map<id,MSA_Contract__c>();
        for(MSA_Contract__c msa : msaContractList){
            system.debug('----msaContractList----'+msaContractList);
            integer yearDifference =   date.today().Year() - msa.MSA_Start_Date__c.Year();
                    system.debug('----yearDifference----'+yearDifference  );
            date msaDate = msa.MSA_Start_Date__c.addYears(yearDifference);
                    system.debug('---msaDate----'+msaDate);

            if(msaDate == date.today()){
                accountIdSet.add(msa.Account_Name__c);
                accIdWithMSAContractMap.put(msa.Account_Name__c,msa);            
            }
        }
        system.debug('----accIdWithMSAContractMap---'+accIdWithMSAContractMap);
        map<id,list<SBQQ__ContractedPrice__c>> accIdWithContractPriceListMap = new map<id,list<SBQQ__ContractedPrice__c>>();
        //Fetching Contracted Price assoicated to MSA Contract Account
        for(SBQQ__ContractedPrice__c contractedPrice : [Select id,Name,SBQQ__Price__c,SBQQ__Account__c,Same_As_List_Price__c,SBQQ__Account__r.Name,SBQQ__Product__c,SBQQ__Product__r.Name
                                                         from SBQQ__ContractedPrice__c where SBQQ__Account__c IN : accountIdSet AND SBQQ__Product__r.IsActive = true AND SBQQ__Price__c != null ]){
                                            system.debug('--SBQQ__Price__c--'+contractedPrice.SBQQ__Price__c);
                                            system.debug('--SBQQ__Price__c-id-'+contractedPrice);            
                                            list<SBQQ__ContractedPrice__c>contractPriceList;
                                            if(!accIdWithContractPriceListMap.isEmpty() && accIdWithContractPriceListMap.containskey(contractedPrice.SBQQ__Account__c)){
                                                contractPriceList = accIdWithContractPriceListMap.get(contractedPrice.SBQQ__Account__c);
                                                contractPriceList.add(contractedPrice);
                                            }
                                            else{
                                                contractPriceList = new list<SBQQ__ContractedPrice__c>();
                                                contractPriceList.add(contractedPrice);
                                            }
                                            accIdWithContractPriceListMap.put(contractedPrice.SBQQ__Account__c,contractPriceList);

        }
        list<SBQQ__ContractedPrice__c>updateContractPriceList = new list<SBQQ__ContractedPrice__c>();
        if(!accIdWithMSAContractMap.isEmpty() && !accIdWithContractPriceListMap.isEmpty()){
            for(id accId : accIdWithMSAContractMap.keyset()){
                MSA_Contract__c MSAContractVal = accIdWithMSAContractMap.get(accId);
                for(SBQQ__ContractedPrice__c contractPriceVal: accIdWithContractPriceListMap.get(accId)){
                    //calculating uplifting percent value in contract price
                    system.debug('---MSAContractVal.Annual_Uplift_Percentage__c---'+MSAContractVal.Annual_Uplift_Percentage__c);
                    system.debug('----contractPriceVal.SBQQ__Price__c ---'+contractPriceVal.SBQQ__Price__c );
                    contractPriceVal.SBQQ__Price__c += ((MSAContractVal.Annual_Uplift_Percentage__c * contractPriceVal.SBQQ__Price__c)/100 ) ;
 
                    updateContractPriceList.add(contractPriceVal);
                   
                }
            }
        }
        if(updateContractPriceList != null && updateContractPriceList.size() > 0){
            system.debug('---updateContractPriceList---'+updateContractPriceList);
            update updateContractPriceList;
        }
        
    }

    global void finish(Database.BatchableContext BC) {
        
    }
}