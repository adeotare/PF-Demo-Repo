/**
@description
Apex class to Add/delete Plants to a Product on the Quote Line and create/delete record/s in the PPT object

1. Update Quantity and Update Pricing methods has been kept separate on purpose

Methods:
// Add Plants, Delete Plants, Fetch current Plants on the Quote line, Fetch Plants to add from the Account-Plant object
public static List<Plant_Product_Transaction__c> fetchPlantProductList(String qLineItemId)
public static void deletePlantProduct(List<Plant_Product_Transaction__c> pptList, String quoteLineId)
public static List<Plant_Product_Transaction__c> addPlantProductList(List<Account_Plant__c> plantList, String quoteLineId)
public static List<Account_Plant__c> fetchAccountPlant(String qLineItemId)

//Calculate and update Quantity
public static void updateQuantityOnQuoteLineItem(String quoteLineId)

//Pricing
public static void updatePricingForQuoteLineInPPT(String quoteLineId)
public static void doDiscountTierBasedPriceCalculationforSW (String quoteLineId, Decimal contractPricePerMSA, List <MSA_Software_Discount_Tier_Price__c> swDiscountTiersList)
public static void doImplBracketTierBasedPriceCalculationforImpl (String quoteLineId, Decimal contractPricePerMSA, List <MSA_Implementation_Bracket_Price__c> ImplBracketPriceTiersList)
public static void updatePricingfromPPTToQuoteline (SBQQ__QuoteLine__c quoteLine1, String quoteLineId)

// When no SW discount tiers or Implementation brackets are applicable to the Account+Product
public static void UpdateAllPlantRecordsWithSamePrice(String qLineItemId, Decimal contractPricePerMSA)

// TO-DO: Update Pricing on PPT when Additional discount is Applied or Quantity is Updated
public static void updatePPTWithAdditionalDiscountFromQuoteLine(String qLineItemId, Decimal additionalDiscountPercent)
public static void updatePPTWithQuantityFromQuoteLine(String qLineItemId, Integer quantityEnteredManuallyOnQuoteline )

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
    @param List of PPT records
    @param Quote Line ID
    */
    @AuraEnabled 
    public static void deletePlantProduct(List<Plant_Product_Transaction__c> pptList, String quoteLineId){  
        
        if (pptList.size() == 0)
            return;  // If number of plants to be deleted is zero, then return
        List<Id>  accplan = new List<Id>();
        for(Plant_Product_Transaction__c ppt :pptList ){
            accplan.add(ppt.Plant__c);
        }
        System.debug('Number of Plants to be deleted are::'+accplan.size());
        //List<Account_Plant__c> aplan =[SELECT Id, Name, Account__r.Name, Plant__r.Plant_Name__c,Plant__r.Country__c, Plant__r.MWp__c, Plant__r.MW_Energy_Capacity_MWh__c, Plant__r.Number_of_Turbines__c,Plant__r.Asset_Class__c From Account_Plant__c where Id IN :accplan WITH SECURITY_ENFORCED];
        //System.debug('aplan::'+aplan.size());
        try {
            delete pptList;
        }
        catch(Exception ex) {
                System.debug('Exception while deleting the plants from the quote line i.e. deleting PPT records'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());

            }

        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__AdditionalDiscount__c, SBQQ__NetPrice__c, SBQQ__NetTotal__c, SBQQ__RegularPrice__c, SBQQ__Quantity__c,SBQQ__Product__r.QuantityUnitOfMeasure 
            from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED];
        
        // Execute the Quantity and Pricing functions  only if - 
        if ((quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'MWp') || (quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'Site')) {
        updateQuantityOnQuoteLineItem(quoteLineId);
        updatePricingForQuoteLineInPPT(quoteLineId);
        updatePricingfromPPTToQuoteline (quoteLine, quoteLineId);
        }
    } 
    
    /*
    @description
    Add the  Plants selected in the UI by the User to the Quote line. This is done by creating a PPT record for every
    Plant that is added
    @param list of plants to be added
    @param quote line ID
    @return list of PPT records
    */
    @AuraEnabled  
    public static List<Plant_Product_Transaction__c> addPlantProductList(List<Account_Plant__c> plantList, String quoteLineId){  
        
        System.debug('Number of Plants to be added is :'+plantList.size());
        if (plantList.size() == 0)
            return null;  // If number of plants to be added is zero, then return

        List<Plant_Product_Transaction__c> pList = new List<Plant_Product_Transaction__c>();
        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__Discount__c, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Product__r.ID,SBQQ__ListPrice__c, SBQQ__Quote__r.SBQQ__Account__r.ID, SBQQ__SpecialPrice__c, SBQQ__EndDate__c, SBQQ__Quote__c, SBQQ__Quote__r.CurrencyIsoCode, SBQQ__Quote__r.SBQQ__StartDate__c, SBQQ__Quote__r.SBQQ__EndDate__c, SBQQ__Quantity__c,SBQQ__Product__r.QuantityUnitOfMeasure from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED];
         
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
            // If Additional discount % is already entered on the Quote line, add it on the new Plant record as well
            ppt.Addl_Discount_Percent__c = quoteLine.SBQQ__Discount__c;
            ppt.Quote_Line__c = quoteLineId;
            ppt.Status__c = 'Quoted';
            if (quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'MWp') {

                ppt.Quote_Line_Quantity__c = ap.Plant__r.MWp__c;  // update the Quoteline Quantity
                System.debug('The Quote_Line_Quantity__c is '+ppt.Quote_Line_Quantity__c);
            }
            if (quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'Site'){
                ppt.Quote_Line_Quantity__c = 1;
                System.debug('The Quote_Line_Quantity__c is '+ppt.Quote_Line_Quantity__c);
            }

            // This is where we store the original Contracted Price value
            // ppt.Contracted_MW_Unit_List_Price__c = quoteLine.SBQQ__SpecialPrice__c;
            List <SBQQ__ContractedPrice__c> cPriceList = [Select SBQQ__Price__c, Name from SBQQ__ContractedPrice__c where SBQQ__Product__r.ID =:quoteLine.SBQQ__Product__r.ID AND SBQQ__Account__r.ID =:quoteLine.SBQQ__Quote__r.SBQQ__Account__r.ID AND CurrencyIsoCode =:quoteLine.SBQQ__Quote__r.CurrencyIsoCode WITH SECURITY_ENFORCED LIMIT 1];
        
            System.debug ('While setting the Contracted Price on the PPTLine - found it '+cPriceList.size());
            If (cPriceList.size() == 1) 
                ppt.Contracted_MW_Unit_List_Price__c = cPriceList[0].SBQQ__Price__c;
            else 
                ppt.Contracted_MW_Unit_List_Price__c = quoteLine.SBQQ__ListPrice__c;

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
        
        // Execute the Quantity and Pricing functions  only if - 
        if ((quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'MWp') || (quoteLine.SBQQ__Product__r.QuantityUnitOfMeasure == 'Site')) {
            updateQuantityOnQuoteLineItem(quoteLineId);
        
            If (quoteLine.SBQQ__Quote__r.SBQQ__Type__c != 'Amendment') {

                System.debug('Quote is not of type Amendment');
                updatePricingForQuoteLineInPPT(quoteLineId);    
                updatePricingfromPPTToQuoteline (quoteLine, quoteLineId);
            }
        }

        return pList;
                 
    }  
    
    /*
    @description
    Based on the Unit of measure associated with the Product on the quote line, calculate the quantity (e.g. number of sites,
    MWp, MWh etc) and update the quote line with the quantity
    @param quote line id
    */
    @AuraEnabled
    public static void updateQuantityOnQuoteLineItem(String quoteLineId){
        Decimal sumOfMWH = 0;
        Decimal sumOfMWp = 0;
        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__Quantity__c,SBQQ__Product__r.QuantityUnitOfMeasure from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED Limit 1 FOR UPDATE];
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
    @param quote line item id
    @return list of Account plants associated with the quote line
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


    // Nitin
    // @description This function will calculate Unit Price for go-forward Veritas pricing. It will also update the PPT records
    // 1- will handle renewals and amendments later
    // 2- should add a checkbox to MSA Contracts - UpdatePricingForAllPlantsOnAmend - All boats rise - True/false
    // 3- all pricing is now go forward
    // 4- check pricing for bluepoint - REQ-2962
    // 5- check how to get past purchases - that are across Asset classes or Product families
    // 6- some GB Products are going to have out of the box discount schedules and block prices
    // 7- check that the UoM on Product and pricing per unit UoM are same for a Product - e.g. Bluepoint
    // 8 - how to update prices in PPT if someone adds additional discount - have another button on the Quote object
    // @param ID of quote line for which pricing is to be updated
    @AuraEnabled(cacheable=true)
    public static void updatePricingForQuoteLineInPPT(String quoteLineId){ 

        System.debug('Inside updatePricingForQuoteLine function');

        // check if this Quote is for go-forward pricing i.e. the one using Standard Price book. This is no longer true 
        // as all GB pricing is also per go-forward pricing approach
        SBQQ__QuoteLine__c quoteLine1 = [SELECT CurrencyIsoCode, SBQQ__ListPrice__c, SBQQ__Product__r.ID, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.SBQQ__Account__r.ID, SBQQ__Product__r.Product_Category__c, SBQQ__SpecialPrice__c, SBQQ__Quote__r.SBQQ__PriceBook__r.Name from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED];
        // Keep the original contract price here... since we are updating Special Price itself, this will not work
        // Decimal contractPricePerMSA = quoteLine1.SBQQ__SpecialPrice__c;
         List <SBQQ__ContractedPrice__c> cPriceList = [Select SBQQ__Price__c, Name from SBQQ__ContractedPrice__c where SBQQ__Product__r.ID =:quoteLine1.SBQQ__Product__r.ID AND SBQQ__Account__r.ID =:quoteLine1.SBQQ__Quote__r.SBQQ__Account__r.ID AND CurrencyIsoCode =:quoteLine1.CurrencyIsoCode WITH SECURITY_ENFORCED LIMIT 1];
        Decimal contractPricePerMSA = 0;
        
        System.debug ('While setting the Contracted Price on the PPTLine - found it '+cPriceList.size());
        If (cPriceList.size() == 1) 
            contractPricePerMSA = cPriceList[0].SBQQ__Price__c;
        else 
            contractPricePerMSA = quoteLine1.SBQQ__ListPrice__c;
        
        if(quoteLine1.SBQQ__Product__r.Product_Category__c == 'Software') {
            // check if there are any custom discount tiers for this SW Product
            System.debug ('Checking if the SW Product has Discount Tier pricing');
            List <MSA_Software_Discount_Tier_Price__c> swDiscountTiersList =  [Select Name, Type__c, Discount_Amount__c, Pricing_Tier__c, Lower_Bound__c, Upper_Bound__c, Cross_Orders__c 
            from MSA_Software_Discount_Tier_Price__c 
            where (Product__r.ID = :quoteLine1.SBQQ__Product__r.ID)  
            AND (Account__r.ID = :quoteLine1.SBQQ__Quote__r.SBQQ__Account__r.ID)
            WITH SECURITY_ENFORCED Order by Lower_Bound__c ];
            if (swDiscountTiersList!=null && !swDiscountTiersList.IsEmpty()) {
                // Found atleast 1 discount tier for the Product on the quote line for a given account
                doDiscountTierBasedPriceCalculationforSW (quoteLineId, contractPricePerMSA, swDiscountTiersList, quoteLine1.SBQQ__Quote__r.SBQQ__Type__c);
    
            }
            else {
                    // No discount tier was found for the Product + Account combination
                    // Therefore no updates to the Contract Price. Just Update the PPT records
                    System.debug ('No Discount Tier pricing for found for the Product');
                    updateAllPlantRecordswithSamePrice(quoteLineId, contractPricePerMSA);
            }

        }
        else {
            System.debug ('Checking if the Product has Implementation Services bracket pricing');
            // The Product is a Professional Services Product. check if there are any Implementation tier brackets for it
            // check if there are any Implementation brackets for this Implementation service
            List <MSA_Implementation_Bracket_Price__c> ImplBracketPriceTiersList =  [SELECT ID, Fixed_Price__c, Lower_Bound__c, Upper_Bound__c 
            from MSA_Implementation_Bracket_Price__c 
            where (Product__r.ID = :quoteLine1.SBQQ__Product__r.ID)  
            AND (Account__r.ID = :quoteLine1.SBQQ__Quote__r.SBQQ__Account__r.ID)
            WITH SECURITY_ENFORCED];    
            if (ImplBracketPriceTiersList!=null && !ImplBracketPriceTiersList.IsEmpty()) {
                // Found atleast 1 Implementation braket tier for the Product on the quote line for a given account
                doImplBracketTierBasedPriceCalculationforImpl (quoteLineId, contractPricePerMSA, ImplBracketPriceTiersList);
    
            }
            else {
                    // No Implementation bracket was found for the Product + Account combination
                    // Therefore no updates to the Contract Price. Just Update the PPT records
                    updateAllPlantRecordswithSamePrice(quoteLineId, contractPricePerMSA);
            }

        }
            

    }

    //@description
    // Function to update a single Price on all Plants of a given Quote Line
    @AuraEnabled(cacheable=true)  
    public static void UpdateAllPlantRecordsWithSamePrice(String qLineItemId, Decimal contractPricePerMSA) {
        System.debug('Entered function UpdateAllPlantRecordsWithSamePrice');
        // get the list of all PPT Lines
        List<Plant_Product_Transaction__c> pptRecordList =[SELECT Unit_Price_After_Volume_Discount__c from Plant_Product_Transaction__c where Quote_Line__c =: qLineItemId WITH SECURITY_ENFORCED];

        for(Plant_Product_Transaction__c pptRecord: pptRecordList){
            pptRecord.Unit_Price_After_Volume_Discount__c = contractPricePerMSA;
            try {
                update pptRecord;
            }
            catch(Exception ex) {
                System.debug('Error updating price on quote line'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());
            }
        }
    }

    //@description
    // This function is called when atleast 1 Discount tier is found for a SW Product
    // @param quote line id
    // @param Contract price as per MSA
    // @param list of Software discount tiers
    // does not include the functionality where we check the Quote Type (New, Trial, Amendment, Renewal) and 
    // also the flag - if All Plants rise
    // 
    @AuraEnabled(cacheable=true)  
    public static void doDiscountTierBasedPriceCalculationforSW (String quoteLineId, Decimal contractPricePerMSA, List <MSA_Software_Discount_Tier_Price__c> swDiscountTiersList, String quoteType){

        System.debug('Entered function doDiscountTierBasedPriceCalculationforSW');
        System.debug('The Quote type is '+quoteType);
        if (swDiscountTiersList!=null && !swDiscountTiersList.IsEmpty()) {
                System.debug('Found atleast 1 discount tier for the Product on the quote line for a given account');
                // get past purchased quantity or currently Active MW
                Decimal ActiveMW = 0;
                // Don't count ActiveMW when Quote is for Renewal else it will result in double counting
                If (swDiscountTiersList[0].Cross_Orders__c == TRUE && quoteType !='Renewal') {
                    try {
                            List <Active_Megawatts__c> aMW = [Select ID from Active_Megawatts__c where (Account__r.ID = :swDiscountTiersList[0].Account__r.ID) WITH SECURITY_ENFORCED limit 1];
                            if (aMW.size() > 0) {
                                ActiveMW = aMW[0].Total_Agnostic__c;
                                System.debug('Currently total Active MW (Active_Megawatts__c.Total_Agnostic__c) for the Account is '+ActiveMW);    
                            }
                        }
                    catch(Exception ex) {
                            System.debug('Exception while finding out Active MW Quantity'
                                +string.valueOf(ex.getLineNumber()) +ex.getTypeName() +string.valueOf(ex.getCause()) +ex.getMessage() +ex.getStackTraceString());
                    }
                }
                
                List<Plant_Product_Transaction__c> pptList =[SELECT Plant__r.Plant__r.MWp__c, Plant__r.Plant__r.Name, Account__c, Addl_Discount_Percent__c, Contracted_MW_Unit_List_Price__c, List_Unit_Price__c, Net_Unit_Price__c, Unit_Price_After_Volume_Discount__c, Discount_Tier__c  
                    from Plant_Product_Transaction__c 
                    where Quote_Line__c =: quoteLineId WITH SECURITY_ENFORCED];
                System.debug('Total records from PPT whose prices we are calculating is '+pptList.size());
                Decimal CurrentMWForPricing = ActiveMW;             // Start with the value of Active MW
                Integer noOfTiers = swDiscountTiersList.size();     // total number of discount tiers
                Integer currentTier = 0;
                Decimal cumulativeDiscount = 0;
                for (Plant_Product_Transaction__c eachPPT:pptList) {
                   
                    currentTier = 0;
                    cumulativeDiscount = 0;
             
                    while (currentTier < noOfTiers) {
                        System.debug('Checking Tier number - '+currentTier);
                        if (currentTier == (noOfTiers -1)) {  // this is the final tier, then do not check the limits
                            System.debug('This plant falls in final Tier number - '+currentTier);
                            System.debug('This plant name is - '+eachPPT.Plant__r.Plant__r.Name);
                            eachPPT.Discount_Tier__c = currentTier+1;
                            cumulativeDiscount += swDiscountTiersList[currentTier].Discount_Amount__c;
                            eachPPT.Unit_Price_After_Volume_Discount__c = contractPricePerMSA - cumulativeDiscount;
                            System.debug('The Unit_Price_After_Volume_Discount__c - '+eachPPT.Unit_Price_After_Volume_Discount__c);
                            update eachPPT;
                            currentTier = noOfTiers; // set to this value so as to break out of the while loop
                        }
                        else {
                            If ((CurrentMWForPricing >= swDiscountTiersList[currentTier].Lower_Bound__c) && (CurrentMWForPricing<= swDiscountTiersList[currentTier].Upper_Bound__c)) {
                            
                            System.debug('This plant falls in Tier number - '+currentTier);
                            System.debug('This plant name is - '+eachPPT.Plant__r.Plant__r.Name);
                            eachPPT.Discount_Tier__c = currentTier+1;
                            cumulativeDiscount += swDiscountTiersList[currentTier].Discount_Amount__c;
                            eachPPT.Unit_Price_After_Volume_Discount__c = contractPricePerMSA - cumulativeDiscount;
                            System.debug('The Unit_Price_After_Volume_Discount__c - '+eachPPT.Unit_Price_After_Volume_Discount__c);
                            update eachPPT;
                            currentTier = noOfTiers; // set to this value so as to break out of the while loop

                            }
                        } 
                            if (currentTier != noOfTiers) {         // till the Tier is not found
                                cumulativeDiscount += swDiscountTiersList[currentTier].Discount_Amount__c;
                                ++ currentTier;     // check into the next tier
                            }
                    
                    }               // end of while loop

                        // Include the Plant MW only after the tier is found...else after addition of the Plant MW, it may get classified into the next tier
                        CurrentMWForPricing += eachPPT.Plant__r.Plant__r.MWp__c; // Nitin - error - the next tier is not starting from the lower bound
                }               
            }
            
    
        else{
            System.debug('No Discount Tiers were found');
            updateAllPlantRecordswithSamePrice(quoteLineId, contractPricePerMSA);
            return;

        }


    }


    //@description
    // This function is called when atleast 1 Implementation bracket is found for an Implementation Service
    // @param quote line id
    // @param Contract price as per MSA
    // @param list of Software discount tiers
    @AuraEnabled(cacheable=true)  
    public static void doImplBracketTierBasedPriceCalculationforImpl (String quoteLineId, Decimal contractPricePerMSA, List <MSA_Implementation_Bracket_Price__c> ImplBracketPriceTiersList){
        System.debug('Entered function doImplBracketTierBasedPriceCalculationforImpl');


        if (ImplBracketPriceTiersList!=null && !ImplBracketPriceTiersList.IsEmpty()) {
                System.debug('Found atleast 1 Implementation bracket for the Product on the quote line for a given account');
                
                List<Plant_Product_Transaction__c> pptList =[SELECT MWp_Quantity__c, Plant__r.Plant__r.MWp__c, Plant__r.Plant__r.Name, Account__c, Addl_Discount_Percent__c, Contracted_MW_Unit_List_Price__c, List_Unit_Price__c, Net_Unit_Price__c, Unit_Price_After_Volume_Discount__c, Discount_Tier__c  
                    from Plant_Product_Transaction__c 
                    where Quote_Line__c =: quoteLineId WITH SECURITY_ENFORCED];
                System.debug('Total records from PPT whose Implementation prices we are calculating is '+pptList.size());
                Integer noOfTiers = ImplBracketPriceTiersList.size();     // total number of Implementation brackets
                Decimal CurrentMWForPricing = 0;
                for (Plant_Product_Transaction__c eachPPT:pptList) {
                    Integer currentTier = 0;
                    CurrentMWForPricing = eachPPT.Plant__r.Plant__r.MWp__c;
                    System.debug('Current MW for Implementation Bracket Pricing calculation is '+CurrentMWForPricing);
                    // If MW is not available on the Plant, then take the MW that may have been entered manually on the PPT line
                    if (CurrentMWForPricing == null) {
                        System.debug('No MW on Plant record');
                        CurrentMWForPricing = eachPPT.MWp_Quantity__c;
                        System.debug('Manually entered MW on PPT record for Implementation Bracket Pricing calculation is '+CurrentMWForPricing);
                    }
                    // If no MW is manually entered on the PPT Line, the put the Plant in the first tier
                    if (CurrentMWForPricing == null){
                        System.debug('No manually entered MW was found on the PPT record or no MW value was found on the Plant');
                        System.debug('So we put this Plant in Tier 1 '+eachPPT.Plant__r.Plant__r.Name);
                        eachPPT.Discount_Tier__c = currentTier+1;
                        eachPPT.Unit_Price_After_Volume_Discount__c = ImplBracketPriceTiersList[currentTier].Fixed_Price__c;
                        System.debug('The Unit_Price_After_Volume_Discount__c - '+eachPPT.Unit_Price_After_Volume_Discount__c);
                        update eachPPT;
                        currentTier = noOfTiers; // set to this value so as to break out of the while loop

                    }
                    while (currentTier < noOfTiers) {
                        System.debug('Checking Tier number - '+currentTier);
                        if (currentTier == (noOfTiers -1)) {  // this is the final tier, then do not check the limits
                            System.debug('This plant falls in final Tier number - '+currentTier);
                            System.debug('This plant name is - '+eachPPT.Plant__r.Plant__r.Name);
                            eachPPT.Discount_Tier__c = currentTier+1;
                            eachPPT.Unit_Price_After_Volume_Discount__c = ImplBracketPriceTiersList[currentTier].Fixed_Price__c;
                            System.debug('The Unit_Price_After_Volume_Discount__c - '+eachPPT.Unit_Price_After_Volume_Discount__c);
                            update eachPPT;
                            currentTier = noOfTiers; // set to this value so as to break out of the while loop
                        }
                        else {
                            If ((CurrentMWForPricing >= ImplBracketPriceTiersList[currentTier].Lower_Bound__c) && (CurrentMWForPricing<= ImplBracketPriceTiersList[currentTier].Upper_Bound__c)) {
                            
                            System.debug('This plant falls in Implementation Tier number - '+currentTier);
                            System.debug('This plant name is - '+eachPPT.Plant__r.Plant__r.Name);
                            eachPPT.Discount_Tier__c = currentTier+1;
                            eachPPT.Unit_Price_After_Volume_Discount__c = ImplBracketPriceTiersList[currentTier].Fixed_Price__c;
                            System.debug('The Unit_Price_After_Volume_Discount__c - '+eachPPT.Unit_Price_After_Volume_Discount__c);
                            update eachPPT;
                            currentTier = noOfTiers; // set to this value so as to break out of the while loop

                            }
                        } 
                            if (currentTier != noOfTiers) {         // till the Tier is not found
                                ++ currentTier;     // check into the next tier
                            }
                    
                    }               // end of while loop

                }               
            }

        else{
            System.debug('No Implementation Brackets were found');
            updateAllPlantRecordswithSamePrice(quoteLineId, contractPricePerMSA);
            return;
        }

    }

    //@description
    // This function is called to update price on the Quote Line after the price is updated on the PPT records
    // @param quote line id
    // @param Quote line
    
    @AuraEnabled(cacheable=true)  
    public static void updatePricingfromPPTToQuoteline (SBQQ__QuoteLine__c quoteLine1, String quoteLineId) {
        
        System.debug('Inside function updatePricingfromPPTToQuoteline '); 

        Decimal cumulativeQLQuantity = 0;
        Decimal cumulativeQLNetTotal = 0;

          // get all the PPT records with this Quoteline ID
        List<Plant_Product_Transaction__c> pptList =[SELECT Unit_Price_After_Volume_Discount__c, Contracted_MW_Unit_List_Price__c, Quote_Line_Quantity__c,  Net_Unit_Price__c, Net_Total_Price__c  
                    from Plant_Product_Transaction__c 
                    where Quote_Line__c =: quoteLineId WITH SECURITY_ENFORCED];
                System.debug('Total records from PPT whose Net Price is going to be updated is '+pptList.size());  
        if (pptList.size() == 0)
            return;

        for (Plant_Product_Transaction__c eachPPT:pptList) {
            
            cumulativeQLQuantity += eachPPT.Quote_Line_Quantity__c;
            
            // we are taking the value before Additional Discount % is applied
            if (eachPPT.Unit_Price_After_Volume_Discount__c == null)
                cumulativeQLNetTotal += (eachPPT.Contracted_MW_Unit_List_Price__c * eachPPT.Quote_Line_Quantity__c);
            else
                cumulativeQLNetTotal += (eachPPT.Unit_Price_After_Volume_Discount__c * eachPPT.Quote_Line_Quantity__c);

        }

        SBQQ__QuoteLine__c quoteLine = [SELECT SBQQ__SpecialPrice__c, SBQQ__AdditionalDiscount__c,  SBQQ__NetPrice__c, SBQQ__NetTotal__c, SBQQ__RegularPrice__c, SBQQ__Quantity__c,SBQQ__Product__r.QuantityUnitOfMeasure 
            from SBQQ__QuoteLine__c where Id =: quoteLineId WITH SECURITY_ENFORCED];

        System.debug('Cumulative QL Net Total Price is = '+cumulativeQLNetTotal);
        System.debug('Cumulative QL Net Total Quantity is = '+cumulativeQLQuantity);
        System.debug('Cumulative QL Net Unit Price (set to Special Price on QL) is = '+(cumulativeQLNetTotal/cumulativeQLQuantity));

        
        quoteLine.SBQQ__SpecialPrice__c = (cumulativeQLNetTotal / cumulativeQLQuantity);
        // quoteLine.SBQQ__RegularPrice__c = 100;
        // quoteLine.SBQQ__SpecialPrice__c = 100;

        update quoteLine;
        System.debug('Updated Quote Line with the value as = '+quoteLine.SBQQ__SpecialPrice__c);

        }



// end of file
}