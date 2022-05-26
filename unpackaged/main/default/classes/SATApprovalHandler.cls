public with sharing class SATApprovalHandler {
    /**
     *This Method used for checking conditions to show/Hide buttons. 
     */
    @AuraEnabled
    public static string setSubmitForApproval(String satRecordId){
        String status = 'None';
        Boolean haveAccessToApproveOrReject = false;
            try{
                system.debug('satRecordId-->'+satRecordId);
                List<ProcessInstanceWorkitem> workItems = [
                    SELECT Id, ProcessInstanceId, ActorId 
                    FROM ProcessInstanceWorkitem 
                    WHERE ProcessInstance.TargetObjectId = :satRecordId  
                ];
                if(workItems.size() > 0 && workItems.get(0).ActorId == UserInfo.getUserId()){
                    haveAccessToApproveOrReject = true;
                }
                //workItems.get(0).ActorId  = userId;
                SAT__c sat = [SELECT Id, Customer_Acceptance_Status__c, SAT_Approval_Status__c FROM SAT__c WHERE Id=:satRecordId ];
                    if((sat.Customer_Acceptance_Status__c == 'Pending' ||
                        sat.Customer_Acceptance_Status__c == 'N/A') && haveAccessToApproveOrReject){
                        status = 'Submitted';
                    }else if(sat.Customer_Acceptance_Status__c == 'On-Hold'){
                        status = 'On-Hold';
                    }
                return status;
            } catch (Exception e) {
                System.debug(' Error Message -> ' + e.getMessage() + ' Line # ' + e.getLineNumber());
                throw new AuraHandledException(e.getMessage()); 
            }
    }

    /**
     * This Method is used to perform approval actions.
     */
    @AuraEnabled
    public static String processStep(String recordId, String comments, String setAction){
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ProcessInstanceId 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordId  
        ];
        return AssetBuilderApprovalHandlerUtils.approvalActionForSat(workItems, recordId, comments, setAction);
    }

    /**
     * This Method is used to perform approval actions.
     */
    @AuraEnabled
    public static String reassignApproval(String recordId, String userId, String setAction){
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ProcessInstanceId, ActorId 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordId  
        ];
        return AssetBuilderApprovalHandlerUtils.reassignApprovalForSat(workItems, userId, setAction);
    }

    /**
     * This method is used to display approval history - related list
     */
    @AuraEnabled (cacheable=true)
    public static ApprovalHistory getApprovalHistory(String recordId){  
                        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                            StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                            ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                            OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                    FROM ProcessInstance where TargetObjectId =:recordId order by CreatedDate DESC];                                                                         
        return AssetBuilderApprovalHandlerUtils.populateApprovalHistoryStepsSAT(processInstances, recordId);                                                 
    }  
    
    public class ApprovalHistoryStep{
        @AuraEnabled  
        public String stepName {get;set;}  
        @AuraEnabled  
        public String stepUrl {get;set;}
        @AuraEnabled  
        public DateTime createdDate {get;set;}   
        @AuraEnabled  
        public String stepStatus {get;set;}  
        @AuraEnabled  
        public String assignedTo {get;set;}   
        @AuraEnabled  
        public String assignedToUrl {get;set;}
        @AuraEnabled
        public String comments {get;set;}
        
        public ApprovalHistoryStep(
            String stepName,
            String stepId,
            DateTime createdDate, 
            String stepStatus,
            String assignedTo,
            String assignedToId,
            String comments )  
        { 
            this.stepName = stepName;
            this.stepUrl = '/' + stepId;
            this.createdDate = createdDate;
            this.assignedTo = assignedTo;  
            this.assignedToUrl = '/'+assignedToId;
            this.comments = comments;

            if(stepStatus == AssetBuilderApprovalHandlerUtils.STATUS_STARTED){
                this.stepStatus = AssetBuilderApprovalHandlerUtils.STATUS_SUBMITTED;
            }else if(stepStatus == AssetBuilderApprovalHandlerUtils.STATUS_REMOVED){
                this.stepStatus = AssetBuilderApprovalHandlerUtils.STATUS_RECALLED;
            }else{
                this.stepStatus = stepStatus;
            }
            
        } 
    }

    public class ApprovalHistory{
        @AuraEnabled
        public List<ApprovalHistoryStep> approvalSteps;
        public ApprovalHistory(List<ApprovalHistoryStep> approvalSteps){
            this.approvalSteps = approvalSteps;
        }
    }
}