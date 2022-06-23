({
    getPlantAsset: function (component, event) {
      var action = component.get("c.getListOfPlantAsset");
      //console.log(component.get("v.rfiSubType"));
      action.setParams({ accountFilter: component.get("v.accountFilter"), subType: component.get("v.rfiSubType") });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var listPA = response.getReturnValue();
          if (listPA.length > 0) {
            component.set("v.loadedSpinner", false);
            component.set("v.listPlantAsset", response.getReturnValue());
            component.set("v.showError", false);
          } else {
            component.set("v.listPlantAsset", []);
            component.set("v.loadedSpinner", false);
            component.set("v.showError", true);
          }
        } else if (state === "ERROR") {
          var error = response.getError(error);
          component.find("notify").showError(error);
        }
      });
      $A.enqueueAction(action);
    },
  
    callAddRfi: function (component, event, selectedPlant, subType, status) {
      console.log("helper" + selectedPlant + "-" + subType);
  
      var action = component.get("c.processRfiWithRfiDetail");
      action.setParams({ subType: subType, selectedPlant: selectedPlant, status: status });
      action.setCallback(this, function (response) {
        var state = response.getState();
        console.log("state" + state);
        if (state === "SUCCESS") {
          console.log(response.getReturnValue());
          if (response.getReturnValue() != null) {
            var navLink = component.find("navService");
            var pageRef = {
              type: "standard__objectPage",
              attributes: {
                objectApiName: "RAID__c",
                actionName: "list"
              },
              state: {
                filterName: "Recent"
              }
            };
            navLink.navigate(pageRef, true);
          }
          component.set("v.showParent", true);
        } else if (state === "ERROR") {
          let errors = response.getError();
          let message = "Unknown error";
          if (errors && Array.isArray(errors) && errors.length > 0) {
            message = errors[0].message;
          }
          console.log(errors);
          component.find("notify").showInfo(message);
        }
      });
      $A.enqueueAction(action);
    },
  
    fetchPickListVal: function (component, objType, fieldName, picklistOptsAttributeName) {
      var hasCustomPermissionAccesss = false;
      if(fieldName === 'Sub_Type__c'){
        var action = component.get("c.getCustomPermissionAccess");
        action.setCallback(this, function (response) {
          if (response.getState() == "SUCCESS") {
            hasCustomPermissionAccesss = response.getReturnValue();
          }
        });
        $A.enqueueAction(action);
      }
      var action = component.get("c.getSelectOptions");
      action.setParams({
        objObject: objType,
        fld: fieldName
      });
      var opts = [];
      action.setCallback(this, function (response) {
        if (response.getState() == "SUCCESS") {
          var allValues = response.getReturnValue();
          for (var i = 0; i < allValues.length; i++) {
            if(allValues[i] === 'Customer'){
              if(hasCustomPermissionAccesss && fieldName === 'Sub_Type__c'){
                opts.push({
                  class: "optionClass",
                  label: allValues[i],
                  value: allValues[i]
                });
              }
            }else{
              opts.push({
                class: "optionClass",
                label: allValues[i],
                value: allValues[i]
              });
            }
          }
          component.set("v." + picklistOptsAttributeName, opts);
        }
      });
      $A.enqueueAction(action);
    }
  });