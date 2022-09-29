({
doinit : function(cmp, event, helper) {
     
cmp.set('v.Columns', [  {label: 'Name', fieldName: 'linkName', type: 'url', 
        typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},

 //{ label: 'Project Name', fieldName: 'Project_Name__c ', type: 'text' },
//{ label: 'Project Type', fieldName: 'Project_Type__c', type: 'text' },
//{ label: 'Project Visibility', fieldName: 'Project_visibility__c', type: 'text' },
{ label: 'Product ', fieldName: 'Product__c ', type: 'text' }, 
{ label: 'Project Status ', fieldName: 'External_Status__c', type: 'text' },
{ label: 'Installation Commencement Date ', fieldName: 'Installation_Commencement_Date__c', type: 'date',typeAttributes:{
            																day: 'numeric',  
                                                                            month: 'numeric', 
                                                                            year: 'numeric',  
                                                                            hour: '2-digit',  
                                                                            minute: '2-digit',  
                                                                            second: '2-digit',  
                                                                            hour12: true} }, 
{ label: 'Approval Status ', fieldName: 'Formula_Approval_Status__c', type: 'text' }
]);
    
var action = cmp.get("c.fetchDetails");
action.setParams({
}); 
    action.setCallback(this, function(response){
var state = response.getState();
if (state === "SUCCESS") {
        var records =response.getReturnValue();
                records.forEach(function(record){
                    record.linkName = '/'+record.Id;
                    
                }); 
      cmp.set("v.data", response.getReturnValue());
                cmp.set("v.filteredData", response.getReturnValue());
//cmp.set("v.ProjectList", records);
}
});
$A.enqueueAction(action);
     },
     searchTable : function(cmp,event,helper) {
        var allRecords = cmp.get("v.data");
        var searchFilter = event.getSource().get("v.value").toUpperCase();
        
        var tempArray = [];
        var i;

        for(i=0; i < allRecords.length; i++){
            if((allRecords[i].Name && allRecords[i].Name.toUpperCase().indexOf(searchFilter) != -1)) //||
               //(allRecords[i].Account_Plant__r.Name && allRecords[i].Account_Plant__r.Name.toUpperCase().indexOf(searchFilter) != -1 ) || 
               //(allRecords[i].External_Status__c && allRecords[i].External_Status__c.toUpperCase().indexOf(searchFilter) != -1 ) )
            {
                tempArray.push(allRecords[i]);
            }
        }
        cmp.set("v.filteredData",tempArray);
     },
  
  
    handleClose : function(component, event, helper) {
    	$A.get("e.force:closeQuickAction").fire();
    },
    
   

})