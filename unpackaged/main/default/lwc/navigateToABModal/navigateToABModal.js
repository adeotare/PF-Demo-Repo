/**
 * Created by karthikeyan.k on 5/13/2021.
 */

 import { LightningElement, api } from 'lwc';

 export default class NavigateToAbModal extends LightningElement {
    @api title;
    @api popUpMessage;
    @api isNoABData;
    @api isShowNavigateModal = false;
    @api plantAssetId;

    closeModal() {
        this.isShowNavigateModal = false;
        this.navigateToABEvent(true, true, true, this.plantAssetId, 'close');
    }

    handleOverride(){
        this.navigateToABEvent(true, true, true, this.plantAssetId, 'override');
    }

    handleNoOverride(){
        this.navigateToABEvent(true, true, false, this.plantAssetId, 'no');
    }

    handleNew() {
        this.navigateToABEvent(true, true, true, this.plantAssetId, 'new');
    }

    navigateToABEvent(isShowAB, isImpWizUpLoad, isOverride, plantAssetId, action){
        console.log(this.plantAssetId);
        this.dispatchEvent(
            new CustomEvent("navigateab", {
                detail: {
                    isShowAB: isShowAB,
                    isImpWizUpLoad: isImpWizUpLoad,
                    isOverride: isOverride,
                    plantAssetId: plantAssetId,
                    action: action
                }
            })
        );
    }
 }