import { LightningElement, api } from 'lwc';
import { registerListener, unregisterAllListeners } from 'c/pubsub';


export default class SpinnerWithMessageContainer extends LightningElement {
    @api isLoadingForDriveMessage = false;
    @api isLoadingForCSVConversion = false;
    pageRef = 'Asset Builder';

    connectedCallback() {
        registerListener('showspinnercompwithmessage', this.handleShowSpinnerPubSub, this);
        registerListener('showspinnercompwithmessageWithDriveconversion', this.handleShowSpinnerPubSubForDriveConversion, this);
    }

    handleShowSpinnerPubSub(action){
        (action) ? this.handleShowSpinner() : this.handleHideSpinner();
    }
    
    handleShowSpinner(){
        this.isLoadingForDriveMessage = false;
        this.isLoadingForCSVConversion = true;
    }
    
    handleHideSpinner(){
        this.isLoadingForDriveMessage = false;
        this.isLoadingForCSVConversion = false;
    }

    handleShowSpinnerPubSubForDriveConversion(action){
        (action) ? this.handleShowSpinnerWithDriveConversion() : this.handleHideSpinnerWithDriveConversion();
    }
    
    handleShowSpinnerWithDriveConversion(){
        this.isLoadingForCSVConversion = false;
        this.isLoadingForDriveMessage = true;
    }
    
    handleHideSpinnerWithDriveConversion(){
        this.isLoadingForCSVConversion = false;
        this.isLoadingForDriveMessage = false;
    }
}