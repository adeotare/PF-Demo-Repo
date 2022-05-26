({
    closeModel: function(component, event, helper) {
       // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
       component.set("v.isOpen", false);
    },

    handleAssetBuilderApprovalRecId: function (component) {
        var pubsub = component.find('pubsub');
        var callback = $A.getCallback(function (data) {
            component.set('v.assetBuilderApprovalRecId', JSON.parse(JSON.stringify(data)).selectedPlantAssetIdABAId);
            component.set('v.plantName', JSON.parse(JSON.stringify(data)).plantName);
            var ABARecId = component.get("v.assetBuilderApprovalRecId");

            if(ABARecId){
                component.set("v.isOpen", true);
            }
        });
        pubsub.registerListener('passAssetBuilderApprovalRecId', callback);
    }
 })