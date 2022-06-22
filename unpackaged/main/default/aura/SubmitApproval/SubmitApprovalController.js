({
	
    init : function(component, event, helper) {

        var action = component.get("c.saveRec");
        action.setParams({"RecId": component.get("v.recordId")});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS"){
               
            } else {
                console.log('There was a problem : '+response.getError());
            }
        });
        $A.enqueueAction(action);
          // Close the action panel 
            var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
            dismissActionPanel.fire();
            $A.get('e.force:refreshView').fire(); 
		
    }
})