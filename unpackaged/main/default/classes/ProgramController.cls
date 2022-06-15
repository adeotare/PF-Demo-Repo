/**
 * This class is for updating CC project records for related program  
 * from quick action
 */
public with sharing class ProgramController {
    /**
     * This method will fetch all required projects for associating program
     * @return :  all projects where program is not associated.
     */
    @AuraEnabled
    public static List<project_cloud__Project__c> fetchData() {
        //Query and return list of Projects
        List<project_cloud__Project__c> objRecords = new List<project_cloud__Project__c>();
        if(project_cloud__Project__c.SObjectType.getDescribe().isAccessible()){
            objRecords = [select Id, Name, project_cloud__Type__c,External_Status__c, Internal_Status__c,Owner.Name,Plant_Name__c,CreatedDate  from project_cloud__Project__c  where Program_Name__c = null limit 2000];
            
        }
        return objRecords;
    }
    /**
    * This method will save Project record for program Id  
    * @param  :  program Id and project list
    * @return :  Save projects for Program Id
    */
    @AuraEnabled 
    public static void addProjects(String programId, String projectIdListJSON){
        if(project_cloud__Project__c.SObjectType.getDescribe().isAccessible()){
            List<project_cloud__Project__c> lstProjects = new List<project_cloud__Project__c>();
            Type idArrType = Type.forName('List<string>');
            List<string> lstPeojectIds = (List<string>) JSON.deserialize(projectIdListJSON, idArrType);

            system.debug('==programId==::'+programId);
            system.debug('==lstPeojectIds==::'+lstPeojectIds);
            if(!string.isblank(programId) && lstPeojectIds.size()>0){
                for(project_cloud__Project__c projRec: [SELECT Id, Program_Name__c From project_cloud__Project__c where id IN :lstPeojectIds]){
                    projRec.Program_Name__c = programId;
                    lstProjects.add(projRec);
                }
                update lstProjects;
            }
        }
    }
}