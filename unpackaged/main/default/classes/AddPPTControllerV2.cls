public with sharing class AddPPTControllerV2 {

    /**
     * This class is for save PPT records for  Cloud Coach Project  
       from quick action 
     */
    @AuraEnabled
    public static List<Plant_Product_Transaction__c > getExistingPPTList(String projectId) {
        //Query and return list of Projects
        List<Plant_Product_Transaction__c > lstPPT = new List<Plant_Product_Transaction__c >();
        List<project_cloud__Project__c> lstProjectAccnts = [select Account_Plant__c from project_cloud__Project__c where id=:projectId];
     
        if(Plant_Product_Transaction__c.SObjectType.getDescribe().isAccessible()){
        	if(lstProjectAccnts.size()>0){
                return [SELECT Id, Name ,Plant_Name__c , Status__c , MWp_Quantity__c,Product_Name__c From Plant_Product_Transaction__c where Plant__c =: lstProjectAccnts[0].Account_Plant__c AND Project_Name__c = null AND Status__c != 'Quoted'];
        	} else {
            	return lstPPT;
            }
         } else {
        	return lstPPT;
         }
    }
    /**
    * This method will save Ppt record for project Id  
    */
    @AuraEnabled 
    public static void addProjects(String projectId, String projectIdListJSON){
        if(project_cloud__Project__c.SObjectType.getDescribe().isAccessible()){
            List<Plant_Product_Transaction__c> lstProjects = new List<Plant_Product_Transaction__c>();
            Type idArrType = Type.forName('List<string>');
            List<string> lstProjectIds = (List<string>) JSON.deserialize(projectIdListJSON, idArrType);

            system.debug('==programId==::'+projectId);
            system.debug('==lstProjectIds==::'+lstProjectIds);
            if(!string.isblank(projectId) && lstProjectIds.size()>0 ){
                Decimal ARR = 0;
                Decimal Installation_Fee = 0;
                String product;
                String Product_Family;
				List<project_cloud__Project__c> Projectdetails =[SELECT Deployment_Date__c from project_cloud__Project__c where id =:projectId];
                system.debug('::Projectdetails'+Projectdetails);
                for(Plant_Product_Transaction__c ppt: [SELECT Id, Name,Product_Category__c,Product__r.Name,Product_Family__c, Net_Total_Price__c From Plant_Product_Transaction__c where id IN:lstProjectIds]){
                    ppt.Project_Name__c = projectId;
                    ppt.Is_Project_Added__c = True;
					if(Projectdetails.size() > 0){
                        system.debug('::ProjectdetailsVale'+Projectdetails[0].Deployment_Date__c);
                       ppt.Deployment_date__c = Projectdetails[0].Deployment_Date__c; 
                    }
                    lstProjects.add(ppt);
                    if(ppt.Product_Category__c == 'Software' && ppt.Net_Total_Price__c != null && ppt.Net_Total_Price__c != 0){
                        system.debug('ARR-Net_Total_Price__c::'+ARR);
                        ARR += ppt.Net_Total_Price__c;
                        product = ppt.Product__r.Name;
                    }
                    if(ppt.Product_Category__c == 'Professional Services' && ppt.Net_Total_Price__c != null && ppt.Net_Total_Price__c != 0){
                        system.debug('Installation_Fee-Net_Total_Price__c::'+ARR);
                        Installation_Fee += ppt.Net_Total_Price__c;
                        Product_Family = ppt.Product_Family__c;
                    }
                }
                
                project_cloud__Project__c project = [select Id, Installation_Fee__c, ARR__c from project_cloud__Project__c where ID =: projectId];
                if(Installation_Fee != null && Installation_Fee != 0){
                    if(project.Installation_Fee__c == null){
                        project.Installation_Fee__c = 0.00;
                    }
                    project.Installation_Fee__c = project.Installation_Fee__c + Installation_Fee;
                }
                
                if(ARR != null && ARR != 0){
                    system.debug('::ARR1111::'+ARR);
                   // Decimal tempARR = 0.00;
                    if(project.ARR__c == null){
                        project.ARR__c = 0.00;
                    }
                    system.debug('::ARR11111__c::'+project.ARR__c);
                    project.ARR__c = project.ARR__c + ARR;
                }
                
                if(!String.isblank(product)){
                    project.Product__c = product;
                }
                if(!String.isblank(Product_Family)){
                    project.Product_Family__c = Product_Family;
                }
                update lstProjects;
                update project;
            }
        }
    }
}