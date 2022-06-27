({
doinit : function(cmp, event, helper) {
     
cmp.set('v.Columns', [  {label: 'name', fieldName: 'linkName', type: 'url', 
        typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},

 //{ label: 'Project Name', fieldName: 'Project_Name__c ', type: 'text' },
{ label: 'Project Type', fieldName: 'Project_Type__c', type: 'text' },
//{ label: 'Project Visibility', fieldName: 'Project_visibility__c', type: 'text' },
{ label: 'Product ', fieldName: 'Product__c ', type: 'text' }

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
cmp.set("v.ProjectList", records);
}
});
$A.enqueueAction(action);
    
   
}
})