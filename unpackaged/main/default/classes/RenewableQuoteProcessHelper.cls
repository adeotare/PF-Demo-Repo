public class RenewableQuoteProcessHelper {
    
    public static void createChildPPTunderRenewableQL(Set<Id> quoteIds){
        
        
        String query = 'select id,name,Product__c,Renewal_Action__c,Plant__c,Subscription__r.SBQQ__Discount__c,Unit_Price_After_Volume_Discount__c,Subscription__r.Line_Classification__c,Contracted_MW_Unit_List_Price__c,Quote_Line_Quantity__c,Plant__r.Plant__r.MWp__c,Account__c,Subscription__c,Subscription__r.SBQQ__QuoteLine__c  '
            			+' from Plant_Product_Transaction__c '
            			+' where Subscription__c != Null AND Status__c = \'Contracted\' AND Plant__r.Status__c =\'Active\' AND Quote_Line__r.SBQQ__Quote__c In: quoteIds';
        
        List<Plant_Product_Transaction__c> pptList = Database.query(query);
        
        Map<Id,List<Plant_Product_Transaction__c>> vargQuotePptMap = new  Map<Id,List<Plant_Product_Transaction__c>>();   
         
            for(Plant_Product_Transaction__c ppt : pptList){																	
            if(vargQuotePptMap.containsKey(ppt.Subscription__c)){
                vargQuotePptMap.get(ppt.Subscription__c).add(ppt);
               //system.debug('The get of vargQuotePptMap '+vargQuotePptMap); 
            }else{
                vargQuotePptMap.put(ppt.Subscription__c , new List<Plant_Product_Transaction__c>{ppt});
                //system.debug('The add this to the ovargQuotePptMap '+vargQuotePptMap);
                
            }
        }
        
        List<SBQQ__QuoteLine__c> qlList = [SELECT ID,SBQQ__RenewedSubscription__c ,
                                           SBQQ__Product__c,
                                           SBQQ__Quantity__c,
                                           SBQQ__ListPrice__c,
                                           SBQQ__SpecialPrice__c,
                                           SBQQ__Quote__r.name,
                                           SBQQ__Quote__r.OwnerId,
                                           SBQQ__Quote__r.CurrencyIsoCode,
                                           SBQQ__Quote__r.SBQQ__StartDate__c,
                                           SBQQ__Quote__r.SBQQ__EndDate__c,
                                           //Plant_Product_Transaction__r.Plant__c,


                                           (Select id from Plant_Product_Transactions__r) 
                                           FROM SBQQ__QuoteLine__c 
                                           WHERE SBQQ__RenewedSubscription__c IN : vargQuotePptMap.keySet() LIMIT 50000];
        
        List<Plant_Product_Transaction__c> pptListTOClone = new List <Plant_Product_Transaction__c>();
        for(SBQQ__QuoteLine__c ql : qlList){
            //system.debug('ql.Plant_Product_Transactions__r--'+ql.Plant_Product_Transactions__r);
            //system.debug('ql.SBQQ__RenewedSubscription__c--'+ql.SBQQ__RenewedSubscription__c);
            if(vargQuotePptMap.containsKey(ql.SBQQ__RenewedSubscription__c) && ( ql.Plant_Product_Transactions__r.size() == null || ql.Plant_Product_Transactions__r.size() == 0)){
                	
                   system.debug('ql.Plant_Product_Transactions__r--'+ql.Plant_Product_Transactions__r);
                   for( Plant_Product_Transaction__c ppt:vargQuotePptMap.get(ql.SBQQ__RenewedSubscription__c) ){
                       Plant_Product_Transaction__c pp = ppt.clone(false,true,false,false);
                       pp.Quote_Line__c = ql.Id;
                       pp.Product__c=ql.SBQQ__Product__c;
                       pp.Quote__c=ql.SBQQ__Quote__r.id;
                       //pp.OwnerId = ql.SBQQ__Quote__r.OwnerId;
                       pp.Renewal_Action__c ='No Change';
                       pp.Plant_Product__c=true;
                       pp.OwnerId=ql.SBQQ__Quote__r.OwnerId;
                       decimal s=ql.SBQQ__SpecialPrice__c;
                       decimal c=pp.Contracted_MW_Unit_List_Price__c;
                        c=s;
                       //pp.Contracted_MW_Unit_List_Price__c=ql.SBQQ__SpecialPrice__c;
                       pp.Unit_Price_After_Volume_Discount__c=ppt.Unit_Price_After_Volume_Discount__c;
                       
                       pp.MWp_Quantity__c=pp.Plant__r.Plant__r.MWp__c;
                       pp.Quote_Line_Quantity__c=pp.Plant__r.Plant__r.MWp__c;
                       pp.CurrencyIsoCode = ql.SBQQ__Quote__r.CurrencyIsoCode;
                       pp.List_Unit_Price__c=ql.SBQQ__ListPrice__c;
                       pp.Status__c = 'Renewal Quoted';
                       pp.Subscription__c = null;
                       pptListTOClone.add(pp);
                       
                       if(ql.SBQQ__Quote__r.SBQQ__StartDate__c !=null) {
                pp.Effective_Date__c = ql.SBQQ__Quote__r.SBQQ__StartDate__c;
                //System.debug('Start Date is on the Quote...so putting effective date in pp from Quote start date');
                }
            else {
                pp.Effective_Date__c = ql.SBQQ__StartDate__c;
                //System.debug('There is no Start Date is on the Quote...so taking from Quote line in pp record');
                }
            if(ql.SBQQ__Quote__r.SBQQ__EndDate__c !=null) {
                pp.End_Date__c = ql.SBQQ__Quote__r.SBQQ__EndDate__c;
                //System.debug('End Date is on the Quote...so putting end date in pp from Quote end  date');
                } 
                else { 
                    pp.End_Date__c = ql.SBQQ__EndDate__c;
                    //System.debug('There is no End Date is on the Quote...so taking from Quote line in pp record');
                    }
                       
                       
                 if(pp.Subscription__r.SBQQ__Discount__c!=null && pp.Status__c =='Renewal Quoted') {
                pp.Addl_Discount_Percent__c = pp.Subscription__r.SBQQ__Discount__c;
                //System.debug(' the Subscription has Additional Discount Percent – if yes, then populate Addl Discount Percent ');
                }  
                       
                   }
            }
        }
        
        if(pptListTOClone != null && pptListTOClone.size() > 0)
        {
            system.debug('pptListTOClone--'+pptListTOClone.size());
            insert pptListTOClone;
        }
        
    }
    
  public static void updateQuantityOnQuoteLineItem2(List<SBQQ__QuoteLine__c> qlListRec){ //List of QL that may be Renewable or original 
       
       
        
        List<SBQQ__QuoteLine__c> qlList = [SELECT ID,SBQQ__RenewedSubscription__c ,(Select id,Quote_Line_Quantity__c from Plant_Product_Transactions__r)
                                           FROM SBQQ__QuoteLine__c 
                                           WHERE Id IN : qlListRec];
        
        List<SBQQ__QuoteLine__c> qlToUpdate = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c ql : qlList){
            if(ql.Plant_Product_Transactions__r != null && ql.Plant_Product_Transactions__r.size() > 0){
                Decimal sumOfPPTQuoteLineQuantity = 0;
                for(Plant_Product_Transaction__c ap: ql.Plant_Product_Transactions__r){
                    sumOfPPTQuoteLineQuantity += ap.Quote_Line_Quantity__c;
                }
                if(sumOfPPTQuoteLineQuantity > 0){
                    ql.SBQQ__Quantity__c = sumOfPPTQuoteLineQuantity;
                    qlToUpdate.add(ql);
                }
                
            }
        }
        
        try {
            update qlToUpdate;
            
            for(SBQQ__QuoteLine__c ql : qlToUpdate){
                
                PlantProductController.updatePricingForQuoteLineInPPT(String.valueOf(ql.Id));
                PlantProductController.updatePricingfromPPTToQuoteline (String.valueOf(ql.Id));
                
            }
        }
        catch(Exception ex) {
            System.debug('Error updating MWh quantity on quote line'
                         +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());
        }
        
    }  
    
}