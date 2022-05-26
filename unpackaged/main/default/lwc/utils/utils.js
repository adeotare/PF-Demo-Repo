/* Util Component for share JS Code*/
import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LOCALE from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import updateG1PlantAssetPromptDetail from "@salesforce/apex/Utils2.updateG1PlantAssetPromptDetail";
import createPE from "@salesforce/apex/TriggerPEForReports.createPE";
import parentSiteMetadataErrMsg from '@salesforce/label/c.ParentSiteMetadataErrMsg';
import callNeuronAPI from '@salesforce/apex/SendNeuronTemplateDetail.callNeuronAPI';
import getSiteMetadata from '@salesforce/apex/TemplateGenerationController.getSiteMetadata';
import smCountGreaterThanRecordCountInCSV from '@salesforce/label/c.SMCountGreaterThanRecordCountInCSV';
import smCountLesserThanRecordCountInCSV from '@salesforce/label/c.SMCountLesserThanRecordCountInCSV';
import APIIDNotPresentInAPIType from '@salesforce/label/c.APIIDNotPresentInAPIType';
import siteMetadataNotAVailable from '@salesforce/label/c.ImplementationWizFormDetailNoSiteMetaData';
import { fireEvent, isBifacialCheckboxTrue, isBifacialCheckboxFalse, isBifacialCheckboxTrueOrFalse } from 'c/pubsub';

export function getcustomDataTable (inputData, additionalParams) {
  let data = [];
  let outputData = {};
  let tableHeaders = [];
  let header = [];
  let siteMetadataMap = new Map();
  let picklistFieldAndValueMap = new Map();

  var picklistFieldAndPicklistValues = inputData.Picklist; // picklistFieldAndPicklistValues - This will have the Picklist Master and Picklist Values.
  var siteMetadataRecords = inputData.SiteMetadataRecords; // siteMetadataRecords - This will have the Queried Site Metadata Records.
  var promptSpecificAttributes = inputData.PromptSpecificAttributes; // promptSpecificAttributes - This will have the Prompt Specific Attribute Records.
  var coreAttributes = inputData.CoreAttributes; // coreAttributes - This will have the Core Attributes.
  
  for (var picklistMasterId in picklistFieldAndPicklistValues) {
    picklistFieldAndValueMap.set(picklistMasterId, picklistFieldAndPicklistValues[picklistMasterId]);
  }

  let rowCount = 0;   

  for (var siteMetadataRecordKey in siteMetadataRecords) {
    isBifacialCheckboxFalse(false);
    let cellCount = 0;
    let siteMetadataRecord = siteMetadataRecords[siteMetadataRecordKey];
    siteMetadataMap.set(siteMetadataRecord.Id, siteMetadataRecord);

    let promptSpecificAttrMetadataObjArraywithHeaders = formDatatableColumnWithAttributes(promptSpecificAttributes, siteMetadataRecord.Prompt_Specific_Info__c, true, siteMetadataRecord, cellCount, picklistFieldAndValueMap, additionalParams);
    let promptSpecificAttrMetadataObjArray = promptSpecificAttrMetadataObjArraywithHeaders.attrMetadataObjArray;
    
    cellCount = promptSpecificAttrMetadataObjArraywithHeaders.cellCountIndex;
    
    let coreAttrMetadataObjArraywithHeaders = formDatatableColumnWithAttributes(coreAttributes, siteMetadataRecord.Attribute_Info__c, false, siteMetadataRecord, cellCount, picklistFieldAndValueMap,additionalParams);
    let coreAttrMetadataObjArray = coreAttrMetadataObjArraywithHeaders.attrMetadataObjArray;
    
    let attrMetadataConcatArray = promptSpecificAttrMetadataObjArray.concat(coreAttrMetadataObjArray);
    
    let concatTableHeaders = (promptSpecificAttrMetadataObjArraywithHeaders.tableHeaders).concat(coreAttrMetadataObjArraywithHeaders.tableHeaders);
    let concatHeaders = (promptSpecificAttrMetadataObjArraywithHeaders.header).concat(coreAttrMetadataObjArraywithHeaders.header);
    tableHeaders.push(concatTableHeaders);
    header.push(concatHeaders);

    data.push({
      siteMetadataRecordId: siteMetadataRecord.Id,
      parentSiteMetaDataAssetName: siteMetadataRecord.Parent_Site_Metadata__r.Asset_Name__c,
      attrMetadata: attrMetadataConcatArray,
      rowIndex: rowCount
    });
    rowCount++;
  }
  outputData = {
    data: data,
    tableHeaders: tableHeaders,
    header: header,
    picklistFieldAndValueMap: picklistFieldAndValueMap,
    rowCount: rowCount,
    siteMetadataMap: siteMetadataMap
  };
  return outputData;
}

/**
 * 
 * @param {object} attributes  - This attribute will have the Core Attribute As well as Prompt Specific Attributes.
 * @param {object} attrKeyAndValueJSON - This attribbute will have Prompt Specific Info or Attribute Info from Site Metadata Records.
 * @param {boolean} isPromptSpecificAttr - This attribute will show whether the attribute is Prompt Specific or Core Attribute.
 * @param {object} siteMetadataRecord - This attribute will have the Site Metadata Record.
 * @param {string} selectedAttrVal - This attribute will have the Drive or Drive Plus string Name.
 * @param {integer} cellCount - This aatribute will have the Cell Count of a DataTable.
 * @param {map} picklistFieldAndValueMap - This attribute will have the PicklistId and the Picklist Field Values.
 */
function formDatatableColumnWithAttributes(attributes, attrKeyAndValueJSON, isPromptSpecificAttr, siteMetadataRecord, cellCount, picklistFieldAndValueMap, additionalParams) {
  if (attributes) {
    let attrMetadataObjArray = [];
    let colNo = cellCount;
    let attrVal = '';
    let picklistVals = [];
    let attrKeyAndValueMap = new Map();
    let parentAttrName = '';
    let parentId = '';
    let tableHeaders = [];
    let header = [];
    let attrMetadataObjArraywithHeaders = {};
    let cellCountIndex = 0;

    if (attrKeyAndValueJSON) {
      JSON.parse(attrKeyAndValueJSON, (attrJSONKey, attrJSONValue) => {
        attrKeyAndValueMap.set(attrJSONKey, attrJSONValue);
      });
    }

    for (var attrKey in attributes) {
      let attrInfo = attributes[attrKey];
      let attrMetadataObj = {};

      if (attrKeyAndValueMap.has(attrInfo.Attribute_Master__r.Name)) {
        attrMetadataObj = formAttributeMetadataObj(attrInfo, attrKeyAndValueMap, isPromptSpecificAttr, siteMetadataRecord, 
          cellCount, picklistFieldAndValueMap, additionalParams);
      } else {
        attrMetadataObj = formAttrObj(attrInfo, attrVal, parentAttrName, parentId, isPromptSpecificAttr, picklistVals, true, cellCount, additionalParams);
      }

      let headerForDataTable = formTableHeaders(attrInfo, isPromptSpecificAttr, tableHeaders, header);
      if(headerForDataTable.tempHeader !== undefined){
        header.push(headerForDataTable.tempHeader);
      }
      
      if(headerForDataTable.tableHeaders !== undefined){
        tableHeaders.push(headerForDataTable.tableHeaders);
      }
      
      attrMetadataObjArray.push({
        attrMetadataObj: attrMetadataObj,
        cellIndex: colNo
      });
      colNo++;
      cellCountIndex = cellCount = colNo;
    }
    attrMetadataObjArraywithHeaders = {
      attrMetadataObjArray: attrMetadataObjArray,
      tableHeaders: tableHeaders,
      header: header,
      cellCountIndex: cellCountIndex
    };
    return attrMetadataObjArraywithHeaders;
  }
}

/**
 * // This method will return an object with Attribute Name, Attribute Value, Site Metadata Record, Cell Count and identification of Prompt Specific.
 * @param {object} attrInfo - This attribute will have the Attribute Record.
 * @param {map} attrKeyAndValueMap - This attribute will have the Attribute Name and the Attribute Value.
 * @param {boolean} isPromptSpecificAttr - To identify Attribute is prompt specific.
 * @param {object} siteMetadataRecord - This attribute will have the Site Metadata Record. 
 * @param {number} cellCount - This attribute will have the Cell Count. 
 * @param {string} selectedAttrVal - This attribute will have the Drive or Drive Plus string Name. 
 * @param {map} picklistFieldAndValueMap - This attribute will have the PicklistId and the Picklist Field Values. 
 */
function formAttributeMetadataObj(attrInfo, attrKeyAndValueMap, isPromptSpecificAttr, siteMetadataRecord, cellCount, 
  picklistFieldAndValueMap, additionalParams) {
  let picklistVals = [];
  let attrVal = attrKeyAndValueMap.get(attrInfo.Attribute_Master__r.Name);
  let parentAttrName;

  let parentId;
  if (attrInfo.Attribute_Master__r.Data_Type__c === 'Picklist') {
    if (attrInfo.Picklist_Dependency1__c) {
      let picklistDependentValue = attrKeyAndValueMap.get(attrInfo.Picklist_Dependency1__r.Name);
    
      var picklistformat = picklistDependentValue + attrInfo.Attribute_Master__r.Name;
      picklistVals = fetchPicklistValues(picklistFieldAndValueMap, picklistformat, attrVal);
    } else if (attrInfo.Attribute_Master__r.Picklist_Master__c) {
      picklistVals = fetchPicklistValues(picklistFieldAndValueMap, attrInfo.Attribute_Master__r.Picklist_Master__c, attrVal);
    }
  }

  if (attrInfo.Show_Alternate_Parent_in_Prompt__c) {
    let altAssetName = siteMetadataRecord.Parent_Site_Metadata__r.Alternate_Parent_Site_Metadata__r.Asset_Name__c;
    attrVal = (altAssetName) ? altAssetName : '';
  } else if (attrInfo.Is_Parent_Asset__c) {
    attrVal = (siteMetadataRecord.Parent_Site_Metadata__r.Asset_Name__c) ? siteMetadataRecord.Parent_Site_Metadata__r.Asset_Name__c : '';
    parentAttrName = siteMetadataRecord.Parent_Site_Metadata__r.Asset_Name__c;
    parentId = siteMetadataRecord.Parent_Site_Metadata__r.Id;
    }

  let attrObj = formAttrObj(attrInfo, attrVal, parentAttrName, parentId, isPromptSpecificAttr, picklistVals, false, 
    cellCount, additionalParams);
  return attrObj;
}

/**
 * This method is used to retrun an object Picklist MasterId, Picklist Values and the selected Picklist Values. 
 * @param {map} picklistFieldAndValueDetails - This attribute will have the Picklist Master Id and the respective Picklist Values. 
 * @param {string} picklistFieldId - This attribute will have the Picklist Master Id. 
 * @param {string} selectedPicklistValue - This attribute will have the selected Picklist Values. 
 */
function fetchPicklistValues(picklistFieldAndValueDetails, picklistFieldId, selectedPicklistValue) {
  let picklistValueArrayObj = [];
  
  if (picklistFieldAndValueDetails.has(picklistFieldId)) {
    let picklistMapValue = picklistFieldAndValueDetails.get(picklistFieldId);

    for (let picklistValKey in picklistMapValue) {
      let picklistLabel = picklistMapValue[picklistValKey];

      picklistValueArrayObj.push({
        picklistVal: picklistValKey,
        picklistLabel: picklistLabel,
        picklistValSelected: (selectedPicklistValue === picklistValKey)
      })
      
    }
    return picklistValueArrayObj.sort(sorting);
  }
  return picklistValueArrayObj;
}

/**
 * To form dynamic table headers with Customer Facing Notes and Attribute Master Units
 * @param {object} attrInfo - Attribute information to map table headers.
 * @param {boolean} isPromptSpecificAttr - To identify Attribute is prompt specific.
 * @param {array} tableHeaders - This array will have the Customer Facing Notes, Label and the Class Name
 * @param {array} header - This attribute will have the header name in the array.
 */
function formTableHeaders(attrInfo, isPromptSpecificAttr, tableHeaders, header) {
  let headerForDataTableComp = [];
  let tempHeader;
  let attrName = attrInfo.Attribute_Master__r.Alias__c;
  let customerFacingNotesAttrMaster = attrInfo.Attribute_Master__r.Customer_Facing_Notes__c;
  let customerFacingNotesAttr = attrInfo.Customer_Facing_Notes__c;
  let uom = attrInfo.Attribute_Master__r.Units__c;
  let customerFacingNotes;
  let attributeHeaderAndUOM = attrName;

  if (typeof uom !== 'undefined') {
    if (!isEmptyOrSpaces(uom) && uom !== 'None') {
      attributeHeaderAndUOM = attrName + ' (' + uom + ')';
    }
  }

  if (!header.includes(attrName)) {
    tempHeader = attrName;
    header.push(attrName);
    if (!customerFacingNotesAttr || customerFacingNotesAttr.length === 0) {
      customerFacingNotes = customerFacingNotesAttrMaster;
    } else {
      customerFacingNotes = customerFacingNotesAttr;
    }

    tableHeaders.push({
      customerFacingNotes: customerFacingNotes,
      label: attributeHeaderAndUOM,
      className : ((isPromptSpecificAttr) ? ' promptSpecificAttrBgColor ' : ' coreAttrBgColor ')
    });
  }
  
  headerForDataTableComp.push({
    tempHeader: tempHeader,
    tableHeaders: tableHeaders
  });
  return headerForDataTableComp;
}

/**
 * 
 * @param {object} attrInfo - This attribute will have the Attribute Record Values.
 * @param {string} attrVal - This attribute will have the Attribute Value.
 * @param {string} parentAttrName - This attribute will have the Patrent Attribute Name. 
 * @param {string} parentId - This attribute will have the Parent Id.
 * @param {boolean} isPromptSpecificAttr - To identify Attribute is prompt specific.  
 * @param {array} picklistVals - This attribute will have the Picklist Values. 
 * @param {boolean} cellDisabled - This attribute will have the boolean to make the cell read only.
 * @param {number} cellCount - This attribute will have the Cell Count. 
 * @param {string} selectedAttrVal - This attribute will have the Drive or Drive Plus string Name. 
 */
function formAttrObj(attrInfo, attrVal, parentAttrName, parentId, isPromptSpecificAttr, 
  picklistVals, cellDisabled, cellCount, additionalParams) {
  let customerFacingNotesAttrMaster = (attrInfo.Attribute_Master__r.Customer_Facing_Notes__c) ? attrInfo.Attribute_Master__r.Customer_Facing_Notes__c : '';
  let customerFacingNotesAttr = (attrInfo.Customer_Facing_Notes__c) ? attrInfo.Customer_Facing_Notes__c : '';
  let customerFacingNotes;
  if (!customerFacingNotesAttr || customerFacingNotesAttr.length === 0) {
    customerFacingNotes = customerFacingNotesAttrMaster;
  } else {
    customerFacingNotes = customerFacingNotesAttr;
  }

  let attributeHeaderAndUOM = attrInfo.Attribute_Master__r.Alias__c;

  let uom = attrInfo.Attribute_Master__r.Units__c;
  if (typeof uom !== 'undefined') {
    if (!isEmptyOrSpaces(uom) && uom !== 'None') {
      attributeHeaderAndUOM = attrInfo.Attribute_Master__r.Alias__c + ' (' + uom + ')';
    }
  }
  var attrClassName;
  var requiredValue;
  if (typeof attrInfo.Required__c !== 'undefined') {
    requiredValue = attrInfo.Required__c;
  }

  let selectedAttrVal = additionalParams.selectedAttrVal;	
  let isReadOnly = additionalParams.isReadOnly;

  if(requiredValue){
    if(requiredValue.includes(selectedAttrVal)){
      if(selectedAttrVal === 'Drive'){
        attrClassName = 'driveHighlighter';
      }
      else if(selectedAttrVal === 'DrivePlus'){
        attrClassName = 'drivePlusHighlighter';
      }
    }
  }
  //To Make all fields disabled based on isReadOnly 	
  if(isReadOnly){	
    cellDisabled = isReadOnly;	
  }

  let attributeValue = (attrInfo.Attribute_Master__r.Data_Type__c === 'Checkbox') ? (attrVal === 'FALSE') ? false : (attrVal === 'TRUE') ? true :attrVal :attrVal;
  let bifacialClassName = 'input-disable bifacialClo';

  if(attrInfo.Attribute_Master__r.Name === 'SUBARRAY_BIFACIAL'){
    if(attributeValue){
      isBifacialCheckboxTrue(true);
    }
  }

  if(attrInfo.Is_Related_Subarray_Bifacial__c){
    if(attributeValue !== '' || isBifacialCheckboxTrueOrFalse()){
      bifacialClassName = ' bifacialClo';
    }
  }

  let attrObj = {
    attributeHeader: attrInfo.Attribute_Master__r.Alias__c,
    attributeHeaderAndUOM: attributeHeaderAndUOM,
    attributeHeaderName: attrInfo.Attribute_Master__r.Name,
    attributeDataType: (attrInfo.Attribute_Master__r.Data_Type__c === 'Decimal') ? 'Number' : attrInfo.Attribute_Master__r.Data_Type__c,
    batId: (attrInfo.Base_Asset_Name__c !== '' && typeof attrInfo.Base_Asset_Name__c != 'undefined') ? attrInfo.Base_Asset_Name__c: 'NoBat',
    attributeDataTypeForCSVExport : attrInfo.Attribute_Master__r.Data_Type__c,
    isPicklist: (attrInfo.Attribute_Master__r.Data_Type__c === 'Picklist'),
    attributeValue: attributeValue,
    parentAttrName: (parentAttrName !== undefined) ? parentAttrName: '',
    parentId: (parentId !== undefined) ? parentId: '',
    keyFieldToGenerateRowCheck: attrInfo.Key_Field_To_Generate_Rows__c,
    picklistValues: picklistVals,
    isPromptSpecificAttr: isPromptSpecificAttr,
    isUnique: attrInfo.Is_Unique__c,
    isAssetName: attrInfo.Is_Asset_Name__c,
    isAlternateParent: attrInfo.Is_Alternate_Parent__c,
    isParentAsset: attrInfo.Is_Parent_Asset__c,
    isDisabled: attrInfo.Is_Read_Only__c,
    className: attrInfo.Required__c+' '+attrInfo.Attribute_Master__r.Data_Type__c + ' uniqueValidationClass ' + ((cellCount > 1) ? ' inputFieldClass ' : '') +' '+ attrClassName +' '+ ((attrInfo.Is_Related_Subarray_Bifacial__c && attrInfo.Attribute_Master__r.Name !== 'SUBARRAY_BIFACIAL') ? bifacialClassName : ''),
    colClassName:  attrInfo.Required__c+' '+((cellCount > 1 && attrInfo.Attribute_Master__r.UI_Column_Size__c) ? attrInfo.Attribute_Master__r.UI_Column_Size__c : 'table-col-medium'),
    headerClassNameVertical : ((isPromptSpecificAttr) ? ' promptSpecificAttrBgColor ' : ' coreAttrBgColor '),
    cellIsDisabled: attrInfo.Is_Read_Only__c ? attrInfo.Is_Read_Only__c : cellDisabled,
    customerFacingNotes: customerFacingNotes,
    attrInfo: attrInfo,
    showClearDate : ((attrInfo.Attribute_Master__r.Data_Type__c === 'Date') ? (attrInfo.Is_Read_Only__c ? false : (cellDisabled ? false : true)) : false),
  }
 
  return attrObj;
}

/**
 * This method is used to map the Site Metadata Record Id to the CSV String for P1 and W1 Prompt.
 * @param {Array} siteMetadataRecordIdLst - This attribute will have the SiteMetadata Records
 * @param {String} csvData - This attribute will have the CSV String
 */
export function mapSiteMetadataIdWithCSVDataForP1AndW1(
  siteMetadataRecordIdLst,
  csvData){
    let csvStringAndCountObject = {};
    var rowEnd = '\n';
    var csvString = '';
    let csvLines = csvData.split('\n');

    for(var rowCount = 0; rowCount < 7; rowCount++){
      csvString += csvLines[rowCount];
      csvString += rowEnd;
    }
    let referenceArray = csvLines[5].split(',');

    let csvDataColumns = [];
    let sitemetaRecordCountInCSV = 0;
    for (var recordCount = 7; recordCount < csvLines.length; recordCount++) {
      csvDataColumns = csvLines[recordCount].split(',');
      if(csvDataColumns.length === referenceArray.length){

        sitemetaRecordCountInCSV = sitemetaRecordCountInCSV + 1;
        var recordData = [];
        var startRecordIndex = 7
        for(var columnData = 0; columnData < referenceArray.length; columnData++){
          if(columnData === 0){
            if((parseInt(recordCount) - parseInt(startRecordIndex)) < siteMetadataRecordIdLst.length){
              recordData.push(siteMetadataRecordIdLst[parseInt(recordCount)-parseInt(startRecordIndex)].Id);
            }else{
              recordData.push('');
            }
          }else{
            recordData.push(csvDataColumns[columnData]);
          }
        }
        csvString += recordData.join(',');
        csvString += rowEnd;
      }
    }
    csvStringAndCountObject={
      csvString: csvString,
      sitemetaRecordCountInCSV: sitemetaRecordCountInCSV,
    };
  return csvStringAndCountObject;
}

/**
 * This method is used to map the Site Metadata Record Id to the CSV String with the Prompt will not have the 
 
 * @param {Array} siteMetadataRecordIdLst - This attribute will have the SiteMetadata Records
 * @param {String} csvData - This attribute will have the CSV String
 */
export function mapSiteMetadataIdWithCSVDataWithoutParent(
  siteMetadataRecordIdLst,
  csvData,
  parentPromptFromP1){

    let csvStringAndCountObject = {};
    var rowEnd = '\n';
    var csvString = '';
    let csvLines = csvData.split('\n');

    for(var rowCount = 0; rowCount < 7; rowCount++){
      if(parentPromptFromP1 === true && rowCount === 5){
        let referenceArrayCheckTemp = csvLines[rowCount].split(',');
        //If the Flat Hierarchy is Yes then we are changing the Parent Name in Reference Row to Value.
        referenceArrayCheckTemp.splice(referenceArrayCheckTemp.indexOf('Parent Asset'), 1, 'VALUE');
        csvString += referenceArrayCheckTemp.join(',');
        csvString += rowEnd;
      }else{
        csvString += csvLines[rowCount];
        csvString += rowEnd;
      }
    }
    
    let referenceArray = csvLines[5].split(',');
    
    let sitemetaRecordCountInCSV = 0;
    let csvDataColumns = [];
    for (var recordCount = 7; recordCount < csvLines.length; recordCount++) {
      csvDataColumns = csvLines[recordCount].split(',');
      
      if(csvDataColumns.length === referenceArray.length){
        
        sitemetaRecordCountInCSV = sitemetaRecordCountInCSV + 1;
        var recordData = [];
        var startRecordIndex = 7
        for(var columnData = 0; columnData < referenceArray.length; columnData++){
          if(columnData === 0){
            if((parseInt(recordCount) - parseInt(startRecordIndex)) < siteMetadataRecordIdLst.length){
              recordData.push(siteMetadataRecordIdLst[parseInt(recordCount)-parseInt(startRecordIndex)].Id);
            }else{
              recordData.push('');
            }
          }else{
            recordData.push(csvDataColumns[columnData]);
          }
        }
        csvString += recordData.join(',');
        csvString += rowEnd;
      }
    }
    csvStringAndCountObject={
      csvString: csvString,
      sitemetaRecordCountInCSV: sitemetaRecordCountInCSV,
    };
    return csvStringAndCountObject;
}

/**
 * This method is used to map the Site Metadata Record Id to the CSV String with the Prompt will have the Parent Asset and the unique Asset Name
 * @param {Array} siteMetadataRecordIdLst - This attribute will have the SiteMetadata Records
 * @param {String} csvData - This attribute will have the CSV String
 */
export function mapSiteMetadataIdWithCSVDataWithUniqueAssetName(
  siteMetadataRecordIdLst,
  csvData,
  ){

    let csvStringAndCountObject = {};
    let siteMetadataToRecordDetails = new Map();
    
    var rowEnd = '\n';
    var csvString = '';
    let csvLines = csvData.split('\n');

    for(var rowCount = 0; rowCount < 7; rowCount++){
      csvString += csvLines[rowCount];
      csvString += rowEnd;
    }

    let referenceArray = csvLines[5].split(',');
    let parentAssetIndex = referenceArray.indexOf("Parent Asset");
    
    let csvDataColumns = [];
    let sitemetaRecordCountInCSV = 0;
    for (var recordCount = 7; recordCount < csvLines.length; recordCount++) {
      csvDataColumns = csvLines[recordCount].split(',');
      
      if(csvDataColumns[parentAssetIndex] !== '' && csvDataColumns[parentAssetIndex] !== undefined
        && csvDataColumns.length === referenceArray.length){
        
        sitemetaRecordCountInCSV = sitemetaRecordCountInCSV + 1;
        var recordData = [];
        var recordId = '';
        for(var columnData = 0; columnData < referenceArray.length; columnData++){
          if(columnData === 0){
            
            for(var siteMetadataRecordKey in siteMetadataRecordIdLst){
              let siteMetadataRecord = siteMetadataRecordIdLst[siteMetadataRecordKey];
              
              if(csvDataColumns[parentAssetIndex].toLowerCase() === siteMetadataRecord.Parent_Site_Metadata__r.Asset_Name__c.toLowerCase()){
                if(!siteMetadataToRecordDetails.has(siteMetadataRecord.Id)){
                  siteMetadataToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
                  recordId = siteMetadataRecord.Id;
                  break;
                }
              }
            }
            recordData.push(recordId);
          }else{
            recordData.push(csvDataColumns[columnData]);
          }
        }
        csvString += recordData.join(',');
        csvString += rowEnd;
      }
    }
    csvStringAndCountObject={
      csvString: csvString,
      sitemetaRecordCountInCSV: sitemetaRecordCountInCSV,
    };
    return csvStringAndCountObject;
}

/**
 * This method is used to map the Site Metadata Record Id to the CSV String with the Prompt will have the Parent Asset and will not have unique Asset Name
 * @param {Array} siteMetadataRecordIdLst - This attribute will have the SiteMetadata Records
 * @param {String} csvData - This attribute will have the CSV String
 */
export function mapSiteMetadataIdWithCSVDataWithoutUniqueAssetName(
  siteMetadataRecordIdLst,
  csvData){

    let csvStringAndCountObject = {};
    let siteMetadataToRecordDetails = new Map();
    
    var rowEnd = '\n';
    var csvString = '';
    let csvLines = csvData.split('\n');

    for(var rowCount = 0; rowCount < 7; rowCount++){
      csvString += csvLines[rowCount];
      csvString += rowEnd;
    }

    let referenceArray = csvLines[5].split(',');
    let parentAssetIndex = referenceArray.indexOf("Parent Asset");
    
    let csvDataColumns = [];
    let sitemetaRecordCountInCSV = 0;
    for (var recordCount = 7; recordCount < csvLines.length; recordCount++) {
      csvDataColumns = csvLines[recordCount].split(',');
      
      if(csvDataColumns[parentAssetIndex] !== '' && csvDataColumns[parentAssetIndex] !== undefined
        && csvDataColumns.length === referenceArray.length){
        
        sitemetaRecordCountInCSV = sitemetaRecordCountInCSV + 1;
        var recordData = [];
        var recordId = '';
        for(var columnData = 0; columnData < referenceArray.length; columnData++){
          if(columnData === 0){
            
            for(var siteMetadataRecordKey in siteMetadataRecordIdLst){
              let siteMetadataRecord = siteMetadataRecordIdLst[siteMetadataRecordKey];
              
              if(csvDataColumns[parentAssetIndex].toLowerCase() === siteMetadataRecord.Parent_Site_Metadata__r.Asset_Name__c.toLowerCase()){
                if(!siteMetadataToRecordDetails.has(siteMetadataRecord.Id)){
                  siteMetadataToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
                  recordId = siteMetadataRecord.Id;
                  break;
                }
              }
            }
            recordData.push(recordId);
          }else{
            recordData.push(csvDataColumns[columnData]);
          }
        }
        csvString += recordData.join(',');
        csvString += rowEnd;
      }
    }
    csvStringAndCountObject={
      csvString: csvString,
      sitemetaRecordCountInCSV: sitemetaRecordCountInCSV,
    };
    return csvStringAndCountObject;
}

export function mapSiteMetadataIdWithCSVDataWithUniqueAssetNameForDetailPrompt(
  csvData,
  detailPromptIdMapForN3uronTemp){

    let csvStringAndCountObject = {};
    let siteMetadataToRecordDetails = new Map();
    
    var rowEnd = '\n';
    var csvString = '';
    let csvLines = csvData.split('\n');

    for(var rowCount = 0; rowCount < 7; rowCount++){
      csvString += csvLines[rowCount];
      csvString += rowEnd;
    }
    
    let referenceArray = csvLines[5].split(',');
    let parentAssetIndex = referenceArray.indexOf("Parent Asset");
    let readonlyIndex = referenceArray.indexOf("readOnly");
    let assetNameIndex = referenceArray.indexOf("Asset Name");
    
    let csvDataColumns = [];
    let sitemetaRecordCountInCSV = 0;
    for (var recordCount = 7; recordCount < csvLines.length; recordCount++) {
      csvDataColumns = csvLines[recordCount].split(',');
      
      if(csvDataColumns[parentAssetIndex] !== '' && csvDataColumns[parentAssetIndex] !== undefined &&
        csvDataColumns[readonlyIndex] !== '' && csvDataColumns[readonlyIndex] !== undefined
        && csvDataColumns.length === referenceArray.length){
        
        var recordData = [];
        var recordId = '';
        for(var columnData = 0; columnData < referenceArray.length; columnData++){
          
          if(columnData === 0){
            let concatDeviceNameAndDeviceType = csvDataColumns[parentAssetIndex].toLowerCase()+ ' - '+csvDataColumns[readonlyIndex].toLowerCase();
            if(detailPromptIdMapForN3uronTemp.has(concatDeviceNameAndDeviceType)){
              let siteMetadataRecordIdArray = detailPromptIdMapForN3uronTemp.get(concatDeviceNameAndDeviceType);
              for (var i = 0; i < siteMetadataRecordIdArray.length; i++) {
                if(!siteMetadataToRecordDetails.has(siteMetadataRecordIdArray[i])){
                  recordId = siteMetadataRecordIdArray[i];
                  siteMetadataToRecordDetails.set(siteMetadataRecordIdArray[i], csvDataColumns[assetNameIndex])
                }
              }
            
            }
            if(recordId !== ''){
              sitemetaRecordCountInCSV = sitemetaRecordCountInCSV + 1;
            }
            recordData.push(recordId);
          }else{
            recordData.push(csvDataColumns[columnData]);
          }
        }
        csvString += recordData.join(',');
        csvString += rowEnd;
      }
    }
    csvStringAndCountObject={
      csvString: csvString,
      sitemetaRecordCountInCSV: sitemetaRecordCountInCSV,
    };
    return csvStringAndCountObject;
}

/**
 * This method is used to replace the Old Attribute value wiith the New Attribute Value in the Data Table Component.
 * @param {map} siteMetadataIdToRecordDetails - This attribute will have the Site Metadata Record Id with respective Site Metadata Records.
 * @param {string} siteMetadataRecordId - This attribute will have the Site Metadata record Id.
 * @param {boolean} isPromptSpecificAttr - This attribute will have the boolean to show whether it is a Prompt Specific Attribute or Core Attribute.
 * @param {string} attributeName - This attribute will have the Attribute Name from the Data Table Component.
 * @param {string} newAttributeValue - This attribute will have the New Attribute value from the Data Table Component.
 */
export function replaceOldAttrbuiteValueWithNewValue(
  siteMetadataIdToRecordDetails,
  siteMetadataRecordId,
  isPromptSpecificAttr,
  attributeName,
  newAttributeValue){
  if(siteMetadataIdToRecordDetails.has(siteMetadataRecordId)){
    let siteMetadataRecordDetail = siteMetadataIdToRecordDetails.get(siteMetadataRecordId);
    if(isPromptSpecificAttr){
      let promptSpecificAttrInfo = siteMetadataRecordDetail.Prompt_Specific_Info__c;
      siteMetadataIdToRecordDetails.get(siteMetadataRecordId).Prompt_Specific_Info__c = 
        updateAttrValue(promptSpecificAttrInfo,attributeName,newAttributeValue);
    }else{
      let coreAttrInfo = siteMetadataRecordDetail.Attribute_Info__c;
      siteMetadataIdToRecordDetails.get(siteMetadataRecordId).Attribute_Info__c = 
        updateAttrValue(coreAttrInfo,attributeName,newAttributeValue);
    }
    return siteMetadataIdToRecordDetails;
  }
}

export function replaceOldAttrbuiteValueWithNewValueForUpdate(
  siteMetadataIdToRecordDetails,
  siteMetadataRecordId,
  isPromptSpecificAttr,
  attributeName,
  newAttributeValue,
  siteMetadataIdToRecordDetailsForUpdate){
  if(siteMetadataIdToRecordDetails.has(siteMetadataRecordId)){
    let siteMetadataRecordDetail = siteMetadataIdToRecordDetails.get(siteMetadataRecordId);
    if(isPromptSpecificAttr){
      let promptSpecificAttrInfo = siteMetadataRecordDetail.Prompt_Specific_Info__c;
      siteMetadataIdToRecordDetails.get(siteMetadataRecordId).Prompt_Specific_Info__c = 
        updateAttrValue(promptSpecificAttrInfo,attributeName,newAttributeValue);
    }else{
      let coreAttrInfo = siteMetadataRecordDetail.Attribute_Info__c;
      siteMetadataIdToRecordDetails.get(siteMetadataRecordId).Attribute_Info__c = 
        updateAttrValue(coreAttrInfo,attributeName,newAttributeValue);
    }
    let updatedSiteMetadataRecordDetail = siteMetadataIdToRecordDetails.get(siteMetadataRecordId);
    siteMetadataIdToRecordDetailsForUpdate.set(siteMetadataRecordId, updatedSiteMetadataRecordDetail);
    return siteMetadataIdToRecordDetailsForUpdate;
  }
}


/**
 * This method is used to check whether there is a change in the Old Attribute and the New Attribute Value.
 * @param {map} saveSiteMetadataMap - This attribute will have the Concatenate Value of Record Id with Attribute Name and Boolean.
 * @param {string} newAttributeValue - This attribute will have the New Attribute value from the Data Table Component.
 * @param {string} oldAttributeValue - This attribute will have the Old Attribute value from the Data Table Component.
 * @param {string} siteMetadataRecordId - This attribute will have the Site Metadata record Id.
 * @param {string} attributeName - This attribute will have the Attribute Name from the Data Table Component.
 */
export function saveLogicMap(
  saveSiteMetadataMap, newAttributeValue, oldAttributeValue, siteMetadataRecordId, attributeName){
    let saveCheckBoolean = false;
    if(oldAttributeValue !== newAttributeValue){
      saveCheckBoolean = true;
    }
    let attributeInstanceValue = siteMetadataRecordId + attributeName;
    saveSiteMetadataMap.set(attributeInstanceValue, saveCheckBoolean);

    return saveSiteMetadataMap;
}

/**
 * This method will return the Concatenate Value of Record Id with Attribute Name and Boolean.
 * @param {map} siteMetdaDataAttributeMap - This attribute will have the Concatenate Value of Record Id with Attribute Name and Boolean.
 * @param {string} siteMetadataRecordId - This attribute will have the Site Metadata record Id. 
 * @param {string} newAttributeValue - This attribute will have the New Attribute value from the Data Table Component. 
 * @param {string} oldAttributeValue - This attribute will have the Old Attribute value from the Data Table Component.
 * @param {string} attributeName - This attribute will have the Attribute Name from the Data Table Component.
 * @param {string} attributeDataType - This attribute will have the Data Type of Attribute from the Data Table Component.
 * @param {boolean} keyFieldToGenerateRowCheckValue - This attribute will have the Boolean value of a attribute record Is Key To Generate Rows.
 */
export function deleteLogicMap(
  siteMetdaDataAttributeMap,
  siteMetadataRecordId, newAttributeValue, oldAttributeValue,
  attributeName, attributeDataType,
  keyFieldToGenerateRowCheckValue){
    let isDeleteBoolean = false;
    let newAttributeValueInt = 0;
    if(keyFieldToGenerateRowCheckValue){
      
      if(newAttributeValue !== '' && attributeDataType === 'Number'){
        newAttributeValueInt = newAttributeValue;
      }

      if(parseInt(oldAttributeValue) > parseInt(newAttributeValueInt)){
        isDeleteBoolean = true;
      }else if(attributeName ==='Flat Hierarchy' && attributeDataType === 'Picklist' && oldAttributeValue !== newAttributeValue && oldAttributeValue !==''){
        isDeleteBoolean = true;
      }else if(attributeName !=='Flat Hierarchy' && attributeDataType === 'Picklist' && oldAttributeValue === 'Yes' && newAttributeValue !== 'Yes'){
        isDeleteBoolean = true;
      }else if(attributeDataType === 'Picklist' && oldAttributeValue !== 'Yes' && newAttributeValue !== 'Yes' && oldAttributeValue !==''
                && oldAttributeValue !== 'No' && newAttributeValue !== 'No' && attributeName !=='Flat Hierarchy'){
        isDeleteBoolean = true;
      }else{
        isDeleteBoolean = false;
      }
    }
    let attributeInstanceValue = siteMetadataRecordId + attributeName;
    siteMetdaDataAttributeMap.set(attributeInstanceValue, isDeleteBoolean);
    
    return siteMetdaDataAttributeMap;
  }

  /**
   * This method will return the Concatenate Value of Record Id with Attribute Name and Boolean.
   * @param {map} siteMetdaDataAttributeMap - This attribute will have the Concatenate Value of Record Id with Attribute Name and Boolean.
   * @param {string} siteMetadataRecordId - This attribute will have the Site Metadata record Id. 
   * @param {string} newAttributeValue - This attribute will have the New Attribute value from the Data Table Component.
   * @param {string} oldAttributeValue - This attribute will have the Old Attribute value from the Data Table Component.
   * @param {string} attributeName - This attribute will have the Attribute Name from the Data Table Component.
   * @param {string} attributeDataType - This attribute will have the Data Type of Attribute from the Data Table Component.
   * @param {boolean} keyFieldToGenerateRowCheckValue - This attribute will have the Boolean value of a attribute record Is Key To Generate Rows.
   */
  export function findOldValToNewValChanges(
    siteMetdaDataAttributeMap,
    siteMetadataRecordId, newAttributeValue, oldAttributeValue,
    attributeName, attributeDataType,
    keyFieldToGenerateRowCheckValue){
    let isValChangedBoolean = false;
    if(keyFieldToGenerateRowCheckValue){
      if(oldAttributeValue !== newAttributeValue){
        isValChangedBoolean = true;
      }
    }
    
    let attributeInstanceValue = siteMetadataRecordId + attributeName;
    siteMetdaDataAttributeMap.set(attributeInstanceValue, isValChangedBoolean);
    
    return siteMetdaDataAttributeMap;
  }

  /**
   * This method is used to check whether there is a change in the prompt Specific Attribute with Is Key To Generate Rows Checked.
   * @param {map} siteMetdaDataAttributeMap - This attribute will have the Concatenate Value of Record Id with Attribute Name and Boolean.
   */
  export function IsBooleanCheck(siteMetdaDataAttributeMap){
    if(siteMetdaDataAttributeMap){
      var booleanValueSet = new Set();
      booleanValueSet = siteMetdaDataAttributeMap.values();
      for (let booleanValue of Array.from(booleanValueSet)) {
        if(booleanValue === true){
          return true;  
        }
      }
      return false;
    }else{
      return false;
    }
  }

  /**
   * This method is used to form JSON values with updated Attribute Name and Attribute Value.
   * @param {object} attrInfoJSON - This attribute will have the object of Attribute Name and Attribute Value.
   * @param {string} attributeName - This attribute will have the Attribute Name from the Data Table Component.
   * @param {string} newAttributeValue - This attribute will have the New Attribute value from the Data Table Component. 
   */
function updateAttrValue(attrInfoJSON,attributeName,newAttributeValue){
  var attrInfoJSONOutput = JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => attrJSONKey === attributeName ? newAttributeValue : attrJSONValue);
  return JSON.stringify(attrInfoJSONOutput);
}

/**
 * This method is used to update the existing values with new attribute value and make that as an object and return it to the respective prompt.
 * @param {map} siteMetadataIdToRecordDetails - This attribute will have the Site Metadata Record Id with respective Site Metadata Records.
 */
export function getModifiedMetadataRecordsArray(siteMetadataIdToRecordDetails){
  if(siteMetadataIdToRecordDetails){
    let modifiedMetadataRecords = [];
    siteMetadataIdToRecordDetails.forEach(function(siteMetadataRecordDetail, siteMetadataRecordId){
      modifiedMetadataRecords.push(siteMetadataRecordDetail);
    });
    return modifiedMetadataRecords;
  }
}

/**
 * This method is used to show the Toast Message in the respective prompts as well as to respective Lightning Web Component.
 * @param {string} cmp - This attribute will have the Component Details.
 * @param {string} message - This attribute will have the Toast Message.
 * @param {string} title -  This attribute will have the Error, success  or info String.
 * @param {string} variant - This attribute will have the Error, success  or info String.
 */
export function showToast(cmp, message, title, variant, mode) {
  if(mode !== undefined){
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: mode
    });
    cmp.dispatchEvent(event);
  }else{
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: 'dismissable'
    });
    cmp.dispatchEvent(event);
  }
}

/**
 * This methos is used to show or hide spinner in respecive Lightning Web Component.
 * @param {string} cmp - This attribute will have the Component Details. 
 * @param {string} spinnerEventName - This attribute will have the ShowSpinner or HideSpinner
 */
export function showAndHideSpinner(cmp, spinnerEventName, eventMessage){
  if(eventMessage != undefined){
    const detail = new CustomEvent('showspinnerwithmessage', {
      detail: {
        eventMessage: eventMessage
      }
    });
    cmp.dispatchEvent(detail);
  }else{
    cmp.dispatchEvent(new CustomEvent(spinnerEventName));
  }
}

/**
 * This method is used to allow only whole numbers in the respective cells. 
 */
export function allowOnlyWholeNumber(inputTagComponents){
  Array.prototype.map.call(inputTagComponents, (inputComp) => {
    inputComp.addEventListener('keypress', function (evt) {
      if (evt.which != 8 && evt.which != 0 && (evt.which < 48 || evt.which > 57)){
        evt.preventDefault();
        return;
      }
    });	      
  });
}

/**
 * This method is used to Validate the Decimal Input in the User Experiencing Cells. 
 */
export function validateDecimalInput(inputTagDecimalComponents){

  Array.prototype.map.call(inputTagDecimalComponents, (inputComp) => {
    inputComp.addEventListener('keypress', function (evt) {

      let fieldValue = evt.target.value;
      let fieldValueLength = fieldValue.length;

      if(fieldValueLength){
        while (fieldValueLength--) {
          let keyCod =  fieldValue.charCodeAt(fieldValueLength);
          if(evt.which === 46 && 46 === keyCod){ // evt.which = 46 this is check to not let user to enter more that one ". (Dot)" in decimal fields 
            evt.preventDefault();
            return;
          }
          if(evt.which === 45 && 45 === keyCod){ // evt.which = 45 this is check to not let user to enter more that one "- (Dash)" in decimal fields
            evt.preventDefault();
            return;
          }
        }
      }

      /** (evt.which < 48 || evt.which > 57) allow only numbers from 0-9
      evt.which != 46 to allow ". (Dot)"
      evt.which != 46 to allow ". (Dash)"
      evt.which != 0 which has no Keys configured - additional fi
      evt.which != 8 which is allow backspace / delete */

      if (evt.which != 8 && evt.which != 0 && (evt.which < 48 || evt.which > 57) && evt.which != 46 && evt.which != 45){
        evt.preventDefault();
        return;
      }
    });
  });
}

/**
 * This method is used to find the Duplicates in a array.
 * @param {array} attrValueArray - This attribiute will have an array of attribute value 
 */
export function findDuplicateInArray(attrValueArray) {
  var object = {};
  var result = [];

  attrValueArray.forEach(function (item) {
    if(!object[item])
        object[item] = 0;
      object[item] += 1;
  })

  for (let prop in object) {
    if(object[prop] >= 2) {
      result.push(prop);
    }
  }
  return result;
}

/**
 * This method is used to check whether the attribute value is epty or not.
 * @param {string} str - This will have the attribute value.
 */
export function isEmptyOrSpaces(str){
  return str === null || str.match(/^ *$/) !== null;
}


export function downloadCSV(csvDataStr, fileName){
  let downloadElement = document.createElement('a');

  // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
  downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvDataStr);
  downloadElement.target = '_self';
  // CSV File Name
  downloadElement.download = fileName;
  // below statement is required if you are using firefox browser
  document.body.appendChild(downloadElement);
  // click() Javascript function to download CSV file
  downloadElement.click();
}

/**
 * This method is used to sort the Picklist options in the Respective Prompts. 
 */
export function sorting(a, b) {
  const labelA = a.picklistLabel.toUpperCase();
  const labelB = b.picklistLabel.toUpperCase();

  let comparison = 0;
  if (labelA > labelB) {
    comparison = 1;
  } else if (labelA < labelB) {
    comparison = -1;
  }
  return comparison;
}

export function convertDateToCurrentUserTimeZone(inputDate){
  var dateFormat = new Date(inputDate); 
  var options = {
    year: 'numeric', month: 'numeric', day: 'numeric',
    hour: 'numeric', minute: 'numeric', second: 'numeric',
    hour12: false,
    timeZone : TIME_ZONE
  };
  let dateValue = new Intl.DateTimeFormat(LOCALE, options).format(dateFormat); 
  return dateValue;
}

export function coreAttributeSorting(a, b) {
  const labelA = a.Sorting_Order__c;
  const labelB = b.Sorting_Order__c;
  const attrNameA = a.Attribute_Master__r.Name.toUpperCase();
  const attrNameB = b.Attribute_Master__r.Name.toUpperCase();
  let comparison = 0;
  if(labelA  < labelB){
    comparison =  -1;  
  }else  if(labelA  > labelB){
    comparison =  1;
  }else{
    if(attrNameA < attrNameB){
      comparison =  -1;
    }else if(attrNameA > attrNameB){
      comparison =  1;
    }
  }
  return comparison;
}

export function showAndHideGoToG1PromptButton(plantAssetPromptDetail) {
  return (plantAssetPromptDetail.Account_Plant__r.Asset_Builder_Status__c !== 'Closed' ||
    plantAssetPromptDetail.Account_Plant__r.Asset_Builder_Status__c !== 'Completed');
}

//This method is used to get the picklist values of a Bulk Import Type
export function bulkImportTypePicklistValues(){
  let picklistShortNameWithPicklistLabels = {};
  picklistShortNameWithPicklistLabels = {
    singleBaseAssetTemplate: 'Single Base Asset Template Prompts',
    multipleBaseAssetTemplate: 'Multiple Base Asset Template Prompts',
    manual: 'Manual',
    completed: 'Completed'
  };
  return picklistShortNameWithPicklistLabels;
}

export function buttonLabels(){
  let buttonLabelsObject = {};
  buttonLabelsObject = {
    saveAndResume: 'Save & Resume',
    next: 'Next',
    recordCountForEachPrompt: 3001
  };
  return buttonLabelsObject;
}


export function updateG1PlantAssetPromptDetailBulkImportType(inputVariableforThis, plantAssetId, jsonInputParametersAndValues){
  updateG1PlantAssetPromptDetail({
    plantAssetId: plantAssetId,
    jsonInputParametersAndValues : jsonInputParametersAndValues
  }).then(result => {
    if (result) {
      showAndHideSpinner(inputVariableforThis, 'hidespinner');
    }
  }).catch(error => {
    if (error) {
      showAndHideSpinner(inputVariableforThis, 'hidespinner');
      showToast(inputVariableforThis, error.body.message, 'Error', 'error');
    }
  });
}

export function uniqueNameValidationFun(uniqueValidationColName, attributeHeaderAndUOM, self){
  if(uniqueValidationColName.has(attributeHeaderAndUOM)){
    if(uniqueValidationColName.size > 0){
      if(self.showUniqueNameToastMessage){
        showToast(self, 'Please enter unique name for ' + Array.from(uniqueValidationColName) , 'Error', 'error');
        self.showUniqueNameToastMessage = false;
      }
      self.isDisableButton = true;
    }else{
      self.isDisableButton = false;
    }
  }else if(uniqueValidationColName.size <= 0){
    self.isDisableButton = false;
    self.showUniqueNameToastMessage = true;
  }else if(!uniqueValidationColName.has(attributeHeaderAndUOM)){
    self.showUniqueNameToastMessage = true;
  }
}

export function generateNeuronTemplate(plantAssetId, isImpWiz){
    var result;
    var templateFile;
    var piTemplateFile;
    var csvInput;
    let siteMetadataIdToRecordDetails = new Map();
    let baseAssetToAttrMap = new Map();
    let coreAttributePathGenerationMap = new Map();
    fireEvent('Asset Builder', 'showspinnercompwithmessage', true);
    getSiteMetadata({
            plantAssetId: plantAssetId,
          }).then(result => {
            if(result !== ''){
              csvInput = result;
              var inputData = JSON.parse(csvInput);
              var siteMetadata = inputData.SiteMetadataRecords;
              var attribute = inputData.Attributes;
              if(inputData.TemplateCSV === 'No CSV Files Found'){
                fireEvent('Asset Builder', 'showspinnercompwithmessage', false);
                showToast(self, 'No Template file found in IWFD', 'Info', 'info');
              }else{
                templateFile = btoa(encodeURIComponent(inputData.TemplateCSV).replace(/%([0-9A-F]{2})/g, function(match, p1) { return String.fromCharCode('0x' + p1); }));
                let rowEnd = '\n';
                let csvString = ''; // csvString - This attribute will be passed as a input to form a CSV File.
                let rowData = new Set(); // rowData - This will have the static Column Headers.
                let attrSet = new Set(); // attrSet - This will have the Dynamic column Headers from Site Metadata Attribute Info Field (Key).

                for (var attrRecordKey in attribute) {
                  let attributeRecordInstance = [];
                  let attributeRecord = attribute[attrRecordKey];
                  let baseAssetId = attributeRecord.Base_Asset_Name__c;
                  if(attributeRecord.Show_Path_in_CSV_Generation__c){
                    let conCatName = attributeRecord.Attribute_Master__r.Name+
                              attributeRecord.Base_Asset_Name__r.Name+
                              attributeRecord.Prompt_Information__r.Name;
                    coreAttributePathGenerationMap.set(conCatName, attributeRecord.Name);
                  }
                  if(attributeRecord.Default_value__c !== '' && attributeRecord.Default_value__c !== undefined){
                    if(!baseAssetToAttrMap.has(baseAssetId)){
                      baseAssetToAttrMap.set(baseAssetId, attributeRecordInstance);
                    }
                    baseAssetToAttrMap.get(baseAssetId).push({
                      attributeRecord:attributeRecord
                    });
                  }
                }

                for (var siteMetadataRecordKey in siteMetadata) {
                  let siteMetadataRecord = siteMetadata[siteMetadataRecordKey];
                  siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
                }

                rowData.add('Selected(x)'); // Static column Headers for the CSV File.
                rowData.add('Parent'); // Static column Headers for the CSV File.
                rowData.add('Name'); // Static column Headers for the CSV File.
                rowData.add('ObjectType'); // Static column Headers for the CSV File.
                rowData.add('Description'); // Static column Headers for the CSV File.
                rowData.add('Template'); // Static column Headers for the CSV File.
                rowData.add('PI_Template');
                siteMetadata.forEach(function(record) {
                  Object.keys(record).forEach(function (key) {
                    if(key === 'Attribute_Info__c'){
                      if (record.hasOwnProperty(key)) {
                        let attrInfoJSON = record[key];
                        JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
                          if(attrJSONKey.trim() !== '' && attrJSONKey !== 'Inverter Name' && attrJSONKey !== 'PI_Template'){
                            var pipeSym = '|';
                            attrSet.add(pipeSym.concat(attrJSONKey));
                          }
                        });
                      }
                    }
                  });
                });
                rowData = Array.from(rowData).concat(Array.from(new Set(attrSet)).sort()); // rowData - This will have the Column Headers for the CSV File.

                csvString += rowData.join(',');
                csvString += rowEnd;
                for(let i=0; i < siteMetadata.length; i++){
                  let colValue = 0;
                  for(let key in rowData) {
                    if(rowData.hasOwnProperty(key)) {
                    let keyname = rowData[key] === 'Parent'?'Parent_Asset_Short_Name__c' : // Replacing the Static Column Headers with the Site Metadata Field Name.
                            rowData[key] === 'Name'?'Asset_Short_Name__c' :
                            rowData[key] === 'ObjectType'?'Name' :
                            rowData[key] === 'Description'?'Asset_Name__c' :
                            rowData[key] === 'Template'?'Base_Asset_Template__r.Name' : rowData[key];
                      if(keyname === 'Selected(x)' ){
                        if(colValue > 0){
                          csvString += ',';
                        }
                        let value = '';
                        csvString += '"'+ value +'"';
                        colValue++;
                      }else if(keyname === 'Parent_Asset_Short_Name__c' || keyname === 'Asset_Short_Name__c' ||
                          keyname === 'Name' || keyname === 'Asset_Name__c'){
                        let rowKey = keyname;
                        if(colValue > 0){
                          csvString += ',';
                        }
                        // If the column is undefined, it as blank in the CSV file.
                        let value = '';
                        if(rowKey === 'Name'){
                          value = 'Element';
                        }else{
                          value = siteMetadata[i][rowKey] === undefined ? '' : siteMetadata[i][rowKey];
                        }
                        csvString += '"'+ value +'"';
                        colValue++;
                      }else if(keyname === 'Base_Asset_Template__r.Name'){
                        let sitemetadatacount = i;
                        if(colValue > 0){
                          csvString += ',';
                        }
                        let value = siteMetadata[sitemetadatacount].Base_Asset_Template__r.Name !== ''?siteMetadata[sitemetadatacount].Base_Asset_Template__r.Name : '';
                        let batName = '';
                            if(value === '_Generic Subarray'){
                              batName = 'Base Subarray';
                            }else{
                              batName = value;
                            }
                        csvString += '"'+ batName +'"';
                        colValue++;
                      }else if(keyname !== 'Parent_Asset_Short_Name__c' && keyname !== 'Asset_Short_Name__c' && keyname !== 'Name' &&
                      keyname !== 'Asset_Name__c' && keyname !== 'Base_Asset_Template__r.Name' && keyname !== 'Selected(x)'){
                        let rowKeyWithSym = rowData[key];
                        let rowKey;
                        if(rowKeyWithSym === 'PI_Template'){
                          rowKey = rowKeyWithSym;
                        }else{
                          rowKey = rowKeyWithSym.slice(1);
                        }
                        let attrName = 'Attribute_Info__c';
                        if(colValue > 0){
                          csvString += ',';
                        }
                        let attrValues = siteMetadata[i][attrName];
                        if(attrValues !== undefined){
                          JSON.parse(attrValues, (attrJSONKey, attrJSONValue) => {
                            if(attrJSONKey === rowKey){
                              let value = attrJSONValue;
                              let sitemetadatacount = i;
                              var recordId = attrJSONValue;
                              var patt = /^[0-9a-zA-Z]{15}[0-9a-zA-Z]{3}|[0-9a-zA-Z]{15}?$/;
                              var salesforceRecordIdCheck = patt.test(recordId);

                              if(attrJSONValue === '' && siteMetadata[i].Base_Asset_Template__c != ''){
                                if(baseAssetToAttrMap.has(siteMetadata[i].Base_Asset_Template__c)){
                                      var attrRecord = baseAssetToAttrMap.get(siteMetadata[i].Base_Asset_Template__c);
                                      for (var attributeRecordKey in attrRecord) {
                                        let attributeRecord = attrRecord[attributeRecordKey];
                                        var attributeMasterName = attributeRecord.attributeRecord.Attribute_Master__r.Name;
                                        var attrDefaultValue = attributeRecord.attributeRecord.Default_value__c;
                                        if(attributeMasterName === attrJSONKey){
                                          value = attrDefaultValue;
                                        }
                                      }
                                }
                              }else if(salesforceRecordIdCheck){
                                if(attrJSONValue !== '' && siteMetadata[i].Base_Asset_Template__c != ''){
                                  let concatName = attrJSONKey+siteMetadata[sitemetadatacount].Base_Asset_Template__r.Name+siteMetadata[sitemetadatacount].Prompt_Information__r.Name;
                                        if(coreAttributePathGenerationMap.has(concatName)){
                                          if(siteMetadataIdToRecordDetails.has(attrJSONValue)){
                                              value = siteMetadataIdToRecordDetails.get(attrJSONValue).Parent_Asset_Short_Name__c+'\\'+siteMetadataIdToRecordDetails.get(attrJSONValue).Asset_Short_Name__c;
                                          }
                                        }

                                }else{
                                  if(siteMetadataIdToRecordDetails.has(attrJSONValue)){
                                          value = siteMetadataIdToRecordDetails.get(attrJSONValue).Asset_Short_Name__c;
                                  }
                                }
                              }else{
                                value = attrJSONValue === undefined ? '' : attrJSONValue;
                              }
                              csvString += '"'+ value +'"';
                              colValue++;
                            }
                          });
                        }
                      }
                    }
                  }
                  csvString += rowEnd;
                }

              piTemplateFile = btoa(encodeURIComponent(csvString).replace(/%([0-9A-F]{2})/g, function(match, p1) { return String.fromCharCode('0x' + p1); }));
              //report generation logic
                createPE({
                    plantAssetId : plantAssetId
                  })
                  .then(response => {
                    let res = JSON.parse(response);
                    if (res.result) {
                        //call neuron API
                        fireEvent('Asset Builder', 'showspinnercompwithmessage', false);
                        fireEvent('Asset Builder', 'showspinnercompwithmessageWithDriveconversion', true);
                        var requestAttributes = {'plantAssetId' : plantAssetId};
                        sendNeuronTemplate(JSON.stringify(requestAttributes), piTemplateFile, templateFile, isImpWiz);
                    }
                  }).catch(error => {
                    if (error) {
                      fireEvent('Asset Builder', 'showspinnercompwithmessage', false);
                      showToast(self, 'No data available', 'Error', 'error');
                    }
                  });
              }
            }else{
              fireEvent('Asset Builder', 'showspinnercompwithmessage', false);
              showToast(self, 'No site metadata available', 'Info', 'info');
            }
          }).catch(error => {
              fireEvent('Asset Builder', 'showspinnercompwithmessage', false);
              fireEvent('Asset Builder', 'showspinnercomp', false);
              showToast(self, 'No data available', 'Info', 'info');
          });
}

function sendNeuronTemplate(requestParameters, assetModelBase64, templatesBase64, isImpWiz) {

    var resultNeuron;
    callNeuronAPI({
          requestParameters : requestParameters,
          assetModelBase64 : assetModelBase64,
          templatesBase64 : templatesBase64,
      }).then(result => {
          if(result.status === 'success') {
              resultNeuron = result;
              let eventDetails = {
                    status : resultNeuron.status,
                    message : 'Download updated neuron template or navigate to IWF',
                    impWizURL : '/lightning/n/Implementation_Wizard_From',
                    fileURL : '/sfc/servlet.shepherd/document/download/'+resultNeuron.cdID,
                    showFinishConfirmCmp : false,
                    showSendNeuronCmp : true
                 }
                 fireEvent('Asset Builder', 'showspinnercompwithmessageWithDriveconversion', false);
                 if(isImpWiz){
                    fireEvent('utilsEvent', 'generateNeuronDetail', eventDetails);
                 } else {
                    fireEvent('Asset Builder', 'generateNeuronDetailOnFinish', eventDetails);
                 }
          } else if(result.status === 'error') {
              resultNeuron = result;
              let eventDetails = {
                    status : resultNeuron.status,
                    message : resultNeuron.errorMessage,
                  }
              fireEvent('Asset Builder', 'showspinnercompwithmessageWithDriveconversion', false);
              if(isImpWiz){
                    fireEvent('utilsEvent', 'generateNeuronDetail', eventDetails);
              } else {
                    fireEvent('Asset Builder', 'generateNeuronDetailOnFinish', eventDetails);
              }
          }
      }).catch(error => {
          fireEvent('Asset Builder', 'showspinnercompwithmessageWithDriveconversion', false);
          showToast(self, 'Error in API call', 'Error', 'error');
      });
    }

export function readCSVAndMapImportRecords(csvLinesData, siteMetadataMapVal, promptSiteMetadata, 
  picklistValuesMap, sitemetaRecordCountInCSV){
  
  var csvLines = [];
  var duplicateCheckArray = [];
  let isAssetNameNotUnique = false;
  var siteMetadataArray = [];
  let siteMetadataRecords;
  let updateExecuteForSMCountGreaterInCSV = true;
  let siteMetadataMap = new Map();
  let isAltParentNotMatch = false;
  
  siteMetadataMap = siteMetadataMapVal;
  siteMetadataRecords = promptSiteMetadata;
  

  csvLines = csvLinesData;
  var csvDataColumns = [];
  var duplicateCheck = [];
  var isExecute = true;
  var isUpdateExecute = true;
  var isDelete = false;
  var csvLinesHeaders = csvLines[0].split(',');
  var csvRowDataType = csvLines[1].split(',');
  var reference = csvLines[5].split(',');
  var uniqueValues = csvLines[4].split(',');
  var attributeType = csvLines[2].split(',');
  var csvDisplayHeaders = csvLines[6].split(',');
  var attrApiToDisplayNameMap = new Map();
  var parentAssetMap = new Map();
  var pickListDetailMap = new Map();
  var uniqueNameMap = new Map();
  var parentAssetValCheckMap = new Map();
  var showGoToG1AndResumeButtonInPrompt = false;
  
  if(siteMetadataMap.size > sitemetaRecordCountInCSV && sitemetaRecordCountInCSV !== undefined){
    showToast(self, smCountGreaterThanRecordCountInCSV, 'Error', 'error', 'sticky');
    showGoToG1AndResumeButtonInPrompt = true;
  }else{
    for (var i = 7; i < csvLines.length; i++) {
      csvDataColumns = csvLines[i].split(',');
      for (var j = 1; j < csvDataColumns.length; j++) {
        if(!isEmptyOrSpaces(csvDataColumns[0])){
          if ((uniqueValues[j] == 'TRUE' || uniqueValues[j] == 'true') && reference[j] == 'Asset Name') {
            if(isEmptyOrSpaces(csvDataColumns[j])){
              let displayHeadersWithAssetName = csvDisplayHeaders[j];
              isAssetNameNotUnique = true;
              if(!duplicateCheckArray.includes(displayHeadersWithAssetName)){
                duplicateCheckArray.push(displayHeadersWithAssetName);
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
          if(!duplicateCheckArray.includes(attrApiToDisplayNameMap.get(key))){
            duplicateCheckArray.push(attrApiToDisplayNameMap.get(key));
          }
        }
      }
    }

    if (duplicateCheck.length > 0) {
      isAssetNameNotUnique = true;
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

    for (var i = 7; i < csvLines.length - 1; i++) {
      csvDataColumns = csvLines[i].split(',');
      var siteMetadataIdVal = csvDataColumns[0];
      var parentSiteMetadataValue = csvDataColumns[1].trim();
      for (var j = 1; j < csvDataColumns.length; j++) {
        if(reference[j] == 'Parent Asset'){
          if (siteMetadataIdVal != null && parentAssetValCheckMap.has(siteMetadataIdVal)) {
            if (parentSiteMetadataValue.toLowerCase() != parentAssetValCheckMap.get(siteMetadataIdVal)) {
              isExecute = false;
              isUpdateExecute = false;
              showGoToG1AndResumeButtonInPrompt = true;
              showToast(self, parentSiteMetadataErrMsg + '--> ' + parentSiteMetadataValue, 'Error', 'error', 'sticky');
              break;
            }
          } else {
            isExecute = false;
            isUpdateExecute = false;
            showGoToG1AndResumeButtonInPrompt = true;
            showToast(self, parentSiteMetadataErrMsg + '--> ' + parentSiteMetadataValue, 'Error', 'error', 'sticky');
            break;
          }
        }
      }
      if(!isExecute && !isUpdateExecute){
        showGoToG1AndResumeButtonInPrompt = true;
        break;
      }
    }

    if(isUpdateExecute){
      
      /*
        * Split the Total Csv lines in to Batches by ignoring the first four lines(Headers part)
        * Each batch default size is 100
      */
      for (var i = 7; i < csvLines.length - 1; i++) {
        csvDataColumns = csvLines[i].split(',');
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
                      if (picklistValuesMap !== 'No Data' && picklistValuesMap !== undefined) {
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
                          isAltParentNotMatch = true;
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
                    if (reference[j] == 'rowGenAttribute') {
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
                    if (picklistValuesMap !== 'No Data' && picklistValuesMap !== undefined) {
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
                          isAltParentNotMatch = true;
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
            siteMetadataArray.push(siteMetadataMap.get(siteMetadataId));
          }
        } else if(siteMetadataMap.size < sitemetaRecordCountInCSV && sitemetaRecordCountInCSV !== undefined) {
          updateExecuteForSMCountGreaterInCSV = false;
        }
      }

      if(!updateExecuteForSMCountGreaterInCSV){
        showToast(self, smCountLesserThanRecordCountInCSV, 'Info', 'info', 'sticky');
      }
    }
  }
  let mapvalues = {};
  mapvalues={
    showGoToG1AndResumeButtonInPrompt: showGoToG1AndResumeButtonInPrompt,
    isAssetNameNotUnique: isAssetNameNotUnique,
    siteMetadataArray : siteMetadataArray,
    isDelete : isDelete,
  };
  return mapvalues;
}