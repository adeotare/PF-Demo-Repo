({
    doInit: function (component, event, helper) {
      component.set("v.showParagraph", true);
      //  component.set("v.showParent",true);
      helper.fetchPickListVal(component, { sobjectType: "RAID__c" }, "Sub_Type__c", "rfiSubTypeOptions");
  
      //helper.getPlantAsset(component, event);
    },
  
    doShowPlantAsset: function (component, event, helper) {
      let typeElem = component.find("rfiSubType");
  
      if (typeElem.checkValidity()) {
        component.set("v.showParagraph", false);
        component.set("v.loadedSpinner", true);
        helper.getPlantAsset(component, event);
        component.set("v.showPlantAsset", true);
      } else {
        typeElem.reportValidity();
      }
    },
  
    changeAccountFilter: function (component, event, helper) {
      var delay = 150;
      var timer = component.get("v.timer");
      clearTimeout(timer);
      component.set("v.loadedSpinner", true);
      timer = setTimeout(function () {
        $A.getCallback(function () {
          helper.getPlantAsset(component, event);
        })();
        clearTimeout(timer);
        component.set("v.timer", null);
      }, delay);
      component.set("v.timer", timer);
    },
  
    //for selectAll
    selectAll: function (component, event, helper) {
      var selectedHeaderCheck = event.getSource().get("v.value");
      var getBoxPlant = component.find("boxPlant");
  
      if (selectedHeaderCheck == true) {
        if (getBoxPlant.length > 0) {
          for (var i = 0; i < getBoxPlant.length; i++) {
            component.find("boxPlant")[i].set("v.value", true);
          }
        } else {
          component.find("boxPlant").set("v.value", true);
        }
      } else {
        if (getBoxPlant.length > 0) {
          for (var i = 0; i < getBoxPlant.length; i++) {
            component.find("boxPlant")[i].set("v.value", false);
          }
        } else {
          component.find("boxPlant").set("v.value", false);
        }
      }
    },
  
    //next Button
    next: function (component, event, helper) {
      var checkvalue = [];
      checkvalue = component.find("boxPlant");
      var selectedPlant = component.get("v.selectedPlant");
      var listPlantAsset = component.get("v.listPlantAsset");
      console.log("checkvalue.length" + checkvalue.length);
  
      if (checkvalue.length > 0 && checkvalue.length != undefined) {
        for (var i = 0; i < checkvalue.length; i++) {
          if (checkvalue[i].get("v.value") == true && !selectedPlant.includes(checkvalue[i].get("v.text"))) {
            selectedPlant.push(checkvalue[i].get("v.text"));
          }
        }
      } else if (checkvalue.length == undefined) {
        var checkboxValue = checkvalue.get("v.value");
        if (checkboxValue && !selectedPlant.includes(checkvalue.get("v.text"))) {
          //console.log('hi');
          selectedPlant.push(checkvalue.get("v.text"));
        }
      }
      console.log(selectedPlant.length);
  
      //for duplicate values in previous
      if (checkvalue.length > 0) {
        for (var i = 0; i < checkvalue.length; i++) {
          if (selectedPlant.includes(checkvalue[i].get("v.text"))) {
            if (checkvalue[i].get("v.value") != true) {
              var indexDel = selectedPlant.indexOf(checkvalue[i].get("v.text"));
              selectedPlant.splice(indexDel, 1);
            }
          }
        }
      } else if (checkvalue.length == undefined) {
        var checkboxValue = checkvalue.get("v.value");
        if (checkboxValue && selectedPlant.includes(checkvalue.get("v.text"))) {
          if (checkvalue.get("v.value") != true) {
            console.log(checkvalue.get("v.text"));
            var indexDel = selectedPlant.indexOf(checkvalue.get("v.text"));
            selectedPlant.splice(indexDel, 1);
          }
        }
      }
  
      component.set("v.selectedPlant", selectedPlant);
      console.log("selectedPlant", component.get("v.selectedPlant"));
  
      if (selectedPlant.length > 0) {
        //component.set("v.showRFICat", true);
        //component.set("v.showParent",false);
        //component.set("v.showPlantAsset", false);
        helper.callAddRfi(component, event, selectedPlant, component.get("v.rfiSubType"), component.get("v.itemStatus"));
      } else {
        alert("Please select any one Account Plant");
        component.set("v.showPlantAsset", true);
      }
  
      var scrollOptions = {
        left: 0,
        top: 0,
        behavior: "smooth"
      };
      window.scrollTo(scrollOptions);
    },
  
    calledPrevious: function (component, event, helper) {
      component.set("v.showPlantAsset", true);
      component.set("v.showRFICat", false);
      var listPlantAsset = component.get("v.listPlantAsset");
      var selectedPlant = component.get("v.selectedPlant");
      console.log("listPlantAsset" + listPlantAsset[0].Id + "selectedPlant" + selectedPlant);
  
      for (var i = 0; i < listPlantAsset.length; i++) {
        if (selectedPlant.includes(listPlantAsset[i].Id)) {
          console.log(" IF $$$ " + listPlantAsset[i].Id);
          component.find("boxPlant")[i].set("v.value", true);
        }
      }
      component.set("v.callParent", false);
    },
  
    doCancelParent: function (component, event, helper) {
      component.set("v.showParent", true);
      component.set("v.showParagraph", true);
      component.set("v.selectedPlant", []);
      component.set("v.showPlantAsset", false);
      component.set("v.showParent", false);
      window.location.reload();
      $A.get("e.force:refreshView").fire();
      window.location.reload(true);
      /*  component.set('v.showParagraph',true);
          component.set('v.selectedPlant','');
       var navLink = component.find("navService");
          var pageRef = {
              type	: "standard__component",
              attributes	: {
                  componentName	: "c__AddPlantAsset"  
              },
              state	: {
                  myAttr	: "attrValue"    
              }
          }
          navLink.navigate(pageRef, true);*/
    },
    doShowParent: function (component, event, helper) {
      // alert("ho0");
      component.set("v.showParent", false);
      component.set("v.showParagraph", true);
      component.set("v.selectedPlant", []);
      component.set("v.showPlantAsset", false);
      component.set("v.showRFICat", false);
    }
  });