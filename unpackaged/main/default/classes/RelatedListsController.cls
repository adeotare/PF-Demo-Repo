/**
 * @description       :
 * @author            : Justin Smith @cyberjus
 * @group             :
 * @last modified on  : 08-31-2022
 * @last modified by  : Justin Smith @cyberjus
 **/
public with sharing class RelatedListsController {
  @AuraEnabled(cacheable=true)
  public static List<Plant_Product_Transaction__c> getPlantProductTransactionsByAccount(
    Id accountId,
    Integer recordCount,
    String search
  ) {
    try {
      String target;
      String soql = 'select Id, Name, Plant__c, ';
      soql += 'Plant_Name__c, Product__c, Product__r.Name, End_Date__c, Contract__c, Contract__r.ContractNumber ';
      soql += 'from Plant_Product_Transaction__c where Account__c = :accountId ';
      soql += 'and Status__c = \'Contracted\' and End_Date__c >= TODAY ';
      if (!String.isBlank(search)) {
        target = '%' + search + '%';
        soql += 'and (Plant_Name__c LIKE :target OR Product__r.Name LIKE :target OR Contract__r.ContractNumber LIKE :target) ';
      }
      soql += 'order by Plant_Name__c limit :recordCount';

      return (List<Plant_Product_Transaction__c>) Database.query(soql);
    } catch (Exception e) {
      System.debug(e.getStackTraceString());    
      throw new AuraHandledException(e.getMessage());
    }
  }
}