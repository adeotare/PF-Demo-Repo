import { LightningElement, api, track } from 'lwc';

export default class RelatedListElement extends LightningElement {

  @api recordId;
  @api numOfRecords = 20;
  @api isFullPage = false;
  wiredRecords;
  @track records;
  columns;

  connectedCallback() {
    if (this.isFullPage) this.numOfRecords = 10000;
  }

  addNavigationFields(row, fieldName, label, recordId) {
    let urlField = fieldName + 'Url';
    let labelField = fieldName + 'Name';
    if (recordId) {
      row[urlField] = "/" + recordId;
      row[labelField] = label;
    }
  }
}