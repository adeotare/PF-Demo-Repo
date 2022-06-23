/**
**/
global class RFIBatchProcess implements Database.Batchable<sObject> {
    global List<RFI_Detail__c> rfiDetailsLst = new List<RFI_Detail__c>();
    global Set<String> errors = new Set<String>();
    //global String[] errors;
    global RFIBatchProcess(List<RFI_Detail__c> objList){
    rfiDetailsLst = objList;
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
    // collect the batches of records or objects to be passed to execute
    String query = 'SELECT Id,Name FROM Account limit 1';
    return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> tacc) {
    try {
        upsert rfiDetailsLst;
        
    } catch(Exception e) {
        System.debug(e.getMessage());
        errors.add(e.getMessage());
        System.debug('errors'+errors);
    }
    System.debug('errors'+errors);
    String userName = UserInfo.getUserName();
    User activeUser = [Select Email From User where Username = : userName limit 1];
    String userEmail = activeUser.Email;
    System.debug('userEmail'+userEmail);
    if(!errors.isEmpty()) {
    
        List<string> toEmailaddress = new  List<string>() ;
        // execute any post-processing operations
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Error Occured During Batch Process: ');
        String mailBody = 'Insertion/Updation of RFI Item failure due to following statements:\n\n'+errors;
        email.setPlainTextBody(mailBody);                           
        toEmailaddress.add(userEmail);
        email.setToAddresses(toEmailaddress);
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
        if (!Test.isRunningtest()) Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        System.debug('toEmailaddress'+toEmailaddress);
        System.debug('messages'+messages);
    }
    }   
    
    global void finish(Database.BatchableContext BC) {
    // execute any post-processing operations
    System.debug('Batch executed successfully');
    System.debug('errors'+errors.size());
        /*  String userName = UserInfo.getUserName();
        User activeUser = [Select Email From User where Username = : userName limit 1];
        String userEmail = activeUser.Email;
        System.debug('userEmail'+userEmail);
    if(!errors.isEmpty()) {
        
        List<string> toEmailaddress = new  List<string>() ;
        // execute any post-processing operations
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Insertion of RFI Item failure due to following statements:');
        String mailBody = ''+ errors;
        email.setPlainTextBody(mailBody);                           
        toEmailaddress.add(userEmail);
        email.setToAddresses(toEmailaddress);
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        System.debug('toEmailaddress'+toEmailaddress);
        System.debug('messages'+messages);
    }*/
    }
    }