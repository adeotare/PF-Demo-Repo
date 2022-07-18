/**
 * TODO - Calls from Site Metadata Trigger when Site Metadata is created or updated.
 * Publish Platform Event for various actions
 * */ 
public class SiteMetaDataHandler {
    /*
    * Formation of necessary list base Asset template Id list and sitemetadata Id list 
    * @param {List<Site_Metadata__c>} siteMetaDataList - List of Site Metadata needed for various process.
    * @param {Boolean} isAfterUpdate - To know whether should execute for after update.
    * @param {Boolean} isAfterInsert - To know whether should execute for after insert.
    */
    public static void triggerPlatformEvents(List<Site_Metadata__c> siteMetaDataList, Boolean isAfterUpdate, Boolean isAfterInsert){
        DateTime lastPromptSaveId;
        String plantAssetId, plantAssetPromptDetailId;
        try{
            set<Id> baseAssetSet = new set<Id>();
            set<Id> siteMetadataSet = new set<Id>();
            set<Id> promptInfoSet = new set<Id>();
            List<Plant_Asset_Prompt_Detail__c> plantAssetPrompt = new List<Plant_Asset_Prompt_Detail__c>();
            Boolean attrValueChanged = false;

            for(Site_Metadata__c siteMetaDataInstance : siteMetaDataList){
                plantAssetId = siteMetaDataInstance.Account_Plant__c;
                plantAssetPromptDetailId = siteMetaDataInstance.Plant_Asset_Prompt_Detail__c;
                attrValueChanged = siteMetaDataInstance.Is_Attribute_Value_Modified_in_Prompt__c;
                if(String.isNotBlank(siteMetaDataInstance.Base_Asset_Template__c)){
                    baseAssetSet.add(siteMetaDataInstance.Base_Asset_Template__c);
                }
                if(String.isNotBlank(siteMetaDataInstance.Prompt_Information__c)){
                    promptInfoSet.add(siteMetaDataInstance.Prompt_Information__c);
                }
                if(isAfterUpdate && attrValueChanged){
                    siteMetadataSet.add(siteMetaDataInstance.Id);
                }else if(isAfterInsert){
                    siteMetadataSet.add(siteMetaDataInstance.Id);
                }
            }
			lastPromptSaveId = StaticVariableForAssetBuilderUtils.platformEventLastProcessedDatetime;
            
            if(siteMetadataSet.size() > 0){
                Plant_Asset_Prompt_Detail__c promptAssetPrompt = [SELECT Id,Last_Process_Initiated_DT__c FROM 
                    Plant_Asset_Prompt_Detail__c WHERE Id=:plantAssetPromptDetailId];
                promptAssetPrompt.Last_Process_Initiated_DT__c = lastPromptSaveId;
                update promptAssetPrompt;
                List<Id> baseAssetLst = new List<Id>(baseAssetSet);
                List<Id> siteMetadataLst = new List<Id>(siteMetadataSet);
                List<Id> promptInfoLst = new List<Id>(promptInfoSet);

                createPlatformEvent(lastPromptSaveId, plantAssetId, plantAssetPromptDetailId, siteMetadataLst, baseAssetLst, isAfterUpdate, isAfterInsert, promptInfoLst);
            }

        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('triggerPlatformEvents',exceptionDetails.getMessage(), 
                exceptionDetails.getLineNumber(), plantAssetId, plantAssetPromptDetailId);
            insert errorLogInstance;
        }
        
    }
    /*
    * Formation of necessary list base Asset template Id list and sitemetadata Id list 
    * @param {List<Site_Metadata__c>} siteMetaDataList - List of Site Metadata needed for various process.
    * @param {Boolean} isAfterUpdate - To know whether should execute for after update.
    * @param {Boolean} isAfterInsert - To know whether should execute for after insert.
    * @param {List<Id>} promptInfoLst - List of prompt information needed for weighted average
    */
    public static void createPlatformEvent(DateTime lastPromptSaveId, String plantAssetId, String plantAssetPromptDetailId, List<Id> siteMetadataLst, List<Id> baseAssetLst, Boolean isAfterUpdate, Boolean isAfterInsert, List<Id> promptInfoLst){
        String plantAssetIdCreatePE, plantAssetPromptDetailIdCreatePE;
        List<Asset_Builder_Async_Job__e> platformEventSiteMetaLst = new List<Asset_Builder_Async_Job__e>();
        try{
            plantAssetIdCreatePE = plantAssetId;
            plantAssetPromptDetailIdCreatePE = plantAssetPromptDetailId;
            
            if(isAfterInsert){
                createPEForAttrValueAndMetricValue(siteMetadataLst, baseAssetLst, lastPromptSaveId, plantAssetPromptDetailId, plantAssetId, promptInfoLst);
            }

            if(isAfterUpdate){
                //Core Attribute Rollup 
                Asset_Builder_Async_Job__e asyncJobRollup = new Asset_Builder_Async_Job__e(); 
                asyncJobRollup.Job_Type__c = 'Core Attribute Roll Up'; 
                asyncJobRollup.Prompt_Information_Ids__c =  (promptInfoLst.size()>1) ? String.join(promptInfoLst,',') : String.valueOf(promptInfoLst[0]); 
                asyncJobRollup.Plant_Asset_Id__c = plantAssetId; 
                asyncJobRollup.Last_Process_Initiated_DT__c = lastPromptSaveId; 
                asyncJobRollup.Plant_Asset_Prompt_Detail_Id__c = plantAssetPromptDetailId; 
                EventBus.publish(asyncJobRollup);

                createPEForAttrValueAndMetricValue(siteMetadataLst, baseAssetLst, lastPromptSaveId, plantAssetPromptDetailId, plantAssetId, promptInfoLst);
                
            }   
        }catch(Exception exceptionDetails){
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            Error_Log__c errorLogInstance = Utils.catchErrorLogs('createPlatformEvent',exceptionDetails.getMessage(), 
                exceptionDetails.getLineNumber(), plantAssetIdCreatePE, plantAssetPromptDetailIdCreatePE);
            insert errorLogInstance;
        }
    }
    /*
    * Publish Platform Event for Various process need to execute after insertion/updation of Site Metadata
    * @param {List<Id>} siteMetadataLst - List of Site Metadata needed for Attribute rollup and Attribute Value creation.
    * @param {List<Id>} baseAssetLst - List of Site Metadata needed for Metric Value Creation.
    * @param {DateTime} lastPromptSaveId - Initiated date and time for track the process execute after insertion/updation of Site Metadata.
    * @param {String} plantAssetPromptDetailId - Track updates of Creation/Updation and store in G1 Plant Asset Prompt Detail against Plant Asset.
    * @param {String} plantAssetId - Process executes(Attribute rollup, or Attribute value or Metric value) against Plant Asset.
    * @param {List<Id>} promptInfoLst - List of prompt information needed for weighted average
    */
    public static void createPEForAttrValueAndMetricValue(List<Id> siteMetadataLst, List<Id> baseAssetLst, DateTime lastPromptSaveId, String plantAssetPromptDetailId, String plantAssetId, List<Id> promptInfoLst){
        //Attr Value creation
        Asset_Builder_Async_Job__e asyncJobAttrValueCreation = new Asset_Builder_Async_Job__e(); 
        asyncJobAttrValueCreation.Job_Type__c = 'Attribute Value Creation'; 
        asyncJobAttrValueCreation.Site_Metadata_Ids__c =  (siteMetadataLst.size()>1) ? String.join(siteMetadataLst,',') : String.valueOf(siteMetadataLst[0]); 
        asyncJobAttrValueCreation.Plant_Asset_Id__c = plantAssetId; 
        asyncJobAttrValueCreation.Last_Process_Initiated_DT__c = lastPromptSaveId; 
        asyncJobAttrValueCreation.Plant_Asset_Prompt_Detail_Id__c = plantAssetPromptDetailId; 
        EventBus.publish(asyncJobAttrValueCreation);
        
        List<Id> metricList = new List<Id>();
        for(Metric_Definition__c metricIns : [SELECT id FROM Metric_Definition__c WHERE Base_Asset_Template__c IN: baseAssetLst]){
            metricList.add(metricIns.Id);
        }
        system.debug('---metricList-size-'+metricList.size());
        //For Single Base Asset Template
        if(metricList.size() <= 2 && metricList.size() >0){
            Asset_Builder_Async_Job__e asyncJobMetricValueCreation = new Asset_Builder_Async_Job__e(); 
            asyncJobMetricValueCreation.Job_Type__c = 'Metric Value Creation'; 
            asyncJobMetricValueCreation.Bast_Asset_Template_Ids__c  = String.join(metricList,','); 
            asyncJobMetricValueCreation.Plant_Asset_Id__c = plantAssetId; 
            asyncJobMetricValueCreation.Last_Process_Initiated_DT__c = lastPromptSaveId; 
            asyncJobMetricValueCreation.Plant_Asset_Prompt_Detail_Id__c = plantAssetPromptDetailId; 
            EventBus.publish(asyncJobMetricValueCreation);
        }else{
            //For Multiple Base Asset Template
            Integer baseAssetIdSize = Integer.valueOf(metricList.size());//Size of Base Asset Template
            AssetBuilderBatchSizeConfiguration__mdt assetBuildBatchSize = [SELECT Id, DeveloperName,Size__c FROM AssetBuilderBatchSizeConfiguration__mdt WHERE DeveloperName =: 'Metric_Value_Creation_Size'];
            Double batchSize = baseAssetIdSize / assetBuildBatchSize.Size__c;  
            batchSize = Math.ceil(batchSize); //To split as batches 
            Integer size = Integer.valueOf(assetBuildBatchSize.Size__c);
            Integer remainingRecordToBeProcessed = Math.mod(baseAssetIdSize, size); //After Splitted, to store the remaining base asset templates
            List<String> batchMetricIds = new List<String>();
            for(Id batId : metricList){
                batchMetricIds.add(batId);
                if(batchMetricIds.size() == 2){
                    Asset_Builder_Async_Job__e asyncJobMetricValueCreation = new Asset_Builder_Async_Job__e(); 
                    asyncJobMetricValueCreation.Job_Type__c = 'Metric Value Creation'; 
                    String lstJoin = String.join(batchMetricIds,',');
                    String metricDefStri;
                    if(lstJoin.endsWith(',')){
                        metricDefStri = lstJoin.removeEnd(',');
                    }else{
                        metricDefStri = lstJoin;
                    }
                    asyncJobMetricValueCreation.Bast_Asset_Template_Ids__c  =  metricDefStri; 
                    asyncJobMetricValueCreation.Plant_Asset_Id__c = plantAssetId; 
                    asyncJobMetricValueCreation.Last_Process_Initiated_DT__c = lastPromptSaveId; 
                    asyncJobMetricValueCreation.Plant_Asset_Prompt_Detail_Id__c = plantAssetPromptDetailId; 
                    EventBus.publish(asyncJobMetricValueCreation);
                    batchMetricIds.clear();
                    batchSize = batchSize - 1;
                }else if(batchSize == 1){
                    if(batchMetricIds.size() == remainingRecordToBeProcessed){
                        Asset_Builder_Async_Job__e asyncJobMetricValueCreation = new Asset_Builder_Async_Job__e(); 
                        asyncJobMetricValueCreation.Job_Type__c = 'Metric Value Creation'; 
                        String lstJoin = String.join(batchMetricIds,',');
                        String metricDefStri;
                        if(lstJoin.endsWith(',')){
                            metricDefStri = lstJoin.removeEnd(',');
                        }else{
                            metricDefStri = lstJoin;
                        }
                        asyncJobMetricValueCreation.Bast_Asset_Template_Ids__c  =  metricDefStri; 
                        asyncJobMetricValueCreation.Plant_Asset_Id__c = plantAssetId; 
                        asyncJobMetricValueCreation.Last_Process_Initiated_DT__c = lastPromptSaveId; 
                        asyncJobMetricValueCreation.Plant_Asset_Prompt_Detail_Id__c = plantAssetPromptDetailId; 
                        EventBus.publish(asyncJobMetricValueCreation);
                        batchMetricIds.clear();
                        batchSize = batchSize - 1;
                    }
                }
            }
        }
        //Weighted average rollup to higest parent prompt
        Asset_Builder_Async_Job__e asyncJobWeightedAvgCalc = new Asset_Builder_Async_Job__e(); 
        asyncJobWeightedAvgCalc.Job_Type__c = 'Weighted Average Rollup'; 
        asyncJobWeightedAvgCalc.Prompt_Information_Ids__c =  (promptInfoLst.size()>1) ? String.join(promptInfoLst,',') : String.valueOf(promptInfoLst[0]); 
        asyncJobWeightedAvgCalc.Plant_Asset_Id__c = plantAssetId; 
        asyncJobWeightedAvgCalc.Last_Process_Initiated_DT__c = lastPromptSaveId; 
        asyncJobWeightedAvgCalc.Plant_Asset_Prompt_Detail_Id__c = plantAssetPromptDetailId; 
        EventBus.publish(asyncJobWeightedAvgCalc);
    }
}