global class AccountHierarchyforProductfamily implements Database.Batchable<SObject> ,Database.Stateful {
    map<id,Active_Megawatts__c> mapToInsert = new map<id,Active_Megawatts__c> ();
    
    global Database.QueryLocator Start(Database.BatchableContext bc){
        set<Id> accId = new set<Id>(); 
        list<Plant_Product_Transaction__c> p =[SELECT id,Plant__c,Product_Family__c,Plant_Name__c,Plant__r.Status__c,MWp_Quantity__c,Product__r.QuantityUnitOfMeasure, Account__c, status__c FROM Plant_Product_Transaction__c
                                               Where Status__c ='contracted'and Plant__r.Status__c ='Active'
                                               and (Product__r.QuantityUnitOfMeasure='MWp' OR Product__r.QuantityUnitOfMeasure='MWh' OR Product__r.QuantityUnitOfMeasure='WGT') 
                                               and Plant__c!=null ];
        for(Plant_Product_Transaction__c se: p){
            accId.add(se.Account__c);
        }
        
        set<id> plist = new set<id>();
        List<Account_Plant__c> pe =[select id, name,Account__c from Account_Plant__c where Account__c=:accId];
        
        for(Account_Plant__c pl:pe)plist.add(pl.id);
        
        String query = 'SELECT id,Plant__c,Product_Family__c, Plant_Name__c,Account__c,plant__r.Asset_Class__c,status__c,MWp_Quantity__c  FROM '+
            ' Plant_Product_Transaction__c WHERE Status__c = \'contracted\' and '+
            ' (Product__r.QuantityUnitOfMeasure=\'MWp\' OR Product__r.QuantityUnitOfMeasure=\'MWh\' OR'+
            ' Product__r.QuantityUnitOfMeasure=\'WGT\') and '+
            ' plant__c=:plist ' ;// AND Contract__r.status = \'Activated\' AND Account__c = \'0017j00000lRbZFAA0\'
        system.debug('********the query2******'+query);
        return Database.getQueryLocator(query);
    } 
    
    global void execute(Database.BatchableContext bc, List<Plant_Product_Transaction__c> scope){
        
        Set<Id> accountIdset = new Set<Id>();
        
        for(Plant_Product_Transaction__c pData :scope){
            if(pData.Account__c!=null)accountIdset.add(pData.Account__c);
        }
        
        List<Plant_Product_Transaction__c> pptRecordsList = [SELECT Name, MWp_Quantity__c,Product_Family__c,Plant_Name__c,plant__r.Asset_Class__c,plant__r.Plant_MWP__c,Account__c,Account__r.ParentId FROM Plant_Product_Transaction__c
                                                             WHERE Account__c In:accountIdset AND Status__c ='Contracted'and MWp_Quantity__c!=null AND plant__c!=null and 
                                                             //(Account__r.ParentId != null OR Account__r.Ultimate_Parent_Account__c = Null) and
                                                              
                                                             (
                                                                 Product_Family__c ='Drive' OR
                                                                 Product_Family__c ='Greenbyte' OR
                                                                 Product_Family__c ='BluePoint' OR
                                                                 Product_Family__c='Ekhosoft'
                                                                 
                                                             ) //AND Account__c = '0017j00000lRbZFAA0'
                                                            ];
        Map<Id, List<Plant_Product_Transaction__c>> pptMap = new Map<Id, List<Plant_Product_Transaction__c>>();
        Map<Id,List<Id>> accountRelationShipMap = new Map<Id,List<Id>>();
        Map<Id,ActiveMegawatWrapper> accCalculationMap = new Map<Id,ActiveMegawatWrapper>();
        
        Map<Id,ActiveMegawatWrapper> independantAccount = new Map<Id,ActiveMegawatWrapper>();
        Set<Id> indipendatAccIds = new Set<Id>();
        
       	for(Plant_Product_Transaction__c ppt : pptRecordsList ){
            if(pptMap.containsKey(ppt.Account__c)){
                pptMap.get(ppt.Account__c).add(ppt);
            }else{
                pptMap.put(ppt.Account__c , new List<Plant_Product_Transaction__c>{ppt});
            }    
            
			if(ppt.Account__c != null && ppt.Account__r.ParentId != null){
                
				if(accountRelationShipMap.containsKey(ppt.Account__r.ParentId)){
                    if(!accountRelationShipMap.get(ppt.Account__r.ParentId).contains(ppt.Account__c)){
						accountRelationShipMap.get(ppt.Account__r.ParentId).add(ppt.Account__c);                        
                    }
                }else{
                    accountRelationShipMap.put(ppt.Account__r.ParentId , new List<Id>{ppt.Account__c});
                } 
			}
            
            if(ppt.Account__c != null && ppt.Account__r.ParentId == null){
                indipendatAccIds.add(ppt.Account__c);
            }
        }
        
        system.debug('indipendatAccIds--'+indipendatAccIds);
        
        for(Id pptId : pptMap.keySet()){
            system.debug('Account Id ->'+pptId);
            Decimal SumSolar =0;
            Decimal SumWind =0;
            Decimal SumHydro =0;
            Decimal SumStorage =0;
            Decimal SumOtherRenewable=0;
            Decimal SumIndustrial=0;
            
            Decimal SumOfDrive =0;
            Decimal SumOfGreenByte =0;
            Decimal SumOfBluePoint =0;
            Decimal SumOfEkhoSoft=0;
            
            Map<String , Map<String , Decimal>> productPptMap = new Map<String , Map<String , Decimal>>();
            
            for(Plant_Product_Transaction__c pData :pptMap.get(pptId)){
                
                system.debug(pData.plant__r.Asset_Class__c +'----PPT Records under AccID ---->'+pData.MWp_Quantity__c);
                if(pData.plant__r.Plant_MWP__c!=null)
                {
                    system.debug(pData.Name+'---'+pData.Id+'---'+pData.plant__r.Asset_Class__c +'-------'+pData.plant__r.Plant_MWP__c);
                    system.debug(pData.Name+'---'+pData.Id+'---'+pData.Product_Family__c +'-------'+pData.plant__r.Plant_MWP__c);
                    
                    if(productPptMap.containsKey(pData.Product_Family__c) && !productPptMap.get(pData.Product_Family__c).containsKey(pData.Plant_Name__c)){
                        //SumOfDrive += pData.plant__r.Plant_MWP__c;
                        productPptMap.get(pData.Product_Family__c).put(pData.Plant_Name__c , pData.plant__r.Plant_MWP__c);
                        
                    }else if (!productPptMap.containsKey(pData.Product_Family__c)){
                        productPptMap.put(pData.Product_Family__c , new Map<String, Decimal>{pData.Plant_Name__c => pData.plant__r.Plant_MWP__c});
                    }
                }
            }
            
            for(String prodFamily : productPptMap.keySet()){
                if(prodFamily == 'Drive'){
                    for(Decimal mwp : productPptMap.get(prodFamily).values()){
                        SumOfDrive += mwp;
                    }
                }else if(prodFamily == 'Greenbyte'){
                    for(Decimal mwp : productPptMap.get(prodFamily).values()){
                        SumOfGreenByte += mwp;
                    }
                }else if(prodFamily == 'BluePoint'){
                    for(Decimal mwp : productPptMap.get(prodFamily).values()){
                        SumOfBluePoint += mwp;
                    }
                }
                else if(prodFamily == 'Ekhosoft'){
                    for(Decimal mwp : productPptMap.get(prodFamily).values()){
                        SumOfEkhoSoft += mwp;
                    }
                }
            }
            
            Decimal Total_MW_Bluepoint 	= SumOfBluePoint;
            Decimal Total_MW_Drive 		= SumOfDrive;
            Decimal Total_MW_Greenbyte 	= SumOfGreenByte;
            Decimal Total_Active_MW_to_consider_for_Ekhosoft = SumOfEkhoSoft;
            
            Decimal MW_Bluepoint 		= SumOfBluePoint;
            Decimal MW_Drive 			= SumOfDrive;
            Decimal MW_Greenbyte 		= SumOfGreenByte;
            Decimal MW_Ekhosoft      = SumOfEkhoSoft;
            
            Decimal Child_MW_Bluepoint 	= SumOfBluePoint;
            Decimal Child_MW_Drive 		= SumOfDrive;
            Decimal Child_MW_Greenbyte 	= SumOfGreenByte;
            Decimal Child_MW_Ekhosoft = SumOfEkhoSoft;
            
            ActiveMegawatWrapper wrp = new ActiveMegawatWrapper(
               Total_MW_Bluepoint, 
                Total_MW_Drive ,
                Total_MW_Greenbyte ,
                Total_Active_MW_to_consider_for_Ekhosoft,
                
                MW_Bluepoint ,
                MW_Drive ,
                MW_Greenbyte ,
                MW_Ekhosoft,
                
                Child_MW_Bluepoint ,
                Child_MW_Drive ,
                Child_MW_Greenbyte,
                Child_MW_Ekhosoft
			);
            accCalculationMap.put(pptId, wrp);
        }
        for(Id accId : accCalculationMap.keySet()){
            if(indipendatAccIds.contains(accId) && !accountRelationShipMap.keySet().contains(accId)){
                independantAccount.put(accId , accCalculationMap.get(accId));
            }
        }
        
        map<id,Active_Megawatts__c> independantAMW =  new map<id,Active_Megawatts__c>();
        
        for(Id indipAccId : independantAccount.keySet()){
            ActiveMegawatWrapper amwWrapper = independantAccount.get(indipAccId);
            Active_Megawatts__c amw = new Active_Megawatts__c(
                
                Total_MW_Bluepoint__c 	= amwWrapper.MW_Bluepoint ,
                Total_MW_Drive__c 		= amwWrapper.MW_Drive ,
                Total_MW_Greenbyte__c 	= amwWrapper.MW_Greenbyte ,
                Total_Active_MW_to_consider_for_Ekhosoft__c=amwWrapper.MW_Ekhosoft,
                
                
                MW_Bluepoint__c 		= amwWrapper.MW_Bluepoint ,
                MW_Drive__c 			= amwWrapper.MW_Drive ,
                MW_Greenbyte__c 		= amwWrapper.MW_Greenbyte ,
                MW_Ekhosoft__c          = amwWrapper.MW_Ekhosoft,
                
                Child_MW_Bluepoint__c 	= 0,
                Child_MW_Drive__c 		= 0,
                Child_MW_Greenbyte__c 	= 0,
                Child_MW_Ekhosoft__c    =0,
                
                Account__c					= 	indipAccId
            );
            independantAMW.put(indipAccId,amw);
        }        
        
        
        map<id,Active_Megawatts__c> mer =  new map<id,Active_Megawatts__c>();
        map<id,Active_Megawatts__c> childActiveMegawatsMaps =  new map<id,Active_Megawatts__c>();
        List<Active_Megawatts__c> activeMWtoInsert = new List<Active_Megawatts__c>();
        for(Id parentAccId : accountRelationShipMap.keySet()){
            Decimal Sum_Total_MW_Bluepoint = 0;
            Decimal Sum_Total_MW_Drive =0;
            Decimal Sum_Total_MW_Greenbyte =0;
            Decimal Sum_Total_MW_EkhoSoft=0;
            
            
            Decimal Sum_MW_Bluepoint =0;
            Decimal Sum_MW_Drive =0;
            Decimal Sum_MW_Greenbyte =0;
            Decimal Sum_MW_EkhoSoft=0;
            
            Decimal Sum_Child_MW_Bluepoint =0;
            Decimal Sum_Child_MW_Drive =0;
            Decimal Sum_Child_MW_Greenbyte =0;
            Decimal Sum_Child_MW_EkhoSoft=0;
            
			for(Id childAccIds :  accountRelationShipMap.get(parentAccId)){
                if(accCalculationMap.containsKey(childAccIds)){
                   
                    Sum_Total_MW_Bluepoint 	+= accCalculationMap.get(childAccIds).Total_MW_Bluepoint;
                    Sum_Total_MW_Drive  	+= accCalculationMap.get(childAccIds).Total_MW_Drive;
                    Sum_Total_MW_Greenbyte 	+= accCalculationMap.get(childAccIds).Total_MW_Greenbyte;
                    Sum_Total_MW_EkhoSoft   += accCalculationMap.get(childAccIds).Total_Active_MW_to_consider_for_Ekhosoft;
                    
                    
                    Sum_MW_Bluepoint 		+= accCalculationMap.get(childAccIds).MW_Bluepoint;
                    Sum_MW_Drive 			+= accCalculationMap.get(childAccIds).MW_Drive;
                    Sum_MW_Greenbyte 		+= accCalculationMap.get(childAccIds).MW_Greenbyte;
                    Sum_MW_EkhoSoft         += accCalculationMap.get(childAccIds).MW_Ekhosoft;
                    
                    
                    Sum_Child_MW_Bluepoint 	+= accCalculationMap.get(childAccIds).Child_MW_Bluepoint;
                    Sum_Child_MW_Drive 		+= accCalculationMap.get(childAccIds).Child_MW_Drive;
                    Sum_Child_MW_Greenbyte 	+= accCalculationMap.get(childAccIds).Child_MW_Greenbyte;
                    Sum_Child_MW_EkhoSoft   += accCalculationMap.get(childAccIds).Child_MW_Ekhosoft;
                    

     				ActiveMegawatWrapper parentFields = accCalculationMap.get(childAccIds);
                    
                    Active_Megawatts__c awForChildAccount = new Active_Megawatts__c(
                       
                        Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint ,
                        Total_MW_Drive__c 		= parentFields.MW_Drive ,
                        Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte ,
                        Total_Active_MW_to_consider_for_Ekhosoft__c= parentFields.MW_Ekhosoft,
                        
                        
                        MW_Bluepoint__c 		= parentFields.MW_Bluepoint ,
                        MW_Drive__c 			= parentFields.MW_Drive ,
                        MW_Greenbyte__c 		= parentFields.MW_Greenbyte ,
                        MW_Ekhosoft__c          = parentFields.MW_Ekhosoft,
                        
                        Child_MW_Bluepoint__c 	= 0,
						Child_MW_Drive__c 		= 0,
                        Child_MW_Greenbyte__c 	= 0,
                        Child_MW_Ekhosoft__c    =0,
                        
                        
                        Account__c					= 	childAccIds
                    );
                    childActiveMegawatsMaps.put(childAccIds,awForChildAccount);
                }
            }
            
            if(accCalculationMap.containsKey(parentAccId)){
                
                ActiveMegawatWrapper parentFields = accCalculationMap.get(parentAccId);
                Active_Megawatts__c ae3 = new Active_Megawatts__c(
                   	Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint  + Sum_Total_MW_Bluepoint ,
                    Total_MW_Drive__c 		= parentFields.MW_Drive + Sum_Total_MW_Drive ,
                    Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte + Sum_Total_MW_Greenbyte ,
                    Total_Active_MW_to_consider_for_Ekhosoft__c=parentFields.MW_Ekhosoft+Sum_Total_MW_EkhoSoft,
                    
                    
                    MW_Bluepoint__c 		= parentFields.MW_Bluepoint ,
                    MW_Drive__c 			= parentFields.MW_Drive ,
                    MW_Greenbyte__c 		= parentFields.MW_Greenbyte ,
                    MW_Ekhosoft__c          = parentFields.MW_Ekhosoft,
                    
                    Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint,
                    Child_MW_Drive__c 		= Sum_Total_MW_Drive,
                    Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte,
                    Child_MW_Ekhosoft__c    = Sum_Total_MW_EkhoSoft,
                    
                    Account__c					= 	parentAccId
                );
                mer.put(parentAccId,ae3);
            }
        }
        System.debug('independantAMW--'+independantAMW);
        activeMWtoInsert.addAll(mer.values());
        activeMWtoInsert.addAll(childActiveMegawatsMaps.values());
        
        mapToInsert.putAll(mer);
        mapToInsert.putAll(childActiveMegawatsMaps); //independantAMW
        mapToInsert.putAll(independantAMW);
        
    }
    
    global void finish(Database.BatchableContext BC){
        for(Id key : mapToInsert.keySet()){
            system.debug('key-->'+key);
        }
        
        if(mapToInsert != null && mapToInsert.size() >0 ){
            try{
                insert mapToInsert.values();
            }
            catch(Exception e){
                system.debug(e.getMessage());
            }
        }
    }
    
    public class ActiveMegawatWrapper{
        public Decimal Total_MW_Bluepoint ;
        public Decimal Total_MW_Drive ;
        public Decimal Total_MW_Greenbyte ;
        public Decimal Total_Active_MW_to_consider_for_Ekhosoft;
        
        
        public Decimal MW_Bluepoint ;
        public Decimal MW_Drive ;
        public Decimal MW_Greenbyte ;
        public Decimal MW_Ekhosoft;
        
        public Decimal Child_MW_Bluepoint ;
        public Decimal Child_MW_Drive ;
        public Decimal Child_MW_Greenbyte ;
        public Decimal Child_MW_Ekhosoft ;

        public ActiveMegawatWrapper(
        	Decimal Total_MW_Bluepoint ,
            Decimal Total_MW_Drive ,
            Decimal Total_MW_Greenbyte ,
            Decimal Total_Active_MW_to_consider_for_Ekhosoft ,
            
            Decimal MW_Bluepoint ,
            Decimal MW_Drive ,
            Decimal MW_Greenbyte ,
            Decimal MW_Ekhosoft,
            
            Decimal Child_MW_Bluepoint ,
            Decimal Child_MW_Drive ,
            Decimal Child_MW_Greenbyte,
            Decimal Child_MW_Ekhosoft
            

        ){
           	this.Total_MW_Bluepoint = Total_MW_Bluepoint ;
            this.Total_MW_Drive = Total_MW_Drive ;
            this.Total_MW_Greenbyte = Total_MW_Greenbyte ;
            this.Total_Active_MW_to_consider_for_Ekhosoft=Total_Active_MW_to_consider_for_Ekhosoft;
            
            this.MW_Bluepoint = MW_Bluepoint ;
            this.MW_Drive = MW_Drive ;
            this.MW_Greenbyte = MW_Greenbyte ;
            this.MW_Ekhosoft=MW_Ekhosoft;
            
            this.Child_MW_Bluepoint = Child_MW_Bluepoint ;
            this.Child_MW_Drive = Child_MW_Drive ;
            this.Child_MW_Greenbyte = Child_MW_Greenbyte;
            this.Child_MW_Ekhosoft=Child_MW_Ekhosoft;

		}
    }
}