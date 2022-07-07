/**
 * This is Test class for scheduler class of Auto creating Projects recors  
 * @param  :  
 * @return :  
 */
@istest
public class SchduleBatchAutoCreateProjectsTest {
	public static testMethod void testschedule() {
		Test.StartTest();
		SchduleBatchAutoCreateProjects testsche = new SchduleBatchAutoCreateProjects();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
	}
}