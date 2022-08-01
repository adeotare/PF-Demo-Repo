/*
*CA2_SubcriptionTriggerHandler
Description: Creates Customer Assets from Subscription line items on the Quote
*/



public class CA2_SubscriptionTriggerHandler extends CA2_TriggerHandler {    
    Date dt = System.today();
    @TestVisible
    protected override void afterInsert(){
        if(!CA2_CustomerAssetUtil.ByPassTrigger){
            createCustomerAssets(trigger.new);
        }
        
        
    }
    @TestVisible
    protected override void afterUpdate() {
        if(CA2_CustomerAssetUtil.Create_CA_On_Update){
            createCustomerAssets(trigger.new);
        }
        
    }
    @TestVisible
    private Map<Id, SBQQ__Subscription__c> subsWithRelated {get {
        if(subsWithRelated == null) {
            subsWithRelated = new Map<Id, SBQQ__Subscription__c>([SELECT Id,QS_Booking_Date__c,QS_Secondary_Account_Id__c,QS_Customer_Asset_Account_Id__c,SBQQ__TerminatedDate__c, SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.QS_Decommission_Reason__c 
                                                                  FROM SBQQ__Subscription__c
                                                                  WHERE Id IN: Trigger.new]);
        }
        return subsWithRelated;
    } set;}
    
    public static boolean bypass = false;
    public void createCustomerAssets(List<SBQQ__Subscription__c> listSubscriptions) {
        try
        {
        
        List<QS_Customer_Asset__c> listCustomerAssetToInsert = new List<QS_Customer_Asset__c>();
        Set<Id> setProdIds = new Set<Id>();
        
        for(SBQQ__Subscription__c sub : listSubscriptions) {
            setProdIds.add(sub.SBQQ__Product__c);
        }
        setProdIds.remove(null);
        if(setProdIds.size() > 0) {
            Set<String> setExistingProdCustomerAsset = new Set<String>();
            // query all the products that have product QS_Generate_Asset__c  true 
            Map<Id, Product2> generateAssetProductById = CA2_CustomerAssetUtil.queryProductsById(setProdIds);
            
            List<SBQQ__Subscription__c> subscriptionsToProcess = new List<SBQQ__Subscription__c>();
            List<SBQQ__Subscription__c> subscriptionsToCreateSubAssetsFor = new List<SBQQ__Subscription__c>();
            for(SBQQ__Subscription__c sub: listSubscriptions) {
				system.debug('->>'+sub.QS_Product_Subscription_Pricing__c+'------'+sub.QS_Parent_Customer_Asset_Id__c);
                if(sub.SBQQ__Product__c != null && generateAssetProductById.containsKey(sub.SBQQ__Product__c) && generateAssetProductById.get(sub.SBQQ__Product__c).SBQQ__SubscriptionPricing__c != 'Percent Of Total') {
                    subscriptionsToProcess.add(sub);
                } else if (sub.QS_Product_Subscription_Pricing__c == 'Percent Of Total' && sub.QS_Parent_Customer_Asset_Id__c != '') {
                    subscriptionsToCreateSubAssetsFor.add(sub);
                }
            }
            if(subscriptionsToProcess.size() > 0) {
                Set<String> customerAssetUniqueIdSet = new Set<String>();
                // get Customer_Asset_Unique_Ids from Subscriptios 
                customerAssetUniqueIdSet = CA2_CustomerAssetUtil.Subscription_CAUniqueId(subscriptionsToProcess);
                // if is an Asset use the Function Asset_CAUniqueId called from the Asset Trigger Handler
                List<QS_Customer_Asset__c> listCustomerAssets = CA2_CustomerAssetUtil.queryCAByUniqueId(customerAssetUniqueIdSet);
                
                system.debug('customerAssetUniqueIdSet---'+customerAssetUniqueIdSet);
                system.debug('listCustomerAssets---'+listCustomerAssets);
                
                if(listCustomerAssets.size() > 0) {
                    for(QS_Customer_Asset__c customerAsset : listCustomerAssets) {
                        setExistingProdCustomerAsset.add(customerAsset.QS_Customer_Asset_Unique_Id__c);
                    }
                }
                //Insert Customer asset record
                for(SBQQ__Subscription__c sub : subscriptionsToProcess) {
                    if(!setExistingProdCustomerAsset.contains(sub.QS_Customer_Asset_Unique_Id__c)
                      ) {
                        QS_Customer_Asset__c cAsset = new QS_Customer_Asset__c();
                        if(generateAssetProductById.keySet().contains(sub.SBQQ__Product__c) && sub.QS_Customer_Asset_Account_Id__c != null) {
                            cAsset.QS_Account__c = sub.QS_Customer_Asset_Account_Id__c;
                            cAsset.QS_Secondary_Account__c = sub.QS_Secondary_Account_Id__c;
                            cAsset.QS_Product__c = sub.SBQQ__Product__c;
                            cAsset.QS_Customer_Asset_Unique_Id__c = sub.QS_Customer_Asset_Unique_Id__c;
                            cAsset.CurrencyIsoCode = sub.CurrencyIsoCode;
                            cAsset.QS_Product_Category__c = 'Subscription';
                            
                            setExistingProdCustomerAsset.add(sub.QS_Customer_Asset_Unique_Id__c); //prevent double adds
                            listCustomerAssetToInsert.add(cAsset);
                        }
                    }
                }
                insert listCustomerAssetToInsert;
                listCustomerAssets.addAll(listCustomerAssetToInsert);
                System.debug('List of Customer Assets passed' + listCustomerAssetToInsert);
                
                insertCustomerAssetDetail(listSubscriptions, listCustomerAssets, generateAssetProductById);                    
                
                
                
            }
            system.debug('subscriptionsToCreateSubAssetsFor--'+subscriptionsToCreateSubAssetsFor);
            if(subscriptionsToCreateSubAssetsFor.size() > 0) {
                System.debug('Reductions Handling Process');
                handleReductions(subscriptionsToCreateSubAssetsFor);
            }
        }
            }catch(Exception ex)
        {
            QS_Helper.logException('Exception', 'Insert Customer Asset Detail from Subscription List', 'CA2_SubscriptionTriggerHandler', 'createCustomerAssets', 'SBQQ__Subscription__c', userInfo.getUserId(), 
                                   ex.getLineNumber(), ex.getTypeName(), string.valueOf(ex.getCause()), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    private void handleReductions(List<SBQQ__Subscription__c> subscriptionsToCreateSubAssetsFor) {
        
        try
        {
            
        
        Set<Id> parentSubscriptions = new Set<Id>();
        Set<Id> subsToReduceIds = new Set<Id>();
        for(SBQQ__Subscription__c sub: subscriptionsToCreateSubAssetsFor) {
            subsToReduceIds.add(sub.Id);
            parentSubscriptions.add(sub.SBQQ__RevisedSubscription__c);
        }
        parentSubscriptions.remove(null);
        Map<String, SBQQ__SubscribedAsset__c> subAssetToCreate = new Map<String, SBQQ__SubscribedAsset__c>();
        List<SBQQ__SubscribedAsset__c> subAssetList = [SELECT SBQQ__Asset__c, QS_Booking_Date__c, SBQQ__Subscription__c, SBQQ__Subscription__r.SBQQ__RevisedSubscription__c FROM SBQQ__SubscribedAsset__c 
                                                       WHERE ((SBQQ__Subscription__c IN: parentSubscriptions AND SBQQ__Subscription__r.SBQQ__Quantity__c > 0) 
                                                              OR (SBQQ__Subscription__r.SBQQ__RevisedSubscription__c IN: parentSubscriptions AND SBQQ__Subscription__r.SBQQ__RevisedSubscription__r.SBQQ__Quantity__c > 0)) 
                                                       AND Id NOT IN: subsToReduceIds];
        
        for(SBQQ__SubscribedAsset__c sa: subAssetList) {
            Id saParent;
            if(String.isNotBlank(sa.SBQQ__Subscription__r.SBQQ__RevisedSubscription__c)) {
                saParent = sa.SBQQ__Subscription__r.SBQQ__RevisedSubscription__c;
            } else {
                saParent = sa.SBQQ__Subscription__c;
            } 
            for(SBQQ__Subscription__c sub: subscriptionsToCreateSubAssetsFor) {
                Id parentOfRevision = sub.SBQQ__RevisedSubscription__c;
                if(saParent == parentOfRevision) {
                    subAssetToCreate.put(sub.Id + '' + sa.SBQQ__Asset__c, new SBQQ__SubscribedAsset__c(SBQQ__Subscription__c = sub.Id, SBQQ__Asset__c = sa.SBQQ__Asset__c, QS_Created_By_Apex__c = true, QS_UpsertKey__c = sub.Id + '' + sa.SBQQ__Asset__c));
                }
            }
        }
        bypass = true;
        upsert subAssetToCreate.values() SBQQ__SubscribedAsset__c.QS_UpsertKey__c;
        bypass = false;
            }catch(Exception ex)
        {
            system.debug('exx--->'+ex.getCause());
            system.debug('exx--->'+ex.getLineNumber());
            system.debug('exx--->'+ex.getMessage());
            QS_Helper.logException('Exception', 'Insert Customer Asset Detail from Subscription List', 'CA2_SubscriptionTriggerHandler', 'handleReductions', 'QS_Customer_Asset_Detail__c', userInfo.getUserId(), 
                                   ex.getLineNumber(), ex.getTypeName(), string.valueOf(ex.getCause()), ex.getMessage(), ex.getStackTraceString());
        }
    }
    /**
* Description : Method to insert CustomerAssetDetail records
**/
    private void insertCustomerAssetDetail(List<SBQQ__Subscription__c> listSubscriptions, List<QS_Customer_Asset__c> listCustomerAssets, Map<Id, Product2> generateAssetProductById) {
       
        try
        {
        
        
        List<QS_Customer_Asset_Detail__c> listCustomerAssetDetailToInsert = new List<QS_Customer_Asset_Detail__c>();
        QS_Customer_Asset_Detail__c cAssetDetailStatus = new QS_Customer_Asset_Detail__c();
        Map<String, QS_Customer_Asset__c> customerAssetByKey = new Map<String, QS_Customer_Asset__c>();
        Set<String> caids = new Set<String>();
        for(QS_Customer_Asset__c ca: listCustomerAssets) {
            customerAssetByKey.put(ca.QS_Customer_Asset_Unique_Id__c, ca);
            caids.add(ca.id);
        }
        List<QS_Customer_Asset_Detail__c> 
            lstcad = [SELECT id,QS_Quantity__c,QS_Terminated_Date__c,QS_Booking_Date__c,
                      QS_Customer_Asset__c,Name,QS_Start_Date__c,QS_End_Date__c,CreatedDate,
                      QS_Subscription__r.Id,QS_Subscription__r.SBQQ__TerminatedDate__c from QS_Customer_Asset_Detail__c 
                      where QS_Customer_Asset__c In :caids AND QS_Renewed_Date__c = NULL order by CreatedDate ]; 
        System.debug('LST Cad' + lstcad);
        
       
        Date currentDate = System.today();
        Date effective_terminated_Date;
       
        for(SBQQ__Subscription__c sub : listSubscriptions) {
            
            if(sub.QS_CA_Quantity__c == 0 && !CA2_CustomerAssetUtil.NoCADCreationFromOpp)
                continue;
            QS_Customer_Asset_Detail__c cAssetDetail = new QS_Customer_Asset_Detail__c();
            cAssetDetail.QS_UniqueKey__c = sub.Id;
            QS_Customer_Asset__c cAsset = customerAssetByKey.get(sub.QS_Customer_Asset_Unique_Id__c);
            if(cAsset == null || generateAssetProductById.get(cAsset.QS_Product__c) == null) { continue; }
            cAssetDetail.QS_Customer_Asset__c = cAsset.Id;
            cAssetDetail.QS_Product__c = cAsset.QS_Product__c;
            cAssetDetail.QS_Subscription__c = sub.Id;
            cAssetDetail.QS_Contract__c = sub.SBQQ__Contract__c;
            cAssetDetail.QS_Quantity__c = sub.QS_CA_Quantity__c;           
            cAssetDetail.QS_Start_Date__c = sub.QS_CA_Start_Date__c;
            cAssetDetail.QS_One_Time_Fee__c = 0;
            cAssetDetail.CurrencyIsoCode = sub.CurrencyIsoCode;
            cAssetDetail.QS_Annual_Recurring_Revenue__c = sub.QS_Annual_Recurring_Revenue__c;
            if(sub.QS_CA_Quantity__c == 0)
            {
                cAssetDetail.QS_End_Date__c = sub.QS_CA_Start_Date__c;
            }else{
                cAssetDetail.QS_End_Date__c = sub.QS_CA_End_Date__c;
            }
            system.debug('subsWithRelated.get(sub.Id)---'+subsWithRelated.get(sub.Id));
            if(subsWithRelated.get(sub.Id) != null && 
               subsWithRelated.get(sub.Id).SBQQ__QuoteLine__r != null && 
               subsWithRelated.get(sub.Id).SBQQ__QuoteLine__r.SBQQ__Quote__r != null && 
               subsWithRelated.get(sub.Id).SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r != null) {
                   cAssetDetail.QS_Decommission_Reason__c = subsWithRelated.get(sub.Id).SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Opportunity2__r.QS_Decommission_Reason__c;    
               }
            
            cAssetDetail.QS_Currently_Active__c = sub.QS_Currently_In_Date_Range__c;
            if(cAssetDetail.QS_New_Asset_Status__c == 'Expired')
                cAssetDetail.QS_Currently_Active__c = false;
            listCustomerAssetDetailToInsert.add(cAssetDetail);
        }
        upsert listCustomerAssetDetailToInsert QS_Customer_Asset__c.QS_UniqueKey__c;
        }catch(Exception ex)
        {
            system.debug('exx--->'+ex.getCause());
            system.debug('exx--->'+ex.getLineNumber());
            system.debug('exx--->'+ex.getMessage());
            QS_Helper.logException('Exception', 'Insert Customer Asset Detail from Subscription List', 'CA2_SubscriptionTriggerHandler', 'insertCustomerAssetDetail', 'QS_Customer_Asset_Detail__c', userInfo.getUserId(), 
                                   ex.getLineNumber(), ex.getTypeName(), string.valueOf(ex.getCause()), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    
    
    
    
        
    
    
    
    
    
}