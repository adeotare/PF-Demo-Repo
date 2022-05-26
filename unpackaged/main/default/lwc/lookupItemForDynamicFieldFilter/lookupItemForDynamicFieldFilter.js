import { LightningElement, api, track } from "lwc";
export default class LookupItem extends LightningElement {
@api record;
@api searchString;
@api selectedSobject;

// This method handles the selection of lookup value
    handleSelect(event) {
    // Check the parameters passed.
        const selectEvent = new CustomEvent("lookupselect", {
            detail: {
                record : this.record,
                searchString : this.searchString
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(selectEvent);
    }
}