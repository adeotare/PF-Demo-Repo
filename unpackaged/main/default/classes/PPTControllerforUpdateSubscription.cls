public class PPTControllerforUpdateSubscription{
public Id accountId {get; set;}

    public PPTControllerforUpdateSubscription(ApexPages.StandardSetController controller) {
    accountId = ApexPages.currentPage().getParameters().get('id');
        System.debug('=====accountId ======='+accountId  );
    }


    
}