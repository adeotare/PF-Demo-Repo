public class RemoveCustomerAccountHierarchy {
    @InvocableMethod(label='Remove Account in Hierarchy for Customer type' description='uncheck the checkbox for all accounts in hierachy')
    public static void removeCustomerTypeInAccountHiereachy(List<Id> accIds){
        Id ultimateAccountId = UpdateCustomerAccountHierarchy.getUltParentId(accIds[0]);
        Account[] allChildren = new Account[] {};
        boolean isChildCustomerType = false;
        String accountCustomerType = [select Type from Account where id=:ultimateAccountId].Type;
        if(accountCustomerType == 'Customer'){
            isChildCustomerType = true;
        }
        if(ultimateAccountId != null){
            Set<Id> parentIds = new Set<Id>{ultimateAccountId};
            Account[] children;
            Integer cntr;
            do {
                children = [select Id, Name, Type from Account where ParentId in :parentIds];
                allChildren.addAll(children);
                parentIds.clear();
                for (Account child : children) {
                    if(child.Type == 'Customer'){
                        isChildCustomerType = true;
                        break;
                    }
                    parentIds.add(child.Id);
                }
            } while (children.size() > 0);
        }
        Account[] acctsToUpdates = new List<Account>();
        
        if(allChildren.size()>0 && isChildCustomerType == false){
            allChildren.add(new Account(Id = ultimateAccountId));
            for (Account childRecord : allChildren){
				childRecord.Account_in_Hierarchy_is_Customer__c = false;               
                acctsToUpdates.add(childRecord);
            }
            if(acctsToUpdates.size()>0){
                system.debug('------acctsToUpdates------'+acctsToUpdates);
                update acctsToUpdates;
            }
        }
    }
}