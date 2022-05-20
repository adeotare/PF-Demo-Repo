({
    init: function (cmp, event, helper) {
        cmp.set('v.columns', [
            { label: 'Project Name', fieldName: 'Name', type: 'text' },
            { label: 'Project Type', fieldName: 'project_cloud__Type__c', type: 'text' },
            { label: 'Project Status', fieldName: 'External_Status__c', type: 'text' },
            { label: 'Internal Status', fieldName: 'Internal_Status__c', type: 'text' },
            { label: 'Completion (%)', fieldName: 'project_cloud__Completed_Percent__c', type: 'text' }
        ]);
        var action = cmp.get("c.fetchData");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.data", response.getReturnValue());
                cmp.set("v.filteredData", response.getReturnValue());
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
    handleRowAction : function(component, event, helper){
        var selRows = event.getParam('selectedRows');
        console.log('selRows -> ' + JSON.stringify(selRows));
        var selectedRowsIds = [];
        for(var i=0;i<selRows.length;i++){
            selectedRowsIds.push(selRows[i].Id);  
            console.log('selectedRowsIds -> ' + selectedRowsIds);
        }
        component.set("v.selectedProjects", selectedRowsIds); 
    },
    HandleSave : function(component, event, helper) {
        try{
            let selectedProjects = component.get("v.selectedProjects");
            let programId = component.get("v.recordId");
            let projectIdListJSON = JSON.stringify(selectedProjects);
            let action = component.get('c.addProjects');
            action.setParams({"programId": programId, "projectIdListJSON": projectIdListJSON});
            action.setCallback(this, function(r){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The Projects record has been added successfully."
                });
                toastEvent.fire();
                console.log('State:'+r.getState());
            });
             $A.enqueueAction(action);
            // Close the action panel 
            var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
            dismissActionPanel.fire();
            $A.get('e.force:refreshView').fire();
        }
        catch(e){
            console.log('Exception: '+e);
        }
    },
    handleClose : function(component, event, helper) {
    	$A.get("e.force:closeQuickAction").fire();
    },
})