import { LightningElement,api,track, wire } from 'lwc';
import { fireEvent } from 'c/pubsub';
import { showToast } from 'c/utils';
import setSubmitForApproval from  "@salesforce/apex/AssetBuilderApprovalHandler.setSubmitForApproval";
import hasApproveRejectPermission from '@salesforce/customPermission/AB_ApproveRejectBtnCustomPermission';//Custom permission for Approve/reject button display
import getApprovalHistory from  "@salesforce/apex/AssetBuilderApprovalHandler.getApprovalHistory";
import { refreshApex } from "@salesforce/apex";

const columns = [
    {
      label: "Step Name",
      fieldName: "stepUrl",
      type: "url",
      typeAttributes: {
        label: {
          fieldName: "stepName"
        }
      }
    },
    {
      label: "Date",
      fieldName: "createdDate",
      type: "date",
      typeAttributes: {
        month: "numeric",
        day: "numeric",
        year: "numeric",
        hour: "numeric",
        minute: "numeric"
      }
    },
    { label: "Status", fieldName: "stepStatus" },
    {
      label: "Assigned To",
      fieldName: "assignedToUrl",
      type: "url",
      typeAttributes: {
        label: {
          fieldName: "assignedTo"
        }
      }
    },
    {label: "Comments", fieldName: "comments" }
  ];

export default class PlantAssetRelatedApprovalContainer extends LightningElement {
  pageRef = 'Asset Builder';
  @api selectedPlantAssetId ='';
  @track showApproveBtn = false;//To Show approve button 
  @track showRejectBtn = false;//To Show Reject button 
  @track showApproveReject = false;
  @track isApprovalSubmitted = false;
  @track columns = columns;
  @track approvalHistory; //approval history to display on page
  @track approvalHistoryNew; //approval history to display on page

  wiredApprovalHistory; //property used to refreshApex
  @api title = '';//Title for comments box popup
  selectedPlantAssetIdABAId;
  plantName;
  showChatterButton = false;
  activeSections = ['A'];

  get showDataTable() {
    return this.approvalHistory
      ? true
      : false;
  }

  get showDataTableNew() {
    return this.approvalHistoryNew
      ? true
      : false;
  }

  @wire(getApprovalHistory, { recordId: "$selectedPlantAssetId" })
    wiredGetApprovalHist(value) {
    this.wiredApprovalHistory = value;
    if (value.data) {
      this.approvalHistory = value.data;
    } 
  }

  @wire(getApprovalHistory, { recordId: "$selectedPlantAssetIdABAId" })
    wiredGetApprovalHistNew(value) {
    this.wiredApprovalHistoryNew = value;
    if (value.data) {
      this.approvalHistoryNew = value.data;
    } 
  }

  refreshApprovalHistory() {
    refreshApex(this.wiredApprovalHistory);
  }

  openChatter(){
    let details = {
      plantName : this.plantName,
      selectedPlantAssetIdABAId : this.selectedPlantAssetIdABAId
    }
    fireEvent(this.pageRef ,'passAssetBuilderApprovalRecId', details);
  }

  connectedCallback(){
    this.refreshApprovalHistory();
    if(this.selectedPlantAssetId !== undefined){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      this.showApproveReject = true; //Hide approve and reject button 
      //Check the approval status and Asset builder status to show/hide approve/reject button
      setSubmitForApproval({
        plantAssetId : this.selectedPlantAssetId
      })
      .then(resultVar => {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        let result = JSON.parse(resultVar);
        if(result.status === 'Submitted' || result.status === 'CustomerSubmitted' || result.status === 'IESubmitted'){
          if(hasApproveRejectPermission){
            this.showApproveReject = false;
          }
          else {
            this.showApproveReject = true;
          }
        }

        if(result.abaRec){
          this.selectedPlantAssetIdABAId = result.abaRec.Id;
          this.plantName = result.plantName;
          this.showChatterButton = true;
        }
      })
      .catch(error => {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this,error.body.message, 'Error', 'error');          
      });   
    }
  }

  handleApprove(){
    if(this.selectedPlantAssetId !== undefined){
      this.showRejectBtn = false;
      this.showApproveBtn = true;
      this.showApproveReject = false;
      this.isApprovalSubmitted = true;
      this.title = 'Approve';
    } 
  }

  handleReject(){
    if(this.selectedPlantAssetId != undefined){
      this.showApproveBtn = false;
      this.showRejectBtn = true;
      this.showApproveReject = false;
      this.isApprovalSubmitted= true;
      this.title = 'Reject';
    }
  }
  
  //On confirm, Hide approve/reject button
  handleApproval(event){
    if(!event.detail.confirmationOutput){    
      this.isApprovalSubmitted = false;
    }
    if(event.detail.showApproveReject){
      this.showApproveReject = true;
      this.refreshApprovalHistory();
    }
  } 
}