/**************************************************************************************
* @File Name          : 	AccountHierarchyproductfamilyTest
* @Description        : 	Test class for AccountHierarchyproductfamily batch class
* @Last Modified On   : 	05/10/2022
* @Modification Log   :
* Ver       Date         Modification
* 1.0    	09/11/2021    Initial Version
***************************************************************************************/

@isTest
public class AccountHierarchyproductfamilyTest {
    
    @TestSetup
    public static void setupData(){
        
        // Test data creation :
        List<String> assetClassList = new List<String>{'Solar', 'Wind','Hydro','Storage','Industrial','Other Renewable'};
            List<String> productFamily = new List<String>{'Drive', 'Greenbyte','BluePoint','Ekhosoft','Drive', 'Greenbyte'};
                List<Account> actList = new List<Account>();
        
        Account act = new Account();
        act.Name  = 'AccountHierarchyMWTest';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        
        insert act;
        actList.add(act);
        
        Account act2 = new Account();
        act2.Name  = 'Test-2022';
        act2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        act2.ParentId = act.Id;
        insert act2;
        
        Account act3 = new Account();
        act3.Name  = 'Test-2023';
        act3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        act3.ParentId = act.Id;
        insert act3;
        actList.add(act3);
        
        Account act4 = new Account();
        act4.Name  = 'Test-2024';
        act4.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        act4.ParentId = act3.Id;
        act4.Ultimate_Parent_Account__c = act.Id;
        insert act4;
        actList.add(act4);
        
        Account act5 = new Account();
        act5.Name  = 'Test-2025';
        act5.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        act5.ParentId = act.Id;
        insert act5;
        actList.add(act5);
        
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
            accPlant.Account__c = math.mod(i, 3) == 0 ? act.Id : act4.Id;
            //accPlant.Account__c = math.mod(i, 4) == 0 ? act.Id : act3.Id;
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
        //insert cnt;
        
        cnt.Status = 'Activated';
        //update cnt;
        
        
        
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
            ppt.Account__c = math.mod(i, 3) == 0 ? act.Id : act4.Id;
            //ppt.Account__c = math.mod(i, 4) == 0 ? act.Id : act3.Id;
            pptList.add(ppt);
        }
        insert pptList;
        
        
        
        System.debug([Select id,name from account]);
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod01(){
        Test.startTest();
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod011(){
        Test.startTest();
        List<Account> accList = [Select Id from Account Where Uses_MSA_of__r.Parent_MSA_Opt_Out__c != 'Yes' or Parent.Uses_MSA_of__r.Parent_MSA_Opt_Out__c != 'Yes'];
        List<Active_Megawatts__c> amwTiInsert = new List<Active_Megawatts__c>();
        for(Account acc: accList){
            Active_Megawatts__c amw = new Active_Megawatts__c(
                Total_MW_Bluepoint__c   = 0 ,
                Total_MW_Drive__c       = 0 ,
                Total_MW_Greenbyte__c   = 0 ,
                
                MW_Bluepoint__c         = 0 ,
                MW_Drive__c             = 0 ,
                MW_Greenbyte__c         = 0 ,
                
                Child_MW_Bluepoint__c   = 0,
                Child_MW_Drive__c       = 0,
                Child_MW_Greenbyte__c   = 0,
                
                Account__c                  =   acc.Id
            );
            amwTiInsert.add(amw);
        }
        
        insert amwTiInsert;
        
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    
    @isTest
    public static void testMethod02(){
        Test.startTest();
        List<Account> accList = [SELECT Id FROM Account LIMIT 2];
        List<Active_Megawatts__c> amwTiInsert = new List<Active_Megawatts__c>();
        for(Account acc: accList){
            Active_Megawatts__c amw = new Active_Megawatts__c(
                Total_MW_Bluepoint__c   = 0 ,
                Total_MW_Drive__c       = 0 ,
                Total_MW_Greenbyte__c   = 0 ,
                
                MW_Bluepoint__c         = 0 ,
                MW_Drive__c             = 0 ,
                MW_Greenbyte__c         = 0 ,
                
                Child_MW_Bluepoint__c   = 0,
                Child_MW_Drive__c       = 0,
                Child_MW_Greenbyte__c   = 0,
                
                Account__c                  =   acc.Id
            );
            amwTiInsert.add(amw);
        }
        
        insert amwTiInsert;
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod03(){
        Test.startTest();
        
        delete [select id from account where parentId != null];
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod04(){
        Test.startTest();
        List<Account> accList = [SELECT Id , parentId FROM Account LIMIT 2];
        List<Active_Megawatts__c> amwTiInsert = new List<Active_Megawatts__c>();
        for(Account acc: accList){
            if(acc.ParentId == null){
                Active_Megawatts__c amw = new Active_Megawatts__c(
                    Total_MW_Bluepoint__c   = 0 ,
                    Total_MW_Drive__c       = 0 ,
                    Total_MW_Greenbyte__c   = 0 ,
                    
                    MW_Bluepoint__c         = 0 ,
                    MW_Drive__c             = 0 ,
                    MW_Greenbyte__c         = 0 ,
                    
                    Child_MW_Bluepoint__c   = 0,
                    Child_MW_Drive__c       = 0,
                    Child_MW_Greenbyte__c   = 0,
                    
                    Account__c                  =   acc.Id
                );
                amwTiInsert.add(amw);
            }
        }
        
        insert amwTiInsert;
        delete [select id from account where parentId != null];
        
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod05(){
        Test.startTest();
        MSA_Contract__c msa = new MSA_Contract__c();
        msa.Subsidiary__c = 'Power Factors LLC';
        msa.Parent_MSA_Opt_Out__c = 'Yes';
        insert msa;
        
        MSA_Contract__c msa2 = new MSA_Contract__c();
        msa2.Subsidiary__c = 'Power Factors LLC';
        msa2.Parent_MSA_Opt_Out__c = 'Yes';
        insert msa2;
        
        List<Account> accList = [SELECT Id FROM Account where name like 'AccountHierarchyMWTest' or name like 'Test-2023' LIMIT 2 ];
        
        accList[0].Uses_MSA_of__c = msa.Id;
        accList[1].Uses_MSA_of__c = msa2.Id;
        update accList;
        
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod06(){
        Test.startTest();
        MSA_Contract__c msa = new MSA_Contract__c();
        msa.Subsidiary__c = 'Power Factors LLC';
        msa.Parent_MSA_Opt_Out__c = 'Yes';
        insert msa;
        
        MSA_Contract__c msa2 = new MSA_Contract__c();
        msa2.Subsidiary__c = 'Power Factors LLC';
        msa2.Parent_MSA_Opt_Out__c = 'Yes';
        insert msa2;
        
        List<Account> accList = [SELECT Id FROM Account where name like 'AccountHierarchyMWTest' or name like 'Test-2023' LIMIT 2 ];
        
        accList[0].Uses_MSA_of__c = msa.Id;
        accList[1].Uses_MSA_of__c = msa2.Id;
        update accList;
        
        List<Account> accList2 = [SELECT Id FROM Account];
        List<Active_Megawatts__c> amwTiInsert = new List<Active_Megawatts__c>();
        for(Account acc: accList2){
            Active_Megawatts__c amw = new Active_Megawatts__c(
                Total_MW_Bluepoint__c   = 0 ,
                Total_MW_Drive__c       = 0 ,
                Total_MW_Greenbyte__c   = 0 ,
                
                MW_Bluepoint__c         = 0 ,
                MW_Drive__c             = 0 ,
                MW_Greenbyte__c         = 0 ,
                
                Child_MW_Bluepoint__c   = 0,
                Child_MW_Drive__c       = 0,
                Child_MW_Greenbyte__c   = 0,
                
                Account__c                  =   acc.Id
            );
            amwTiInsert.add(amw);
        }
        
        insert amwTiInsert;
        
        
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod07(){
        Test.startTest();
        Account acc = [Select id from account where name like 'Test-2023' LIMIT 1];
        List<Account_Plant__c> apList= [Select id from Account_Plant__c LIMIT 3];
        List<Plant_Product_Transaction__c> pptList = [Select Id FROM Plant_Product_Transaction__c LIMIT 3]; 
        
        for(Integer i = 0 ; i < 3 ;i++){
            pptList[i].Account__c = acc.Id;
            apList[i].Account__c = acc.Id;
        }
        
        update apList;
        update pptList;
        
        
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    @isTest
    public static void testMethod09(){
        Test.startTest();
        
        Account acc = [Select id from account where name like 'Test-2023' LIMIT 1];
        List<Account_Plant__c> apList= [Select id from Account_Plant__c LIMIT 3];
        List<Plant_Product_Transaction__c> pptList = [Select Id FROM Plant_Product_Transaction__c LIMIT 3]; 
        
        for(Integer i = 0 ; i < 3 ;i++){
            pptList[i].Account__c = acc.Id;
            apList[i].Account__c = acc.Id;
        }
        Active_Megawatts__c amw = new Active_Megawatts__c(
            Total_MW_Bluepoint__c   = 0 ,
            Total_MW_Drive__c       = 0 ,
            Total_MW_Greenbyte__c   = 0 ,
            
            MW_Bluepoint__c         = 0 ,
            MW_Drive__c             = 0 ,
            MW_Greenbyte__c         = 0 ,
            
            Child_MW_Bluepoint__c   = 0,
            Child_MW_Drive__c       = 0,
            Child_MW_Greenbyte__c   = 0,
            
            Account__c                  =   acc.Id
        );
        insert amw;
        update apList;
        update pptList;
        
        
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod10(){
        Test.startTest();
        
        MSA_Contract__c msa = new MSA_Contract__c();
        msa.Subsidiary__c = 'Power Factors LLC';
        msa.Parent_MSA_Opt_Out__c = 'Yes';
        insert msa;
        
        Account acc = [Select id from account where name like 'Test-2023' LIMIT 1];
        acc.Uses_MSA_of__c = msa.id;
        update acc;
        
        List<Account_Plant__c> apList= [Select id from Account_Plant__c LIMIT 3];
        List<Plant_Product_Transaction__c> pptList = [Select Id FROM Plant_Product_Transaction__c LIMIT 3]; 
        
        for(Integer i = 0 ; i < 3 ;i++){
            pptList[i].Account__c = acc.Id;
            apList[i].Account__c = acc.Id;
        }
        Active_Megawatts__c amw = new Active_Megawatts__c(
            Total_MW_Bluepoint__c   = 0 ,
            Total_MW_Drive__c       = 0 ,
            Total_MW_Greenbyte__c   = 0 ,
            
            MW_Bluepoint__c         = 0 ,
            MW_Drive__c             = 0 ,
            MW_Greenbyte__c         = 0 ,
            
            Child_MW_Bluepoint__c   = 0,
            Child_MW_Drive__c       = 0,
            Child_MW_Greenbyte__c   = 0,
            
            Account__c                  =   acc.Id
        );
        insert amw;
        update apList;
        update pptList;
        
        
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMethod11(){
        Test.startTest();
        MSA_Contract__c msa = new MSA_Contract__c();
        msa.Subsidiary__c = 'Power Factors LLC';
        msa.Parent_MSA_Opt_Out__c = 'Yes';
        insert msa;
        
        Account acc = [Select id from account where name like 'Test-2023' LIMIT 1];
        acc.Uses_MSA_of__c = msa.id;
        update acc;
        List<Account_Plant__c> apList= [Select id from Account_Plant__c LIMIT 3];
        List<Plant_Product_Transaction__c> pptList = [Select Id FROM Plant_Product_Transaction__c LIMIT 3]; 
        
        for(Integer i = 0 ; i < 3 ;i++){
            pptList[i].Account__c = acc.Id;
            apList[i].Account__c = acc.Id;
        }
        update apList;
        update pptList;
        
        
        AccountHierarchyproductfamily upd = new AccountHierarchyproductfamily();
        Database.executeBatch(upd);
        
        Test.stopTest();
    }
}