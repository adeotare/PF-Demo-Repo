/**
* Creates Customer Assets from Asset line items on the Quote
* 
*/
public class CA2_AssetTriggerHandler extends CA2_TriggerHandler {
    
    
    /**
* Handler entry point after insert.
*/
    @TestVisible
    protected override void afterInsert(){
        if(!CA2_CustomerAssetUtil.ByPassTrigger){
        	createCustomerAssets((List<Asset>)Trigger.new, new Map<Id, SBQQ__SubscribedAsset__c>());
        }
        
    }
    /**
* Handler entry point after update.
*/
    @TestVisible
    protected override void afterUpdate(){
        if(CA2_CustomerAssetUtil.Create_CA_On_Update || Test.isRunningTest()){
            createCustomerAssets((List<Asset>)Trigger.new, new Map<Id, SBQQ__SubscribedAsset__c>());    
        }
        
    }
    
    /**
* Creates Customer Assets based on Subscribed Assets list.
* @param subAssetList list of subscribed assets.
*/
    public static void createCustomerAssets(List<SBQQ__SubscribedAsset__c> subAssetList) {
        
        try
        {
            Set<String> setExistingAssetIds = new Set<String>();
            //this map holds the assetId as key and subscriobption id as value. this is used to get the subscription based on asset Id
            Map<Id, SBQQ__SubscribedAsset__c> subAssetById = new Map<Id, SBQQ__SubscribedAsset__c>(subAssetList);
            Set<Id> assetIdSet = new Set<Id>();
            for(SBQQ__SubscribedAsset__c subAsset: subAssetList) {
                if(subAsset.SBQQ__Asset__c != null && !setExistingAssetIds.Contains(subAsset.SBQQ__Asset__c)) {
                    if(subAsset.SBQQ__Asset__c != null) {
                        assetIdSet.add(subAsset.SBQQ__Asset__c);
                    }
                }
            }
            List<Asset> listAsset = [SELECT Product2Id, QS_Booking_Date__c,QS_Secondary_Account_Id__c,CurrencyIsoCode,QS_Customer_Asset_Account_Id__c, QS_Effective_Start_Date__c, SBQQ__SubscriptionStartDate__c, Product2.SBQQ__SubscriptionBase__c, SBQQ__SubscriptionEndDate__c, Quantity,AccountId,QS_Customer_Asset_Unique_Id__c,SBQQ__ListPrice__c,SBQQ__PricingMethod__c,QS_Net_Price__c 
                                     FROM Asset 
                                     WHERE Id IN: assetIdSet];
            
            if(listAsset.size() > 0) {
                CA2_AssetTriggerHandler.createCustomerAssets(listAsset, subAssetById);
            }
            
            
            
        }catch(Exception ex)
        {
            QS_Helper.logException('Exception', 'Creation of Assets from Subscribed Assets', 'CA2_AssetTriggerHandler', 'createCustomerAssets', 'Asset', userInfo.getUserId(), 
                                   ex.getLineNumber(), ex.getTypeName(), string.valueOf(ex.getCause()), ex.getMessage(), ex.getStackTraceString());
            
        }
        
    }
    /**
* Creates Customer Assets based on list of associated assets and subscribed assets.
* @param lstAssets Assets list.
* @param subAssetById Subscribed assets map.
*/
    public static void createCustomerAssets(List<Asset> lstAssets, Map<Id, SBQQ__SubscribedAsset__c> subAssetById) {
        
        try
        {
            
            // this list is to hold the new list of customerassets that needs to be inserted
            List<QS_Customer_Asset__c> listCustomerAssetToInsert = new List<QS_Customer_Asset__c>();
            Set<Id> setProdIds = new Set<Id>();
            // This map is to Hold Asset ProductId as key and Asset as Value and it is used to get the asset based on product id
            for(Asset asset : lstAssets) {
                setProdIds.add(asset.Product2Id);
            }
            setProdIds.remove(null);
            if(setProdIds.size() > 0) {
                Set<String> existingCustomerAssetKeys = new Set<String>();
                Map<Id, Product2> generateAssetProductById = CA2_CustomerAssetUtil.queryProductsById(setProdIds);
                //This list hold the filtered asserts based on Product that has generate asset true
                List<Asset> assetsToProcess = new List<Asset>();
                for(Asset asset : lstAssets) {
                    if(generateAssetProductById.containskey(asset.Product2Id)) {
                        assetsToProcess.add(asset);
                    }
                }
                if(assetsToProcess.size() > 0) {
                    Set<String> customerAssetUniqueIdSet = new Set<String>();
                    customerAssetUniqueIdSet = CA2_CustomerAssetUtil.getMatchingKeys(assetsToProcess);
                    // if is an Asset use the Function getMatchingKeys called from the Asset Trigger Handler
                    List<QS_Customer_Asset__c> customerAssets = CA2_CustomerAssetUtil.queryCAByUniqueId(customerAssetUniqueIdSet);
                    if(customerAssets.size() > 0) {
                        for(QS_Customer_Asset__c ca : customerAssets) {
                            existingCustomerAssetKeys.add(ca.QS_Customer_Asset_Unique_Id__c);
                        }
                    }
                    //Insert CustomerAsset record
                    for(Asset asset : assetsToProcess) {
                        Boolean createdMatchingSA = false;
                        if(!createdMatchingSA) {
                            if(!existingCustomerAssetKeys.contains(asset.QS_Customer_Asset_Unique_Id__c)) {
                                QS_Customer_Asset__c cAsset = new QS_Customer_Asset__c();
                                if(generateAssetProductById.keySet().contains(asset.Product2Id)){
                                    cAsset.QS_Account__c = asset.QS_Customer_Asset_Account_Id__c;
                                    cAsset.QS_Secondary_Account__c = asset.QS_Secondary_Account_Id__c;
                                    cAsset.QS_Product__c = asset.Product2Id;
                                    cAsset.QS_Customer_Asset_Unique_Id__c = asset.QS_Customer_Asset_Unique_Id__c;
                                    cAsset.CurrencyIsoCode = asset.CurrencyIsoCode;
                                    cAsset.QS_Product_Category__c = 'Asset';
                                    existingCustomerAssetKeys.add(asset.QS_Customer_Asset_Unique_Id__c);//prevent double adds
                                    listCustomerAssetToInsert.add(cAsset);
                                }
                            }
                        }
                    }
                    insert listCustomerAssetToInsert;
                    
                    // add the customer assets thats need be inserted to the main list of customerassers
                    customerAssets.addAll(listCustomerAssetToInsert);
                    if(subAssetById.size() > 0) {
                        insertCustomerAssetDetailForSubscribedAssets(assetsToProcess, customerAssets, subAssetById, generateAssetProductById); 
                    } else {
                        insertCustomerAssetDetail(assetsToProcess, customerAssets, generateAssetProductById);
                    }
                }
            }
        }catch(Exception ex)
        {
            QS_Helper.logException('Exception', 'Creation of Assets from Assets and Sub Asset ID', 'CA2_AssetTriggerHandler', 'createCustomerAssets', 'Asset', userInfo.getUserId(), 
                                   ex.getLineNumber(), ex.getTypeName(), string.valueOf(ex.getCause()), ex.getMessage(), ex.getStackTraceString());
            
        }
        
    }
    
    /**
* Method inserts Customer Asset Detail records on insert of Asset.
* @param assetsToProcess Assets objects to be processed.
* @param customerAssets Customer Assets related to assets.
* @param generateAssetProductById map of product IDs.
*/
    public static void insertCustomerAssetDetail(List<Asset> assetsToProcess, List<QS_Customer_Asset__c> customerAssets, Map<Id, Product2> generateAssetProductById) {
        try
        {
            
            
            
            Map<String, QS_Customer_Asset__c> customerAssetByKey = new Map<String, QS_Customer_Asset__c>();
            Set<String> caids = new Set<String>();
            for(QS_Customer_Asset__c ca: customerAssets) {
                customerAssetByKey.put(ca.QS_Customer_Asset_Unique_Id__c, ca);
                caids.add(ca.id);
            }
            
            CA2_SubscriptionTriggerHandler sth = new CA2_SubscriptionTriggerHandler();
            List<QS_Customer_Asset_Detail__c> lstcad = [SELECT id,QS_Quantity__c,QS_Customer_Asset__c,QS_Booking_Date__c from QS_Customer_Asset_Detail__c where QS_Customer_Asset__c In :caids and QS_Renewed_Date__c = null]; 
            List<QS_Customer_Asset_Detail__c> customerAssetDetailToInsert = new List<QS_Customer_Asset_Detail__c>();
            
            for(Asset asset : assetsToProcess) {
                QS_Customer_Asset_Detail__c cAssetDetail = new QS_Customer_Asset_Detail__c();
                cAssetDetail.QS_UniqueKey__c = asset.Id;
                QS_Customer_Asset__c cAsset = customerAssetByKey.get(asset.QS_Customer_Asset_Unique_Id__c);
                if(cAsset == null || generateAssetProductById.get(cAsset.QS_Product__c) == null) { continue; }
                cAssetDetail.QS_Customer_Asset__c = cAsset.Id;
                cAssetDetail.QS_Product__c = cAsset.QS_Product__c;
                cAssetDetail.QS_Asset__c = asset.Id;
                cAssetDetail.QS_Quantity__c = asset.Quantity;
                cAssetDetail.QS_One_Time_Fee__c =  asset.QS_Net_Price__c;
                cAssetDetail.QS_Annual_Recurring_Revenue__c = 0;
                cAssetDetail.CurrencyIsoCode = asset.CurrencyIsoCode;
                cAssetDetail.QS_Currently_Active__c = true; // Asset Status will always be true 
                if(cAssetDetail.QS_New_Asset_Status__c == 'Expired')
                    cAssetDetail.QS_Currently_Active__c = false;
                if(asset.QS_Effective_Start_Date__c != null) {
                    cAssetDetail.QS_Start_Date__c = asset.QS_Effective_Start_Date__c;
                }
                
                customerAssetDetailToInsert.add(cAssetDetail);
            }
            upsert customerAssetDetailToInsert QS_Customer_Asset_Detail__c.QS_UniqueKey__c;
            
        }catch(Exception ex)
        {
            QS_Helper.logException('Exception', 'Insert Customer Asset Detail from Asset and CA Asset', 'CA2_AssetTriggerHandler', 'insertCustomerAssetDetail', 'Asset', userInfo.getUserId(), 
                                   ex.getLineNumber(), ex.getTypeName(), string.valueOf(ex.getCause()), ex.getMessage(), ex.getStackTraceString());
            
        }
    }
    /**
* Method inserts Customer Asset Detail records on insert of Subscribed Assets.
* @param assetsToProcess Assets objects to be processed.
* @param customerAssets Customer Assets related to assets.
* @param subAssetById map of Subscribed Assets.
* @param generateAssetProductById map of product IDs.
*/
    public static void insertCustomerAssetDetailForSubscribedAssets(List<Asset> assetsToProcess, List<QS_Customer_Asset__c> customerAssets, Map<Id, SBQQ__SubscribedAsset__c> subAssetById, Map<Id, Product2> generateAssetProductById) {
        try
        {
            
            Map<String, QS_Customer_Asset__c> customerAssetByKey = new Map<String, QS_Customer_Asset__c>();
            Set<String> caids = new Set<String>();
            QS_Customer_Asset_Detail__c cAssetDetailStatus = new QS_Customer_Asset_Detail__c(); 
            CA2_SubscriptionTriggerHandler sth = new CA2_SubscriptionTriggerHandler();
            for(QS_Customer_Asset__c ca: customerAssets) {
                customerAssetByKey.put(ca.QS_Customer_Asset_Unique_Id__c, ca);
                caids.add(ca.id);
            }
            
            List<QS_Customer_Asset_Detail__c> customerAssetDetailToInsert = new List<QS_Customer_Asset_Detail__c>();       
            Set<Id> setSubscriptionIds = new Set<Id>();
            for(SBQQ__SubscribedAsset__c sa: subAssetById.values()) {
                setSubscriptionIds.add(sa.SBQQ__Subscription__c);
            }
            
            List<QS_Customer_Asset_Detail__c> lstcad = [SELECT id,QS_Quantity__c,QS_Customer_Asset__c,QS_Booking_Date__c from QS_Customer_Asset_Detail__c where QS_Customer_Asset__c In :caids]; 
            
            Map<Id, SBQQ__Subscription__c> subscriptionById = new Map<Id, SBQQ__Subscription__c>();
            if(setSubscriptionIds.size() > 0) {
                //Get subscription's net price for ARR calculation
                subscriptionById = new Map<Id, SBQQ__Subscription__c>([SELECT Id, SBQQ__StartDate__c,QS_CA_Quantity__c,SBQQ__TerminatedDate__c,QS_CA_End_Date__c, 
                                                                       SBQQ__RevisedSubscription__c,QS_Booking_Date__c, SBQQ__RevisedSubscription__r.SBQQ__Quantity__c, 
                                                                       SBQQ__Product__c, SBQQ__Quantity__c,QS_Currently_In_Date_Range__c, SBQQ__EndDate__c, SBQQ__Contract__c, 
                                                                       SBQQ__NetPrice__c, SBQQ__ListPrice__c, QS_Customer_Asset_Unique_Id__c 
                                                                       FROM SBQQ__Subscription__c 
                                                                       WHERE Id IN :setSubscriptionIds]);
            }
            //Insert CustomerAssetDetail record
            for(SBQQ__SubscribedAsset__c sa: subAssetById.values()) {
                for(Asset asset : assetsToProcess) {
                    if(sa.SBQQ__Asset__c == asset.Id) {
                        Id subId = sa.SBQQ__Subscription__c;
                        QS_Customer_Asset_Detail__c cAssetDetail = new QS_Customer_Asset_Detail__c();
                        cAssetDetail.QS_UniqueKey__c = sa.Id;
                        cAssetDetail.QS_Subscribed_Asset__c = sa.Id;
                        SBQQ__Subscription__c subsc = subscriptionById.get(subId);
                        QS_Customer_Asset__c cAsset = customerAssetByKey.get(subsc.QS_Customer_Asset_Unique_Id__c);
                        if(cAsset == null) {
                            cAsset = customerAssetByKey.get(asset.QS_Customer_Asset_Unique_Id__c);
                        }
                        if(cAsset == null || generateAssetProductById.get(cAsset.QS_Product__c) == null) { continue; }
                        cAssetDetail.QS_Customer_Asset__c = cAsset.Id;
                        cAssetDetail.QS_Product__c = subsc.SBQQ__Product__c;
                        cAssetDetail.QS_Asset__c = asset.Id;
                        cAssetDetail.QS_One_Time_Fee__c = 0;
                        cAssetDetail.QS_Currently_Active__c = subsc.QS_Currently_In_Date_Range__c;
                        if(cAssetDetail.QS_New_Asset_Status__c == 'Expired')
                            cAssetDetail.QS_Currently_Active__c = false;
                        cAssetDetail.CurrencyIsoCode = asset.CurrencyIsoCode;
                        cAssetDetail.QS_Contract__c = subsc.SBQQ__Contract__c;
                        cAssetDetail.QS_Start_Date__c = subsc.SBQQ__StartDate__c;
                        cAssetDetail.QS_End_Date__c = subsc.QS_CA_End_Date__c;
                        if(sa.QS_Created_By_Apex__c) {
                            cAssetDetail.QS_Quantity__c = subsc.SBQQ__Quantity__c;    
                        } else {
                            cAssetDetail.QS_Quantity__c = sa.QS_Subscription_Quantity__c;
                        }
                        
                        cAssetDetail.QS_Subscription__c = subsc.Id;
                        cAssetDetail.QS_Maintain_Line__c = true;
                        cAssetDetail.QS_Annual_Recurring_Revenue__c = sa.QS_Annual_Recurring_Revenue__c;
                        if(sa.SBQQ__Active__c)
                        {
                            customerAssetDetailToInsert.add(cAssetDetail);
                        }
                    }
                }
            }
            
            upsert customerAssetDetailToInsert QS_Customer_Asset__c.QS_UniqueKey__c;
            
        }catch(Exception ex)
        {
            QS_Helper.logException('Exception', 'Insert Customer Asset Detail from Subscribed Asset', 'CA2_AssetTriggerHandler', 'insertCustomerAssetDetailForSubscribedAssets', 'Asset', userInfo.getUserId(), 
                                   ex.getLineNumber(), ex.getTypeName(), string.valueOf(ex.getCause()), ex.getMessage(), ex.getStackTraceString());
        }
    }
    
    
    
    
    
    
    
}