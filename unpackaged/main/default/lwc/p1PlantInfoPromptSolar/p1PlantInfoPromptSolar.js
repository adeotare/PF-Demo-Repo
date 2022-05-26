import { LightningElement, track, api } from "lwc";
import getCustomDatatableCompInput from "@salesforce/apex/P1PlantInfoPromptSolar.getCustomDatatableCompInput";
import saveSiteMetadataRecords from "@salesforce/apex/P1PlantInfoPromptSolar.saveSiteMetadataRecords";
import findNextPromptId from "@salesforce/apex/P1PlantInfoPromptSolar.findNextPromptId";
import findPreviousPromptId from "@salesforce/apex/Utils.findPreviousPromptId";
import clearPromptInfo from "@salesforce/apex/P1PlantInfoPromptSolar.clearPromptInfo";
import clearMessage from '@salesforce/label/c.AssetBuilderClearPopupMessage';
import assetBuilderNextConfirmationMessage from '@salesforce/label/c.AssetBuilderNextConfirmationMessage';
import assetBuilderClearErrorMessage from '@salesforce/label/c.AssetBuilderClearErrorMessage';
import assetBuilderClearPromptInfoMessage from '@salesforce/label/c.AssetBuilderClearPromptInfoMessage';
import assetBuilderSuccessMessageOnSave from '@salesforce/label/c.AssetBuilderSuccessMessageOnSave';
import assetBuilderPreviousPromptErrorMessage from '@salesforce/label/c.AssetBuilderPreviousPromptErrorMessage';
import assetBuilderNextPromptErrorMessage from '@salesforce/label/c.AssetBuilderNextPromptErrorMessage';
import p1PlantInfoEnterNoOfBlocksIfFlatHierarchyIsNo from '@salesforce/label/c.P1PlantInfoEnterNoOfBlocksIfFlatHierarchyIsNo';
import p1PlantInfoChooseFlatHierarchy from '@salesforce/label/c.P1PlantInfoChooseFlatHierarchy';
import confirmationPopupTitleOnClear from '@salesforce/label/c.ConfirmationPopupTitleOnClear';
import confirmationPopupTitleOnNext from '@salesforce/label/c.ConfirmationPopupTitleOnNext';
import assetBuilderDeleteConfirmationMessage from '@salesforce/label/c.AssetBuilderDeleteConfirmationMessage';
import confirmationPopupTitleOnDelete from '@salesforce/label/c.ConfirmationPopUpTitleOnDelete';
import confirmationPopupTitleOnFinish from '@salesforce/label/c.ConfirmationPopupTitleOnFinish';
import assetBuilderFinishConfirmationMessage from '@salesforce/label/c.AssetBuilderFinishConfirmationMessage';
import reportRelatedFinishButtonInfoMsg from '@salesforce/label/c.ReportRelatedFinishButtonInfoMessage';
import findG1PromptId from "@salesforce/apex/Utils.findG1PromptId";
import {
  replaceOldAttrbuiteValueWithNewValue,
  deleteLogicMap,
  getModifiedMetadataRecordsArray,
  IsBooleanCheck,
  saveLogicMap,
  showToast,
  showAndHideSpinner,
  findOldValToNewValChanges,
  mapSiteMetadataIdWithCSVDataForP1AndW1,
  getcustomDataTable,
  showAndHideGoToG1PromptButton,
  buttonLabels,
  readCSVAndMapImportRecords
} from "c/utils";

export default class P1PlantInfoPromptSolar extends LightningElement {
  @api plantAssetId;//Plant Assset Id passed from the previous prompt
  @api previousPromptName;
  @api attrHlVal;
  @api isBulkUpload;
  @api isBulkUploadMultipleBAT;
  @api isImpWizUpLoad;
  @api isOverride;
  @api csvLines;
  @api siteMetadataRecordCountFromCSVImport;
  @api siteMetadataMap = new Map();
  @track recordIdAndAttrInfoMap;
  @track customDatatableInput;//site metadata from the prompt
  @track showConfirmPopupOnClear = false;
  @track clearMessage;
  @track onClickNextMessage;
  @track showConfirmPopupOnNext = false;
  @track showConfirmPopupOnDelete = false;
  @track plantAssetPromptDetail;
  @track promptInfoRecord;
  @api openedFromReport = false;
  @api ConfirmationModalTitle;
  @track showReCalcReportButton = false;
  @track showReCalcReportButtonInfoMessage = false;
  @track goToG1PromptButton = false;
  @track reportRelatedFinishButtonInfoMessage = '';
  @track buttonLabel = '';
  @track hideNextButtonForBulkImport = false;
  @track buttonLabelsObj = {};
  @track IsdeleteCSVCheck = false;
  @track callNextWithValidationForBulkImport = false;
  siteMetdaDataAttributeMap = new Map();
  saveSiteMetadataMap = new Map();
  siteMetadataIdToRecordDetails = new Map();
  findOldValToNewValChangesMap = new Map();
  jsonInputParametersAndValues={};
  isExecutedFromImportExport = false;

  label = {
    confirmationPopupTitleOnClear,
    confirmationPopupTitleOnFinish
  };
  @track onClickFinishMessage;
  @track showConfirmPopupOnFinish;

  /** 		
   * isReadOnly value passed from promptNavigator to decide isReadOnly for this Prompt(to hide btns) 		
   * and assetBuilderCustomDatatable(to make records readonly), Save fn should not call on click of Next and Previous buttons		
  */		
  @api isReadOnly; 		
  @track showSaveButton = false;		
  @track showClearButton = false;
  @track showPreviousButton = false;
  toastMessageMode = 'dismissable';

  connectedCallback() {
    if(this.openedFromReport){
      this.isBulkUpload = false;
      this.isBulkUploadMultipleBAT = false;
      this.isImpWizUpLoad = false;
      this.isOverride = false;
      this.showReCalcReportButton = true;
    }
    this.jsonInputParametersAndValues = {
      isBulkUpload : this.isBulkUpload.toString(),
      isBulkUploadMultipleBAT : this.isBulkUploadMultipleBAT.toString(),
      isImpWizUpLoad : this.isImpWizUpLoad.toString(),
      isOverride : this.isOverride.toString(),
    };
    this.buttonLabelsObj = buttonLabels();
    this.toastMessageMode = (this.isBulkUpload || this.isImpWizUpLoad) ? 'sticky' : this.toastMessageMode;
    this.buttonLabel = (this.isBulkUpload) ? this.buttonLabelsObj.saveAndResume : (this.isBulkUploadMultipleBAT) ? this.buttonLabelsObj.saveAndResume : this.buttonLabelsObj.next;
    showAndHideSpinner(this, 'showspinner');

    //To Hide Save and Clear button if IsBulkUpload true or IsReadOnly true else show btns if IsReadOnly false	
    this.showSaveButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : !this.isReadOnly;
    this.showClearButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : !this.isReadOnly;
    this.showPreviousButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : true;
    
  /**
   * to retrieve the sitemetadata records to display that as a vertical prompt
   * param1 plantAssetId 
   * param2 previousPromptName
   */
    getCustomDatatableCompInput({
      plantAssetId: this.plantAssetId,
      previousPromptName: this.previousPromptName,
      jsonInputParametersAndValues : JSON.stringify(this.jsonInputParametersAndValues)
    }).then(result => {
      if (result) {
        if(!this.isBulkUpload || !this.isImpWizUpLoad){
          showAndHideSpinner(this, 'hidespinner');
        }
        
        let inputData = JSON.parse(result);
        if (inputData.PlantAssetPromptDetail) {
          this.plantAssetPromptDetail = inputData.PlantAssetPromptDetail;
          if(showAndHideGoToG1PromptButton(this.plantAssetPromptDetail) && this.isBulkUpload){
            this.goToG1PromptButton = true;
          }
        }
        
        if (inputData.PromptInfo) {
          this.promptInfoRecord = inputData.PromptInfo;
        }

        if (inputData.SiteMetadataRecords) {
          var siteMetadataRecords = inputData.SiteMetadataRecords;
          
          for (var siteMetadataRecordKey in siteMetadataRecords) {
            let siteMetadataRecord = siteMetadataRecords[siteMetadataRecordKey];
            this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
          }
          
        }

        if(this.isImpWizUpLoad && this.isOverride){
          let csvStr = inputData.csvData
          if (csvStr !== 'No CSV Files Found') {
            
            let inputDataFromUtils;
            if (this.selectedAttrVal !== undefined) {
              inputDataFromUtils = getcustomDataTable(inputData, this.selectedAttrVal);
            } else {
              inputDataFromUtils = getcustomDataTable(inputData, 'None');
            }
            this.promptSiteMetadata = inputDataFromUtils.data;
            this.siteMetadataMap = inputDataFromUtils.siteMetadataMap;
            let csvStringObject = mapSiteMetadataIdWithCSVDataForP1AndW1(inputData.SiteMetadataRecords, inputData.csvData);
            let csvString = csvStringObject.csvString;
            this.siteMetadataRecordCountFromCSVImport = csvStringObject.sitemetaRecordCountInCSV;
            this.csvLines = csvString.split('\n');
            let mappedValuesForUI =  readCSVAndMapImportRecords(this.csvLines, this.siteMetadataMap, this.promptSiteMetadata, 'No Data', this.siteMetadataRecordCountFromCSVImport);
            if(!mappedValuesForUI.showGoToG1AndResumeButtonInPrompt){
              inputData.SiteMetadataRecords = mappedValuesForUI.siteMetadataArray;
              var siteMetadataRecords = mappedValuesForUI.SiteMetadataRecords;
              
              //replacing old map values with new values
              for (var siteMetadataRecordKey in siteMetadataRecords) {
                let siteMetadataRecord = siteMetadataRecords[siteMetadataRecordKey];
                this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
              }
              this.IsdeleteCSVCheck = mappedValuesForUI.isDelete;

            }else{
              this.isParentNameMisMatchInBulkImport = true;
              this.isDisableButton = true;
            }
          }
        }
        
        this.customDatatableInput = JSON.stringify(inputData);

        if(inputData.csvData && this.isBulkUpload && !this.isExecutedFromImportExport && !this.callNextWithValidationForBulkImport){
          let csvStr = inputData.csvData;
          if(csvStr !== 'No CSV Files Found'){
            let inputDataFromUtils;
            if(this.selectedAttrVal !== undefined){
              inputDataFromUtils = getcustomDataTable(inputData, this.selectedAttrVal);
            } else {
              inputDataFromUtils = getcustomDataTable(inputData, 'None');
            }
            this.promptSiteMetadata = inputDataFromUtils.data;
            this.siteMetadataMap = inputDataFromUtils.siteMetadataMap;
            let csvStringObject = mapSiteMetadataIdWithCSVDataForP1AndW1(inputData.SiteMetadataRecords, inputData.csvData);
            let csvString = csvStringObject.csvString;
            this.siteMetadataRecordCountFromCSVImport = csvStringObject.sitemetaRecordCountInCSV;
            this.csvLines = csvString.split('\n');
            this.template.querySelector("c-import-and-export-c-s-v").readCsvAndImportRecords('No Data', this.csvLines, this.siteMetadataMap, this.promptSiteMetadata, 'No Data', this.siteMetadataRecordCountFromCSVImport);
          }
        }
        
        if((this.isBulkUploadMultipleBAT || this.callNextWithValidationForBulkImport) && !this.isImpWizUpLoad){
          this.goToNext();
        }

        if(this.isBulkUpload || this.isImpWizUpLoad){
          showAndHideSpinner(this, 'hidespinner');
        }
      }
    }).catch(error => {
      if (error) {
        showToast(this, error.body.message, 'Error', 'error');
      }
    });
  }

  /**
   * Custom validation will not run on previous, when user comes to the prompt for the first time,
   * if the user navigate to the next prompt and once come back to the current prompt, custom validation will run on on click of Previous button
  */
  goToPrevious(event){
    let isValid = true;
    if(this.plantAssetPromptDetail.Validate_On_Previous__c){
      isValid = this.validation();
    }
    let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true: this.IsdeleteCSVCheck;
    if(isValid){
      if(IsdeleteBooleanCheck && !this.isReadOnly){
        this.ConfirmationModalTitle = confirmationPopupTitleOnDelete;
        this.onClickNextMessage = ((typeof this.promptInfoRecord.Confirm_Message_On_Delete__c === 'undefined')) ? assetBuilderDeleteConfirmationMessage : this.promptInfoRecord.Confirm_Message_On_Next__c;
        this.showConfirmPopupOnDelete = true;
      } else {
        this.handlePreviousOnConfirm(event, true);
      }
    }  
  }
  

  handlePreviousOnConfirm(event, executeDeleteLogic) {
    let allowDeleteLogic = (executeDeleteLogic) ? executeDeleteLogic : event.detail.confirmationOutput;
    if (allowDeleteLogic ) {
      showAndHideSpinner(this, 'showspinner');
      let modifiedMetadataRecords = [];
      modifiedMetadataRecords = getModifiedMetadataRecordsArray(
        this.siteMetadataIdToRecordDetails
      );
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true: this.IsdeleteCSVCheck;
      let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true: false;
      let addtionalParamsForPrevious = {isReadOnly: this.isReadOnly};
      /*
       * to find the previous Prompt id 
       * param1 PlantAssetId (Plant Asset Id)
       * param2 siteMetadataRecordsToSave (SiteMetadata records)
       * param3 promptInfo (Prompt Information)
       * param4 isKeyToGenerateRows (it set to true if there is decrease in count of records)
       * attrValueChanged (if any change occured in the prompt the 'attrValueChanged' is set to true)
      */
      findPreviousPromptId({
        plantAssetId: this.plantAssetId,
        siteMetadataRecordsToSave: JSON.stringify(modifiedMetadataRecords),
        promptInfo: JSON.stringify(this.promptInfoRecord),
        isKeyToGenerateRows: IsdeleteBooleanCheck,
        attrValueChanged: attrValueChangeCheck,
        addtionalParamsForPrevious: JSON.stringify(addtionalParamsForPrevious),
        finalBatchBoolean: true,
      }).then(result => {
        showAndHideSpinner(this, 'hidespinner');
        var previousPromptFinderRes = JSON.parse(result);
        if (previousPromptFinderRes.previousPromptId) {
          this.dispatchEvent(
            new CustomEvent("previous", {
              detail: {
                action: "previous",
                currentPromptId: previousPromptFinderRes.currentPromptId,
                previousPromptId: previousPromptFinderRes.previousPromptId,
                plantAssetId: previousPromptFinderRes.plantAssetId,
              }
            })
          );
        } else {
          showToast(this, assetBuilderPreviousPromptErrorMessage, 'Error', 'error');
        }
      }).catch(error => {
        if (error) {
          showToast(this, error.body.message, 'Error', 'error');
        }
      });
    }else{
      showAndHideSpinner(this, 'hidespinner');
      this.showConfirmPopupOnDelete = false;
    }
  }

  //clicking on next button this function will be called
  goToNext(event){
   if (this.validation()) {
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true: this.IsdeleteCSVCheck;
      if(IsdeleteBooleanCheck && !this.isBulkUpload && !this.isReadOnly && !this.isBulkUploadMultipleBAT){
        this.ConfirmationModalTitle = confirmationPopupTitleOnDelete;
        this.onClickNextMessage = ((typeof this.promptInfoRecord.Confirm_Message_On_Delete__c === 'undefined')) ? assetBuilderDeleteConfirmationMessage : this.promptInfoRecord.Confirm_Message_On_Delete__c;
        this.showConfirmPopupOnNext = true;
      }else if(this.promptInfoRecord.Show_Popup_On_Next_Button__c && !this.isBulkUpload && !this.isReadOnly && !this.isBulkUploadMultipleBAT){
        this.ConfirmationModalTitle = confirmationPopupTitleOnNext;
        this.onClickNextMessage = ((typeof this.promptInfoRecord.Confirm_Message_On_Next__c === 'undefined')) ? assetBuilderNextConfirmationMessage : this.promptInfoRecord.Confirm_Message_On_Next__c;
        this.showConfirmPopupOnNext = true;
      }else{
        this.hanldeNextOnConfirm(event, true);
      }
    }
  }
 
  // based on confirmation Output it will allow the next Logic
  hanldeNextOnConfirm(event, executeNextLogic) {
    let allowNextLogic = (executeNextLogic) ? executeNextLogic : event.detail.confirmationOutput;
    if (allowNextLogic) {
      showAndHideSpinner(this, 'showspinner');
      let modifiedMetadataRecords = [];
      modifiedMetadataRecords = getModifiedMetadataRecordsArray(
        this.siteMetadataIdToRecordDetails
      );
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true: this.IsdeleteCSVCheck;
      let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true: 
                                  this.isBulkUpload ? true : this.isImpWizUpLoad;
      let additionalParamsForNext = {isReadOnly: this.isReadOnly};	
      /*
       *to find the next Prompt id
       *@param PlantAssetId
       *param siteMetadataRecordsToSave (SiteMetadata records)
       *param isKeyToGenerateRows (it set to true if there is decrease in count of records)
       *param attrValueChanged (it become true if the existing attribute values are changed)
      */
      findNextPromptId({
        plantAssetId: this.plantAssetId,
        siteMetadataRecordsToSave: JSON.stringify(modifiedMetadataRecords),
        isKeyToGenerateRows: IsdeleteBooleanCheck,
        attrValueChanged: attrValueChangeCheck,
        additionalParamsForNext: JSON.stringify(additionalParamsForNext),
        finalBatchBoolean: true,
      }).then(result => {
        showAndHideSpinner(this, 'hidespinner');
        var nextPromptFinderRes = JSON.parse(result);
        if (nextPromptFinderRes.nextPromptId) {
          this.dispatchEvent(
            new CustomEvent("next", {
              detail: {
                action: "next",
                currentPromptId: nextPromptFinderRes.currentPromptId,
                nextPromptId: nextPromptFinderRes.nextPromptId,
                plantAssetId: nextPromptFinderRes.plantAssetId,
                previousPromptName: nextPromptFinderRes.plantAssetPromptDetailId,
                isBulkUpload: this.isBulkUpload,
                isBulkUploadMultipleBAT: this.isBulkUploadMultipleBAT,
                isImpWizUpLoad : this.isImpWizUpLoad,
                isOverride : this.isOverride,
              }
            })
          );
        } else {
          showToast(this, assetBuilderNextPromptErrorMessage, 'Error', 'error');
        }
      }).catch(error => {
        if (error) {
          showToast(this, error.body.message, 'Error', 'error');
        }
      });
    } else {
      this.showConfirmPopupOnNext = false;
    }
  }

  // Any change of value in the prompt is tracked here for the further process
  handleAttrValueChange(event) {
    var siteMetadataRecordId = event.detail.siteMetadataRecordId;
    var attributeName = event.detail.attrDetails.attributeName;
    var newAttributeValue = event.detail.attrDetails.newAttributeValue;
    var oldAttributeValue = event.detail.attrDetails.oldAttributeValue;
    var isPromptSpecificAttr = event.detail.attrDetails.isPromptSpecificAttr;
    var keyFieldToGenerateRowCheckValue = event.detail.attrDetails.keyFieldToGenerateRowCheckValue;
    var attributeDataType = event.detail.attrDetails.attributeDataType;

    this.siteMetadataIdToRecordDetails = replaceOldAttrbuiteValueWithNewValue(
      this.siteMetadataIdToRecordDetails,
      siteMetadataRecordId,
      isPromptSpecificAttr,
      attributeName,
      newAttributeValue
    );
    this.siteMetdaDataAttributeMap = deleteLogicMap(
      this.siteMetdaDataAttributeMap,
      siteMetadataRecordId,
      newAttributeValue,
      oldAttributeValue,
      attributeName,
      attributeDataType,
      keyFieldToGenerateRowCheckValue
    );
    this.saveSiteMetadataMap = saveLogicMap(
      this.saveSiteMetadataMap,
      newAttributeValue, 
      oldAttributeValue, 
      siteMetadataRecordId, 
      attributeName
    );

    if(keyFieldToGenerateRowCheckValue){
      this.findOldValToNewValChangesMap = findOldValToNewValChanges(
        this.findOldValToNewValChangesMap,
        siteMetadataRecordId,
        newAttributeValue,
        oldAttributeValue,
        attributeName,
        attributeDataType,
        keyFieldToGenerateRowCheckValue
      );
      
      if(this.openedFromReport){
        if(IsBooleanCheck(this.findOldValToNewValChangesMap)){
          this.showReCalcReportButton = false;
          this.showReCalcReportButtonInfoMessage = true;
          this.reportRelatedFinishButtonInfoMessage = reportRelatedFinishButtonInfoMsg;
        }else{
          this.showReCalcReportButtonInfoMessage = false;
          this.showReCalcReportButton = true;
        }
      }
    }
  }

  // To validate the Unique and mandatory fields in the siteMetadata
  validation() {
    let noOfBlocks = 0;
    let flatHierarchyIsNo = false;
    let flatHierarchyIsNull = false;
    let noOfBlocksCheck = true;

    this.siteMetadataIdToRecordDetails.forEach((value, key) => {
      let siteMetadataRecordDetail = this.siteMetadataIdToRecordDetails.get(key);
      let attrInfoJSON = siteMetadataRecordDetail.Prompt_Specific_Info__c;
      JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
        if (attrJSONKey === 'Flat Hierarchy' && attrJSONValue === 'No') {
          flatHierarchyIsNo = true;
        }
        if (attrJSONKey === 'Flat Hierarchy' && (attrJSONValue === '--None--' || (!attrJSONValue))) {
          flatHierarchyIsNull = true;
        }
        if (attrJSONKey === 'No of Blocks') {
          if (attrJSONValue) {
            noOfBlocks = parseInt(attrJSONValue, 10);
          }
        }
      });
    });

    if (flatHierarchyIsNull) {
      showAndHideSpinner(this, 'hidespinner');
      showToast(this, p1PlantInfoChooseFlatHierarchy, 'Error', 'error', this.toastMessageMode);
      noOfBlocksCheck = false;
    } else if (flatHierarchyIsNo && noOfBlocks <= 0) {
      showAndHideSpinner(this, 'hidespinner');
      showToast(this, p1PlantInfoEnterNoOfBlocksIfFlatHierarchyIsNo, 'Error', 'error', this.toastMessageMode);
      noOfBlocksCheck = false;
    }

    if(!noOfBlocksCheck && (this.isBulkUpload || this.isImpWizUpLoad)){
      this.hideNextButtonForBulkImport = true;
    }
    return noOfBlocksCheck;
  }

  //Passes the Modified site metadata record from the prompt,plantAssetId to the prompt Controller
  saveSiteMetadata(event) {
    let isValid = true;
    if(this.plantAssetPromptDetail.Validate_On_Previous__c){
      isValid = this.validation();
    }

    if(isValid){
      showAndHideSpinner(this, 'showspinner');
      let modifiedMetadataRecords = [];
      modifiedMetadataRecords = getModifiedMetadataRecordsArray(
        this.siteMetadataIdToRecordDetails
      );
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true: this.IsdeleteCSVCheck;
      let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : 
                                  this.isBulkUpload ? true : this.isImpWizUpLoad;
      saveSiteMetadataRecords({
        siteMetadataRecordsToSave: JSON.stringify(modifiedMetadataRecords),
        plantAssetId: this.plantAssetId,
        isKeyToGenerateRows: IsdeleteBooleanCheck,
        attrValueChanged: attrValueChangeCheck,
        finalBatchBoolean: true,
      }).then(result => {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this, assetBuilderSuccessMessageOnSave, 'Info', 'success');
      }).catch(error => {
        showAndHideSpinner(this, 'hidespinner');
        if (error) {
          showToast(this, error.body.message, 'Error', 'error');
        }
      });
    }
  }
  //on click of clear ,call this function
  clearSiteMetadata() {
    this.clearMessage = clearMessage;
    this.showConfirmPopupOnClear = true;
  }

  /* Clears the attriute info and prompt specific info field in the sitemetadata record
   * param1 PlantAssetID
   * param2 previousPromptName
  */
  handleClear(event) {
    if (event.detail.confirmationOutput) {
      this.customDatatableInput = undefined;
      this.siteMetdataIdToRecordDetails = new Map();
      showAndHideSpinner(this, 'showspinner');

      clearPromptInfo({
        plantAssetId: this.plantAssetId,
        previousPromptName: this.previousPromptName
      }).then(result => {
        if (result !== 'false') {
          this.customDatatableInput = result;
          this.IsdeleteCSVCheck = false;
          var inputData = JSON.parse(this.customDatatableInput);
          var siteMetadataRecords = inputData.SiteMetadataRecords;

          for (var siteMetadataRecordKey in siteMetadataRecords) {
            let siteMetadataRecord = siteMetadataRecords[siteMetadataRecordKey];
            this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
          }

          if (inputData.PlantAssetPromptDetail) {
            this.plantAssetPromptDetail = inputData.PlantAssetPromptDetail;
          }    

          if (inputData.PromptInfo) {
            this.promptInfoRecord = inputData.PromptInfo;
          } 
          this.showConfirmPopupOnClear = false;
          showAndHideSpinner(this, 'hidespinner');
          showToast(this, assetBuilderClearPromptInfoMessage, 'Info', 'success');
        }
      }).catch(error => {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this, assetBuilderClearErrorMessage, 'Error', 'error');
      });
    } else {
      this.showConfirmPopupOnClear = false;
    }
  }

  nextForBulkImport(event) {
    if (event.detail.callNextForBulkImport && (this.isBulkUpload || this.isImpWizUpLoad)) {
      this.callNextWithValidationForBulkImport = true;
      this.customDatatableInput = '';
      this.connectedCallback();
    }
  }

  refreshOnImport(event){
    if (event.detail.refreshDatatable) {
      this.isExecutedFromImportExport = true;
      this.customDatatableInput = '';
      this.connectedCallback();
    }
  }

  /**
   * This method is used to show or hide Finish, Resume and finish Button for Bulk Import
   */
  showOrHideGoToG1AndResumeButton(event){
    if (event.detail.showGoToG1AndResumeButtonInPrompt) {
      if(this.showReCalcReportButton){
        this.showReCalcReportButton = false;
      }
      this.hideNextButtonForBulkImport = true;
    }
  }

  spinnerInImport(event){
    this.isSpinner = event.detail.spinnerVal;
  }

  //Click of Finish button, saves the prompt values to the site metadata record,and displays the finish confirmation dialog to proceed further
  goToFinish(event) {
    showAndHideSpinner(this, 'showspinner');

    if (this.validation()) {
      if(!this.isReadOnly){
        let modifiedMetadataRecords = [];
        modifiedMetadataRecords = getModifiedMetadataRecordsArray(
          this.siteMetadataIdToRecordDetails
        );
        let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : 
                                this.isBulkUpload ? true : this.isImpWizUpLoad;
        saveSiteMetadataRecords({
          siteMetadataRecordsToSave: JSON.stringify(modifiedMetadataRecords),
          plantAssetId: this.plantAssetId,
          isKeyToGenerateRows: false,
          attrValueChanged: attrValueChangeCheck,
          finalBatchBoolean: true,
        }).then(result => {
          showAndHideSpinner(this, 'hidespinner');
        }).catch(error => {
          showAndHideSpinner(this, 'hidespinner');
          if (error) {
            showToast(this, error.body.message, 'Error', 'error');
          }
        });
        this.onClickFinishMessage = assetBuilderFinishConfirmationMessage;
        this.showConfirmPopupOnFinish = true;  
      }else{
        findG1PromptId({
        }).then(result => {
          let eventDet = {
            plantAssetId : this.plantAssetId,
            promptId : result
          }
          fireEvent(this.pageRef, 'redirectToG1Prompt', eventDet);
        });   
      }  
    }
  }

  hanldeFinishOnConfirm(event) {
    this.showConfirmPopupOnFinish = false; 
  }
}