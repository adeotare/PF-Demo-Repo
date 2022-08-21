import { LightningElement, track, api, wire } from 'lwc';
import getAllAccounts from '@salesforce/apex/AccountForMSAContractedPrices.fetchAccountName';
import getCurrency from '@salesforce/apex/AccountForMSAContractedPrices.fetchCurrency';
import getPriceBook from '@salesforce/apex/AccountForMSAContractedPrices.fetchPriceBook';
import createNewContractPrice from '@salesforce/apex/AccountForMSAContractedPrices.createNewContractPrice';
import getContractedPriceRecords from '@salesforce/apex/AccountForMSAContractedPrices.contractedPricesRecord';
import getPriceBookRecords from '@salesforce/apex/AccountForMSAContractedPrices.priceBookRecords';
import updateContractPrice from '@salesforce/apex/AccountForMSAContractedPrices.updateContractedPrices';
import deleteContractPrice from '@salesforce/apex/AccountForMSAContractedPrices.deleteContractedPrice';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class CreateContractedPrice extends LightningElement {
  cols = [
    { label: 'Product Name', fieldName: 'ProductName', type: 'text' },
    { label: 'Product Code', fieldName: 'ProductCode', type: 'text' },
    { label: 'List Price', fieldName: 'ListPrice', type: 'text', sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'Contract Price', fieldName: 'ContractPrice', type: 'text', cellAttributes: { alignment: 'center' } },
  ];

  colsOfPriceBook = [
    { label: 'Product Name', fieldName: 'ProductName', type: 'text' },
    { label: 'Product Code', fieldName: 'ProductCode', type: 'text' },
    { label: 'List Price', fieldName: 'ListPrice', type: 'text', sortable: true, cellAttributes: { alignment: 'center' } },
    { label: 'Contract Price', fieldName: 'SBQQ__Price__c', type: 'text', editable: true, cellAttributes: { alignment: 'center' } },
  ];

  @track accountName;
  @track currency;
  @track priceBookName;
  @track accountListdata;
  @track currencyListdata;
  @track priceBookListdata;
  @track contractedPriceListdata;
  @track allPriceBookRecordListdata;
  @api recordId;
  @track deleteButtontrue = true;
  @track contractedPriceData;
  @track allPriceBookData;
  @api isLoading = false; // Show and Hide Spinner 


  draftValues = [];

  data = [];

  @wire(getAllAccounts, { RecId: '$recordId' })
  accountList(result) {
    this.accountListdata = result;
    if (result.data) {
      this.accountName = result.data[0].Account_Name__r.Name;

    } else if (result.error) {
      console.log(result.error);
    }
  }

  @wire(getCurrency, { RecId: '$recordId' })
  currencyList(result) {
    this.currencyListdata = result;
    if (result.data) {
      this.currency = result.data[0].CurrencyIsoCode;

    } else if (result.error) {
      console.log(result.error);
    }
  }

  @wire(getPriceBook, { RecId: '$recordId' })
  priceBookList(result) {
    this.priceBookListdata = result;
    if (result.data) {
      this.priceBookName = result.data[0].Account_Name__r.Account_Price_Book__r.Name;

    } else if (result.error) {
      console.log(result.error);
    }
  }



  @wire(createNewContractPrice, { msaRecId: '$recordId' })
  contracted1;
  async refreshClicked(event) {
    this.isLoading = true;
    // Prepare the record IDs for getRecordNotifyChange()
    const notifyChangeIds = this.recordId;

    try {
      // Pass edited fields to the updateContacts Apex controller
      //alert(this.recordId);
      const result = await createNewContractPrice({ msaRecId: this.recordId });
      console.log(JSON.stringify("Apex update result: " + result));
      this.isLoading = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success!',
          message: result,
          variant: 'Success!'
        })
      );

      // Refresh LDS cache and wires
      //      getRecordNotifyChange(notifyChangeIds);
      this.isModalOpen = false;
      // Display fresh data in the datatable
      refreshApex(this.contractedPriceData);
      refreshApex(this.allPriceBookData);

    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error updating or refreshing records',
          message: error.body.message,
          variant: 'error'
        })
      );
    };
  }



  @wire(getContractedPriceRecords, { RecId: '$recordId' })
  contractedPriceRecord(result) {
    this.contractedPriceData = result;
    if (result.data) {
      this.contractedPriceListdata = result.data.map((row) => ({
        ...row,
        ProductName: row.SBQQ__Product__r.Name,
        ProductCode: row.SBQQ__Product__r.ProductCode,
        ListPrice: row.Product_List_Price__c,
        ContractPrice: row.SBQQ__Price__c
      }));
    } else if (result.error) {
      console.log(result.error);
    }
  }

  @wire(getPriceBookRecords, { RecId: '$recordId' })
  allPriceBookRecord(result) {
    this.allPriceBookData = result;
    if (result.data) {
      this.mainAllProducts = result.data.map((row) => ({
        ...row,
        ProductName: row.SBQQ__Product__r.Name,
        ProductCode: row.SBQQ__Product__r.ProductCode,
        ListPrice: row.Product_List_Price__c,
        ContractPrice: row.SBQQ__Price__c
      }));
      this.allPriceBookRecordListdata = result.data.map((row) => ({
        ...row,
        ProductName: row.SBQQ__Product__r.Name,
        ProductCode: row.SBQQ__Product__r.ProductCode,
        ListPrice: row.Product_List_Price__c,
        ContractPrice: row.SBQQ__Price__c
      }));

    } else if (result.error) {
      console.log(result.error);
    }
  }


  handleSelectContractedPrice(event) {
    const selRows = event.detail.selectedRows;
    console.log('Selected Rows are ' + JSON.stringify(selRows));

    if (selRows.length > 0) {
      this.deleteButtontrue = false;
    } else {
      this.deleteButtontrue = true;
    }

  }

  @track isModalOpen = false;

  openModal() {
    // to open modal set isModalOpen tarck value as true
    this.isModalOpen = true;
  }
  closeModal() {
    // to close modal set isModalOpen tarck value as false
    this.isModalOpen = false;
  }

  deleteRecord() {

    var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
    console.log('selectedRecords for delete::', selectedRecords);

    deleteContractPrice({ cpList: selectedRecords, msaId: this.recordId })
      .then(result => {
        const evt = new ShowToastEvent({
          title: 'Success!',
          message: 'Successfully Deleted',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(evt);

        refreshApex(this.contractedPriceData);
        refreshApex(this.allPriceBookData);
      })
      .catch(error => {
        alert('Could not delete' + JSON.stringify(error));
      })
  }



  @wire(updateContractPrice, { RecId: '$recordId' })
  contracted;
  async handleSave(event) {
    var updatedFields = event.detail.draftValues;
    updatedFields.forEach(row => {
      row.Same_As_List_Price__c = false;
    });

    // Prepare the record IDs for getRecordNotifyChange()
    const notifyChangeIds = updatedFields.map(row => { return { "recordId": row.Id } });

    try {
      // Pass edited fields to the updateContacts Apex controller
      const result = await updateContractPrice({ data: updatedFields });
      console.log(JSON.stringify("Apex update result: " + result));
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Contract Prices updated',
          variant: 'success'
        })
      );

      // Refresh LDS cache and wires
      getRecordNotifyChange(notifyChangeIds);
      this.isModalOpen = false;
      // Display fresh data in the datatable
      refreshApex(this.contractedPriceData);
      refreshApex(this.allPriceBookData);

    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error updating or refreshing records',
          message: error.body.message,
          variant: 'error'
        })
      );
    };
  }


  closeQuickAction() {

    this.dispatchEvent(new CloseActionScreenEvent());
  }

  //sort

  @track defaultSortDirection = 'asc';
  @track sortDirection = 'asc';
  @track sortedBy;


  sortBy(field, reverse, primer) {
    const key = primer
      ? function (x) {
        return primer(x[field]);
      }
      : function (x) {
        return x[field];
      };

    return function (a, b) {
      a = key(a);
      b = key(b);
      return reverse * ((a > b) - (b > a));
    };
  }

  onHandleSortContracted(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.contractedPriceListdata];

    cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
    this.contractedPriceListdata = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

  onHandleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.allPriceBookRecordListdata];

    cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
    this.allPriceBookRecordListdata = cloneData;
    this.sortDirection = sortDirection;
    this.sortedBy = sortedBy;
  }

  //Search

  @track mainAllProducts = [];

  searchHandler(event) {

    let searchKey = event.detail.value.toLowerCase();
    let searchedTempProducts = [];


    if (event.detail.value.length > 1) {
      for (const product of this.mainAllProducts) {
        if (product.SBQQ__Product__r.Name.toLowerCase().includes(searchKey))
          searchedTempProducts.push(product);
      }
      this.allPriceBookRecordListdata = searchedTempProducts;
    }

    if (event.detail.value.length == 0) {
      this.allPriceBookRecordListdata = this.mainAllProducts;
    }


  }


}