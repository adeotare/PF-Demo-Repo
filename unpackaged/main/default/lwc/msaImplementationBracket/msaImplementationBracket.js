import { LightningElement, track, api, wire } from 'lwc';

import getAccount from '@salesforce/apex/ImplementationBracketPrice.fetchAccountName';
import getCurrency from '@salesforce/apex/ImplementationBracketPrice.fetchCurrency';
import getAllRecords from '@salesforce/apex/ImplementationBracketPrice.implementationBracketPriceRecords';
import deleteImplementationPriceRecord from '@salesforce/apex/ImplementationBracketPrice.deleteImplementationPriceRecord';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MsaImplementationBracket extends LightningElement {

  data = [];

  cols = [
    { label: 'Name', fieldName: 'Name', type: 'text' },
    { label: 'Product', fieldName: 'Product', type: 'text' },
    { label: 'Pricing Tier', fieldName: 'PricingTier', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Lower Bound', fieldName: 'LowerBound', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Upper Bound', fieldName: 'UpperBound', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Fixed Price', fieldName: 'FixedPrice', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Asset Class', fieldName: 'AssetClass', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Description', fieldName: 'Description', type: 'text', cellAttributes: { alignment: 'center' } }
  ];

  @track accountName;
  @track accountId;
  @track msaId;
  @track currency;
  @track accountListdata;
  @track currencyListdata;
  @track implementationPriceData;
  @track implementationPriceListdata;
  @api recordId;
  @track isModalOpen = false;
  @track implementationId;
  @track deleteButtontrue = true;


  @wire(getAccount, { RecId: '$recordId' })
  accountList(result) {
    this.accountListdata = result;
    if (result.data) {
      this.accountName = result.data[0].Account_Name__r.Name;
      this.accountId = result.data[0].Account_Name__c;
      this.msaId = result.data[0].Id;

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

  @wire(getAllRecords, { RecId: '$recordId' })
  implementationPriceRecord(result) {
    this.implementationPriceData = result;
    if (result.data) {

      this.implementationPriceListdata = result.data.map((row) => ({
        ...row,
        Name: row.Name,
        Product: row.Product__r.Name,
        PricingTier: row.Pricing_Tier__c,
        LowerBound: row.Lower_Bound__c,
        UpperBound: row.Upper_Bound__c,
        FixedPrice: row.Fixed_Price__c,
        AssetClass: row.Asset_Class__c,
        Description: row.Description__c
      }));
    } else if (result.error) {
      console.log(result.error);
    }
  }

  openModal() {
    // to open modal set isModalOpen tarck value as true
    this.isModalOpen = true;
  }
  closeModal() {
    // to close modal set isModalOpen tarck value as false
    this.isModalOpen = false;
  }

  closeQuickAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  handleSuccess(event) {

    try {
      this.implementationId = event.detail.id;
      //console.log('onsuccess: ', softwareId);
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Software Discount Tier Added',
          variant: 'success'
        })
      );
      this.isModalOpen = false;
      refreshApex(this.implementationPriceData);
    }
    catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error updating or refreshing records',
          message: error.body.message,
          variant: 'error'
        })
      );
    };

  }

  deleteRecord(){  
    var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();  
    console.log('selectedRecords for delete::',selectedRecords);
    deleteImplementationPriceRecord({implementationPriceList: selectedRecords, msaId:this.recordId})  
    .then(result=>{  
      const evt = new ShowToastEvent({
          title: 'Success!',
          message: 'Successfully Deleted',
          variant: 'success',
          mode: 'dismissable'
      });
      this.dispatchEvent(evt);
      return refreshApex(this.implementationPriceData);  
    })  
    .catch(error=>{  
      alert('Could not delete'+JSON.stringify(error));  
    })  
  }


  handleSelectImplementationPriceRecord(event){
    const selRows = event.detail.selectedRows;
    console.log( 'Selected Rows are ' + JSON.stringify(selRows));
    //console.log( 'selRows.length: ' + selRows.length);
    if(selRows.length>0){
      this.deleteButtontrue = false;
    }else{
      this.deleteButtontrue = true;
    }
    
  }

}