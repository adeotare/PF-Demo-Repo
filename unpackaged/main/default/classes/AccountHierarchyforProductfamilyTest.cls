@isTest
public class AccountHierarchyforProductfamilyTest {
	@TestSetup
    public static void setupData(){
        
        // Test data creation :
        List<String> assetClassList = new List<String>{'Solar', 'Wind','Hydro','Storage','Industrial','Other Renewable'};
        List<String> productFamily = new List<String>{'Drive', 'Greenbyte','BluePoint','Ekhosoft','Drive', 'Greenbyte'};
        
        List<Account> actList = new List<Account>();
        
        Account act = new Account();
        act.Name  = 'AccountHierarchyMWTest';
        insert act;
        actList.add(act);
        
        Account act2 = new Account();
        act2.Name  = 'Test-2022';
        act2.ParentId = act.Id;
        insert act2;
        actList.add(act2);
        
        Account act3 = new Account();
        act3.Name  = 'Test-2023';
        insert act3;
        actList.add(act3);
         
       	List<Plant__c> plantList = new List<Plant__c>();
        for(Integer i = 0 ; i<6 ; i++){
            Plant__c pl = new Plant__c();
            //pl.Name = 'Test Plant - '+(i+1);
            pl.Megawatt_AC__c = i+5;
            pl.Megawatt_DC__c = i+10;
            pl.Asset_Class__c = assetClassList[i];
            plantList.add(pl);
        }
		insert plantList;
        
        Test.startTest();
        List<Account_Plant__c> accPlantList = new List<Account_Plant__c>();
        for(Integer i = 0 ; i<6 ; i++){
            Account_Plant__c accPlant = new Account_Plant__c();
            //accPlant.Name = 'Test Acc Plant - '+(i+1);
            accPlant.Account__c = math.mod(i, 2) == 0 ? act.Id : act2.Id;
            accPlant.Plant__c = plantList[i].Id;
            accPlant.Status__c ='Active';
            accPlantList.add(accPlant);
            
        }
        insert accPlantList;
        
        Contract cnt = new Contract();
        cnt.AccountId = act.Id;
        cnt.Status = 'Draft';
        cnt.StartDate = System.today().addDays(-5);
        cnt.ContractTerm = 5;
        insert cnt;
       
        cnt.Status = 'Activated';
        update cnt;
        
        
        
        List<Product2> prdList = new List<Product2>();
        for(Integer i = 0 ; i<6 ; i++){
            Product2 prd = new Product2();
            prd.Name = 'Test Product - '+(i+1);
            prd.QuantityUnitOfMeasure = 'MWp';
            prd.Product_Line__c = 'Core'; 
            prd.Product_Category__c = 'Software';
            prd.Product_Type__c = 'SaaS';
            prd.Product_Services__c = 'N/A';
            prd.QuantityUnitOfMeasure = 'MWp';
            prd.Asset_Class__c = 'Solar';
            prd.Family = productFamily[i];
            prdList.add(prd);
        }
        insert prdList;
        
        SBQQ__Subscription__c subs = new SBQQ__Subscription__c();
        subs.SBQQ__Quantity__c = 100;
        //subs.SBQQ__Product__c = prdList[i].Id;
        subs.SBQQ__Contract__c = cnt.Id;
        subs.SBQQ__Account__c = act.Id;
        insert subs;
        
        List<Plant_Product_Transaction__c> pptList = new List<Plant_Product_Transaction__c>();
        for(Integer i = 0 ; i<6 ; i++){
            Plant_Product_Transaction__c ppt = new Plant_Product_Transaction__c();   
            ppt.Name = 'AccountHierarch- Catan- DR-CR-SW-SS-N/A-AL-MW-LA - '+(i+1);
            ppt.Plant__c = accPlantList[i].Id;
            ppt.Status__c = 'Contracted';
            ppt.Subscription__c = subs.Id;
            ppt.Product__c = prdList[i].Id;
            ppt.Contract__c = cnt.Id;
            ppt.MWp_Quantity__c = 11;
            ppt.Account__c = math.mod(i, 2) == 0 ? act.Id : act2.Id;
            if(i == 5)  ppt.Account__c = act3.Id;
            pptList.add(ppt);
        }
        insert pptList;
        Test.stopTest();
    }
    
     @isTest
    public static void testMethod02(){
        List<Plant_Product_Transaction__c> pptList = [Select Id FROM Plant_Product_Transaction__c]; 
        Test.startTest();
        
        AccountHierarchyforProductfamily upd = new AccountHierarchyforProductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
}