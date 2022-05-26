import { LightningElement,api,track } from 'lwc';
import { fireEvent } from 'c/pubsub';
import { showToast } from 'c/utils';
import AB_AP_SubmittedForApprovalMessage from '@salesforce/label/c.AB_AP_SubmittedForApprovalMessage';////Custom Label for submitted request message
import AB_AP_ApprovedMessage from '@salesforce/label/c.AB_AP_ApprovedMessage';//Custom Label for Approved request message
import AB_AP_RejectedMessage from '@salesforce/label/c.AB_AP_RejectedMessage';//Custom Label for Rejected request message
import AB_AP_NoCommentsMessage from '@salesforce/label/c.AB_AP_NoCommentsMessage';//Custom Label for No comments message for validating comments in rejectRecord()
import AB_AP_RecalledMessage from '@salesforce/label/c.AB_AP_RecalledMessage';//Custom Label for recalled request message
import processStep from  "@salesforce/apex/AssetBuilderApprovalHandler.processStep";//approvalAction  Method
import submitForApproval from  "@salesforce/apex/AssetBuilderApprovalHandlerUtils.SubmitForApproval";//submitForApproval  Method
import ABApprovalProcessAPIName from '@salesforce/label/c.ABApprovalProcessAPIName';//Custom Label for Approval process name

export default class ApprovalProcessCommentsPopUp extends LightningElement {
  @api selectedPlantAssetId = '';
  @api selectedPlantAssetAbaId = '';
  @track comments = '';
  @api showApproveBtn = false;
  @api showRejectBtn = false;
  @api showSubmitBtn = false;
  @api showRecallBtn = false;
  @api title =''; 
  @api isLoading=false; // Show and Hide Spinner 

  inputChangeHandler(event){
      this.comments = event.detail.value;
  }

  /**
   * This Method is used to submit approval request 
   */
  handleSubmit(){
    if(this.selectedPlantAssetId !== undefined){
      this.isLoading=true;
      fireEvent(this.pageRef, 'showspinnercomp', true);
      submitForApproval({
        plantAssetId : this.selectedPlantAssetAbaId,
        comments : this.comments,
        approvalProcessName : ABApprovalProcessAPIName,
        setSkipEntryCriteria : false
      }).then(result =>{
        fireEvent(this.pageRef, 'showspinnercomp', false);
        if(result === 'Submitted'){
          this.showSubmitBtn = false;
          this.isLoading=false;
          showToast(this,AB_AP_SubmittedForApprovalMessage, 'Success', 'Success'); 
        }
        const selectedEvent = new CustomEvent("confirm", {
          detail: {
            submitRecall : 'Submit'
          }
        });
        this.dispatchEvent(selectedEvent);
      })
      .catch(error => {
        this.isLoading=false;
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this, error.body.message, 'Error', 'error');          
      });
    }
  }

  /**
   * This Method is used to Approve approval request 
   */
  handleApprove(){
    if(this.selectedPlantAssetId !== undefined){
      this.isLoading=true;
      fireEvent(this.pageRef, 'showspinnercomp', true);
      processStep({
        plantAssetId : this.selectedPlantAssetAbaId,
        comments : this.comments,
        setAction : 'Approve'
      }).then(response =>{
        this.showApproveReject = false;
        this.isLoading = false;
        let resultantValue = response.split("&");
        showToast(this, resultantValue[0], resultantValue[1], resultantValue[1].toLowerCase());
        const selectedEvent = new CustomEvent("confirm", {
          detail: {
            confirmationOutput: false,
            showApproveReject: true
          }
        });
        this.dispatchEvent(selectedEvent);
      })
      .catch(error => {
        this.isLoading=false;
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this, error.body.message, 'Error', 'error');          
      });
    }
  }

  /**
   * This Method is used to Reject approval request 
   */
  handleReject(){
    if(this.selectedPlantAssetId !== undefined){
      fireEvent(this.pageRef, 'showspinnercomp', true);
      if(this.comments === ''){
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this,AB_AP_NoCommentsMessage, 'Error', 'Error'); 
      }
      else{
        this.isLoading=true;
        processStep({
          plantAssetId : this.selectedPlantAssetAbaId,
          comments : this.comments,
          setAction : 'Reject'
        }).then(result =>{
          this.isLoading=false;
          fireEvent(this.pageRef, 'showspinnercomp', false);
          if(result === 'Reject'){
            this.showRejectBtn = false;
            this. showApproveReject = false;
            showToast(this,AB_AP_RejectedMessage, 'Info', 'Info'); 
          }
          const selectedEvent = new CustomEvent("confirm", {
            detail: {
              confirmationOutput: false,
              showApproveReject : true
            }
          });
          this.dispatchEvent(selectedEvent);
        })
        .catch(error => {
          this.isLoading=false;
          fireEvent(this.pageRef, 'showspinnercomp', false);
          showToast(this, error.body.message, 'Error', 'error');          
        });
      }
    }
  }

  /**
   * This Method is used to Recall approval request 
   */
  handleRecall(){
    if(this.selectedPlantAssetId !== undefined){
      this.isLoading=true;
      fireEvent(this.pageRef, 'showspinnercomp', true);
      processStep({
        plantAssetId : this.selectedPlantAssetAbaId,
        comments : this.comments,
        setAction : 'Removed'
      }).then(result =>{
        this.isLoading=false;
        fireEvent(this.pageRef, 'showspinnercomp', false);
        if(result === 'Removed'){
          this.showRecallBtn = false;
          this.showSubmitBtn = true;
          this. showApproveReject = false;
          showToast(this,AB_AP_RecalledMessage, 'Info', 'Info'); 
        }
        const selectedEvent = new CustomEvent("confirm", {
          detail: {
            showApproveReject: true,
            submitRecall: 'Recall'
          }
        });
        this.dispatchEvent(selectedEvent);
      })
      .catch(error => {
        this.isLoading=false;
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this, error.body.message, 'Error', 'error');          
      });
    }
  }

  handleCancel(event) {
    const selectedEvent = new CustomEvent("confirm", {
      detail: {
        confirmationOutput: false,
        submitRecall: 'Cancel'
      }
    });
    this.dispatchEvent(selectedEvent);
  }
}