({
	handleNotification: function(component, title, message, type){
        component.set("v.show", false);
        var severity = type == 'success' ? 'confirm' : type;
        component.set("v.message", message);
        component.set("v.title", title);
        component.set("v.severity", severity);
        component.set("v.show", true);
    },
    parseErrorResponse: function(response) {
        if(typeof response === "string"){
            return response;
        }else if(response.getError()){
            var errorObj = {};
            errorObj = response.getError();
            return this.parseErrors(errorObj[0]);
        }
        else return 'Unknown error';
    },
    parseErrors: function(error){
        if (this.pageErrorCheck(error)) return error.pageErrors[0].message;
        else if (this.fieldErrorCheck(error)) return error.fieldErrors[0].message;
        else if (error.message) return error.message;
        else return 'Unknown error';
    },
    pageErrorCheck: function(error){
        return Boolean(error.pageErrors && error.pageErrors[0] && error.pageErrors[0].message);
    },
    fieldErrorCheck: function(error){
        return Boolean(error.fieldErrors && error.fieldErrors[0] && error.fieldErrors[0].message);
    }
})