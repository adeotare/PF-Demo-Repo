({
  onPageReferenceChange: function (cmp, event, helper) {
    var pageRef = cmp.get("v.pageReference");
    cmp.set("v.id", pageRef.state.c__id);
    cmp.set("v.listName", pageRef.state.c__listName);

    // Dynamically Create Related List Component based on Name
    $A.createComponent(
      "c:" + cmp.get("v.listName"),
      {
        recordId: cmp.get("v.id"),
        isFullPage: true
      },
      function (body, status, errorMessage) {
        //Add the new button to the body array
        if (status === "SUCCESS") {
          cmp.set("v.body", body);
        } else if (status === "INCOMPLETE") {
          console.log("No response from server or client is offline.");
          // Show offline error
        } else if (status === "ERROR") {
          console.log("Error: " + errorMessage);
          // Show error message
        }
      }
    );
  }
});