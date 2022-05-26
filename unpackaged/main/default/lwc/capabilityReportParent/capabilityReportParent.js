import { LightningElement, track, api } from 'lwc';
import getallEvaluation from '@salesforce/apex/CapabilityReportController.getallEvaluation';
import {
    showToast
  } from "c/utils";

/**
 * This component is used to get the Unique name of Category and Sub Category Name for the Dynamic Report Table Generation.
 * @param {map} evaluationMap - This attribute will have a map of Category and Sub Category Name.
 * @param {string} plantAssetId - This attribute will hold current Plant Asset Id. 
 */
export default class CapabilityReportParent extends LightningElement {
    @track evaluationMap = [];
    @api plantAssetId;
    connectedCallback() {
        getallEvaluation({
        }).then(result => {
            if(result === ''){
                showToast(this, 'There is no Evaluation Value', 'Error', 'error');
            }else{
                var inputData = result;
                let evaluationRecords = JSON.parse(inputData);
                let evaluation = evaluationRecords.evaluation;

                for(var key in evaluation){
                    this.evaluationMap.push({value:evaluation[key], key:key});
                }
            }
        })
    }
}