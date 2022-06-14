public class ImplementationBracketPrice {

    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchAccountName(String RecId){
        System.debug('Implementation Bracket fetchAccountName');
        return [Select Account_Name__r.Name from MSA_Contract__c where Id = :RecId];
    }
    

    @AuraEnabled(cacheable=true)
    public static List<MSA_Contract__c> fetchCurrency(String RecId){
        System.debug('Implementation Bracket fetchCurrency');
        return [Select CurrencyIsoCode from MSA_Contract__c where Id = :RecId];
    }


    @AuraEnabled(cacheable=true)
    public static List<MSA_Implementation_Bracket_Price__c> implementationBracketPriceRecords(String RecId){
        List<MSA_Contract__c> accountId = [Select Account_Name__r.Account_Price_Book__r.name from MSA_Contract__c where Id = :RecId limit 1];
        Id accId = string.valueOf(accountId[0].Account_Name__c);
        List<MSA_Implementation_Bracket_Price__c> records = [Select Name , Lower_Bound__c, Upper_Bound__c, Pricing_Tier__c, Fixed_Price__c, Asset_Class__c, Description__c 
            from MSA_Implementation_Bracket_Price__c 
            where Account__r.Id = :accId];
        system.debug('Account ID' + accId);
        system.debug('No of records found with contracted price =>' + records.size());
        return records;
    }
    
}