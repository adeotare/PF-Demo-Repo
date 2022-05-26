import { LightningElement, track, api } from 'lwc';
import { showToast, convertDateToCurrentUserTimeZone } from 'c/utils';
import getG1PlantAssetPromptDetail from "@salesforce/apex/Utils.getG1PlantAssetPromptDetail";
export default class AssetBuilderReportDetails extends LightningElement {
    @api plantAssetId;
    @track reportExecutedByUser;
    @track reportExecutedByDatetime;
    @track temVersion;

    connectedCallback() {
        getG1PlantAssetPromptDetail({ plantAssetId: this.plantAssetId }).then(result => {
            if (result != null) {
                this.reportExecutedByUser = result.Report_Execution_By_User__r.Name;
                this.temVersion = result.Account_Plant__r.TEM_Version__r.Name;
                this.reportExecutedByDatetime = convertDateToCurrentUserTimeZone(result.Report_Generated_Datetime__c);
            }
        }).catch(error => {
            showToast(this, error.body.message, 'Error', 'error');
        });
    }
}