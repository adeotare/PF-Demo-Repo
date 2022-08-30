public class AccountForMSAContractedPrices {
    
    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchAccountName(String RecId){
        System.debug('Entered function fetchAccountName');
        return [Select Account_Name__r.Name from MSA_Contract__c where Id = :RecId];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchCurrency(String RecId){
        System.debug('Entered function fetchCurrency');
        return [Select Account_Name__r.CurrencyIsoCode from MSA_Contract__c where Id = :RecId];
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

        //formContractedPrice(accId,accountId[0].id);

        system.debug('-----after cp creation-------');
        List<SBQQ__ContractedPrice__c> records = [Select SBQQ__Product__r.Name,SBQQ__Product__r.IsActive,SBQQ__Product__r.ProductCode , Product_List_Price__c, SBQQ__Price__c 
            from SBQQ__ContractedPrice__c 
            where SBQQ__Account__r.Id = :accId AND Same_As_List_Price__c = False AND SBQQ__Product__r.ProductCode != null AND SBQQ__Product__r.IsActive=true];
        system.debug('Account ID' + accId);
        system.debug('No of records found with contracted price =>' + records.size());
        return records;
    }
    
    @AuraEnabled   
    public static string createNewContractPrice(String msaRecId){
        system.debug('----RecId-dd--'+msaRecId);  
               
        
//        CreateMSAContractPriceBatchProcess obj = new CreateMSAContractPriceBatchProcess(msaRecId);
//		Database.executeBatch(obj,10);
        
        //  List<MSA_Contract__c> msaContract = [Select Account_Name__r.Account_Price_Book__r.name from MSA_Contract__c where Id = :msaRecId limit 1];
//        Id accId = string.valueOf(msaContract[0].Account_Name__c);

        list<PricebookEntry>priceBookEntryList = new list<PricebookEntry>();
        map<string,Account>priceBookWithAccountMap = new map<string,Account>();

        set<id>priceBookIdSet = new set<id>();
        set<string>accountCurrency = new set<string>();
        list<Account>accountUpdate = new list<Account>();
        set<id>AccountIdSet = new set<id>();
        for(Account accountInfo : [Select id,Name,Account_Price_Book__c,CurrencyIsoCode,isContractPriceCreated__c,Uses_MSA_of__c from Account
                                     where Uses_MSA_of__c =: msaRecId AND  Account_Price_Book__c != null AND isContractPriceCreated__c = false]){
                                         system.debug('---accountInfo---'+accountInfo);

                                    priceBookIdSet.add(accountInfo.Account_Price_Book__c);
                                    accountCurrency.add(accountInfo.CurrencyIsoCode);
                                    string accountMapKey = accountInfo.Account_Price_Book__c + '-' + accountInfo.CurrencyIsoCode + '*' + accountInfo.Id;
                                    accountInfo.isContractPriceCreated__c = true;
                                    accountUpdate.add(accountInfo);
                                    priceBookWithAccountMap.put(accountMapKey,accountInfo);
        }   
        /*set<id>removeProductSet = new set<Id>();
        for(QS_Customer_Asset__c purchaseProduct : [Select id,Name,QS_Product__c from QS_Customer_Asset__c where QS_Account__c IN : AccountIdSet AND QS_New_Asset_Status__c = 'Active']){
            removeProductSet.add(purchaseProduct.QS_Product__c);
        } */    
        
        map<string,list<PricebookEntry>>priceBookWithPriceBookEntryMap = new map<string,list<PricebookEntry>>();
        for(PricebookEntry PBE : [Select id,UnitPrice,Pricebook2Id,CurrencyIsoCode,Product2Id,ProductCode 
                                 from PricebookEntry where Pricebook2Id IN : priceBookIdSet AND Product2.Product_Category__c =: Label.Product_Category AND CurrencyIsoCode IN : accountCurrency] ){
                                system.debug('---PBE---'+PBE);
                                string pricebookEntryKey = PBE.Pricebook2Id + '-' + PBE.CurrencyIsoCode;

                                list<PricebookEntry>pricebookEntryDataList;
                                if(priceBookWithPriceBookEntryMap.containskey(pricebookEntryKey)){
                                    pricebookEntryDataList = priceBookWithPriceBookEntryMap.get(pricebookEntryKey);
                                    pricebookEntryDataList.add(PBE);
                                }
                                else{
                                    pricebookEntryDataList = new list<PricebookEntry>();
                                    pricebookEntryDataList.add(PBE);
                                }
                                priceBookWithPriceBookEntryMap.put(pricebookEntryKey,pricebookEntryDataList);

        }    
        system.debug('---priceBookWithPriceBookEntryMap---'+priceBookWithPriceBookEntryMap);
        list<SBQQ__ContractedPrice__c>insertContractedPriceList = new list<SBQQ__ContractedPrice__c>();
        if(!priceBookWithAccountMap.isEmpty() && !priceBookWithPriceBookEntryMap.isEmpty()){
            for(string keySplit : priceBookWithAccountMap.keyset()){
                string[] keyValue = keySplit.split('\\*');

                if(priceBookWithPriceBookEntryMap.containskey(keyValue[0])){
                    list<PricebookEntry>getpriceBookEntryList = priceBookWithPriceBookEntryMap.get(keyValue[0]);
                    Account accountData = priceBookWithAccountMap.get(keySplit);
                    if(getpriceBookEntryList.size() > 0 && getpriceBookEntryList != null){
                        for(PricebookEntry priceBookEntry : getpriceBookEntryList){  
                            

                            SBQQ__ContractedPrice__c cp = new SBQQ__ContractedPrice__c();
                            cp.SBQQ__Account__c	        = keyValue[1];
                            cp.SBQQ__Product__c         = priceBookEntry.Product2Id;
                            cp.SBQQ__Price__c	        = priceBookEntry.UnitPrice;
                            cp.CurrencyIsoCode          = accountData.CurrencyIsoCode;
                            cp.Same_As_List_Price__c    = true;
                            cp.SBQQ__NonDiscountable__c = false;
                            cp.Product_List_Price__c    = priceBookEntry.UnitPrice;
                            cp.MSA_Contract__c          = msaRecId;

                            insertContractedPriceList.add(cp);                            
                        }               
                    }
                }
            }
            
        }
        system.debug('-----insertContractedPriceList-size---'+insertContractedPriceList);
        system.debug('-----insertContractedPriceList----'+insertContractedPriceList.size());
       
       
        if(insertContractedPriceList != null && insertContractedPriceList.size() > 0){
            insert insertContractedPriceList;
        }
        if(accountUpdate != null && accountUpdate.size() > 0){
            system.debug('--accountUpdate--'+accountUpdate.size());
            update accountUpdate;
        }
        else{
            return 'Contracted Price has already been created for this account!';
        }
        return 'Inserting Contract Prices !';
        
    }

    @AuraEnabled(cacheable=true)
    public static List<SBQQ__ContractedPrice__c> priceBookRecords(String RecId){

        List<MSA_Contract__c> accountId = [Select Account_Name__r.Account_Price_Book__r.name from MSA_Contract__c where Id = :RecId limit 1];
        Id accId = string.valueOf(accountId[0].Account_Name__c);
        
        List<SBQQ__ContractedPrice__c> records = [Select SBQQ__Product__r.Name,SBQQ__Product__r.IsActive, Same_As_List_Price__c, SBQQ__Product__r.ProductCode , Product_List_Price__c, SBQQ__Price__c 
            from SBQQ__ContractedPrice__c 
            where SBQQ__Account__r.Id = :accId AND Same_As_List_Price__c = True AND SBQQ__Product__r.Product_Category__c = 'Software' AND SBQQ__Product__r.IsActive=true];
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
            catch (DmlException e) {
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