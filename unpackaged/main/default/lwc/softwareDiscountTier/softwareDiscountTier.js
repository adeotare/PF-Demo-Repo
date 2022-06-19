import { LightningElement, track, api, wire } from 'lwc';

import getAccount from '@salesforce/apex/SoftwareDiscountTier.fetchAccountName';
import getCurrency from '@salesforce/apex/SoftwareDiscountTier.fetchCurrency';
import getSoftwareDiscountDetails from '@salesforce/apex/SoftwareDiscountTier.fetchSoftwareListPriceData';
import deleteSoftwarePriceRecord from '@salesforce/apex/SoftwareDiscountTier.deleteSoftwarePriceRecord';
import { CloseActionScreenEvent } from 'lightning/actions';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SoftwareDiscountTier extends LightningElement {

  cols = [
    { label: 'Product', fieldName: 'Product', type: 'text' },
    { label: 'Pricing Tier', fieldName: 'PricingTier', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Consider Active MW', fieldName: 'ConsiderActiveMW', type: 'boolean', cellAttributes: { alignment: 'center' } },
    { label: 'Lower Bound', fieldName: 'LowerBound', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Upper Bound', fieldName: 'UpperBound', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Discount Amount', fieldName: 'DiscountAmount', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'Start Date', fieldName: 'StartDate', type: 'text', cellAttributes: { alignment: 'center' } },
    { label: 'End Date', fieldName: 'EndDate', type: 'text', cellAttributes: { alignment: 'center' } }

  ];

  data = [];

  @track accountName;
  @track currency;
  @track accountId;
  @track msaId;
  @track accountListdata;
  @track currencyListdata;
  @api recordId;
  @track softwareDiscountPriceData;
  @track softwareDiscountPriceListdata;
  @track softwareId;
  @track isModalOpen = false;
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

  @wire(getSoftwareDiscountDetails, { RecId: '$recordId' })
  softwareDiscountPriceRecord(result) {
    this.softwareDiscountPriceData = result;
    if (result.data) {
      this.softwareDiscountPriceListdata = result.data.map((row) => ({
        ...row,
        Product: row.Product__r.Name,
        PricingTier: row.Pricing_Tier__c,
        ConsiderActiveMW: row.Cross_Orders__c,
        LowerBound: row.Lower_Bound__c,
        UpperBound: row.Upper_Bound__c,
        DiscountAmount: row.Discount_Amount__c,
        StartDate: row.Effective_Start_Date__c,
        EndDate: row.Effective_End_Date__c
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
      this.softwareId = event.detail.id;
      //console.log('onsuccess: ', softwareId);
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Success',
          message: 'Software Discount Tier Added',
          variant: 'success'
        })
      );
      this.isModalOpen = false;
      refreshApex(this.softwareDiscountPriceData);
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
    deleteSoftwarePriceRecord({softPriceList: selectedRecords, msaId:this.recordId})  
    .then(result=>{  
      const evt = new ShowToastEvent({
          title: 'Success!',
          message: 'Successfully Deleted',
          variant: 'success',
          mode: 'dismissable'
      });
      this.dispatchEvent(evt);
      return refreshApex(this.softwareDiscountPriceData);  
    })  
    .catch(error=>{  
      alert('Could not delete'+JSON.stringify(error));  
    })  
  }


  handleSelectSoftwarePriceRecord(event){
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