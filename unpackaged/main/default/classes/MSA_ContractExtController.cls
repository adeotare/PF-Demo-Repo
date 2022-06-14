public with sharing class MSA_ContractExtController { 
    private Id MSA_ContractId; 
    public MSA_ContractExtController(ApexPages.StandardController stdController) { 
        MSA_ContractId = stdController.getId(); 
    } 
    public PageReference onSubmit() { 
        if (MSA_ContractId != null) { 
            SBAA.ApprovalAPI.submit(MSA_ContractId, SBAA__Approval__c.MSA_Contract__c); 
        } 
        return new PageReference('/' + MSA_ContractId); 
    } 
    public PageReference onRecall() { 
        if (MSA_ContractId != null) { 
            SBAA.ApprovalAPI.recall(MSA_ContractId, SBAA__Approval__c.MSA_Contract__c); 
        } 
        return new PageReference('/' + MSA_ContractId); 
    } 
}