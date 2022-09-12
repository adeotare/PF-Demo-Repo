global class AccountHierarchyproductfamily implements Database.Batchable<SObject> ,Database.Stateful {
    
    public Set<Id> idSetToTest = new Set<Id>();
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
        
        
        List<Plant_Product_Transaction__c> pptRecordsList = [SELECT Name, 
                                                             		MWp_Quantity__c,
                                                             		Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c , 
                                                             		Account__r.Uses_MSA_of__r.Parent_MSA_Opt_Out__c , 
                                                             		Account__r.Name,
                                                             		Account__r.Parent.Name,
                                                             		Account__r.Ultimate_Parent_Account__r.Uses_MSA_of__c,
                                                             		Account__r.Parent.Uses_MSA_of__c,
                                                             		Product_Family__c,
                                                             		Plant_Name__c,
                                                                    plant__r.Asset_Class__c,
                                                                    plant__r.Plant_MWP__c,
                                                                    Account__c,
                                                                    Account__r.ParentId 
                                                             FROM Plant_Product_Transaction__c
                                                             //WHERE Account__c In:accountIdset 
                                                             WHERE Account__c In :accountIdset
                                                             AND Status__c ='Contracted'
                                                             AND MWp_Quantity__c!=null 
                                                             AND plant__c!=null 
                                                             AND (( Account__r.ParentId != null 
                                                                  ) 
                                                                  OR Account__r.Ultimate_Parent_Account__c = Null) 
                                                            
                                                             AND (Product_Family__c ='Drive' OR
                                                                  Product_Family__c ='Greenbyte' OR
                                                                  Product_Family__c ='BluePoint' OR
                                                                  Product_Family__c='Ekhosoft') ];
        
        Map<Id, List<Plant_Product_Transaction__c>> pptMap = new Map<Id, List<Plant_Product_Transaction__c>>();
        Map<Id,List<Id>> accountRelationShipMap = new Map<Id,List<Id>>();
        
        Map<Id,List<Id>> accountRelationShipMapWithParentOptOut = new Map<Id,List<Id>>();
        
        Map<Id,List<Id>> ultimateParentAndItsAcc = new Map<Id,List<Id>>();
        
        Set<Id> accSet1 = new Set<Id>();
        Set<Id> accSet2 = new Set<Id>();
        
        Map<Id,ActiveMegawatWrapper> accCalculationMap = new Map<Id,ActiveMegawatWrapper>();
        
        Map<Id,ActiveMegawatWrapper> independantAccount = new Map<Id,ActiveMegawatWrapper>();
        Set<Id> indipendatAccIds = new Set<Id>();
        
        
       	for(Plant_Product_Transaction__c ppt : pptRecordsList ){
            if(pptMap.containsKey(ppt.Account__c)){
                pptMap.get(ppt.Account__c).add(ppt);
            }else{
                pptMap.put(ppt.Account__c , new List<Plant_Product_Transaction__c>{ppt});
            }    
            
            System.debug('ppt.Account__c-->'+ppt.Account__c + '->'+ppt.Account__r.Name);
            System.debug('ppt.Account__r.ParentId-->'+ppt.Account__r.ParentId + '->'+ppt.Account__r.Parent.Name);
            System.debug('ppt.Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c-->'+ppt.Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c );
            
            if(ppt.Account__c != null 
               && ppt.Account__r.ParentId != null 
               && ppt.Account__r.Uses_MSA_of__r.Parent_MSA_Opt_Out__c != 'Yes'
               && (ppt.Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c != 'Yes')
               && !accSet2.contains(ppt.Account__c)
               && !accSet2.contains(ppt.Account__r.ParentId)){
                   
                   System.debug('ppt.Account__c-->'+ppt.Account__c + '->'+ppt.Account__r.Name );
                   System.debug('ppt.Account__r.ParentId-->'+ppt.Account__r.ParentId + '->'+ppt.Account__r.Parent.Name);
                   System.debug('ppt.Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c-->'+ppt.Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c );
                   
                   accSet1.add(ppt.Account__c);
                   accSet1.add(ppt.Account__r.ParentId);
                   if(accountRelationShipMap.containsKey(ppt.Account__r.ParentId)){
                       if(!accountRelationShipMap.get(ppt.Account__r.ParentId).contains(ppt.Account__c)){
                           accountRelationShipMap.get(ppt.Account__r.ParentId).add(ppt.Account__c);                        
                       }
                   }else{
                       accountRelationShipMap.put(ppt.Account__r.ParentId , new List<Id>{ppt.Account__c});
                   } 
                   
                   if( ppt.Account__r.ParentId == ppt.Account__r.Ultimate_Parent_Account__c &&
                      ppt.Account__r.Ultimate_Parent_Account__r.Uses_MSA_of__c == ppt.Account__r.Uses_MSA_of__c ){
                          system.debug('in iff');
                          if(ultimateParentAndItsAcc.containsKey(ppt.Account__r.ParentId)){
                              if(!ultimateParentAndItsAcc.get(ppt.Account__r.ParentId).contains(ppt.Account__c)){
                                  system.debug('in iff-2 ');
                                  ultimateParentAndItsAcc.get(ppt.Account__r.ParentId).add(ppt.Account__c);                        
                              }
                          }else{
                              system.debug('in else');
                              ultimateParentAndItsAcc.put(ppt.Account__r.ParentId , new List<Id>{ppt.Account__c});
                          } 
                      }
               }
            
            if(ppt.Account__c != null 
               && ppt.Account__r.ParentId != null 
               && ppt.Account__r.Ultimate_Parent_Account__r.Uses_MSA_of__c != ppt.Account__r.Parent.Uses_MSA_of__c
               && ppt.Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c == 'Yes' 
               && !accSet1.contains(ppt.Account__c)
               && !accSet1.contains(ppt.Account__r.ParentId)){
                
                   
                   accSet2.add(ppt.Account__c);
                   accSet2.add(ppt.Account__r.ParentId);
                   
                   System.debug('ppt.Account__c-->'+ppt.Account__c + '->'+ppt.Account__r.Name );
                   System.debug('ppt.Account__r.ParentId-->'+ppt.Account__r.ParentId + '->'+ppt.Account__r.Parent.Name);
                   System.debug('ppt.Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c-->'+ppt.Account__r.Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c );
                   
                   if(accountRelationShipMapWithParentOptOut.containsKey(ppt.Account__r.ParentId)){
                       if(!accountRelationShipMapWithParentOptOut.get(ppt.Account__r.ParentId).contains(ppt.Account__c)){
                           accountRelationShipMapWithParentOptOut.get(ppt.Account__r.ParentId).add(ppt.Account__c);                        
                       }
                   }else{
                       accountRelationShipMapWithParentOptOut.put(ppt.Account__r.ParentId , new List<Id>{ppt.Account__c});
                   } 
               }
            
            
            
            if(ppt.Account__c != null && ppt.Account__r.ParentId == null){
                indipendatAccIds.add(ppt.Account__c);
            }
        }
        
        for(Id key: accountRelationShipMapWithParentOptOut.keySet()){
            System.debug('accountRelationShipMapWithParentOptOut Id-->'+key+ ' :: '+accountRelationShipMapWithParentOptOut.get(key));
        }
        
        for(Id key: accountRelationShipMap.keySet()){
            System.debug('accountRelationShipMap Id-->'+key +' :: '+accountRelationShipMap.get(key));
        }
        
        for(Id pptId : pptMap.keySet()){
            system.debug('Account Id ->'+pptId);
            Decimal SumOfDrive =0;
            Decimal SumOfGreenByte =0;
            Decimal SumOfBluePoint =0;
            Decimal SumOfEkhoSoft=0;
            
            Map<String , Map<String , Decimal>> productPptMap = new Map<String , Map<String , Decimal>>();
            
            for(Plant_Product_Transaction__c pData :pptMap.get(pptId)){
                system.debug(pData.plant__r.Asset_Class__c +'----PPT Records under AccID ---->'+pData.MWp_Quantity__c);
                if(pData.plant__r.Plant_MWP__c!=null){
                    system.debug(pData.Plant_Name__c+'---'+pData.Id+'---'+pData.Product_Family__c +'-------'+pData.plant__r.Plant_MWP__c);
                    
                    if(productPptMap.containsKey(pData.Product_Family__c) && !productPptMap.get(pData.Product_Family__c).containsKey(pData.Plant_Name__c)){
                        productPptMap.get(pData.Product_Family__c).put(pData.Plant_Name__c , pData.plant__r.Plant_MWP__c);
                    }
                    else if (!productPptMap.containsKey(pData.Product_Family__c)){
                        productPptMap.put(pData.Product_Family__c , new Map<String, Decimal>{pData.Plant_Name__c => pData.plant__r.Plant_MWP__c});
                    }
                }
            }
            
            for(String prodFamily : productPptMap.keySet()){
                if(prodFamily == 'Drive'){
                    for(Decimal mwp : productPptMap.get(prodFamily).values())SumOfDrive += mwp;
                }else if(prodFamily == 'Greenbyte'){
                    for(Decimal mwp : productPptMap.get(prodFamily).values())SumOfGreenByte += mwp;
                }else if(prodFamily == 'BluePoint'){
                    for(Decimal mwp : productPptMap.get(prodFamily).values())SumOfBluePoint += mwp;
                }
            }
            Decimal Total_MW_Bluepoint 	= SumOfBluePoint;
            Decimal Total_MW_Drive 		= SumOfDrive;
            Decimal Total_MW_Greenbyte 	= SumOfGreenByte;
            
            Decimal MW_Bluepoint 		= SumOfBluePoint;
            Decimal MW_Drive 			= SumOfDrive;
            Decimal MW_Greenbyte 		= SumOfGreenByte;
            
            Decimal Child_MW_Bluepoint 	= SumOfBluePoint;
            Decimal Child_MW_Drive 		= SumOfDrive;
            Decimal Child_MW_Greenbyte 	= SumOfGreenByte;
            
            ActiveMegawatWrapper wrp = new ActiveMegawatWrapper(
               Total_MW_Bluepoint, 
                Total_MW_Drive ,
                Total_MW_Greenbyte ,
                
                MW_Bluepoint ,
                MW_Drive ,
                MW_Greenbyte ,
                
                Child_MW_Bluepoint ,
                Child_MW_Drive ,
                Child_MW_Greenbyte 
			);
            accCalculationMap.put(pptId, wrp);
        }
		
		for(Id accId : accCalculationMap.keySet()){
            if(indipendatAccIds.contains(accId) && !accountRelationShipMap.keySet().contains(accId) && !accountRelationShipMapWithParentOptOut.keySet().contains(accId)){
                independantAccount.put(accId , accCalculationMap.get(accId));
            }
        }
        
		// for the scenario parent have no PPT and child have PPT and they are in hierarchy : 
		//Start -- 
        map<id,Active_Megawatts__c> patentWitoutPPTChildWithPPT =  new map<id,Active_Megawatts__c>();
        for(Id accId : accountRelationShipMap.KeySet() ){
            if(!accCalculationMap.KeySet().contains(accId)){
                Decimal Sum_Total_MW_Bluepoint 	= 0;
                Decimal Sum_Total_MW_Drive 		= 0;
                Decimal Sum_Total_MW_Greenbyte 	= 0;
                
                
                for(Id childAccId : accountRelationShipMap.get(accId)){
                    if(accCalculationMap.KeySet().contains(childAccId)){
                        Sum_Total_MW_Bluepoint 	+= accCalculationMap.get(childAccId).Total_MW_Bluepoint;
                        Sum_Total_MW_Drive  	+= accCalculationMap.get(childAccId).Total_MW_Drive;
                        Sum_Total_MW_Greenbyte 	+= accCalculationMap.get(childAccId).Total_MW_Greenbyte;
                   }
                    
                }
                if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(accId)){
                        Active_Megawatts__c amw = existingAMWMap.get(accId).clone(true,true,true,true);
                        
                        amw.Total_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint ;
                        amw.Total_MW_Drive__c 		= Sum_Total_MW_Drive ;
                        amw.Total_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte ;
                        
                        amw.MW_Bluepoint__c 		= 0 ;
                        amw.MW_Drive__c 			= 0 ;
                        amw.MW_Greenbyte__c 		= 0 ;
                        
                        amw.Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint;
                        amw.Child_MW_Drive__c 		= Sum_Total_MW_Drive;
                        amw.Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte;
                        
                        patentWitoutPPTChildWithPPT.put(accId,amw);
                        
                    }
                    else{
                        Active_Megawatts__c awForChildAccount = new Active_Megawatts__c(
                            
                            Total_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint ,
                            Total_MW_Drive__c 		= Sum_Total_MW_Drive ,
                            Total_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte ,
                            
                            MW_Bluepoint__c 		= 0 ,
                            MW_Drive__c 			= 0 ,
                            MW_Greenbyte__c 		= 0 ,
                            
                            Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint,
                            Child_MW_Drive__c 		= Sum_Total_MW_Drive,
                            Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte,
                            
                            Account__c					= 	accId
                        );
                        patentWitoutPPTChildWithPPT.put(accId,awForChildAccount);
                    }
            }
        }
        
        map<id,Active_Megawatts__c> patentWitoutPPTChildWithPPT2 =  new map<id,Active_Megawatts__c>();
        for(Id accId : accountRelationShipMapWithParentOptOut.KeySet() ){
            if(!accCalculationMap.KeySet().contains(accId)){
                Decimal Sum_Total_MW_Bluepoint 	= 0;
                Decimal Sum_Total_MW_Drive 		= 0;
                Decimal Sum_Total_MW_Greenbyte 	= 0;
                
                
                for(Id childAccId : accountRelationShipMapWithParentOptOut.get(accId)){
                    if(accCalculationMap.KeySet().contains(childAccId)){
                        Sum_Total_MW_Bluepoint 	+= accCalculationMap.get(childAccId).Total_MW_Bluepoint;
                        Sum_Total_MW_Drive  	+= accCalculationMap.get(childAccId).Total_MW_Drive;
                        Sum_Total_MW_Greenbyte 	+= accCalculationMap.get(childAccId).Total_MW_Greenbyte;
                   }
                    
                }
                if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(accId)){
                        Active_Megawatts__c amw = existingAMWMap.get(accId).clone(true,true,true,true);
                        
                        amw.Total_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint ;
                        amw.Total_MW_Drive__c 		= Sum_Total_MW_Drive ;
                        amw.Total_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte ;
                        
                        amw.MW_Bluepoint__c 		= 0 ;
                        amw.MW_Drive__c 			= 0 ;
                        amw.MW_Greenbyte__c 		= 0 ;
                        
                        amw.Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint;
                        amw.Child_MW_Drive__c 		= Sum_Total_MW_Drive;
                        amw.Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte;
                        
                        patentWitoutPPTChildWithPPT2.put(accId,amw);
                        
                    }
                    else{
                        Active_Megawatts__c awForChildAccount = new Active_Megawatts__c(
                            
                            Total_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint ,
                            Total_MW_Drive__c 		= Sum_Total_MW_Drive ,
                            Total_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte ,
                            
                            MW_Bluepoint__c 		= 0 ,
                            MW_Drive__c 			= 0 ,
                            MW_Greenbyte__c 		= 0 ,
                            
                            Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint,
                            Child_MW_Drive__c 		= Sum_Total_MW_Drive,
                            Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte,
                            
                            Account__c					= 	accId
                        );
                        patentWitoutPPTChildWithPPT2.put(accId,awForChildAccount);
                    }
            }
        }
        
        
        map<id,Active_Megawatts__c> independantAMW =  new map<id,Active_Megawatts__c>();
        
        for(Id indipAccId : independantAccount.keySet()){
            ActiveMegawatWrapper amwWrapper = independantAccount.get(indipAccId);
            
            if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(indipAccId)){
                Active_Megawatts__c amw = existingAMWMap.get(indipAccId).clone(true,true,true,true);
                
                amw.Total_MW_Bluepoint__c 	= amwWrapper.MW_Bluepoint ;
                amw.Total_MW_Drive__c 		= amwWrapper.MW_Drive ;
                amw.Total_MW_Greenbyte__c 	= amwWrapper.MW_Greenbyte ;
                
                amw.MW_Bluepoint__c 		= amwWrapper.MW_Bluepoint ;
                amw.MW_Drive__c 			= amwWrapper.MW_Drive ;
                amw.MW_Greenbyte__c 		= amwWrapper.MW_Greenbyte ;
                
                amw.Child_MW_Bluepoint__c 	= 0;
                amw.Child_MW_Drive__c 		= 0;
                amw.Child_MW_Greenbyte__c 	= 0;
                
                independantAMW.put(indipAccId,amw);
                
            }
            else{
                
                Active_Megawatts__c awForChildAccount = new Active_Megawatts__c(
                    
                    Total_MW_Bluepoint__c 	= amwWrapper.MW_Bluepoint ,
                    Total_MW_Drive__c 		= amwWrapper.MW_Drive ,
                    Total_MW_Greenbyte__c 	= amwWrapper.MW_Greenbyte ,
                    
                    MW_Bluepoint__c 		= amwWrapper.MW_Bluepoint ,
                    MW_Drive__c 			= amwWrapper.MW_Drive ,
                    MW_Greenbyte__c 		= amwWrapper.MW_Greenbyte ,
                    
                    Child_MW_Bluepoint__c 	= 0,
                    Child_MW_Drive__c 		= 0,
                    Child_MW_Greenbyte__c 	= 0,
                    
                    Account__c					= 	indipAccId
                );
                independantAMW.put(indipAccId,awForChildAccount);
            }
            
        } 
        
        map<id,Active_Megawatts__c> mer =  new map<id,Active_Megawatts__c>();
        map<id,Active_Megawatts__c> childActiveMegawatsMaps =  new map<id,Active_Megawatts__c>();
        
        for(Id parentAccId : accountRelationShipMap.keySet()){
            Decimal Sum_Total_MW_Bluepoint = 0;
            Decimal Sum_Total_MW_Drive =0;
            Decimal Sum_Total_MW_Greenbyte =0;
            
            Decimal Sum_MW_Bluepoint =0;
            Decimal Sum_MW_Drive =0;
            Decimal Sum_MW_Greenbyte =0;
            
            Decimal Sum_Child_MW_Bluepoint =0;
            Decimal Sum_Child_MW_Drive =0;
            Decimal Sum_Child_MW_Greenbyte =0;
            
			for(Id childAccIds :  accountRelationShipMap.get(parentAccId)){
                if(accCalculationMap.containsKey(childAccIds)){
                   
                    Sum_Total_MW_Bluepoint 	+= accCalculationMap.get(childAccIds).Total_MW_Bluepoint;
                    Sum_Total_MW_Drive  	+= accCalculationMap.get(childAccIds).Total_MW_Drive;
                    Sum_Total_MW_Greenbyte 	+= accCalculationMap.get(childAccIds).Total_MW_Greenbyte;
                    
                    Sum_MW_Bluepoint 		+= accCalculationMap.get(childAccIds).MW_Bluepoint;
                    Sum_MW_Drive 			+= accCalculationMap.get(childAccIds).MW_Drive;
                    Sum_MW_Greenbyte 		+= accCalculationMap.get(childAccIds).MW_Greenbyte;
                    
                    Sum_Child_MW_Bluepoint 	+= accCalculationMap.get(childAccIds).Child_MW_Bluepoint;
                    Sum_Child_MW_Drive 		+= accCalculationMap.get(childAccIds).Child_MW_Drive;
                    Sum_Child_MW_Greenbyte 	+= accCalculationMap.get(childAccIds).Child_MW_Greenbyte;

     				ActiveMegawatWrapper parentFields = accCalculationMap.get(childAccIds);
                    
                    if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(childAccIds)){
                        Active_Megawatts__c amw = existingAMWMap.get(childAccIds).clone(true,true,true,true);
                        
                        amw.Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint ;
                        amw.Total_MW_Drive__c 		= parentFields.MW_Drive ;
                        amw.Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte ;
                        
                        amw.MW_Bluepoint__c 		= parentFields.MW_Bluepoint ;
                        amw.MW_Drive__c 			= parentFields.MW_Drive ;
                        amw.MW_Greenbyte__c 		= parentFields.MW_Greenbyte ;
                        
                        amw.Child_MW_Bluepoint__c 	= 0;
                        amw.Child_MW_Drive__c 		= 0;
                        amw.Child_MW_Greenbyte__c 	= 0;
                        
                        childActiveMegawatsMaps.put(childAccIds,amw);
                        
                    }
                    else{
                        Active_Megawatts__c awForChildAccount = new Active_Megawatts__c(
                            
                            Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint ,
                            Total_MW_Drive__c 		= parentFields.MW_Drive ,
                            Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte ,
                            
                            MW_Bluepoint__c 		= parentFields.MW_Bluepoint ,
                            MW_Drive__c 			= parentFields.MW_Drive ,
                            MW_Greenbyte__c 		= parentFields.MW_Greenbyte ,
                            
                            Child_MW_Bluepoint__c 	= 0,
                            Child_MW_Drive__c 		= 0,
                            Child_MW_Greenbyte__c 	= 0,
                            
                            Account__c					= 	childAccIds
                        );
                        childActiveMegawatsMaps.put(childAccIds,awForChildAccount);
                    }
                }
            }
            
            if(accCalculationMap.containsKey(parentAccId)){
                
                ActiveMegawatWrapper parentFields = accCalculationMap.get(parentAccId);
                
                //if(ultimateParentAndItsAcc.contain)
                
                if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(parentAccId)){
                    Active_Megawatts__c amw = existingAMWMap.get(parentAccId).clone(true,true,true,true);
                    
                    amw.Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint  + Sum_Total_MW_Bluepoint ;
                    amw.Total_MW_Drive__c 		= parentFields.MW_Drive + Sum_Total_MW_Drive ;
                    amw.Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte + Sum_Total_MW_Greenbyte ;
                    
                    amw.MW_Bluepoint__c 		= parentFields.MW_Bluepoint ;
                    amw.MW_Drive__c 			= parentFields.MW_Drive ;
                    amw.MW_Greenbyte__c 		= parentFields.MW_Greenbyte ;
                    
                    amw.Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint;
                    amw.Child_MW_Drive__c 		= Sum_Total_MW_Drive;
                    amw.Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte;
                    
                    mer.put(parentAccId,amw);
                    
                }
                else{
                    
                    Active_Megawatts__c ae3 = new Active_Megawatts__c(
                        Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint  + Sum_Total_MW_Bluepoint ,
                        Total_MW_Drive__c 		= parentFields.MW_Drive + Sum_Total_MW_Drive ,
                        Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte + Sum_Total_MW_Greenbyte ,
                        
                        MW_Bluepoint__c 		= parentFields.MW_Bluepoint ,
                        MW_Drive__c 			= parentFields.MW_Drive ,
                        MW_Greenbyte__c 		= parentFields.MW_Greenbyte ,
                        
                        Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint,
                        Child_MW_Drive__c 		= Sum_Total_MW_Drive,
                        Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte,
                        
                        Account__c					= 	parentAccId
                    );
                    mer.put(parentAccId,ae3);
                }
            }
        }
        
        for(Id accId : ultimateParentAndItsAcc.keySet()){
            system.debug('ultimateParentAndItsAcc---'+accId);
            if(mer.containsKey(accId)){
                for(Id childAcc : ultimateParentAndItsAcc.get(accId)){
                    system.debug('child acc---'+childAcc);
                    if(childActiveMegawatsMaps.containsKey(childAcc)){
                        childActiveMegawatsMaps.get(childAcc).Total_MW_Bluepoint__c = mer.get(accId).Total_MW_Bluepoint__c;
                        childActiveMegawatsMaps.get(childAcc).Total_MW_Drive__c = mer.get(accId).Total_MW_Drive__c;
                        childActiveMegawatsMaps.get(childAcc).Total_MW_Greenbyte__c = mer.get(accId).Total_MW_Greenbyte__c;
                        
                        //childActiveMegawatsMaps.get(childAcc).Account__c = accId;
                        childActiveMegawatsMaps.get(childAcc).AccountForPricingAM__c = accId;
                        
                        system.debug('Acc--'+childAcc + ' :: '+mer.get(accId).Total_MW_Bluepoint__c);
                        system.debug('Acc--'+childAcc + ' :: '+mer.get(accId).Total_MW_Drive__c);
                        system.debug('Acc--'+childAcc + ' :: '+mer.get(accId).Total_MW_Greenbyte__c);
                    }
                }
            }
            if(patentWitoutPPTChildWithPPT.containsKey(accId)){
                for(Id childAcc : ultimateParentAndItsAcc.get(accId)){
                    system.debug('child acc---'+childAcc);
                    if(childActiveMegawatsMaps.containsKey(childAcc)){
                        childActiveMegawatsMaps.get(childAcc).Total_MW_Bluepoint__c = patentWitoutPPTChildWithPPT.get(accId).Total_MW_Bluepoint__c;
                        childActiveMegawatsMaps.get(childAcc).Total_MW_Drive__c = patentWitoutPPTChildWithPPT.get(accId).Total_MW_Drive__c;
                        childActiveMegawatsMaps.get(childAcc).Total_MW_Greenbyte__c = patentWitoutPPTChildWithPPT.get(accId).Total_MW_Greenbyte__c;
                        
                        //childActiveMegawatsMaps.get(childAcc).Account__c = accId;
                        childActiveMegawatsMaps.get(childAcc).AccountForPricingAM__c = accId;
                        
                        system.debug('Acc--'+childAcc + ' :: '+patentWitoutPPTChildWithPPT.get(accId).Total_MW_Bluepoint__c);
                        system.debug('Acc--'+childAcc + ' :: '+patentWitoutPPTChildWithPPT.get(accId).Total_MW_Drive__c);
                        system.debug('Acc--'+childAcc + ' :: '+patentWitoutPPTChildWithPPT.get(accId).Total_MW_Greenbyte__c);
                    }
                }
            }
            
        }
        
        
        map<id,Active_Megawatts__c> mer2 =  new map<id,Active_Megawatts__c>();
        map<id,Active_Megawatts__c> childActiveMegawatsMaps2 =  new map<id,Active_Megawatts__c>();
        
        for(Id parentAccId : accountRelationShipMapWithParentOptOut.keySet()){
            Decimal Sum_Total_MW_Bluepoint = 0;
            Decimal Sum_Total_MW_Drive =0;
            Decimal Sum_Total_MW_Greenbyte =0;
            
            Decimal Sum_MW_Bluepoint =0;
            Decimal Sum_MW_Drive =0;
            Decimal Sum_MW_Greenbyte =0;
            
            Decimal Sum_Child_MW_Bluepoint =0;
            Decimal Sum_Child_MW_Drive =0;
            Decimal Sum_Child_MW_Greenbyte =0;
            
            for(Id childAccIds :  accountRelationShipMapWithParentOptOut.get(parentAccId)){
                if(accCalculationMap.containsKey(childAccIds)){
                    
                    Sum_Total_MW_Bluepoint 	+= accCalculationMap.get(childAccIds).Total_MW_Bluepoint;
                    Sum_Total_MW_Drive  	+= accCalculationMap.get(childAccIds).Total_MW_Drive;
                    Sum_Total_MW_Greenbyte 	+= accCalculationMap.get(childAccIds).Total_MW_Greenbyte;
                    
                    Sum_MW_Bluepoint 		+= accCalculationMap.get(childAccIds).MW_Bluepoint;
                    Sum_MW_Drive 			+= accCalculationMap.get(childAccIds).MW_Drive;
                    Sum_MW_Greenbyte 		+= accCalculationMap.get(childAccIds).MW_Greenbyte;
                    
                    Sum_Child_MW_Bluepoint 	+= accCalculationMap.get(childAccIds).Child_MW_Bluepoint;
                    Sum_Child_MW_Drive 		+= accCalculationMap.get(childAccIds).Child_MW_Drive;
                    Sum_Child_MW_Greenbyte 	+= accCalculationMap.get(childAccIds).Child_MW_Greenbyte;
                    
                    ActiveMegawatWrapper parentFields = accCalculationMap.get(childAccIds);
                    
                    if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(childAccIds)){
                        Active_Megawatts__c amw = existingAMWMap.get(childAccIds).clone(true,true,true,true);
                        
                        amw.Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint ;
                        amw.Total_MW_Drive__c 		= parentFields.MW_Drive ;
                        amw.Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte ;
                        
                        amw.MW_Bluepoint__c 		= parentFields.MW_Bluepoint ;
                        amw.MW_Drive__c 			= parentFields.MW_Drive ;
                        amw.MW_Greenbyte__c 		= parentFields.MW_Greenbyte ;
                        
                        amw.Child_MW_Bluepoint__c 	= 0;
                        amw.Child_MW_Drive__c 		= 0;
                        amw.Child_MW_Greenbyte__c 	= 0;
                        
                        childActiveMegawatsMaps2.put(childAccIds,amw);
                        
                    }
                    else{
                        
                        Active_Megawatts__c awForChildAccount = new Active_Megawatts__c(
                            
                            Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint ,
                            Total_MW_Drive__c 		= parentFields.MW_Drive ,
                            Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte ,
                            
                            MW_Bluepoint__c 		= parentFields.MW_Bluepoint ,
                            MW_Drive__c 			= parentFields.MW_Drive ,
                            MW_Greenbyte__c 		= parentFields.MW_Greenbyte ,
                            
                            Child_MW_Bluepoint__c 	= 0,
                            Child_MW_Drive__c 		= 0,
                            Child_MW_Greenbyte__c 	= 0,
                            
                            Account__c					= 	childAccIds
                        );
                        childActiveMegawatsMaps2.put(childAccIds,awForChildAccount);
                    }
                }
            }
            
            if(accCalculationMap.containsKey(parentAccId)){
                
                ActiveMegawatWrapper parentFields = accCalculationMap.get(parentAccId);
                
                if(existingAMWMap != null && existingAMWMap.size() > 0 && existingAMWMap.containsKey(parentAccId)){
                    Active_Megawatts__c amw = existingAMWMap.get(parentAccId).clone(true,true,true,true);
                    
                    amw.Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint  + Sum_Total_MW_Bluepoint ;
                    amw.Total_MW_Drive__c 		= parentFields.MW_Drive + Sum_Total_MW_Drive ;
                    amw.Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte + Sum_Total_MW_Greenbyte ;
                    
                    amw.MW_Bluepoint__c 		= parentFields.MW_Bluepoint ;
                    amw.MW_Drive__c 			= parentFields.MW_Drive ;
                    amw.MW_Greenbyte__c 		= parentFields.MW_Greenbyte ;
                    
                    amw.Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint;
                    amw.Child_MW_Drive__c 		= Sum_Total_MW_Drive;
                    amw.Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte;
                    
                    mer2.put(parentAccId,amw);
                    
                }
                else{
                    
                    Active_Megawatts__c ae3 = new Active_Megawatts__c(
                        Total_MW_Bluepoint__c 	= parentFields.MW_Bluepoint  + Sum_Total_MW_Bluepoint ,
                        Total_MW_Drive__c 		= parentFields.MW_Drive + Sum_Total_MW_Drive ,
                        Total_MW_Greenbyte__c 	= parentFields.MW_Greenbyte + Sum_Total_MW_Greenbyte ,
                        
                        MW_Bluepoint__c 		= parentFields.MW_Bluepoint ,
                        MW_Drive__c 			= parentFields.MW_Drive ,
                        MW_Greenbyte__c 		= parentFields.MW_Greenbyte ,
                        
                        Child_MW_Bluepoint__c 	= Sum_Total_MW_Bluepoint,
                        Child_MW_Drive__c 		= Sum_Total_MW_Drive,
                        Child_MW_Greenbyte__c 	= Sum_Total_MW_Greenbyte,
                        
                        Account__c					= 	parentAccId
                    );
                    mer2.put(parentAccId,ae3);
                }
            }
        }
        
        // START -- Block to create AMW for Indipandant Account (having No PPT and No AMW Earlier)
        
        List<Account> indipandantAccountsList= [SELECT ID 
                                                FROM Account 
                                                WHERE Id NOT IN (SELECT Account__c FROM Active_Megawatts__c) 
                                                AND Id NOT IN (SELECT Account__c FROM Plant_Product_Transaction__c)
                                                ];
        
        system.debug('indipandantAccountsList size--'+indipandantAccountsList.size());
        Map<Id, Active_Megawatts__c> indipandantAccountsMap = new Map<Id, Active_Megawatts__c>();
        
        for(Account acc : indipandantAccountsList){
            Active_Megawatts__c amw = new Active_Megawatts__c(
                Total_MW_Bluepoint__c 	= 0 ,
                Total_MW_Drive__c 		= 0 ,
                Total_MW_Greenbyte__c 	= 0 ,
                
                MW_Bluepoint__c 		= 0 ,
                MW_Drive__c 			= 0 ,
                MW_Greenbyte__c 		= 0 ,
                
                Child_MW_Bluepoint__c 	= 0,
                Child_MW_Drive__c 		= 0,
                Child_MW_Greenbyte__c 	= 0,
                
                Account__c					= 	acc.Id
            );
            indipandantAccountsMap.put(acc.Id,amw);
        }
         
        
        // END -- Block to create AMW for Indipandant Account (having No PPT and No AMW Earlier)
        
        
        mapToInsert.putAll(childActiveMegawatsMaps);
        mapToInsert.putAll(mer);
        
        
        mapToInsert.putAll(childActiveMegawatsMaps2);
        mapToInsert.putAll(mer2);
        
       	mapToInsert.putAll(independantAMW);
        
        mapToInsert.putAll(indipandantAccountsMap);
        
        //
       	mapToInsert.putAll(patentWitoutPPTChildWithPPT);
        mapToInsert.putAll(patentWitoutPPTChildWithPPT2);
        system.debug('\n\n\n');
        for(Id ids : indipandantAccountsMap.keySet()){
            System.debug('indipandantAccountsMap key ->'+ids+' :: '+indipandantAccountsMap.get(ids));
        }
        system.debug('\n\n\n');
        for(Id ids : mer.keySet()){
            System.debug('key ->'+ids+' :: '+mer.get(ids));
        }
        
        system.debug('\n\n\n');
        for(Id ids : childActiveMegawatsMaps.keySet()){
            System.debug('key ->'+ids+' :: '+childActiveMegawatsMaps.get(ids));
        }
        system.debug('\n\n\n');
        for(Id ids : mer2.keySet()){
            System.debug('key ->'+ids+' :: '+mer2.get(ids));
        }
        system.debug('\n\n\n');
        for(Id ids : childActiveMegawatsMaps2.keySet()){
            System.debug('key ->'+ids+' :: '+childActiveMegawatsMaps2.get(ids));
        }
    }
    
    global void finish(Database.BatchableContext BC){
        for(Id key : mapToInsert.keySet()){
            system.debug('key-->'+key + ' :: '+mapToInsert.get(key));
        }
        
        if(mapToInsert != null && mapToInsert.size() >0 ){
            try{
                upsert mapToInsert.values();
            }
            catch(Exception e){
                system.debug(e.getMessage());
                system.debug(e.getLineNumber());
             }
        }
    }
    
    public class ActiveMegawatWrapper{
        public Decimal Total_MW_Bluepoint ;
        public Decimal Total_MW_Drive ;
        public Decimal Total_MW_Greenbyte ;
        
        public Decimal MW_Bluepoint ;
        public Decimal MW_Drive ;
        public Decimal MW_Greenbyte ;
        
        public Decimal Child_MW_Bluepoint ;
        public Decimal Child_MW_Drive ;
        public Decimal Child_MW_Greenbyte ;

        public ActiveMegawatWrapper(
        	Decimal Total_MW_Bluepoint ,
            Decimal Total_MW_Drive ,
            Decimal Total_MW_Greenbyte ,
            
            Decimal MW_Bluepoint ,
            Decimal MW_Drive ,
            Decimal MW_Greenbyte ,
            
            Decimal Child_MW_Bluepoint ,
            Decimal Child_MW_Drive ,
            Decimal Child_MW_Greenbyte 

        ){
           	this.Total_MW_Bluepoint = Total_MW_Bluepoint ;
            this.Total_MW_Drive = Total_MW_Drive ;
            this.Total_MW_Greenbyte = Total_MW_Greenbyte ;
            
            this.MW_Bluepoint = MW_Bluepoint ;
            this.MW_Drive = MW_Drive ;
            this.MW_Greenbyte = MW_Greenbyte ;
            
            this.Child_MW_Bluepoint = Child_MW_Bluepoint ;
            this.Child_MW_Drive = Child_MW_Drive ;
            this.Child_MW_Greenbyte = Child_MW_Greenbyte;
		}
    }
}