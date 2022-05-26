/*
 - 
 */
public with sharing class LookupWithDynamicFieldFilterCont {
    /* This method will return records based on search string */
    @AuraEnabled(cacheable = true)  
    public static List<Sobject> getLookupSearchRecords(String searchString, String selectedSObject, Integer recordLimit,
      List<String> fieldsToShowList, String filterFieldAPIName) { 
      if(searchString != null && searchString != '') { 
        String query;
        String selectFields = '';
        String whereCondition;
        String limitString = ' LIMIT '+recordLimit;
        String fromQuery = ' FROM '+selectedSObject;
        for (String str : fieldsToShowList) {
          selectFields += str + ',';  
        }
        if (String.isNotBlank(selectFields))  {
          selectFields = selectFields.removeEnd(',');
        }
        whereCondition = ' WHERE '+ ((String.isNotBlank(filterFieldAPIName)) ? filterFieldAPIName : 'Name') +' like \'%'+ searchString +'%\' '; 
        query = 'SELECT '+selectFields + fromQuery + whereCondition + limitString;
        return Database.query(query);   
      }
      return new List<Sobject>();
    } 
  }