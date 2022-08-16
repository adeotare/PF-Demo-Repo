global class AutoUpliftPercentageScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        autoUpliftContractedPriceBatchProcess batchIns = new autoUpliftContractedPriceBatchProcess(); 
        database.executebatch(batchIns);
    }
}