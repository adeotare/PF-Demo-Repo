import { LightningElement, api} from 'lwc';
import nextPromptFinder from "@salesforce/apex/Utils.nextPromptFinder";
export default class FinishButtonHelper extends LightningElement {

  @api promptName;
  @api plantAssetId;

  connectedCallback() {
    nextPromptFinder({
        currentPromptName: this.promptName,
        plantAssetId: this.plantAssetId
      }).then(result => {
        if (result) {
          this.dispatchEvent(
            new CustomEvent("finishbuttonfinderresponse", {
              detail: {
               result: result,
              }
            })
          );
        }
      })
      .catch(error => {
        this.error = error;
      });
  }
}