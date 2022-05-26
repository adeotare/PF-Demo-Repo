import { LightningElement, track, api, wire } from "lwc";
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import meessageOnRecordCount from '@salesforce/label/c.MeessageOnRecordCount';
import  countOfRecords from '@salesforce/label/c.CountOfRecords';

export default class PromptsParentComp extends LightningElement {
  @track promptFlow = {};
  @track attrHLValue;
  @api isBulkUpload;
  @api isBulkUploadMultipleBAT;
  @api isImpWizUpLoad;
  @api isOverride;
  @track isReadOnly;
  @api isOverrideBackUp = false;
  @api plantAssetRecordIdBackUp = '';

  @api plantAssetRecordId; // Pass plant asset record id for record Edit form  
  @api isLoading=false; // Show and Hide Spinner 
  @api previousPromptName;
  @api openedFromReport = false; 
  @api g1OpenFromFinishBtn = false;
  pageRef = 'Asset Builder'; 
  @track showAssetBuildPrompts = false;
  @track showAssetBuildReports = false;
  numberOfprompts = 30; // Total no of prompt child component
  promptId;
  @track totalNoOfRecords;
  @track messageOnLoad = false;
  @track setOfPromptNameLoadedAlready = new Set();
  @track isLoadingForAssetCreation = false;
  @track isLoadingForFectchingAssets = false;
  
  @api promptIdFromReport;
  // It helps to close the already opened prompt in asset builder tab and retain the current opened prompt value 
  // Defaulted to prompt1 as we have the goto report button in prompt1 which is G1
  openPromptId = 'prompt1'; 

  isBulkUpload = false;
  isBulkUploadMultipleBAT = false;
  isImpWizUpLoad = false;
  isOverride = false;
  plantName = '';
  plantAssetTEM = '';
  showPlantAssetDetail = false;

  connectedCallback() {
    registerListener('showspinnercomp', this.handleShowSpinnerPubSub, this); // this pubsub event listener is used from g1PromptActionButtons component  
    registerListener('redirectToG1Prompt', this.handleRedirectToG1Prompt, this); // to handle the finish button redirection to G1 prompt 
    registerListener('attrHLValueSelected', this.handleAttrHighlighterValChng, this); // to handle attribute highlighter.
    registerListener('setBulkImportVariable', this.setBulkImportVariable, this);// to handle multiple csv
    registerListener('setBulkImportVariableForMultipleBAT', this.setBulkImportVariableForMultipleBAT, this);// to handle multiple csv for Multiple BAT
    registerListener('showPlantAssetDetails', this.showPlantAssetDetails, this);// to handle multiple csv for Multiple BAT

    this.showAssetBuildPrompts = true;
    this.showAssetBuildReports = false;
    this.showPromptInfo(this.numberOfprompts, this.promptId);
    if(this.isOverride && this.isImpWizUpLoad){
      this.isOverrideBackUp = true;
      this.plantAssetRecordIdBackUp = this.plantAssetRecordId;
    }
  }

  // To show selected plant asset name and TEM version in all prompts 
  showPlantAssetDetails(eventDet){
    this.plantName = eventDet.plantAssetName;
    this.plantAssetTEM = eventDet.plantAssetTemVersion;
    this.showPlantAssetDetail = true;
  }

  handleRedirectToG1Prompt(eventDet){
    if(this.isImpWizUpLoad && !this.isBulkUpload && !this.isBulkUploadMultipleBAT){
      this.isOverrideBackUp = false;
      this.plantAssetRecordIdBackUp = '';
      this.isOverride = false;
      this.PromptNameLoadedAlreadyFunReset();
    }
    this.showPrompt(eventDet.promptId, this.previousPromptName, eventDet.plantAssetId, false);
  }
  handleAttrHighlighterValChng(eventDet){
    this.attrHLValue = eventDet;
  }

  showPromptInfo(numberOfprompts, promptId){
    let key;
    for (let i = 1; i <= numberOfprompts; i++) {
      key = "prompt" + i; // Key - dynamically calculated
      this.promptFlow[key] = i === 1;
    }
  }

  @api
  showPrompt(promptId, previousPapdIdEvt, plantAssetIdEvt, openedFromReport, g1OpenFromFinishBtn){
    this.previousPromptName = previousPapdIdEvt;
    this.plantAssetRecordId = plantAssetIdEvt;
    this.promptFlow[this.openPromptId] = false;
    this.promptFlow[promptId] = true;
    this.openPromptId = promptId;
    this.openedFromReport = openedFromReport;
    this.g1OpenFromFinishBtn = g1OpenFromFinishBtn;
  }

  handlePrevious(event) {
    var currentPromptId = event.detail.currentPromptId;
    this.promptFlow[currentPromptId] = false;
    var previousPromptId = event.detail.previousPromptId; // This value should come from apex logic
    this.promptFlow[previousPromptId] = true;
    this.plantAssetRecordId = event.detail.plantAssetId;
    this.previousPromptName = '';
    this.openPromptId = previousPromptId;
    let plantssetIdPromptIdConCatValue = this.plantAssetRecordId+'-'+previousPromptId;
    if((this.plantAssetRecordIdBackUp === this.plantAssetRecordId) 
      && this.isOverrideBackUp && this.isImpWizUpLoad){
      this.isOverride = this.setAndCheckPromptNameNotOverridenAlready(plantssetIdPromptIdConCatValue);
    }else if((this.plantAssetRecordIdBackUp !== this.plantAssetRecordId) 
      && this.isOverrideBackUp && this.isImpWizUpLoad){
      this.isOverride = false;
    }else{
      this.isOverride = false;
    }
  }

  setAndCheckPromptNameNotOverridenAlready(plantssetIdPromptIdConCatValue){
    let result = false;
    if(!this.setOfPromptNameLoadedAlready.has(plantssetIdPromptIdConCatValue)){
      this.setOfPromptNameLoadedAlready.add(plantssetIdPromptIdConCatValue);
      result =  true;
    }else if(this.setOfPromptNameLoadedAlready.has(plantssetIdPromptIdConCatValue)){
      result =  false;
    }
    return result;
  }

  PromptNameLoadedAlreadyFunReset(){
    this.setOfPromptNameLoadedAlready.clear();
  }

  handleNext(event) {
    var currentPromptId = event.detail.currentPromptId;
    this.promptFlow[currentPromptId] = false;
    var nextPromptId = event.detail.nextPromptId; // This value should come from apex logic
    this.promptFlow[nextPromptId] = true;
    this.plantAssetRecordId = event.detail.plantAssetId;
    this.previousPromptName = event.detail.previousPromptName;
    this.openPromptId = nextPromptId;
    this.isBulkUpload = event.detail.isBulkUpload;
    this.isBulkUploadMultipleBAT = event.detail.isBulkUploadMultipleBAT;
    this.isImpWizUpLoad = event.detail.isImpWizUpLoad;
    let plantssetIdPromptIdConCatValue = this.plantAssetRecordId+'-'+nextPromptId;
    if((this.plantAssetRecordIdBackUp === this.plantAssetRecordId) 
      && this.isOverrideBackUp && this.isImpWizUpLoad){
      this.isOverride = this.setAndCheckPromptNameNotOverridenAlready(plantssetIdPromptIdConCatValue);
    }else if((this.plantAssetRecordIdBackUp !== this.plantAssetRecordId) 
      && this.isOverrideBackUp && this.isImpWizUpLoad){
      this.isOverride = false;
    }else{
      this.isOverride = false;
    }
  }

  handleShowSpinnerPubSub(action){
    (action) ? this.handleShowSpinner() : this.handleHideSpinner();
  }

  handleShowSpinner(event){
    this.isLoading = true;
    this.isLoadingForAssetCreation = false;
    this.isLoadingForFectchingAssets = false;  
  } 

  handleShowSpinnerWithMessage(event){
    if(event.detail.eventMessage){
      if(event.detail.eventMessage === 'Please wait... asset creation process is running...'){
        this.isLoadingForAssetCreation = true;
        this.isLoadingForFectchingAssets = false;
        this.isLoading = false;
      }else if(event.detail.eventMessage === 'Please wait... fetching assets...'){
        this.isLoadingForAssetCreation = false;
        this.isLoadingForFectchingAssets = true;
        this.isLoading = false;
      }
    }
  }

  handleHideSpinner(event){
    this.isLoading = false;
    this.isLoadingForAssetCreation = false;
    this.isLoadingForFectchingAssets = false;
  }

  onLoadMessage(event){
    if(event.detail.recordCount > parseInt(countOfRecords)){
      this.totalNoOfRecords = event.detail.recordCount
      this.messageOnLoad = meessageOnRecordCount;
    }
  }

  disconnectedCallback(){
    unregisterAllListeners(this);
  }

  setBulkImportVariable(valueForBulkImport){
    this.isBulkUpload = valueForBulkImport;
  }

  setBulkImportVariableForMultipleBAT(valueForBulkImportMultipleBAT){
    this.isBulkUploadMultipleBAT = valueForBulkImportMultipleBAT;
  }
  
  handleReadOnlyConfirm(event){	
    this.isReadOnly = event.detail.confirmationOutput; //Event dispatched from G1 Prompt to decide upcoming prompts isReadOnly	
  }
}