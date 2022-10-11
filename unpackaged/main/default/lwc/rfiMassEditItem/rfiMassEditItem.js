import { LightningElement, api, track, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import saveRFIItems from "@salesforce/apex/RFIMassEditItemsController.saveRFIItems";

const ACCEPTEDFILEFORMATS = [".jpg", ".jpeg", ".pdf", ".zip", ".xlsx", ".png", ".csv", ".txt", ".docx", ".jfif"];
const REQUESTOR_OPTIONS = ["Requested", "In Progress", "Canceled", "Cannot Complete"];
const REQUESTEE_OPTIONS = ["Requested", "In Progress"];
const SUBMITTED_OPTIONS = ["Submitted", "Needs Detail", "Closed", "Canceled", "Cannot Complete"];
const SUBMITTER_STATUSES = ["Requested", "In Progress", "Needs Detail"];
const REQUESTOR_STATUSES = ["Submitted"];
const COMPLETED_STATUSES = ["Closed", "Canceled", "Cannot Complete"];

export default class RfiMassEditItem extends NavigationMixin(LightningElement) {
  @api item;
  @api permissions;

  fieldControl = [];
  @track files = [];

  showComments = false;
  showSave = false;

  itemStatus;
  url;
  instructionUrl;

  acceptedFormats = ACCEPTEDFILEFORMATS;

  @api
  getItemRecord() {
    // Gets field values set by the user from inputs
    let item = { Id: this.item.Id };
    if (this.permissions.data.Customer_Comments__c.Edit && this.template.querySelector(".customer_comments")) {
      item.Customer_Comments__c = this.template.querySelector(".customer_comments").value;
    }
    if (this.permissions.data.Customer_Comments__c.Edit && this.template.querySelector(".completed")) {
      item.Completed__c = this.template.querySelector(".completed").checked;
    }
    if (this.permissions.data.RFI_Item_Status__c.Edit) {
      item.RFI_Item_Status__c = this.itemStatus;
    }
    if (this.permissions.data.Due_Date__c.Edit && this.template.querySelector(".due_date")) {
      item.Due_Date__c = this.template.querySelector(".due_date").value;
    }
    if (
      this.permissions.data.Cancel_Cannot_Complete_Description__c.Edit &&
      this.template.querySelector(".cancel_cannot_complete")
    ) {
      item.Cancel_Cannot_Complete_Description__c = this.template.querySelector(".cancel_cannot_complete").value;
    }
    return item;
  }

  get statusOptions() {
    // Controls what options are available to the user, business logic
    let options = [];
    if (this.item && this.permissions && this.permissions.data.RFI_Item_Status__c.Edit) {
      if (!this.item.Is_Requestor__c) {
        options = [...REQUESTEE_OPTIONS];
      } else if (this.item.Is_Requestor__c && this.item.RFI_Item_Status__c == "Submitted") {
        options = [...SUBMITTED_OPTIONS];
      } else if (this.item.Is_Requestor__c) {
        options = [...REQUESTOR_OPTIONS];
      }
      // Add in needs details when it goes back to the submitter
      if (this.item.RFI_Item_Status__c == "Needs Detail" && options.includes("Requested")) {
        options[options.indexOf("Requested")] = "Needs Detail";
      }
      // Force add an option if not in one the above lists
      if (!options.includes(this.itemStatus)) {
        options.unshift(this.itemStatus);
      }
    }
    if (options === []) return;
    // Return options in value/label paid
    return options.map((i) => {
      return { value: i, label: i };
    });
  }

  get isToDo() {
    // Current user should do this, shows the clock icon
    if (this.item.Is_Requestor__c) return REQUESTOR_STATUSES.includes(this.itemStatus);
    return SUBMITTER_STATUSES.includes(this.itemStatus);
  }

  get isComplete() {
    // Shows complete check
    return (
      COMPLETED_STATUSES.includes(this.itemStatus) ||
      (!this.item.Is_Requestor__c && REQUESTOR_STATUSES.includes(this.itemStatus))
    );
  }

  get isBlocker() {
    // Shows warning icon
    return this.isToDo && this.item.Implementation_Blocked__c;
  }

  get isComment() {
    return !this.isFile && !this.isCheckbox;
  }

  get isFile() {
    return this.item.RFI_Category__r && this.item.RFI_Category__r.Request_Type__c == "Document";
  }

  get isCheckbox() {
    return this.item.RFI_Category__r && this.item.RFI_Category__r.Request_Type__c == "Checkbox";
  }

  get isCancel() {
    return this.itemStatus == "Canceled" || this.itemStatus == "Cannot Complete";
  }
  showCancel = false;

  @api
  saveComplete() {
    this.setFieldControl();
    this.showSave = false;
  }

  connectedCallback() {
    // Set Helper Variables
    let comments = this.item.Customer_Comments__c;
    this.itemStatus = this.item.RFI_Item_Status__c;
    this.showComments = !!comments || this.isComment;
    // Load files not readonly collection
    if (this.item.ContentDocumentLinks) {
      let files = this.item.ContentDocumentLinks.map((f) => Object.assign({}, f));
      this.files = files;
    }
    this.setFieldControl();

    // Generate link for A tag and navigation use later
    this.itemPageRef = {
      type: "standard__recordPage",
      attributes: {
        recordId: this.item.Id,
        objectApiName: "RFI_Detail__c",
        actionName: "view"
      }
    };
    this[NavigationMixin.GenerateUrl](this.itemPageRef).then((url) => (this.url = url));

    // Generate Instruction Url for Later
    if (this.item.RFI_Category__r && this.item.RFI_Category__r.Knowledge_Article_Name__c) {
      this[NavigationMixin.GenerateUrl]({
        type: "standard__knowledgeArticlePage",
        attributes: {
          articleType: "Knowledge",
          urlName: this.item.RFI_Category__r.Knowledge_Article_Name__c
        }
      }).then((url) => (this.instructionUrl = url));
    }
  }

  setFieldControl() {
    // Sets the array to control is a field is visible or not based on permissions and current status/conditions
    let completed = COMPLETED_STATUSES.includes(this.itemStatus);
    let control = [];
    let requestor = this.item.Is_Requestor__c;

    control.RFI_Item_Status__c =
      !completed &&
      (requestor || SUBMITTER_STATUSES.includes(this.itemStatus)) &&
      (!this.permissions.data.RFI_Item_Status__c || this.permissions.data.RFI_Item_Status__c.Edit);
    control.Due_Date__c =
      !completed && requestor && (!this.permissions.data.Due_Date__c || this.permissions.data.Due_Date__c.Edit);
    control.Customer_Comments__c =
      !completed &&
      !requestor &&
      (!this.permissions.data.Customer_Comments__c || this.permissions.data.Customer_Comments__c.Edit);
    control.Cancel_Cannot_Complete_Description__c =
      requestor &&
      (this.permissions.data.Cancel_Cannot_Complete_Description__c ||
        this.permissions.data.Cancel_Cannot_Complete_Description__c.Edit);
    this.fieldControl = control;
  }

  unsaved() {
    // Prompt save and fire event to parent
    this.showSave = true;
    this.dispatchEvent(new CustomEvent("itemedit", { detail: this.item.Id }));
  }

  clickNavigateItem(event) {
    // Nvaigate to item detail page
    event.preventDefault();
    event.stopPropagation();
    this[NavigationMixin.Navigate](this.itemPageRef);
  }

  clickNavigateInstructions(event) {
    // Navigate to instructions
    event.preventDefault();
    event.stopPropagation();
    window.open(this.instructionUrl);
  }

  clickNavigateFile(event) {
    // Show files
    let file = this.files[[...event.target.parentElement.children].indexOf(event.target)];

    let recordIds = this.files.map((f) => f.ContentDocumentId).join(",");
    let selectedRecordId = file.ContentDocumentId;

    this.filePreview = {
      type: "standard__namedPage",
      attributes: {
        pageName: "filePreview"
      },
      state: {
        recordIds: recordIds,
        selectedRecordId: selectedRecordId
      }
    };

    // Get the Url of the file preview
    this[NavigationMixin.GenerateUrl](this.filePreview).then((url) => {
      if (url) {
        this[NavigationMixin.Navigate](this.filePreview);
      } else {
        // If No URL, we must be in community, force download instead -> file preview not available in communities yet, should work if it ever is available
        let community = window.location.href.substr(0, window.location.href.indexOf("/s/"));
        window.open(community + "/sfc/servlet.shepherd/document/download/" + this.filePreview.state.selectedRecordId) +
          "?operationContext=S1";
      }
    });
  }

  handleClickSave() {
    // Save item
    let item = Object.assign({}, this.item, this.getItemRecord());

    saveRFIItems({ lstRFIDetails: [item] })
      .then((data) => {
        this.showSave = false;
        this.dispatchEvent(new CustomEvent("itemsave"));
      })
      .catch((error) => {
        console.error(error);
        this.dispatchEvent(new CustomEvent("itemerror", { detail: error.body.message }));
      });
  }

  handleUploadFinished(event) {
    // When uploading file, callback function
    this.itemStatus = "Submitted";
    // add files to list so it shows right away
    event.detail.files.forEach((f) => {
      this.files.push({ ContentDocumentId: f.documentId, ContentDocument: { Title: f.name } });
    });
    this.handleClickSave();
  }

  handleToggleComplete(event) {
    this.itemStatus = event.target.checked ? "Submitted" : "In Progress";
    this.unsaved();
  }

  handleChangeComment(event) {
    let comments = event.target.value;
    if (this.isComment) this.itemStatus = !!comments ? "Submitted" : "In Progress";
    this.unsaved();
  }

  handleClickAddComment(event) {
    this.showComments = true;
  }

  changeItemStatus(event) {
    this.itemStatus = event.target.value;
    this.unsaved();
  }
}