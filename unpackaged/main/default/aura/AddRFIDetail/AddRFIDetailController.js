({
    loadData: function (component, event, helper) {
      //using parent value
      component.set("v.loadedSpinner", true);
      helper.fetchPickListVal(component, "Category_Type__c", "categoryTypeOptions");
  
      //check data
      var proceed;
      var action = component.get("c.getCheckRfi");
      var recordId = component.get("v.recordId");
      // alert('recordId'+recordId);
      action.setParams({
        recordId: recordId
      });
      action.setCallback(this, function (response) {
        //store state of response
        var state = response.getState();
        if (state === "SUCCESS") {
          proceed = response.getReturnValue();
          if (proceed > 0) {
            component.set("v.showCat", true);
  
            //call Missing category
            var action = component.get("c.getCategoriesForRfi");
            action.setParams({
              recordId: recordId
            });
            action.setCallback(this, function (response) {
              //store state of response
              var state = response.getState();
              if (state === "SUCCESS") {
                component.set("v.loadedSpinner", false);
                component.set("v.showError", false);
  
                let categories = response.getReturnValue().map((i) => Object.assign({}, i));
                component.set("v.wrapperMissingCat", categories);
                console.log(response.getReturnValue());
              }
            });
            $A.enqueueAction(action);
          } else {
            component.set("v.loadedSpinner", false);
            component.set("v.showError", true);
            component.set("v.errorMessages", "This RFI is Closed, hence you cannot add new categories.");
          }
        }
      });
      $A.enqueueAction(action);
  
      var scrollOptions = {
        left: 0,
        top: 0,
        behavior: "smooth"
      };
      window.scrollTo(scrollOptions);
    },
  
    handleFocus: function (cmp, event) {
      console.log("Input Seven has recieved the focus.");
    },
  
    handleBlur: function (cmp, event) {
      console.log("Input Seven has released the focus.");
    },
  
    /*selectAll: function (component, event, helper) {
      var selectedHeaderCheck = event.getSource().get("v.value");
      var getAllId = component.find("boxPack");
  
      if (selectedHeaderCheck == true) {
        if (getAllId.length > 0) {
          for (var i = 0; i < getAllId.length; i++) {
            component.find("boxPack")[i].set("v.value", true);
          }
        } else {
          component.find("boxPack").set("v.value", true);
        }
      } else {
        if (getAllId.length > 0) {
          for (var i = 0; i < getAllId.length; i++) {
            component.find("boxPack")[i].set("v.value", false);
          }
        } else {
          component.find("boxPack").set("v.value", false);
        }
      }
      component.set("v.requiredDes", true);
    },*/
  
    searchCategories: function (component, event, helper) {
      var search = component.find("category-search").get("v.value").toUpperCase();
      var selected = component.find("show-selected").get("v.checked");
      var categories = component.get("v.wrapperMissingCat");
  
      let filteredCategories = [];
      for (let i = 0; i < component.get("v.wrapperMissingCat").length; i++) {
        let c = component.get("v.wrapperMissingCat")[i];
        console.log(c.lstRfiCat.Name);
        console.log(c.lstRfiCat.Name.toUpperCase().indexOf(search) == -1);
        c.filtered = search != "" && c.lstRfiCat.Name.toUpperCase().indexOf(search) == -1;
        if (!selected && c.selected) c.filtered = true;
        filteredCategories.push(c);
      }
      component.set("v.wrapperMissingCat", filteredCategories);
    },
  
    selectAllMissing: function (component, event, helper) {
      var selectedHeaderCheck = event.getSource().get("v.value");
      var getAllMissingId = component.find("boxPackMissing");
  
      if (selectedHeaderCheck == true) {
        if (getAllMissingId.length > 0) {
          for (var i = 0; i < getAllMissingId.length; i++) {
            component.find("boxPackMissing")[i].set("v.value", true);
          }
        } else {
          component.find("boxPackMissing").set("v.value", true);
        }
      } else {
        if (getAllMissingId.length > 0) {
          for (var i = 0; i < getAllMissingId.length; i++) {
            component.find("boxPackMissing")[i].set("v.value", false);
          }
        } else {
          component.find("boxPackMissing").set("v.value", false);
        }
      }
      //component.set("v.requiredDes", true);
    },
  
    /*previous: function (component, event, helper) {
      //for Validation
      var checkvalue = [];
      checkvalue = component.find("boxPack");
      var selectedCategory = new Map();
      selectedCategory = component.get("v.selectedCategory");
      var wrapperIncorrectCat = component.get("v.wrapperIncorrectCat");
      var errorVal = 0;
      var errValString = [];
      var errorDes = 0;
      var errorDesString = [];
      var errorPick = 0;
      var errorPickString = [];
      console.log("wrapperIncorrectCat" + wrapperIncorrectCat.length);
      if (checkvalue.length > 0) {
        for (var i = 0; i < checkvalue.length; i++) {
          if (checkvalue[i].get("v.value") == true) {
            // console.log(JSON.stringify(wrapperIncorrectCat[i].selOption));
            if (wrapperIncorrectCat[i].selOption == "") {
              errorPick++;
              errorPickString.push(wrapperIncorrectCat[i].lstRfiCat.Name);
            }
            if (wrapperIncorrectCat[i].description == "") {
              errorDes++;
              errorDesString.push(wrapperIncorrectCat[i].lstRfiCat.Name);
            }
            if (wrapperIncorrectCat[i].selOption == "Yes" && wrapperIncorrectCat[i].onsiteDescription == "") {
              errorVal++;
              errValString.push(wrapperIncorrectCat[i].lstRfiCat.Name);
            }
          }
          continue;
        }
      } else {
        var checkvalue = checkvalue.get("v.value");
        if (checkvalue) {
          if (wrapperIncorrectCat[i].selOption == "") {
            errorPick++;
            errorPickString.push(wrapperIncorrectCat[i].lstRfiCat.Name);
          }
          if (wrapperIncorrectCat[i].description == "") {
            errorDes++;
            errorDesString.push(wrapperIncorrectCat[i].lstRfiCat.Name);
          } else if (wrapperIncorrectCat[i].selOption == "Yes" && wrapperIncorrectCat[i].onsiteDescription == "") {
            errorVal++;
            errValString.push(wrapperIncorrectCat[i].lstRfiCat.Name);
          }
        }
      }
      console.log("errorPick" + errorPick);
      console.log("errorDes" + errorDes);
      console.log("errorVal" + errorVal);
  
      if (errorPick > 0 || errorDes > 0 || errorVal > 0) {
        var content = "Please fill the missing information listed below for selected RFI Categories:\n";
        if (errorDesString.length > 0 && errorPickString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - RFI Item Description & Onsite Remediation Required,\n";
              // console.log(content);
            }
          }
          for (var i = 0; i < errorPickString.length; i++) {
            if (!content.includes(errorPickString[i])) {
              content += "'" + errorPickString[i] + "' - RFI Item Description & Onsite Remediation Required,\n";
              // console.log(content);
            }
          }
        }
        if (errorDesString.length > 0 && errValString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - RFI Item Description,\n";
              // console.log(content);
            }
          }
          for (var i = 0; i < errValString.length; i++) {
            if (!content.includes(errValString[i])) {
              content += "'" + errValString[i] + "' - Onsite Remediation Description,\n";
              //  console.log(content);
            }
          }
        }
        if (errorDesString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - RFI Item Description,\n";
              // console.log(content);
            }
          }
        }
        if (errorPickString.length > 0) {
          for (var i = 0; i < errorPickString.length; i++) {
            if (!content.includes(errorPickString[i])) {
              content += "'" + errorPickString[i] + "' - Onsite Remediation Required,\n";
              //   console.log(content);
            }
          }
        }
        if (errValString.length > 0) {
          for (var i = 0; i < errValString.length; i++) {
            if (!content.includes(errValString[i])) {
              content += "'" + errValString[i] + "' - Remediation Description,\n";
              // console.log(content);
            }
          }
        }
  
        alert(content);
        console.log(content);
      } else if (errorVal == 0 && errorDes == 0 && errorPick == 0) {
        component.set("v.showCat", true);
  
        //to store second set of list
        var checkvalue = [];
        checkvalue = component.find("boxPack");
        var selectedCategory = component.get("v.selectedCategory");
        var wrapperIncorrectCat = component.get("v.wrapperIncorrectCat");
        var valuesCheck = JSON.stringify(selectedCategory);
  
        console.log("selectedCategory" + selectedCategory);
  
        if (checkvalue.length > 0) {
          for (var i = 0; i < checkvalue.length; i++) {
            if (checkvalue[i].get("v.value") == true) {
              selectedCategory[checkvalue[i].get("v.text")] = JSON.stringify(wrapperIncorrectCat[i]);
            }
          }
        } else {
          var checkboxValue = checkvalue.get("v.value");
          if (checkboxValue) {
            selectedCategory[checkvalue.get("v.text")] = JSON.stringify(wrapperIncorrectCat[0]);
          }
        }
        component.set("v.selectedCategory", selectedCategory);
  
        //for duplicate values in previous
        var catValue1 = [];
        catValue1 = Object.keys(selectedCategory);
        console.log("fruits - " + catValue1.length);
  
        if (checkvalue.length > 0) {
          for (var i = 0; i < checkvalue.length; i++) {
            if (catValue1.includes(checkvalue[i].get("v.text"))) {
              if (checkvalue[i].get("v.value") != true) {
                // var chkV = checkvalue[i].get("v.text");
                delete selectedCategory[checkvalue[i].get("v.text")];
              }
            }
          }
        } else {
          var checkboxValue = checkvalue.get("v.value");
          if (catValue1.includes(checkvalue[i].get("v.text"))) {
            if (checkvalue[i].get("v.value") != true) {
              delete selectedCategory[checkvalue[i].get("v.text")];
            }
          }
        }
  
        // show missing category that does not contain selected item of incorrect
        var wrapperMissingCatSample = component.get("v.wrapperMissingCat");
        var valuesCheck = JSON.stringify(selectedCategory);
  
        for (var iterator = 0; iterator < Object.keys(wrapperMissingCatSample).length; iterator++) {
          var obj = new Object();
          obj = wrapperMissingCatSample[iterator];
          if (valuesCheck.includes(obj.lstRfiCat.Name)) {
            for (var iteratorWrapper = 0; iteratorWrapper < Object.keys(selectedCategory).length; iteratorWrapper++) {
              var key = Array.from(Object.keys(selectedCategory))[iteratorWrapper];
              var obj1 = new Object();
              obj1 = JSON.parse(selectedCategory[key]);
              if (
                obj1.lstRfiCat.Name === obj.lstRfiCat.Name &&
                obj1.lstRfiCat.RecordType.Name != obj.lstRfiCat.RecordType.Name
              ) {
                console.log(wrapperMissingCatSample[iterator]);
                delete wrapperMissingCatSample[iterator];
              }
            }
          }
        }
  
        var myArrayNew = wrapperMissingCatSample.filter(function (el) {
          return el != null && el != "";
        });
  
        console.log("removed-->" + JSON.stringify(myArrayNew));
        component.set("v.wrapperMissingCat", myArrayNew);
  
        // to check the check box in missing category
  
        var selectedCategory = component.get("v.selectedCategory");
        var selectedHeaderCheck = event.getSource().get("v.value");
        var wrapperMissingCat = component.get("v.wrapperMissingCat");
        var valuesCheck = JSON.stringify(selectedCategory);
  
        for (var i = 0; i < wrapperMissingCat.length; i++) {
          //console.log('Tets $$$ '+wrapperMissingCat[i].lstRfiCat.Id);
          if (valuesCheck.includes(wrapperMissingCat[i].lstRfiCat.Id)) {
            console.log(" IF $$$ " + wrapperMissingCat[i].lstRfiCat.Id);
            component.find("boxPackMissing")[i].set("v.value", true);
          }
        }
        console.log("selectedCategoryAfterPrevious" + JSON.stringify(selectedCategory));
      }
      //scroll the page up
      var scrollOptions = {
        left: 0,
        top: 0,
        behavior: "smooth"
      };
      window.scrollTo(scrollOptions);
    },*/
  
    /*previousParent: function (component, event, helper) {
      component.set("v.showNotify", true);
    },
  
    next: function (component, event, helper) {
      var wrapperIncorrectCat = component.get("v.wrapperIncorrectCat");
      var parentOn = component.get("v.selectedPlant");
      console.log("parentOn" + parent.length);
      console.log(JSON.stringify(component.get("v.wrapperMissingCat")));
  
      //for Validation
      var checkvalue = [];
      checkvalue = component.find("boxPackMissing");
      var selectedCategory = new Map();
      selectedCategory = component.get("v.selectedCategory");
      var wrapperMissingCat = component.get("v.wrapperMissingCat");
      var errorVal = 0;
      var errValString = [];
      var errorDes = 0;
      var errorDesString = [];
      var errorPick = 0;
      var errorPickString = [];
      // console.log('checkvalue-'+checkvalue.length);
      console.log("wrapperMissingCat" + wrapperMissingCat.length);
      if (checkvalue.length > 0) {
        for (var i = 0; i < checkvalue.length; i++) {
          if (checkvalue[i].get("v.value") == true) {
            // console.log(JSON.stringify(wrapperMissingCat[i].selOption));
            if (wrapperMissingCat[i].selOption == "") {
              errorPick++;
              errorPickString.push(wrapperMissingCat[i].lstRfiCat.Name);
            }
            if (wrapperMissingCat[i].description == "") {
              errorDes++;
              errorDesString.push(wrapperMissingCat[i].lstRfiCat.Name);
            }
            if (wrapperMissingCat[i].selOption == "Yes" && wrapperMissingCat[i].onsiteDescription == "") {
              errorVal++;
              errValString.push(wrapperMissingCat[i].lstRfiCat.Name);
            }
          }
          continue;
        }
      } else {
        var checkvalue = checkvalue.get("v.value");
        if (checkvalue) {
          if (wrapperMissingCat[i].selOption == "") {
            errorPick++;
            var constantPick = wrapperMissingCat[i].lstRfiCat.Name;
            errorPickString.push(wrapperMissingCat[i].lstRfiCat.Name);
          }
          if (wrapperMissingCat[i].description == "") {
            errorDes++;
            errorDesString.push(wrapperMissingCat[i].lstRfiCat.Name);
          } else if (wrapperMissingCat[i].selOption == "Yes" && wrapperMissingCat[i].onsiteDescription == "") {
            errorVal++;
            errValString.push(wrapperMissingCat[i].lstRfiCat.Name);
          }
        }
      }
      console.log("errorVal" + errValString.length);
      console.log("errorVal" + errValString[0]);
      console.log("errorDes" + errorDesString.length);
      console.log("errorDes" + errorDesString[0]);
      console.log("errorPickString" + errorPickString.length);
      console.log("errorPickString" + errorPickString[0]);
      if (errorPick > 0 || errorDes > 0 || errorVal > 0) {
        var content = "Please fill the missing information listed below for selected RFI Categories:\n";
        if (errorDesString.length > 0 && errorPickString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - RFI Item Description & Onsite Remediation Required,\n";
              console.log(content);
            }
          }
          for (var i = 0; i < errorPickString.length; i++) {
            if (!content.includes(errorPickString[i])) {
              content += "'" + errorPickString[i] + "' - RFI Item Description & Onsite Remediation Required,\n";
              console.log(content);
            }
          }
        }
        if (errorDesString.length > 0 && errValString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - RFI Item Description,\n";
              console.log(content);
            }
          }
          for (var i = 0; i < errValString.length; i++) {
            if (!content.includes(errValString[i])) {
              content += "'" + errValString[i] + "' - Onsite Remediation Description,\n";
              console.log(content);
            }
          }
        }
        if (errorDesString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - RFI Item Description,\n";
              console.log(content);
            }
          }
        }
        if (errorPickString.length > 0) {
          for (var i = 0; i < errorPickString.length; i++) {
            if (!content.includes(errorPickString[i])) {
              content += "'" + errorPickString[i] + "' - Onsite Remediation Required,\n";
              console.log(content);
            }
          }
        }
        if (errValString.length > 0) {
          for (var i = 0; i < errValString.length; i++) {
            if (!content.includes(errValString[i])) {
              content += "'" + errValString[i] + "' - Onsite Remediation Description,\n";
              console.log(content);
            }
          }
        }
  
        alert(content);
      } else if (errorVal == 0 && errorDes == 0 && errorPick == 0) {
        var wrapperMissingCat = component.get("v.wrapperMissingCat");
        if (wrapperMissingCat.length > 0) {
          //to add the selected category in missing category
          var checkvalue = [];
          checkvalue = component.find("boxPackMissing");
          var selectedCategory = new Map();
          selectedCategory = component.get("v.selectedCategory");
          var wrapperMissingCat = component.get("v.wrapperMissingCat");
          var errorVal = 0;
          // console.log('checkvalue-'+checkvalue.length);
          console.log("wrapperMissingCat" + wrapperMissingCat.length);
          if (checkvalue.length > 0) {
            for (var i = 0; i < checkvalue.length; i++) {
              if (checkvalue[i].get("v.value") == true) {
                selectedCategory[checkvalue[i].get("v.text")] = JSON.stringify(wrapperMissingCat[i]);
              }
            }
          } else {
            var checkvalue = checkvalue.get("v.value");
            if (checkvalue) {
              selectedCategory[checkvalue.get("v.text")] = JSON.stringify(wrapperMissingCat[0]);
            }
          }
          component.set("v.selectedCategory", selectedCategory);
        }
  
        var catValue1 = [];
        catValue1 = Object.keys(selectedCategory);
        console.log("fruits - " + catValue1);
  
        //for duplicate values in previous
        if (checkvalue.length > 0) {
          for (var i = 0; i < checkvalue.length; i++) {
            if (catValue1.includes(checkvalue[i].get("v.text"))) {
              if (checkvalue[i].get("v.value") != true) {
                // var chkV = checkvalue[i].get("v.text");
                delete selectedCategory[checkvalue[i].get("v.text")];
              }
            }
          }
        } else {
          var checkboxValue = checkvalue.get("v.value");
          if (catValue1.includes(checkvalue[i].get("v.text"))) {
            if (checkvalue[i].get("v.value") != true) {
              delete selectedCategory[checkvalue[i].get("v.text")];
            }
          }
        }
  
        console.log("selectedCategory--->Next " + JSON.stringify(selectedCategory));
  
        // show incorrect category that does not contain selected item of missing
        var wrapperIncorrectCatSample = component.get("v.wrapperIncorrectCat");
        var valuesCheck = JSON.stringify(selectedCategory);
  
        for (var iterator = 0; iterator < Object.keys(wrapperIncorrectCatSample).length; iterator++) {
          var obj = new Object();
          obj = wrapperIncorrectCatSample[iterator];
          if (valuesCheck.includes(obj.lstRfiCat.Name)) {
            for (var iteratorWrapper = 0; iteratorWrapper < Object.keys(selectedCategory).length; iteratorWrapper++) {
              var key = Array.from(Object.keys(selectedCategory))[iteratorWrapper];
              var obj1 = new Object();
              obj1 = JSON.parse(selectedCategory[key]);
              if (
                obj1.lstRfiCat.Name === obj.lstRfiCat.Name &&
                obj1.lstRfiCat.RecordType.Name != obj.lstRfiCat.RecordType.Name
              ) {
                delete wrapperIncorrectCatSample[iterator];
              }
            }
          }
        }
        console.log("removed:---" + JSON.stringify(wrapperIncorrectCatSample));
  
        var myArrayNew = wrapperIncorrectCatSample.filter(function (el) {
          return el != null && el != "";
        });
        console.log("myArrayNew type " + myArrayNew instanceof Object);
        console.log("removed-->" + JSON.stringify(myArrayNew));
        component.set("v.wrapperIncorrectCat", myArrayNew);
  
        //to check the check box in incorrect category
  
        component.set("v.showCat", true);
  
        var wrapperIncorrectCat = component.get("v.wrapperIncorrectCat");
        console.log("wrapperIncorrectCat:--" + JSON.stringify(wrapperIncorrectCat));
        for (var i = 0; i < wrapperIncorrectCat.length; i++) {
          if (valuesCheck.includes(wrapperIncorrectCat[i].lstRfiCat.Id)) {
            console.log(" IF $$$ " + wrapperIncorrectCat[i].lstRfiCat.Id);
            component.find("boxPack")[i].set("v.value", true);
          }
        }
      }
  
      // to show the conformation box
      var parentOn = component.get("v.selectedPlant");
      console.log("parentOn" + parent.length);
      if (parentOn.length > 0) {
        component.set("v.parentOn", true);
      }
      //scroll the page up
      var scrollOptions = {
        left: 0,
        top: 0,
        behavior: "smooth"
      };
      window.scrollTo(scrollOptions);
    },
  
    save: function (component, event, helper) {
      var checkvalue = [];
      checkvalue = component.find("boxPack");
      var selectedCat = component.get("v.selectedCat");
      var wrapperList = component.get("v.wrapperList");
  
      if (checkvalue.length > 0) {
        for (var i = 0; i < checkvalue.length; i++) {
          if (checkvalue[i].get("v.value") == true) {
            selectedCat[checkvalue[i].get("v.text")] = JSON.stringify(wrapperList[i]);
          }
        }
      } else {
        var checkboxValue = checkvalue.get("v.value");
        if (checkboxValue) {
          selectedCat[checkvalue.get("v.text")] = JSON.stringify(wrapperList[0]);
        }
      }
      if (typeof selectedCat != "undefined") {
        helper.callController(component, event, selectedCat);
      }
    },*/
  
    saveNew: function (component, event, helper) {
      //for Validation
      //var checkvalue = [];
      //checkvalue = component.find("boxPackMissing");
      var selectedCategory = new Map();
      selectedCategory = component.get("v.selectedCategory");
      var wrapperMissingCat = component.get("v.wrapperMissingCat");
      var errorVal = 0;
      var errValString = [];
      var errorDes = 0;
      var errorDesString = [];
      var errorPick = 0;
      var errorPickString = [];
      //console.log("wrapperMissingCat" + wrapperMissingCat.length);
      //if (checkvalue.length > 0) {
      for (var i = 0; i < wrapperMissingCat.length; i++) {
        if (wrapperMissingCat[i].selected) {
          // console.log(JSON.stringify(wrapperMissingCat[i].selOption));
          if (wrapperMissingCat[i].description == "") {
            errorDes++;
            errorDesString.push(wrapperMissingCat[i].lstRfiCat.Name);
          }
        }
      }
  
      console.log("errorVal" + errValString.length);
      console.log("errorVal" + errValString[0]);
      console.log("errorDes" + errorDesString.length);
      console.log("errorDes" + errorDesString[0]);
      console.log("hi");
      console.log("errorPickString" + errorPickString.length);
      console.log("errorPickString" + errorPickString[0]);
      if (errorPick > 0 || errorDes > 0 || errorVal > 0) {
        var content = "Please fill the missing information listed below for selected RFI Categories:\n";
        if (errorDesString.length > 0 && errorPickString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - RFI Item Description & Onsite Remediation Required,\n";
              console.log(content);
            }
          }
          for (var i = 0; i < errorPickString.length; i++) {
            if (!content.includes(errorPickString[i])) {
              content += "'" + errorPickString[i] + "' - RFI Item Description & Onsite Remediation Required,\n";
              console.log(content);
            }
          }
        }
        if (errorDesString.length > 0 && errValString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - Onsite Remediation Description,\n";
              console.log(content);
            }
          }
          for (var i = 0; i < errValString.length; i++) {
            if (!content.includes(errValString[i])) {
              content += "'" + errValString[i] + "' - Onsite Remediation Description,\n";
              console.log(content);
            }
          }
        }
        if (errorDesString.length > 0) {
          for (var i = 0; i < errorDesString.length; i++) {
            if (!content.includes(errorDesString[i])) {
              content += "'" + errorDesString[i] + "' - RFI Item Description,\n";
              console.log(content);
            }
          }
        }
        if (errorPickString.length > 0) {
          for (var i = 0; i < errorPickString.length; i++) {
            if (!content.includes(errorPickString[i])) {
              content += "'" + errorPickString[i] + "' - Onsite Remediation,\n";
              console.log(content);
            }
          }
        }
        if (errValString.length > 0) {
          for (var i = 0; i < errValString.length; i++) {
            if (!content.includes(errValString[i])) {
              content += "'" + errValString[i] + "'- Onsite Remediation Description, \n";
              console.log(content);
            }
          }
        }
  
        alert(content);
      } else if (errorVal == 0 && errorDes == 0 && errorPick == 0) {
        //var selectedCategory = component.get("v.selectedCategory");
        var wrapperMissingCat = component.get("v.wrapperMissingCat");
        var itemStatus = component.get("v.itemStatus");
  
        selectedCategory = new Map();
        for (var i = 0; i < wrapperMissingCat.length; i++) {
          if (wrapperMissingCat[i].selected) {
            let w = wrapperMissingCat[i];
            w.status = itemStatus;
            selectedCategory[w.lstRfiCat.Id] = JSON.stringify(w);
          }
        }
        component.set("v.selectedCategory", selectedCategory);
  
        var catValue1 = [];
        console.log("selected categories" + JSON.stringify(selectedCategory));
        catValue1 = Object.keys(selectedCategory);
        console.log("fruits - " + catValue1.length);
        console.log("keys" + JSON.stringify(catValue1));
  
        if (catValue1.length == 0) {
          alert("No RFI Item is selected.");
        } else if (catValue1.length != wrapperMissingCat.length || confirm('You have selected all of the categories. Are you sure you want to do this?')) {
          //using parent value
          var selectedPlant = component.get("v.selectedPlant");
          console.log("selected Plant" + selectedPlant.length);
          console.log("selected categories" + JSON.stringify(selectedCategory));
          if (selectedPlant.length > 0 && typeof selectedCategory != "undefined") {
            helper.callAddRfi(component, event, selectedPlant, selectedCategory);
          } else if (typeof selectedCategory != "undefined") {
            //call Incorrect category
            helper.callControllerCategory(component, event, selectedCategory);
          }
        }
      }
    },
  
    doCancel: function (component, event, helper) {
      var recordId = component.get("v.recordId");
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
    },
  
    handleConfirmDialogYes: function (component, event, helper) {
      component.set("v.callParent", true);
    },
  
    handleConfirmDialogNo: function (component, event, helper) {
      component.set("v.showNotify", false);
    },
  
    doCancelParent: function (component, event, helper) {
      var navLink = component.find("navService");
      var pageRef = {
        type: "standard__component",
        attributes: {
          componentName: "c__AddPlantAsset"
        },
        state: {
          myAttr: "attrValue"
        }
      };
      navLink.navigate(pageRef, true);
    },
  
    onChangePick: function (component, event, helper) {
      //var selectedHeaderCheck = event.getSource().get("v.text") == true;
      if (event.getSource().get("v.value") == true) {
        alert(event.getSource().get("v.value"));
        //component.find("description").focus();
        component.set("v.requiredDes", true);
      }
      /*var checkvalue = [];
  checkvalue = component.find("boxPackMissing");
  var selectedCategory = component.get("v.selectedCategory");
  // var wrapperIncorrectCat = component.get('v.wrapperIncorrectCat');
  
  if(checkvalue.length > 0){
      for (var i = 0; i < checkvalue.length; i++){
          if (checkvalue[i].get("v.value") == true){
              alert(checkvalue[i].get("v.text"));
              //selectedCategory[checkvalue[i].get("v.text")] = JSON.stringify(wrapperIncorrectCat[i]);
          }
      }
  }else{
      var checkboxValue = checkvalue.get("v.value");
      if(checkboxValue){
              alert(checkvalue[i].get("v.text"));
          //  selectedCategory[checkvalue.get("v.text")] = JSON.stringify(wrapperIncorrectCat[0]);
      }
  } */
    },
    onClose: function (component, event, helper) {
      component.set("v.needRequired", false);
    },
    doImplementationMissing: function (component, event, helper) {
      var wrapperMissingCat = component.get("v.wrapperMissingCat");
  
      var checkvalue = [];
      checkvalue = component.find("implementationBlk");
      //alert(checkvalue.length);
      if (checkvalue.length > 0) {
        for (var i = 0; i < checkvalue.length; i++) {
          if (checkvalue[i].get("v.value") == true) {
            //    alert(wrapperMissingCat[i].implementationBlock);
  
            wrapperMissingCat[i].implementationBlock = true;
  
            //     alert(wrapperMissingCat[i].implementationBlock);
            // selectedCategory[checkvalue[i].get("v.text")] = JSON.stringify(wrapperIncorrectCat[i]);
          }
        }
      } else {
        var checkboxValue = checkvalue.get("v.value");
        if (checkboxValue) {
          //   alert(checkvalue[i].get("v.text"));
          wrapperMissingCat[i].implementationBlock = true;
  
          // alert(wrapperMissingCat[i]);
        }
      }
    },
  
    /*doImplementationIncorrect: function (component, event, helper) {
      var wrapperIncorrectCat = component.get("v.wrapperIncorrectCat");
  
      var checkvalue = [];
      checkvalue = component.find("implementationBlkIncorrect");
      //alert(checkvalue.length);
      if (checkvalue.length > 0) {
        for (var i = 0; i < checkvalue.length; i++) {
          if (checkvalue[i].get("v.value") == true) {
            //  alert(checkvalue[i].get("v.text"));
            wrapperMissingCat[i].implementationBlock = true;
            //alert(JSON.stringify(wrapperIncorrectCat[i].implementationBlock));
          }
        }
      } else {
        var checkboxValue = checkvalue.get("v.value");
        if (checkboxValue) {
          //   alert(checkvalue[i].get("v.text"));
          wrapperMissingCat[i].implementationBlock = true;
          //  alert(wrapperIncorrectCat[i]);
        }
      }
    },*/
  
    changeOnsiteRemediationMissing: function (component, event, helper) {
      var picklistValue = component.find("remRequiredMissing");
      if (picklistValue.length > 0) {
        for (var iterationReq = 0; iterationReq < picklistValue.length; iterationReq++) {
          if (picklistValue[iterationReq].get("v.value") != "" && picklistValue[iterationReq].get("v.value") == "No") {
            var desValues = component.find("remeDesMissing");
            desValues[iterationReq].set("v.value", "");
            desValues[iterationReq].set("v.disabled", true);
          } else if (
            picklistValue[iterationReq].get("v.value") != "" &&
            picklistValue[iterationReq].get("v.value") == "Yes"
          ) {
            var desValues = component.find("remeDesMissing");
            desValues[iterationReq].set("v.disabled", false);
          }
        }
      }
    },
  
    /*changeOnsiteRemediationIncorrect: function (component, event, helper) {
      var picklistValue = component.find("remRequiredIncorrect");
      if (picklistValue.length > 0) {
        for (var iterationReq = 0; iterationReq < picklistValue.length; iterationReq++) {
          if (picklistValue[iterationReq].get("v.value") != "" && picklistValue[iterationReq].get("v.value") == "No") {
            var desValues = component.find("remeDesIncorrect");
            desValues[iterationReq].set("v.value", "");
            desValues[iterationReq].set("v.disabled", true);
            //.set("v.disabled", true); component.find("dueDate").set("v.disabled", true);
            //alert('picklistValue'+desValues[iterationReq].set("v.disabled", true));
          } else if (
            picklistValue[iterationReq].get("v.value") != "" &&
            picklistValue[iterationReq].get("v.value") == "Yes"
          ) {
            var desValues = component.find("remeDesIncorrect");
            desValues[iterationReq].set("v.disabled", false);
            //.set("v.disabled", true); component.find("dueDate").set("v.disabled", true);
            //alert('picklistValue'+desValues[iterationReq].set("v.disabled", true));
          }
        }
      }
    },*/
  
    onChangePickMissing: function (component, event, helper) {
      var checkBoxMissing = component.find("boxPackMissing");
      var description = component.find("description");
  
      if (checkBoxMissing.length > 0) {
        for (var i = 0; i < checkBoxMissing.length; i++) {
          if (checkBoxMissing[i].get("v.value") == true) {
            description[i].set("v.required", true);
          } else {
            description[i].set("v.required", false);
          }
        }
      } else {
        var checkBoxMissing = checkBoxMissing.get("v.value");
        if (checkBoxMissing) {
          description.set("v.required", true);
        } else {
          description.set("v.required", false);
        }
      }
    }
  
    /*onChangePickIncorrect: function (component, event, helper) {
      var checkBoxMissing = component.find("boxPack");
      var description = component.find("descriptionIncorrect");
      var remRequiredMissing = component.find("remRequiredIncorrect");
  
      if (checkBoxMissing.length > 0) {
        for (var i = 0; i < checkBoxMissing.length; i++) {
          if (checkBoxMissing[i].get("v.value") == true) {
            description[i].set("v.required", true);
            remRequiredMissing[i].set("v.required", true);
          } else {
            description[i].set("v.required", false);
            remRequiredMissing[i].set("v.required", false);
          }
        }
      } else {
        var checkBoxMissing = checkBoxMissing.get("v.value");
        if (checkBoxMissing) {
          description.set("v.required", true);
          remRequiredMissing.set("v.required", true);
        } else {
          description.set("v.required", false);
          remRequiredMissing.set("v.required", false);
        }
      }
    }*/
  });