import { LightningElement, api, track } from 'lwc';
import updatePlantAssetPromptDetail from "@salesforce/apex/Utils2.updatePlantAssetPromptDetail";
import plantAssetPromptDetailUpdateMsg from '@salesforce/label/c.plantAssetPromptDetailUpdateMsg';
import plantAssetPromptDetailUpdateTitle from '@salesforce/label/c.plantAssetPromptDetailUpdateTitle';
import { fireEvent } from 'c/pubsub';

export default class BulkImportGotoG1PromptButton extends LightningElement{
  @api plantAssetId;
  @track showConfirmationPopup = false;
  pageRef = 'Asset Builder';
  label = {
    plantAssetPromptDetailUpdateMsg,
    plantAssetPromptDetailUpdateTitle,
  };

  gotoG1Prompt(event){
    this.showConfirmationPopup = true;
  }
  
  goToG1OnConfirm(event){
    if(event.detail.confirmationOutput){
      this.showConfirmationPopup = false;
      updatePlantAssetPromptDetail({
      plantAssetId: this.plantAssetId
      }).then(result => {
        if (result) {
            let eventDet = {
            plantAssetId: this.plantAssetId,
            promptId: 'prompt1'
          }
          fireEvent(this.pageRef, 'redirectToG1Prompt', eventDet);
        }
      })
      .catch(error => {
        this.error = error;
      });
    } else{
      this.showConfirmationPopup = false;
    }
  }
}