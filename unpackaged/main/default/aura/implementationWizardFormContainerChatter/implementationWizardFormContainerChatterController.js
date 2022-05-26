({
	handleIWFDNavigation: function(component, message, helper) { 
		if (message != null && message.getParam("isShowAB") != null &&
			message.getParam("isHideIWFD") != null) {
			component.set("v.isShowAB",message.getParam("isShowAB"));
			component.set("v.isHideIWFD",message.getParam("isHideIWFD"));
		}
	},

	handleABNavigation: function(component, message, helper) { 
		if (message != null && message.getParam("plantAssetId") != null) {
			component.set("v.plantAssetId",message.getParam('plantAssetId'));
			component.set("v.isImpWizUpLoad",message.getParam('isImpWizUpLoad'));
			component.set("v.isOverride",message.getParam('isOverride'));
			component.set("v.isShowAB",message.getParam('isShowAB'));
			component.set("v.isHideIWFD",true);
		}
	}
})