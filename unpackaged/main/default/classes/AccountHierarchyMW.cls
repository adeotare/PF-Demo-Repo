global class AccountHierarchyMW implements Database.Batchable<SObject> , Database.Stateful {
    
    map<id,Active_Megawatts__c> mapToInsert = new map<id,Active_Megawatts__c> ();
    
    
    global Database.QueryLocator Start(Database.BatchableContext bc)
    {
        
        
        set<Id> accId = new set<Id>(); 
        list<Plant_Product_Transaction__c> p =[SELECT id,Plant__c,Plant__r.Status__c,MWp_Quantity__c,Product__r.QuantityUnitOfMeasure, Account__c, status__c FROM Plant_Product_Transaction__c
                                               Where Status__c ='contracted'and Plant__r.Status__c ='Active'
                                               and (Product__r.QuantityUnitOfMeasure='MWp' OR Product__r.QuantityUnitOfMeasure='MWh' OR Product__r.QuantityUnitOfMeasure='WGT') 
                                               and Plant__c!=null ];
        for(Plant_Product_Transaction__c se: p){
            accId.add(se.Account__c);
        }
        
        
        set<id> plist = new set<id>();
        List<Account_Plant__c> pe =[select id, name,Account__c from Account_Plant__c where Account__c=:accId];
        
        for(Account_Plant__c pl:pe){
            plist.add(pl.id);
        }
        
        String query = 'SELECT id,Plant__c, Account__c,plant__r.Asset_Class__c,status__c,MWp_Quantity__c  FROM '+
            ' Plant_Product_Transaction__c WHERE Status__c = \'contracted\' and '+
            ' (Product__r.QuantityUnitOfMeasure=\'MWp\' OR Product__r.QuantityUnitOfMeasure=\'MWh\' OR'+
            ' Product__r.QuantityUnitOfMeasure=\'WGT\') and '+
            ' plant__c=:plist';// AND Contract__r.status = \'Activated\'
        system.debug('********the query2******'+query);
        return Database.getQueryLocator(query);
    } 
    
    
    global void execute(Database.BatchableContext bc, List<Plant_Product_Transaction__c> scope){
        
        Set<Id> accountIdset = new Set<Id>();
        
        for(Plant_Product_Transaction__c pData :scope){
            if(pData.Account__c!=null)accountIdset.add(pData.Account__c);
        }
        
        List<Active_Megawatts__c> existingAmw = [SELECT Id,Account__c FROM Active_Megawatts__c  WHERE Account__c IN: accountIdset];
        
        Map<Id, Active_Megawatts__c> existingAMWMap = new Map<Id, Active_Megawatts__c>();
        for(Active_Megawatts__c amw : existingAmw){
            existingAMWMap.put(amw.Account__c , amw);
        }
        
        
        List<Plant_Product_Transaction__c> pptRecordsList = [SELECT Name, MWp_Quantity__c,plant__r.Asset_Class__c,Plant__c ,Plant__r.Plant__c, Quote_Line__r.SBQQ__Quote__c , plant__r.Plant_MWP__c,Account__c,Account__r.ParentId FROM Plant_Product_Transaction__c
                                                             WHERE Account__c In:accountIdset AND Status__c ='Contracted'and MWp_Quantity__c!=null AND plant__c!=null and 
																( ( Account__r.ParentId != null AND Account__r.Parent.RecordType.name = 'Customer') OR Account__r.Ultimate_Parent_Account__c = Null) and
                                                             Account__r.RecordType.name = 'Customer' AND
                                                             ( plant__r.Asset_Class__c='Solar' 
                                                              OR plant__r.Asset_Class__c='Other Renewable'
                                                              OR plant__r.Asset_Class__c='Wind'
                                                              OR plant__r.Asset_Class__c='Hydro'
                                                              OR plant__r.Asset_Class__c='Storage')
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
				///accountRelationShipMap.put(ppt.Account__r.ParentId,ppt.Account__c);
            }
            
            if(ppt.Account__c != null && ppt.Account__r.ParentId == null){
                indipendatAccIds.add(ppt.Account__c);
            }
        }
        
        System.debug('indipendatAccIds--'+indipendatAccIds);
        System.debug('accountRelationShipMap--'+accountRelationShipMap);
        
        /*
        List<Account> accountWithNoAMandPPt = [SELECT Id From Account WHERE Id NOT In :accountIdset AND Id NOT In (SELECT Account__c  from Active_Megawatts__c)];
        
        System.debug('accountWithNoAMandPPt---'+accountWithNoAMandPPt);
        
        map<id,Active_Megawatts__c> independantAMWWithIndipendatAcc =  new map<id,Active_Megawatts__c>();
        
        for(Account acc : accountWithNoAMandPPt){
            Active_Megawatts__c amw = new Active_Megawatts__c(
                
                Total_Agnostic__c			= 	0,
                Total_MW_Hydro__c 			= 	0 ,
                Total_MW_Industrial__c		=	0 ,
                Total_MW_Other_Renewable__c	=	0 ,
                Total_MW_Solar__c			=	0 ,
                Total_MW_Storage__c			=	0 ,
                Total_MW_Wind__c			=	0 ,
                
                MW_Agnostic__c 				=	0,
                MW_Hydro__c 				=	0 ,
                MW_Industrial__c 			= 	0 ,
                MW_Other_Renewable__c 		= 	0 ,
                MW_Solar__c 				= 	0 ,
                MW_Storage__c 				= 	0 ,
                MW_Wind__c					=	0 ,
                
                Child_MW_Agnostic__c		=	0 ,
                Child_MW_Hydro__c			=	0 ,
                Child_MW_Industrial__c		=	0 ,
                Child_MW_Other_Renewable__c	=	0 ,
                Child_MW_Solar__c 			=	0 ,
                Child_MW_Storage__c 		=	0 ,
                Child_MW_Wind__c 			= 	0 ,
                
                Account__c					= 	acc.Id
            );
            independantAMWWithIndipendatAcc.put(acc.Id,amw);
        }
        */
        
        for(Id pptId : pptMap.keySet()){
            system.debug('Account Id ->'+pptId);
            Decimal SumSolar =0;
            Decimal SumWind =0;
            Decimal SumHydro =0;
            Decimal SumStorage =0;
            Decimal SumOtherRenewable=0;
            Decimal SumIndustrial=0;
            
            //Map<Id , Set<Id>> plantPptMap = new Map<Id , Set<Id>>();
            //
            
            Map<Id , Map<String, Decimal>> plantPptMap2 = new Map<Id ,Map<String, Decimal>>();
            
            Set<Id> plantIds = new Set<Id>();
            for(Plant_Product_Transaction__c pData :pptMap.get(pptId)){
                system.debug(pData.plant__r.Asset_Class__c +'----PPT Records under AccID ---->'+pData.MWp_Quantity__c);
                if(pData.plant__r.Plant_MWP__c!=null)
                {	
                    /*
                    if(plantPptMap.containsKey(pData.Quote_Line__r.SBQQ__Quote__c) && !plantPptMap.get(pData.Quote_Line__r.SBQQ__Quote__c).contains(pData.Plant__c)){
                        //SumOfDrive += pData.plant__r.Plant_MWP__c;
                        plantPptMap.get(pData.Quote_Line__r.SBQQ__Quote__c).add(pData.Plant__c);
                        
                    }else if (!plantPptMap.containsKey(pData.Quote_Line__r.SBQQ__Quote__c)){
                        plantPptMap.put(pData.Quote_Line__r.SBQQ__Quote__c , new Set<Id> {pData.Plant__c});
                    }
                    */
                    system.debug(plantPptMap2.containsKey(pData.Plant__r.Plant__c));
                    system.debug('plantPptMap2.get(pData.Plant__c)--'+plantPptMap2.get(pData.Plant__r.Plant__c));
                    system.debug('pData.plant__r.Asset_Class__c--'+pData.plant__r.Asset_Class__c);
                    //system.debug('!plantPptMap2.get(pData.Plant__c).containsKey(pData.plant__r.Asset_Class__c)--'+!plantPptMap2.get(pData.Plant__c).containsKey(pData.plant__r.Asset_Class__c));
                    if(plantPptMap2.containsKey(pData.Plant__r.Plant__c) && !plantPptMap2.get(pData.Plant__r.Plant__c).containsKey(pData.plant__r.Asset_Class__c)){
                        //SumOfDrive += pData.plant__r.Plant_MWP__c;
                        plantPptMap2.get(pData.Plant__r.Plant__c).put(pData.plant__r.Asset_Class__c, pData.plant__r.Plant_MWP__c);
                        
                    }else if (!plantPptMap2.containsKey(pData.Plant__c)){
                        plantPptMap2.put(pData.Plant__r.Plant__c , new Map<String, Decimal>{pData.plant__r.Asset_Class__c => pData.plant__r.Plant_MWP__c});
                    }
					
                    
					system.debug(pData.Plant__r.Plant__c+'-----------'+pData.Name+'---'+pData.Id+'---'+pData.plant__r.Asset_Class__c +'-------'+pData.plant__r.Plant_MWP__c);
                    
                }
            }
            
            for(Id plantId : plantPptMap2.keySet()){
                for(String assetClass : plantPptMap2.get(plantId).keySet()){
                    if(assetClass == 'Solar'){
                        SumSolar +=  plantPptMap2.get(plantId).get(assetClass);
                    }
                    else if(assetClass == 'Other Renewable'){
                        SumOtherRenewable += plantPptMap2.get(plantId).get(assetClass);
                    }
                    else if(assetClass == 'Wind'){
                        SumWind += plantPptMap2.get(plantId).get(assetClass);
                    }
                    else if(assetClass == 'Hydro'){
                        SumHydro += plantPptMap2.get(plantId).get(assetClass);
                    }
                    else if(assetClass == 'Storage'){
                        SumStorage += plantPptMap2.get(plantId).get(assetClass);
                    }
                    else if(assetClass == 'Industrial'){
                        SumIndustrial += plantPptMap2.get(plantId).get(assetClass);
                    } 
                }
            }
            
            
            system.debug('SumSolar--->'+SumSolar);
            system.debug('SumOtherRenewable--->'+SumOtherRenewable);
            system.debug('SumWind--->'+SumWind);
            system.debug('SumHydro--->'+SumHydro);
            system.debug('SumStorage--->'+SumStorage);
            system.debug('SumIndustrial--->'+SumIndustrial);
           
            Decimal Total_Agnostic= SumStorage + SumWind + SumSolar + SumHydro+ SumOtherRenewable;
            Decimal Total_MW_Storage=SumStorage ;
            Decimal Total_MW_Other_Renewable=SumOtherRenewable;
            Decimal Total_MW_Wind =SumWind; 
            Decimal Total_MW_Hydro = SumHydro;
            Decimal Total_MW_Solar = SumSolar;
            Decimal Total_MW_Industrial = SumIndustrial;
            
            Decimal MW_Agnostic=SumStorage + SumWind + SumSolar + SumHydro+ SumOtherRenewable;
            Decimal MW_Storage=SumStorage;
           	Decimal MW_Other_Renewable=SumOtherRenewable;
            Decimal MW_Wind =SumWind;
            Decimal MW_Solar = SumSolar;
            Decimal MW_Hydro = SumHydro;
            Decimal MW_Industrial = SumIndustrial;
            
            Decimal Child_MW_Agnostic= SumStorage + SumWind + SumSolar + SumHydro+ SumOtherRenewable;
            Decimal Child_MW_Storage=SumStorage;
           	Decimal Child_MW_Other_Renewable=SumOtherRenewable;
            Decimal Child_MW_Wind =SumWind;
            Decimal Child_MW_Solar = SumSolar;
            Decimal Child_MW_Hydro = SumHydro;
            Decimal Child_MW_Industrial = SumIndustrial;
            
            
            ActiveMegawatWrapper wrp = new ActiveMegawatWrapper(
                Total_Agnostic,
                Total_MW_Storage,
                Total_MW_Hydro,
                Total_MW_Industrial,
                Total_MW_Wind,
                Total_MW_Other_Renewable,
                Total_MW_Solar,
                
                MW_Agnostic,
                MW_Storage,
                MW_Other_Renewable,
                MW_Wind,
                MW_Solar,
                MW_Hydro,
                MW_Industrial,
                
                Child_MW_Agnostic,
                Child_MW_Storage,
                Child_MW_Other_Renewable,
                Child_MW_Wind,
                Child_MW_Solar,
                Child_MW_Hydro,
                Child_MW_Industrial
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
            /*
            if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(indipAccId)){
                Active_Megawatts__c existingAMW = existingAMWMap.get(indipAccId);
                
                
                existingAMW.Total_Agnostic__c			= 	amwWrapper.MW_Agnostic;
                    existingAMW.Total_MW_Hydro__c 			= 	amwWrapper.MW_Hydro ;
                    existingAMW.Total_MW_Industrial__c		=	amwWrapper.MW_Industrial ;
                    existingAMW.Total_MW_Other_Renewable__c	=	amwWrapper.MW_Other_Renewable ;
                    existingAMW.Total_MW_Solar__c			=	amwWrapper.MW_Solar ;
                    existingAMW.Total_MW_Storage__c			=	amwWrapper.MW_Storage ;
                    existingAMW.Total_MW_Wind__c			=	amwWrapper.MW_Wind ;
                    
                    existingAMW.MW_Agnostic__c 				=	amwWrapper.MW_Agnostic;
                    existingAMW.MW_Hydro__c 				=	amwWrapper.MW_Hydro ;
                    existingAMW.MW_Industrial__c 			= 	amwWrapper.MW_Industrial ;
                    existingAMW.MW_Other_Renewable__c 		= 	amwWrapper.MW_Other_Renewable ;
                    existingAMW.MW_Solar__c 				= 	amwWrapper.MW_Solar ;
                    existingAMW.MW_Storage__c 				= 	amwWrapper.MW_Storage ;
                    existingAMW.MW_Wind__c					=	amwWrapper.MW_Wind ;
                    
                    existingAMW.Child_MW_Agnostic__c		=	0 ;
                    existingAMW.Child_MW_Hydro__c			=	0 ;
                    existingAMW.Child_MW_Industrial__c		=	0 ;
                    existingAMW.Child_MW_Other_Renewable__c	=	0 ;
                    existingAMW.Child_MW_Solar__c 			=	0 ;
                    existingAMW.Child_MW_Storage__c 		=	0 ;
                    existingAMW.Child_MW_Wind__c 			= 	0 ;
                
                
            } */
            
            if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(indipAccId)){
                Active_Megawatts__c amw = existingAMWMap.get(indipAccId).clone(true,true,true,true);
                amw.Total_Agnostic__c			= 	amwWrapper.MW_Agnostic;
                amw.Total_MW_Hydro__c 			= 	amwWrapper.MW_Hydro ;
                amw.Total_MW_Industrial__c		=	amwWrapper.MW_Industrial ;
                amw.Total_MW_Other_Renewable__c	=	amwWrapper.MW_Other_Renewable ;
                amw.Total_MW_Solar__c			=	amwWrapper.MW_Solar ;
                amw.Total_MW_Storage__c			=	amwWrapper.MW_Storage ;
                amw.Total_MW_Wind__c			=	amwWrapper.MW_Wind ;
                
                amw.MW_Agnostic__c 				=	amwWrapper.MW_Agnostic;
                amw.MW_Hydro__c 				=	amwWrapper.MW_Hydro ;
                amw.MW_Industrial__c 			= 	amwWrapper.MW_Industrial ;
                amw.MW_Other_Renewable__c 		= 	amwWrapper.MW_Other_Renewable ;
                amw.MW_Solar__c 				= 	amwWrapper.MW_Solar ;
                amw.MW_Storage__c 				= 	amwWrapper.MW_Storage ;
                amw.MW_Wind__c					=	amwWrapper.MW_Wind ;
                
                amw.Child_MW_Agnostic__c		=	0 ;
                amw.Child_MW_Hydro__c			=	0 ;
                amw.Child_MW_Industrial__c		=	0 ;
                amw.Child_MW_Other_Renewable__c	=	0 ;
                amw.Child_MW_Solar__c 			=	0 ;
                amw.Child_MW_Storage__c 		=	0 ;
                amw.Child_MW_Wind__c 			= 	0 ;
                
                independantAMW.put(indipAccId,amw);
            }
            else{
                Active_Megawatts__c amw = new Active_Megawatts__c(
                    
                    Total_Agnostic__c			= 	amwWrapper.MW_Agnostic,
                    Total_MW_Hydro__c 			= 	amwWrapper.MW_Hydro ,
                    Total_MW_Industrial__c		=	amwWrapper.MW_Industrial ,
                    Total_MW_Other_Renewable__c	=	amwWrapper.MW_Other_Renewable ,
                    Total_MW_Solar__c			=	amwWrapper.MW_Solar ,
                    Total_MW_Storage__c			=	amwWrapper.MW_Storage ,
                    Total_MW_Wind__c			=	amwWrapper.MW_Wind ,
                    
                    MW_Agnostic__c 				=	amwWrapper.MW_Agnostic,
                    MW_Hydro__c 				=	amwWrapper.MW_Hydro ,
                    MW_Industrial__c 			= 	amwWrapper.MW_Industrial ,
                    MW_Other_Renewable__c 		= 	amwWrapper.MW_Other_Renewable ,
                    MW_Solar__c 				= 	amwWrapper.MW_Solar ,
                    MW_Storage__c 				= 	amwWrapper.MW_Storage ,
                    MW_Wind__c					=	amwWrapper.MW_Wind ,
                    
                    Child_MW_Agnostic__c		=	0 ,
                    Child_MW_Hydro__c			=	0 ,
                    Child_MW_Industrial__c		=	0 ,
                    Child_MW_Other_Renewable__c	=	0 ,
                    Child_MW_Solar__c 			=	0 ,
                    Child_MW_Storage__c 		=	0 ,
                    Child_MW_Wind__c 			= 	0 ,
                    
                    Account__c					= 	indipAccId
                );
                independantAMW.put(indipAccId,amw);
            }
            
        }    
        
        map<id,Active_Megawatts__c> mer =  new map<id,Active_Megawatts__c>();
        map<id,Active_Megawatts__c> childActiveMegawatsMaps =  new map<id,Active_Megawatts__c>();
        List<Active_Megawatts__c> activeMWtoInsert = new List<Active_Megawatts__c>();
        for(Id parentAccId : accountRelationShipMap.keySet()){
				
				
				Decimal Sum_Total_Agnostic = 0;
                Decimal Sum_Total_MW_Storage = 0;
                Decimal Sum_Total_MW_Hydro = 0;
                Decimal Sum_Total_MW_Industrial = 0;
                Decimal Sum_Total_MW_Wind = 0;
                Decimal Sum_Total_MW_Other_Renewable = 0;
                Decimal Sum_Total_MW_Solar = 0;
                
                Decimal Sum_MW_Agnostic = 0;
                Decimal Sum_MW_Storage = 0;
                Decimal Sum_MW_Other_Renewable = 0;
                Decimal Sum_MW_Wind = 0;
                Decimal Sum_MW_Solar = 0;
                Decimal Sum_MW_Hydro = 0;
                Decimal Sum_MW_Industrial = 0;
                
                Decimal Sum_Child_MW_Agnostic = 0;
                Decimal Sum_Child_MW_Storage = 0;
                Decimal Sum_Child_MW_Other_Renewable = 0;
                Decimal Sum_Child_MW_Wind = 0;
                Decimal Sum_Child_MW_Solar = 0;
                Decimal Sum_Child_MW_Hydro = 0;
                Decimal Sum_Child_MW_Industrial = 0;

            for(Id childAccIds :  accountRelationShipMap.get(parentAccId)){
                
                if(accCalculationMap.containsKey(childAccIds)){
                    Sum_Total_Agnostic  +=	accCalculationMap.get(childAccIds).Total_Agnostic;
                    Sum_Total_MW_Storage  +=	accCalculationMap.get(childAccIds).Total_MW_Storage;
                    Sum_Total_MW_Hydro  +=	accCalculationMap.get(childAccIds).Total_MW_Hydro;
                    Sum_Total_MW_Industrial  +=	accCalculationMap.get(childAccIds).Total_MW_Industrial;
                    Sum_Total_MW_Wind  +=	accCalculationMap.get(childAccIds).Total_MW_Wind;
                    Sum_Total_MW_Other_Renewable  +=	accCalculationMap.get(childAccIds).Total_MW_Other_Renewable;
                    Sum_Total_MW_Solar  +=	accCalculationMap.get(childAccIds).Total_MW_Solar;
                    
                    Sum_MW_Agnostic  +=	accCalculationMap.get(childAccIds).MW_Agnostic;
                    Sum_MW_Storage  +=	accCalculationMap.get(childAccIds).MW_Storage;
                    Sum_MW_Other_Renewable  +=	accCalculationMap.get(childAccIds).MW_Other_Renewable;
                    Sum_MW_Wind  +=	accCalculationMap.get(childAccIds).MW_Wind;
                    Sum_MW_Solar  +=	accCalculationMap.get(childAccIds).MW_Solar;
                    Sum_MW_Hydro  +=	accCalculationMap.get(childAccIds).MW_Hydro;
                    Sum_MW_Industrial  +=	accCalculationMap.get(childAccIds).MW_Industrial;
                    
                    Sum_Child_MW_Agnostic  +=	accCalculationMap.get(childAccIds).Child_MW_Agnostic;
                    Sum_Child_MW_Storage  +=	accCalculationMap.get(childAccIds).Child_MW_Storage;
                    Sum_Child_MW_Other_Renewable  +=	accCalculationMap.get(childAccIds).Child_MW_Other_Renewable;
                    Sum_Child_MW_Wind  +=	accCalculationMap.get(childAccIds).Child_MW_Wind;
                    Sum_Child_MW_Solar  +=	accCalculationMap.get(childAccIds).Child_MW_Solar;
                    Sum_Child_MW_Hydro  +=	accCalculationMap.get(childAccIds).Child_MW_Hydro;
                    Sum_Child_MW_Industrial  +=	accCalculationMap.get(childAccIds).Child_MW_Industrial;
                    
                    
                    ActiveMegawatWrapper parentFields = accCalculationMap.get(childAccIds);
                    
                    if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(childAccIds)){
                        Active_Megawatts__c amw = existingAMWMap.get(childAccIds).clone(true,true,true,true);
                        amw.Total_Agnostic__c			= 	parentFields.MW_Agnostic;
                        amw.Total_MW_Hydro__c 			= 	parentFields.MW_Hydro ;
                        amw.Total_MW_Industrial__c		=	parentFields.MW_Industrial ;
                        amw.Total_MW_Other_Renewable__c	=	parentFields.MW_Other_Renewable ;
                        amw.Total_MW_Solar__c			=	parentFields.MW_Solar ;
                        amw.Total_MW_Storage__c			=	parentFields.MW_Storage ;
                        amw.Total_MW_Wind__c			=	parentFields.MW_Wind ;
                        
                        amw.MW_Agnostic__c 				=	parentFields.MW_Agnostic;
                        amw.MW_Hydro__c 				=	parentFields.MW_Hydro ;
                        amw.MW_Industrial__c 			= 	parentFields.MW_Industrial ;
                        amw.MW_Other_Renewable__c 		= 	parentFields.MW_Other_Renewable ;
                        amw.MW_Solar__c 				= 	parentFields.MW_Solar ;
                        amw.MW_Storage__c 				= 	parentFields.MW_Storage ;
                        amw.MW_Wind__c					=	parentFields.MW_Wind ;
                        
                        amw.Child_MW_Agnostic__c		=	0 ;
                        amw.Child_MW_Hydro__c			=	0 ;
                        amw.Child_MW_Industrial__c		=	0 ;
                        amw.Child_MW_Other_Renewable__c	=	0 ;
                        amw.Child_MW_Solar__c 			=	0 ;
                        amw.Child_MW_Storage__c 		=	0 ;
                        amw.Child_MW_Wind__c 			= 	0 ;
                        
                        childActiveMegawatsMaps.put(childAccIds,amw);
                    }
                    else{
                        Active_Megawatts__c awForChildAccount = new Active_Megawatts__c(
                            Total_Agnostic__c			= 	parentFields.MW_Agnostic,
                            Total_MW_Hydro__c 			= 	parentFields.MW_Hydro ,
                            Total_MW_Industrial__c		=	parentFields.MW_Industrial ,
                            Total_MW_Other_Renewable__c	=	parentFields.MW_Other_Renewable ,
                            Total_MW_Solar__c			=	parentFields.MW_Solar ,
                            Total_MW_Storage__c			=	parentFields.MW_Storage ,
                            Total_MW_Wind__c			=	parentFields.MW_Wind ,
                            
                            MW_Agnostic__c 				=	parentFields.MW_Agnostic,
                            MW_Hydro__c 				=	parentFields.MW_Hydro ,
                            MW_Industrial__c 			= 	parentFields.MW_Industrial ,
                            MW_Other_Renewable__c 		= 	parentFields.MW_Other_Renewable ,
                            MW_Solar__c 				= 	parentFields.MW_Solar ,
                            MW_Storage__c 				= 	parentFields.MW_Storage ,
                            MW_Wind__c					=	parentFields.MW_Wind ,
                            
                            Child_MW_Agnostic__c		=	0 ,
                            Child_MW_Hydro__c			=	0 ,
                            Child_MW_Industrial__c		=	0 ,
                            Child_MW_Other_Renewable__c	=	0 ,
                            Child_MW_Solar__c 			=	0 ,
                            Child_MW_Storage__c 		=	0 ,
                            Child_MW_Wind__c 			= 	0 ,
                            
                            Account__c					= 	childAccIds
                        );
                        
                        childActiveMegawatsMaps.put(childAccIds,awForChildAccount);
                    }
                    
                    
                }
                
                
                
            }
            
            

                if(accCalculationMap.containsKey(parentAccId)){
                    
                    ActiveMegawatWrapper parentFields = accCalculationMap.get(parentAccId);
                    
                    
                    
                    if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(parentAccId)){
                        Active_Megawatts__c amw = existingAMWMap.get(parentAccId).clone(true,true,true,true);
                        amw.Total_Agnostic__c			= 	parentFields.MW_Agnostic;
                        amw.Total_MW_Hydro__c 			= 	parentFields.MW_Hydro ;
                        amw.Total_MW_Industrial__c		=	parentFields.MW_Industrial ;
                        amw.Total_MW_Other_Renewable__c	=	parentFields.MW_Other_Renewable ;
                        amw.Total_MW_Solar__c			=	parentFields.MW_Solar ;
                        amw.Total_MW_Storage__c			=	parentFields.MW_Storage ;
                        amw.Total_MW_Wind__c			=	parentFields.MW_Wind ;
                        
                        amw.MW_Agnostic__c 				=	parentFields.MW_Agnostic;
                        amw.MW_Hydro__c 				=	parentFields.MW_Hydro ;
                        amw.MW_Industrial__c 			= 	parentFields.MW_Industrial ;
                        amw.MW_Other_Renewable__c 		= 	parentFields.MW_Other_Renewable ;
                        amw.MW_Solar__c 				= 	parentFields.MW_Solar ;
                        amw.MW_Storage__c 				= 	parentFields.MW_Storage ;
                        amw.MW_Wind__c					=	parentFields.MW_Wind ;
                        
                        amw.Child_MW_Agnostic__c		=	0 ;
                        amw.Child_MW_Hydro__c			=	0 ;
                        amw.Child_MW_Industrial__c		=	0 ;
                        amw.Child_MW_Other_Renewable__c	=	0 ;
                        amw.Child_MW_Solar__c 			=	0 ;
                        amw.Child_MW_Storage__c 		=	0 ;
                        amw.Child_MW_Wind__c 			= 	0 ;
                        
                        mer.put(parentAccId,amw);
                    }
                    else{
                    	Active_Megawatts__c ae3 = new Active_Megawatts__c(
                            Total_Agnostic__c			= 	parentFields.Total_Agnostic +Sum_Total_Agnostic ,
                            Total_MW_Hydro__c 			= 	parentFields.Total_MW_Hydro +Sum_Total_MW_Hydro ,
                            Total_MW_Industrial__c		=	parentFields.Total_MW_Industrial +Sum_Total_MW_Industrial ,
                            Total_MW_Other_Renewable__c	=	parentFields.Total_MW_Other_Renewable +Sum_Total_MW_Other_Renewable ,
                            Total_MW_Solar__c			=	parentFields.Total_MW_Solar +Sum_Total_MW_Solar ,
                            Total_MW_Storage__c			=	parentFields.Total_MW_Storage +Sum_Total_MW_Storage ,
                            Total_MW_Wind__c			=	parentFields.Total_MW_Wind +Sum_Total_MW_Wind ,
                            
                            MW_Agnostic__c 				=	parentFields.MW_Agnostic,
                            MW_Hydro__c 				=	parentFields.MW_Hydro ,
                            MW_Industrial__c 			= 	parentFields.MW_Industrial ,
                            MW_Other_Renewable__c 		= 	parentFields.MW_Other_Renewable ,
                            MW_Solar__c 				= 	parentFields.MW_Solar ,
                            MW_Storage__c 				= 	parentFields.MW_Storage ,
                            MW_Wind__c					=	parentFields.MW_Wind ,
                            
                            Child_MW_Agnostic__c		=	Sum_Total_Agnostic ,
                            Child_MW_Hydro__c			=	Sum_Total_MW_Hydro ,
                            Child_MW_Industrial__c		=	Sum_Total_MW_Industrial ,
                            Child_MW_Other_Renewable__c	=	Sum_Total_MW_Other_Renewable ,
                            Child_MW_Solar__c 			=	Sum_Total_MW_Solar ,
                            Child_MW_Storage__c 		=	Sum_Total_MW_Storage ,
                            Child_MW_Wind__c 			= 	Sum_Total_MW_Wind ,
                            
                            Account__c					= 	parentAccId
                    );

                        mer.put(parentAccId,ae3);
                    }
             	}
        }
        
        activeMWtoInsert.addAll(mer.values());
        activeMWtoInsert.addAll(childActiveMegawatsMaps.values());
        activeMWtoInsert.addAll(independantAMW.values());
        
        
        mapToInsert.putAll(mer);
        mapToInsert.putAll(childActiveMegawatsMaps);
        mapToInsert.putAll(independantAMW); 
        //mapToInsert.putAll(independantAMWWithIndipendatAcc);
        system.debug('mer---'+mer.size());
        system.debug('childActiveMegawatsMaps---'+childActiveMegawatsMaps.size());
        system.debug('independantAMW---'+independantAMW.size());
        //System.debug('independantAMWWithIndipendatAcc--->'+independantAMWWithIndipendatAcc.Size());
        
        /*
        if(activeMWtoInsert != null && activeMWtoInsert.size() >0 ){
            try{
                insert activeMWtoInsert;
            }
            catch(Exception e){
                system.debug(e.getMessage());
            }
        }
        */
        
         
    }
    
    
    global void finish(Database.BatchableContext BC){
        system.debug(mapToInsert.size()+'---mapToInsert---'+mapToInsert);
        if(mapToInsert != null && mapToInsert.size() >0 ){
            
                upsert mapToInsert.values();
            
        }
    }
    
    public class ActiveMegawatWrapper{
        public Decimal Total_Agnostic;
        public Decimal Total_MW_Storage;
        public Decimal Total_MW_Hydro;
        public Decimal Total_MW_Industrial;
        public Decimal Total_MW_Solar;
        public Decimal Total_MW_Other_Renewable;
        public Decimal Total_MW_Wind;
        
        public Decimal MW_Agnostic;
        public Decimal MW_Storage;
        public Decimal MW_Other_Renewable;
        public Decimal MW_Wind;
        public Decimal MW_Solar;
        public Decimal MW_Hydro;
        public Decimal MW_Industrial;
        
        public Decimal Child_MW_Agnostic;
        public Decimal Child_MW_Storage;
        public Decimal Child_MW_Other_Renewable;
        public Decimal Child_MW_Wind;
        public Decimal Child_MW_Solar;
        public Decimal Child_MW_Hydro;
        public Decimal Child_MW_Industrial;
        
        
        public ActiveMegawatWrapper(
        	Decimal Total_Agnostic,
            Decimal Total_MW_Storage,
            Decimal Total_MW_Hydro,
            Decimal Total_MW_Industrial,
            Decimal Total_MW_Wind,
            Decimal Total_MW_Other_Renewable,
            Decimal Total_MW_Solar,

            
            Decimal MW_Agnostic,
            Decimal MW_Storage,
            Decimal MW_Other_Renewable,
            Decimal MW_Wind,
            Decimal MW_Solar,
            Decimal MW_Hydro,
            Decimal MW_Industrial,
            
            Decimal Child_MW_Agnostic,
            Decimal Child_MW_Storage,
            Decimal Child_MW_Other_Renewable,
            Decimal Child_MW_Wind,
            Decimal Child_MW_Solar,
            Decimal Child_MW_Hydro,
            Decimal Child_MW_Industrial
            
            
		){
            this.Total_Agnostic = Total_Agnostic;
            this.Total_MW_Hydro = Total_MW_Hydro;
            this.Total_MW_Storage = Total_MW_Storage;
            this.Total_MW_Other_Renewable = Total_MW_Other_Renewable;
            this.Total_MW_Solar = Total_MW_Solar;
            this.Total_MW_Wind = Total_MW_Wind;
            this.Total_MW_Industrial = Total_MW_Industrial;
            
            this.MW_Agnostic = MW_Agnostic;
            this.MW_Storage = MW_Storage;
            this.MW_Other_Renewable = MW_Other_Renewable;
            this.MW_Wind = MW_Wind;
			this.MW_Solar = MW_Solar;
            this.MW_Hydro = MW_Hydro;
            this.MW_Industrial = MW_Industrial;
			
            this.Child_MW_Agnostic =  Child_MW_Agnostic;
            this.Child_MW_Storage =  Child_MW_Storage;
            this.Child_MW_Other_Renewable =  Child_MW_Other_Renewable;
            this.Child_MW_Wind =  Child_MW_Wind;
            this.Child_MW_Solar =  Child_MW_Solar;
            this.Child_MW_Hydro =  Child_MW_Hydro;
            this.Child_MW_Industrial = Child_MW_Industrial;

        }
    }
}