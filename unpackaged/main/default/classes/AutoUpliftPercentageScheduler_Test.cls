@istest
public class AutoUpliftPercentageScheduler_Test{
	public static testMethod void testschedule() {
		Test.StartTest();
		AutoUpliftPercentageScheduler testsche = new AutoUpliftPercentageScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}