public class AccountForMSAContractedPrices {
    
    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchAccountName(String RecId){
        System.debug('Entered function fetchAccountName');
        return [Select Account_Name__r.Name from MSA_Contract__c where Id = :RecId];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchCurrency(String RecId){
        System.debug('Entered function fetchCurrency');
        return [Select CurrencyIsoCode from MSA_Contract__c where Id = :RecId];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchPriceBook(String RecId){
        System.debug('Entered function fetchPriceBook');
        return [Select Account_Name__r.Account_Price_Book__r.Name from MSA_Contract__c where Id = :RecId];
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<SBQQ__ContractedPrice__c> contractedPricesRecord(String RecId){
        List<MSA_Contract__c> accountId = [Select Account_Name__r.Account_Price_Book__r.name from MSA_Contract__c where Id = :RecId limit 1];
        Id accId = string.valueOf(accountId[0].Account_Name__c);
        List<SBQQ__ContractedPrice__c> records = [Select SBQQ__Product__r.Name, SBQQ__Product__r.ProductCode , Product_List_Price__c, SBQQ__Price__c 
            from SBQQ__ContractedPrice__c 
            where SBQQ__Account__r.Id = :accId AND Same_As_List_Price__c = False AND SBQQ__Product__r.ProductCode != null];
        system.debug('Account ID' + accId);
        system.debug('No of records found with contracted price =>' + records.size());
        return records;
    }


    @AuraEnabled(cacheable=true)
    public static List<SBQQ__ContractedPrice__c> priceBookRecords(String RecId){

        List<MSA_Contract__c> accountId = [Select Account_Name__r.Account_Price_Book__r.name from MSA_Contract__c where Id = :RecId limit 1];
        Id accId = string.valueOf(accountId[0].Account_Name__c);
        List<SBQQ__ContractedPrice__c> records = [Select SBQQ__Product__r.Name, Same_As_List_Price__c, SBQQ__Product__r.ProductCode , Product_List_Price__c, SBQQ__Price__c 
            from SBQQ__ContractedPrice__c 
            where SBQQ__Account__r.Id = :accId AND Same_As_List_Price__c = True];
        system.debug('Account ID' + accId);
        system.debug('No of records found with contracted price =>' + records.size());
        return records;

    }


    @AuraEnabled
    public static string updateContractedPrices(Object data) {
    List<SBQQ__ContractedPrice__c> contractPriceForUpdate = new List<SBQQ__ContractedPrice__c>();
    List<SBQQ__ContractedPrice__c> contractPriceDataList = (List<SBQQ__ContractedPrice__c>) JSON.deserialize(
         JSON.serialize(data),
         List<SBQQ__ContractedPrice__c>.class
            );
            Set<ID> contactedPRiceIdSet = new Set<id>();
            Map<Id, SBQQ__ContractedPrice__c> contractedPriceDataMap = new Map<Id,SBQQ__ContractedPrice__c>(); 
            for(SBQQ__ContractedPrice__c conPrice: contractPriceDataList){
                contactedPRiceIdSet.add(conPrice.Id);
                contractedPriceDataMap.put(conPrice.Id, conPrice);
            }
            List<SBQQ__ContractedPrice__c> contractedPriceList = [Select id, Product_List_Price__c from SBQQ__ContractedPrice__c where id in:contactedPRiceIdSet ];
            for(SBQQ__ContractedPrice__c conPriceRec: contractedPriceList){
                if(conPriceRec.Product_List_Price__c != contractedPriceDataMap.get(conPriceRec.Id).SBQQ__Price__c){
                   contractPriceForUpdate.add(contractedPriceDataMap.get(conPriceRec.Id));
                }
            }
            system.debug('Contracted Price Record=>' + contractPriceForUpdate);
            try {
                update contractPriceForUpdate;
                return 'Success: Contracted Prices updated successfully';
                }
            catch (Exception e) {
                return 'The following exception has occurred: ' + e.getMessage();
                }
    }


        @AuraEnabled 
		public static void deleteContractedPrice(List<SBQQ__ContractedPrice__c> cpList, String msaId){
            if (cpList.size()>0)
            {
                List<SBQQ__ContractedPrice__c> lstSelectedContractedRecords = new List<SBQQ__ContractedPrice__c>();

                for(SBQQ__ContractedPrice__c cps :cpList )
                {
                    if(cps.SBQQ__Price__c != cps.Product_List_Price__c){
                        cps.SBQQ__Price__c = cps.Product_List_Price__c;
                        cps.Same_As_List_Price__c = True;
                        lstSelectedContractedRecords.add(cps);
                    }
                }
                System.debug('Cp list : '+cpList);
                if(lstSelectedContractedRecords.size()>0)
                {
                    update lstSelectedContractedRecords;
                }
            }

        }

}