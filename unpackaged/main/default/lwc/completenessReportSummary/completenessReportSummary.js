import { LightningElement, api, track, wire } from 'lwc';
import getCompletenessReportSummary from "@salesforce/apex/CompletenessReportSummary.getCompletenessReportSummary";
import { loadScript } from 'lightning/platformResourceLoader';
import D3 from '@salesforce/resourceUrl/d3';
import { showToast } from "c/utils";
import noDataForCompletenessReport from '@salesforce/label/c.NoDataForCompletenessReport';
import dataAvailableForCompletenessReportInfoMsg from '@salesforce/label/c.DataAvailableForCompletenessReportInfoMsg';
import { fireEvent } from 'c/pubsub';
/**
 * Please refer the comments in completeness report, the logic is same.
 */
export default class CompletenessReportSummary extends LightningElement {
  @api plantAssetId;
  @api promptType;
  @api totalCompCount;
  @track reportData;
  @track nestedReportData;
  @track systemNameArray = [];
  @track reportData;
  @track isLoading = false;
  promptTypeArrayForSorting = [];
  reportGenerated = false;
  completenessReportSectionConfigMap = new Map(); // this map will help to populate the section name dynamically, the value will be fetched from custom metadata type
  pageRef = 'Asset Builder'; 

  @track hideInfo = false;
  @track reportDataInfoMessage;
  @track className;
  @track iconName;
  @track title;

  connectedCallback(){
    this.isLoading = true;
    getCompletenessReportSummary({
      plantAssetId : this.plantAssetId,
    })
    .then(result => {
      let inputData = JSON.parse(result);
      if(inputData){
        this.reportData = inputData.completnessReport;
        this.systemNameArray = inputData.systemName;
        this.promptType = inputData.promptType;
      }

      if(this.promptType.length > 0){
        for(var key in this.promptType){
          let customMetadataRec = this.promptType[key];
          this.promptTypeArrayForSorting.push(customMetadataRec.Prompt_Type__c);
          this.completenessReportSectionConfigMap.set(customMetadataRec.Prompt_Type__c, customMetadataRec);
        }
      }

      if(this.reportData.length > 0){
        Promise.all([
          loadScript(this, D3 + '/d3/d3.v4.min.js'),
        ])
        .then(() => {
          this.isLoading = false;
          this.reportDataInfoMessage = dataAvailableForCompletenessReportInfoMsg;
          this.className = 'successBox';
          this.iconName = 'utility:info';
          this.title = 'Info';

          fireEvent(this.pageRef, 'showRunReportButton', this.totalCompCount);
        }).catch((error) => {
          showToast(this,'Problem in loading javascript library, Please contact administrator','Error','error');
        });
      }else{
        this.isLoading = false;
        this.reportDataInfoMessage = noDataForCompletenessReport;
        this.className = 'infoBox';
        this.iconName = 'utility:info_alt';
        this.title = 'Info';

        fireEvent(this.pageRef, 'showRunReportButton', this.totalCompCount);
      }
    })
    .catch(error => {
      this.isLoading = false;
    });
  }
/**
 * Please refer the comments in completeness report, the logic is same.
 */
  @api
  loadReportData() {
    try {
      if(this.reportData.length > 0 && this.reportGenerated === false){
        this.isLoading = true;
        this.hideInfo = true;

        var table = this.template.querySelector('.tblCRSummary');

        var systemOrder = this.systemNameArray;
        var typeOrder = ['Required', 'Required (Default)', 'Optional', 'Optional (Default)'];
        var systemAndTypeCellIndexMap = new Map();

        var systemRow = table.insertRow(0);
        systemRow.insertCell(0);

        var typeRow = table.insertRow(1);
        var cell0 = typeRow.insertCell(0);
        cell0.innerHTML = 'Grouping';
        cell0.setAttribute('class', 'groupingHeaderName');

        var systemAndTypeCellIndex = 1; // used to identify the from which column the report data "1/20" should start as we have prompt type in the first column
        var totalCellCount = (systemOrder.length * typeOrder.length) + 1; // total column based on system and its type (Drive-Required, Drive-Optional, Drive Plus-Required) 
        var totalAttrCountMap = new Map();
        var summaryReportAvailableForPromptTypeArray = []; // to store prompt type which has summary report data 

        // Drive Scores and Drive Plus Scores Header formation along with Required, Optional
        for(var i = 0; i < systemOrder.length; i++){
          var sysNameCells = systemRow.insertCell(i+1);
          sysNameCells.innerHTML = systemOrder[i] + ' Scores';
          sysNameCells.setAttribute('colspan', typeOrder.length);
          
          for(var j = 0; j < typeOrder.length; j++){
            var typeNameCells = typeRow.insertCell(j+1);
            typeNameCells.innerHTML = typeOrder[j];
            typeNameCells.setAttribute('class', 'typeCls');
            systemAndTypeCellIndexMap.set((systemOrder[i]+'-'+typeOrder[j]), systemAndTypeCellIndex);
            systemAndTypeCellIndex = systemAndTypeCellIndex + 1;
          }
        }

        this.nestedReportData = this.d3Nest(this.reportData, systemOrder, typeOrder, this.promptTypeArrayForSorting);

        var reportDataRow;
        var cellCount;

        for(var summaryReportDatakey = 0; summaryReportDatakey < this.nestedReportData.length; summaryReportDatakey++){
          var reportDataValues = this.nestedReportData[summaryReportDatakey];

          for(var promptTypeKey in reportDataValues){
            var promptTypeValues = reportDataValues[promptTypeKey];
            var promptType;

            if(typeof promptTypeValues === 'string') promptType = promptTypeValues;
            if(typeof promptTypeValues === 'object'){
              cellCount = 1;
              var noOfRows = (summaryReportDatakey + 2);
              reportDataRow = table.insertRow(noOfRows);
              var promptCellVal = reportDataRow.insertCell(0);
              promptCellVal.innerHTML = (this.completenessReportSectionConfigMap.has(promptType)) ? this.completenessReportSectionConfigMap.get(promptType).Summary_Report_First_Column_Label__c : promptType;
              typeNameCells.setAttribute('class', 'sectionName');

              for(var systemKey in promptTypeValues){
                var systemValues = promptTypeValues[systemKey];
                var systemNameForCheck;

                if(typeof systemValues === 'object'){

                  for (const [key, value] of Object.entries(systemValues)) {
                    if(typeof value === 'string') systemNameForCheck = value;
                    if(typeof value === 'object'){
                      var typeValues = value;
                      var typeNameForCheck;

                      for(var typeKey in typeValues){
                        var typeVal = typeValues[typeKey];
                        if(typeof typeVal === 'object'){
                          for (const [key, value] of Object.entries(typeVal)){
                            if(typeof value === 'string') typeNameForCheck = value;
                            var sysAndtypeConcan = systemNameForCheck+'-'+typeNameForCheck;    
                            if(!summaryReportAvailableForPromptTypeArray.includes(promptType)){
                              summaryReportAvailableForPromptTypeArray.push(promptType);
                            }                        

                            if(typeof value === 'object'){
                              var typeVal = value;
                              var cellCountFromMap =  systemAndTypeCellIndexMap.get(sysAndtypeConcan);

                              while(cellCountFromMap !== cellCount && cellCountFromMap > cellCount){
                                let typeCellValue  = reportDataRow.insertCell(cellCount);
                                let cellValue = '-';
                                typeCellValue.innerHTML = cellValue;
                                typeCellValue.setAttribute('class', 'cellVal');
                                cellCount = cellCount + 1;
                              }

                              if(cellCountFromMap === cellCount){
                                let typeCellVal  = reportDataRow.insertCell(cellCount);
                                let cellVal = typeVal.totalCompletedAttributeCount +'/'+ typeVal.totalAttributeCount;
                                typeCellVal.innerHTML = cellVal;
                                typeCellVal.setAttribute('class', 'cellVal');
                                if(totalAttrCountMap.has(cellCount)){
                                  let maptotalAttrCountMapVal = totalAttrCountMap.get(cellCount);
                                  let maptotalAttrCountMapValArray = maptotalAttrCountMapVal.split("/");
                                  let exsitingCompletedAttrCount = parseInt(maptotalAttrCountMapValArray[0]);
                                  let exsitingTotalAttrCount = parseInt(maptotalAttrCountMapValArray[1]);
                                  let newCompletedAttrCount = exsitingCompletedAttrCount + parseInt(typeVal.totalCompletedAttributeCount);
                                  let newTotalAttrCount = exsitingTotalAttrCount + parseInt(typeVal.totalAttributeCount);
                                  let maptotalAttrCountMapNewVal = newCompletedAttrCount + '/' + newTotalAttrCount;
                                  totalAttrCountMap.set(cellCount, maptotalAttrCountMapNewVal);
                                }else{
                                  let newCompletedAttrCount = typeVal.totalCompletedAttributeCount;
                                  let newTotalAttrCount = typeVal.totalAttributeCount;
                                  let maptotalAttrCountMapNewVal = newCompletedAttrCount + '/' + newTotalAttrCount;
                                  totalAttrCountMap.set(cellCount, maptotalAttrCountMapNewVal);
                                }
                                cellCount = cellCount + 1;
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        this.createRowsHasNoData(table, totalCellCount, summaryReportAvailableForPromptTypeArray);
        this.formTotalRow(table, totalCellCount, totalAttrCountMap);
      }
      this.reportGenerated = true;
    }catch (err) {
      this.isLoading = false;
      this.reportGenerated = false;
      showToast(this,'Problem in running the report, Please contact administrator' + JSON.stringify(err),'Error','error'); // No need of custom label
    }
  }
/**
 * Please refer the comments in completeness report, the logic is same.
 */
  formTotalRow(table, totalCellCount, totalAttrCountMap){
    var totalCountRow = table.insertRow(-1);
    var totalTextCell0 = totalCountRow.insertCell(0);
    totalTextCell0.innerHTML = 'Total';
    totalTextCell0.setAttribute('class', 'totalHeaderCell');

    for(var cnt = 1; cnt < totalCellCount; cnt++){
      if(totalAttrCountMap.has(cnt)){
        var totalCell = totalCountRow.insertCell((cnt));
        totalCell.innerHTML = totalAttrCountMap.get(cnt);
        totalCell.setAttribute('class', 'cellVal');
      }else{
        var totalCell = totalCountRow.insertCell((cnt));
        totalCell.innerHTML = '-';
        totalCell.setAttribute('class', 'cellVal');
      }
    }
    this.isLoading = false;
  }
/**
 * Please refer the comments in completeness report, the logic is same.
 */
  createRowsHasNoData(table, totalCellCount, summaryReportAvailableForPromptTypeArray){
    var rowCount = 0;
    this.completenessReportSectionConfigMap.forEach((value, key, map) => {
      if(!summaryReportAvailableForPromptTypeArray.includes(key)){
        var emptyReportDataRow = table.insertRow((rowCount+2));
        var promptCellVal = emptyReportDataRow.insertCell(0);
        promptCellVal.innerHTML = this.completenessReportSectionConfigMap.get(key).Summary_Report_First_Column_Label__c;

        for(var emptyCellCount = 1; emptyCellCount < totalCellCount; emptyCellCount++){
          let typeCellValue  = emptyReportDataRow.insertCell(emptyCellCount);
          let cellValue = '-';
          typeCellValue.innerHTML = cellValue;
        }
      }
      rowCount = rowCount + 1;
    })
  }
/**
 * Please refer the comments in completeness report, the logic is same.
 */
  d3Nest(reportData, systemOrder, typeOrder, promptTypeArrayForSorting){
    return d3.nest()
    .key(function(data) { return data.Prompt_Information__r.Type__c; }).sortKeys(function(a, b) { return promptTypeArrayForSorting.indexOf(a) - promptTypeArrayForSorting.indexOf(b); })
    .key(function(data) { return data.System__c; }).sortKeys(function(a, b) { return systemOrder.indexOf(a) - systemOrder.indexOf(b); })
    .key(function(data) { return data.Type__c; }).sortKeys(function(a, b) { return typeOrder.indexOf(a) - typeOrder.indexOf(b); })
    .rollup(function(dataRollup){
      return {
        "totalCompletedAttributeCount": d3.sum(dataRollup, function(d) {
          return parseFloat(d.Total_Completed_Attribute_Count__c) ; 
        }),
        "totalAttributeCount": d3.sum(dataRollup, function(d) {
          return parseFloat(d.Total_Attribute_Count__c) ; 
        })
      }
    })
    .entries(reportData);
  }
}