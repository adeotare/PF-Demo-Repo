/*
* Class that enables scheduling of the Batch job for Plant_Product_Transaction  Status updates. Only processes record which have the Purchase Status as set to Contracted
*
* @see Schedulable
*/
global class ActiveMegawattQuantitySchedule implements schedulable 
{
global void execute(Schedulablecontext sc)
{
    try
    {
     ActiveMegawattQuantityBatchapex am = new ActiveMegawattQuantityBatchapex(); 
     Database.executeBatch(am);
    }
        
  catch(exception ex)
  {
      system.debug(ex.getMessage());
  }      
        
}
}