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
                                                                 Subscription__r.id,
                                                                 Subscription__r.Line_Classification__c ,
                                                                 Plant__r.Name,
                                                                 Amendment_Action__c,
                                                                 CurrencyIsoCode,
                                                                 Plant_Product__c,
                                                                 Contract__r.name,
                                                                 Subscription__r.Name,
                                                                 Plant__r.Plant__r.MWp__c,
                                                                 Contracted_MW_Unit_List_Price__c,
                                                                 Quote_Line_Quantity__c,
                                                                        Subscription__r.SBQQ__QuoteLine__c,
                                                                 Subscription__r.SBQQ__Product__c,
                                                                        Quote_Line__r.SBQQ__Quote__r.SBQQ__Account__c,
                                                                 Unit_Price_After_Volume_Discount__c,
                                                                 
                                                                        Product__c,
                                                                        Quote_Line__r.SBQQ__Product__c
                                                                 FROM Plant_Product_Transaction__c
                                                                 WHERE Subscription__r.SBQQ__Product__c IN: productQuotelineMap.keySet() 
                                                                 AND Status__c = 'Contracted'
                                                                 
                                                                 //AND  Amendment_Action__c != 'Removed Plant' //
                                                                 AND  Plant__r.Status__c ='Active'
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
                    pp.CurrencyIsoCode= ppt.CurrencyIsoCode;     
                    
                    pp.List_Unit_Price__c=ql.SBQQ__ListPrice__c;
                    pp.Contracted_MW_Unit_List_Price__c= ppt.Contracted_MW_Unit_List_Price__c;
                    pp.Unit_Price_After_Volume_Discount__c= ppt.Unit_Price_After_Volume_Discount__c;  
                        
                        /**/
                         
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
    
    
    public static void createPPTunderAmbededQLRevised(Map<Id, Opportunity> lastOppMap , Map<Id, Opportunity> newOppMap){
        List<SBQQ__Quote__c> quoteList = [select  id ,
                                                  SBQQ__Type__c , 
                                                  SBQQ__Opportunity2__c,
                                                  (select id,SBQQ__Product__c , SBQQ__Quote__r.id from SBQQ__LineItems__r) 
                                          from SBQQ__Quote__c 
                                          where SBQQ__Type__c  = 'Amendment' 
                                          AND SBQQ__Primary__c =  true
											and (SBQQ__Opportunity2__r.Id In :lastOppMap.keySet() OR  SBQQ__Opportunity2__r.Id In :newOppMap.keySet()) ];
        for(SBQQ__Quote__c qut : quoteList){
            system.debug('qut--'+qut.SBQQ__LineItems__r);
        }
        Map<Id, Map<Id, SBQQ__QuoteLine__c >> existingData = new Map<Id, Map<Id, SBQQ__QuoteLine__c >>();
        Map<Id, Map<Id, SBQQ__QuoteLine__c >> revisedData = new Map<Id, Map<Id, SBQQ__QuoteLine__c >>();
        
        Map<Id, SBQQ__QuoteLine__c > existingData2 = new Map<Id, SBQQ__QuoteLine__c >();
        Map<Id, SBQQ__QuoteLine__c > revisedData2 = new Map<Id, SBQQ__QuoteLine__c >();        
        
        Set<Id> sourceQuoteLines = new Set<Id>();
        
        for(SBQQ__Quote__c qut : quoteList){
            system.debug('qut-->'+qut);
            if(lastOppMap.containsKey(qut.SBQQ__Opportunity2__c) && qut.SBQQ__LineItems__r != null && qut.SBQQ__LineItems__r.size() > 0){
                for(SBQQ__QuoteLine__c quoteLine : qut.SBQQ__LineItems__r){
                    sourceQuoteLines.add(quoteLine.Id);
                    /*if(existingData.containsKey(qut.Id)){
                        if(!existingData.get(qut.Id).containsKey(quoteLine.SBQQ__Product__c)){
                            existingData.get(qut.Id).put(quoteLine.SBQQ__Product__c,quoteLine);
                        }
                    }else{
                        existingData.put(qut.Id , new Map<Id, SBQQ__QuoteLine__c>{quoteLine.SBQQ__Product__c => quoteLine});
                    }*/
                    
                    if(!existingData2.containsKey(quoteLine.SBQQ__Product__c)){
                        existingData2.put(quoteLine.SBQQ__Product__c,quoteLine);
                    }
                }
            }
            
            if(newOppMap.containsKey(qut.SBQQ__Opportunity2__c) && qut.SBQQ__LineItems__r != null && qut.SBQQ__LineItems__r.size() > 0){
                for(SBQQ__QuoteLine__c quoteLine : qut.SBQQ__LineItems__r){
                   /* if(revisedData.containsKey(qut.Id)){
                        if(!revisedData.get(qut.Id).containsKey(quoteLine.SBQQ__Product__c)){
                            revisedData.get(qut.Id).put(quoteLine.SBQQ__Product__c,quoteLine);
                        }
                    }else{
                        revisedData.put(qut.Id , new Map<Id, SBQQ__QuoteLine__c>{quoteLine.SBQQ__Product__c => quoteLine});
                    }*/
                    
                    if(!revisedData2.containsKey(quoteLine.SBQQ__Product__c)){
                        revisedData2.put(quoteLine.SBQQ__Product__c,quoteLine);
                    }
                }
            }
            
            
        }
        system.debug('existingData2-->'+existingData2);
        system.debug('revisedData2-->'+revisedData2);
        system.debug('sourceQuoteLines-->'+sourceQuoteLines);
        List<SBQQ__QuoteLine__c> qlList = [select id , SBQQ__Product__c,SBQQ__Quote__r.id,SBQQ__ListPrice__c,
                                                    (select id,
                                                            name,
                                                            Subscription__c,
                                                            Account__c,
                                                            Subscription__r.id,
                                                            Subscription__r.Line_Classification__c ,
                                                            Plant__r.Name,
                                                            Amendment_Action__c,
                                                            CurrencyIsoCode,
                                                            Plant_Product__c,
                                                            Contract__r.name,
                                                            Subscription__r.Name,
                                                            Plant__r.Plant__r.MWp__c,
                                                            Contracted_MW_Unit_List_Price__c,
                                                            Quote_Line_Quantity__c,
                                                            Subscription__r.SBQQ__QuoteLine__c,
                                                            Subscription__r.SBQQ__Product__c,
                                                            Quote_Line__r.SBQQ__Quote__r.SBQQ__Account__c,
                                                            Unit_Price_After_Volume_Discount__c,
                                                            Product__c,
                                                            Quote_Line__r.SBQQ__Product__c 
                                                    from Plant_Product_Transactions__r 
                                                    where Status__c != 'Decommissioned') 
                                        from SBQQ__QuoteLine__c
                                        Where Id IN :sourceQuoteLines ];
        
        system.debug('qlList-->'+qlList);
        List<Plant_Product_Transaction__c> pptListTOClone = new List <Plant_Product_Transaction__c>();
        for(SBQQ__QuoteLine__c ql : qlList){
            system.debug('quote line-->'+ql.Plant_Product_Transactions__r);
            if(revisedData2.containsKey(ql.SBQQ__Product__c ) && ql.Plant_Product_Transactions__r != null && ql.Plant_Product_Transactions__r.size() > 0){
                for(Plant_Product_Transaction__c ppt  : ql.Plant_Product_Transactions__r ){
                    Plant_Product_Transaction__c pp = ppt.clone(false,true,false,false);
                    pp.Quote_Line__c        =   revisedData2.get(ql.SBQQ__Product__c ).Id;
                    pp.Status__c            =   'Amendment_Quoted';
                    pp.Plant_Product__c     =   true ;
                    pp.Amendment_Action__c  =   'No_Change';    
                    pp.Product__c           =   revisedData2.get(ql.SBQQ__Product__c ).SBQQ__Product__c;
                    pp.Quote__c             =   revisedData2.get(ql.SBQQ__Product__c ).SBQQ__Quote__r.id;
                    pp.Subscription__c      =   null;
                    pp.MWp_Quantity__c      =   pp.Plant__r.Plant__r.MWp__c;
                    pp.Quote_Line_Quantity__c=  ppt.Quote_Line_Quantity__c;
                    pp.CurrencyIsoCode      =   ppt.CurrencyIsoCode;     
                    pp.List_Unit_Price__c   =   ql.SBQQ__ListPrice__c;
                    pp.Contracted_MW_Unit_List_Price__c     =   ppt.Contracted_MW_Unit_List_Price__c;
                    pp.Unit_Price_After_Volume_Discount__c  =   ppt.Unit_Price_After_Volume_Discount__c;  
                    
                    pptListTOClone.add(pp);
                }
            }
        }
        
        if(pptListTOClone != null && pptListTOClone.size() > 0){
            system.debug('insert list--'+pptListTOClone.size());
            try{
                insert pptListTOClone;
            }
            catch(Exception e){
                system.debug(e.getCause());
                system.debug(e.getMessage());
                system.debug(e.getLineNumber());
            }
        }
        
    }
}