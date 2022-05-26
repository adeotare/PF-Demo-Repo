public with sharing class AssetBuilderApprovalHandlerUtils {

    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_STARTED = 'Started';
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_RECALLED = 'Recalled';
    public static final String STATUS_REMOVED = 'Removed';
    
     /**
     * This Method is used for submitting Approval request
     */
    @AuraEnabled
    public static String SubmitForApproval(String plantAssetId, String comments, String approvalProcessName, Boolean setSkipEntryCriteria){    
        String status = 'None';  
        try{
            Approval.ProcessSubmitRequest approvalRequestInstance = new Approval.ProcessSubmitRequest();
            approvalRequestInstance.setComments(comments);
            approvalRequestInstance.setObjectId(plantAssetId);
            approvalRequestInstance.setProcessDefinitionNameOrId(approvalProcessName);
            approvalRequestInstance.setSkipEntryCriteria(setSkipEntryCriteria);
            Approval.ProcessResult result = Approval.process(approvalRequestInstance);  
            if(result.isSuccess()){
                status = 'Submitted';
            }
            else{
                status = 'Error - '+result.getErrors() ;
            }
            return status;
        } catch (Exception e){
            System.debug(' Error Message -> ' + e.getMessage() + ' Line # ' + e.getLineNumber());
            String errorMessage;
            if(e.getMessage().CONTAINS('NO_APPLICABLE_PROCESS')){
                errorMessage = System.label.AB_AP_NoApplicableProcessFound;
            } else {
                errorMessage = e.getMessage();
            }
            if(!Test.isRunningTest()){
                throw new AuraHandledException(errorMessage);
            }
            else{
                return errorMessage;
            }
        }
    } 

    /**
     * This Method is used for approve/reject/recall the approval request
     */
    public static String approvalAction(List<ProcessInstanceWorkitem> workItems, String plantAssetId, String comments, String setAction ){
        String status ='None';
        try {
            Approval.ProcessWorkitemRequest approvalActionInstance = new Approval.ProcessWorkitemRequest();
            approvalActionInstance.setComments(comments);
            approvalActionInstance.setAction(setAction);
            if(workItems.size() > 0){
                approvalActionInstance.setWorkitemId(workItems[0].Id);
                Approval.ProcessResult result =  Approval.process(approvalActionInstance);
                if(result.isSuccess()){
                    status = setAction;
                    if(status == 'Approve'){
                        Id paId =  [SELECT Id, Account_Plant__c FROM Asset_Builder_Approval__c WHERE Id =: plantAssetId].Account_Plant__c;
                        status = Utils2.callRFIGeneration(paId);
                    }
                } 
                else{
                    status = 'Error - '+result.getErrors() ;
                }
            }
            return status;
        } catch (Exception e) {
            System.debug(' Error Message -> ' + e.getMessage() + ' Line # ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }   
    }

    /**
     * This Method is used for approve/reject/recall the approval request
     */
    public static String approvalActionForSat(List<ProcessInstanceWorkitem> workItems, String satId, String comments, String setAction ){
        String status ='None';
        try {
            Approval.ProcessWorkitemRequest approvalActionInstance = new Approval.ProcessWorkitemRequest();
            approvalActionInstance.setComments(comments);
            approvalActionInstance.setAction(setAction);
            if(workItems.size() > 0){
                approvalActionInstance.setWorkitemId(workItems[0].Id);
                Approval.ProcessResult result =  Approval.process(approvalActionInstance);
                if(result.isSuccess()){
                    status = setAction;
                    if(status == 'Approved'){
                        status = 'Approved';
                    }
                } 
                else{
                    status = 'Error - '+result.getErrors() ;
                }
            }
            system.debug('status===>'+status);
            return status;
        } catch (Exception e) {
            System.debug(' Error Message -> ' + e.getMessage() + ' Line # ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }   
    }

    /**
     * This Method is used to display Approval history in Approvals tab.
    */ 
    public static AssetBuilderApprovalHandler.ApprovalHistory populateApprovalHistorySteps(List<ProcessInstance> processInstances, String recordId){
        List<AssetBuilderApprovalHandler.ApprovalHistoryStep> steps = new List<AssetBuilderApprovalHandler.ApprovalHistoryStep>();
        //Iterating through processInstance records to build the approval history steps
        AssetBuilderApprovalHandler.ApprovalHistory approvalHistoryToReturn = new AssetBuilderApprovalHandler.ApprovalHistory(steps);
        for(ProcessInstance pr :  processInstances){
            for(ProcessInstanceHistory step : pr.StepsAndWorkitems){
                steps.add(new AssetBuilderApprovalHandler.ApprovalHistoryStep( step.ProcessNode.Name == null ? pr.ProcessDefinition.Name  : step.ProcessNode.Name,step.Id, step.CreatedDate,  step.StepStatus, step.Actor.Name,step.Actor.Id, step.Comments));
            }
        } 
        return approvalHistoryToReturn;
    }
    
    /**
     * This Method is used to display Approval history in Approvals tab.
    */ 
    public static SATApprovalHandler.ApprovalHistory populateApprovalHistoryStepsSAT(List<ProcessInstance> processInstances, String recordId){
        List<SATApprovalHandler.ApprovalHistoryStep> steps = new List<SATApprovalHandler.ApprovalHistoryStep>();
        //Iterating through processInstance records to build the approval history steps
        SATApprovalHandler.ApprovalHistory approvalHistoryToReturn = new SATApprovalHandler.ApprovalHistory(steps);
        for(ProcessInstance pr :  processInstances){
            for(ProcessInstanceHistory step : pr.StepsAndWorkitems){
                steps.add(new SATApprovalHandler.ApprovalHistoryStep( step.ProcessNode.Name == null ? pr.ProcessDefinition.Name  : step.ProcessNode.Name,step.Id, step.CreatedDate,  step.StepStatus, step.Actor.Name,step.Actor.Id, step.Comments));
            }
        } 
        return approvalHistoryToReturn;
    }

    /**
     * This Method is used for approve/reject/recall the approval request
     */
    public static String reassignApprovalForSat(List<ProcessInstanceWorkitem> workItems, String userId, String setAction ){
        String status ='None';
        try {
            if(workItems.size() > 0){
                workItems.get(0).ActorId  = userId;
                update workItems;
                status = 'success';    
            }
            return status;
        } catch (Exception e) {
            System.debug(' Error Message -> ' + e.getMessage() + ' Line # ' + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }   
    }
}