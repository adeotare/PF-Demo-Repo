@istest
public class CardPriorityTest {
@istest
    static void Prioritytest()
    {
        
    project_cloud__Project__c p= new project_cloud__Project__c(
        name = 'Testing',
        Product_Family__c = 'Drive',
        project_cloud__Methodology__c = 'Kanban',
        Manage_Project_Priorities__c = true,
        project_cloud__Autonomous_Start__c = system.today(),
        project_cloud__Autonomous_End__c = system.today() + 5

    ); 
    insert p; 

    project_cloud__Project__c p1 =new project_cloud__Project__c( 
        name = 'testing2',
        Product_Family__c = 'Drive',
        project_cloud__Methodology__c = 'Waterfall',
        Position__c = 1
    );
    insert p1; 

        system.debug('project1=='+p1);  
    project_cloud__Project__c p2 =new project_cloud__Project__c(
        name = 'testing1',
        Product_Family__c = 'Drive',
        project_cloud__Methodology__c = 'Waterfall',
        Position__c = 1
    );
    insert p2; 
        system.debug('project2=='+p2);  

    
    project_cloud__Board__c  testBoard = new project_cloud__Board__c();
        testBoard.name = 'test name';
        insert testBoard;
     
        
    project_cloud__Card__c card1 = new project_cloud__Card__c();
        card1.project_cloud__Card_Name__c = p1.name;
        card1.project_cloud__Position__c = 1;
        card1.Card_Created_From_Project_Id__c = p1.Id;
        card1.Id = p1.OwnerId;
        card1.project_cloud__Board__c = testBoard.Id;
        insert card1; 

        system.debug('card1=='+card1); 
        
    project_cloud__Card__c card2= new project_cloud__Card__c();
        card2.project_cloud__Card_Name__c = p2.name;
        card2.project_cloud__Position__c = 2;
        card2.Card_Created_From_Project_Id__c = p2.Id;
        card2.Id = p2.Id;     
        insert card2;     
        system.debug('card2=='+card2);      
    }
}