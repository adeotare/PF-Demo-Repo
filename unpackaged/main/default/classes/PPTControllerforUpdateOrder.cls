public class PPTControllerforUpdateOrder{
public Id accountId {get; set;}

    public PPTControllerforUpdateOrder(ApexPages.StandardSetController controller) {
    accountId = ApexPages.currentPage().getParameters().get('id');
        System.debug('=====accountId ======='+accountId  );
    }


    
}