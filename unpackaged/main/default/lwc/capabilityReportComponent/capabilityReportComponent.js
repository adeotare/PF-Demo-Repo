import { LightningElement, track, api } from 'lwc';
import getEvaluationValues from '@salesforce/apex/CapabilityReportController.getEvaluationValues';
import { fireEvent } from 'c/pubsub';
import id from '@salesforce/user/Id';

/**
 * This component is used to form a Report Table for a particular Category and Sub Category from the Evaluation Value Records.
 * @param {object} colHeader - This attribute will have Column Header of the report component.
 * @param {object} columnValues - This attribute will have Column Values of the report component.
 * @param {array} totalResultLstArray - This attribute will total result where the evaluation value result meets pass alone.
 * @param {string} plantAssetId - This attribute will hold the current Plant Asset Id.
 * @param {string} categoryName - This attribute will hold the Category Name.
 * @param {string} subCategory - This attribute will hold the Sub Category Name.
 * @param {string} headerName - This attribute will have the Capability Report Test Name eg: (Solar - Data Capability Test).
 * @param {map} evaluationValueMap - This attribute will have the mpa of evaluation values based on the Group 1 and Group 2.
*/
export default class CapabilityReportController extends LightningElement {
    @track colHeader = [];
    @track columnValues = [];
    @track totalResultLstArray = [];
    @api plantAssetId;
    @api categoryName;
    @api subCategory;
    @track headerName;
    pageRef = 'Asset Builder';
    evaluationValueMap = new Map();
    promptIdToPreviousPlantAssetDetailMap = new Map();
    promptToPromptIdMap = new Map();
    connectedCallback() {
        getEvaluationValues({
            plantAssetId: this.plantAssetId,
            categoryName: this.categoryName,
            subCategory: this.subCategory,
        }).then(result => {
            if (result === '') {
            } else {
                var inputData = result;
                let evaluation = JSON.parse(inputData);
                let evaluationrecords = evaluation.evaluationValue;
                this.promptIdToPreviousPlantAssetDetailMap = evaluation.promptIdToPreviousPlantAssetDetail;
                this.promptToPromptIdMap = evaluation.promptToPromptId;
                let evaluationValeRecordCount = 0;
                // evaluationValeRecordCount - This will have the total number of records based on the Category Name and Sub Category Name.

                for (var evaluationValueRecordKey in evaluationrecords) {
                    let evalValueRecordInstance = [];
                    evaluationValeRecordCount += 1;
                    let evalValueRecord = evaluationrecords[evaluationValueRecordKey];
                    let group1Name = evalValueRecord.Evaluation__r.Group_1__c;
                    let group2Name = evalValueRecord.Evaluation__r.Group_2__c === undefined ? '' : evalValueRecord.Evaluation__r.Group_2__c;
                    let groupName = '';
                    if (group2Name !== '') {
                        groupName = group1Name + ' - ' + group2Name;
                    } else {
                        groupName = group1Name;
                    }
                    if (!this.evaluationValueMap.has(groupName)) {
                        this.evaluationValueMap.set(groupName, evalValueRecordInstance);
                    }
                    this.evaluationValueMap.get(groupName).push({
                        evalValueRecord
                    });
                }
                let testName = evaluationrecords[0].Evaluation__r.Sub_Category__c + ' - ' +
                    evaluationrecords[0].Evaluation__r.Category__c +
                    ' Tests';
                this.headerName = testName;
                this.colHeader.push(testName);
                this.colHeader.push('TestId'); // Static column Headers for the Cpabailty Report Test.
                this.colHeader.push('Result'); // Static column Headers for the Cpabailty Report Test.
                this.colHeader.push('Notes'); // Static column Headers for the Cpabailty Report Test.
                this.evaluationValueMap.forEach((values, keys) => {// Keys - This will have the Group 1 and Group 2 Concatenation Value.
                    let columnValuesArray = []; // columnValuesArray - This object will have the Column Values and ClassName used in HTML for CSS.

                    let colClassName = 'groupingWhiteBackground'; // colClassName - This parameter is used for the CSS
                    let colClassForResult = ''
                    var result = this.fetchEvaluationTotalValueResult(keys);
                    if (result === 'Pass') {
                        colClassForResult = 'groupingGreenBackground';
                    } else {
                        colClassForResult = 'groupingRedBackground';
                    }
                    columnValuesArray.push({
                        colValues: keys,
                        colClassName: 'colHeader'
                    });
                    columnValuesArray.push({
                        colValues: '',
                        colClassName: colClassName
                    });
                    columnValuesArray.push({
                        colValues: result,
                        colClassName: colClassForResult
                    });
                    columnValuesArray.push({
                        colValues: '',
                        colClassName: colClassName
                    });

                    this.columnValues.push(columnValuesArray);
                    this.formColumnValues(keys);
                })
                var totalResult = this.totalResultLstArray.length + '/' + evaluationValeRecordCount;
                let totalResultArray = []; // totalResultArray - This object will have the Column Values and ClassName used in HTML for CSS.

                let colClassName = 'whiteBackground';
                let colClassForResult = ''
                if (this.totalResultLstArray.length === evaluationValeRecordCount) {
                    colClassForResult = 'groupingGreenBackground';
                } else {
                    colClassForResult = 'groupingRedBackground';
                }
                totalResultArray.push({
                    colValues: 'Total',
                    colClassName: 'colFooter'
                });
                totalResultArray.push({
                    colValues: '',
                    colClassName: 'colFooter'
                });
                totalResultArray.push({
                    colValues: totalResult,
                    colClassName: colClassForResult
                });
                totalResultArray.push({
                    colValues: '',
                    colClassName: colClassName
                });

                this.columnValues.push(totalResultArray);
            }
        })
    }

    /**
     * This method is used to Get the total Evaluation Result for a Category and Sub Category.
     * @param {string} keys - This will have the Group 1 and Group 2 Concatenation Value.
     */
    fetchEvaluationTotalValueResult(keys) {
        if (keys) {
            let resultLst = [];
            let lstSize = 0;
            if (this.evaluationValueMap.has(keys)) {
                var evaluationValueRecords = this.evaluationValueMap.get(keys);
                lstSize = evaluationValueRecords.length;
                for (var evalutionValueRecordKey in evaluationValueRecords) {
                    let evalValueRecord = evaluationValueRecords[evalutionValueRecordKey];
                    var result = evalValueRecord.evalValueRecord.Result__c === undefined ? '' : evalValueRecord.evalValueRecord.Result__c;
                    if (result === 'Pass') {
                        resultLst.push('Pass');
                    }
                }
            }
            if (lstSize === resultLst.length) {
                return 'Pass';
            } else {
                var result = resultLst.length + '/' + lstSize;
                return result;
            }
        }
    }

    /**
     * This Method is to form Column Values the Test Report based on the Group 1 and Group 2 Concatenation Value.
     * @param {String} keys - This will have the Group 1 and Group 2 Concatenation Value.
     */
    formColumnValues(keys) {
        if (keys) {
            if (this.evaluationValueMap.has(keys)) {
                var evaluationValueRecords = this.evaluationValueMap.get(keys);
                for (var evalutionValueRecordKey in evaluationValueRecords) {
                    let evalValueRecord = evaluationValueRecords[evalutionValueRecordKey];
                    var aliasName = evalValueRecord.evalValueRecord.Evaluation__r.Alias__c === undefined ? '' : evalValueRecord.evalValueRecord.Evaluation__r.Alias__c;
                    var name = evalValueRecord.evalValueRecord.Test_Id__c === undefined ? '' : evalValueRecord.evalValueRecord.Test_Id__c;
                    var result = evalValueRecord.evalValueRecord.Result__c === undefined ? '' : evalValueRecord.evalValueRecord.Result__c;
                    var notes = evalValueRecord.evalValueRecord.Evaluation__r.Evaluation_Notes__c === undefined ? '' : evalValueRecord.evalValueRecord.Evaluation__r.Evaluation_Notes__c;
                    var promptId = evalValueRecord.evalValueRecord.Evaluation__r.Prompt_Information__r.Id === undefined ? '' : evalValueRecord.evalValueRecord.Evaluation__r.Prompt_Information__r.Id;
                    let colClassName = 'whiteBackground';
                    let colClassForResult = ''
                    if (result === 'Pass') {
                        this.totalResultLstArray.push('Pass');
                        colClassForResult = 'greenBackground';
                    } else {
                        colClassForResult = 'redBackground';
                    }
                    let columnValuesArray = []; // columnValuesArray - This object will have the Column Values and ClassName used in HTML for CSS.
                    columnValuesArray.push({
                        isHyperLink: true,
                        promptId: promptId,
                        colValues: aliasName,
                        colClassName: 'whiteBackgroundColumnGroupValues'
                    });
                    columnValuesArray.push({
                        isHyperLink: false,
                        colValues: name,
                        colClassName: colClassName
                    });
                    columnValuesArray.push({
                        isHyperLink: false,
                        colValues: result,
                        colClassName: colClassForResult
                    });
                    columnValuesArray.push({
                        isHyperLink: false,
                        colValues: notes,
                        colClassName: colClassName
                    });
                    this.columnValues.push(columnValuesArray);
                }
            }
        }
    }

    /**
     * this method is called  onClick of AliasName and it will navigate to the respective prompt page.
     * @param {*} event 
     */
    handlePromptNavigator(event) {
        let prompId = event.target.dataset.promptid;
        let promptIdEvtDetails = {
            promptId: this.promptToPromptIdMap[prompId],
            plantAssetIdEvt: this.plantAssetId,
            previousPapdIdEvt: this.promptIdToPreviousPlantAssetDetailMap[prompId]
        }

        /**
         * This varibale "pageRefCustom" is to replace "this.pageRef" variable, as we could not access the @api, @track, @wire variables in
         * renderedCallback()
         */
        let pageRefCustom = 'Asset Builder';
        fireEvent(pageRefCustom, 'showPrompt', promptIdEvtDetails);
    }
}