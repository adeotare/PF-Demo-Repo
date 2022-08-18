public class UpdateUltimateAccountHierarchy {
    @InvocableMethod(label='Update Ultimate Account in hierarchy' description='Check and Update Ultimate Account in hierachy')
    public static void updateUltimateAccountInHiereachy(List<Id> accIds){
		Account[] acctsToUpdates = new List<Account>();
		
		List<Account> currentAccountDetails = [select ParentId, Ultimate_Parent_Account__c,Type from Account where Id=:accIds[0]];
		if(currentAccountDetails.size() > 0 ){
			if(currentAccountDetails[0].ParentId == null){
				// Update current account as ultimate account Ultimate_Parent__c
				List<Account> childAccounts = getChildAccounts(accIds[0]);
                Boolean CustomerAccount = false;
				if(childAccounts.size()>0){
                    for (Account childRec : childAccounts){
                        if(childRec.Type == 'Customer'){
                            CustomerAccount = true;
                        }
                    }
					for (Account childRecord : childAccounts){
						childRecord.Ultimate_Parent_Account__c = accIds[0];
                        //childRecord.Uses_MSA_of__c = accIds[0];
						childRecord.Ultimate_Parent__c = false;	
                        if(CustomerAccount){
                            childRecord.Account_in_Hierarchy_is_Customer__c = true; 
                        } else {
                            childRecord.Account_in_Hierarchy_is_Customer__c = false; 
                        }
						acctsToUpdates.add(childRecord);
					}
				}
				//add ultimate account details to update 
                if(currentAccountDetails[0].Type == 'Customer'){
                   	acctsToUpdates.add(new Account(Id = accIds[0],Account_in_Hierarchy_is_Customer__c = true, Ultimate_Parent__c = true, Ultimate_Parent_Account__c=null)); 
                } else {
					acctsToUpdates.add(new Account(Id = accIds[0], Ultimate_Parent__c = true, Ultimate_Parent_Account__c=null));
				}	
				if(acctsToUpdates.size()>0){
					system.debug('------acctsToUpdates--ParentId == null----'+acctsToUpdates);
					update acctsToUpdates;
				}
				
			}
			if(currentAccountDetails[0].ParentId != null){
				Id ultimateAccountId = UpdateCustomerAccountHierarchy.getUltParentId(accIds[0]);
                List<Account> ultimateAccountDetails = [select ParentId, Ultimate_Parent_Account__c,Type from Account where Id=:ultimateAccountId];
				List<Account> childAccounts = getChildAccounts(ultimateAccountId);
                Boolean CustomerAccount = false;
                if(ultimateAccountDetails[0].type == 'Customer'){
                    CustomerAccount = true;
                }
				system.debug('ultimateAccountId-->'+ultimateAccountId);
				if(childAccounts.size()>0){
                    for (Account childRec : childAccounts){
                        if(childRec.Type == 'Customer'){
                            CustomerAccount = true;
                        }
                    }
					for (Account childRecord : childAccounts){
						childRecord.Ultimate_Parent_Account__c = ultimateAccountId;
                        //childRecord.Uses_MSA_of__c = ultimateAccountId;
						childRecord.Ultimate_Parent__c = false;	
                        if(CustomerAccount){
                            childRecord.Account_in_Hierarchy_is_Customer__c = true; 
                        } else {
                            childRecord.Account_in_Hierarchy_is_Customer__c = false; 
                        }
						acctsToUpdates.add(childRecord);
					}
				}
				//add ultimate account details to update 
					//acctsToUpdates.add(new Account(Id = ultimateAccountId, Ultimate_Parent__c = true, Ultimate_Parent_Account__c=null));
				if(acctsToUpdates.size()>0){
					system.debug('------acctsToUpdates--ParentId != null----'+acctsToUpdates);
					update acctsToUpdates;
				}
			}
		}
    }
	
	public static List<Account> getChildAccounts(Id accid){
		Account[] allChildren = new Account[] {};
		if(accid != null){
			Set<Id> parentIds = new Set<Id>{accid};
			Account[] children;
			Integer cntr;
			do {
				children = [select Id, Name,Type from Account where ParentId in :parentIds];
				allChildren.addAll(children);
				parentIds.clear();
				for (Account child : children) {
				parentIds.add(child.Id);
				}
			} while (children.size() > 0);
		}
		return allChildren;
	}
}