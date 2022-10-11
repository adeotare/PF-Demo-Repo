import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRFIItems from "@salesforce/apex/RFIMassEditItemsController.getRFIItems";
import saveRFIItems from "@salesforce/apex/RFIMassEditItemsController.saveRFIItems";
import getPermissions from "@salesforce/apex/RFIMassEditItemsController.getPermission";
import { CurrentPageReference } from "lightning/navigation";

export default class RfiMassEditItems extends LightningElement {
  @api recordId;
  showSave = false;

  @wire(CurrentPageReference)
  wiredPageRef() {
    refreshApex(this.items);
  }

  @wire(getRFIItems, { artId: "$recordId" })
  items;

  @wire(getPermissions, { recordId: "$recordId" })
  permissions;

  get showTable() {
    return this.items.data && this.permissions.data;
  }

  get saveButtonVariant() {
    return this.showSave ? "brand" : "neutral";
  }

  handleItemEdit(event) {
    this.showSave = true;
  }

  handleClickSave(event) {
    // Map RFI Items for save
    let rfiItems = [...this.template.querySelectorAll("c-rfi-mass-edit-item")].map((i, n) =>
      Object.assign({}, this.items.data[n], i.getItemRecord())
    );

    saveRFIItems({ lstRFIDetails: rfiItems })
      .then((data) => {
        this.showSave = false;
        [...this.template.querySelectorAll("c-rfi-mass-edit-item")].forEach((i) => i.saveComplete());
        this.showToast("Saved", "All RFI Items Saved Successfully.", "success");
      })
      .catch((error) => {
        this.showToast("Error", error.body.message, "error");
      });
  }

  handleItemSave(event) {
    this.showToast("Saved", "RFI Item Saved", "success");
  }

  handleItemError(event) {
    this.showToast("Error", event.detail, "error");
  }

  handleClickCancel(event) {
    refreshApex(this.items);
    this.showSave = false;
    [...this.template.querySelectorAll("c-rfi-mass-edit-item")].forEach((i) => i.saveComplete());
  }

  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }
}