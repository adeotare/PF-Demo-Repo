trigger ProjectBoard on project_cloud__Project__c (before insert,before update, after update, before delete) {
    List<project_cloud__Project__c> projectList = new list<project_cloud__Project__c>();
    if(Trigger.isBefore  ){
        if(Trigger.isInsert){
            for(project_cloud__Project__c project : Trigger.new){
                if(project.Product_Family__c != null){
                    projectList.add(project);
                }
            } 
        }
       
        if(trigger.isUpdate){
            for(project_cloud__Project__c project : Trigger.new){
                system.debug('----before update---');
                if(project.Internal_Status__c != 'To Do' && trigger.oldMap.get(project.Id).Internal_Status__c == 'To Do'
                   && project.Internal_Status__c != trigger.oldMap.get(project.Id).Internal_Status__c ){
                       project.Position__c = 0;
                   }
            }
        }
    }
    // This portion of the code is designed to add new Cards to a Kanban Project from the creation of a new Project
    // After the creation of a new Project the Trigger is designed to create a new Card reprensenting that newly
    // created project
    if(Trigger.isAfter){

        if (Trigger.isUpdate && Trigger.New[0].Manage_Project_Priorities__c == false) {

            //System.debug('After update trigger------------');
            // List: will hold the new Card that is going to be inserted in the Kanban Project
            List<project_cloud__Card__c> newCardList =  new List<project_cloud__Card__c>();
           // List: will hold the Card Member that represents the Project Manager in the Project
            List<project_cloud__Card_Member__c> newCardMemberList =  new List<project_cloud__Card_Member__c>();
            //
            // List<project_cloud__Project__c> updateProjectList = new List<project_cloud__Project__c>();
 
            List<project_cloud__Project__c> projectMain = [SELECT 
                                                            Id, 
                                                            Name, 
                                                            project_cloud__IsTemplate__c, 
                                                            //project_cloud__Type__c,
                                                            Product_Family__c,
                                                            project_cloud__Methodology__c, 
                                                            OwnerId, 
                                                            project_cloud__Project_Duration__c, 
                                                            project_cloud__Start__c,
                                                            Internal_Status__c
                                                        FROM project_cloud__Project__c
                                                        WHERE Manage_Project_Priorities__c = true ];
    
                                                        // SELECTING INTERNAL AND EXTERNAL TYPE FOR NOW
                                                        // NOW WE GOT TO SEE HOW TO GET THE BOARD FROM THESE PROJECTS
    
            List<project_cloud__Board__c> boardList = [SELECT 
                                                        Id, 
                                                        project_cloud__Project_Phase__r.project_cloud__Project__c, 
                                                        project_cloud__Project_Phase__r.project_cloud__Project__r.Product_Family__c,
                                                        project_cloud__Board_Process__c 
                                                    FROM project_cloud__Board__c
                                                    WHERE project_cloud__Project_Phase__r.project_cloud__Project__c  IN :projectMain];

            // Create a map: <Board ID, Board Process ID>
            Map<Id, Id> boardIdToBoardProcess = new Map<Id, Id>();
            // Create a map <Project Type, Board>
            Map<String, Id> projectTypeToBoard = new Map<String, Id>();
            // Save Board Process Ids
            for(project_cloud__Board__c b : boardList){
                projectTypeToBoard.put(b.project_cloud__Project_Phase__r.project_cloud__Project__r.Product_Family__c, b.Id);
                boardIdToBoardProcess.put(b.Id, b.project_cloud__Board_Process__c);
            }

            List<project_cloud__Board_Process_Step__c> boardProcessSteps = [SELECT Id, Name, 
                                                                            project_cloud__Board_Process__c
                                                                            FROM project_cloud__Board_Process_Step__c 
                                                                            WHERE Name = 'New'
                                                                            AND project_cloud__Board_Process__c IN :boardIdToBoardProcess.values()];

            Map<Id, Id> boardProcessToStep = new Map<Id, Id>();
            for (project_cloud__Board_Process_Step__c bProcessStep : boardProcessSteps) {
                
                boardProcessToStep.put(bProcessStep.project_cloud__Board_Process__c, bProcessStep.Id);
            }
    
            // SOQL query to the newly created project (Project object) to gather the necessary field data to be added to the card
            /* Calculated Start Date
             *  Calculated End Date
             *  Card Created: Lookup field to the Card
             *  OwnerId: to create the Card Member that represents the Project Manager */
            set<string> ProjectIds =new set<string>(); 
            Map<Id,string> StatusCheck = new Map<Id, string>();
                // Save projectStatus  Ids
            for(project_cloud__Project__c p : Trigger.New){
                StatusCheck.put(p.Id , p.Internal_Status__c ); 
                ProjectIds.add(p.id);
            } 
            boolean isprojectcardExist=false;
            for(project_cloud__Card__c cm: [select id, project_cloud__Card_Name__c from project_cloud__Card__c where Card_Created_From_Project_Id__c IN :ProjectIds])
            {
                if(cm.id != null){
                    isprojectcardExist=true;
                }
            } 
  
            List<project_cloud__Project__c> newProjects = [SELECT 
                                                                Id, 
                                                                Name, 
                                                                Product_Family__c,
                                                                Internal_Status__c ,
                                                                project_cloud__Type__c,
                                                                project_cloud__Calculated_Start__c, 
                                                                project_cloud__Calculated_End__c, 
                                                                Card_Created__c, 
                                                                OwnerId
                                                            FROM project_cloud__Project__c
                                                            WHERE Id IN :Trigger.New
                                                             ];
             
            for(project_cloud__Project__c p :newProjects){ 
                    
                // Card creation from the data gather from the project
                // project_cloud__Board__c: fixed board in the Kanban project
                // project_cloud__Board_Process_Step__c: step in the fixed board
                if(StatusCheck.get(p.Id) == 'To Do' &&  isprojectcardExist == false ) {

                    if(p.Product_Family__c == 'Greenbyte' || p.Product_Family__c == 'BluePoint')
                    {
                       p.Product_Family__c= 'Greenbyte,BluePoint';
                    }
                     project_cloud__Card__c newCard = new project_cloud__Card__c(
                         Card_Created_From_Project_Id__c = p.Id,
                         project_cloud__Card_Name__c = p.Name,
                         ProjectOwnerIdText__c = p.OwnerId,
                         Calculated_Start_Date__c = p.project_cloud__Calculated_Start__c,
                         Calculated_End_Date__c = p.project_cloud__Calculated_End__c,
                        //  project_cloud__Board__c = p.project_cloud__Type__c != null ? projectTypeToBoard.get(p.project_cloud__Type__c) : projectTypeToBoard.get(null),
                         project_cloud__Board__c = projectTypeToBoard.get(p.Product_Family__c),
                         project_cloud__Board_Process_Step__c = p.Product_Family__c != null 
                                                                ? boardProcessToStep.get(boardIdToBoardProcess.get(projectTypeToBoard.get(p.Product_Family__c)))
                                                                : boardProcessToStep.get(boardIdToBoardProcess.get(projectTypeToBoard.get(null)))
                     );
                     
                     newCardList.add(newCard);
                     // To update the project to alert the PM that a Card exist
                     p.Card_Created__c = true;
                     // updateProjectList.add(p);
                }
                // If the card was created and added the list successfuly, it gets inserted in the Salesforce Database
                if(!newCardList.isEmpty()){
                    insert newCardList;   
                }
            
                // To create the Card Member that will represent the Project Manager
                for(project_cloud__Card__c c: newCardList){

                    //VERIFY IF ENTERING OWNER IS A QUEUE OR A USER
                    //IF THE ENTERING OWNER IS A USER, THEN ASSIGN A CARD MEMBER
                    //IF NOT, IGNORE CARD MEMBER
                    if(c.ProjectOwnerIdText__c.startsWith('005')){
                        //System.debug('CHECK PROJECT OWNER ID: '+c.ProjectOwnerIdText__c.startsWith('005'));
                        project_cloud__Card_Member__c cardMember = new project_cloud__Card_Member__c(
                            project_cloud__Card__c = c.Id,
                            project_cloud__User__c = c.ProjectOwnerIdText__c             
                        );
                        newCardMemberList.add(cardMember);
                    } 
                }
                // If the Card Member was created and added the list successfuly, it gets inserted in the Salesforce Database
                if(!newCardMemberList.isEmpty()){
                    insert newCardMemberList;   
                }
        
                // If the status is Not In Progress then this if condition will function for Deletion of card
                if(StatusCheck.get(p.Id)!= 'To Do' && isprojectcardExist == true ) {
                    
                    List<project_cloud__Card__c> cardToUpdate = new List<project_cloud__Card__c>();
                    List<project_cloud__Project__c> projectList = new List<project_cloud__Project__c>();

                    List<project_cloud__Card__c> card = [SELECT Id,  Card_Created_From_Project_Id__c,
                                                        ProjectOwnerIdText__c 
                                                        FROM project_cloud__Card__c
                                                        WHERE Card_Created_From_Project_Id__c IN :Trigger.new];
            
                    if( p.Name != trigger.oldMap.get(p.Id).Name ||
                        p.project_cloud__Calculated_Start__c != trigger.oldMap.get(p.Id).project_cloud__Calculated_Start__c ||
                        p.project_cloud__Calculated_End__c != trigger.oldMap.get(p.Id).project_cloud__Calculated_End__c ||
                        p.OwnerId != trigger.oldMap.get(p.Id).OwnerId ||
                        p.Internal_Status__c !=trigger.oldmap.get(p.id).Internal_Status__c )
                    {

                        project_cloud__Card__c newCard = new project_cloud__Card__c(
                            Id = card[0].Id,
                            Card_Created_From_Project_Id__c = p.Id,
                            project_cloud__Card_Name__c = p.Name,
                            ProjectOwnerIdText__c = p.OwnerId,
                            Calculated_Start_Date__c = p.project_cloud__Calculated_Start__c,
                            Calculated_End_Date__c = p.project_cloud__Calculated_End__c
                        
                        );    
                        cardToUpdate.add(newCard);
                        projectList.add(p);
                    }  
                    
                    if(!cardToUpdate.isEmpty()){
                        update cardToUpdate;
                    }
            
                    if(!cardToUpdate.isEmpty())// &&
                    //(projectList[0].OwnerId != trigger.oldMap.get(projectList[0].Id).OwnerId) )
                    {
                        List<project_cloud__Card_Member__c> createCardMemberList = new List<project_cloud__Card_Member__c>();
                        List<project_cloud__Card__c> deleteCardMemberList = new List<project_cloud__Card__c>();
                        List<project_cloud__Card__c> cardMemberToDelete = [SELECT Id
                                                                                FROM project_cloud__Card__c
                                                                                WHERE id = :card[0].Id];   
            
                        if(!cardMemberToDelete.isEmpty() && (p.Internal_Status__c != 'To Do')){
                            for(project_cloud__Card__c c: card){
                                project_cloud__Card__c cardMemDel = new project_cloud__Card__c(
                                    Id = cardMemberToDelete[0].Id
                                );
                                deleteCardMemberList.add(cardMemDel);
                            }   
                        }
            
                        if(!deleteCardMemberList.isEmpty()){
                            delete deleteCardMemberList;  
                        } 
                         
                    }
                }
            }
        }
    }
    
    else  
    // If a Project gets deleted this portion of the trigger will get rid of any associated card.
    if(Trigger.isDelete){     
        List<project_cloud__Card__c> deleteCardList = new List<project_cloud__Card__c>();
       
        for(project_cloud__Card__c c: [SELECT Id, Name, Card_Created_From_Project_Id__c
                                       FROM project_cloud__Card__c
                                       WHERE Card_Created_From_Project_Id__c IN :Trigger.oldMap.keySet()])
        {                                    
            deleteCardList.add(c);
        }
        
        if(!deleteCardList.isEmpty()){
            delete deleteCardList;   
        }          

    }

}

/**trigger ProjectBoard on project_cloud__Project__c (before insert,before update, after update, before delete) {
    list<project_cloud__Project__c>projectList1 = new list<project_cloud__Project__c>();
    if(Trigger.isBefore  ){
        if(Trigger.isInsert){
            for(project_cloud__Project__c project : Trigger.new){
                if(project.Product_Family__c != null){
                    projectList1.add(project);
                }
            }
        }        
        if(trigger.isUpdate){
            for(project_cloud__Project__c project : Trigger.new){
                system.debug('----before update---');
                if(project.Internal_Status__c != 'To Do' && trigger.oldMap.get(project.Id).Internal_Status__c == 'To Do'
                   && project.Internal_Status__c != trigger.oldMap.get(project.Id).Internal_Status__c ){
                       project.Position__c = 0;
                   }
            }
        }
    }
    // This portion of the code is designed to add new Cards to a Kanban Project from the creation of a new Project
    // After the creation of a new Project the Trigger is designed to create a new Card reprensenting that newly
    // created project
    if(Trigger.isAfter){
        if (Trigger.isupdate) {
            System.debug('After update trigger------------');
            // List: will hold the new Card that is going to be inserted in the Kanban Project
            List<project_cloud__Card__c> newCardList =  new List<project_cloud__Card__c>();
            // List: will hold the Card Member that represents the Project Manager in the Project
            List<project_cloud__Card_Member__c> newCardMemberList =  new List<project_cloud__Card_Member__c>();
            //
            // List<project_cloud__Project__c> updateProjectList = new List<project_cloud__Project__c>();
            
            List<project_cloud__Project__c> projectMain = [SELECT 
                                                           Id, 
                                                           Name, 
                                                           project_cloud__IsTemplate__c, 
                                                           //project_cloud__Type__c,
                                                           Product_Family__c,
                                                           project_cloud__Methodology__c, 
                                                           OwnerId, 
                                                           project_cloud__Project_Duration__c, 
                                                           project_cloud__Start__c,
                                                           Project_Status__c 
                                                           FROM project_cloud__Project__c
                                                           WHERE Manage_Project_Priorities__c = true ];
            
            // SELECTING INTERNAL AND EXTERNAL TYPE FOR NOW
            // NOW WE GOT TO SEE HOW TO GET THE BOARD FROM THESE PROJECTS
            
            System.debug('if priorities true------------' + projectMain);
            
            List<project_cloud__Board__c> boardList = [SELECT 
                                                       Id, 
                                                       project_cloud__Project_Phase__r.project_cloud__Project__c, 
                                                       project_cloud__Project_Phase__r.project_cloud__Project__r.Product_Family__c,
                                                       project_cloud__Board_Process__c 
                                                       FROM project_cloud__Board__c
                                                       WHERE project_cloud__Project_Phase__r.project_cloud__Project__c  IN :projectMain];
            
            // Create a map: <Board ID, Board Process ID>
            Map<Id, Id> boardIdToBoardProcess = new Map<Id, Id>();
            // Create a map <Project Type, Board>
            Map<String, Id> projectTypeToBoard = new Map<String, Id>();
            // Save Board Process Ids
            for(project_cloud__Board__c b : boardList){
                projectTypeToBoard.put(b.project_cloud__Project_Phase__r.project_cloud__Project__r.Product_Family__c, b.Id);
                boardIdToBoardProcess.put(b.Id, b.project_cloud__Board_Process__c);
            }
            //System.debug('fetch board process------------' + board);
            
            List<project_cloud__Board_Process_Step__c> boardProcessSteps = [SELECT Id, Name, 
                                                                            project_cloud__Board_Process__c
                                                                            FROM project_cloud__Board_Process_Step__c 
                                                                            WHERE Name = 'New'
                                                                            AND project_cloud__Board_Process__c IN :boardIdToBoardProcess.values()];
            Map<Id, Id> boardProcessToStep = new Map<Id, Id>();
            for (project_cloud__Board_Process_Step__c bProcessStep : boardProcessSteps) {
                boardProcessToStep.put(bProcessStep.project_cloud__Board_Process__c, bProcessStep.Id);
            }
            
            System.debug('fetch board process step------------:' + boardProcessSteps );
            // SOQL query to the newly created project (Project object) to gather the necessary field data to be added to the card
            /* Calculated Start Date
*  Calculated End Date
*  Card Created: Lookup field to the Card
*  OwnerId: to create the Card Member that represents the Project Manager */
        /** set<string> ProjectIds =new set<string>(); 
            Map<Id,string> StatusCheck = new Map<Id, string>();
            // Save projectStatus  Ids
            for(project_cloud__Project__c p : Trigger.New){
                StatusCheck.put(p.Id , p.Internal_Status__c ); 
                ProjectIds.add(p.id);
            } 
            boolean isprojectcardExist=false;
            for(project_cloud__Card__c cm: [select id from project_cloud__Card__c where Card_Created_From_Project_Id__c IN:ProjectIds])
            {
                if(cm.id != null){
                    isprojectcardExist=true;
                }
            } 
            
            List<project_cloud__Project__c> newProjects = [SELECT 
                                                           Id, 
                                                           Name, 
                                                           Product_Family__c,
                                                           Internal_Status__c ,
                                                           project_cloud__Type__c,
                                                           project_cloud__Calculated_Start__c, 
                                                           project_cloud__Calculated_End__c, 
                                                           Card_Created__c, 
                                                           OwnerId
                                                           FROM project_cloud__Project__c
                                                           WHERE Id IN :Trigger.New
                                                          ];
            
            
            
            for(project_cloud__Project__c p : newProjects){ 
                System.debug('test--------');
                // Card creation from the data gather from the project
                // project_cloud__Board__c: fixed board in the Kanban project
                // project_cloud__Board_Process_Step__c: step in the fixed board
                system.debug('Status... :' +p.Internal_Status__c );
                if(StatusCheck.get(p.Id)=='To Do' &&  isprojectcardExist == false ) {
                    if(p.Product_Family__c=='Greenbyte' || p.Product_Family__c=='BluePoint')
                    {
                        p.Product_Family__c= 'Greenbyte,BluePoint';
                    }
                    project_cloud__Card__c newCard = new project_cloud__Card__c(
                        Card_Created_From_Project_Id__c = p.Id,
                        project_cloud__Card_Name__c = p.Name,
                        ProjectOwnerIdText__c = p.OwnerId,
                        Calculated_Start_Date__c = p.project_cloud__Calculated_Start__c,
                        Calculated_End_Date__c = p.project_cloud__Calculated_End__c,
                        //    project_cloud__Board__c = p.project_cloud__Type__c != null ? projectTypeToBoard.get(p.project_cloud__Type__c) : projectTypeToBoard.get(null),
                        project_cloud__Board__c = projectTypeToBoard.get(p.Product_Family__c),
                        project_cloud__Board_Process_Step__c = p.Product_Family__c != null 
                        ? boardProcessToStep.get(boardIdToBoardProcess.get(projectTypeToBoard.get(p.Product_Family__c)))
                        : boardProcessToStep.get(boardIdToBoardProcess.get(projectTypeToBoard.get(null)))
                    );
                    System.debug('Board Id ' + newCard.project_cloud__Board__c);
                    System.System.debug(boardProcessToStep.get(boardIdToBoardProcess.get(newCard.project_cloud__Board__c)));
                    System.debug(newCard.project_cloud__Board_Process_Step__c);
                    newCardList.add(newCard);
                    // To update the project to alert the PM that a Card exist
                    p.Card_Created__c = true;
                    // updateProjectList.add(p);
                }
                // If the card was created and added the list successfuly, it gets inserted in the Salesforce Database
                if(!newCardList.isEmpty()){
                    insert newCardList;   
                }
                
                
                System.debug('newCardList--------'+newCardList);
                // To create the Card Member that will represent the Project Manager
                
                for(project_cloud__Card__c c: newCardList){
                    //VERIFY IF ENTERING OWNER IS A QUEUE OR A USER
                    //IF THE ENTERING OWNER IS A USER, THEN ASSIGN A CARD MEMBER
                    //IF NOT, IGNORE CARD MEMBER
                    if(c.ProjectOwnerIdText__c.startsWith('005')){
                        System.debug(c.ProjectOwnerIdText__c.startsWith('005'));
                        project_cloud__Card_Member__c cardMember = new project_cloud__Card_Member__c(
                            project_cloud__Card__c = c.Id,
                            project_cloud__User__c = c.ProjectOwnerIdText__c             
                        );
                        newCardMemberList.add(cardMember);
                    } 
                }
                // If the Card Member was created and added the list successfuly, it gets inserted in the Salesforce Database
                if(!newCardMemberList.isEmpty()){
                    insert newCardMemberList;   
                }
                
                
                System.debug('newCardMemberList--------'+newCardMemberList);
                // If the status is Not In Progress then this if condition will function for Deletion of card
                
                if(StatusCheck.get(p.Id)!='To Do' && isprojectcardExist==True ) {
                    system.debug('code for removing card');
                    List<project_cloud__Card__c> cardToUpdate = new List<project_cloud__Card__c>();
                    List<project_cloud__Project__c> projectList = new List<project_cloud__Project__c>();
                    //
                    List<project_cloud__Card__c> card = [SELECT Id,  Card_Created_From_Project_Id__c,
                                                         ProjectOwnerIdText__c 
                                                         FROM project_cloud__Card__c
                                                         WHERE Card_Created_From_Project_Id__c IN :Trigger.new];
                    
                    
                    if( p.Name != trigger.oldMap.get(p.Id).Name ||
                       p.project_cloud__Calculated_Start__c != trigger.oldMap.get(p.Id).project_cloud__Calculated_Start__c ||
                       p.project_cloud__Calculated_End__c != trigger.oldMap.get(p.Id).project_cloud__Calculated_End__c ||
                       p.OwnerId != trigger.oldMap.get(p.Id).OwnerId 
                       || p.Internal_Status__c !=trigger.oldmap.get(p.id).Internal_Status__c  )
                    {
                        
                        project_cloud__Card__c newCard = new project_cloud__Card__c(
                            Id = card[0].Id,
                            Card_Created_From_Project_Id__c = p.Id,
                            project_cloud__Card_Name__c = p.Name,
                            ProjectOwnerIdText__c = p.OwnerId,
                            Calculated_Start_Date__c = p.project_cloud__Calculated_Start__c,
                            Calculated_End_Date__c = p.project_cloud__Calculated_End__c
                            
                        );    
                        cardToUpdate.add(newCard);
                        projectList.add(p);
                    }  
                    
                    
                    if(!cardToUpdate.isEmpty()){
                        update cardToUpdate;
                    }
                    System.debug('cardToUpdate-------'+cardToUpdate); 
                    
                    if(!cardToUpdate.isEmpty())// &&
                        //(projectList[0].OwnerId != trigger.oldMap.get(projectList[0].Id).OwnerId) )
                    {
                        List<project_cloud__Card_Member__c> createCardMemberList = new List<project_cloud__Card_Member__c>();
                        List<project_cloud__Card__c> deleteCardMemberList = new List<project_cloud__Card__c>();
                        List<project_cloud__Card__c> cardMemberToDelete = [SELECT Id
                                                                           FROM project_cloud__Card__c
                                                                           WHERE id = :card[0].Id];   
                        
                        if(!cardMemberToDelete.isEmpty() && (p.Internal_Status__c !='To Do')){
                            for(project_cloud__Card__c c: card){
                                project_cloud__Card__c cardMemDel = new project_cloud__Card__c(
                                    Id = cardMemberToDelete[0].Id
                                );
                                deleteCardMemberList.add(cardMemDel);
                            }   
                            system.debug('card member to del  :'+ deleteCardMemberList );
                        }
                        
                        if(!deleteCardMemberList.isEmpty()){
                            delete deleteCardMemberList;  
                        } 
                        
                        
                    }
                }
            }
        }
    }else
        
        // If a Project gets deleted this portion of the trigger will get rid of any associated card.
        if(Trigger.isDelete){     
            List<project_cloud__Card__c> deleteCardList = new List<project_cloud__Card__c>();
            set<id>projectCloudIdSet= new set<id>();
            for(project_cloud__Card__c c: [SELECT Id, Name, Card_Created_From_Project_Id__c
                                           FROM project_cloud__Card__c
                                           WHERE Card_Created_From_Project_Id__c IN :Trigger.oldMap.keySet()])
            {                                    
                deleteCardList.add(c);
                projectCloudIdSet.add(c.Card_Created_From_Project_Id__c);
            }
            
            if(!deleteCardList.isEmpty()){
                delete deleteCardList;   
            }          
            
        }
}*/