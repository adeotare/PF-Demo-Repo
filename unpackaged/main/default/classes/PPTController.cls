public class PPTController{
public Id accountId {get; set;}

    public PPTController(ApexPages.StandardSetController controller) {
    accountId = ApexPages.currentPage().getParameters().get('id');
        System.debug('=====accountId ======='+accountId  );
    }


    
}