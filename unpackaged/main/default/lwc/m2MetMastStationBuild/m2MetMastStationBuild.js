import { LightningElement, api, track } from 'lwc';
import getCustomDatatableCompInput from "@salesforce/apex/M2MetMastStationBuild.getCustomDatatableCompInput";
import getConfirmationMessageOnNext from "@salesforce/apex/Utils.getConfirmationMessageOnNext";
import saveSiteMetadataRecords from "@salesforce/apex/M2MetMastStationBuild.saveSiteMetadataRecords";
import findNextPromptId from "@salesforce/apex/M2MetMastStationBuild.findNextPromptId";
import assetBuilderExceptionMessage from '@salesforce/label/c.AssetBuilderExceptionMessage';
import assetBuilderSuccessMessageOnSave from '@salesforce/label/c.AssetBuilderSuccessMessageOnSave';
import confirmationPopupTitleOnClear from '@salesforce/label/c.ConfirmationPopupTitleOnClear';
import confirmationPopupTitleOnNext from '@salesforce/label/c.ConfirmationPopupTitleOnNext';
import assetBuilderClearPopupMessage from '@salesforce/label/c.AssetBuilderClearPopupMessage';
import clearPromptInfo from "@salesforce/apex/M2MetMastStationBuild.clearPromptInfo";
import recordLimitExcessInfoMessasge from '@salesforce/label/c.RecordLimitExcessInfoMessasge';
import assetCreationProcess from '@salesforce/label/c.AssetCreationProcess';
import fetchingAssets from '@salesforce/label/c.FetchingAssets';
import findPreviousPromptId from "@salesforce/apex/Utils.findPreviousPromptId";
import querySiteMetadata from "@salesforce/apex/Utils.querySortedSiteMetadata";
import m2ValidationErrorOnDataSave from '@salesforce/label/c.m2ValidationErrorOnDataSave';
import dataClearedSuccessMessage from '@salesforce/label/c.AssetBuilderClearPromptInfoMessage';
import assetBuilderFinishConfirmationMessage from '@salesforce/label/c.AssetBuilderFinishConfirmationMessage';
import confirmationPopupTitleOnFinish from '@salesforce/label/c.ConfirmationPopupTitleOnFinish';
import uniqueNameValidation from '@salesforce/label/c.UniqueNameValidation';
import assetNameAndAltParentErrMsg from '@salesforce/label/c.AssetNameAndAltParentErrMsg';
import assetNameErrMsg from '@salesforce/label/c.assetNameErrMsg';
import alternateParentErrMsg from '@salesforce/label/c.alternateParentErrMsg';
import countOfRecords from '@salesforce/label/c.CountOfRecords';
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
  showAndHideGoToG1PromptButton,
  buttonLabels,
  updateG1PlantAssetPromptDetailBulkImportType,
  getcustomDataTable,
  uniqueNameValidationFun,
  mapSiteMetadataIdWithCSVDataWithUniqueAssetNameForDetailPrompt,
  readCSVAndMapImportRecords,
  replaceOldAttrbuiteValueWithNewValueForUpdate
} from "c/utils";

export default class M2MetMastStationBuild extends LightningElement {
  @api plantAssetId;
  @api customDatatableInput;
  @api previousPromptName;
  @api openedFromReport = false;
  @api promptInfoRecord;
  @api plantAssetRecordId;
  @api promptSiteMetadata
  @api attrHlVal;
  @api isBulkUpload;
  @api csvLines;
  @api siteMetadataMap = new Map();
  @api isBulkUploadMultipleBAT;
  @api isImpWizUpLoad;
  @api isOverride;
  @api siteMetadataRecordCountFromCSVImport;
  @api detailPromptIdMapForN3uronTemp = new Map();
  @track isDisableButton;
  @track showConfirmPopupOnClear = false;
  @track clearMessage;
  @track isHideNextButton = false;
  @track isHideFinishButton = false;
  @track showConfirmPopupOnNext = false;
  @track onClickNextMessage;
  @track plantAssetPromptDetail;
  @track onClickFinishMessage;
  @track showConfirmPopupOnFinish = false;
  @track isSpinner = false;
  @track showImportAndExportButton = false;
  @track goToG1PromptButton = false;
  @track buttonLabel = '';
  @track buttonLabelsObj = {};
  @track IsdeleteCSVCheck = false;
  isExecutedFromImportExport = false;
  callNextForBulkImportWithoutValidation = false;
  /** 	
   * isReadOnly value passed from promptNavigator to decide isReadOnly for this Prompt(to hide btns) 	
   * and assetBuilderCustomDatatable(to make records readonly), Save fn should not call on click of Next	
  */	
  @api isReadOnly; 	
  @track showSaveButton = false;	
  @track showClearButton = false;
  @track showPreviousButton = false;
  @track buttonHideBooleanForMoreThan3KRecords = false; // This Boolean is used to hide/show the finish button from finish button response

  pageRef = 'Asset Builder';
  saveSiteMetadataMap = new Map();
  siteMetdaDataAttributeMap = new Map();
  jsonInputParametersAndValues={};
  callFinish = false;

  label = {
    confirmationPopupTitleOnClear,
    confirmationPopupTitleOnNext,
    confirmationPopupTitleOnFinish
  };
  siteMetadataIdToRecordDetails = new Map();
  siteMetadataIdToRecordDetailsForUpdate = new Map();
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
      isBulkUpload : this.isBulkUpload.toString(),
      isBulkUploadMultipleBAT : this.isBulkUploadMultipleBAT.toString(),
      isImpWizUpLoad : this.isImpWizUpLoad.toString(),
      isOverride : this.isOverride.toString(),
    };
    this.buttonLabelsObj = buttonLabels();
    this.toastMessageMode = (this.isBulkUploadMultipleBAT || this.isImpWizUpLoad) ? 'sticky' : this.toastMessageMode;
    this.buttonLabel = (this.isBulkUpload) ? this.buttonLabelsObj.saveAndResume : (this.isBulkUploadMultipleBAT) ? this.buttonLabelsObj.saveAndResume : this.buttonLabelsObj.next;
    registerListener('getDataFromAssetDataTable', this.handleExportComponent, this);
    this.isDisableButton = false;
    showAndHideSpinner(this,'showspinner',assetCreationProcess);

    //To Hide Save and Clear button if isReadOnly true	
    this.showSaveButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : !this.isReadOnly;
    this.showClearButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : !this.isReadOnly;
    this.showPreviousButton = (this.isBulkUpload) ? false : (this.isBulkUploadMultipleBAT) ? false : true;
    
    getCustomDatatableCompInput({
      plantAssetId: this.plantAssetId,
      previousPromptName: this.previousPromptName,
      isExecuteClear: false,
      jsonInputParametersAndValues : JSON.stringify(this.jsonInputParametersAndValues)
    })
      .then(result => {
        if (result) {
          let inputData = JSON.parse(result);
          if (inputData.PlantAssetPromptDetail) {
            this.plantAssetPromptDetail = inputData.PlantAssetPromptDetail;
            if(showAndHideGoToG1PromptButton(this.plantAssetPromptDetail) && this.isBulkUploadMultipleBAT){
              this.goToG1PromptButton = true;
            }
          }

          if (inputData.PromptInfo) {
            this.promptInfoRecord = inputData.PromptInfo;
          }

          if(inputData.nextPromptFinderResponse){
            if(inputData.nextPromptFinderResponse !== 'finish'){
              this.isHideNextButton = true;
            }else{
              this.callFinish = true;
              this.isHideFinishButton = true;
            }
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
                for(let i=0; i < siteMetadataRecords.length; i++){
                  let siteMetadataId = siteMetadataRecords[i]['Id'];
                  let sitemetadataCount = i;
                  let parentSiteAssetName = siteMetadataRecords[sitemetadataCount].Parent_Site_Metadata__r.Asset_Name__c;
                  let deviceType = '';
                  let concatDeviceNameAndDeviceType = '';
                  let attrValues = siteMetadataRecords[i]['Prompt_Specific_Info__c'];
                  JSON.parse(attrValues, (attrJSONKey, attrJSONValue) => {
                    if(attrJSONKey === 'Device Type'){
                      deviceType = attrJSONValue;
                    }
                  });
                  concatDeviceNameAndDeviceType = parentSiteAssetName.toLowerCase()+' - '+deviceType.toLowerCase();
                  if(!this.detailPromptIdMapForN3uronTemp.has(concatDeviceNameAndDeviceType)){
                    let newarray = [];
                    this.detailPromptIdMapForN3uronTemp.set(concatDeviceNameAndDeviceType, newarray);
                  }
                  this.detailPromptIdMapForN3uronTemp.get(concatDeviceNameAndDeviceType).push(siteMetadataId);
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
                  let csvStringObject = mapSiteMetadataIdWithCSVDataWithUniqueAssetNameForDetailPrompt(csvStr,this.detailPromptIdMapForN3uronTemp);
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

              if(((this.isBulkUpload && !this.callNextForBulkImportWithoutValidation) 
              || (this.isBulkUploadMultipleBAT && this.callNextForBulkImportWithoutValidation)) && !this.callFinish && !this.isImpWizUpLoad){
                this.goToNext();
              }
      
              if(((this.isBulkUpload && !this.callNextForBulkImportWithoutValidation) 
              || (this.isBulkUploadMultipleBAT && this.callNextForBulkImportWithoutValidation)) && this.callFinish && !this.isImpWizUpLoad){
                this.goToFinish();
              }

              if(inputData.csvData && this.isBulkUploadMultipleBAT && !this.isExecutedFromImportExport && !this.callNextForBulkImportWithoutValidation){
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
                  this.csvLines = csvStr.split('\n');
                  this.siteMetadataRecordCountFromCSVImport = siteMetadataRecords.length;
                  this.template.querySelector("c-import-and-export-c-s-v").readCsvAndImportRecords('No Data', this.csvLines, this.siteMetadataMap, this.promptSiteMetadata, 'No Data', this.siteMetadataRecordCountFromCSVImport);
                }
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
      })
      .catch(error => {
        if (error) {
          showAndHideSpinner(this, 'hidespinner');
          showToast(this, error.body.message, 'Error', 'error');
        }
      });
  }

  handleExportComponent(eventData){
    this.promptSiteMetadata = eventData;
    if(this.promptSiteMetadata !== undefined)
      this.showImportAndExportButton = this.isReadOnly ? false : true;
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
  }

  saveSiteMetadata(event) {
    showAndHideSpinner(this, 'showspinner');
    let modifiedMetadataRecords = [];
    if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
      modifiedMetadataRecords = getModifiedMetadataRecordsArray(
        this.siteMetadataIdToRecordDetailsForUpdate
      );
    }
    let IsdeleteBooleanCheck = IsBooleanCheck(this.siteMetdaDataAttributeMap) === true ? true : this.IsdeleteCSVCheck;
    let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : 
                                this.isBulkUploadMultipleBAT ? true : this.isImpWizUpLoad;
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
      } else {
        showAndHideSpinner(this, 'hidespinner');
        showToast(this,"No Records Modified",'Info','info');
      }
    }
  }

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
                                  this.isBulkUploadMultipleBAT ? true : this.isImpWizUpLoad;
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
    let addtionalParamsForPrevious = {isReadOnly: this.isReadOnly};
    if (this.plantAssetPromptDetail.Validate_On_Previous__c) {
      isValid = this.validation();
    }
    if (isValid) {
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

  clearSiteMetadata() {
    this.clearMessage = assetBuilderClearPopupMessage;
    this.showConfirmPopupOnClear = true;
  }

  handleClear(event) {
    if (event.detail.confirmationOutput) {
      this.showConfirmPopupOnClear = false;
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
              showAndHideSpinner(this, 'hidespinner');
              showToast(this, dataClearedSuccessMessage, 'Info', 'success');
            }).catch(error => {
              showAndHideSpinner(this, 'hidespinner');
            });
          }
        }
      }).catch(error => {
        if (error) {
          showAndHideSpinner(this, 'hidespinner');
          showToast(this, error.body.message, 'Error', 'error');
        }
      });
    } else {
      showAndHideSpinner(this, 'hidespinner');
      this.showConfirmPopupOnClear = false;
    }
  }

  handleFinishButtonFinderResponse(event) {
    if(!this.buttonHideBooleanForMoreThan3KRecords){
      if (event.detail.result != 'finish') {
        this.isHideNextButton = true;
      } else {
        this.isHideFinishButton = true;
      }
    }
  }

  validation() {
    var deviceNameCheck = true;
    var uniqueValueCheck = true;
    var allValues = [];
    this.siteMetadataIdToRecordDetails.forEach((value, key) => {
      let siteMetadataRecordDetail = this.siteMetadataIdToRecordDetails.get(key);
      let attrInfoJSON = siteMetadataRecordDetail.Prompt_Specific_Info__c;
      JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
        if (attrJSONKey === 'Device Name') {
          let parsedAttrValue = attrJSONValue.trim();
          if ((isEmptyOrSpaces(parsedAttrValue))) {
            deviceNameCheck = false;
            showAndHideSpinner(this, 'hidespinner');
            showToast(this, m2ValidationErrorOnDataSave, 'Error', 'error', this.toastMessageMode);
          }
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

    if(uniqueValueCheck){
      return deviceNameCheck;
    }else{
      return false;
    }
  }

  goToFinish(event) {
    if (this.validation()) {
      if(!this.isReadOnly){
        this.plantAssetRecordId = this.plantAssetId;
        if((!this.isBulkUpload && !this.isBulkUploadMultipleBAT) ||
        (this.isBulkUploadMultipleBAT && this.isExecutedFromImportExport)){
          let modifiedMetadataRecords = [];
          if(this.siteMetadataIdToRecordDetailsForUpdate.size > 0){
            modifiedMetadataRecords = getModifiedMetadataRecordsArray(
              this.siteMetadataIdToRecordDetailsForUpdate
            );
          }
          let attrValueChangeCheck = IsBooleanCheck(this.saveSiteMetadataMap) === true ? true : 
                                this.isBulkUploadMultipleBAT ? true : this.isImpWizUpLoad;
          
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
    let allowNextLogic = event.detail.confirmationOutput;
    if((this.isBulkUpload === true || this.isBulkUploadMultipleBAT === true) && allowNextLogic){
      updateG1PlantAssetPromptDetailBulkImportType(this, this.plantAssetId, JSON.stringify(this.jsonInputParametersAndValues));
    }
    this.showConfirmPopupOnFinish = false;
  }

  handleFinishButtonFinderResponse(event) {
    if(!this.buttonHideBooleanForMoreThan3KRecords){
      if (event.detail.result != 'finish') {
        this.isHideNextButton = true;
        if(this.openedFromReport){
          this.isHideFinishButton = true;
        }
      } else {
        this.isHideFinishButton = true;
      }
    }
  }

  refreshOnImport(event) {
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
      if(this.isHideNextButton || this.isHideFinishButton){
        this.isParentNameMisMatchInBulkImport = true;
        this.isDisableButton = true;
      }
    }
  }

  nextForBulkImport(event){
    if (event.detail.callNextForBulkImport && (this.isBulkUploadMultipleBAT || this.isImpWizUpLoad)) {
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

  spinnerInImport(event) {
    this.isSpinner = event.detail.spinnerVal;
    if (event.detail.recordCount > parseInt(countOfRecords)) {
      const recordcount = new CustomEvent("recordcount", {
        detail: {
          recordCount: event.detail.recordCount
        }
      });
      this.dispatchEvent(recordcount);
    }
  }
}