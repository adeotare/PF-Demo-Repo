({
	
    init : function(component, event, helper) {

        var action = component.get("c.saveRec");
        action.setParams({"RecId": component.get("v.recordId")});

        action.setCallback(this, function(response) {
            var state = response.getState();
                               
            if( state === "SUCCESS"){
                  var result=response.getReturnValue();
                 var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Submitted for Approval.",
                    "type":"Success"
                 });
                toastEvent.fire();     
               // alert('Success : ' +result);
               // console.log(success);
              var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
             dismissActionPanel.fire(); 
            }
            
                
            else if(state=== "ERROR") {
                var errors=response.getError();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Project visibility should be 'Visible to customer' on Cloud coach Project	.",
                    "type":"error",
                    "mode":"sticky"
                    });
                toastEvent.fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
                 dismissActionPanel.fire();
                //alert('ERROR: ' +  errors[0].message);
                    // console.log (error +errors) ;     
                    }
    
                
        });
        $A.enqueueAction(action);
          // Close the action panel 
           //var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
            // dismissActionPanel.fire();  
            $A.get('e.force:refreshView').fire();
		
    }
})