/**
@description
BatchApex class to Aggregate Active Megawatts records Under Account object  
*/

global class ActiveMegawattQuantityBatchapex implements Database.Batchable<SObject> {
 
 /**
* Batachable start method implementation.
* @param BC The BatchableContext object provided by runtime.
* @return List of Plant_Product_Transaction to be fetched when the Status__c= Contracted,
  QuantityUnitOfMeasureas (MWp or MWh or WTG
  Account Plantis unique
*/   
global Database.QueryLocator Start(Database.BatchableContext bc)
{
       
            
       set<Id> accId = new set<Id>(); 
       list<Plant_Product_Transaction__c> p =[SELECT id,Plant__c,MWp_Quantity__c, Account__c, status__c FROM Plant_Product_Transaction__c
                                              Where Status__c ='contracted'
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
        return Database.getQueryLocator(query);
    } 

/**
* Batchable execute method implementation.
* This method applies calculate logic based on the asset class.

*/
    global void execute(Database.BatchableContext bc, List<Plant_Product_Transaction__c> scope){
        Decimal SumSolar =0;
        Decimal SumWind =0;
        Decimal SumHydro =0;
        Decimal SumStorage =0;
        Decimal SumOtherRenewable=0;
        
        map<id,Active_Megawatts__c> mer =  new map<id,Active_Megawatts__c>();
        for(Plant_Product_Transaction__c pData :scope)
        {           
          if(pData.Account__c!=null){
             AggregateResult[] groupedResult1 = [SELECT SUM(MWp_Quantity__c)aver FROM Plant_Product_Transaction__c
                                                   where Account__c=:pData.Account__c and 
                                                    plant__r.Asset_Class__c='Solar'];
                                               Object a=groupedResult1[0].get('aver');
                if(a!=null && a!=''){SumSolar = Decimal.valueOf(String.valueOf(a));}
                
                AggregateResult[] groupedResult2 = [SELECT SUM(MWp_Quantity__c)aver FROM Plant_Product_Transaction__c
                                                   where Account__c=:pData.Account__c and 
                                                    plant__r.Asset_Class__c='Other Renewable'];
                                               Object b=groupedResult2[0].get('aver');
                if(b!=null && b!=''){SumOtherRenewable = Decimal.valueOf(String.valueOf(b));}
                
                
                    
                AggregateResult[] groupedResult3 = [SELECT SUM(MWp_Quantity__c)aver FROM Plant_Product_Transaction__c
                                                    where Account__c=:pData.Account__c and plant__r.Asset_Class__c='Wind'];
                Object c=groupedResult3[0].get('aver');
                if(c!=null && c!=''){SumWind = Decimal.valueOf(String.valueOf(c));}
                
                AggregateResult[] groupedResult4 = [SELECT SUM(MWp_Quantity__c)aver FROM Plant_Product_Transaction__c
                                                    where Account__c=:pData.Account__c and plant__r.Asset_Class__c='Hydro'];
                Object d=groupedResult4[0].get('aver');
                if(d!=null && d!=''){SumWind = Decimal.valueOf(String.valueOf(d));}
             
                    
                AggregateResult[] groupedResult5 = [SELECT SUM(MWp_Quantity__c)aver FROM Plant_Product_Transaction__c
                                                    where Account__c=:pData.Account__c and plant__r.Asset_Class__c='Storage'];
                object e = groupedResult5[0].get('aver');
                  if(e!=null && e!=''){SumStorage = Decimal.valueOf(String.valueOf(e));}
                
                
                    
                Active_Megawatts__c ae3 = new Active_Megawatts__c(
                    Total_Agnostic__c= SumStorage + SumWind + SumSolar + SumHydro+ SumOtherRenewable,
                    MW_Storage__c=SumStorage,
                    Total_MW_Storage__c=SumStorage ,
                    MW_Other_Renewable__c=SumOtherRenewable,
                    Total_MW_Other_Renewable__c=SumOtherRenewable,
                    MW_Wind__c =SumWind,
                    Total_MW_Wind__c =SumWind, 
                    MW_Solar__c = SumSolar,
                    Total_MW_Solar__c = SumSolar,
                    MW_Hydro__c = SumHydro,
                    Total_MW_Hydro__c = SumHydro,
                   Account__c=pData.Account__c);
                   mer.put(pData.Account__c,ae3);
             
           }SumSolar=0;SumHydro=0;SumWind=0;SumOtherRenewable=0;
        } 
        insert mer.Values();   
    }
    /**
* Batchable finish method implementation.
* @param BC The BatchableContext object provided by runtime.
*/
    global void finish(Database.BatchableContext BC)
    {
    }
    
    }