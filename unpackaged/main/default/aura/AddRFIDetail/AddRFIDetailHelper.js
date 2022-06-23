({
    callController: function (component, event, selectedCat) {
      var action = component.get("c.processValues");
      action.setParams({ selectedCat: selectedCat });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          console.log(response.getReturnValue());
          if (response.getReturnValue() > 0) {
            var navLink = component.find("navService");
            var pageRef = {
              type: "standard__recordPage",
              attributes: {
                actionName: "view",
                objectApiName: "RAID__c",
                recordId: "a0y1F00000168NtQAI" // change record id.
              }
            };
            navLink.navigate(pageRef, true);
          }
        }
      });
      $A.enqueueAction(action);
    },
  
    callControllerCategory: function (component, event, selectedCategory) {
      var action = component.get("c.processCatValues");
      var recordId = component.get("v.recordId");
      action.setParams({ selectedCategory: selectedCategory, recordId: recordId });
      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          console.log("resultantValue" + response.getReturnValue());
          if (response.getReturnValue() != null) {
            var navLink = component.find("navService");
            var pageRef = {
              type: "standard__recordPage",
              attributes: {
                actionName: "view",
                objectApiName: "RAID__c",
                recordId: recordId // change record id.
              }
            };
            navLink.navigate(pageRef, true);
          }
        } else if (state === "ERROR") {
          console.log("Errors" + response.getError());
          $A.log("Errors", response.getError());
        }
      });
      $A.enqueueAction(action);
    },
  
    callAddRfi: function (component, event, selectedPlant, selectedCategory) {
      // console.log('helper'+selectedPlant+'-'+selectedCategory);
  
      var action = component.get("c.processRfiWithRfiDetail");
      action.setParams({ selectedCategory: selectedCategory, selectedPlant: selectedPlant });
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
  
    fetchPickListVal: function (component, fieldName, picklistOptsAttributeName) {
      var action = component.get("c.getSelectOptions");
      action.setParams({
        objObject: component.get("v.objectNeeded"),
        fld: fieldName
      });
      var opts = [];
      action.setCallback(this, function (response) {
        if (response.getState() == "SUCCESS") {
          var allValues = response.getReturnValue();
          for (var i = 0; i < allValues.length; i++) {
            opts.push({
              class: "optionClass",
              label: allValues[i],
              value: allValues[i]
            });
          }
          component.set("v." + picklistOptsAttributeName, opts);
        }
      });
      $A.enqueueAction(action);
    }
  });