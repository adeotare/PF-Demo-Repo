import { LightningElement, track, api } from 'lwc';
import getAllEvaluationValues from '@salesforce/apex/CapabilityReportController.getallEvaluationValues';
import {
    showToast
  } from "c/utils";

  /**
   * This component is used to form a Summary Report For a Paricaluar Plant Asset Id.
   * @param {array} colHeader - This attribute will have the Column Header Name.
   * @param {object} columnValues - This attribute will have the Column Values.
   * @param {array} resultLstArray - This attribute will total result where the evaluation value result meets pass alone.
   * @param {string} plantAssetId - This attribute will have the Plant Asset Id.
   * @param {map} evaluationValueMap - This attribute will have the group based on the Category and the Sub Category Name.
   * @param {boolean} hideInfo - This attribute will have the Boolean value to show the Summary Report.
   * @param {string} reportDataInfoMessage - This attribute will have the Rport Info Message.
   * @param {string} className - This attribute will have the ClassName for Report Info Message.
   * @param {string} iconName - This attribute will have the IconName for Report Info Message.
   * @param {string} title - This attribute will have the Title for Report Info Message.
   * @param {boolean} infoMessage - This attribute will have the Boolean value to show the Info Message.
   */
export default class CapabilityReportController extends LightningElement {
    @track colHeader = [];
    @track columnValues = [];
    @track resultLstArray = [];
    @api plantAssetId;
    evaluationValueMap = new Map();
    @track hideInfo = false;
    @track reportDataInfoMessage;
    @track className;
    @track iconName;
    @track title;
    @track infoMessage = false;

    connectedCallback() {
        getAllEvaluationValues({
            plantAssetId: this.plantAssetId,
        }).then(result => {
            if (result === '') {
                this.infoMessage = true;
                this.reportDataInfoMessage = 'No data available for this Plant Asset';
                this.className = 'infoBox';
                this.iconName = 'utility:info_alt';
                this.title = 'Info';
                //showToast(this, 'There is no Evaluation Value', 'Error', 'error');
            }else{
                this.infoMessage = false;
                var inputData = result;
                let evaluation = JSON.parse(inputData);
                let evaluationrecords = evaluation.evaluationValue;
                
                for (var evaluationValueRecordKey in evaluationrecords) {
                    let evalValueRecordInstance = [];
                    let evalValueRecord = evaluationrecords[evaluationValueRecordKey];
                    let subCategoryName = evalValueRecord.Evaluation__r.Sub_Category__c;
                    let categoryName = evalValueRecord.Evaluation__r.Category__c;
                    let testGroupName = subCategoryName +' - ' + categoryName +' Tests';
                    if(!this.evaluationValueMap.has(testGroupName)){
                        this.evaluationValueMap.set(testGroupName, evalValueRecordInstance);
                    }
                    this.evaluationValueMap.get(testGroupName).push({
                        evalValueRecord:evalValueRecord
                    });
                }

                this.colHeader.push('Test Group'); // Static Values for Table Headers.
                this.colHeader.push('Result'); // Static Values for Table Headers.
                this.evaluationValueMap.forEach((values,keys)=>{ // keys - This will have the Concatenate value of Sub Category Name and Category Name.
                    let columnValueArray = []; // columnValueArray - This will have the Column Values along with the ClassNme for CSS.
                    columnValueArray.push({
                        colValues: keys,
                        colClassName: 'colWidth'
                    });
                    columnValueArray.push({
                        colValues: this.fetchEvaluationValueResult(keys),
                        colClassName: 'colWidth'
                    });
                    this.columnValues.push(columnValueArray);
                })
                let totalResultArray = [];
                totalResultArray.push({
                    colValues: 'Total',
                    colClassName: 'colFooter'
                });
                var totalResult = this.resultLstArray.length+'/'+this.evaluationValueMap.size;
                totalResultArray.push({
                    colValues: totalResult,
                    colClassName: 'colWidth'
                });
                this.columnValues.push(totalResultArray);
            }
        })
    }

    /**
     * This method is used to get the Evaluation Result of Category and Sub Category Values.
     * @param {string} keys - This attribute will have the Concate value of Sub Category and Category Name along with Test.
     */
    fetchEvaluationValueResult(keys){
        if(keys){
            let resultLst = [];
            let lstSize = 0;
            if (this.evaluationValueMap.has(keys)) {
                var evaluationValueRecords = this.evaluationValueMap.get(keys);
                lstSize = evaluationValueRecords.length;
                for(var evalutionValueRecordKey in evaluationValueRecords){
                    let evalValueRecord = evaluationValueRecords[evalutionValueRecordKey];
                    var result = evalValueRecord.evalValueRecord.Result__c === undefined ? '' :evalValueRecord.evalValueRecord.Result__c;
                    if(result === 'Pass'){
                        resultLst.push('Pass'); 
                    }
                }
            }
            if(resultLst.length === lstSize){
                this.resultLstArray.push('Pass');
            }
            var result = resultLst.length +'/'+ lstSize;
            return result;
        }
    }
}