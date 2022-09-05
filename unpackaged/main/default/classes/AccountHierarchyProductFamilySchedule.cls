global class AccountHierarchyProductFamilySchedule implements schedulable 
{
global void execute(Schedulablecontext sc)
{
    try
    {
     AccountHierarchyproductfamily ap = new AccountHierarchyproductfamily(); 
     Database.executeBatch(ap);
    }
        
  catch(exception ex)
  {
      system.debug(ex.getMessage());
  }      
        
}
}