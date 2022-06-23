({
	 
    Handleapprove : function(component, event, helper) {

        var action = component.get("c.AppRec");
        action.setParams({"RecId": component.get("v.recordId")});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS"){
                var D = response.getReturnValue();
                component.set("v.RecordId", D);
            } else {
                console.log('There was a problem : '+response.getError());
            }
        });
        $A.enqueueAction(action);
          // Close the action panel 
            var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
            dismissActionPanel.fire();
            $A.get('e.force:refreshView').fire(); 

},
      HandleReject : function(component, event, helper) {

        var action = component.get("c.RejRec");
        action.setParams({"RecId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS"){
                var B = response.getReturnValue();
                component.set("v.RecordId", B);
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