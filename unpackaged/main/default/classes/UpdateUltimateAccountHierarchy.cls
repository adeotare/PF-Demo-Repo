public class UpdateUltimateAccountHierarchy {
    @InvocableMethod(label='Update Ultimate Account in hierarchy' description='Check and Update Ultimate Account in hierachy')
    public static void updateUltimateAccountInHiereachy(List<Id> accIds){
		Account[] acctsToUpdates = new List<Account>();
		
		List<Account> currentAccountDetails = [select ParentId, Ultimate_Parent_Account__c from Account where Id=:accIds[0]];
		if(currentAccountDetails.size() > 0 ){
			if(currentAccountDetails[0].ParentId == null){
				// Update current account as ultimate account Ultimate_Parent__c
				List<Account> childAccounts = getChildAccounts(accIds[0]);
				if(childAccounts.size()>0){
					for (Account childRecord : childAccounts){
						childRecord.Ultimate_Parent_Account__c = accIds[0];
                        //childRecord.Uses_MSA_of__c = accIds[0];
						childRecord.Ultimate_Parent__c = false;					
						acctsToUpdates.add(childRecord);
					}
				}
				//add ultimate account details to update 
				acctsToUpdates.add(new Account(Id = accIds[0], Ultimate_Parent__c = true, Ultimate_Parent_Account__c=null));
					
				if(acctsToUpdates.size()>0){
					system.debug('------acctsToUpdates--ParentId == null----'+acctsToUpdates);
					update acctsToUpdates;
				}
				
			}
			if(currentAccountDetails[0].ParentId != null){
				Id ultimateAccountId = UpdateCustomerAccountHierarchy.getUltParentId(accIds[0]);
				List<Account> childAccounts = getChildAccounts(ultimateAccountId);
				system.debug('ultimateAccountId-->'+ultimateAccountId);
				if(childAccounts.size()>0){
					for (Account childRecord : childAccounts){
						childRecord.Ultimate_Parent_Account__c = ultimateAccountId;
                        //childRecord.Uses_MSA_of__c = ultimateAccountId;
						childRecord.Ultimate_Parent__c = false;					
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
				children = [select Id, Name from Account where ParentId in :parentIds];
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