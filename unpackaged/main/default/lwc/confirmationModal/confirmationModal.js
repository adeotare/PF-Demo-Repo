import { LightningElement,api } from 'lwc';

export default class ConfirmationModal extends LightningElement {

  @api title;
  @api popUpMessage;
  @api promptName;
 
  handleOk(event) {
    const selectedEvent = new CustomEvent("confirm", {
      detail: {
        confirmationOutput: true,
      }
    });
    this.dispatchEvent(selectedEvent);
  }

  handleCancel(event) {
    const selectedEvent = new CustomEvent("confirm", {
      detail: {
        confirmationOutput: false,
      }
    });
    this.dispatchEvent(selectedEvent);
  }
}