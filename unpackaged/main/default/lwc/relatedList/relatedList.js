import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

/* TODO 

show + in count if more than number of records are available

*/

const DELAY = 300;

export default class RelatedList extends NavigationMixin(LightningElement) {
  @api listName;
  @api listIcon;
  @api columns;
  @api recordId;
  @api componentName;
  @api isFullPage = false;
  searchLoading = false;
  sortBy;
  sortDirection;
  viewAllUrl;
  _records;

  @api
  get records() {
    return this._records;
  }
  set records(v) {
    this.searchLoading = false;
    this._records = v;
  }

  get count() {
    if (!this._records) return 0;
    return this._records.length;
  }

  get countLabel() {
    return this.listName + " (" + this.count + ")";
  }

  connectedCallback() {
    // Build View All Link
    this[NavigationMixin.GenerateUrl]({
      type: "standard__component",
      attributes: {
        componentName: "c__RelatedListFull"
      },
      state: {
        c__id: this.recordId,
        c__listName: this.componentName
      }
    }).then((url) => (this.viewAllUrl = url));
  }

  handleSort(event) {
    // Sort Coumns
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortRecords();
  }

  handleSearchKeyChange(event) {
    // Search/Filter input
    window.clearTimeout(this.delayTimeout);
    const searchKey = event.target.value;
    this.searchLoading = true;
    this.delayTimeout = setTimeout(() => {
      this.dispatchEvent(new CustomEvent("search", { detail: searchKey }));
    }, DELAY);
  }

  handleClickRefresh() {
    this.dispatchEvent(new CustomEvent("refresh"));
  }

  sortRecords() {
    // Sort Data Records
    let records = JSON.parse(JSON.stringify(this._records));
    let reverse = this.sortDirection === "asc" ? 1 : -1;
    let sortField = this.sortBy;
    // Change URL fields to Name fields for sorting
    if (sortField.endsWith("Url"))
      sortField = sortField.substring(0, sortField.length - 3) + "Name";
    let getField = function (f) {
      // Extract field from the data
      let v = f[sortField];
      if (v === undefined) v = "";
      if (typeof v === "string") v = v.toLowerCase();
      return v;
    };
    if (sortField) {
      // Sort Records based on sort field value
      records.sort((a, b) => {
        let A = getField(a),
          B = getField(b);
        return (A < B ? -1 : A > B ? 1 : 0) * reverse;
      });
    }
    this._records = records;
  }
}