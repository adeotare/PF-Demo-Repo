/**
 * This is scheduler class for Auto creating Projects recors  
 * 
 * @param  :  
 * @return :  
 */
global class SchduleBatchAutoCreateProjects implements Schedulable {

   global void execute(SchedulableContext ctx) {
      BatchApexAutocreateProjects p = new BatchApexAutocreateProjects();
      database.executeBatch(p, integer.ValueOf(Label.AutoCreateProjectsBatchSize));
   }   
}