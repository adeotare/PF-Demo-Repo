@istest
public class PPTBillingTriggerScheduler_Test{
	public static testMethod void testschedule() {
		Test.StartTest();
		PPTBillingTriggerScheduler testsche = new PPTBillingTriggerScheduler();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}