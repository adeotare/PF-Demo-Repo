public class AmendmentQuoteProcessHelper {
    public static void createPPTunderAmbededQL(List <SBQQ__QuoteLine__c> amendedQl){
        
        Set<Id> prodIdSet = new Set<Id>();
        
        
        Map<Id, SBQQ__QuoteLine__c> productQuotelineMap = new Map<Id, SBQQ__QuoteLine__c>();
        
        for(SBQQ__QuoteLine__c ql : amendedQl){
            productQuotelineMap.put(ql.SBQQ__Product__c, ql);
            //prodIdSet.add(ql.SBQQ__Product__c);
        }
        
        system.debug('idList--'+prodIdSet);
        List<Plant_Product_Transaction__c> pptUnderVarginalQL = [SELECT id,
                                                                 		name,
                                                                 		Subscription__c,
                                                                 		Account__c,
                                                                 Plant__r.Name,
                                                                 Amendment_Action__c,
                                                                 Plant_Product__c,
                                                                 Plant__r.Plant__r.MWp__c,
                                                                 Contracted_MW_Unit_List_Price__c,
                                                                 Quote_Line_Quantity__c,
                                                                 		Subscription__r.SBQQ__QuoteLine__c,
                                                                 Subscription__r.SBQQ__Product__c,
                                                                 		Quote_Line__r.SBQQ__Quote__r.SBQQ__Account__c,
                                                                 		Product__c,
                                                                 		Quote_Line__r.SBQQ__Product__c
                                                                 FROM Plant_Product_Transaction__c
                                                                 WHERE Subscription__r.SBQQ__Product__c IN: productQuotelineMap.keySet() 
                                                                 AND Status__c = 'Contracted'and Plant__r.Status__c ='Active'
                                                                ];
        
        system.debug('pptUnderVarginalQL---'+pptUnderVarginalQL);
        
        Map<Id,List<Plant_Product_Transaction__c>> vargQuoteLinePptMap = new  Map<Id,List<Plant_Product_Transaction__c>>();   
       // Map<Id,Map<Id,List<Plant_Product_Transaction__c>>> vargQuoteLinePptMap2 = new  Map<Id,Map<Id,List<Plant_Product_Transaction__c>>>();   
        
        for(Plant_Product_Transaction__c ppt : pptUnderVarginalQL){	
            if(vargQuoteLinePptMap.containsKey(ppt.Subscription__r.SBQQ__Product__c)){
                vargQuoteLinePptMap.get(ppt.Subscription__r.SBQQ__Product__c).add(ppt);
            }
            else{
                vargQuoteLinePptMap.put(ppt.Subscription__r.SBQQ__Product__c  , new List<Plant_Product_Transaction__c> {ppt});
            }
            
        }
        
        List<Plant_Product_Transaction__c> pptListTOClone = new List <Plant_Product_Transaction__c>();
        
        for(SBQQ__QuoteLine__c ql : productQuotelineMap.values()){
            
            if(vargQuoteLinePptMap.containsKey(ql.SBQQ__Product__c)
               && ( ql.Plant_Product_Transactions__r.size() == null || ql.Plant_Product_Transactions__r.size() == 0)){
                for( Plant_Product_Transaction__c ppt: vargQuoteLinePptMap.get(ql.SBQQ__Product__c) ){
                    if(ppt.Account__c == ql.SBQQ__Quote__r.SBQQ__Account__c){
                        Plant_Product_Transaction__c pp = ppt.clone(false,true,false,false);
                        
                        
                        
                      pp.Quote_Line__c = ql.Id;
                    pp.Status__c = 'Amendment_Quoted';
                      //pp.Trial__c =false; 
                    //pp.Amendment_Action__c ='NoChange' ;
                    pp.Plant_Product__c =true ;
                    pp.Amendment_Action__c='No_Change';    
                    pp.Product__c=ql.SBQQ__Product__c;
                    pp.Quote__c=ql.SBQQ__Quote__r.id;
                    pp.Subscription__c = null;
                    pp.MWp_Quantity__c=pp.Plant__r.Plant__r.MWp__c;
                    //pp.Quote_Line_Quantity__c=pp.Plant__r.Plant__r.MWp__c;
                    pp.Quote_Line_Quantity__c=ppt.Quote_Line_Quantity__c;
                    
                    pp.List_Unit_Price__c=ql.SBQQ__ListPrice__c;
                    pp.Contracted_MW_Unit_List_Price__c= ppt.Contracted_MW_Unit_List_Price__c;  
                        
                        pptListTOClone.add(pp);
                    }
                }
            }
            
        }
		
		if(pptListTOClone != null && pptListTOClone.size() > 0){
            system.debug('pptListTOClone--'+pptListTOClone.size());
            insert pptListTOClone;
        }
    }
}