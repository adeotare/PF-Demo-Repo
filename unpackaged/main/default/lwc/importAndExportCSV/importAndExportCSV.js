import { LightningElement, track, api } from 'lwc';
import importcsvValidation from '@salesforce/label/c.importcsvValidation';
import readCSV from '@salesforce/apex/ImportAndExportCSV.getPromptSiteMetadataRecords';
import updateSiteMetadata from '@salesforce/apex/ImportAndExportCSV.updateSiteMetadata';
import getPlantAssetDetail from '@salesforce/apex/ImportAndExportCSV.getPlantAssetDetail';
import siteMetadataUpdateSuccessMesssge from '@salesforce/label/c.siteMetadataUpdateSuccessMesssge';
import confirmationPopupTitleOnDelete from '@salesforce/label/c.ConfirmationPopUpTitleOnDelete';
import alternateParentAssetErrMsg from '@salesforce/label/c.AlternateParentAssetErrMsg';
import parentSiteMetadataErrMsg from '@salesforce/label/c.ParentSiteMetadataErrMsg';
import smCountGreaterThanRecordCountInCSV from '@salesforce/label/c.SMCountGreaterThanRecordCountInCSV';
import smCountLesserThanRecordCountInCSV from '@salesforce/label/c.SMCountLesserThanRecordCountInCSV';

import {
  showToast,
  isEmptyOrSpaces
} from "c/utils";

/**
 * This Component is used to Export/Import site Metdadata Records as a CSV File in respective Prompts.
 * @param {string} plantAssetId - This will have the current Plant Asset Id.
 * @param {array} csvInput - This attribute will have the group of Site Metadata Records and Attribute record List.
 * @param {map} siteMetadataIdToRecordDetails - This attribute will have the map of Site Metadata Record with record details.
 * @param {map} attrMap - This attribute will have the map of Attribute Name with Attribute Details.
 * @param {object} promptInfo - This will have the Prompt Information.
 */

export default class ImportAndExportCSV extends LightningElement {
  @track error;
  @track csvLines = [];
  @api plantAssetId;
  @track siteMetadata;
  @api promptInfo;
  @track csvInput;
  @track attribute;
  @track isLoading;
  @api promptSiteMetadata
  @api picklistValues;
  @track showConfirmPopupOnDelete = false;
  @track confirmPopupOnDelete = false;
  @track customerPlantAssetId;
  @track popUpDeleteWarnMsg;
  @track isAssetNameNotUnique = false;
  @track isAltParentNotMatch = false;
  @track duplicateCheckArray = [];

  siteMetadataIdToRecordDetails = new Map();
  attrMap = new Map();
  coreAttrMap = new Map();
  csvIdAndRowMap = new Map();
  siteMetadataArray = [];
  tempArray = [];
  dataObjReadCsvAndImportRecords;

  connectedCallback() {
    getPlantAssetDetail({
      plantAssetId: this.plantAssetId
    }).then(result => {
      this.customerPlantAssetId = result;
    }).catch(error => {
      if (error) {
        showToast(this, error.body.message, 'Error', 'error');
        this.isLoading = false;
        this.promptSpinner();
      }
    });
  }

  /*
   *To read and upload a CSV file 
  */
  handleUploadFinished(event) {
    this.isLoading = true;
    this.promptSpinner();
    this.csvIdAndRowMap = new Map();
    this.siteMetadataArray = [];
    this.tempArray = [];
    let file = event.target.files[0];
    let reader = new FileReader();
    reader.readAsText(file);

    reader.onload = () => {
      let csvStr = reader.result;
      this.csvLines = csvStr.split('\n');
    };

    reader.onerror = () => {
    };

    // To read a  CSV file.
    readCSV({
      plantAssetId: this.plantAssetId,
      promptInfo: JSON.stringify(this.promptInfo)
    }).then(result => {
      var dataObj = JSON.stringify(result);
      this.readCsvAndImportRecords(dataObj, this.csvLines);
    }).catch(error => {
      if (error) {
        this.isLoading = false;
        this.promptSpinner();
        showToast(this, error.body.message, 'Error', 'error');
      }
    });
  }

  // to upload the csv file
  @api
  readCsvAndImportRecords(dataObj, csvLinesData, siteMetadataMapVal, promptSiteMetadata, picklistValuesMap, sitemetaRecordCountInCSV) {
    this.duplicateCheckArray = [];
    let siteMetadataRecords;
    let updateExecuteForSMCountGreaterInCSV = true;
    let siteMetadataMap = new Map();
    this.dataObjReadCsvAndImportRecords = dataObj;
    var isNormaluploadData = true;
    if (dataObj !== 'No Data') {
      dataObj = JSON.parse(dataObj);
      let siteMetadata = JSON.parse(dataObj.siteMetadata);
      for (var siteMetadataId in siteMetadata) {
        siteMetadataMap.set(siteMetadataId, siteMetadata[siteMetadataId]);
      }
      siteMetadataRecords = this.promptSiteMetadata;
    } else {
      this.isLoading = true;
      this.promptSpinner();
      isNormaluploadData = false;
      siteMetadataMap = siteMetadataMapVal;
      siteMetadataRecords = promptSiteMetadata;
    }

    this.csvLines = csvLinesData;
    var csvDataColumns = [];
    var duplicateCheck = [];
    var isExecute = true;
    var isUpdateExecute = true;
    var isDuplicate = true;
    var isDelete = false;
    var csvLinesHeaders = this.csvLines[0].split(',');
    var csvRowDataType = this.csvLines[1].split(',');
    var reference = this.csvLines[5].split(',');
    var uniqueValues = this.csvLines[4].split(',');
    var attributeType = this.csvLines[2].split(',');
    var csvDisplayHeaders = this.csvLines[6].split(',');
    var attrApiToDisplayNameMap = new Map();
    var parentAssetMap = new Map();
    var pickListDetailMap = new Map();
    var uniqueNameMap = new Map();
    var parentAssetValCheckMap = new Map();
    
    if(dataObj === 'No Data' && siteMetadataMap.size > sitemetaRecordCountInCSV && sitemetaRecordCountInCSV !== undefined){
      this.isLoading = false;
      this.promptSpinner();
      showToast(this, smCountGreaterThanRecordCountInCSV, 'Error', 'error', 'sticky');
      const showhidebuttons = new CustomEvent("showhidebuttons", {
        detail: {
          showGoToG1AndResumeButtonInPrompt: true,
        }
      });
      this.dispatchEvent(showhidebuttons);
    }else{
      for (var i = 7; i < this.csvLines.length; i++) {
        csvDataColumns = this.csvLines[i].split(',');
        for (var j = 1; j < csvDataColumns.length; j++) {
          if(!isEmptyOrSpaces(csvDataColumns[0])){
            if ((uniqueValues[j] == 'TRUE' || uniqueValues[j] == 'true') && reference[j] == 'Asset Name') {
              if(isEmptyOrSpaces(csvDataColumns[j])){
                let displayHeadersWithAssetName = csvDisplayHeaders[j];
                this.isAssetNameNotUnique = true;
                if(!this.duplicateCheckArray.includes(displayHeadersWithAssetName)){
                  this.duplicateCheckArray.push(displayHeadersWithAssetName);
                }
              }
            }

            if (uniqueValues[j] == 'TRUE' || uniqueValues[j] == 'true') {
              var assetNameConCatWithAttribute = csvLinesHeaders[j];
              attrApiToDisplayNameMap.set(csvLinesHeaders[j], csvDisplayHeaders[j]);
              
              if (uniqueNameMap.has(assetNameConCatWithAttribute)) {
                var existingValues = uniqueNameMap.get(assetNameConCatWithAttribute);
                if (!isEmptyOrSpaces(csvDataColumns[j])) {
                  existingValues.push(csvDataColumns[j].toLowerCase());
                  uniqueNameMap.set(assetNameConCatWithAttribute, existingValues);
                }
              } else {
                var attrVal = [];
                if (!isEmptyOrSpaces(csvDataColumns[j])) {
                  attrVal.push(csvDataColumns[j].toLowerCase());
                  uniqueNameMap.set(assetNameConCatWithAttribute, attrVal);
                }
              }
            }
          }
        }
      }

      for (let [key, value] of uniqueNameMap) {
        if (new Set(value).size !== value.length) {
          duplicateCheck.push(key);
          if(attrApiToDisplayNameMap.has(key)){
            if(!this.duplicateCheckArray.includes(attrApiToDisplayNameMap.get(key))){
              this.duplicateCheckArray.push(attrApiToDisplayNameMap.get(key));
            }
          }
        }
      }

      if (duplicateCheck.length > 0) {
        if(isNormaluploadData){
            isExecute = false;
            isDuplicate = false;
            this.isLoading = false;
            this.promptSpinner();
            showToast(this, duplicateCheck + ' ' + importcsvValidation, 'Error', 'error');
        } else{
          this.isAssetNameNotUnique = true;
        }
      }

      for (var key in siteMetadataRecords) {
        var entry = siteMetadataRecords[key];
        var attrMetadata = entry.attrMetadata;
        if (typeof entry.siteMetadataRecordId !== 'undefined' && typeof entry.parentSiteMetaDataAssetName !== 'undefined') {
          parentAssetValCheckMap.set(entry.siteMetadataRecordId, (entry.parentSiteMetaDataAssetName).toLowerCase());
        }
        attrMetadata.forEach(function (entry1) {
          var attrMetadataObj = entry1.attrMetadataObj;
          if (attrMetadataObj.parentId != '' && attrMetadataObj.parentAttrName != '') {
            parentAssetMap.set(attrMetadataObj.parentAttrName, attrMetadataObj.parentId);
          }
        });
      }
    
      var deviceTypeValueArray = [];
      for (var key in siteMetadataRecords) {
        var entry = siteMetadataRecords[key];
        var attrMetadata = entry.attrMetadata;
        attrMetadata.forEach(function (entry1) {
          var attrMetadataObj = entry1.attrMetadataObj;
          if ((!deviceTypeValueArray.includes(attrMetadataObj.batId) && attrMetadataObj.picklistValues.length > 0) || (deviceTypeValueArray.includes(attrMetadataObj.batId) && attrMetadataObj.picklistValues.length > 0 && !pickListDetailMap.has(attrMetadataObj.attributeHeaderName))) {
            if (attrMetadataObj.batId !== 'NoBat') {
              deviceTypeValueArray.push(attrMetadataObj.batId);
            }
            var pickListDetails = [];
            var picklistValueDeatails = attrMetadataObj.picklistValues;
            picklistValueDeatails.forEach(function (entry) {
              pickListDetails.push(entry.picklistVal);
            });
            pickListDetailMap.set(attrMetadataObj.attributeHeaderName, pickListDetails);
          }
        });
      }

      for (var i = 7; i < this.csvLines.length - 1; i++) {
        csvDataColumns = this.csvLines[i].split(',');
        var siteMetadataIdVal = csvDataColumns[0];
        var parentSiteMetadataValue = csvDataColumns[1].trim();
        for (var j = 1; j < csvDataColumns.length; j++) {
          if(reference[j] == 'Parent Asset'){
            if (siteMetadataIdVal != null && parentAssetValCheckMap.has(siteMetadataIdVal)) {
              if (parentSiteMetadataValue.toLowerCase() != parentAssetValCheckMap.get(siteMetadataIdVal)) {
                isExecute = false;
                isUpdateExecute = false;
                this.isLoading = false;
                this.promptSpinner();
                showToast(this, parentSiteMetadataErrMsg + '--> ' + parentSiteMetadataValue, 'Error', 'error', 'sticky');
                break;
              }
            } else {
              isExecute = false;
              isUpdateExecute = false;
              this.isLoading = false;
              this.promptSpinner();
              showToast(this, parentSiteMetadataErrMsg + '--> ' + parentSiteMetadataValue, 'Error', 'error', 'sticky');
              break;
            }
          }
        }
        if(!isExecute && !isUpdateExecute){
          break;
        }
      }

      if(!isUpdateExecute && dataObj === 'No Data'){
        const showhidebuttons = new CustomEvent("showhidebuttons", {
          detail: {
            showGoToG1AndResumeButtonInPrompt: true,
          }
        });
        this.dispatchEvent(showhidebuttons);
      } else {

        /*
          * Split the Total Csv lines in to Batches by ignoring the first four lines(Headers part)
          * Each batch default size is 100
        */
        for (var i = 7; i < this.csvLines.length - 1; i++) {
          csvDataColumns = this.csvLines[i].split(',');
          var siteMetadataId = csvDataColumns[0];
          var promptSpecificInfo;
          var attrInfo;
          var parentAssetName;
          var alternateParentAssetSiteMetadataId = '';
          parentAssetName = csvDataColumns[1];
          if (siteMetadataMap.has(siteMetadataId)) {
            promptSpecificInfo = JSON.parse(siteMetadataMap.get(siteMetadataId).Prompt_Specific_Info__c);
            attrInfo = JSON.parse(siteMetadataMap.get(siteMetadataId).Attribute_Info__c);
            for (var j = 1; j < csvDataColumns.length; j++) {
              if (reference[j] != 'Parent Asset') {
                var headerVal = csvLinesHeaders[j];
                headerVal = headerVal.replace(/[\r\n]+/gm, "");
                var columnValue = csvDataColumns[j];
                columnValue = columnValue.replace(/[\r\n]+/gm, "");
                var dataType = csvRowDataType[j];
                dataType = dataType.replace(/[\r\n]+/gm, "");
                if (dataType == 'Date') {
                  columnValue = columnValue.replace('/', '-');
                  columnValue = columnValue.replace('/', '-');
                }
                if (dataType == 'Date') {
                  columnValue = columnValue.replace('/', '-');
                  columnValue = columnValue.replace('/', '-');
                }
                if (columnValue == 'YES' || columnValue == 'yes') {
                  columnValue = 'Yes';
                }
                if (columnValue == 'NO' || columnValue == 'no') {
                  columnValue = 'No';
                }
                if (dataType == 'Checkbox') {
                  if (columnValue == 'TRUE' || columnValue == 'true') {
                    columnValue = 'TRUE';
                  } else {
                    columnValue = 'FALSE';
                  }
                }

                attributeType[j] = attributeType[j].replace(/[\r\n]+/gm, "");
                reference[j] = reference[j].replace(/[\r\n]+/gm, "");

                if (attributeType[j] == 'Prompt Attribute') {
                  var promptValue = siteMetadataMap.get(siteMetadataId).Prompt_Specific_Info__c;
                  if (promptValue != undefined && promptValue != null && promptValue != '{}') {
                    if (reference[j] == 'Alternate Parent Asset' || reference[j] == 'SFID') {
                      if (columnValue != '') {
                        columnValue = columnValue.toLowerCase();
                        var pickListValuesMap;
                        if (dataObj === 'No Data' && picklistValuesMap !== 'No Data' && picklistValuesMap !== undefined) {
                          pickListValuesMap = JSON.parse(JSON.stringify(picklistValuesMap));
                        } else {
                          pickListValuesMap = JSON.parse(JSON.stringify(this.picklistValues));
                        }

                        if (promptSpecificInfo.hasOwnProperty(headerVal)) {
                          var attrValues = [];
                          var pickValMap = new Map();
                          for (var key in pickListValuesMap) {
                            if (key.includes(headerVal)) {
                              if (key.includes(parentAssetMap.get(parentAssetName))) {
                                attrValues = [];
                                var pickMap = pickListValuesMap[key];
                                for (var parentId in pickMap) {
                                  attrValues.push((pickMap[parentId]).toLowerCase());
                                  pickValMap.set((pickMap[parentId].toLowerCase()), parentId);
                                }
                              }
                            }
                          }

                          if (attrValues.includes(columnValue)) {
                            promptSpecificInfo[headerVal] = pickValMap.get(columnValue);
                            if(reference[j] == 'Alternate Parent Asset'){
                              alternateParentAssetSiteMetadataId = pickValMap.get(columnValue);
                            }
                          } else {
                              if(isNormaluploadData){
                                isExecute = false;
                                this.isLoading = false;
                                this.promptSpinner();
                                showToast(this, alternateParentAssetErrMsg, 'Error', 'error');
                                break;
                            } else {
                              this.isAltParentNotMatch = true;
                            }
                          }
                        }
                      } else {
                        promptSpecificInfo[headerVal] = '';
                      }
                    } else if (reference[j] == 'Asset Name') {
                      promptSpecificInfo[headerVal] = columnValue;
                      siteMetadataMap.get(siteMetadataId).Asset_Name__c = columnValue;
                    } else if (reference[j] == 'readOnly') {
                      promptSpecificInfo[headerVal] = promptSpecificInfo[headerVal];
                    } else {
                      if (reference[j] == 'rowGenAttribute' && dataObj !== 'No Data') {
                        if (promptSpecificInfo[headerVal] > columnValue) {
                          isDelete = true;
                        }
                      }

                      if (csvRowDataType[j] == 'Picklist') {
                        if (pickListDetailMap.has(headerVal)) {
                          var picklistValues = pickListDetailMap.get(headerVal);
                          if (picklistValues.includes(columnValue)) {
                            promptSpecificInfo[headerVal] = columnValue;
                          } else {
                            promptSpecificInfo[headerVal] = '';
                          }
                        }
                      } else {
                        promptSpecificInfo[headerVal] = columnValue;
                      }
                    }
                  }
                } else {
                  var attrValue = siteMetadataMap.get(siteMetadataId).Attribute_Info__c;
                  if (attrValue != undefined && attrValue != null && attrValue != '{}') {
                    if (reference[j] == 'SFID') {
                      var pickListValuesMap;
                      if (dataObj === 'No Data' && picklistValuesMap !== 'No Data' && picklistValuesMap !== undefined) {
                        pickListValuesMap = JSON.parse(JSON.stringify(picklistValuesMap));
                      } else {
                        pickListValuesMap = JSON.parse(JSON.stringify(this.picklistValues));
                      }
                      if (columnValue != '') {
                        columnValue = columnValue.toLowerCase();
                        if (attrInfo.hasOwnProperty(headerVal)) {
                          var attrValues = [];
                          var pickValMap = new Map();
                          for (var key in pickListValuesMap) {
                            if (key.includes(headerVal)) {
                              if (key.includes(parentAssetMap.get(parentAssetName))) {
                                attrValues = [];
                                var pickMap = pickListValuesMap[key];
                                for (var parentId in pickMap) {
                                  attrValues.push((pickMap[parentId]).toLowerCase());
                                  pickValMap.set((pickMap[parentId]).toLowerCase(), parentId);
                                }
                              }
                            }
                          }

                          if (attrValues.includes(columnValue)) {
                            attrInfo[headerVal] = pickValMap.get(columnValue);
                          } else {
                            if(isNormaluploadData){
                              isExecute = false;
                              this.isLoading = false;
                              this.promptSpinner();
                              showToast(this, alternateParentAssetErrMsg, 'Error', 'error');
                              break;
                            } else {
                              this.isAltParentNotMatch = true;
                            }
                          }
                        }
                      } else {
                        if (attrInfo.hasOwnProperty(headerVal)) {
                          attrInfo[headerVal] = '';
                        }
                      }
                    } else {
                      if (attrInfo.hasOwnProperty(headerVal)) {
                        if (csvRowDataType[j] == 'Picklist') {
                          if (pickListDetailMap.has(headerVal)) {
                            var picklistValues = pickListDetailMap.get(headerVal);
                            if (picklistValues.includes(columnValue)) {
                              attrInfo[headerVal] = columnValue;
                            } else {
                              attrInfo[headerVal] = '';
                            }
                          }
                        } else {
                          attrInfo[headerVal] = columnValue;
                        }
                      }
                    }
                  }
                }
              }
            }
            if (siteMetadataMap.has(siteMetadataId)) {
              siteMetadataMap.get(siteMetadataId).Prompt_Specific_Info__c = JSON.stringify(promptSpecificInfo);
              siteMetadataMap.get(siteMetadataId).Attribute_Info__c = JSON.stringify(attrInfo);
              siteMetadataMap.get(siteMetadataId).Alternate_Parent_Site_Metadata__c = alternateParentAssetSiteMetadataId;
              this.siteMetadataArray.push(siteMetadataMap.get(siteMetadataId));
            }
          } else if(dataObj === 'No Data' && siteMetadataMap.size < sitemetaRecordCountInCSV && sitemetaRecordCountInCSV !== undefined) {
            updateExecuteForSMCountGreaterInCSV = false;
            
          }
        }

        if(!updateExecuteForSMCountGreaterInCSV){
          showToast(this, smCountLesserThanRecordCountInCSV, 'Info', 'info', 'sticky');
        }

        if (isExecute && isDuplicate && this.siteMetadataArray.length > 0) {
          this.ConfirmationModalTitle = confirmationPopupTitleOnDelete;
          if (dataObj !== 'No Data') {
            this.showConfirmPopupOnDelete = isDelete;
            this.popUpDeleteWarnMsg = this.promptInfo.Confirm_Message_On_Next__c;
          }
          let chunk = 100;
          if (!isDelete) {
            if (this.siteMetadataArray.length > 0) {
              var count = 0;
              var finalBtach = 0;
              if (this.siteMetadataArray.length % 100 == 0) {
                finalBtach = this.siteMetadataArray.length / 100;
              }
              for (var k = 0; k < this.siteMetadataArray.length; k += chunk) {
                this.tempArray = [];
                count = count + 1;
                this.tempArray = this.siteMetadataArray.slice(k, k + chunk);
                if (this.tempArray.length == 100) {
                  if (finalBtach > 0 && (finalBtach == count)) {
                    this.updateSiteMetadataFn(this.tempArray, true, false);
                  } else {
                    this.updateSiteMetadataFn(this.tempArray, false, false);
                  }

                } else if (this.tempArray.length < 100) {
                  this.updateSiteMetadataFn(this.tempArray, true, false);
                }
              }
            } else {
              this.isLoading = false;
              this.promptSpinner();
              if (dataObj !== 'No Data') {
                const refresh = new CustomEvent("refresh", {
                  detail: {
                    refreshDatatable: true,
                  }
                });
                this.dispatchEvent(refresh);
              }
            }
          } else {
            this.isLoading = false;
            this.promptSpinner();
          }
        }
      }
    }
  }

  //confirmation on delete
  handlePreviousOnConfirm(event) {
    this.confirmPopupOnDelete = event.detail.confirmationOutput;
    if (this.confirmPopupOnDelete) {
      this.showConfirmPopupOnDelete = false;
      if (this.confirmPopupOnDelete) {
        if (this.siteMetadataArray.length > 0) {
          var count = 0;
          var finalBtach = 0;
          if (this.siteMetadataArray.length % 100 == 0) {
            finalBtach = this.siteMetadataArray.length / 100;
          }
          let chunk = 100;
          for (var i = 0; i < this.siteMetadataArray.length; i += chunk) {
            this.tempArray = [];
            this.tempArray = this.siteMetadataArray.slice(i, i + chunk);
            if (this.tempArray.length == 100) {
              if (finalBtach > 0 && (finalBtach == count)) {
                this.updateSiteMetadataFn(this.tempArray, true, this.confirmPopupOnDelete);
              } else {
                this.updateSiteMetadataFn(this.tempArray, false, false);
              }
            } else if (this.tempArray.length <= 100) {
              this.updateSiteMetadataFn(this.tempArray, true, this.confirmPopupOnDelete);
            }
          }
        }
      }
    } else {
      this.showConfirmPopupOnDelete = false;
      this.isLoading = false;
      this.promptSpinner();
    }
  }
  /*
   * to update the SiteMetadata records with the updated CSV File.
  */
  updateSiteMetadataFn(tempArray, isLastBatch, isDelete) {
    updateSiteMetadata({
      siteMetadataRecords: JSON.stringify(tempArray),
      isDelete: isDelete,
      isLastBatch: isLastBatch
    }).then(result => {
      if (result) {
        if (isLastBatch) {
          this.isLoading = false;
          this.promptSpinner();
          if (this.dataObjReadCsvAndImportRecords === 'No Data') {
            const callnext = new CustomEvent("callnext", {
              detail: {
                callNextForBulkImport: true,
                isAssetNameNotUnique: this.isAssetNameNotUnique,
                isAltParentNotMatch: this.isAltParentNotMatch,
                duplicateCheckArray: this.duplicateCheckArray
              }
            });
            this.dispatchEvent(callnext);
          } else {
            const refresh = new CustomEvent("refresh", {
              detail: {
                refreshDatatable: true,
              }
            });
            this.dispatchEvent(refresh);
          }
        }
      }
    }).catch(error => {
      if (error) {
        showToast(this, error.body.message, 'Error', 'error');
        this.isLoading = false;
        this.promptSpinner();
      }
    });
  }

  exportCSVFile() {
    this.isLoading = true;
    this.promptSpinner();
    var siteMetadataRecords = this.promptSiteMetadata;
    var csvString = '';
    var rowEnd = '\n';
    var dataType = ['Data Type'];
    var customerFacingNotes = ['Customer Facing Notes'];
    var attrType = ['Attribute Type'];
    var reference = ['Reference'];
    var aliasName = ['Alias Name'];
    var siteMetaRecordId = ['Core Attribute API Name'];
    var isUnique = ['Is Unique'];
    for (var siteMetadata in siteMetadataRecords) {
      if (siteMetadata == 0) {
        var entry = siteMetadataRecords[siteMetadata];
        var attrMetadata = entry.attrMetadata;
        attrMetadata.forEach(function (entry1) {
          var attrMetadataObj = entry1.attrMetadataObj;
          dataType.push(attrMetadataObj.attributeDataTypeForCSVExport);
          if (attrMetadataObj.isAssetName) {
            reference.push('Asset Name');
          } else if (attrMetadataObj.isParentAsset) {
            reference.push('Parent Asset');
          } else if (attrMetadataObj.isAlternateParent) {
            reference.push('Alternate Parent Asset');
          } else if (attrMetadataObj.isDisabled) {
            reference.push('readOnly');
          } else if (attrMetadataObj.keyFieldToGenerateRowCheck) {
            reference.push('rowGenAttribute');
          }
          else if (attrMetadataObj.attrInfo.Picklist_Dependency1__r) {
            reference.push('SFID');
          }
          else {
            reference.push('Value');
          }

          //To remove the line breaks in the customer facing notes.
          let customerFacingNote = attrMetadataObj.customerFacingNotes.replace(/\n/g, "");
          customerFacingNotes.push('"' + customerFacingNote.replaceAll('"', '`') + '"');
          if (attrMetadataObj.isPromptSpecificAttr) {
            attrType.push('Prompt Attribute');
          } else {
            attrType.push('CoreAttribute');
          }

          siteMetaRecordId.push(attrMetadataObj.attributeHeaderName);
          aliasName.push(attrMetadataObj.attributeHeader);
          isUnique.push(attrMetadataObj.isUnique);
        });
      }
    }

    csvString += siteMetaRecordId.join(',');
    csvString += rowEnd;
    csvString += dataType.join(',');
    csvString += rowEnd;
    csvString += attrType.join(',');
    csvString += rowEnd;
    csvString += customerFacingNotes.join(',');
    csvString += rowEnd;
    csvString += isUnique.join(',');
    csvString += rowEnd;
    csvString += reference.join(',');
    csvString += rowEnd;
    csvString += aliasName.join(',');
    csvString += rowEnd;

    for (var siteMetadata in siteMetadataRecords) {
      var recordData = [];
      var entry = siteMetadataRecords[siteMetadata];
      var attrMetadata = entry.attrMetadata;
      recordData.push(siteMetadataRecords[siteMetadata].siteMetadataRecordId);
      attrMetadata.forEach(function (entry1) {
        var attrMetadataObj = entry1.attrMetadataObj;
        if (attrMetadataObj.isPicklist && attrMetadataObj.picklistValues != undefined) {
          if (attrMetadataObj.attributeValue == '--None--') {
            recordData.push('');
          } else if (attrMetadataObj.attributeValue != '') {
            var pickListVal = attrMetadataObj.picklistValues;
            pickListVal.forEach(function (entry2) {
              if (entry2.picklistVal == attrMetadataObj.attributeValue) {
                recordData.push(entry2.picklistLabel);
              }
            });
          } else {
            recordData.push('');
          }
        } else if (attrMetadataObj.isPicklist) {
          recordData.push('');
        } else {
          recordData.push(attrMetadataObj.attributeValue);
        }
      });
      csvString += recordData.join(',');
      csvString += rowEnd;
    }

    this.isLoading = false;
    this.promptSpinner();
    // CSV File Name
    let downloadElement = document.createElement('a');

    // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
    downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvString);
    downloadElement.target = '_self';
    // CSV File Name
    downloadElement.download = this.customerPlantAssetId + '_' + this.promptInfo.Name + '.csv';
    // below statement is required if you are using firefox browser
    document.body.appendChild(downloadElement);
    // click() Javascript function to download CSV file
    downloadElement.click();

    this.isLoading = false;
    showToast(this, 'SiteMetadata exported Successfully!', 'Info', 'success');
  }

  /**
   * this method is used to show spinner in this component while Export/Import is made.
   */
  promptSpinner() {
    const spinner = new CustomEvent("spinner", {
      detail: {
        spinnerVal: this.isLoading,
        recordCount: (this.csvLines.length - 6)
      }
    });
    this.dispatchEvent(spinner);
  }
}