({
doinit : function(cmp, event, helper) {
cmp.set('v.Columns', [
 { label: ' Name', fieldName: 'Name', type: 'text' } ,
{ label: 'Project Name', fieldName: 'Project_Name__c ', type: 'text' },
{ label: 'Project Type', fieldName: 'Project_Type__c', type: 'text' },
{ label: 'Project Visibility', fieldName: 'Project_visibility__c', type: 'text' },
{ label: 'Product ', fieldName: 'Product__c ', type: 'text' }

]);
var action = cmp.get("c.fetchDetails");
action.setParams({
}); 
    action.setCallback(this, function(response){
var state = response.getState();
if (state === "SUCCESS") {
cmp.set("v.ProjectList", response.getReturnValue());
}
});
$A.enqueueAction(action);
}
})