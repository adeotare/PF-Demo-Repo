public with sharing class wrapperForChangeMassPF {
    @AuraEnabled public RFI_Detail__c lstRfiDetails{get;set;}
    @AuraEnabled public String selOptionOwner {get;set;}
    
    public wrapperForChangeMassPF() {
        lstRfiDetails = new RFI_Detail__c();
    }
    
}