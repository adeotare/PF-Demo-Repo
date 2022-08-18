global class PPTBillingTriggerScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        PPTBillingTriggerBatchApex batchIns = new PPTBillingTriggerBatchApex(); 
        database.executebatch(batchIns);
    }
}