({
	showError: function(component, event, helper){
		var params = event.getParam('arguments');
		helper.handleNotification(component, params.title, params.message, 'error');
	},
	showSuccess: function(component, event, helper){
		var params = event.getParam('arguments');
		helper.handleNotification(component, params.title, params.message, 'success');
	},
	showWarning: function(component, event, helper){
		var params = event.getParam('arguments');
		helper.handleNotification(component, params.title, params.message, 'warning');
	},
	showInfo: function(component, event, helper){
        var params = event.getParam('arguments');
        helper.handleNotification(component, params.title, params.message, 'info');
    },
	showErrorResponse: function(component, event, helper){
		var params = event.getParam('arguments');
		var message = helper.parseErrorResponse(params.response);
		helper.handleNotification(component, params.title, message, 'error');
	},
	hideUiMessage: function(component, event){
		component.set("v.show", false);
	}
})