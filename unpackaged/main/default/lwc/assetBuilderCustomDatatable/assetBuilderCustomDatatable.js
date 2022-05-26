import { LightningElement, api, track, wire } from 'lwc';
import pageCount from '@salesforce/label/c.PageCount';
import getAttrReqFromCustomMetadata from "@salesforce/apex/Utils.getAttrReqFromCustomMetadata";
import { fireEvent } from 'c/pubsub';
import { loadScript } from 'lightning/platformResourceLoader';
import momentLib from '@salesforce/resourceUrl/Moment';
import jQueryLib from '@salesforce/resourceUrl/jQuery';
import LOCALE from '@salesforce/i18n/locale';
import dateFormatToLocale from '@salesforce/resourceUrl/DateFormatToLocale';

import {
  allowOnlyWholeNumber,
  validateDecimalInput,
  findDuplicateInArray,
  isEmptyOrSpaces,
  showToast,
  getcustomDataTable
} from "c/utils";

/**
 * 
 * @param {object} inputsToFormDatatable- This attribute hold the Site Metadata, Attribute, Prompt Information, Picklist values and Plant Asst Prompt Detail.
 * @param {boolean} isVertical - This attribute will be used to show the Table in Vertical view.
 * @param {number} countOfRecords - This attribute will have the count of Site Metadata Records.
 * @param {object} dataTableOutput - This attribute will have the values, which are changed in the Data Table.
 * @param {object} tableHeaders - This attribute will have the Column Headers and Customer Facing Notes.
 * @param {array} header - This attribute will have the attribute Name.
 * @param {boolean} isSpinner - This attribute will be used to show the spinner on the Table.
 * @param {boolean} isNameUnique - This attribute will have the boolean to unique value on the attributes.
 * @param {boolean} isKeyFieldToGenerateRows - This attribute will have the boolean for the Prompt Specific Attributes with Is Key To Generate Rows Checked.
 * @param {number} colCount - This attribute will have the Total Column Count in a Table.
 * @param {number} totalRowCount - This attribute will have the Total Row Count in a Table.
 * @param {object} driveAndDrivePlusTableCells - This attribute will have the Drive and Drive Plus Categorization.
 * @param {number} page - This attribute will Initialize the 1st Page. 
 * @param {number} startingRecord - This attribute will have the Start Record Position Per Page.
 * @param {number} endingRecord - This attribute will have the end Record Position Per Page.
 * @param {number} totalRecountCount - This attribute will have the total record count received from all retrieved records.
 * @param {number} pageSize - This attribute will have the Page Size.
 * @param {number} totalPage - This attribute will have the total number of page is needed to display all records.
 * @param {object} data - This attribute will have Site Metadata Record Id, Attribute Concatenate Name and Row Index.
 * @param {object} oldSiteMetadataValueArray - This attribute will have Site Metadata Record Id, Attribute Concatenate Name and Row Index.
 * @param {object} attrReq - This attribute will have Drive and Drive Plus from the Custom Metadata Type.
 * @param {map} smOldValueMap - This attribute will have Concatenate value of Site Metadata Record Id with attribute Name to Old value.
 * @param {map} picklistFieldAndValue - This attribute will have Picklist Master Id and the Respective Picklist Values.
 */
export default class AssetBuilderCustomDatatable extends LightningElement {
  @api inputsToFormDatatable;
  @api isVertical = false;
  @api countOfRecords = false;
  @track dataTableOutput = [];
  @track tableHeaders = [];
  @track header = [];
  @track isSpinner = false;
  isNameUnique = true;
  isKeyFieldToGenerateRows = false;
  picklistFieldAndValue = new Map();
  colCount = 0;
  totalRowCount = 0;
  driveAndDrivePlusTableCells = [];//Store Highlighted cells
  isAttrReqValChng = false;
  @track page = 1; //this will initialize 1st page
  @track startingRecord = 1; //start record position per page
  @track endingRecord = 0; //end record position per page
  @track pageSize = 25;
  @track totalRecountCount = 0; //total record count received from all retrieved records
  @track totalPage = 0; //total number of page is needed to display all records
  data = [];
  oldSiteMetadataValueArray = [];
  @track attrReq = [];//To store Attribute Requirements
  pageRef = 'Asset Builder';
  isNameUnique = true;
  isKeyFieldToGenerateRows = false;
  colCount = 0;
  totalRowCount = 0;
  data = [];
  smOldValueMap = new Map(); 
  picklistFieldAndValue = new Map();
  uniqueValidationColName = new Set();

  attrHLVal; // Attribute Highlighter Value selected in radio button
  @track attrHLValue;
  @api selectedAttrVal;
  @api isReadOnly; //Passed from every prompts to decide all fields are readOnly
  @track cssClassCellBuffer;
  dateFormatBasedLocale = 'MM-DD-YYYY';

  clearDate(event){
    let cellIndex = event.target.dataset.cellindex;
    let rowIndex = event.target.dataset.rowindex;
    let parsedRowIndex = parseInt(rowIndex, 10);
    const constantInt = 1;
    let datatableRowIndex = parsedRowIndex + constantInt;
    let element;

    if(this.isVertical){
      element = this.template.querySelector('table').rows[cellIndex].cells.item(1);
    }else{
      element = this.template.querySelector('table').rows[datatableRowIndex].cells.item(cellIndex);
    }

    element.children[0].value = '';
    element.children[0].dataset.date = '';
    let onChangeEvent = new Event('change');
    element.children[0].dispatchEvent(onChangeEvent);
  }

  connectedCallback() {
    /**
   * Registers a callback to retrieve Attribute Requirement from custom metadata
   */
    getAttrReqFromCustomMetadata({}).then(result => {
      if(result){
        let inputDataForCustomDataTable = JSON.parse(result);
        let attrReq = inputDataForCustomDataTable.attrReqLst;

        if(inputDataForCustomDataTable.theme !== 'Theme3'){
          this.cssClassCellBuffer = 'tableCellbuffer';
        }else{
          this.cssClassCellBuffer = 'tableCellbufferComm';
        }

        for(let i in attrReq){
          let str = attrReq[i];
          this.attrReq.push({
            key : str,
            value : str.split(" ").join("")
          })
        }

       let radioBtns = this.template.querySelectorAll('.radioBtn');
        if(!this.selectedAttrVal){ 
          for(let radioBtnCount = 0; radioBtnCount < radioBtns.length; radioBtnCount++){
            if(radioBtns[radioBtnCount].value === 'None'){
              radioBtns[radioBtnCount].checked = true;
            }
          } 
        }
      }
    })
    .catch(error => {      
      showToast(this,error.body.message,'Error','error');
    });
    
    let inputData = JSON.parse(this.inputsToFormDatatable);
    let inputDataFromUtils;
    let additionalParams = {selectedAttrVal : this.selectedAttrVal !== undefined ? this.selectedAttrVal : 'None',
                            isReadOnly: this.isReadOnly};	
    inputDataFromUtils = getcustomDataTable(inputData, additionalParams);
    
    this.data = inputDataFromUtils.data;
    this.oldSiteMetadataValueArray = inputDataFromUtils.data;
    this.tableHeaders = inputDataFromUtils.tableHeaders[0];
    this.header = inputDataFromUtils.header;
    this.picklistFieldAndValue = inputDataFromUtils.picklistFieldAndValueMap
    fireEvent(this.pageRef, 'getDataFromAssetDataTable', this.data);
    this.pageSize = parseInt(pageCount);
    this.totalRecountCount = this.data.length;
    if(this.totalRecountCount > 100){
      this.countOfRecords = true;
    }
    this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); //here it is 5
    this.dataTableOutput = this.data.slice(0, this.pageSize);
    this.endingRecord = this.pageSize;
    this.totalRowCount = inputDataFromUtils.rowCount;
  }
  
  //Removal and Addition of classname for Attribute Highlighter Selected value
  attrHLValueHandler(classNameVar){
    var classNameValRet;
    var classNameValue = [];
    classNameValue = classNameVar.split(' ');

    if(this.attrHLVal === 'None'){ 
      if(classNameValue.includes('drivePlusHighlighter') ){
      var index = classNameValue.indexOf('drivePlusHighlighter');
        if (index !== -1) {
          classNameValue.splice(index, 1);
        }
      }
      if(classNameValue.includes('driveHighlighter')){
        var index = classNameValue.indexOf('driveHighlighter');
        if (index !== -1) {
          classNameValue.splice(index, 1);
        }
      }
      classNameValRet = classNameValue.join(' ');
    }

    if(this.attrHLVal === 'Drive'){ 
      if(classNameVar.includes('Drive')){
        if(classNameValue.includes('driveHighlighter') == false){
          classNameValue.push('driveHighlighter');
          }
        }
        if(classNameVar.includes('DrivePlus')){
          if(classNameValue.includes('drivePlusHighlighter') == true){
           var index1 = classNameValue.indexOf('drivePlusHighlighter');
           if (index1 !== -1){
            classNameValue.splice(index1, 1);
           }
          }
        }
        if(classNameVar.includes('Drive DrivePlus')){
          if(classNameValue.includes('drivePlusHighlighter') == true){
            var index1 = classNameValue.indexOf('drivePlusHighlighter');
           
            if (index1 !== -1) {
              classNameValue.splice(index1, 1);
            }
          }
        }
     classNameValRet = classNameValue.join(' ');
     }

     if(this.attrHLVal === 'DrivePlus'){
        var index1 = classNameValue.indexOf('driveHighlighter');
        if (index1 !== -1) {
          classNameValue.splice(index1, 1);
        }
        if(classNameVar.includes('DrivePlus') == true){
          if(classNameValue.includes('drivePlusHighlighter') == false){
            classNameValue.push('drivePlusHighlighter');
           
          }
        }
        if(classNameVar.includes('Drive')){
          if(classNameValue.includes('driveHighlighter') == true){
           
           var index1 = classNameValue.indexOf('driveHighlighter');
           
            if (index1 !== -1) {
            classNameValue.splice(index1, 1);
          }
         }
        }
        if(classNameVar.includes('Drive DrivePlus')){
      
          if(classNameValue.includes('driveHighlighter') == true){
            var index1 = classNameValue.indexOf('driveHighlighter');
          
            if (index1 !== -1) {
              classNameValue.splice(index1, 1);
            }
          }
        }
        classNameValRet = classNameValue.join(' ');
      }
     
     if(this.attrHLVal != null ){
        return  classNameValRet;
    }
    else{
    return classNameVar;
    }
  }

  // Function for attribute highlighter function call
  attrHLfunction(dataTableOutput){

    var slicedOutput =dataTableOutput;
    for(let sm = 0; sm <slicedOutput.length; sm++){
      for(let att = 0;att<slicedOutput[sm].attrMetadata.length;att++){
        var attrMetdataVar = slicedOutput[sm].attrMetadata[att];
        var classNameVar = attrMetdataVar.attrMetadataObj.className; 
        classNameVar = this.attrHLValueHandler(classNameVar);
        attrMetdataVar.attrMetadataObj.className = classNameVar;
      }
    }
  }

  //clicking on previous button this method will be called to set the Radio Button Default and reducing the page number by 1.
  previousHandler() {
    if (this.page > 1) {
      this.dataTableOutput = this.data.slice((this.page - 2) * this.pageSize, (this.page - 1) * this.pageSize);
      this.attrHLfunction(this.dataTableOutput);
      if (this.dataTableOutput.length != 0) {
        this.page = this.page - 1;
        //decrease page by 1
        this.displayRecordPerPage(this.page);
      }
    }
  } 

  //clicking on next button this method will be called to set the Radio Button Default and increasing the page number by 1.
  nextHandler() {
     if ((this.page < this.totalPage) && this.page !== this.totalPage) {
      this.dataTableOutput = this.data.slice(this.page * this.pageSize, (this.page + 1) * this.pageSize);
      this.attrHLfunction(this.dataTableOutput);
      this.page = this.page + 1; //increase page by 1
      this.displayRecordPerPage(this.page);
    }
  }

  //this method displays records page by page
  displayRecordPerPage(page) {
    this.startingRecord = ((page - 1) * this.pageSize);
    this.endingRecord = (this.pageSize * page);
    this.endingRecord = (this.endingRecord > this.totalRecountCount)
      ? this.totalRecountCount : this.endingRecord;
    this.startingRecord = this.startingRecord + 1;
  }

  /**
   * This method is used to check whether the attribute name is present in the JSON File.
   * @param {string} attrHeader - This attribute will have the Attribute Name. 
   * @param {object} attrInfoJSON - This attribute will have the Attribute Name and Attribute Value.
   */
  checkAttrNameInSiteMetadatAttrJSON(attrHeader, attrInfoJSON) {
    if (attrInfoJSON && attrHeader) {
      let attrValueArray = [];

      JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
        attrValueArray.push(attrJSONKey);
      });
      return !attrValueArray.includes(attrHeader);
    }
  }

  //This method is used to fire an event to get the Old and New Attribute values of a Site Metadata Record along with the Site Metadata Record Id.
  inputChangeHandler(event) {
    let rowIndex = event.target.dataset.rowindex;
    let cellIndex = event.target.dataset.cellindex;
    let isBifacial = event.target.dataset.isbifacial;

    let siteMetadataRecordId = this.data[rowIndex].siteMetadataRecordId;
    let isPromptSpecificAttr = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.isPromptSpecificAttr;

    let attributeName = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeHeaderName;
    let attributeHeaderAndUOM = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeHeaderAndUOM;

    let keyFieldToGenerateRowCheckValue = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.keyFieldToGenerateRowCheck;
    let isUnique = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.isUnique;
    let attributeDataType = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeDataType;
    let newAttributeValue = (typeof event.target.value !== 'undefined') ? event.target.value : '';
    let oldAttributeValue;

    let sitemetadataIdAndAttrName = siteMetadataRecordId + attributeName;
    if(!this.smOldValueMap.has(sitemetadataIdAndAttrName)){
      oldAttributeValue = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeValue;
      this.smOldValueMap.set(sitemetadataIdAndAttrName, oldAttributeValue);
    }else{
      oldAttributeValue = this.smOldValueMap.get(sitemetadataIdAndAttrName);
    }

    this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeValue = (attributeDataType === 'Checkbox') ? event.target.checked : newAttributeValue.trim();

    if(attributeName === 'SUBARRAY_BIFACIAL'){
      let newAttrValue = event.target.checked;
      this.hideAndShowBifacialFields(this, rowIndex, cellIndex, newAttrValue);
    }

    if (isUnique) {
      this.isNameUnique = this.uniqueNameValidation(this, rowIndex, cellIndex, newAttributeValue.toLowerCase());

      if(!this.isNameUnique){
        this.uniqueValidationColName.add(attributeHeaderAndUOM);
      }else{
        this.uniqueValidationColName.delete(attributeHeaderAndUOM);
      }
    }

    let attrDetails = {
      attributeName: attributeName,
      attributeHeaderAndUOM : attributeHeaderAndUOM,
      newAttributeValue: (attributeDataType === 'Checkbox') ? event.target.checked : newAttributeValue.trim(),
      oldAttributeValue: oldAttributeValue,
      isPromptSpecificAttr: isPromptSpecificAttr,
      isAssetNameUnique: this.isNameUnique,
      keyFieldToGenerateRowCheckValue: keyFieldToGenerateRowCheckValue,
      attributeDataType: attributeDataType,
      uniqueValidationColName: this.uniqueValidationColName,
      isBifacial : isBifacial
    }

    fireEvent(this.pageRef, 'getDataFromAssetDataTable', this.data);
    this.dispatchEvent(
      new CustomEvent("attrvaluechange", {
        detail: {
          siteMetadataRecordId: siteMetadataRecordId,
          attrDetails: attrDetails,
        }
      })
    );
  }

  /**
   * This method is used to restrict the user from entering the Decimal Values in Number Data Type
   * and validating the Decimal values entered by the user.
   */
  renderedCallback() {
    Promise.all([
      loadScript(this, jQueryLib + '/jQuery/jquery-2.2.4.min.js' ),
      loadScript(this, momentLib + '/Moment/moment.min.js'),
      loadScript(this, dateFormatToLocale)
    ])
    .then(() => { 
      let templateDate = this.template.querySelectorAll('.Date');
      if(templateDate.length > 0){
        for(let dateFieldCount = 0; dateFieldCount < templateDate.length; dateFieldCount++){
          $(templateDate[dateFieldCount]).on("change", function() {
            if(window.DateFormatToLocaleMap.hasOwnProperty(LOCALE)){
              this.dateFormatBasedLocale = window.DateFormatToLocaleMap[LOCALE].toString();      
            }

            let dateValueFormat = moment(this.value, "YYYY-MM-DD").format(this.dateFormatBasedLocale);
            this.setAttribute(
                "data-date", (dateValueFormat === 'Invalid date' ? this.dateFormatBasedLocale : dateValueFormat)
            )
          }).trigger("change")
        }
      }
    }).catch(() => {
      console.log(`jQuery loading was failed.`);
    });

    let inputTagNumberComponents = this.template.querySelectorAll(".Number");
    allowOnlyWholeNumber(inputTagNumberComponents);

    let inputTagDecimalComponents = this.template.querySelectorAll(".Decimal");
    validateDecimalInput(inputTagDecimalComponents);

    let radioBtns = this.template.querySelectorAll('.radioBtn');
    if(this.selectedAttrVal && this.isAttrReqValChng === false){ 
      for(let radioBtnCount = 0; radioBtnCount < radioBtns.length; radioBtnCount++){
        if(radioBtns[radioBtnCount].value === this.selectedAttrVal){
          radioBtns[radioBtnCount].checked = true;
        }
      } 
    }
  }

  hideAndShowBifacialFields(self, rowIndex, cellIndex, newAttributeValue) {
    let isValidData = true;
    let parsedRowIndex = parseInt(rowIndex, 10);

    if (this.dataTableOutput.length > 1) {
      const constantInt = 1;
      let element = self.template.querySelector('table').rows[(parsedRowIndex+constantInt)].getElementsByClassName('bifacialClo');

      for(let j = 0; j < element.length; j++){
        if(newAttributeValue === true){
          element.item(j).classList.remove('input-disable');
          const evt = new Event("change");
          element.item(j).dispatchEvent(evt);
        }else if(newAttributeValue === false){
          element.item(j).classList.add("input-disable");
          element.item(j).value = '';
          const evt = new Event("change");
          element.item(j).dispatchEvent(evt);
        }
      }
    }
    return isValidData;
  }

  /**
   * This method is used to check the Unique values of a Attribute Already existed or not. 
   * self - This attribute will have the Curren position of the Cell.
   * @param {number} rowIndex - This attribute will have the Row Index Number.
   * @param {number} cellIndex - This attribute will have the Cell Index Number. 
   * @param {string} newAttributeValue - This will have the New Attribute Value.
   */
  uniqueNameValidation(self, rowIndex, cellIndex, newAttributeValue) {
    let isValidData = true;
    let attrValueToRowIndexMap = new Map();
    let attrValueArray = [];
    let parsedRowIndex = parseInt(rowIndex, 10);

    if (this.dataTableOutput.length > 1) {
      for (let i = 0; i < this.dataTableOutput.length; i++) {
        const constantInt = 1;
        let datatableRowIndex = i + constantInt;

        let element = self.template.querySelector('table').rows[datatableRowIndex].getElementsByClassName('uniqueValidationClass');
        let cellValue = element.item(cellIndex).value.toLowerCase();

        if (!isEmptyOrSpaces(cellValue)) {
          attrValueArray.push(cellValue.trim());
          attrValueToRowIndexMap.set(cellValue.trim(), datatableRowIndex);
        } else {
          self.template.querySelector('table').rows[datatableRowIndex].getElementsByClassName('uniqueValidationClass').item(cellIndex).classList.remove('dupeValueHighlighter');
        }
      }
      let dupeValueArray = findDuplicateInArray(attrValueArray);

      if (attrValueArray.length > 0) {
        attrValueArray.forEach((attrValue) => {
          if (dupeValueArray.includes(attrValue)) {
            isValidData = false;
            if (newAttributeValue.trim() === attrValue) {
              self.template.querySelector('table').rows[parsedRowIndex + 1].getElementsByClassName('uniqueValidationClass').item(cellIndex).classList.add('dupeValueHighlighter');
            }
          } else {
            if (attrValueToRowIndexMap.has(attrValue)) {
              let rowIndex = attrValueToRowIndexMap.get(attrValue);
              self.template.querySelector('table').rows[rowIndex].getElementsByClassName('uniqueValidationClass').item(cellIndex).classList.remove('dupeValueHighlighter');
            }
          }
        })
      }
    }
    return isValidData;
  }
  /*
   * Method to Uncheck all other radio button other than selected radio button, and pass the checked value to another method.
   * @param {object} event - Name of the event to listen when radio button is clicked.
   */
  handleChange(event){
    this.value = event.target.value;
    if(this.value){
      this.isAttrReqValChng = true;
      //To check the selected value in "Attribute Requirement" Radio button
      var radioBtns = this.template.querySelectorAll('.radioBtn');
      for(var radioBtnCount = 0; radioBtnCount < radioBtns.length; radioBtnCount++){
        if(radioBtns[radioBtnCount].value != this.value){
            radioBtns[radioBtnCount].checked = false;
        }
        if(radioBtns[radioBtnCount].value == this.value){
          this.attrHLVal = radioBtns[radioBtnCount].value;
        }
      } 
      this.isSpinner = true;
      new Promise((resolve,reject)=> {
          setTimeout(() => {
            let result = this.attrRequirementHighlight(this.value);
            resolve(result);
          }, 1000);
      }).then(
        result=>this.isSpinner = false,
        error=>showToast(this,error.body.message,'Error','error')
      );
    }
  }

  /*
   * Method to hightlight Attributes based on Attribute Requirements. Using classname appended in table cell, highlight for vertical and horizontal prompts.
   * @param {string} value - Checked radio button value.
   */
  attrRequirementHighlight(value){
    let pageRefCustom = 'Asset Builder';
    fireEvent(pageRefCustom, 'attrHLValueSelected', value);
    this.attrHLfunction(this.dataTableOutput);
    return 'true';
  }
}