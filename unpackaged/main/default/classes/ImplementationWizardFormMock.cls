@IsTest
public class ImplementationWizardFormMock implements HttpCalloutMock {
    // Implement this interface method
    public String bdyContentType;
    public Integer statusCode;

    public ImplementationWizardFormMock(String bodyContent, Integer statusCod){
        bdyContentType = bodyContent;
        statusCode = statusCod;
    }

    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(bdyContentType);
        response.setStatusCode(statusCode);
        return response;
    }
}