global class PPTBillingTriggerBatchApex implements Database.Batchable<sObject>
{
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        
        String query = 'SELECT Id,Name,Product_Category__c,Product_Family__c,Product_Line__c,Effective_Date__c,Billing_Start_Date__c,Implementation_Start_Date__c,'+
                        ' Deployment_date__c,Installation_Commencement_Date__c,Project_Name__c,Project_Name__r.Implementation_Start_Date__c FROM Plant_Product_Transaction__c '+ 
                        System.Label.PPTBillingTriggerSoql;
                        // +System.Label.BatchApexAutocreateProjectSoql where Product_Line__c != null AND Product_Family__c != null AND  Product_Category__c != null
       	system.debug('::query::'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Plant_Product_Transaction__c> scope)
    {
        list<Plant_Product_Transaction__c> updatePPTList = new list<Plant_Product_Transaction__c>();
        set<id>projectIdSet = new set<id>();
        for(Plant_Product_Transaction__c pptRec : scope){  
            system.debug('---pptRec---'+pptRec);
            //Criteria to populate Billing_Start_Date__c from Installation commencement Date    
           if((pptRec.Product_Category__c == 'Professional Services' &&  pptRec.Product_Family__c == 'Greenbyte') && ( pptRec.Product_Line__c =='Add-ons' || pptRec.Product_Line__c =='Core')){
            pptRec.Billing_Start_Date__c = pptRec.Implementation_Start_Date__c;
            updatePPTList.add(pptRec);
           }
           //Criteria to populate Billing_Start_Date__c from Implementation Start Date
           if((pptRec.Product_Family__c == 'Drive' && pptRec.Product_Category__c == 'Professional Services') && (pptRec.Product_Line__c =='Pro' || pptRec.Product_Line__c =='Core') ){
            system.debug('-----pptRec.Project_Name__r.Implementation_Start_Date__c;----'+pptRec.Project_Name__r.Implementation_Start_Date__c);
            pptRec.Billing_Start_Date__c = pptRec.Implementation_Start_Date__c;
            updatePPTList.add(pptRec);
           }
           //Criteria to populate Billing_Start_Date__c from Effective Date
           if(((pptRec.Product_Family__c == 'Ekhosoft' && pptRec.Product_Line__c =='Ekho') && (pptRec.Product_Category__c == 'Software' || pptRec.Product_Category__c == 'license')) ||
                (pptRec.Product_Family__c == 'Greenbyte' && pptRec.Product_Line__c =='Customer Success' && pptRec.Product_Category__c =='Professional Services')){
                pptRec.Billing_Start_Date__c = pptRec.Effective_Date__c;
                updatePPTList.add(pptRec);
           }
           //Criteria to populate Billing_Start_Date__c from Discussion Pending
           if(((pptRec.Product_Family__c == 'BluePoint' && pptRec.Product_Category__c == 'Software') && (pptRec.Product_Line__c == 'Bluepoint' || pptRec.Product_Line__c == 'Core' || pptRec.Product_Line__c == 'Enterprise' || pptRec.Product_Line__c == 'Pro'))){
                pptRec.Billing_Start_Date__c = pptRec.Deployment_date__c;
                updatePPTList.add(pptRec);
           }
           if((pptRec.Product_Family__c == 'BluePoint' && pptRec.Product_Category__c == 'Professional Services' && pptRec.Product_Line__c == 'Bluepoint')){
               pptRec.Billing_Start_Date__c = pptRec.Implementation_Start_Date__c;
               updatePPTList.add(pptRec);
           }
           //Criteria to populate Billing_Start_Date__c from Deployment Date
           if(
            ((pptRec.Product_Family__c == 'Drive' && pptRec.Product_Category__c == 'Software') && (pptRec.Product_Line__c == 'Add-ons' || pptRec.Product_Line__c == 'Core' || pptRec.Product_Line__c == 'Core Lite' || pptRec.Product_Line__c == 'O&M' || pptRec.Product_Line__c == 'Pro')) ||
           ((pptRec.Product_Family__c == 'Drive' && pptRec.Product_Category__c == 'Professional Services') && (pptRec.Product_Line__c == 'Add-ons' || pptRec.Product_Line__c == 'Customer Success'||pptRec.Product_Line__c == 'O&M')) ||
            (pptRec.Product_Family__c == 'Drive' && pptRec.Product_Category__c == 'Hardware' && pptRec.Product_Line__c == 'Customer Success') ||
            (pptRec.Product_Family__c == 'Ekhosoft' && pptRec.Product_Category__c == 'Professional Services' && pptRec.Product_Line__c == 'Ekho') ||
            ((pptRec.Product_Family__c == 'Greenbyte' && pptRec.Product_Category__c == 'Software') && (pptRec.Product_Line__c == 'Add-ons'|| pptRec.Product_Line__c == 'Breeze Development'|| pptRec.Product_Line__c == 'Core')) ||
            (pptRec.Product_Family__c == 'Greenbyte' && pptRec.Product_Category__c == 'Professional Services' && pptRec.Product_Line__c == 'Breeze Development')){
                pptRec.Billing_Start_Date__c = pptRec.Deployment_date__c;
                updatePPTList.add(pptRec);
           }

        }
        if(updatePPTList.size() > 0 && updatePPTList != null){
            system.debug('---updatePPTList.size()---'+updatePPTList.size());
            system.debug('---updatePPTList---'+updatePPTList);
            update updatePPTList;
        }
        
    }
    global void finish(Database.BatchableContext BC) {
    }
}