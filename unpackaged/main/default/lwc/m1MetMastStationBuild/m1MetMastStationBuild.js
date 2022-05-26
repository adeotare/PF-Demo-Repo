import { LightningElement, track, api, wire } from "lwc";
import getCustomDatatableCompInput from "@salesforce/apex/M1MetMastStationBuild.getCustomDatatableCompInput";
import saveSiteMetadataRecords from "@salesforce/apex/M1MetMastStationBuild.saveSiteMetadataRecords";
import clearPromptInfo from "@salesforce/apex/M1MetMastStationBuild.clearPromptInfo";
import findNextPromptId from "@salesforce/apex/M1MetMastStationBuild.findNextPromptId";
import clearMessage from '@salesforce/label/c.AssetBuilderClearPopupMessage';
import assetBuilderExceptionMessage from '@salesforce/label/c.AssetBuilderExceptionMessage';
import assetBuilderSuccessMessageOnSave from '@salesforce/label/c.AssetBuilderSuccessMessageOnSave';
import dataClearedSuccessMessage from '@salesforce/label/c.AssetBuilderClearPromptInfoMessage';
import dataClearedErrorsMessage from '@salesforce/label/c.AssetBuilderClearErrorMessage';
import getConfirmationMessageOnNext from "@salesforce/apex/Utils.getConfirmationMessageOnNext";
import assetBuilderNextConfirmationMessage from '@salesforce/label/c.AssetBuilderNextConfirmationMessage';
import m1AStationNameIsBlankMsg from '@salesforce/label/c.M1AStationNameIsBlankMsg';
import confirmationPopupTitleOnClear from '@salesforce/label/c.ConfirmationPopupTitleOnClear';
import confirmationPopupTitleOnNext from '@salesforce/label/c.ConfirmationPopupTitleOnNext';
import assetNameAndAltParentErrMsg from '@salesforce/label/c.AssetNameAndAltParentErrMsg';
import assetNameErrMsg from '@salesforce/label/c.assetNameErrMsg';
import alternateParentErrMsg from '@salesforce/label/c.alternateParentErrMsg';
import findPreviousPromptId from "@salesforce/apex/Utils.findPreviousPromptId";
import assetBuilderDeleteConfirmationMessage from '@salesforce/label/c.AssetBuilderDeleteConfirmationMessage';
import confirmationPopupTitleOnDelete from '@salesforce/label/c.ConfirmationPopUpTitleOnDelete';
import attrCountAndStationErrMsg from '@salesforce/label/c.AttrCountAndStationErrMsg';
import attrCountValidationMessage from '@salesforce/label/c.AttrCountValidationMessage';
import confirmationPopupTitleOnFinish from '@salesforce/label/c.ConfirmationPopupTitleOnFinish';
import assetBuilderFinishConfirmationMessage from '@salesforce/label/c.AssetBuilderFinishConfirmationMessage';
import reportRelatedFinishButtonInfoMsg from '@salesforce/label/c.ReportRelatedFinishButtonInfoMessage';
import uniqueNameValidation from '@salesforce/label/c.UniqueNameValidation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';
import findG1PromptId from "@salesforce/apex/Utils.findG1PromptId";
import {
  replaceOldAttrbuiteValueWithNewValue,
  getModifiedMetadataRecordsArray,
  showToast,
  deleteLogicMap,
  IsBooleanCheck,
  saveLogicMap,
  showAndHideSpinner,
  isEmptyOrSpaces,
  findOldValToNewValChanges,
  mapSiteMetadataIdWithCSVDataWithoutParent,
  getcustomDataTable,
  showAndHideGoToG1PromptButton,
  buttonLabels,
  uniqueNameValidationFun,
  readCSVAndMapImportRecords,
  replaceOldAttrbuiteValueWithNewValueForUpdate
} from "c/utils";

export default class M1AMetMastStationBuild extends LightningElement {
  @api plantAssetId;
  @api customDatatableInput;
  @api openedFromReport = false;
  @api previousPromptName;
  @api ConfirmationModalTitle;
  @api promptInfoRecord;
  @api promptSiteMetadata
  @api attrHlVal;
  @api isBulkUpload;
  @api isBulkUploadMultipleBAT;
  @api isImpWizUpLoad;
  @api isOverride;
  @api csvLines;
  @api siteMetadataRecordCountFromCSVImport;
  @api siteMetadataMap = new Map();
  @track showConfirmPopupOnClear = false;
  @track clearMessage;
  @track isDisableButton;
  @track onClickNextMessage;
  @track showConfirmPopupOnNext = false;
  @track plantAssetPromptDetail;
  @track showConfirmPopupOnDelete = false;
  @track showReCalcReportButton = false;
  @track showReCalcReportButtonInfoMessage = false;
  @track reportRelatedFinishButtonInfoMessage = '';
  @track onClickFinishMessage;
  @track showConfirmPopupOnFinish;
  @track showImportAndExportButton = false;
  @track goToG1PromptButton = false;
  @track buttonLabel = '';
  @track buttonLabelsObj = {};
  @track IsdeleteCSVCheck = false;
  /** 	
   * isReadOnly value passed from promptNavigator to decide isReadOnly for this Prompt(to hide btns) 	
   * and assetBuilderCustomDatatable(to make records readonly), Save fn should not call on click of Next	
  */	
  @api isReadOnly; 	
  @track showSaveButton = false;	
  @track showClearButton = false;
  @track showPreviousButton = false;
  pageRef = 'Asset Builder';
  jsonInputParametersAndValues={};
  isExecutedFromImportExport = false;
  callNextForBulkImportWithoutValidation = false;

  
  saveSiteMetadataMap = new Map();
  siteMetdaDataAttributeMap = new Map();
  siteMetadataIdToRecordDetails = new Map();
  siteMetadataIdToRecordDetailsForUpdate = new Map();
  findOldValToNewValChangesMap = new Map();

  label = {
    confirmationPopupTitleOnClear,
    confirmationPopupTitleOnFinish
  };
  @track isParentNameMisMatchInBulkImport = false;
  toastMessageMode = 'dismissable';
  showUniqueNameToastMessage = true;

  connectedCallback() {
    if (this.openedFromReport) {
      this.isBulkUpload = false;
      this.isBulkUploadMultipleBAT = false;
      this.showReCalcReportButton = true;
      this.isImpWizUpLoad = false;
      this.isOverride = false;
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
    registerListener('getDataFromAssetDataTable', this.handleExportComponent, this);
    this.isDisableButton = false;
    showAndHideSpinner(this, 'showspinner');

    //To Hide Save and Clear button if isReadOnly true	
    this.showSaveButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : !this.isReadOnly;
    this.showClearButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : !this.isReadOnly;
    this.showPreviousButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : true;

    getCustomDatatableCompInput({
      plantAssetId: this.plantAssetId,
      previousPromptName: this.previousPromptName,
      jsonInputParametersAndValues : JSON.stringify(this.jsonInputParametersAndValues)
    }).then(result => {
      showAndHideSpinner(this, 'hidespinner');
      if (result) {
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
        var siteMetadataRecords = inputData.SiteMetadataRecords;

        for (var siteMetadataRecordKey in siteMetadataRecords) {
          let siteMetadataRecord = siteMetadataRecords[siteMetadataRecordKey];
          this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
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
            let csvStringObject = mapSiteMetadataIdWithCSVDataWithoutParent(inputData.SiteMetadataRecords, inputData.csvData);
            let csvString = csvStringObject.csvString;
            this.siteMetadataRecordCountFromCSVImport = csvStringObject.sitemetaRecordCountInCSV;
            this.csvLines = csvString.split('\n');
            let mappedValuesForUI =  readCSVAndMapImportRecords(this.csvLines, this.siteMetadataMap, this.promptSiteMetadata, 'No Data', this.siteMetadataRecordCountFromCSVImport);
            if(!mappedValuesForUI.showGoToG1AndResumeButtonInPrompt){
              inputData.SiteMetadataRecords = mappedValuesForUI.siteMetadataArray;
              var siteMetadataRecords = mappedValuesForUI.siteMetadataArray;
              
              //replacing old map values with new values
              for (var siteMetadataRecordKey in siteMetadataRecords) {
                let siteMetadataRecord = siteMetadataRecords[siteMetadataRecordKey];
                this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
                this.siteMetadataIdToRecordDetailsForUpdate.set(siteMetadataRecord.Id, siteMetadataRecord);
              }
              this.IsdeleteCSVCheck = mappedValuesForUI.isDelete;

            }else{
              this.isParentNameMisMatchInBulkImport = true;
              this.isDisableButton = true;
            }
          }
        }
        
        this.customDatatableInput = JSON.stringify(inputData);

        if(inputData.csvData && this.isBulkUpload && !this.isExecutedFromImportExport && !this.callNextForBulkImportWithoutValidation){
          let csvStr = inputData.csvData
          if(csvStr !== 'No CSV Files Found'){
            let inputDataFromUtils;
            if(this.selectedAttrVal !== undefined){
              inputDataFromUtils = getcustomDataTable(inputData, this.selectedAttrVal);
            } else {
              inputDataFromUtils = getcustomDataTable(inputData, 'None');
            }
            this.promptSiteMetadata = inputDataFromUtils.data;
            this.siteMetadataMap = inputDataFromUtils.siteMetadataMap;
            let csvStringObject = mapSiteMetadataIdWithCSVDataWithoutParent(inputData.SiteMetadataRecords, inputData.csvData);
            let csvString = csvStringObject.csvString;
            this.siteMetadataRecordCountFromCSVImport = csvStringObject.sitemetaRecordCountInCSV;
            this.csvLines = csvString.split('\n');
            this.template.querySelector("c-import-and-export-c-s-v").readCsvAndImportRecords('No Data', this.csvLines, this.siteMetadataMap, this.promptSiteMetadata, 'No Data', this.siteMetadataRecordCountFromCSVImport);
          }
        }

        if((this.isBulkUploadMultipleBAT || this.callNextForBulkImportWithoutValidation) && !this.isImpWizUpLoad){
          this.goToNext();
        }
      }
    }).catch(error => {
      showAndHideSpinner(this, 'hidespinner');
      if (error) {
        showToast(this, error.body.message, 'Error', 'error');
      }
    });
  }

  handleExportComponent(eventData){
    this.promptSiteMetadata = eventData;
    if(this.promptSiteMetadata !== undefined)
      this.showImportAndExportButton = this.isReadOnly ? false : true;
  }

  refreshOnImport(event) {
    if (event.detail.refreshDatatable) {
      this.isExecutedFromImportExport = true;
      this.customDatatableInput = '';
      this.connectedCallback();
    }
  }

  nextForBulkImport(event) {
    if (event.detail.callNextForBulkImport && (this.isBulkUpload || this.isImpWizUpLoad)) {
      if (event.detail.isAssetNameNotUnique || event.detail.isAltParentNotMatch) {
        this.isExecutedFromImportExport = true;
        this.customDatatableInput = '';
        this.connectedCallback();
        if (event.detail.isAssetNameNotUnique && event.detail.isAltParentNotMatch) {
          showToast(this, event.detail.duplicateCheckArray+'  ' + assetNameAndAltParentErrMsg, 'Error', 'error', this.toastMessageMode);
        } else if (event.detail.isAssetNameNotUnique) {
          showToast(this, event.detail.duplicateCheckArray+'  ' + assetNameErrMsg, 'Error', 'error', this.toastMessageMode);
        } else {
          showToast(this, alternateParentErrMsg, 'Error', 'error', this.toastMessageMode);
        }
      } else {
        this.callNextForBulkImportWithoutValidation = true;
        this.customDatatableInput = '';
        this.connectedCallback();
      }
    }
  }

  /**
   * This method is used to show or hide Finish, Resume and finish Button for Bulk Import
   */
  showOrHideGoToG1AndResumeButton(event){
    if (event.detail.showGoToG1AndResumeButtonInPrompt) {
      this.isParentNameMisMatchInBulkImport = true;
      this.isDisableButton = true;
    }
  }

  spinnerInImport(event){
   this.isSpinner = event.detail.spinnerVal;
  }

  handleAttrValueChange(event) {
    var siteMetadataRecordId = event.detail.siteMetadataRecordId;
    var attributeName = event.detail.attrDetails.attributeName;
    var newAttributeValue = event.detail.attrDetails.newAttributeValue;
    var oldAttributeValue = event.detail.attrDetails.oldAttributeValue;
    var isPromptSpecificAttr = event.detail.attrDetails.isPromptSpecificAttr;
    var keyFieldToGenerateRowCheckValue = event.detail.attrDetails.keyFieldToGenerateRowCheckValue;
    var attributeDataType = event.detail.attrDetails.attributeDataType;
    var uniqueValidationColName = event.detail.attrDetails.uniqueValidationColName;
    var attributeHeaderAndUOM = event.detail.attrDetails.attributeHeaderAndUOM;

    if(!this.isExecutedFromImportExport && !this.isParentNameMisMatchInBulkImport){
      uniqueNameValidationFun(uniqueValidationColName, attributeHeaderAndUOM, this);
    }
    this.siteMetadataIdToRecordDetails = replaceOldAttrbuiteValueWithNewValue(
      this.siteMetadataIdToRecordDetails,
      siteMetadataRecordId,
      isPromptSpecificAttr,
      attributeName,
      newAttributeValue
    );

    this.siteMetadataIdToRecordDetailsForUpdate = replaceOldAttrbuiteValueWithNewValueForUpdate(
      this.siteMetadataIdToRecordDetails,
      siteMetadataRecordId,
      isPromptSpecificAttr,
      attributeName, 
      newAttributeValue,
      this.siteMetadataIdToRecordDetailsForUpdate
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

  validation() {
    let isValid = true;
    var attrValueCheck = false;
    var count = 0;
    var uniqueValueCheck = true;
    var allValues = [];
    this.siteMetadataIdToRecordDetails.forEach((value, key) => {
      let siteMetadataRecordDetail = this.siteMetadataIdToRecordDetails.get(key);
      let attrInfoJSON = siteMetadataRecordDetail.Prompt_Specific_Info__c;
      JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
        if (attrJSONKey === 'Station Name') {
          if (isEmptyOrSpaces(attrJSONValue)) {
            isValid = false;
          }
          let parsedAttrValue = attrJSONValue.trim();
          if (!(isEmptyOrSpaces(parsedAttrValue))) {
            if (!(allValues.includes(parsedAttrValue))) {
              allValues.push(parsedAttrValue);
            } else {
              uniqueValueCheck = false;
              showAndHideSpinner(this, 'hidespinner');
              showToast(this, uniqueNameValidation + '    ' + parsedAttrValue, 'Error', 'error', this.toastMessageMode);
            }
          }
        } else {
          let parsedAttrValue = attrJSONValue;
          if (parsedAttrValue !== '' && !(isNaN(parsedAttrValue)) && parsedAttrValue > 0) {
            count = count + 1;
            if (count > 0) {
              attrValueCheck = true;
            }
          }
        }
      });
    });

    if(uniqueValueCheck){
      if (isValid && attrValueCheck) {
        return true;
      } else if (isValid && !attrValueCheck) {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this, attrCountValidationMessage  , 'Error', 'error', this.toastMessageMode);
        return false;
      } else if (!isValid && attrValueCheck) {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this, m1AStationNameIsBlankMsg, 'Error', 'error', this.toastMessageMode);
        return false;
      } else if (!isValid && !attrValueCheck) {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this, attrCountAndStationErrMsg, 'Error', 'error', this.toastMessageMode);
        return false;
      }
    }else{
      return false;
    }
  }

  handleSave() {
    showAndHideSpinner(this, 'showspinner');
    let modifiedMetadataRecords = [];
    if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
      modifiedMetadataRecords = getModifiedMetadataRecordsArray(
        this.siteMetadataIdToRecordDetailsForUpdate
      );
    }
    let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true : this.IsdeleteCSVCheck;
    let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : 
                                this.isBulkUpload ? true : this.isImpWizUpLoad;
    let isValid = true;
    if (this.plantAssetPromptDetail.Validate_On_Previous__c) {
      isValid = this.validation();
    }
    if (isValid) {
      if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
        let chunk = 100;
        var count = 0;
        var finalBatch = 0;
        if (modifiedMetadataRecords.length % 100 == 0) {
          finalBatch = modifiedMetadataRecords.length / 100;
        }
        for (var batchCount = 0; batchCount < modifiedMetadataRecords.length; batchCount += chunk) {
          var tempArray = [];
          count = count + 1;
          tempArray = modifiedMetadataRecords.slice(batchCount, batchCount + chunk);
          if (tempArray.length == 100) {
            if (finalBatch > 0 && (finalBatch == count)) {
              saveSiteMetadataRecords({
                siteMetadataRecordsToSave: JSON.stringify(tempArray),
                plantAssetId : this.plantAssetId,
                isKeyToGenerateRows: IsdeleteBooleanCheck,
                attrValueChanged: attrValueChangeCheck,
                finalBatchBoolean: true,
              }).then(result => {
                if (result) {
                  showAndHideSpinner(this,'hidespinner');
                  showToast(this,assetBuilderSuccessMessageOnSave,'Info','success');
                }
              }).catch(error => {
                let errorMessage;
                if(error){
                  errorMessage =error.body.message;
                  showAndHideSpinner(this, 'hidespinner');
                  showToast(this,errorMessage,'Error','error');
                }
              });
              //finalBatchBoolean = true;
            } else {
              saveSiteMetadataRecords({
                siteMetadataRecordsToSave: JSON.stringify(tempArray),
                plantAssetId : this.plantAssetId,
                isKeyToGenerateRows: IsdeleteBooleanCheck,
                attrValueChanged: attrValueChangeCheck,
                finalBatchBoolean: false,
              }).then(result => {
                console.log('Batch Check in save');
              }).catch(error => {
              });
            }
          } else if (tempArray.length < 100) {
            saveSiteMetadataRecords({
              siteMetadataRecordsToSave: JSON.stringify(tempArray),
              plantAssetId : this.plantAssetId,
              isKeyToGenerateRows: IsdeleteBooleanCheck,
              attrValueChanged: attrValueChangeCheck,
              finalBatchBoolean: true,
            }).then(result => {
              if (result) {
                showAndHideSpinner(this,'hidespinner');
                showToast(this,assetBuilderSuccessMessageOnSave,'Info','success');
              }
            }).catch(error => {
              let errorMessage;
              if(error){
                errorMessage =error.body.message;
                showAndHideSpinner(this, 'hidespinner');
                showToast(this,errorMessage,'Error','error');
              }
            });
            //finalBatchBoolean = true;
          }
        }
      }else{
        showAndHideSpinner(this, 'hidespinner');
        showToast(this,"No Records Modified",'Info','info');
      }
    }
  }

  clearSiteMetadata() {
    this.clearMessage = clearMessage;
    this.showConfirmPopupOnClear = true;
  }

  handleClear(event) {
    if (event.detail.confirmationOutput) {
      this.customDatatableInput = undefined;
      this.siteMetadataIdToRecordDetails = new Map();
      this.siteMetadataIdToRecordDetailsForUpdate = new Map();
      showAndHideSpinner(this, 'showspinner');

      clearPromptInfo({
        plantAssetId: this.plantAssetId,
        previousPromptName: this.previousPromptName
      }).then(result => {
        if (result !== 'false') {
          this.isDisableButton = false;
          this.IsdeleteCSVCheck = false;
          this.customDatatableInput = result;
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
          showToast(this, dataClearedSuccessMessage, 'Info', 'success');
        }
      }).catch(error => {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this, dataClearedErrorsMessage, 'Error', 'error');
      });
    } else {
      showAndHideSpinner(this, 'hidespinner');
      this.showConfirmPopupOnClear = false;
    }
  }

  goToNext(event) {
    if (this.validation()) {
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true : this.IsdeleteCSVCheck;
      if (IsdeleteBooleanCheck && !this.isBulkUpload && !this.isReadOnly && !this.isBulkUploadMultipleBAT) {
        this.ConfirmationModalTitle = confirmationPopupTitleOnDelete;
        this.onClickNextMessage = ((typeof this.promptInfoRecord.Confirm_Message_On_Delete__c === 'undefined')) ? assetBuilderDeleteConfirmationMessage : this.promptInfoRecord.Confirm_Message_On_Delete__c;
        this.showConfirmPopupOnNext = true;
      } else if (this.promptInfoRecord.Show_Popup_On_Next_Button__c && !this.isBulkUpload && !this.isReadOnly && !this.isBulkUploadMultipleBAT) {
        this.ConfirmationModalTitle = confirmationPopupTitleOnNext;
        this.onClickNextMessage = ((typeof this.promptInfoRecord.Confirm_Message_On_Next__c === 'undefined')) ? assetBuilderNextConfirmationMessage : this.promptInfoRecord.Confirm_Message_On_Next__c;
        this.showConfirmPopupOnNext = true;
      } else {
        this.hanldeNextOnConfirm(event, true);
      }
    }
  }

  hanldeNextOnConfirm(event, executeNextLogic) {
    let allowNextLogic = (executeNextLogic) ? executeNextLogic : event.detail.confirmationOutput;
    if (allowNextLogic) {
      showAndHideSpinner(this, 'showspinner');
      let modifiedMetadataRecords = [];
      if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
        modifiedMetadataRecords = getModifiedMetadataRecordsArray(
          this.siteMetadataIdToRecordDetailsForUpdate
        );
      }
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true : this.IsdeleteCSVCheck;
      let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : 
                                  this.isBulkUpload ? true : this.isImpWizUpLoad;
      let additionalParamsForNext = {isReadOnly: this.isReadOnly};

      if(!this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
        findNextPromptId({
          plantAssetId: this.plantAssetId,
          siteMetadataRecordsToSave: '',
          isKeyToGenerateRows: IsdeleteBooleanCheck,
          attrValueChanged: attrValueChangeCheck,
          additionalParamsForNext: JSON.stringify(additionalParamsForNext),
          finalBatchBoolean: true,
        }).then(result => {
          showAndHideSpinner(this, 'hidespinner');
          var nextPromptFinderRes = JSON.parse(result);
          if(nextPromptFinderRes.nextPromptId){
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
          }else{
            showAndHideSpinner(this, 'hidespinner');
            showToast(this, assetBuilderExceptionMessage, 'Error', 'error');
          }
        }).catch(error => {
          let errorMessage;
          if(error){
            errorMessage =error.body.message;
          }
          showAndHideSpinner(this, 'hidespinner');
          showToast(this,errorMessage,'Error','error');
        });
      }else{
        let chunk = 100;
        var count = 0;
        var finalBatch = 0;
        if (modifiedMetadataRecords.length % 100 == 0) {
          finalBatch = modifiedMetadataRecords.length / 100;
        }
        for (var batchCount = 0; batchCount < modifiedMetadataRecords.length; batchCount += chunk) {
          var tempArray = [];
          count = count + 1;
          tempArray = modifiedMetadataRecords.slice(batchCount, batchCount + chunk);
          if (tempArray.length == 100) {
            if (finalBatch > 0 && (finalBatch == count)) {
              findNextPromptId({
                plantAssetId: this.plantAssetId,
                siteMetadataRecordsToSave: JSON.stringify(tempArray),
                isKeyToGenerateRows: IsdeleteBooleanCheck,
                attrValueChanged: attrValueChangeCheck,
                additionalParamsForNext: JSON.stringify(additionalParamsForNext),
                finalBatchBoolean: true,
              }).then(result => {
                showAndHideSpinner(this, 'hidespinner');
                var nextPromptFinderRes = JSON.parse(result);
                if(nextPromptFinderRes.nextPromptId){
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
                }else{
                  showAndHideSpinner(this, 'hidespinner');
                  showToast(this, assetBuilderExceptionMessage, 'Error', 'error');
                }
              }).catch(error => {
                let errorMessage;
                if(error){
                  errorMessage =error.body.message;
                }
                showAndHideSpinner(this, 'hidespinner');
                showToast(this,errorMessage,'Error','error');
              });
              //finalBatchBoolean = true;
            } else {
              findNextPromptId({
                plantAssetId: this.plantAssetId,
                siteMetadataRecordsToSave: JSON.stringify(tempArray),
                isKeyToGenerateRows: IsdeleteBooleanCheck,
                attrValueChanged: attrValueChangeCheck,
                additionalParamsForNext: JSON.stringify(additionalParamsForNext),
                finalBatchBoolean: false,
              }).then(result => {
                console.log('Batch Check in next');
              }).catch(error => {
              });
              //finalBatchBoolean = false;
            }
          } else if (tempArray.length < 100) {
            findNextPromptId({
              plantAssetId: this.plantAssetId,
              siteMetadataRecordsToSave: JSON.stringify(tempArray),
              isKeyToGenerateRows: IsdeleteBooleanCheck,
              attrValueChanged: attrValueChangeCheck,
              additionalParamsForNext: JSON.stringify(additionalParamsForNext),
              finalBatchBoolean: true,
            }).then(result => {
              showAndHideSpinner(this, 'hidespinner');
              var nextPromptFinderRes = JSON.parse(result);
              if(nextPromptFinderRes.nextPromptId){
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
              }else{
                showAndHideSpinner(this, 'hidespinner');
                showToast(this, assetBuilderExceptionMessage, 'Error', 'error');
              }
            }).catch(error => {
              let errorMessage;
              if(error){
                errorMessage =error.body.message;
              }
              showAndHideSpinner(this, 'hidespinner');
              showToast(this,errorMessage,'Error','error');
            });
            //finalBatchBoolean = true;
          }
        }
      }
    } else {
      this.showConfirmPopupOnNext = false;
    }
  }

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
      if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
        modifiedMetadataRecords = getModifiedMetadataRecordsArray(
          this.siteMetadataIdToRecordDetailsForUpdate
        );
      }
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true : this.IsdeleteCSVCheck;
      let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : false;
      let addtionalParamsForPrevious = {isReadOnly: this.isReadOnly};

      if(!this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
        findPreviousPromptId({
          plantAssetId: this.plantAssetId,
          siteMetadataRecordsToSave: '',
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
          }
        }).catch(error => {
          let errorMessage;
          if (error) {
            errorMessage = error.body.message;
          }
          showAndHideSpinner(this, 'hidespinner');
          showToast(this, errorMessage, 'Error', 'error');
        });
      }else{
        let chunk = 100;
        var count = 0;
        var finalBatch = 0;
        if (modifiedMetadataRecords.length % 100 == 0) {
          finalBatch = modifiedMetadataRecords.length / 100;
        }
        for (var batchCount = 0; batchCount < modifiedMetadataRecords.length; batchCount += chunk) {
          var tempArray = [];
          count = count + 1;
          tempArray = modifiedMetadataRecords.slice(batchCount, batchCount + chunk);
          if (tempArray.length == 100) {
            if (finalBatch > 0 && (finalBatch == count)) {
              findPreviousPromptId({
                plantAssetId: this.plantAssetId,
                siteMetadataRecordsToSave: JSON.stringify(tempArray),
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
                }
              }).catch(error => {
                let errorMessage;
                if (error) {
                  errorMessage = error.body.message;
                }
                showAndHideSpinner(this, 'hidespinner');
                showToast(this, errorMessage, 'Error', 'error');
              });
              //finalBatchBoolean = true;
            } else {
              findPreviousPromptId({
                plantAssetId: this.plantAssetId,
                siteMetadataRecordsToSave: JSON.stringify(tempArray),
                promptInfo: JSON.stringify(this.promptInfoRecord),
                isKeyToGenerateRows: IsdeleteBooleanCheck,
                attrValueChanged: attrValueChangeCheck,
                addtionalParamsForPrevious: JSON.stringify(addtionalParamsForPrevious),
                finalBatchBoolean: false,
              }).then(result => {
                console.log('Batch Check in Previous');
              }).catch(error => {
              });
              //finalBatchBoolean = false;
            }
          } else if (tempArray.length < 100) {
            findPreviousPromptId({
              plantAssetId: this.plantAssetId,
              siteMetadataRecordsToSave: JSON.stringify(tempArray),
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
              }
            }).catch(error => {
              let errorMessage;
              if (error) {
                errorMessage = error.body.message;
              }
              showAndHideSpinner(this, 'hidespinner');
              showToast(this, errorMessage, 'Error', 'error');
            });
            //finalBatchBoolean = true;
          }
        }
      }
    } else{
      showAndHideSpinner(this, 'hidespinner');
      this.showConfirmPopupOnDelete = false;
    }
  }

  goToFinish(event) {
    showAndHideSpinner(this, 'showspinner');

    if (this.validation()) {
      if(!this.isReadOnly){
        let modifiedMetadataRecords = [];
        if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
          modifiedMetadataRecords = getModifiedMetadataRecordsArray(
            this.siteMetadataIdToRecordDetailsForUpdate
          );
        }
        let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : 
                                this.isBulkUpload ? true : this.isImpWizUpLoad;
        
        if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
          let chunk = 100;
          var count = 0;
          var finalBatch = 0;
          if (modifiedMetadataRecords.length % 100 == 0) {
            finalBatch = modifiedMetadataRecords.length / 100;
          }
          for (var batchCount = 0; batchCount < modifiedMetadataRecords.length; batchCount += chunk) {
            var tempArray = [];
            count = count + 1;
            tempArray = modifiedMetadataRecords.slice(batchCount, batchCount + chunk);
            if (tempArray.length == 100) {
              if (finalBatch > 0 && (finalBatch == count)) {
                saveSiteMetadataRecords({
                  siteMetadataRecordsToSave: JSON.stringify(tempArray),
                  plantAssetId : this.plantAssetId,
                  isKeyToGenerateRows: false,
                  attrValueChanged: attrValueChangeCheck,
                  finalBatchBoolean: true,
                }).then(result => {
                  if (result) {
                    showAndHideSpinner(this,'hidespinner');
                  }
                }).catch(error => {
                  let errorMessage;
                  if(error){
                    errorMessage =error.body.message;
                    showAndHideSpinner(this, 'hidespinner');
                    showToast(this,errorMessage,'Error','error');
                  }
                });
                //finalBatchBoolean = true;
              } else {
                saveSiteMetadataRecords({
                  siteMetadataRecordsToSave: JSON.stringify(tempArray),
                  plantAssetId : this.plantAssetId,
                  isKeyToGenerateRows: false,
                  attrValueChanged: attrValueChangeCheck,
                  finalBatchBoolean: false,
                }).then(result => {
                  console.log('Batch Check in save');
                }).catch(error => {
                });
              }
            } else if (tempArray.length < 100) {
              saveSiteMetadataRecords({
                siteMetadataRecordsToSave: JSON.stringify(tempArray),
                plantAssetId : this.plantAssetId,
                isKeyToGenerateRows: false,
                attrValueChanged: attrValueChangeCheck,
                finalBatchBoolean: true,
              }).then(result => {
                if (result) {
                  showAndHideSpinner(this,'hidespinner');
                }
              }).catch(error => {
                let errorMessage;
                if(error){
                  errorMessage =error.body.message;
                  showAndHideSpinner(this, 'hidespinner');
                  showToast(this,errorMessage,'Error','error');
                }
              });
              //finalBatchBoolean = true;
            }
          }
        }
        showAndHideSpinner(this, 'hidespinner');
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