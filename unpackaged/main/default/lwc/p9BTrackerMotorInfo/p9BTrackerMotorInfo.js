import { LightningElement, track, api, wire } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCustomDatatableCompInput from "@salesforce/apex/P9BTrackerMotorInfo.getCustomDatatableCompInput";
import saveSiteMetadataRecords from "@salesforce/apex/P9BTrackerMotorInfo.saveSiteMetadataRecords";
import findNextPromptId from "@salesforce/apex/P9BTrackerMotorInfo.findNextPromptId";
import findPreviousPromptId from "@salesforce/apex/Utils.findPreviousPromptId";
import querySiteMetadata from "@salesforce/apex/Utils.querySortedSiteMetadata";
import clearPromptInfo from "@salesforce/apex/P9BTrackerMotorInfo.clearPromptInfo";
import recordLimitExcessInfoMessasge from '@salesforce/label/c.RecordLimitExcessInfoMessasge';
import assetCreationProcess from '@salesforce/label/c.AssetCreationProcess';
import fetchingAssets from '@salesforce/label/c.FetchingAssets';
import clearMessage from '@salesforce/label/c.AssetBuilderClearPopupMessage';
import dataClearedSuccessMessage from '@salesforce/label/c.AssetBuilderClearPromptInfoMessage';
import dataClearedErrorsMessage from '@salesforce/label/c.AssetBuilderClearErrorMessage';
import p9BTackerMotorNameIsBlankMessage from '@salesforce/label/c.P9BTackerMotorNameIsBlankMessage';
import assetBuilderNextConfirmationMessage from '@salesforce/label/c.AssetBuilderNextConfirmationMessage';
import getConfirmationMessageOnNext from "@salesforce/apex/Utils.getConfirmationMessageOnNext";
import nextPromptErrorMessage from '@salesforce/label/c.AssetBuilderNextPromptErrorMessage';
import assetBuilderExceptionMessage from '@salesforce/label/c.AssetBuilderExceptionMessage';
import assetBuilderSuccessMessageOnSave from '@salesforce/label/c.AssetBuilderSuccessMessageOnSave';
import confirmationPopupTitleOnClear from '@salesforce/label/c.ConfirmationPopupTitleOnClear';
import confirmationPopupTitleOnNext from '@salesforce/label/c.ConfirmationPopupTitleOnNext';
import assetBuilderFinishConfirmationMessage from '@salesforce/label/c.AssetBuilderFinishConfirmationMessage';
import confirmationPopupTitleOnFinish from '@salesforce/label/c.ConfirmationPopupTitleOnFinish';
import uniqueNameValidation from '@salesforce/label/c.UniqueNameValidation';
import assetNameAndAltParentErrMsg from '@salesforce/label/c.AssetNameAndAltParentErrMsg';
import assetNameErrMsg from '@salesforce/label/c.assetNameErrMsg';
import alternateParentErrMsg from '@salesforce/label/c.alternateParentErrMsg';
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
  mapSiteMetadataIdWithCSVDataWithUniqueAssetName,
  getcustomDataTable,
  showAndHideGoToG1PromptButton,
  updateG1PlantAssetPromptDetailBulkImportType,
  buttonLabels,
  uniqueNameValidationFun,
  readCSVAndMapImportRecords,
  replaceOldAttrbuiteValueWithNewValueForUpdate
} from "c/utils";

export default class P9BTrackerMotorInfo extends LightningElement {
  @api plantAssetId;
  @api previousPromptName;
  @api attrHlVal;
  @api isBulkUpload;
  @api isBulkUploadMultipleBAT;
  @api isImpWizUpLoad;
  @api isOverride;
  @api csvLines;
  @api siteMetadataRecordCountFromCSVImport;
  @api siteMetadataMap = new Map();
  @track promptData;
  @track customDatatableInput;
  @track showConfirmPopupOnClear = false;
  @track clearMessage;
  @track isDisableButton;
  @track isHideNextButton = false;
  @track isHideFinishButton = false;
  @track onClickNextMessage;
  siteMetadataIdToRecordDetails = new Map();
  siteMetadataIdToRecordDetailsForUpdate = new Map();
  @track showConfirmPopupOnNext = false;
  @track plantAssetPromptDetail;
  @api promptInfoRecord;
  @track onClickFinishMessage;
  @track showConfirmPopupOnFinish = false;
  @api plantAssetRecordId;
  @track isSpinner = false;
  @api openedFromReport = false;
  @api picklistValues;
  @track showImportAndExportButton = false;
  @track goToG1PromptButton = false;
  @track buttonLabel = '';
  @track buttonLabelsObj = {};
  @track IsdeleteCSVCheck = false;
  /** 	
   * isReadOnly value passed from promptNavigator to decide isReadOnly for this Prompt(to hide btns) 	
   * and assetBuilderCustomDatatable(to make records readonly), Save fn should not call on click of Next and Previous button
  */
  @api isReadOnly;
  @track showSaveButton = false;
  @track showClearButton = false;
  @track showPreviousButton = false;
  @track buttonHideBooleanForMoreThan3KRecords = false; // This Boolean is used to hide/show the finish button from finish button response

  pageRef = 'Asset Builder';
  jsonInputParametersAndValues = {};
  isExecutedFromImportExport = false;
  callNextForBulkImportWithoutValidation = false;
  callFinish = false;

  saveSiteMetadataMap = new Map();
  siteMetdaDataAttributeMap = new Map();
  label = {
    confirmationPopupTitleOnClear,
    confirmationPopupTitleOnNext,
    confirmationPopupTitleOnFinish
  }
  @track isParentNameMisMatchInBulkImport = false;
  toastMessageMode = 'dismissable';
  showUniqueNameToastMessage = true;

  connectedCallback() {
    if (this.openedFromReport) {
      this.isBulkUpload = false;
      this.isBulkUploadMultipleBAT = false;
      this.isImpWizUpLoad = false;
      this.isOverride = false;
    }
    this.jsonInputParametersAndValues = {
      isBulkUpload: this.isBulkUpload.toString(),
      isBulkUploadMultipleBAT: this.isBulkUploadMultipleBAT.toString(),
      isImpWizUpLoad : this.isImpWizUpLoad.toString(),
      isOverride : this.isOverride.toString(),
    };
    this.buttonLabelsObj = buttonLabels();
    this.toastMessageMode = (this.isBulkUpload || this.isImpWizUpLoad) ? 'sticky' : this.toastMessageMode;
    this.buttonLabel = (this.isBulkUpload) ? this.buttonLabelsObj.saveAndResume : (this.isBulkUploadMultipleBAT) ? this.buttonLabelsObj.saveAndResume : this.buttonLabelsObj.next;
    registerListener('getDataFromAssetDataTable', this.handleExportComponent, this);
    this.isDisableButton = false;
    showAndHideSpinner(this,'showspinner',assetCreationProcess);

    //To Hide Save and Clear button if isReadOnly true	
    this.showSaveButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : !this.isReadOnly;
    this.showClearButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : !this.isReadOnly;
    this.showPreviousButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : true;

    /**
     * to retrieve the sitemetadata records to display that as a vertical prompt
     * @param {string} plantAssetId - current Plant Asset Id
     * @param {string} previousPromptName - previous prompt name
     */
    getCustomDatatableCompInput({
      plantAssetId: this.plantAssetId,
      previousPromptName: this.previousPromptName,
      jsonInputParametersAndValues: JSON.stringify(this.jsonInputParametersAndValues)
    }).then(result => {
      if (result) {
        let inputData = JSON.parse(result);
        if (inputData.PlantAssetPromptDetail) {
          this.plantAssetPromptDetail = inputData.PlantAssetPromptDetail;
          if (showAndHideGoToG1PromptButton(this.plantAssetPromptDetail) && this.isBulkUpload) {
            this.goToG1PromptButton = true;
          }
        }
        if (inputData.PromptInfo) {
          this.promptInfoRecord = inputData.PromptInfo;
        }

        //This is used to get the Next Prompt Response either to navigate to Next or Finish
        if (inputData.nextPromptFinderResponse) {
          if (inputData.nextPromptFinderResponse !== 'finish') {
            this.isHideNextButton = true;
          } else {
            this.callFinish = true;
            this.isHideFinishButton = true;
          }
        }

        if (inputData.Picklist) {
          this.picklistValues = inputData.Picklist;
        }

        if(inputData.SiteMetadataRecords < this.buttonLabelsObj.recordCountForEachPrompt){
          showAndHideSpinner(this,'showspinner',fetchingAssets);
          querySiteMetadata({
            promptName : this.promptInfoRecord.Name,
            plantAssetId : this.plantAssetId
          }).then(result => {
            inputData.SiteMetadataRecords = result;
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
                let csvStringObject = mapSiteMetadataIdWithCSVDataWithUniqueAssetName(inputData.SiteMetadataRecords, inputData.csvData);
                let csvString = csvStringObject.csvString;
                this.siteMetadataRecordCountFromCSVImport = csvStringObject.sitemetaRecordCountInCSV;
                this.csvLines = csvString.split('\n');
                let mappedValuesForUI =  readCSVAndMapImportRecords(this.csvLines, this.siteMetadataMap, this.promptSiteMetadata, this.picklistValues, this.siteMetadataRecordCountFromCSVImport);
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

            if (inputData.csvData && this.isBulkUpload && !this.isExecutedFromImportExport && !this.callNextForBulkImportWithoutValidation) {
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
                let csvStringObject = mapSiteMetadataIdWithCSVDataWithUniqueAssetName(inputData.SiteMetadataRecords, inputData.csvData);
                let csvString = csvStringObject.csvString;
                this.siteMetadataRecordCountFromCSVImport = csvStringObject.sitemetaRecordCountInCSV;
                this.csvLines = csvString.split('\n');
                this.template.querySelector("c-import-and-export-c-s-v").readCsvAndImportRecords('No Data', this.csvLines, this.siteMetadataMap,
                  this.promptSiteMetadata, this.picklistValues, this.siteMetadataRecordCountFromCSVImport);
              }
            }

            if(((this.isBulkUploadMultipleBAT && !this.callNextForBulkImportWithoutValidation) 
            || (this.isBulkUpload && this.callNextForBulkImportWithoutValidation)) && !this.callFinish && !this.isImpWizUpLoad){
              this.goToNext();
            }
      
            if(((this.isBulkUploadMultipleBAT && !this.callNextForBulkImportWithoutValidation) 
            || (this.isBulkUpload && this.callNextForBulkImportWithoutValidation)) && this.callFinish && !this.isImpWizUpLoad){
              this.goToFinish();
            }
            showAndHideSpinner(this, 'hidespinner');
          }).catch(error => {
            showAndHideSpinner(this, 'hidespinner');
          });
        }else{
          this.buttonHideBooleanForMoreThan3KRecords = true;
          this.isHideNextButton = false; //This Boolean will hide the next Button 
          this.showSaveButton = false; //This Boolean will hide the save Button
          this.showClearButton = false; //This Boolean will hide the clear Button
          this.isHideFinishButton = false; //This Boolean will hide the Finish Button
          this.showPreviousButton = true; // This Boolean will show the previous Button
          inputData.SiteMetadataRecords = [];
          this.customDatatableInput = JSON.stringify(inputData);
          showAndHideSpinner(this, 'hidespinner');
          showToast(this,recordLimitExcessInfoMessasge,'Info','info','sticky');
        }
      }
    }).catch(error => {
      if (error) {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this, error.body.message, 'Error', 'error');
      }
    });
  }

  handleExportComponent(eventData) {
    this.promptSiteMetadata = eventData;
    if (this.promptSiteMetadata !== undefined)
      this.showImportAndExportButton = this.isReadOnly ? false : true;
  }

  handleFinishButtonFinderResponse(event) {
    if(!this.buttonHideBooleanForMoreThan3KRecords){
      if (event.detail.result != 'finish') {
        this.isHideNextButton = true;
        if (this.openedFromReport) {
          this.isHideFinishButton = true;
        }
      } else {
        this.isHideFinishButton = true;
      }
    }
  }

  //Any change of value in the prompt is tracked here for the further process
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
  }

  //Passes the Modified site metadata record from the prompt,plantAssetId to the prompt Controller
  saveSiteMetadata(event) {
    showAndHideSpinner(this, 'showspinner');
    let isValid = true;
    if (this.plantAssetPromptDetail.Validate_On_Previous__c) {
      isValid = this.validation();
    }
    if (isValid) {
      let modifiedMetadataRecords = [];
      if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
        modifiedMetadataRecords = getModifiedMetadataRecordsArray(
          this.siteMetadataIdToRecordDetailsForUpdate
        );
      }
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true : this.IsdeleteCSVCheck;
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
      } else {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this,"No Records Modified",'Info','info');
      }
    }
  }

  //clicking on next button this function will be called
  goToNext(event) {
    if (this.validation()) {
      if (this.promptInfoRecord.Show_Popup_On_Next_Button__c && !this.isBulkUpload && !this.isReadOnly && !this.isBulkUploadMultipleBAT) {
        this.onClickNextMessage = ((typeof this.promptInfoRecord.Confirm_Message_On_Next__c === 'undefined')) ? assetBuilderNextConfirmationMessage : this.promptInfoRecord.Confirm_Message_On_Next__c;
        this.showConfirmPopupOnNext = true;
      } else {
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
      if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
        modifiedMetadataRecords = getModifiedMetadataRecordsArray(
          this.siteMetadataIdToRecordDetailsForUpdate
        );
      }
      let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true : this.IsdeleteCSVCheck;
      let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : 
                                  this.isBulkUpload ? true : this.isImpWizUpLoad;
      let additionalParamsForNext = { isReadOnly: this.isReadOnly };
      /*
       * to find the next Prompt id
       * @param {string} plantAssetId - current Plant Asset Id
       * @param {map} siteMetadataRecordsToSave - this map contains current prompt's  all the sitemetadata record id's and sitemetadata record details.
       * @param {boolean} isKeyToGenerateRows (it set to true if there is decrease in count of records)
       * @param {boolean} attrValueChanged (if any change occured in the prompt the 'attrValueChanged' is set to true)
      */
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

  /**
   * Custom validation will not run on previous, when user comes to the prompt for the first time,
   * if the user navigate to the next prompt and once come back to the current prompt, custom validation will run on on click of Previous button
  */
  goToPrevious(event) {
    showAndHideSpinner(this, 'showspinner');

    let modifiedMetadataRecords = [];
    if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
      modifiedMetadataRecords = getModifiedMetadataRecordsArray(
        this.siteMetadataIdToRecordDetailsForUpdate
      );
    }
    let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true : this.IsdeleteCSVCheck;
    let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : false;
    let isValid = true;
    let addtionalParamsForPrevious = { isReadOnly: this.isReadOnly };
    if (this.plantAssetPromptDetail.Validate_On_Previous__c) {
      isValid = this.validation();
    }
    if (isValid) {
      /*
      * to find the previous Prompt id 
      * @param {string} plantAssetId - current Plant Asset Id
      * @param {map} siteMetadataRecordsToSave - this map contains current prompt's  all the sitemetadata record id's and sitemetadata record details.
      * @param {object} promptInfo - this attribute holds the Current Prompt Information record details.
      * @param {boolean} isKeyToGenerateRows (it set to true if there is decrease in count of records)
      * @param {boolean} attrValueChanged (if any change occured in the prompt the 'attrValueChanged' is set to true)
     */
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
    }
  }

  //on click of clear ,call this function
  clearSiteMetadata() {
    this.clearMessage = clearMessage;
    this.showConfirmPopupOnClear = true;
  }

  /* Clears the attriute info and prompt specific info field in the sitemetadata record
   * @param {string} plantAssetId - current Plant Asset Id
   * @param {string} previousPromptName - previous prompt name
  */
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
          let inputData = JSON.parse(result);

          if (inputData.PlantAssetPromptDetail) {
            this.plantAssetPromptDetail = inputData.PlantAssetPromptDetail;
          }    

          if (inputData.PromptInfo) {
            this.promptInfoRecord = inputData.PromptInfo;
          }
          if(inputData.SiteMetadataRecords < this.buttonLabelsObj.recordCountForEachPrompt){
            querySiteMetadata({
              promptName : this.promptInfoRecord.Name,
              plantAssetId : this.plantAssetId
            }).then(result => {
              inputData.SiteMetadataRecords = result;
              var siteMetadataRecords = inputData.SiteMetadataRecords;

              for(var siteMetadataRecordKey in siteMetadataRecords){
                let siteMetadataRecord = siteMetadataRecords[siteMetadataRecordKey];
                this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id,siteMetadataRecord);
              }
              this.customDatatableInput = JSON.stringify(inputData);
              this.showConfirmPopupOnClear = false;
              showAndHideSpinner(this, 'hidespinner');
              showToast(this, dataClearedSuccessMessage, 'Info', 'success');
            }).catch(error => {
              showAndHideSpinner(this, 'hidespinner');
            });
          }
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

  // To validate the Unique and mandatory fields in the siteMetadata
  validation() {
    var nullValueCheck = true;
    var uniqueValueCheck = true;
    var allValues = [];
    this.siteMetadataIdToRecordDetails.forEach((value, key) => {
      let siteMetadataRecordDetail = this.siteMetadataIdToRecordDetails.get(key);
      let attrInfoJSON = siteMetadataRecordDetail.Prompt_Specific_Info__c;
      JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
        if (attrJSONKey === 'Tracker Motor Name') {
          if (isEmptyOrSpaces(attrJSONValue)) {
            nullValueCheck = false;
            showAndHideSpinner(this, 'hidespinner');
            showToast(this, p9BTackerMotorNameIsBlankMessage, 'Error', 'error', this.toastMessageMode);
          }
          
          //This is for Unique Name Validation Used For Bulk Import
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
        }
      });
    });
    return (uniqueValueCheck) ? nullValueCheck : false;
  }

  //Click of Finish button, saves the prompt values to the site metadata record,and displays the finish confirmation dialog to proceed further
  goToFinish(event) {
    if (this.validation()) {
      if(!this.isReadOnly){
        this.plantAssetRecordId = this.plantAssetId;
        if((!this.isBulkUpload && !this.isBulkUploadMultipleBAT) ||
        (this.isBulkUpload && this.isExecutedFromImportExport)){
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
        }
        showAndHideSpinner(this, 'hidespinner');
        this.onClickFinishMessage = assetBuilderFinishConfirmationMessage;
        this.showConfirmPopupOnFinish = true;
      } else {
        findG1PromptId({
        }).then(result => {
          let eventDet = {
            plantAssetId: this.plantAssetId,
            promptId: result
          }
          fireEvent(this.pageRef, 'redirectToG1Prompt', eventDet);
        });
      }
    }
  }

  hanldeFinishOnConfirm(event) {
    let allowNextLogic = event.detail.confirmationOutput;
    if((this.isBulkUpload === true || this.isBulkUploadMultipleBAT === true) && allowNextLogic){
      updateG1PlantAssetPromptDetailBulkImportType(this, this.plantAssetId, JSON.stringify(this.jsonInputParametersAndValues));
    }
    this.showConfirmPopupOnFinish = false;
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
  showOrHideGoToG1AndResumeButton(event) {
    if (event.detail.showGoToG1AndResumeButtonInPrompt) {
      if(this.isHideNextButton || this.isHideFinishButton){
        this.isParentNameMisMatchInBulkImport = true;
        this.isDisableButton = true;
      }
    }
  }

  spinnerInImport(event) {
    this.isSpinner = event.detail.spinnerVal;
  }
}