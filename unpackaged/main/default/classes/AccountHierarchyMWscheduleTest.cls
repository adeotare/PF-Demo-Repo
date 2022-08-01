@isTest
public class AccountHierarchyMWscheduleTest {
 public static testmethod void test()
 {
    Test.startTest();
    AccountHierarchyMWschedule amw= new AccountHierarchyMWschedule();
    string sch='0 0 2 * * ?';
    system.Schedule('Test AccountHierarchyMW',sch,amw);
    Test.stopTest();
 }

}