public class SoftwareDiscountTier {

    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchAccountName(String RecId){
        System.debug('Discount tier fetchAccountName');
        return [Select Account_Name__r.Name from MSA_Contract__c where Id = :RecId];
    }
    

    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchCurrency(String RecId){
        System.debug('ESoftware Discount Tier fetchCurrency');
        return [Select CurrencyIsoCode from MSA_Contract__c where Id = :RecId];
    }


    @AuraEnabled(cacheable=true)
    public static List<MSA_Software_Discount_Tier_Price__c> fetchSoftwareListPriceData(String RecId){
        List<MSA_Contract__c> accountId = [Select Account_Name__c from MSA_Contract__c where Id = :RecId limit 1];
        Id accId = string.valueOf(accountId[0].Account_Name__c);
        List<MSA_Software_Discount_Tier_Price__c> records = [Select Id, Account__r.Name, Product__r.Name, Pricing_Tier__c, Cross_Orders__c, Lower_Bound__c, Upper_Bound__c, Discount_Amount__c, Effective_Start_Date__c,  Effective_End_Date__c
            from MSA_Software_Discount_Tier_Price__c 
            where Account__r.Id = :accId ];
        system.debug('Account ID' + accId);
        system.debug('No of records found with contracted price =>' + records.size());
        return records;
    }


}