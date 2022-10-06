@isTest
public class AccountHierarchyproductfamilyScdtest {
 public static testmethod void test()
 {
    Test.startTest();
    AccountHierarchyProductFamilySchedule ahpf= new AccountHierarchyProductFamilySchedule();
    string sch='0 0 1 * * ?';
    system.Schedule('Test AccountHierarchyProductFamily',sch,ahpf);
    Test.stopTest();
 }

}