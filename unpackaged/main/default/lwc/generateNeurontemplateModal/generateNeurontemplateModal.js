/**
 * 
 */

 import { LightningElement, api } from 'lwc';

export default class GenerateNeurontemplateModal extends LightningElement {
    @api isShowGenerateNeuronModal = false;
    @api fileURL;
    @api popUpMessage;

    closeModal() {
        this.isShowGenerateNeuronModal = false;
    }
}