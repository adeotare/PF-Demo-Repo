trigger Updaterfidetail on RFI_Detail__c (before insert, before update, after insert, after update) {
    for(RFI_Detail__c rfi : Trigger.new){
        if(trigger.isBefore && trigger.isInsert){
            //rfi.RFI_Item_Status__c = 'Submitted – Pending Customer Review';
/*            if(rfi.Missing_Incomplete_Category__c != null){
                System.debug('tt' +rfi.Missing_Incomplete_Category__r.Name);
               rfi.Name =  rfi.Missing_Incomplete_Category__r.Name;
            } else{
                 System.debug('tt' +rfi.Incorrect_Category__c);
              rfi.name=  rfi.Incorrect_Category__r.Name;
            }*/
        }
    }
    
    if(trigger.isAfter && trigger.isInsert){
    
    list<RFI_Detail__c> rfiDetailLIst = new list<RFI_Detail__c >();
        updateRFIstatus.getrfidetails(Trigger.new);
        
    }
    if(trigger.isAfter && trigger.isUpdate){
        list<Id> itemId = new list<Id>();
            for( Id rfiitemId : Trigger.newMap.keySet()){
            if((Trigger.oldMap.get( rfiitemId ).RFI_Item_Status__c != Trigger.newMap.get( rfiitemId ).RFI_Item_Status__c) ||
               (Trigger.oldMap.get( rfiitemId ).Implementation_Blocked__c != Trigger.newMap.get( rfiitemId ).Implementation_Blocked__c)){
                  itemId.add(rfiitemId);
              
            }
        }
        if(itemId != null){
           list<RFI_Detail__c> updatelist = [SELECT Id,RAID__c,Name,RFI_Item_Status__c,RFI_Detail_Description__c,Cancel_Cannot_Complete_Description__c,Customer_Comments__c,
                                             Implementation_Blocked__c, Onsite_Remediation_Required__c, Onsite_Remediation_Description__c from RFI_Detail__c Where Id IN :itemId];
            list<Id> idLst = new list<Id>();
            for(RFI_Detail__c  querId: updatelist ){
                idLst.add(querId.Id);
            }
            system.debug('Query handler--->' +idLst);
            system.debug('Trigger handler--->' +itemId);
            updateRFIstatus.getrfidetails(updatelist); 
        }
    }
}