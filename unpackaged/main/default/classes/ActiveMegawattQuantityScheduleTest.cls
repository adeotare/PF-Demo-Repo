@isTest
public class ActiveMegawattQuantityScheduleTest {
 public static testmethod void test()
 {
    Test.startTest();
    ActiveMegawattQuantitySchedule ams= new ActiveMegawattQuantitySchedule();
    string sch='0 0 2 * * ?';
    system.Schedule('Test Activemegawatt',sch,ams);
    Test.stopTest();
 }

}