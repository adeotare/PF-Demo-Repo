import { LightningElement, api, track, wire } from 'lwc';
import getCompletenessReportData from "@salesforce/apex/CompletenessReport.getCompletenessReportData"; // Client side controller to fetch report data
import { loadScript } from 'lightning/platformResourceLoader'; // used to load the 3rd party script 
import D3 from '@salesforce/resourceUrl/d3'; // used for grouping the report data
import { showToast } from "c/utils"; // to show any exception message
// custom label to store the report data info message
import noDataForCompletenessReport from '@salesforce/label/c.NoDataForCompletenessReport';
import dataAvailableForCompletenessReportInfoMsg from '@salesforce/label/c.DataAvailableForCompletenessReportInfoMsg';

import { fireEvent } from 'c/pubsub'; // publish and subscribe model to send info across dom

/**
* To form dynamic table headers with Customer Facing Notes and Attribute Master Units.
* @param {string} plantAssetId - This attribute will take the current plant asset id to generated the report for the passed plant asset.
* @param {string} promptType - This attribute will take the prompt type (eg, Solar, Wind, Met Mast, Switchgear and Substation) to query only 
*                              particualr prompt type completness reports
* @param {integer} totalCompCount - This attribute will take the total count of Prompt type from the completenessReportParent comp. 
*                                  This will help us to enable and disable Run Report button in assetBuilderReportContainer with a pubsub 
*                                    event.
* @param {boolean} isLoading - To show and hide the lightning spinner.
* @param {boolean} hideInfo - To show and hide the info component - if there is not data to run report for a specific prompt type, 
*                                we will show info message using c-report-info-message custom component.
* @param {string} reportDataInfoMessage - This attribute hold the c-report-info-message component text message. 
* @param {string} className - To pass CSS "class" name to c-report-info-message - please refer c-report-info-message component for more details.
* @param {string} iconName - To pass "icon name" to c-report-info-message - please refer c-report-info-message component for more details.
* @param {string} title - To pass "title" to c-report-info-message - please refer c-report-info-message component for more details.
* @param {object} pageRef - This attribute is mandatory for pubsub modal. This will make sure the event fires and handled in the same page. 
* @param {array} reportData - List of record from Asset Builder Report Data object to generate the completeness report
* @param {array} nestedReportData - Output of D3 nest method. List of record from Asset Builder Report Data object is grouped based on three field.
*                                  Please check this.d3Nest();  
* @param {array} systemNameArray - List of system names from custom metadata eg(Drive, Drive Plus).
* @param {boolean} reportGenerated -  ************* May be we have to remove this attribute - will check and remove it *************
* @param {map} promptInfoAndIdMap - To store prompt Name and its prompt id eg(P.1.0 Plant Info - Solar - prompt1) which is stored in 
*                                    all prompt information object records and required to open a prompt in asset builder flow.
* @param {map} promptInfoAndPapdRecMap - To store prompt names and its previous prompt id which is required to open a prompt in asset builder flow.
*/

export default class CompletenessReport extends LightningElement {
  @api plantAssetId;
  @api promptType;
  @api totalCompCount;
  @track isLoading = false;
  @track hideInfo = false;
  @track reportDataInfoMessage;
  @track className;
  @track iconName;
  @track title;
  pageRef = 'Asset Builder';
  reportData;
  nestedReportData;
  systemNameArray = [];
  reportGenerated = false;
  promptInfoAndIdMap = new Map();
  promptInfoAndPapdRecMap = new Map();
  baseAssetAndPromptNameToAssetCountMap = new Map();
  totalAssetCount = 0;

  connectedCallback(){
    this.isLoading = true;
    getCompletenessReportData({
      plantAssetId: this.plantAssetId, // Plant asset id to query reportData
      promptType: this.promptType, // Plant asset id to query reportData related to only specific prompt type as the report will be sectioned based on prompt type 
    })
      .then(result => {
        let inputData = JSON.parse(result);
        if(inputData){
          this.reportData = inputData.completnessReport; // Report data from database - more detail please refer the comments for all params above.
          this.systemNameArray = inputData.systemName; // System name from database - more detail please refer the comments for all params above.
          for(var promptInfoAndIdKey in inputData.promptInfoAndId){ // Looping the prompt name and its id to form a map - more detail please refer the comments for all params above.
            this.promptInfoAndIdMap.set(promptInfoAndIdKey, inputData.promptInfoAndId[promptInfoAndIdKey]);
          }
          for(var promptInfoAndPapdRecKey in inputData.promptInfoAndPapdRec){ // Looping the prompt info and its previous prompt id to form map - more detail please refer the comments for all params above.
            this.promptInfoAndPapdRecMap.set(promptInfoAndPapdRecKey, inputData.promptInfoAndPapdRec[promptInfoAndPapdRecKey]);
          }
          for(var baseAssetAndPromptName in inputData.baseAssetAndPromptNameToAssetCount){
            this.baseAssetAndPromptNameToAssetCountMap.set(baseAssetAndPromptName, inputData.baseAssetAndPromptNameToAssetCount[baseAssetAndPromptName]);
          }
        }

        if(this.reportData.length > 0){ // If report data is available, load the D3 nest script to group the data
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
              showToast(this, 'Problem in loading javascript library, Please contact administrator', 'Error', 'error'); // No need of custom label
            });
        }else{
          this.reportDataInfoMessage = noDataForCompletenessReport;
          this.className = 'infoBox';
          this.iconName = 'utility:info_alt';
          this.title = 'Info';

          this.isLoading = false;
          fireEvent(this.pageRef, 'showRunReportButton', this.totalCompCount);
        }
      })
      .catch(error => {
        this.isLoading = false;
      });
  }

  /**
   * To form dynamic table headers with Customer Facing Notes and Attribute Master Units.
   * @param {object} table - This attribute will have DOM object of the <table class="tblCr" lwc:dom="manual"></table> element with the help of the class name. 
   * @param {array} systemOrder - Holds the system name array
   * @param {array} typeOrder - This holds the completeness report second row column values 
   * @param {map} systemAndTypeCellIndexMap - This holds the count of cell in a row which the data is plotted in the loop (eg. Drive-Required - 3, Drive-Required (Default) - 4)
   * @param {map} systemAndTypeCellIndex - This holds the starting cell number in a row (value = 2) as the first two columns will have prompt name and base asset name 
   * @param {integer} totalCellCount - This holds the total cell count in a row based on this.systemNameArray size and typeOrder size.
   * @param {map} totalAttrCountMap - This will have the column wise total for completeness report
  */

  @api
  loadReportData() {
    try {
      if(this.reportData.length > 0 && this.reportGenerated === false){
        this.isLoading = true; // please refer the comments on top
        this.hideInfo = true; // please refer the comments on top

        var table = this.template.querySelector('.tblCr');

        var systemOrder = this.systemNameArray;
        var typeOrder = ['Required', 'Required (Default)', 'Optional', 'Optional (Default)']; // Manually formed to have a sorting order like the way it is addes in the array, please dont change
        var systemAndTypeCellIndexMap = new Map();

        var systemRow = table.insertRow(0); // Inserting report first row
        systemRow.insertCell(0); // first three cells will be blank as this report will be the salesforce matrix report format - please refer the report UI for more details 
        systemRow.insertCell(1);
        systemRow.insertCell(2);

        var typeRow = table.insertRow(1);
        var cell0 = typeRow.insertCell(0); // Prompt Name
        var cell1 = typeRow.insertCell(1); // Base Asset Name 
        var cell2 = typeRow.insertCell(2); // Asset Count

        cell0.innerHTML = 'Prompt Name';
        cell0.setAttribute('class', 'promptHeaderName'); // Class names will help in CSS 

        cell1.innerHTML = 'Base Asset Name';
        cell1.setAttribute('class', 'batHeaderName'); // Class names will help in CSS

        cell2.innerHTML = 'Asset Count';
        cell2.setAttribute('class', 'assetCount'); // Class names will help in CSS

        var systemAndTypeCellIndex = 3;
        var totalCellCount = (systemOrder.length * typeOrder.length) + 2; // this.systemNameArray size and typeOrder size output is 8. As the cell index starts with 0, adding one (1).
        var totalAttrCountMap = new Map();

        // Drive Scores and Drive Plus Scores Header formation along with Required, Optional
        for(var i = 0; i < systemOrder.length; i++){
          var sysNameCells = systemRow.insertCell(i + 3);
          sysNameCells.innerHTML = systemOrder[i] + ' Scores';
          sysNameCells.setAttribute('colspan', typeOrder.length); // Colspan to merge the first row System name cells based on type length

          for(var j = 0; j < typeOrder.length; j++){
            var typeNameCells = typeRow.insertCell(j + 3);
            typeNameCells.innerHTML = typeOrder[j];
            typeNameCells.setAttribute('class', 'typeCls'); // Class names will help in CSS

            let sysAndType = (systemOrder[i] + '-' + typeOrder[j]);
            systemAndTypeCellIndexMap.set(sysAndType, systemAndTypeCellIndex);
            systemAndTypeCellIndex = systemAndTypeCellIndex + 1;
          }
        }

        this.nestedReportData = this.d3Nest(this.reportData, systemOrder, typeOrder); // D3 nest used to group the data base on three field - please check this.d3Nest() function 

        var reportDataRow; // To form report data row
        var cellCount; // Cell count is to track which cell index we need to populate the correct data, sometime some cell may not have value hence we should form the cell and write - (dash) instead of empty.

        for(var reportDatakey = 0; reportDatakey < this.nestedReportData.length; reportDatakey++){
          var reportDataValues = this.nestedReportData[reportDatakey];

          for(var promptNameKey in reportDataValues){
            var promptNameValues = reportDataValues[promptNameKey];
            var promptName;
            if(typeof promptNameValues === 'string') promptName = promptNameValues;
            if(typeof promptNameValues === 'object'){
              for(var baseAssetkey = 0; baseAssetkey < promptNameValues.length; baseAssetkey++){
                cellCount = 3;
                var baseAssetKeyValues = promptNameValues[baseAssetkey];
                var noOfRows = (baseAssetkey + 2);
                reportDataRow = table.insertRow(noOfRows);
                var promptCellVal = reportDataRow.insertCell(0);
                // This class name "promptName" is to help add eventListner in renderedCallback
                let promptNameInnerHTML = '<p class="promptName"';
                // HTML5 is designed with extensibility in mind for data that should be associated with a particular element but need not have any defined meaning. data-* attributes
                // data-promptid is to store the promptId related to the prompt name (e.g prompt1, prompt2, ..) which will help to navigate to respective prompt from the report 
                promptNameInnerHTML += ' data-promptid="' + (this.promptInfoAndIdMap.has(promptName) ? this.promptInfoAndIdMap.get(promptName) : 'noId') + '"';
                // data-plantassetid is to store plant asset id as it is needed to open prompt in asset builder
                promptNameInnerHTML += ' data-plantassetid="' + this.plantAssetId + '"';
                // data-previouspapdid is to store previous prompt id as it is needed to open prompt in asset builder
                promptNameInnerHTML += ' data-previouspapdid="' + (this.promptInfoAndPapdRecMap.has(promptName) ? this.promptInfoAndPapdRecMap.get(promptName).Previous_Plant_Asset_Prompt__c : 'noId') + '"'; // Previous Plant Asset Prompt Detail Id
                // promptName to show the prompt name (P.1.0 Plant Info Prompt - Solar) 
                promptNameInnerHTML += '>' + promptName + '</p>';
                promptCellVal.innerHTML = promptNameInnerHTML;

                var batCellVal = reportDataRow.insertCell(1);
                batCellVal.innerHTML = baseAssetKeyValues.key;
                batCellVal.setAttribute('class', 'batName'); // Class names will help in CSS
                batCellVal.innerHTML = baseAssetKeyValues.key;

                var assetNameCellVal = reportDataRow.insertCell(2);
                assetNameCellVal.innerHTML = (this.baseAssetAndPromptNameToAssetCountMap.get(promptName + '-' + baseAssetKeyValues.key) == undefined || this.baseAssetAndPromptNameToAssetCountMap.get(promptName + '-' + baseAssetKeyValues.key) == '') ? 'N/A' : this.baseAssetAndPromptNameToAssetCountMap.get(promptName + '-' + baseAssetKeyValues.key); // Asste count get it from the baseAssetAndPromptNameToAssetCountMap by using BaseAssetName
                assetNameCellVal.setAttribute('class', 'assetCountVal'); // Class names will help in CSS

                //Column wise total assetCount calculation for completeness report
                if(this.baseAssetAndPromptNameToAssetCountMap.get(promptName + '-' + baseAssetKeyValues.key) != undefined && this.baseAssetAndPromptNameToAssetCountMap.get(promptName + '-' + baseAssetKeyValues.key) != '' && this.baseAssetAndPromptNameToAssetCountMap.get(promptName + '-' + baseAssetKeyValues.key) != 'N/A'){
                  this.totalAssetCount = this.totalAssetCount + parseInt(this.baseAssetAndPromptNameToAssetCountMap.get(promptName + '-' + baseAssetKeyValues.key));
                }

                for(var systemKey in baseAssetKeyValues){
                  var systemValues = baseAssetKeyValues[systemKey];

                  if(typeof systemValues === 'object'){
                    for(var systemNameKey in systemValues){
                      var systemNameValues = systemValues[systemNameKey];

                      if(typeof systemNameValues === 'object'){
                        var totalSysAndType = (systemValues.length * systemNameValues.values.length);

                        for(var system in systemNameValues){
                          var typeNameObj = systemNameValues[system];
                          var systemNameForCheck;

                          if(typeof typeNameObj === 'string') systemNameForCheck = typeNameObj;
                          if(typeof typeNameObj === 'object'){

                            for(var typeNameKey in typeNameObj){
                              var typeName = typeNameObj[typeNameKey];

                              if(typeof typeName === 'object'){
                                for(const [key, value] of Object.entries(typeName)){
                                  var typeNameForCheck;

                                  if(typeof value === 'string') typeNameForCheck = value;
                                  var sysAndtypeConcan = systemNameForCheck + '-' + typeNameForCheck;

                                  if(typeof value === 'object'){
                                    var typeVal = value;
                                    var cellCountFromMap = systemAndTypeCellIndexMap.get(sysAndtypeConcan);

                                    // To form empty cell and populate dash (-)
                                    while(cellCountFromMap !== cellCount && cellCountFromMap > cellCount){
                                      let typeCellValue = reportDataRow.insertCell(cellCount);
                                      let cellValue = '-';
                                      typeCellValue.innerHTML = cellValue;
                                      typeCellValue.setAttribute('class', 'cellVal'); // Class names will help in CSS
                                      cellCount = cellCount + 1;
                                    }

                                    if(cellCountFromMap === cellCount){
                                      let typeCellVal = reportDataRow.insertCell(cellCount);
                                      let cellVal = typeVal.totalCompletedAttributeCount + '/' + typeVal.totalAttributeCount;
                                      typeCellVal.innerHTML = cellVal;
                                      typeCellVal.setAttribute('class', 'cellVal'); // Class names will help in CSS

                                      // Column wise total calculation for completeness report

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
                while(totalCellCount === cellCount || cellCount < totalCellCount){
                  let typeCellValue = reportDataRow.insertCell(cellCount);
                  let cellValue = '-';
                  typeCellValue.innerHTML = cellValue;
                  typeCellValue.setAttribute('class', 'cellVal'); // Class names will help in CSS
                  cellCount = cellCount + 1;
                }
              }
            }
          }
        }
        this.formTotalRow(table, totalCellCount, totalAttrCountMap);
      }
      this.reportGenerated = true;
    } catch (err) {
      this.isLoading = false;
      this.reportGenerated = false;
      showToast(this, 'Problem in running the report, Please contact administrator', 'Error', 'error'); // No need of custom label
    }
  }

  /**
   * 
   * @param {object} table - This attribute will 
   * @param {integer} totalCellCount - This attribute will take total column count (cell count) to populate  
   * @param {map} totalAttrCountMap - This will have the column wise total for completeness report
   */

  formTotalRow(table, totalCellCount, totalAttrCountMap){
    var totalCountRow = table.insertRow(-1);
    var totalTextCell0 = totalCountRow.insertCell(0);
    totalTextCell0.innerHTML = 'Total'; // Last row first two cells value 
    totalTextCell0.setAttribute('colspan', 2); // Colspan for first two columns 
    totalTextCell0.setAttribute('class', 'totalHeaderCell'); // Class names will help in CSS

    var totalAssetCountCell = totalCountRow.insertCell(1); // this cell is to have totalAssetCount
    totalAssetCountCell.innerHTML = this.totalAssetCount; // placing the totalAssetCount value in to the cell 
    totalAssetCountCell.setAttribute('class', 'cellVal'); // class name help in CSS


    for(var cnt = 3; cnt <= totalCellCount; cnt++){
      if(totalAttrCountMap.has(cnt)){
        var totalCell = totalCountRow.insertCell((cnt - 1));
        totalCell.innerHTML = totalAttrCountMap.get(cnt);
        totalCell.setAttribute('class', 'cellVal'); // Class names will help in CSS
      }else{
        var totalCell = totalCountRow.insertCell((cnt - 1));
        totalCell.innerHTML = '-';
        totalCell.setAttribute('class', 'cellVal'); // Class names will help in CSS
      }
    }
    this.isLoading = false;
  }

  /**
   * Descroption : This function takes the below parameters and group the report data. For grouping level, please check the comments in code below.
   * @param {array} reportData - List of record from Asset Builder Report Data object to generate the completeness report
   * @param {array} systemOrder - List of system names from custom metadata eg(Drive, Drive Plus) to sort the grouping in the order
   * @param {array} typeOrder - Manually formed type (eg. Required, Required (default),...) to have a sorting order like the way it is addes in the array.
   */

  d3Nest(reportData, systemOrder, typeOrder){
    return d3.nest()
      .key(function (data) { return data.Prompt_Information__r.Name; }) // First level grouping
      .key(function (data) { return data.Base_Asset_Template__r.Name; }).sortKeys(d3.ascending) // Second level grouping
      .key(function (data) { return data.System__c; }).sortKeys(function (a, b) { return systemOrder.indexOf(a) - systemOrder.indexOf(b); }) // Third level grouping 
      .key(function (data) { return data.Type__c; }).sortKeys(function (a, b) { return typeOrder.indexOf(a) - typeOrder.indexOf(b); }) // Forth level grouping 
      .rollup(function (dataRollup) {
        return {
          "totalCompletedAttributeCount": d3.sum(dataRollup, function (d) {
            return parseFloat(d.Total_Completed_Attribute_Count__c);  // Return the total no of attribute filled by users or defaulted value from core attribute record in prompt flow
          }),
          "totalAttributeCount": d3.sum(dataRollup, function (d) {
            return parseFloat(d.Total_Attribute_Count__c); // Return the total no of attribute for the grouping 
          })
        }
      })
      .entries(reportData); // Passing the raw reportData array to D3 nest function  
  }

  /**
   * - This will get executed after the component rendered phase. Here we use this standard LWC lifecycle hook function to add "onclick" 
   *    event listener.
   * - This event listener will help navigating to the respective prompt by a pubsub event.
   */

  renderedCallback(){
    var tblRows = this.template.querySelectorAll('.promptName');
    Array.prototype.map.call(tblRows, (inputComp) => {
      inputComp.addEventListener('click', function (evt) {
        let promptId = evt.target.dataset.promptid;
        let plantAssetIdEvt = evt.target.dataset.plantassetid;
        let previousPapdIdEvt = evt.target.dataset.previouspapdid;

        let promptIdEvtDetails = {
          promptId: promptId,
          plantAssetIdEvt: plantAssetIdEvt,
          previousPapdIdEvt: previousPapdIdEvt
        }

        /**
         * This varibale "pageRefCustom" is to replace "this.pageRef" variable, as we could not access the @api, @track, @wire variables in
         * renderedCallback()
         */
        let pageRefCustom = 'Asset Builder';
        fireEvent(pageRefCustom, 'showPrompt', promptIdEvtDetails);
      });
    });
  }
}