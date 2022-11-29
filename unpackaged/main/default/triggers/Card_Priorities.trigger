trigger Card_Priorities on project_cloud__Card__c (before insert, after update) {
    list<project_cloud__Card__c>cardList = new list<project_cloud__Card__c>();
    if(trigger.IsBefore && trigger.isInsert){
        for(project_cloud__Card__c card : Trigger.new){
            if(card.project_cloud__Priority__c != null){
                cardList.add(card);
            }
        }
    }
    if(trigger.isAfter && trigger.isUpdate){
        List<project_cloud__Project__c> projecUpdateList = new List<project_cloud__Project__c>();
        
        for(project_cloud__Card__c c: [SELECT Id,     project_cloud__Position__c, project_cloud__Priority__c,
                                       Card_Created_From_Project_Id__c  
                                       FROM project_cloud__Card__c
                                       WHERE Id IN :Trigger.new]){

                                           if( c.project_cloud__Position__c != trigger.oldMap.get(c.Id).project_cloud__Position__c ||
                                              c.project_cloud__Priority__c != trigger.oldMap.get(c.Id).project_cloud__Priority__c  )
                                           {
                                               project_cloud__Project__c updateProject = new project_cloud__Project__c(
                                                   Id = c.Card_Created_From_Project_Id__c,
                                                   Priority__c = c.project_cloud__Priority__c,
                                                   Position__c =c.project_cloud__Position__c
                                               );
                                               projecUpdateList.add(updateProject);
                                           }
                                       }
        if(!projecUpdateList.isEmpty()){
            update projecUpdateList;//
        }
    }
        
}