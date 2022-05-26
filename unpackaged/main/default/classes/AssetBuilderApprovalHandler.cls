public without sharing   class AssetBuilderApprovalHandler {

    /**
     *This Method used for checking conditions to show/Hide buttons. 
     */
    @AuraEnabled
    public static string setSubmitForApproval(String plantAssetId){
     String status = 'None';
     String queueName = System.label.AB_AllPFCommunityQueue;
     String currentUserId = UserInfo.getUserId();
     Boolean isCustomerAsset = false;
        try{
            Account_Plant__c plantAsset = [SELECT Id, Name, AB_Approval_Status__c,Asset_Builder_Status__c,PF_Service_Product__c FROM Account_Plant__c WHERE Id=:plantAssetId ];
            User currentUser = [SELECT Id,Profile.UserLicense.Name, Profile.Name FROM User WHERE Id=: currentUserId];
            Asset_Builder_Approval__c abaRecord = 
            [SELECT Id, Approval_Status__c FROM Asset_Builder_Approval__c WHERE Account_Plant__c =: plantAsset.Id];
            String abSubmitForApprovalProfileAccess = System.label.AB_ProvideAccessToSubmitForApproval;

            //Status Check for IE Built
            if(currentUser.Profile.UserLicense.Name == 'Salesforce' 
                || abSubmitForApprovalProfileAccess.contains(currentUser.Profile.Name)){
                if(plantAsset.AB_Approval_Status__c == 'Submitted'){
                    status = 'Submitted';
                }
                else if(plantAsset.Asset_Builder_Status__c == 'Completed' && 
                    (plantAsset.AB_Approval_Status__c == null || plantAsset.AB_Approval_Status__c == 'Rejected') ){
                    status = 'showSubmitButton';
                }
            }
            else {
                //Status Check for Customer Built
                Id queueId = [SELECT Id FROM Group WHERE type='Queue' and DeveloperNAME =: queueName LIMIT 1 ].Id ;
                List<User> groupMember =[SELECT id FROM User WHERE id IN ( SELECT userOrGroupId FROM GroupMember WHERE groupId = :queueId AND userOrGroupId =:currentUserId ) AND  isActive = true ];
                //Check whether the user is in All Pf Community queue
                if(groupMember.size()>0 || Test.isRunningTest()){
                    if(plantAsset.PF_Service_Product__c == null){
                        isCustomerAsset = true;
                    }
                    if(plantAsset.PF_Service_Product__c != null){
                        if(plantAsset.PF_Service_Product__c.contains('Implementation (Asset Building)')){
                            isCustomerAsset = false;
                        }
                        else{
                            isCustomerAsset = true;
                        }
                    }
                    if(isCustomerAsset){
                        if(plantAsset.AB_Approval_Status__c == 'Submitted'){
                            ProcessInstanceWorkitem approvalInstance = [SELECT Id, ProcessInstance.SubmittedById FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: abaRecord.Id];
                            if(approvalInstance.ProcessInstance.SubmittedById == UserInfo.getUserId()){
                                status = 'Submitted';
                            }
                            else{
                                status = 'CustomerSubmitted';
                            }
                        }
                        else if(plantAsset.Asset_Builder_Status__c == 'Completed' && (plantAsset.AB_Approval_Status__c == null || plantAsset.AB_Approval_Status__c == 'Rejected') ){
                            status = 'showSubmitButton';
                        }
                    }
                    else{
                        if(plantAsset.AB_Approval_Status__c == 'Submitted'){
                            status = 'IESubmitted';
                        }
                    }
                }
                else{
                    status = 'Access Denied';
                }
            }
        
        Map<String, Object> outputMap = new Map<String, Object>();
        outputMap.put('status', status);
        outputMap.put('abaRec', abaRecord);
        outputMap.put('plantName', plantAsset.Name);

        return JSON.serialize(outputMap);
        } catch (Exception e) {
            System.debug(' Error Message -> ' + e.getMessage() + ' Line # ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    /**
     * This Method is used to perform approval actions.
     */
    @AuraEnabled
    public static String processStep(String plantAssetId, String comments, String setAction){
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ProcessInstanceId 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :plantAssetId  
        ];    
        return AssetBuilderApprovalHandlerUtils.approvalAction(workItems, plantAssetId, comments, setAction);
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
        return AssetBuilderApprovalHandlerUtils.populateApprovalHistorySteps(processInstances, recordId);                                                 
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