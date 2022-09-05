@isTest
public class ActHierarchyProductFamilyScheduleTest {
 public static testmethod void test()
 {
    Test.startTest();
    AccountHierarchyProductFamilySchedule apf= new AccountHierarchyProductFamilySchedule();
    string sch='0 0 2 * * ?';
    system.Schedule('Test AccountHierarchyMW',sch,apf);
    Test.stopTest();
 }

}