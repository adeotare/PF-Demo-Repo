@isTest(SeeAllData=true)
public class CardPriorityTest {

    @isTest
    public static void Prioritytest()
    {

        Id profId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

        User user = new User(ProfileId = profId,
                            LastName = 'Readonly',
                            Email = 'puser000@amamama.com',
                            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                            CompanyName = 'TEST',
                            Alias = 'testmark',
                            TimeZoneSidKey = 'America/Los_Angeles',
                            EmailEncodingKey = 'UTF-8',
                            LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US');
       
        insert user;
        
        project_cloud__Project__c p= new project_cloud__Project__c(
            name = 'Testing',
            Product_Family__c = 'Drive',
            project_cloud__Methodology__c = 'Kanban',
            Manage_Project_Priorities__c = true,
            project_cloud__Autonomous_Start__c = system.today(),
            project_cloud__Autonomous_End__c = system.today() + 5

        ); 
        insert p;

        project_cloud__Project_Phase__c phase1 = new project_cloud__Project_Phase__c(
            Name = 'Phase 101',
            project_cloud__Project__c = p.Id
        );
        insert phase1;

        project_cloud__Project__c p1 = new project_cloud__Project__c( 
            name = 'testing2',
            Product_Family__c = 'Greenbyte',
            project_cloud__Methodology__c = 'Waterfall',
            Position__c = 1,
            OwnerId = user.id
        );
        
        insert p1; 
        system.debug('project1=='+p1);

        project_cloud__Project__c p2 = new project_cloud__Project__c(
            Name = 'testing1',
            Product_Family__c = 'Drive',
            project_cloud__Methodology__c = 'Waterfall',
            Position__c = 1,
            OwnerId = user.Id,
            Internal_Status__c = 'In progress'
        );
        insert p2; 
        system.debug('project2=='+p2);  
        
        project_cloud__Board_Process__c boardProcess = [SELECT Id FROM project_cloud__Board_Process__c WHERE Name = 'Basic Kanban' limit 1];

        // project_cloud__Board_Process__c boardProcess = new project_cloud__Board_Process__c();
        // boardProcess.Name = 'Test Board Process';
        // insert boardProcess;

        project_cloud__Board_Process_Step__c boardProcessStep1 = [SELECT Id FROM project_cloud__Board_Process_Step__c WHERE Name = 'New' limit 1];

        // project_cloud__Board_Process_Step__c boardProcessStep = new project_cloud__Board_Process_Step__c();
        // boardProcessStep.Name = 'Test Board Process Step';
        // insert boardProcessStep;
        
        project_cloud__Board__c  testBoard = new project_cloud__Board__c();
        testBoard.name = 'test name';
        testBoard.project_cloud__Board_Process__c = boardProcess.id;
        testBoard.project_cloud__Project_Phase__c = phase1.Id;
        insert testBoard;

        project_cloud__Card__c card1 = new project_cloud__Card__c();
        card1.project_cloud__Card_Name__c = p1.Name;
        card1.project_cloud__Position__c = 1;
        card1.Card_Created_From_Project_Id__c = p1.Id;
        // card1.Project_Owner_Id__c = p1.OwnerId;
        card1.ProjectOwnerIdText__c = p1.OwnerId;
        card1.project_cloud__Board__c = testBoard.Id;
        card1.project_cloud__Board_Process_Step__c = boardProcessStep1.Id;
        card1.project_cloud__Priority__c = 'Low';
        insert card1; 
        card1.ProjectOwnerIdText__c = p1.OwnerId;


        //card1.project_cloud__Board_Process_Step__c = boardProcessStep2.Id;
        card1.project_cloud__Priority__c = 'High';
        update card1;
        system.debug('card1=='+card1); 
            
        // project_cloud__Card__c card2= new project_cloud__Card__c();
        // card2.project_cloud__Card_Name__c = p2.name;
        // card2.project_cloud__Position__c = 1;
        // card2.Card_Created_From_Project_Id__c = p2.Id; 
        // card2.Project_Owner_Id__c = p2.OwnerId;
        // card2.ProjectOwnerIdText__c = p2.OwnerId;
        // card2.project_cloud__Board__c = testBoard.Id;
        // card2.project_cloud__Board_Process_Step__c = boardProcessStep.Id;
        // insert card2;     
        // system.debug('card2=='+card2);  
        
        p1.Internal_Status__c = 'Inbox';
        p1.Name = 'Hello World';
        update p1;

        // card1.project_cloud__Position__c = 2;
        // update card1;

        delete p1;

        p2.Internal_Status__c = 'To Do';
        update p2;
        
		p2.Internal_Status__c = 'In progress';
        update p2;
    }

}

/**@isTest(SeeAllData=true)
public class CardPriorityTest {
@istest
    public static void Prioritytest()
    {

        Id profId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;

        User user = new User(ProfileId = profId,
                            LastName = 'Readonly',
                            Email = 'puser000@amamama.com',
                            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                            CompanyName = 'TEST',
                            Alias = 'testmark',
                            TimeZoneSidKey = 'America/Los_Angeles',
                            EmailEncodingKey = 'UTF-8',
                            LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US');
       
        insert user;
        
        project_cloud__Project__c p= new project_cloud__Project__c(
            name = 'Testing',
            Product_Family__c = 'Greenbyte',
            project_cloud__Methodology__c = 'Kanban',
            Manage_Project_Priorities__c = true,
            project_cloud__Autonomous_Start__c = system.today(),
            project_cloud__Autonomous_End__c = system.today() + 5

        ); 
        insert p;
        

        project_cloud__Project__c p1 = new project_cloud__Project__c( 
            name = 'testing2',
            Product_Family__c = 'Drive',
            project_cloud__Methodology__c = 'Waterfall',
            Position__c = 1,
            OwnerId = user.id
        );
        insert p1; 
        system.debug('project1=='+p1);  

        project_cloud__Project__c p2 = new project_cloud__Project__c(
            Name = 'testing1',
            Product_Family__c = 'Drive',
            project_cloud__Methodology__c = 'Waterfall',
            Position__c = 1,
            OwnerId = user.Id
        );
        insert p2; 
        system.debug('project2=='+p2);  
        
        
        project_cloud__Board_Process__c boardProcess = [SELECT Id FROM project_cloud__Board_Process__c WHERE Name = 'Priorities Process' limit 1];

        // project_cloud__Board_Process__c boardProcess = new project_cloud__Board_Process__c();
        // boardProcess.Name = 'Test Board Process';
        // insert boardProcess;

        project_cloud__Board_Process_Step__c boardProcessStep = [SELECT Id FROM project_cloud__Board_Process_Step__c WHERE Name = 'No Priority' limit 1];

        // project_cloud__Board_Process_Step__c boardProcessStep = new project_cloud__Board_Process_Step__c();
        // boardProcessStep.Name = 'Test Board Process Step';
        // insert boardProcessStep;
        
        project_cloud__Board__c  testBoard = new project_cloud__Board__c();
        testBoard.name = 'test name';
        testBoard.project_cloud__Board_Process__c = boardProcess.id;
        insert testBoard;
               
        system.debug('Board process: '+boardProcess);
        system.debug('Test Board: '+testBoard);
        system.debug('Project Owner Id: '+p1.OwnerId);

        project_cloud__Card__c card1 = new project_cloud__Card__c();
        card1.project_cloud__Card_Name__c = p1.Name;
        card1.project_cloud__Position__c = 1;
        card1.Card_Created_From_Project_Id__c = p1.Id;
//        card1.Project_Owner_Id__c = p1.OwnerId;
        card1.ProjectOwnerIdText__c = p1.OwnerId;
        card1.project_cloud__Board__c = testBoard.Id;
        card1.project_cloud__Board_Process_Step__c = boardProcessStep.Id;
        insert card1; 
        card1.ProjectOwnerIdText__c = p1.OwnerId;
        update card1;
        system.debug('card1=='+card1); 
            
        project_cloud__Card__c card2= new project_cloud__Card__c();
        card2.project_cloud__Card_Name__c = p2.name;
        card2.project_cloud__Position__c = 1;
        card2.Card_Created_From_Project_Id__c = p2.Id; 
//        card2.Project_Owner_Id__c = p2.OwnerId;
        card2.ProjectOwnerIdText__c = p2.OwnerId;
        card2.project_cloud__Board__c = testBoard.Id;
        card2.project_cloud__Board_Process_Step__c = boardProcessStep.Id;
        insert card2;     
        
        system.debug('card2=='+card2);  
        
        p.Internal_Status__c = 'To Do';
        update p;

    }

}*/