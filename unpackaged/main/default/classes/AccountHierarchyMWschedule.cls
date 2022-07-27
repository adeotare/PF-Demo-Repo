global class AccountHierarchyMWschedule implements schedulable 
{
global void execute(Schedulablecontext sc)
{
    try
    {
     AccountHierarchyMW ah = new AccountHierarchyMW(); 
     Database.executeBatch(ah);
    }
        
  catch(exception ex)
  {
      system.debug(ex.getMessage());
  }      
        
}
}