public class UpdateCustomerAccountHierarchy {
    @InvocableMethod(label='Update Account in Hierarchy for Customer type' description='Check the checkbox for all accounts in hierachy')
    public static void updateCustomerTypeInAccountHiereachy(List<Id> accIds){
        Id ultimateAccountId = getUltParentId(accIds[0]);
        Account[] allChildren = new Account[] {};
        if(ultimateAccountId != null){
            Set<Id> parentIds = new Set<Id>{ultimateAccountId};
            Account[] children;
            Integer cntr;
            do {
                children = [select Id, Name from Account where ParentId in :parentIds];
                allChildren.addAll(children);
                parentIds.clear();
                for (Account child : children) {
                parentIds.add(child.Id);
                }
            } while (children.size() > 0);
        }
        Account[] acctsToUpdates = new List<Account>();
        
        if(allChildren.size()>0){
            allChildren.add(new Account(Id = ultimateAccountId));
            for (Account childRecord : allChildren){
				childRecord.Account_in_Hierarchy_is_Customer__c = true;               
                acctsToUpdates.add(childRecord);
            }
        }
        if(acctsToUpdates.size()>0){
            system.debug('------acctsToUpdates------'+acctsToUpdates);
            update acctsToUpdates;
        }
    }
    
    public static Id getUltParentId( Id accid ){
        Boolean topLevelParent = false;
        while ( !topLevelParent ) {
            Account a = [ Select Id,ParentId From Account where Id =: accid limit 1 ];
            if ( a.ParentID != null ) {
                accid = a.ParentID;
            }
            else {
                topLevelParent = true;
            }
        }
        system.debug('11111111'+accid);
        return accid ; // This returns the utltimate parentid for an account
    }
}