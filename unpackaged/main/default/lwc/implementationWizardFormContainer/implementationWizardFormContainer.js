import { LightningElement, api } from 'lwc';

export default class ImplementationWizardFormContainer extends LightningElement {
    @api isLoading = false;
    @api spinnerLoadingMessage = '';
    
    loadSpinner(event){
        this.isLoading = event.detail.showOrHideSpinner;
        this.spinnerLoadingMessage = event.detail.spinnerLoadingMessage;
    }
}