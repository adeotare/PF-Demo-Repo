import { LightningElement, track, api, wire } from 'lwc';
import checkPlantAssetPromptDetail from "@salesforce/apex/G1PromptActionButtons.checkPlantAssetPromptDetail";
import checkABStatusOfPlantAsset from "@salesforce/apex/G1InitialPlantInfoPromptRefresh.checkABStatusOfPlantAsset";
import refreshG1SiteMetaData from "@salesforce/apex/G1InitialPlantInfoPromptRefresh.refreshG1SiteMetaData";
import callLocationAPI from "@salesforce/apex/AssetBuilderLocationAPI.callLocationAPIfromLWC";
import fetchPlantAssetDetails from "@salesforce/apex/WeightedAverageRollUpModalPopUp.plantAssetDetails";
import { fireEvent } from 'c/pubsub';
import { showToast } from 'c/utils';
import assetBuilderStatusClosedMessage from '@salesforce/label/c.AssetBuilderStatusClosedMessage';
import weightedAverageRollUpNotCalculated from '@salesforce/label/c.WeightedAverageRollUpNotCalculated';
import weightedAverageRollUpInfoMessage from '@salesforce/label/c.WeightedAverageRollUpInfoMessage';
import readOnlyPromptInfoMessage from '@salesforce/label/c.ReadOnlyPromptInfoMessage';
import assetBuilderProcessNotStartedForWeightedAvgRollUp from '@salesforce/label/c.AssetBuilderProcessNotStartedForWeightedAvgRollUp';
import reportGenerationInProgress from '@salesforce/label/c.ReportGenerationInProgress';
import reportGenerationNotStarted from '@salesforce/label/c.ReportGenerationNotStarted';
import errorInReportGeneration from '@salesforce/label/c.ErrorInReportGeneration';
import assetBuilderProcessNotStarted from '@salesforce/label/c.AssetBuilderProcessNotStarted';
import morethanOneRecordInPAPD from '@salesforce/label/c.MorethanOneRecordInPAPD';
import createPEForRFI from "@salesforce/apex/TriggerPEForRFICreation.createPEForRFI";
import g1InitialPlantInfoPromptRefreshTitle from '@salesforce/label/c.G1InitialPlantInfoPromptRefreshTitle';
import g1InitialPlantInfoPromptRefreshPopupMsg from '@salesforce/label/c.G1InitialPlantInfoPromptRefreshPopupMsg';
import g1InitialPlantInfoPromptRefreshSuccessMsg from '@salesforce/label/c.G1InitialPlantInfoPromptRefreshSuccessMsg';
import g1InitialPlntInfoPmtRefreshABNotInProgressMsg from '@salesforce/label/c.G1InitialPlntInfoPmtRefreshABNotInProgressMsg';
import noCustomPermissionMessage from '@salesforce/label/c.NoCustomPermissionMessage';
import checkSiteMetadataRecord from "@salesforce/apex/ExportAssetBuilderPromptsTemplate.checkSiteMetadataRecord";
import updateG1Prompt from "@salesforce/apex/ExportAssetBuilderPromptsTemplate.updateG1Prompt";
import bulkExportAssetBuilderSuccessMessage from '@salesforce/label/c.bulkExportAssetBuilderSuccessMessage';
import bulkExportAssetBuilderErrorMessage from '@salesforce/label/c.bulkExportAssetBuilderErrorMessage';
import renewableTypeIsNotConfigured from '@salesforce/label/c.renewableTypeIsNotConfigured';
import titleForABTemplateExport from '@salesforce/label/c.titleForABTemplateExport';
import assetBuilderConditionNotMet from '@salesforce/label/c.assetBuilderConditionNotMet';
import reportExportSuccessMessage from '@salesforce/label/c.ReportExportSuccessMessage';
import hasDownloadCSVCstmPermission from '@salesforce/customPermission/AB_DownloadCSVCustomPermission';
import hasGenerateRFICstmPermission from '@salesforce/customPermission/AB_GenerateRFICustomPermission';
import hasDownloadMetadataPerm from '@salesforce/customPermission/AB_DownloadMetadataCsv';
import getG1RecordDetails from "@salesforce/apex/G1BulkImportButtonHndlr.getG1RecordDetails";
import g1ABProcessstartedMessage from '@salesforce/label/c.g1ABProcessstartedMessage';
import g1BulkImportNoSiteMetadataMessage from '@salesforce/label/c.g1BulkImportNoSiteMetadataMessage';
import selectPlantAsset from '@salesforce/label/c.selectPlantAsset';
import setSubmitForApproval from  "@salesforce/apex/AssetBuilderApprovalHandler.setSubmitForApproval";
import AB_AP_SubmittedAlreadyForApprovalMessage from '@salesforce/label/c.AB_AP_SubmittedAlreadyForApprovalMessage';
import hasSubmitRecallPermission from '@salesforce/customPermission/AB_ApprovalRequestSubmitRecall_Custom_Permission';

export default class G1PromptActionButtons extends LightningElement {
  pageRef = 'Asset Builder'; 
  @api promptInfo;
  @api selectedPlantAssetId = '';
  @track hideGotoButton = false;
  @track hideExportButton =  false;
  @track popUpMessage = '';
  @track showExportConfirmPopupMsg = false;
  @track abTemplatetitle = titleForABTemplateExport;
  @track createg1Prompt = false;
  @track renewableTypeSet = new Set();
  @track xlsHeader = [];
  @track workSheetNameList = []; 
  @track xlsData = []; 
  @track filename ; 
  @track saveFile;
  @track loadXlsxMain = false;
  @track excelInputValue;
  @track m1PromptName;
  @track s1PromptName;
  @track showDownloadCSV = false;
  @track showUpdateMetadataCSV = false;
  @track showWeightedAvgRollUpButton = false;
  @track showWeightedAvgModalPopUp = false;

/* Show RFI Generation Button**/
  @track showRFIBtn = false;
  /* *For Refresh button*/
  @api showRefresh;
  @track plantId;
  @track showConfirmPopupMsg = false; 
  label = {
    g1InitialPlantInfoPromptRefreshTitle,
    g1InitialPlantInfoPromptRefreshPopupMsg,
    g1InitialPlantInfoPromptRefreshSuccessMsg,
    g1InitialPlntInfoPmtRefreshABNotInProgressMsg
  };
  @track showUpload = false;// For Showing upload file Component for Bulk Import
  @api title = '';//Title for comments box popup
  @track isApprovalSubmitted = false;// Show or Hide comments popup for approval.
  @track showSubmitBtn = false;//Show/hide submit button in comments popup
  @track showSubmitForApprovalBtn = false;//Show/hide Submit for approval button based on status
  @track showRecallBtn = false;//Show/Hide recall button inside popup 
  @track showRecallApprovalBtn = false; //Show/Hide recall Approval button in g1
  @track showHierarchyButton = false;
  @api showBtnDropdown = false;
  @api showUploadMetadata = false;// To Show upload file Component for Metadata Import
  parentComp = this;
  selectedPlantAssetIdABAId = '';

  connectedCallback() {
    if(this.selectedPlantAssetId !== 'None' && typeof this.selectedPlantAssetId !== 'undefined'){
      this.showBtnDropdown = true;
      this.hideGotoButton = true;
      this.hideExportButton = true;
      this.showHierarchyButton = true;
      this.showWeightedAvgRollUpButton = true;
      if(hasDownloadCSVCstmPermission){
        this.showDownloadCSV = true;
      }
      if(hasDownloadMetadataPerm){
        this.showUpdateMetadataCSV = true;
      }
      if(hasGenerateRFICstmPermission){
        this.showRFIBtn = true
      }
      this.showSubmitRecallBtn();//Show or Hide Submit and recall button based on Permission and status
    }else{
      this.showBtnDropdown = false;
      this.hideGotoButton = false;
      this.hideExportButton = false;
      this.showDownloadCSV = false;
      this.showRFIBtn = false;  
      this.showHierarchyButton = false;
      this.showUpdateMetadataCSV = false;
      this.showWeightedAvgRollUpButton = false;
    }
  }

  viewReportEventPub(){  
    if(this.selectedPlantAssetId.length > 0){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      
      checkPlantAssetPromptDetail({
        plantAssetId: this.selectedPlantAssetId,
        promptInfo: JSON.stringify(this.promptInfo),
      })
      .then(result => {
        if(result !== 'No Data'){
          let papdRes = JSON.parse(result);
          if(papdRes.length === 1){
            if((papdRes[0].Account_Plant__r.Asset_Builder_Status__c !== 'Completed') && (papdRes[0].Account_Plant__r.Asset_Builder_Status__c !== 'Closed')){
              showToast(this, assetBuilderProcessNotStarted, 'Info', 'info');
            }else if(papdRes[0].Capability_Report_Status__c === 'Completed' && papdRes[0].Completeness_Report_Status__c === 'Completed'){
              let eventDet = {
                plantAssetId : this.selectedPlantAssetId
              }
              fireEvent(this.pageRef, 'showReportComponent', eventDet);
            }else if(papdRes[0].Capability_Report_Status__c === 'In Progress' && papdRes[0].Completeness_Report_Status__c === 'In Progress'){
              showToast(this, reportGenerationInProgress, 'Info', 'info');
            }else if(papdRes[0].Capability_Report_Status__c === 'Not Yet Started' && papdRes[0].Completeness_Report_Status__c === 'Not Yet Started'){
              showToast(this, reportGenerationNotStarted, 'Info', 'info');
            }else if(papdRes[0].Capability_Report_Status__c === 'Completed - Error' && papdRes[0].Completeness_Report_Status__c === 'Completed - Error'){
              showToast(this, errorInReportGeneration, 'Info', 'info');
            }
          }else if(papdRes.length === 0){
            showToast(this, assetBuilderProcessNotStarted, 'Info', 'info');
          }else if(papdRes.length > 1){
            showToast(this, morethanOneRecordInPAPD, 'Info', 'info');
          }
          fireEvent(this.pageRef, 'showspinnercomp', false);
        }else{
          showToast(this, assetBuilderProcessNotStarted, 'Info', 'info');
          fireEvent(this.pageRef, 'showspinnercomp', false);
        }
      })
      .catch(error => { 
        showToast(this, error.body.message, 'Error', 'error');   
        fireEvent(this.pageRef, 'showspinnercomp', false);
      });
    }
  }

  handleHierarchyBtnClick(){
    if(typeof this.selectedPlantAssetId != 'undefined'){
      let eventDet = {
        plantAssetId : this.selectedPlantAssetId
      }
      fireEvent(this.pageRef, 'showHierarchyComponent', eventDet);
    }
  }

  fetchLocation () {
      fireEvent(this.pageRef, 'showspinnercomp', true);
      callLocationAPI({
          plantAssetID : this.selectedPlantAssetId,
          locationAPIfromLWC : true,
        })
        .then(response => {
          let locationResponse = response.true;
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, locationResponse, 'Success', 'Success');
        }).catch(error => {
          if (error) {
            fireEvent(this.pageRef, 'showspinnercomp', false);
            showToast(this, error, 'Error', 'error');
          }
        });
  }

  @api
  getSelectPlantAssetId(planAssetIdVal){
    if(planAssetIdVal !== 'None'){
      this.showBtnDropdown = true;
      this.hideGotoButton = true;
	    this.hideExportButton = true;
      this.showHierarchyButton = true;
      this.showWeightedAvgRollUpButton = true;
      this.selectedPlantAssetId = planAssetIdVal;
      //To Enable DownloadCSV button, if the user has the custom permission
      if(hasDownloadCSVCstmPermission){
        this.showDownloadCSV = true; 
      }
      // To Enable metadata download
      if(hasDownloadMetadataPerm){
        this.showUpdateMetadataCSV = true;
      }
      // To Enable Generate RFI button, If the user has permission.
      if(hasGenerateRFICstmPermission){
        this.showRFIBtn = true;
      }
      //Show/hide submit and recall button in g1 based on permission and status
      this.showSubmitRecallBtn();
    }else{
      this.showBtnDropdown = false;
      this.hideGotoButton = false;
	    this.hideExportButton = false;
      this.selectedPlantAssetId = undefined;
      this.showDownloadCSV = false; //To Hide the DownloadCSV btn if the selected plantassetId is none
      this.showRFIBtn = false;
      this.showSubmitForApprovalBtn = false;
      this.showRecallApprovalBtn = false;
      this.showHierarchyButton = false;
      this.showUpdateMetadataCSV = false;
      this.showWeightedAvgRollUpButton = false;
    }
  }

  csvGeneration(){
    if(this.selectedPlantAssetId.length <= 0){
      showToast(this, 'Please compelete the asset builder process for CSV Generation', 'Info', 'info');
    }else{
      fireEvent(this.pageRef, 'showspinnercomp', true);
      this.template.querySelector("c-c-s-v-generation").downloadCSVFile(this.selectedPlantAssetId);
    }
  }

  downloadAbMetadataCsv(){
    if(this.selectedPlantAssetId.length <= 0){
      showToast(this, 'Please compelete the asset builder process for CSV Generation', 'Info', 'info');
    }else{
      //fireEvent(this.pageRef, 'showspinnercomp', true);
      this.template.querySelector("c-download-ab-metadata-csv").downloadAbMetadataCsv(this.selectedPlantAssetId);
    }
  }

  uploadAbMetadataCsv(){
    this.showUploadMetadata = true;
  }

  /**For RFI and RFI Item generation */
  rfiGeneration(){
    if(typeof this.selectedPlantAssetId != 'undefined'){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      createPEForRFI({ 
        plantAssetId : this.selectedPlantAssetId
      })
      .then(response => {
        let resultantValue = response.split("&");
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this, resultantValue[0], resultantValue[1], resultantValue[1].toLowerCase());
      }).catch(error => {
        if (error) {
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, error, 'Error', 'error');
        }
      });
    }
  }

 //To check Asset Builder status of plant asset on click of Refresh button 
  handleRefreshBtnClick(){
    if(typeof this.selectedPlantAssetId != 'undefined'){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      checkABStatusOfPlantAsset({
        plantAssetId : this.selectedPlantAssetId
      })
      .then(result => {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        if(result){
          this.showConfirmPopupMsg = true;
        }else{
          showToast(this, this.label.g1InitialPlntInfoPmtRefreshABNotInProgressMsg, 'Info', 'info');
        }
      })      
    }
  }

  //To update G1, P1, W1 Site meta data with latest Plant Asset Values on confirm  of Refresh confirmation popup
  handleConfirm(event){
    if(event.detail.confirmationOutput){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      
      if(typeof this.selectedPlantAssetId != 'undefined'){
        refreshG1SiteMetaData({
          plantAssetId : this.selectedPlantAssetId
        })
        .then(result => { 
          if(result){   
            fireEvent(this.pageRef, 'showspinnercomp', false);
            this.showConfirmPopupMsg = false;                     
            showToast(this, this.label.g1InitialPlantInfoPromptRefreshSuccessMsg, 'Success', 'success');
            fireEvent(this.pageRef, 'refreshG1', this.selectedPlantAssetId);
          }
        })
        .catch(error => {
          fireEvent(this.pageRef, 'showspinnercomp', false);
          this.showConfirmPopupMsg = false;
          showToast(this, error.body.message, 'Error', 'error');          
        });
      }
    }else{
      this.showConfirmPopupMsg = false;
      this.showUpload = false;
      this.isApprovalSubmitted = false;
    }
  }

  fetchplantAssetStatus(){
    if(typeof this.selectedPlantAssetId == 'undefined'){
      showToast(this, selectPlantAsset , 'Info', 'Info');
    }else if(this.selectedPlantAssetId != undefined){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      fetchPlantAssetDetails({
        plantAssetId : this.selectedPlantAssetId
      }).then( result => {
        if(result == 'Read Only Prompts'){
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, readOnlyPromptInfoMessage, 'Info', 'info');
        }else if(result == 'Closed'){
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, assetBuilderStatusClosedMessage, 'Info', 'info');
        }else if(result == 'weighted Average Not calculated'){
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, weightedAverageRollUpNotCalculated, 'Info', 'info');
        }else if(result == 'open Modal Popup'){
          fireEvent(this.pageRef, 'showspinnercomp', false);
          this.showWeightedAvgModalPopUp = true;
        }else if(result == 'rollup is for Solar Prompts'){
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, weightedAverageRollUpInfoMessage, 'Info', 'info');
        }else{
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, assetBuilderProcessNotStartedForWeightedAvgRollUp, 'Info', 'info');
        }
      }).catch(error => {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this, error.body.message, 'Error', 'error');          
      });
    }
  }

  handleImportButton(){
	//If No Plant Asset is Selected.
    if(typeof this.selectedPlantAssetId == 'undefined'){
      showToast(this, selectPlantAsset , 'Info', 'Info');
    }
    else if(this.selectedPlantAssetId != undefined){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      getG1RecordDetails({
        plantAssetId : this.selectedPlantAssetId
      })
     .then( result => {
       //If Plant Asset is newly Created.
        if(result == 'isNewPlant'){
          showToast(this, g1BulkImportNoSiteMetadataMessage, 'Info', 'info');
          fireEvent(this.pageRef, 'showspinnercomp', false);
        }
        //If Asset Builder Process starts.(Entered into few prompts)
        else if(result == 'buildStarted'){
          showToast(this, g1ABProcessstartedMessage, 'Info', 'info');
          fireEvent(this.pageRef, 'showspinnercomp', false);
        }
        //If a Plant Asset has Only G1.
        else if(result == 'enableBulkImportButton'){
          fireEvent(this.pageRef, 'showspinnercomp', false);
          this.showUpload = true;//Show upload File Component for plant Asset having only G1 Plant Asset Prompt Detail.
        }
      })
      .catch(error => {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this, error.body.message, 'Error', 'error');          
      });
    }
  }
  
  /**	
   * Check If the g1 record already exist	
   * if yes, update the g1 record and call the handleExportCLick()	
   * or call the handleExportClick()	
  **/	
  handleUpdateCheck(){	
    if(typeof this.selectedPlantAssetId != 'undefined'){	
      updateG1Prompt({	
        plantAssetId : this.selectedPlantAssetId	
      })	
      .then(result => {	
        if(result){	
          this.dispatchEvent(	
            new CustomEvent("g1recordcreation", {	
              detail: {	
                updateG1Record: true,	
              }	
            })	
          );	
        }else{	
          this.handleExportClick();	
        }	
      })	
    }	
  }

  /** 
   * Export Asset Builder prompts template related to the plant asset record or G1 SiteMetadata Prompt.
   * On click of Export button in the component,  @param {loadXlsxMain} is set to false, to avoid duplicating data in the excel sheet on multiple excel export
  */
  @api
  handleExportClick(){
    this.xlsHeader.length = 0;
    this.workSheetNameList.length = 0;
    this.xlsData.length = 0;
    this.filename = '';
    this.loadXlsxMain = false;
    fireEvent(this.pageRef, 'showspinnercomp', true);
    if(typeof this.selectedPlantAssetId != 'undefined'){
      checkSiteMetadataRecord({
        plantAssetId : this.selectedPlantAssetId
      })
      .then(result => {
        var checkResult = JSON.parse(result);
        this.m1PromptName = checkResult['m1PromptName'];
        this.s1PromptName = checkResult['s1PromptName'];
        /**
         * Check the status of the Asset Builder Status field of Plant Asset record
         * Check whether p1 site metadata record available
         * Check whether the renewable type of custom metadata and the plant asset's or g1 site metadata's renewable type is matched
         * If it meets, all the above condition and if g1 site metadata is not available, create a event for g1 record and calls the exportSiteMetadata. 
         * If it meets, all the above condition and if G1 site metadata is available, it calls exportSiteMetadata.
         */
        if(!checkResult.hasOwnProperty('AssetBuilderStatusCheck')){
          if(!checkResult.hasOwnProperty('assetBuilderProcessExist')){
            if(!checkResult.hasOwnProperty('RenewableTypesForBulkUpload')){
              if(checkResult.hasOwnProperty('g1SiteMedataRecord') && checkResult.hasOwnProperty('Attributes')){
                this.excelInputValue = JSON.parse(checkResult['Attributes']);
                var plantAssetRecord = checkResult['plantAssetRecord'];
                this.plantId = plantAssetRecord['Customer_Plant_Asset_ID__c'];
                if(checkResult['g1SiteMedataRecord']){
                  this.exportSiteMetadata(true, true);
                }
                else{
                  this.dispatchEvent(
                    new CustomEvent("g1recordcreation", {
                      detail: {
                        fromExportButton: true,
                      }
                    })
                  );
                }
              }
            }
            else{
              fireEvent(this.pageRef, 'showspinnercomp', false);
              showToast(this, renewableTypeIsNotConfigured, 'Error', 'error');
            }
          }
          else{
            fireEvent(this.pageRef, 'showspinnercomp', false);
            showToast(this, bulkExportAssetBuilderErrorMessage, 'Error', 'error');
          }
        }else{
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, assetBuilderConditionNotMet, 'Error', 'error');
        }
      })
    }
  }

  /**
   * Iterate the prompt & core attribute of every prompt and form an array of object
   * @param {xlsHeader} - store header for the xlsx sheet
   * @param {workSheetNameList} - store worksheet name 
   * @param {xlsData} - store xlsx sheet data 
   */
  @api
  exportSiteMetadata(metMastCount, switchgearsSubstationCount){
    fireEvent(this.pageRef, 'showspinnercomp', false);
    var valueMap = new Map();
    for (const [key, value] of Object.entries(this.excelInputValue)){
      var objKey = key;
      let sheetName = [];
      let inputData = this.excelInputValue[key];
      var promptSpecificattrLst = inputData.promptSpecificattribute;
      for (var promptSpecificattrkey in promptSpecificattrLst) {
        let promptSpecificRecord = promptSpecificattrLst[promptSpecificattrkey];
        let attrInfoJSON = promptSpecificRecord['Prompt_Information__r'];
        sheetName = attrInfoJSON['Name']; 
      }
      /* Querying Core Attribute for all prompt information for the tempalte.If g1 record is created by export button, we are removing the metmast and 
      switchgear prompt from the template if there is no metmast or switchgear count*/
      if((sheetName.includes(this.m1PromptName) && !metMastCount)){
        delete this.excelInputValue[objKey];
      }else if(sheetName.includes(this.s1PromptName) && !switchgearsSubstationCount){
        delete this.excelInputValue[objKey];
      }
    }

    for(let value in this.excelInputValue){
      let inputData;
      if(this.excelInputValue[value] !== 'undefined'){
        inputData = this.excelInputValue[value];
      }
      var coreAttrLst = inputData.coreAttribute;
      var promptSpecificattrLst = inputData.promptSpecificattribute;
      var dataTypeObj ={};
      var attributeType ={};
      var customerFacingNotesObj ={};
      var isUnique = {};
      var reference= {};
      var aliasName = {};
      var arrayObject =[];
      let promptInfo = {};
      let attrInfo = {};
      let recordId ={};
      var sheetName;

      recordId['Core Attribute API Name'] = null;
      dataTypeObj['Core Attribute API Name'] = 'Data Type';
      attributeType['Core Attribute API Name'] = 'Attribute Type';
      customerFacingNotesObj['Core Attribute API Name'] = 'Customer Facing Notes';
      isUnique['Core Attribute API Name'] = 'Is Unique';
      reference['Core Attribute API Name'] = 'Reference';
      aliasName['Core Attribute API Name'] ='Alias Name';

      for (var promptSpecificattrkey in promptSpecificattrLst) {
        let promptSpecificRecord = promptSpecificattrLst[promptSpecificattrkey];
        let attrMasterRecord = promptSpecificRecord['Attribute_Master__r'];
        let attrInfoJSON = promptSpecificRecord['Prompt_Information__r'];
        sheetName = attrInfoJSON['Name'].replaceAll('/','-').substring(0, 31); 
        promptInfo[attrMasterRecord['Name']] = null;
        dataTypeObj[attrMasterRecord['Name']] = attrMasterRecord['Data_Type__c'];
        attributeType[attrMasterRecord['Name']] = 'Prompt Attribute';
        let attrMasterCustomerFacingNotes;
        let attributeCustomerFacingNotes;

        if(attrMasterRecord['Customer_Facing_Notes__c']){
          let customerFacingNote = attrMasterRecord['Customer_Facing_Notes__c'].replace( /[\r\n]+/gm, "" );
          attrMasterCustomerFacingNotes = customerFacingNote.replaceAll('"', '`');
        }

        if(promptSpecificRecord['Customer_Facing_Notes__c']){
          let customerFacingNote  = promptSpecificRecord['Customer_Facing_Notes__c'].replace( /[\r\n]+/gm, "" );
          attributeCustomerFacingNotes = customerFacingNote.replaceAll('"', '`');
        }

        customerFacingNotesObj[attrMasterRecord['Name']] = 
                        (attrMasterRecord['Customer_Facing_Notes__c']) ? attrMasterCustomerFacingNotes : (promptSpecificRecord['Customer_Facing_Notes__c']) ? attributeCustomerFacingNotes:'';
        isUnique[attrMasterRecord['Name']] = promptSpecificRecord.Is_Unique__c;
        aliasName[attrMasterRecord['Name']] = attrMasterRecord['Alias__c'];
        let plantAssetFieldName = promptSpecificRecord.hasOwnProperty('Plant_Asset_Field_Name__c');

        if(promptSpecificRecord.Is_Asset_Name__c){
          reference[attrMasterRecord['Name']] = 'Asset Name';
        }
        else if(promptSpecificRecord.Is_Parent_Asset__c){
          reference[attrMasterRecord['Name']] = 'Parent Asset';
        }
        else if(promptSpecificRecord.Is_Alternate_Parent__c){
          reference[attrMasterRecord['Name']] = 'Alternate Parent Asset';
        }else if(promptSpecificRecord.Is_Read_Only__c && !promptSpecificRecord.Is_Parent_Asset__c
            && plantAssetFieldName == false){
          reference[attrMasterRecord['Name']] = 'readOnly';
        }
        else{
          reference[attrMasterRecord['Name']] = 'rowGenAttribute';
        }
      }

      for (var CoreAttributekey in coreAttrLst) {
        let coreAttributeRecord = coreAttrLst[CoreAttributekey];
        let attrMasterRecord = coreAttributeRecord['Attribute_Master__r'];
        attrInfo[attrMasterRecord['Name']] = null;
        dataTypeObj[attrMasterRecord['Name']] = attrMasterRecord['Data_Type__c'];
        attributeType[attrMasterRecord['Name']] = 'CoreAttribute';
        customerFacingNotesObj[attrMasterRecord['Name']] = 
                    (attrMasterRecord['Customer_Facing_Notes__c']) ? attrMasterRecord['Customer_Facing_Notes__c'] : (coreAttributeRecord['Customer_Facing_Notes__c']) ? (coreAttributeRecord['Customer_Facing_Notes__c']):'';
        isUnique[attrMasterRecord['Name']] = (coreAttributeRecord.Is_Unique__c) ? coreAttributeRecord.Is_Unique__c :'FALSE';
        aliasName[attrMasterRecord['Name']] = attrMasterRecord['Alias__c'];
        reference[attrMasterRecord['Name']] = (attrMasterRecord['Alias__c'] === 'Subarray Name') ? 'SFID' : 'Value';
      }

      let obj = {...recordId,...promptInfo, ...attrInfo};
      arrayObject.push(obj);  
      valueMap.set(sheetName, arrayObject);
      arrayObject.splice(0,0,dataTypeObj);
      arrayObject.splice(1,0,attributeType);
      arrayObject.splice(2,0,customerFacingNotesObj);
      arrayObject.splice(3,0,isUnique);
      arrayObject.splice(4,0,reference);
      arrayObject.splice(5,0,aliasName);
    }

    for (const [key, value] of valueMap) {
      this.xlsFormatter(value, key);
    }
    var today = new Date();
    var date = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
    var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();
    this.filename = this.plantId +' '+ 'UploadSiteMetadata' +' '+ date +' '+ time +'.xlsx'; 
    this.showExportConfirmPopupMsg = true;
    this.popUpMessage = bulkExportAssetBuilderSuccessMessage;
  }

  /**
   * 
   * @param {data}  - Data of the excel worksheet 
   * @param {sheetName}  - Sheet names of the worksheet
   */
  xlsFormatter(data, sheetName) {
    let Header = Object.keys(data[0]);
    this.xlsHeader.push(Header);
    this.workSheetNameList.push(sheetName);
    this.xlsData.push(data);
    this.saveFile = false;
    this.loadXlsxMain = true;
  }

  /**
   * On click of proceed in the confirmation modal, this function is called.
   * If, confirmationOutput is true, download function of xlsx main component is called
   * if no, showExportConfirmPopupMsg is set to false, which will close the confirmation modal.
   */
  handleExportConfirm(event){
    if(event.detail.confirmationOutput){
      this.template.querySelector("c-xlsx-main").download();
    }
    else{
      this.showExportConfirmPopupMsg = false;
    }
  }

  /**
   * On successful export of ABPromptTemplate Xlsx file, closes the confirmation modal box and a success toast message appears
  */
  handleFileSuccess(event){
    this.showExportConfirmPopupMsg = false;
    showToast(this, reportExportSuccessMessage, 'Info', 'success');
  }

  /**
   *  Handler Method for Submit-for-approval button in G1
   */
  submitApprovalHandler(){
    if(this.selectedPlantAssetId != undefined){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      this.showSubmitBtn = true;//Show submit button inside comments popup
      this.showRecallBtn = false;
      setSubmitForApproval({
        plantAssetId : this.selectedPlantAssetId
      }).then(resultVar => {
        let result = JSON.parse(resultVar);
        fireEvent(this.pageRef, 'showspinnercomp', false);
         if(result.status === 'Submitted'){
          this.showRecallApprovalBtn = true;
          this.showSubmitForApprovalBtn = false;
          showToast(this,AB_AP_SubmittedAlreadyForApprovalMessage, 'Info', 'Info');  
        }
        else{
          //Hide submit for approval button and show recall approval button in g1 Prompt
          this.isApprovalSubmitted = true;
          this.title = 'Submit for Approval';
          this.showRecallApprovalBtn = false;
          this.showSubmitForApprovalBtn = true;
        }
      })
      .catch(error => {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this,error.body.message, 'Error', 'error');          
      });
    }
  }

  /**
   *  Handler Method forrecall-approval button in G1 
   */
  recallApprovalHandler(){
    if(this.selectedPlantAssetId != undefined){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      this.showSubmitBtn = false;
      this.showRecallBtn = true;
      setSubmitForApproval({
        plantAssetId : this.selectedPlantAssetId
      }).then(resultVar => {
        let result = JSON.parse(resultVar);
        fireEvent(this.pageRef, 'showspinnercomp', false);
        if(result.status === 'Submitted'){
          this.showRecallApprovalBtn = true;
          this.showSubmitForApprovalBtn = false;
          this.title = 'Recall Approval';
          this.isApprovalSubmitted = true;
        }
        else{
          this.showRecallApprovalBtn = false;
          this.showSubmitForApprovalBtn = true;
          this.isApprovalSubmitted = true;          
        }
      })
      .catch(error => {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this,error.body.message, 'Error', 'error');          
      });
    }
  }

  /**
   * On click of proceed in the confirmation modal, this function is called.
   * If, submitRecall is submit, Hide submit button , show recall button, close comments box popup
   *  If, submitRecall is recall, Hide recall button, show submit button, close comments box popup
   *  If, submitRecall is cancel, Hide both button and comments box popup
   */
  handleSubmitConfirm(event){
    if(event.detail.submitRecall == 'Submit'){
      if(this.selectedPlantAssetId != undefined){
        this.showRecallApprovalBtn = true;
        this.showSubmitForApprovalBtn = false;
        this.isApprovalSubmitted = false;
        this.dispatchEvent(	
          new CustomEvent("showandhidesaveandnextbutton", {	
            detail: {	
              isReadOnly: true,
              showSave: false,
              isInputFieldDisabled: true,
              showNext: true
            }	
          })	
        );
      }
    }
    else if(event.detail.submitRecall == 'Recall'){
      this.showRecallApprovalBtn = false;
      this.showSubmitForApprovalBtn = true;
      this.isApprovalSubmitted = false;
      this.dispatchEvent(	
        new CustomEvent("showandhidesaveandnextbutton", {	
          detail: {	
            isReadOnly: false,
            showSave: true,
            isInputFieldDisabled: false,
            showNext: true
          }	
        })	
      );
    }
    else if(event.detail.submitRecall == 'Cancel'){
      this.isApprovalSubmitted = false;
    }
  }

  /**
   * This method is used to check the permission for showing/hiding submit for approval and recall button
   */
  showSubmitRecallBtn(){
    if(this.selectedPlantAssetId != undefined){
      if(hasSubmitRecallPermission){
        setSubmitForApproval({
          plantAssetId : this.selectedPlantAssetId
        }).then(resultVar => {
          let result = JSON.parse(resultVar);
          fireEvent(this.pageRef, 'showspinnercomp', false);
          if(result.status === 'showSubmitButton'){
            //Show submit button only if the Asset Builder Status = 'Completed' , AB Approval Status = null,AB Approval Status = 'Rejected'
            this.showRecallApprovalBtn = false;
            this.showSubmitForApprovalBtn = true;
          }
          else if(result.status === 'Submitted'){
            //Show recall button only if the Approval status = submitted
            this.showRecallApprovalBtn = true;
            this.showSubmitForApprovalBtn = false;
          }
          else{
            //Hide both buttons
            this.showRecallApprovalBtn = false;
            this.showSubmitForApprovalBtn = false;
          }

          if(result.abaRec){
            this.selectedPlantAssetIdABAId = result.abaRec.Id;
          }
        })
        .catch(error => {
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this,error.body.message, 'Error', 'error');          
        });
      }
    }
  }

  closeweightedAvgModaPopUp(event){
    if(event.detail.closeModalPopup){
      this.showWeightedAvgModalPopUp = false;
    }
  }
}