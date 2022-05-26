public with sharing class PromptNotes {
    @AuraEnabled
    public static String queryPromptNotes(String promptName) { 
        String notes = '';
        List<Prompt_Information__c> promptNote = [SELECT id,Notes__c 
                            FROM Prompt_Information__c WHERE Name =: promptName LIMIT 1];
        if(promptNote.size()>0){
            notes = String.isblank(promptNote[0].Notes__c)?'':promptNote[0].Notes__c;
        }

        return notes;
    }
}