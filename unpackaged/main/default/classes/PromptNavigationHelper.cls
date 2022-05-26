public with sharing class PromptNavigationHelper {
 
    public static String findPromptId(String promptName) {
        String retString;

        if(!String.isBlank(promptName)){
            List<Prompt_Information__c> promptInfo = [SELECT id, Prompt_Id__c 
                            FROM Prompt_Information__c WHERE Name =: promptName LIMIT 1];
            if(promptInfo.size() > 0){
                retString = promptInfo[0].Prompt_Id__c;
            }else{
                retString = 'The Next or Previous prompt is not found, Please contact admnistrator.';
            }
        }else{
            retString = 'The Next or Previous prompt is not found, Please contact admnistrator.';
        }
        return retString;
    }
}