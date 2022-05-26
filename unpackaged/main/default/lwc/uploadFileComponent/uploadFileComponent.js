import { LightningElement, api, track} from 'lwc';
import fileUpload from '@salesforce/apex/ReadExcelAsCSV.fileUpload';
import getG1PAPD from '@salesforce/apex/Utils.getG1PlantAssetPromptDetail';
import deleteCSV from '@salesforce/apex/ReadExcelAsCSV.deleteContentDocument';
import ErrorInGetingG1PlantAssetPromptDetail from '@salesforce/label/c.ErrorInGetingG1PlantAssetPromptDetail';
import FailedToLoadFile from '@salesforce/label/c.FailedToLoadFile';
import bulkImportMultipleBATInfoMessage from '@salesforce/label/c.bulkImportMultipleBATInfoMessage';
import bulkImportSingleBATInfoMessage from '@salesforce/label/c.bulkImportSingleBATInfoMessage';
import UploadedSuccessfully from '@salesforce/label/c.UploadedSuccessfully';
import ErrorWhileUploadingCsvFileInPlantAssetPromptDetail from '@salesforce/label/c.ErrorWhileUploadingCsvFileInPlantAssetPromptDetail';
import ErrorWhileDeletingCsvFileInPlantAssetPromptDetail from '@salesforce/label/c.ErrorWhileDeletingCsvFileInPlantAssetPromptDetail';
import InvalidFileSelectedKindlySelectFileTypeRelateTo from '@salesforce/label/c.InvalidFileSelectedKindlySelectFileTypeRelateTo';
import { fireEvent } from 'c/pubsub';
import {
  showToast,
  bulkImportTypePicklistValues
} from "c/utils";


export default class UploadFileComponent extends LightningElement {
  @api plantAssetId;
  @api xlsFileData; //excel file from button click
  @api showInfoMessage = false;
  @track bulkImportType; //This will show whether Bulk Import is for Single BAT or Multiple BAT
  @track bulkImportTypePicklistValuesObj = {};
  papdId = '';
  pageRef = 'Asset Builder';
  currentCSVInPAPD = [];

  get acceptedFormats() { 
    return ['.xlsx']; // allow on xlsx format
  }
  /**
   * Registers a callback to retrieve the plant asset prompt detail against selected plant asset
   */
  connectedCallback(){
    getG1PAPD({
      plantAssetId : this.plantAssetId
    }).then(result => {
      if(result){
        this.papdId = result.Id;
        this.bulkImportType = result.Bulk_Import_Type__c;
        this.bulkImportTypePicklistValuesObj = bulkImportTypePicklistValues();
        if(result.Bulk_Import_Type__c === this.bulkImportTypePicklistValuesObj.singleBaseAssetTemplate){
          this.showInfoMessage = true;
          this.bulkImportInfoMessage = bulkImportSingleBATInfoMessage;
          this.className = 'infoBox';
          this.iconName = 'utility:info_alt';
          this.title = 'Info';
        } else if(result.Bulk_Import_Type__c === this.bulkImportTypePicklistValuesObj.multipleBaseAssetTemplate){
          this.showInfoMessage = true;
          this.bulkImportInfoMessage = bulkImportMultipleBATInfoMessage;
          this.className = 'infoBox';
          this.iconName = 'utility:info_alt';
          this.title = 'Info';
        } else{
          this.showInfoMessage = false;
        }
      }
    }).catch(error => {
      fireEvent(this.pageRef, 'showspinnercomp', false);
      showToast(this, ErrorInGetingG1PlantAssetPromptDetail, 'Error', 'error');
    });
  }

  /*
  This function is used to get the data from the uploaded file and send xlsxMain component for csv convertion
  */
  handleFileChange(event) {
    fireEvent(this.pageRef, 'showspinnercomp', true);
    var uploadedXlsFile = event.target.files[0];
    //To check the selected file in xlsx format
    var validExts = new Array(".xlsx");
    var fileExt = uploadedXlsFile.name;
    fileExt = fileExt.substring(fileExt.lastIndexOf('.'));
    if (validExts.indexOf(fileExt) >= 0) {
      if (uploadedXlsFile) {
          var reader = new FileReader();
          reader.onload = e => {
            this.xlsFileData = e.target.result;
            this.template.querySelector('c-xlsx-main').processExcelToCSV(this.xlsFileData);
          }
          reader.readAsBinaryString(uploadedXlsFile);
      } else {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this, FailedToLoadFile, 'Error', 'error');
      }
    }
    else{
      fireEvent(this.pageRef, 'showspinnercomp', false);
      showToast(this, InvalidFileSelectedKindlySelectFileTypeRelateTo+validExts.toString(), 'Error', 'error');
    } 
  }

  /* 
  * Method for close button
  */  
  handleCancel(event) {
    const selectedEvent = new CustomEvent("confirm", {
      detail: {
        confirmationOutput: false,
      }
    });
    this.dispatchEvent(selectedEvent);
  }

  /* 
  * Method to pass csv file to server side controller(apex class), to upload files in plant asset prompt detail
  */ 
  handleUploadCSV(event){
    try{
      var csvFiles = event.detail.csvFiles;
      for(let nameOfCsv in csvFiles){
        let fileName = nameOfCsv+'.csv';
        fileUpload({
          csvToShow : csvFiles[nameOfCsv],
          papdId: this.papdId,
          fileName: fileName,
        }).then(result => {
          if(result.length >0){
            this.currentCSVInPAPD.push(result);
            if(Object.keys(csvFiles).length == this.currentCSVInPAPD.length){
              if(this.bulkImportType === this.bulkImportTypePicklistValuesObj.singleBaseAssetTemplate){
                fireEvent(this.pageRef, 'callG1NextFromBulkUpload', true); //Fired a event to call g1 next logic
                fireEvent(this.pageRef, 'setBulkImportVariable', true); //Fired a event to indicate bulk import started for Single BAT
                fireEvent(this.pageRef, 'setBulkImportVariableForMultipleBAT', false); //Fired a event to indicate bulk import started for Multiple BAT as false
              } else if(this.bulkImportType === this.bulkImportTypePicklistValuesObj.multipleBaseAssetTemplate){
                fireEvent(this.pageRef, 'callG1NextFromBulkUploadForMultipleBAT', true); //Fired a event to call g1 next logic for multiple BAT Bulk Import
                fireEvent(this.pageRef, 'setBulkImportVariableForMultipleBAT', true); //Fired a event to indicate bulk import started for Multiple BAT
                fireEvent(this.pageRef, 'setBulkImportVariable', false); //Fired a event to indicate bulk import started for Single BAT as false
              }
              fireEvent(this.pageRef, 'showspinnercomp', false);
              showToast(this, UploadedSuccessfully, 'Success', 'success');
              const selectedEvent = new CustomEvent("confirm", {
                detail: {
                  confirmationOutput: false,
                }
              });
              this.dispatchEvent(selectedEvent);//To close upload popup immediately whenever upload completed
            }
          }
        }).catch(error => {
          deleteCSV({currentCSVInPAPD : this.currentCSVInPAPD})
            .then(result => {
            }).catch(error => {
              fireEvent(this.pageRef, 'showspinnercomp', false);
              showToast(this, ErrorWhileDeletingCsvFileInPlantAssetPromptDetail, 'Error', 'error');
            });
            this.currentCSVInPAPD.length = 0;
            fireEvent(this.pageRef, 'showspinnercomp', false);
            showToast(this, ErrorWhileUploadingCsvFileInPlantAssetPromptDetail, 'Error', 'error');
        });
      }
    }catch(error){
      fireEvent(this.pageRef, 'showspinnercomp', false);
      showToast(this, ErrorWhileUploadingCsvFileInPlantAssetPromptDetail, 'Error', 'error');
    }
  }
}