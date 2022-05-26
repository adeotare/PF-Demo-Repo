import { LightningElement, api, track,wire } from 'lwc';
import getCustomDatatableCompInput from "@salesforce/apex/S2SubstationSwitchgearBuildInfo.getCustomDatatableCompInput";
import saveSiteMetadataRecords from "@salesforce/apex/S2SubstationSwitchgearBuildInfo.saveSiteMetadataRecords";
import assetBuilderSuccessMessageOnSave from '@salesforce/label/c.AssetBuilderSuccessMessageOnSave';
import s2ValidationErrorOnDataSave from '@salesforce/label/c.S2ValidationErrorOnDataSave';
import confirmationPopupTitleOnClear from '@salesforce/label/c.ConfirmationPopupTitleOnClear';
import assetBuilderClearPopupMessage from '@salesforce/label/c.AssetBuilderClearPopupMessage';
import clearPromptInfo from "@salesforce/apex/S2SubstationSwitchgearBuildInfo.clearPromptInfo";
import recordLimitExcessInfoMessasge from '@salesforce/label/c.RecordLimitExcessInfoMessasge';
import assetCreationProcess from '@salesforce/label/c.AssetCreationProcess';
import fetchingAssets from '@salesforce/label/c.FetchingAssets';
import findPreviousPromptId from "@salesforce/apex/Utils.findPreviousPromptId";
import querySiteMetadata from "@salesforce/apex/Utils.querySortedSiteMetadata";
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
  updateG1PlantAssetPromptDetailBulkImportType,
  getcustomDataTable,
  uniqueNameValidationFun,
  mapSiteMetadataIdWithCSVDataWithUniqueAssetNameForDetailPrompt,
  readCSVAndMapImportRecords,
  replaceOldAttrbuiteValueWithNewValueForUpdate
} from "c/utils";

export default class S2SubstationSwitchgearBuildInfo extends LightningElement {
  @api plantAssetId; //Plant Assset Id passed from the previous prompt
  @api openedFromReport = false;
  @api previousPromptName;
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
  @track customDatatableInput; //site metadata from the prompt
  @track isDisableButton;
  @track showConfirmPopupOnClear = false;
  @track clearMessage;
  @track isHideFinishButton = true;
  @track plantAssetPromptDetail;
  @track onClickFinishMessage;
  @track showConfirmPopupOnFinish = false;
  @track isSpinner = false;
  @track showImportAndExportButton = false;
  @track goToG1PromptButton = false;
  @track IsdeleteCSVCheck = false;
  isExecutedFromImportExport = false;
  callNextForBulkImportWithoutValidation = false;
  jsonInputParametersAndValues={};
  /** 	
   * isReadOnly value passed from promptNavigator to decide isReadOnly for this Prompt(to hide btns) 	
   * and assetBuilderCustomDatatable(to make records readonly), Save fn should not call on click of Next	
  */	
  @api isReadOnly; 	
  @track showSaveButton = false;	
  @track showClearButton = false;
  @track showPreviousButton = false;
  @track buttonHideBooleanForMoreThan3KRecords = false; // This Boolean is used to hide/show the finish button from finish button response

  @track isParentNameMisMatchInBulkImport = false;
  pageRef = 'Asset Builder';
 
  saveSiteMetadataMap = new Map();
  siteMetdaDataAttributeMap = new Map();
  label = {
    confirmationPopupTitleOnClear,
    confirmationPopupTitleOnFinish
  };
  siteMetadataIdToRecordDetails = new Map();
  siteMetadataIdToRecordDetailsForUpdate = new Map();
  toastMessageMode = 'dismissable';
  showUniqueNameToastMessage = true;

  connectedCallback() {
    registerListener('getDataFromAssetDataTable', this.handleExportComponent, this);
    this.isDisableButton = false;
    showAndHideSpinner(this,'showspinner',assetCreationProcess);

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
    this.toastMessageMode = (this.isBulkUploadMultipleBAT || this.isImpWizUpLoad) ? 'sticky' : this.toastMessageMode;

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
      isExecuteClear: false,
      jsonInputParametersAndValues : JSON.stringify(this.jsonInputParametersAndValues)
    }).then(result => {
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

        if(inputData.SiteMetadataRecords < 3001){
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
            
            if((this.isBulkUpload || (this.isBulkUploadMultipleBAT && this.callNextForBulkImportWithoutValidation)) && !this.isImpWizUpLoad){
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

  handleExportComponent(eventData){
    this.promptSiteMetadata = eventData;
    if(this.promptSiteMetadata !== undefined)
      this.showImportAndExportButton = this.isReadOnly ? false : true;
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

  // To validate the Unique and mandatory fields in the siteMetadata
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
            showToast(this, s2ValidationErrorOnDataSave, 'Error', 'error', this.toastMessageMode);
          }
          if (!(isEmptyOrSpaces(parsedAttrValue))) {
            if (!(allValues.includes(parsedAttrValue))) {
              allValues.push(parsedAttrValue);
            } else {
              uniqueValueCheck = false;
              showAndHideSpinner(this, 'hidespinner');
              showToast(this, uniqueNameValidation + '  ' + parsedAttrValue, 'Error', 'error', this.toastMessageMode);
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

  //Passes the Modified site metadata record from the prompt,plantAssetId to the prompt Controller
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
      }else{
        showAndHideSpinner(this, 'hidespinner');
        showToast(this,"No Records Modified",'Info','info');
      }
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
    let addtionalParamsForPrevious = {isReadOnly: this.isReadOnly};
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

  //on click of clear, call this function
  clearSiteMetadata() {
    this.clearMessage = assetBuilderClearPopupMessage;
    this.showConfirmPopupOnClear = true;
  }

  /* Clears the attriute info and prompt specific info field in the sitemetadata record
   * @param {string} plantAssetId - current Plant Asset Id
   * @param {string} previousPromptName - previous prompt name
  */
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
          if(inputData.SiteMetadataRecords < 3001){
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
      this.isHideFinishButton = true;
    }
  }

  //Click of Finish button, saves the prompt values to the site metadata record,and displays the finish confirmation dialog to proceed further
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
      if(this.isHideFinishButton){
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