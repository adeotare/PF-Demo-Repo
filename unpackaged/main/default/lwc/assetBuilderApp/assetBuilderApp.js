import { LightningElement, api, track, wire } from 'lwc';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';

export default class AssetBuilderApp extends LightningElement {
  pageRef = 'Asset Builder';
  @track selectedPlanAssetIdVal;
  @track showReportContainer = false;
  @api previousPromptName;
  @api plantAssetRecordId;
  @track infoMessage;
  @track showReportStatus = false;
  @track showReportStatusMsg;
  @track showAssetBuilderHierarchy = false;
  @api isImpWizUpLoad = false;
  @api isOverride = false;

  connectedCallback() {
      console.log('asset builder app', this.isOverride);
    registerListener('showReportComponent', this.handleShowReportComponent, this);
    registerListener('showPrompt', this.handleShowPromptComponent, this);
    registerListener('plantAssetIdChg', this.handlePlantAssetIdChg, this);
    registerListener('showHierarchyComponent', this.handleShowHierarchyComponent, this);
    registerListener('g1CompChange', this.handleG1CompChangeForHierarchy, this);
    
    if(!this.showReportContainer){
      this.infoMessage = 'Please select a plant asset from the dropdown and visit again';
    }
  }

  handlePlantAssetIdChg(eventDet){
    this.showReportContainer = eventDet;
  }

  handleShowReportComponent(evtDetail){
    this.selectedPlanAssetIdVal = evtDetail.plantAssetId;

    var activeTab = this.template.querySelector('lightning-tabset');
    activeTab.activeTabValue = 'Reports';
    this.showReportContainer = true;
  }   

  handleShowHierarchyComponent(eventDet){
    this.selectedPlanAssetIdVal = eventDet.plantAssetId;
    var activeTab = this.template.querySelector('lightning-tabset');
    activeTab.activeTabValue = 'Asset Builder Hierarchy';
    this.showAssetBuilderHierarchy = true;
  }
  
  handleG1CompChangeForHierarchy(eventDet){
    this.showAssetBuilderHierarchy = eventDet;
  }
 
  handleShowPromptComponent(eventDet){
    this.showHideAssetBuilder = true;
    var tabSet = this.template.querySelector('lightning-tabset');
    tabSet.activeTabValue = 'Asset Builder';

    var showPrompt = this.template.querySelector('c-prompt-navigator'); 
    showPrompt.showPrompt(eventDet.promptId, eventDet.previousPapdIdEvt, eventDet.plantAssetIdEvt, true);
  }

  disconnectedCallback(){
    unregisterAllListeners(this);
  }
}