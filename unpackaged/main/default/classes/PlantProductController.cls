/**
@description
Apex class to Add/delete Plants to a Product on the Quote Line and create/delete record/s in the PPT object
*/

public with sharing class PlantProductController {

    /**
    @description
    Methods to get the list of Plants that are associated with a quote line PPT object. This list of Plants are shown in the
    UI when the button to Add / Remove Plants is clicked
    */  
    @AuraEnabled(cacheable=true)  
    public static List<Plant_Product_Transaction__c> fetchPlantProductList(String qLineItemId){  
        // return [SELECT Id, Name, Account__r.Name,Plant__r.Name,Plant__r.Plant_Name__c,Plant__r.Plant_MWH__c,Plant__r.Plant_MWP__c, Plant__r.Plant_Country__c,Plant__r.Plant_Number_of_Devices__c, Plant__r.Asset_Class__c From Plant_Product_Transaction__c where Quote_Line__c =: qLineItemId];  
        return [SELECT Id, Name, Account__r.Name,Plant__r.Plant__r.Name,Plant__r.Plant_MWH__c,Plant__r.Plant_MWP__c, Plant__r.Plant_Country__c,Plant__r.Plant__r.Number_of_Turbines__c, Plant__r.Asset_Class__c From Plant_Product_Transaction__c where Quote_Line__c =: qLineItemId WITH SECURITY_ENFORCED];  
    }

    /*
    @description
    delete the selected plants from the quote line. The associated PPT records are deleted
    */
    @AuraEnabled 
    public static void deletePlantProduct(List<Plant_Product_Transaction__c> pptList, String quoteLineId){  
        //List<Account_Plant__c> aplan =[SELECT Id, Name, Account__r.Name, Plant__r.Plant_Name__c,Plant__r.Country__c, Plant__r.MWp__c, Plant__r.MW_Energy_Capacity_MWh__c, Plant__r.Number_of_Devices__c,Plant__r.Asset_Class__c From Account_Plant__c where Id =:pptList.Plant__c WITH SECURITY_ENFORCED];
        //System.debug('aplan::'+aplan.size());
        List<Id>  accplan = new List<Id>();
        for(Plant_Product_Transaction__c ppt :pptList ){
            accplan.add(ppt.Plant__c);
        }
        System.debug('accplan::'+accplan);
        List<Account_Plant__c> aplan =[SELECT Id, Name, Account__r.Name, Plant__r.Plant_Name__c,Plant__r.Country__c, Plant__r.MWp__c, Plant__r.MW_Energy_Capacity_MWh__c, Plant__r.Number_of_Turbines__c,Plant__r.Asset_Class__c From Account_Plant__c where Id IN :accplan WITH SECURITY_ENFORCED];
        System.debug('aplan::'+aplan.size());
        Integer sumOfMWH = 0;
        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__Quantity__c,SBQQ__Product__r.QuantityUnitOfMeasure from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED];
        
        try {
        delete pptList;
        }
        catch(Exception ex) {
                System.debug('Exception while deleting the plants from the quote line i.e. deleting PPT records'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());

            }
        updateQuantityOnQuoteLineItem(quoteLineId);
        
    } 
    
    /*
    @description
    Add the  Plants selected in the UI by the User to the Quote line. This is done by creating a PPT record for every
    Plant that is added
    */
    @AuraEnabled  
    public static List<Plant_Product_Transaction__c> addPlantProductList(List<Account_Plant__c> plantList, String quoteLineId){  
        System.debug('plantList::'+plantList.size());
        List<Plant_Product_Transaction__c> pList = new List<Plant_Product_Transaction__c>();
        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__EndDate__c, SBQQ__Quote__c, SBQQ__Quote__r.CurrencyIsoCode, SBQQ__Quote__r.SBQQ__StartDate__c, SBQQ__Quote__r.SBQQ__EndDate__c, SBQQ__Quantity__c,SBQQ__Product__r.QuantityUnitOfMeasure from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED];
        for(Account_Plant__c ap: plantList){
            // For every new plant that is added, create a record in the PPT table and populate it's fields
            
            Plant_Product_Transaction__c ppt = new Plant_Product_Transaction__c();
            ppt.Plant__c = ap.Id;
            ppt.Name = ap.Name; 
            ppt.Account__c = ap.Account__c;
            ppt.CurrencyIsoCode = quoteLine.SBQQ__Quote__r.CurrencyIsoCode;
            // If Quote has a Start/End Date, then it should override the Start/End date on the Quote line
            // Nitin - TEST this
            if(quoteLine.SBQQ__Quote__r.SBQQ__StartDate__c !=null) {
                ppt.Effective_Date__c = quoteLine.SBQQ__Quote__r.SBQQ__StartDate__c;
                System.debug('Start Date is on the Quote...so putting effective date in PPT from Quote start date');
                }
            else {
                ppt.Effective_Date__c = quoteLine.SBQQ__StartDate__c;
                System.debug('There is no Start Date is on the Quote...so taking from Quote line in PPT record');
                }
            if(quoteLine.SBQQ__Quote__r.SBQQ__EndDate__c !=null) {
                ppt.End_Date__c = quoteLine.SBQQ__Quote__r.SBQQ__EndDate__c;
                System.debug('End Date is on the Quote...so putting end date in PPT from Quote end  date');
                } 
                else { 
                    ppt.End_Date__c = quoteLine.SBQQ__EndDate__c;
                    System.debug('There is no End Date is on the Quote...so taking from Quote line in PPT record');
                    }
            
            ppt.MWp_Quantity__c = ap.Plant__r.MWp__c;
            ppt.Product__c = quoteLine.SBQQ__Product__c;
            ppt.Quote__c = quoteLine.SBQQ__Quote__c;
            ppt.Quote_Line__c = quoteLineId;
            ppt.Status__c = 'Quote In Draft';
            pList.add(ppt);
        }
        if(pList.size()>0){
            System.debug('pList::'+pList.size());
            
            try {
                insert pList;
            }
            catch(Exception ex) {
                System.debug('Exception adding PPT record'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());

            }

        }
        updateQuantityOnQuoteLineItem(quoteLineId);
        //updatePricing(quoteLineId);
        return pList;
                 
    }  
    
    /*
    @description
    Based on the Unit of measure associated with the Product on the quote line, calculate the quantity (e.g. number of sites,
    MWp, MWh etc) and update the quote line with the quantity
    */
    @AuraEnabled
    public static void updateQuantityOnQuoteLineItem(String quoteLineId){
        Decimal sumOfMWH = 0;
        Decimal sumOfMWp = 0;
        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__Quantity__c,SBQQ__Product__r.QuantityUnitOfMeasure from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED];
        // List<Plant_Product_Transaction__c> ppt =[SELECT Plant__r.Plant__c from Plant_Product_Transaction__c where Quote_Line__c =: quoteLineId];
        List<Plant_Product_Transaction__c> ppt =[SELECT Plant__r.Plant__r.MWp__c from Plant_Product_Transaction__c where Quote_Line__c =: quoteLineId WITH SECURITY_ENFORCED];
        System.debug('Total records from PPT whose quantity we are calculating is '+ppt.size());
        System.debug('inside Quantity calculation');
        
        
        if(quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'MWh (EnCap)'){
            for(Plant_Product_Transaction__c ap: ppt){
                // sumOfMWH =sumOfMWH + ap.Plant__r.Plant_MWH__c.intValue();
                sumOfMWH =sumOfMWH + ap.Plant__r.Plant__r.MW_Energy_Capacity_MWh__c;
                // System.debug('ap.Plant_MWH__c::'+SUM((ap.Plant__r.MW_Energy_Capacity_MWh__c.intValue()));
            }
            System.debug('sumOfMWH::'+sumOfMWH);
            quoteLine.SBQQ__Quantity__c = sumOfMWH;
            try {
                update quoteLine;
            }
            catch(Exception ex) {
                System.debug('Error updating MWh quantity on quote line'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());
            }
        }
        
        if(quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'MWp'){
            for(Plant_Product_Transaction__c ap: ppt) {
                sumOfMWp =sumOfMWp + (ap.Plant__r.Plant__r.MWp__c);     
                //System.debug('ap.Plant__r.MWp__c::'+SUM(decimal.valueof(ap.Plant__r.Plant_MWP__c)));
                // System.debug('Sum of MWp' +sumOfMWp);
            }
            System.debug('sumOfMWp::'+sumOfMWp);
            quoteLine.SBQQ__Quantity__c = sumOfMWp;
            try {
                update quoteLine;
            }
            catch(Exception ex) {
                System.debug('Error updating MWp quantity on quote line'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());
            }
        }
        
        if(quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'Site'){
            //List<Plant_Product_Transaction__c> ppt =[SELECT Plant__r.Plant__c from Plant_Product_Transaction__c where Quote_Line__c =: quoteLineId];
            SBQQ__QuoteLine__c quoteLine1 = [SELECT SBQQ__Quantity__c from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED];
            quoteLine1.SBQQ__Quantity__c = ppt.size();
            try {
                update quoteLine1;
            }
            catch(Exception ex) {
                System.debug('Error updating Number of Sites quantity on quote line'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());
            }
        }
        
        
    }

    /*
    @description
    get the list of Plants associated with the Account for which this quote is. We shall be adding plants on the 
    quote line from this list
    */
    @AuraEnabled(cacheable=true)  
    public static List<Account_Plant__c> fetchAccountPlant(String qLineItemId){  
       // return [SELECT Id, Name, Account__r.Name,Plant__r.Name From Account_Plant__c];  
       SBQQ__QuoteLine__c quoteLine = [Select Id, SBQQ__Quote__r.Id, SBQQ__Quote__r.SBQQ__Account__c from SBQQ__QuoteLine__c WHERE id = :qLineItemId WITH SECURITY_ENFORCED limit 1];

      return [SELECT Id, Name,Asset_Class__c, Account__r.Name, Plant__r.Name, Plant__r.Country__c, 
                Plant__r.MWp__c, Plant__r.MW_Energy_Capacity_MWh__c, Plant__r.Number_of_Turbines__c,
                Plant__r.Asset_Class__c 
                From Account_Plant__c
                WHERE Account__r.Id = :quoteLine.SBQQ__Quote__r.SBQQ__Account__c AND Status__c='Active' WITH SECURITY_ENFORCED];
    }

/*
    // This function will calculate Unit Price for go-forward Veritas pricing. It will also update the PPT records
    // 1- will handle renewals and amendments later
    // 2- should add a checkbox to MSA Contracts - UpdatePricingForAllPlantsOnAmend - True/false
    // 3- all pricing is now go forward
    // 4- check pricing for bluepoint
    // 5- check how to get past purchases
    // 6- some GB Products are going to have out of the box discount schedules and block prices
    // 7- check that the UoM on Product and pricing per unit UoM are same for a Product
    @AuraEnabled(cacheable=true)
    public static void updatePricing(String quoteLineId){ 

        System.debug('Inside updatePricing function');

        // check if this Quote is for go-forward pricing i.e. the one using Standard Price book
        // SBQQ__QuoteLine__c quoteLine1 = [SELECT SBQQ__Product__r.ID, SBQQ__Quote__r.SBQQ__Account__r.ID, SBQQ__Product__r.Product_Category__c, SBQQ__SpecialPrice__c, SBQQ__Quote__r.SBQQ__PriceBook__r.Name from SBQQ__QuoteLine__c where Id =: quoteLineId];
        // Keep the original contract price here
        Decimal contractPricePerMSA = quoteLine1.SBQQ__SpecialPrice__c;
        //if(quoteLine1.SBQQ__Quote__r.SBQQ__PriceBook__r.Name == 'Standard Price Book') {

        //  System.debug('found standard price book');

            if(quoteLine1.SBQQ__Product__r.Product_Category__c == 'Software') {
                // check if there are any custom discount tiers for this Product
            List <MSA_Software_Discount_Tier_Price__c> swDiscountTiersList = 
            [// SELECT ID from MSA_Software_Discount_Tier_Price__c where Product__r.ID = '01t7j000003QkFIAA0' AND Account__r.ID ='0017j00000iXrXPAA0'  
            SELECT ID from MSA_Software_Discount_Tier_Price__c where Product__r.ID = :quoteLine1.SBQQ__Product__r.ID  AND Account__r.ID = :quoteLine1.SBQQ__Quote__r.SBQQ__Account__r.ID
            WITH SECURITY_ENFORCED];
                if (swDiscountTiersList!=null && !swDiscountTiersList.IsEmpty()) {
                    // Found atleast 1 discount tier for the Product on the quote line for a given account
                    doSpecialPriceUpdateAndNetPriceCalculationforSW (quoteLineId, contractPricePerMSA, swDiscountTiersList);

            
                }
                else {
                    // No discount tier was found for the Product + Account combination
                    // Therefore no updates to the Contract Price. Just Update the PPT records
                    updateAllPlantRecordswithSamePrice(quoteLineId, contractPricePerMSA);
                }

            }
            else {
                    // The Product is a Professional Services Product. check if there are any Implementation tier brackets for it


            }
            

        //}
        //else {
        // this is going to change as GB gets remodeled - Nitin
        // System.debug('Price book on the Quote is not a Standard price book');
        // return;
        //}

    }


    //@description
    // Function to update a single Price on all Plants of a given Quote Line
    @AuraEnabled(cacheable=true)  
    public static void UpdateAllPlantRecordsWithSamePrice(String qLineItemId, Decimal contractPricePerMSA) {
        // get the list of all Quote Lines
        List<Plant_Product_Transaction__c> ppt =[SELECT Plant__r.Plant__r.MWp__c from Plant_Product_Transaction__c where Quote_Line__c =: quoteLineId WITH SECURITY_ENFORCED];

        for(Plant_Product_Transaction__c ap: ppt){
            quoteLine.SBQQ__Quantity__c = contractPricePerMSA;
            try {
                update quoteLine;
            }
            catch(Exception ex) {
                System.debug('Error updating MWh quantity on quote line'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());
            }

    }

    //@description
    // This function is called when atleast 1 Discount tier is found for a SW Product
    @AuraEnabled(cacheable=true)  
    public static void doSpecialPriceUpdateAndNetPriceCalculationForSW (String quoteLineId, Decimal contractPricePerMSA, List <MSA_Software_Discount_Tier_Price__c> swDiscountTiersList){


    }
*/

// end of file
}