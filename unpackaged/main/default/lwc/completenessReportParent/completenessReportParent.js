import { LightningElement, api, track } from 'lwc';
import getCompletenessReportSection from "@salesforce/apex/CompletenessReportParent.getCompletenessReportSection";

/**
 * @param {string} plantAssetId - This attribute will take the current plant asset id to generated the report for the passed plant asset.
 * @param {string} promptTypeArray - This attribute will take the prompt type (eg, Solar, Wind, Met Mast, Switchgear and Substation) to query only 
 *                              particualr prompt type completness reports
 * @param {boolean} isLoading - To show and hide the lightning spinner.
 * @param {integer} totalChildComponent - This will be calculated based on "promptTypeArray" attribute size.
 *                                           
 */

export default class CompletenessReportParent extends LightningElement {
  @api plantAssetId;
  @track promptTypeArray = [];
  @track isLoading = false;
  @track totalChildComponent = 0;

  connectedCallback(){    
    this.isLoading = true;
    getCompletenessReportSection({})
    .then(result => {
      if(result.length > 0){
        let res = JSON.parse(result);
        for(var promptTyp in res){
          // Add the record to the last index using this ((res.length+1) - 1) to make the ASC sorting order work fine    
          this.promptTypeArray.splice(((res.length+1) - 1),0,{
            key : promptTyp,
            value : res[promptTyp].Prompt_Type__c,
            sectionLabel : res[promptTyp].Section_Label__c,
          })
        }
        this.isLoading = false;
        this.totalChildComponent = (this.promptTypeArray.length + 1);
      }
    })
    .catch(error => {
      this.isLoading = false;
    });
  }

  /**
   * - This @api function will be called from the parent component - assetBuilderReportContainer
   */
  @api
  onClkCompletenessReport(){
    var completenessReportComp = this.template.querySelectorAll('c-completeness-report');
    var completenessReportSummaryComp = this.template.querySelectorAll('c-completeness-report-summary');

    if(completenessReportComp.length > 0 && completenessReportSummaryComp.length === 1){
      completenessReportComp.forEach((item, index) => {
        item.loadReportData(); // Executing the @api function of c-completeness-report component
      });
      completenessReportSummaryComp[0].loadReportData(); // Executing the @api function of c-completeness-report-summary
    }else{
      showToast(this, 'Please wait till the time report gets loaded', 'Info', 'info');
    }
  }
}