trigger ContractTrigger on Contract (after update) {
    if(Trigger.isAfter){
        if(Trigger.isUpdate){
            ContractTriggerHandler.manageParentRenQuote(Trigger.newMap, Trigger.oldMap);
        }
    }
}