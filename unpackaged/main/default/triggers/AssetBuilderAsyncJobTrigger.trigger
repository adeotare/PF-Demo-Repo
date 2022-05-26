/**
 * TODO - Calls when Asset Builder Async Job Platform Event publish
 * */ 
trigger AssetBuilderAsyncJobTrigger on Asset_Builder_Async_Job__e (after insert) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            /*
            * To pass new data or data's to handler to processAsynJobTrg
            @param {List<Asset_Builder_Async_Job__e>} Trigger.new - Pass new Asset Builder Async Job.
            */
            //AssetBuilderAsyncJobTrgHdlr.processAsynJobTrg(Trigger.new);
            String lastPromptInitiatedId;
            String plantAssetId;
            String plantAssetPromptDetail;
            try{
                List<Id> idList = new List<Id>();
                Integer batchCount=1;
                AssetBuilderBatchSizeConfiguration__mdt assetBuildBatchSize = [SELECT Id, DeveloperName,Size__c FROM AssetBuilderBatchSizeConfiguration__mdt WHERE DeveloperName =: 'Platform_Event_Batch_Size'];
                for(Asset_Builder_Async_Job__e asyncJobInst : Trigger.new){
                    plantAssetId = asyncJobInst.Plant_Asset_Id__c;
                    plantAssetPromptDetail = String.isNotBlank(asyncJobInst.Plant_Asset_Prompt_Detail_Id__c) ? asyncJobInst.Plant_Asset_Prompt_Detail_Id__c : '';
                    Plant_Asset_Prompt_Detail__c pltAstPrtDtl; 
                    
                    if(String.isNotBlank(plantAssetPromptDetail)){
                        pltAstPrtDtl = [SELECT Id, Name, Last_Process_Initiated_DT__c FROM Plant_Asset_Prompt_Detail__c WHERE Id =: asyncJobInst.Plant_Asset_Prompt_Detail_Id__c];
                    }
                    
                    if(batchCount <= assetBuildBatchSize.Size__c){
                        /* For report data creation process*/
                        if(asyncJobInst.Job_Type__c == 'Capability Report' || asyncJobInst.Job_Type__c == 'Completeness Report'){
                            if(asyncJobInst.Job_Type__c == 'Capability Report'){
                                EvaluationValueDataCreation.mapFormationForEvaluationValue(asyncJobInst.Plant_Asset_Id__c);
                            }else if(asyncJobInst.Job_Type__c == 'Completeness Report'){
                                List<Id> promptInfoId = new List<Id>();
                                ReportDataHandler reportDataHldr = new ReportDataHandler();
                                reportDataHldr.queryExsistingReportData(asyncJobInst.Plant_Asset_Id__c, promptInfoId);
                            }
                            EventBus.TriggerContext.currentContext().setResumeCheckpoint(asyncJobInst.ReplayId);  
                        }
                        
                        if(String.isNotBlank(plantAssetPromptDetail)){
                            if(asyncJobInst.Last_Process_Initiated_DT__c == pltAstPrtDtl.Last_Process_Initiated_DT__c){
                                if(asyncJobInst.Job_Type__c == 'Core Attribute Roll Up'){
                                    idList.clear();
                                    if(asyncJobInst.Prompt_Information_Ids__c.contains(',')){
                                        //To Store multiple prompt information
                                        List<String> strLst = asyncJobInst.Prompt_Information_Ids__c.split(',');
                                        idList.addAll(strLst);
                                    }else{
                                        //To Store single prompt information
                                        idList.add(asyncJobInst.Prompt_Information_Ids__c);
                                    }
                                    CoreAttrRollUpHdlr.afterUpdateSiteMetaData(idList, asyncJobInst.Last_Process_Initiated_DT__c, 
                                    asyncJobInst.Plant_Asset_Prompt_Detail_Id__c, asyncJobInst.Plant_Asset_Id__c);
                                }else if(asyncJobInst.Job_Type__c == 'Attribute Value Creation'){
                                    idList.clear();
                                    if(asyncJobInst.Site_Metadata_Ids__c.contains(',')){
                                            //To Store multiple Site Metadata
                                        List<String> strLst = asyncJobInst.Site_Metadata_Ids__c.split(',');
                                        idList.addAll(strLst);
                                    }else{
                                        //To Store single Site Metadata
                                        idList.add(asyncJobInst.Site_Metadata_Ids__c);
                                    }
                                    AttributeValueObjDataHandler.createOrUpdateAttrValueRecs(idList, asyncJobInst.Last_Process_Initiated_DT__c, 
                                    asyncJobInst.Plant_Asset_Prompt_Detail_Id__c, asyncJobInst.Plant_Asset_Id__c);
                                }else if(asyncJobInst.Job_Type__c == 'Metric Value Creation'){
                                    idList.clear();
                                    if(asyncJobInst.Bast_Asset_Template_Ids__c != null){
                                            //To Store multiple Base Asset Template
                                        if(asyncJobInst.Bast_Asset_Template_Ids__c.contains(',')){
                                            List<String> strLst = asyncJobInst.Bast_Asset_Template_Ids__c.split(',');
                                            idList.addAll(strLst);
                                        }else if(String.isNotBlank(asyncJobInst.Bast_Asset_Template_Ids__c)){
                                            //To Store single Base Asset Template
                                            idList.add(asyncJobInst.Bast_Asset_Template_Ids__c);
                                        }
                                    }
                                    MetricValueDataCreation.queryBaseAssetCoreAttrBasedOnMetricDef(idList, asyncJobInst.Last_Process_Initiated_DT__c, 
                                    asyncJobInst.Plant_Asset_Prompt_Detail_Id__c, asyncJobInst.Plant_Asset_Id__c);
                                }else if(asyncJobInst.Job_Type__c == 'Weighted Average Rollup'){
                                    idList.clear();
                                    if(asyncJobInst.Prompt_Information_Ids__c != null){
                                        if(asyncJobInst.Prompt_Information_Ids__c.contains(',')){
                                            List<String> strLst = asyncJobInst.Prompt_Information_Ids__c.split(',');
                                            idList.addAll(strLst);
                                        }else if(String.isNotBlank(asyncJobInst.Prompt_Information_Ids__c)){
                                            idList.add(asyncJobInst.Prompt_Information_Ids__c);
                                        }
                                    }
                                    WeightedAverageRollup.formMapForRollup(idList, asyncJobInst.Last_Process_Initiated_DT__c, asyncJobInst.Plant_Asset_Prompt_Detail_Id__c, asyncJobInst.Plant_Asset_Id__c);
                                }
                            }
                        }
                        EventBus.TriggerContext.currentContext().setResumeCheckpoint(asyncJobInst.ReplayId);
                    }else{
                        break;
                    }
                    batchCount++;
                }
            }catch(Exception exceptionDetails){
                System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
                Error_Log__c errorLogInstance = Utils.catchErrorLogs('processAsynJobTrg',exceptionDetails.getMessage(), 
                    exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetail);
                insert errorLogInstance;
            }
        }
    }
}