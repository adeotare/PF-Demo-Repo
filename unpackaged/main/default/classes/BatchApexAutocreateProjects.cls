/**
 * The batch class will auto-create projects for PPT records.   
 * for non-renewal opportunities
 * @param  :  
 * @return :  Create Project Records
 */
global class BatchApexAutocreateProjects implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String query = 'select id,Account__c,Account__r.Name, Plant__c,Plant__r.Name,Product__r.Name,Product__r.ProductCode,Product__r.Services_Short_Name__c, Installation_Commencement_Date__c, Product_Category__c, Project_Creation_Status__c,MWp_Quantity__c,Net_Total_Price__c,Status__c,Plant_Name__c,Product_Family__c from Plant_Product_Transaction__c where Project_Creation_Status__c !=\'Completed\' AND Status__c NOT IN(\'Quoted\',\'Amendment Quoted\')';

        system.debug('==soql.Value__c='+query);
       
       
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Plant_Product_Transaction__c> pptList) {
		
		set<id>templateIdSet = new set<id>();
		Map<Id, Plant_Product_Transaction__c> mapIdVsPPT = new Map<Id, Plant_Product_Transaction__c>();
		set<id>lstPPTToUpdate = new set<id>();
		set<id>productIdSet = new set<id>();
		
		for(Plant_Product_Transaction__c ppt : pptList) {
			productIdSet.add(ppt.Product__c);
        }
		list<Project_Template__c>templateList= new list<Project_Template__c>();
        for(Project_Template__c templateRec : [Select id,Template__c,Project_Type__c,Product_Code__c,Decommission_Template__c from Project_Template__c 
                                                where Product_Code__c IN : productIdSet]){
                   templateList.add(templateRec);
        }
		
		map<string,string>accountPlantWithProductmap = new map<string,string>();	
		for(Plant_Product_Transaction__c ppt : pptList){
			for(Project_Template__c template : templateList){
				string key = ppt.Plant__c +'-'+ ppt.Product__c;
				if(ppt.Product__c == template.Product_Code__c && !accountPlantWithProductmap.containskey(key)){
					string uniqueqAccPlantProdId ;
					Plant_Product_Transaction__c pptRecord = new Plant_Product_Transaction__c();
					if(ppt.Status__c == 'Decommissioned' && template.Decommission_Template__c != null){
						templateIdSet.add(template.Decommission_Template__c);
						mapIdVsPPT.put(template.Decommission_Template__c, ppt);
					} else if(ppt.Status__c == 'Contracted' || ppt.Status__c == 'Ordered'){
						templateIdSet.add(template.Template__c);
						mapIdVsPPT.put(template.Template__c, ppt);
					}
					
				   uniqueqAccPlantProdId = ppt.Plant__c +'-'+ ppt.Product__c;
				   accountPlantWithProductmap.put(uniqueqAccPlantProdId,uniqueqAccPlantProdId);
					   
				}            
			}
		}
		
        system.debug('::templateIdSet::'+templateIdSet);
        system.debug('::templateIdSetsize::'+templateIdSet.size());
        system.debug('::mapIdVsPPT::'+mapIdVsPPT);
		map<string,string>queueNameVsId = new map<string,string>();
		for(QueueSobject qobj : [select  Queue.Id, queue.name,Queue.DeveloperName from QueueSobject where SobjectType = 'project_cloud__Project__c']){
			queueNameVsId.put(qobj.queue.DeveloperName, qobj.Queue.Id);
		}
		system.debug('--queueNameVsId'+queueNameVsId);
		
		List<project_cloud__Project__c> projects = [SELECT Id, Name,ccpe_ocp__Account__c,
                                                        Account_Plant__c,Installation_Commencement_Date__c,Product__c,
                                                        ARR__c,Installation_Fee__c,PPT_Reference__c,project_cloud__Methodology__c,
                                                        project_cloud__Type__c,Project_Description__c,Notes__c, Project_Visibility__c,project_cloud__Project_Duration__c,OwnerId
														,project_cloud__Start__c
                                                        FROM project_cloud__Project__c WHERE 
                                                        project_cloud__IsTemplate__c = true AND Id IN:templateIdSet]; 
		for(project_cloud__Project__c toClone : projects){
			//project_cloud__Project__c toClone = p.clone(false, true);
			
				String projectName = '';
				
				if(!string.isBlank(mapIdVsPPT.get(toClone.id).Account__r.Name)){
                    if(mapIdVsPPT.get(toClone.id).Account__r.Name.length() > 10){
						projectName += mapIdVsPPT.get(toClone.id).Account__r.Name.substring(0,10);
                    } else {
                        projectName += mapIdVsPPT.get(toClone.id).Account__r.Name;
                    }
				}
				projectName += ' - ' + datetime.now().format('YYMM');
				if(mapIdVsPPT.get(toClone.id).MWp_Quantity__c != null){
					projectName += ' - ' + mapIdVsPPT.get(toClone.id).MWp_Quantity__c.setScale(2);
				}
				if(!string.isBlank(mapIdVsPPT.get(toClone.id).Product__r.Services_Short_Name__c)){
					if(mapIdVsPPT.get(toClone.id).Product__r.Services_Short_Name__c.length() > 20){
						projectName += ' - ' + mapIdVsPPT.get(toClone.id).Product__r.Services_Short_Name__c.substring(0,20);
					} else {
						projectName += ' - ' + mapIdVsPPT.get(toClone.id).Product__r.Services_Short_Name__c;
					}
				}
				if(!string.isBlank(mapIdVsPPT.get(toClone.id).Plant_Name__c)){
					projectName += ' - ' + mapIdVsPPT.get(toClone.id).Plant_Name__c;
				}
                //toClone.Id = p.Id;
                system.debug('----toClone--'+toClone);
                toClone.Name = projectName;
                toClone.ccpe_ocp__Account__c = mapIdVsPPT.get(toClone.id).Account__c;
                toClone.Account_Plant__c = mapIdVsPPT.get(toClone.id).Plant__c;
                toClone.Installation_Commencement_Date__c = mapIdVsPPT.get(toClone.id).Installation_Commencement_Date__c;
                if(mapIdVsPPT.get(toClone.id).Product_Category__c == 'Software'){
                    toClone.Product__c = mapIdVsPPT.get(toClone.id).Product__r.Name;
                    toClone.ARR__c = mapIdVsPPT.get(toClone.id).Net_Total_Price__c;
                }
                if(mapIdVsPPT.get(toClone.id).Product_Category__c == 'Professional Services'){
                    toClone.Installation_Fee__c = mapIdVsPPT.get(toClone.id).Net_Total_Price__c;
                    toClone.Product_Family__c = mapIdVsPPT.get(toClone.id).Product_Family__c;
                }
                toClone.PPT_Reference__c = mapIdVsPPT.get(toClone.id).id;
            	toClone.Template_Id_Reference__c = toClone.id;
            	//toClone.OwnerId = '00G7j000001xugiEAA';
                
                
                if(mapIdVsPPT.get(toClone.id).Product__r.ProductCode.containsIgnoreCase('DR-OM-') && queueNameVsId.get('Services_Drive_O_M') != null){
                    toClone.OwnerId = queueNameVsId.get('Services_Drive_O_M');
                } else if(mapIdVsPPT.get(toClone.id).Product__r.ProductCode.containsIgnoreCase('DR-') && queueNameVsId.get('Services_Drive') != null){
                    toClone.OwnerId = queueNameVsId.get('Services_Drive');
                } else if(mapIdVsPPT.get(toClone.id).Product__r.ProductCode.containsIgnoreCase('BP-') && queueNameVsId.get('Services_Bluepoint') != null){
                    toClone.OwnerId = queueNameVsId.get('Services_Bluepoint');
                } else if(mapIdVsPPT.get(toClone.id).Product__r.ProductCode.containsIgnoreCase('GB-') && queueNameVsId.get('Services_Greenbyte') != null){
                    toClone.OwnerId = queueNameVsId.get('Services_Greenbyte');
                }
            	
                system.debug('--toClone'+toClone);
				try {
					project_cloud.CloneHelper.cloneProject(toClone, Date.today());
					lstPPTToUpdate.add(mapIdVsPPT.get(toClone.id).id);
				 
				} catch(Exception e) {
					System.debug('::BatchApexAutocreateProjects::'+e);
				}
                
		}
		
		List<Plant_Product_Transaction__c> pptDetails = [select id, Project_Creation_Status__c from Plant_Product_Transaction__c where ID IN :lstPPTToUpdate];
		if(pptDetails.size() > 0){
			for(Plant_Product_Transaction__c pptRec : pptDetails) {      
				pptRec.Project_Creation_Status__c = 'Completed';
			}
			try {
                System.debug('::pptDetails::'+pptDetails);
				update pptDetails;
			 
			} catch(Exception e) {
				System.debug(e);
			}
		}
    }   
     
    global void finish(Database.BatchableContext BC) {
        
    }
}