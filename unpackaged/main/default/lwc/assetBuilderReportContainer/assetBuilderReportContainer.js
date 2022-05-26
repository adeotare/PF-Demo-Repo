import { LightningElement, track, api} from 'lwc';
import { showToast } from 'c/utils';
import { registerListener, unregisterAllListeners } from 'c/pubsub';

export default class AssetBuilderReportContainer extends LightningElement {
  pageRef = 'Asset Builder'; 
  @api plantAssetId;
  @track disableRunReportButton = true;
  @track runReportButtonLabel = 'Please wait...';
  eventCount = 0;

  connectedCallback(){
    registerListener('showRunReportButton', this.handleShowRunReportButton, this);
  }

  handleShowRunReportButton(totalCompCnt){
    this.eventCount = this.eventCount + 1;
    if(this.eventCount === totalCompCnt){
      this.disableRunReportButton = false;
      this.runReportButtonLabel = 'Run Report';
    }
  }

  disconnectedCallback(){
    unregisterAllListeners(this);
  }

  runReport(){
    let completenessReportParentComp = this.template.querySelectorAll('c-completeness-report-parent');

    if(completenessReportParentComp.length === 1){
      completenessReportParentComp[0].onClkCompletenessReport();
    }else{
      showToast(this, 'Please wait till the time report gets loaded', 'Info', 'info');
    }
  }
}