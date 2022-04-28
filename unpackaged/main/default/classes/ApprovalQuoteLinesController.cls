/**
*@description Class ApprovalQuoteLinesController
*/
public with sharing class ApprovalQuoteLinesController
{ 
/**
*@param quoteId 
*@param quotelines 
*/
    public static String quoteId {get; set;} 
    
    public static List<SBQQ__QuoteLine__c> quotelines {
        get
        {
            return [select Id,
                    SBQQ__ProductCode__c,
                    SBQQ__ProductName__c,
                    SBQQ__Quantity__c,
                    SBQQ__ListPrice__c,
                    SBQQ__Discount__c,
                    SBQQ__NetTotal__c,
                    CurrencyIsoCode 
                    from SBQQ__QuoteLine__c 
                    where SBQQ__Quote__c= : quoteId ];
        }
    }      
}