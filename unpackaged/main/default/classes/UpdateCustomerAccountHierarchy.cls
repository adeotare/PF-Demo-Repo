public class UpdateCustomerAccountHierarchy {
    @InvocableMethod(label='Update Account in Hierarchy for Customer type' description='Check the checkbox for all accounts in hierachy')
    public static void updateCustomerTypeInAccountHiereachy(List<Id> accIds){
        Id ultimateAccountId = getUltParentId(accIds[0]);
        List<Account> ultimateAccountDetails = [select ParentId, Ultimate_Parent_Account__c,Type from Account where Id=:ultimateAccountId];
        Account[] allChildren = new Account[] {};
        if(ultimateAccountId != null){
            Set<Id> parentIds = new Set<Id>{ultimateAccountId};
            Account[] children;
            Integer cntr;
            do {
                children = [select Id, Name, type from Account where ParentId in :parentIds];
                allChildren.addAll(children);
                parentIds.clear();
                for (Account child : children) {
                parentIds.add(child.Id);
                }
            } while (children.size() > 0);
        }
        Account[] acctsToUpdates = new List<Account>();
        Boolean CustomerAccount = false;
        if(ultimateAccountDetails[0].type == 'Customer'){
            CustomerAccount = true;
        }
        
        if(allChildren.size()>0){
            for (Account childRec : allChildren){
                if(childRec.Type == 'Customer'){
                    CustomerAccount = true;
                }
             }
            allChildren.add(new Account(Id = ultimateAccountId));
            for (Account childRecord : allChildren){
                if(CustomerAccount){
                    childRecord.Account_in_Hierarchy_is_Customer__c = true; 
                } else {
                    childRecord.Account_in_Hierarchy_is_Customer__c = false; 
                }     
                acctsToUpdates.add(childRecord);
            }
        } else {
            if(ultimateAccountId != null){
                allChildren.add(new Account(Id = ultimateAccountId));
                for (Account childRecord : allChildren){
                    if(ultimateAccountDetails[0].type == 'Customer'){
                    	childRecord.Account_in_Hierarchy_is_Customer__c = true; 
                    } else {
                        childRecord.Account_in_Hierarchy_is_Customer__c = false;
                    }
                    acctsToUpdates.add(childRecord);
                }
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