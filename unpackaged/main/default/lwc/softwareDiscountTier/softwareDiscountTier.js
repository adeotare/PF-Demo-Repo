import { LightningElement, track, api, wire } from 'lwc';

import getAccount from '@salesforce/apex/SoftwareDiscountTier.fetchAccountName';
import getCurrency from '@salesforce/apex/SoftwareDiscountTier.fetchCurrency';
import getSoftwareDiscountDetails from '@salesforce/apex/SoftwareDiscountTier.fetchSoftwareListPriceData';
import { CloseActionScreenEvent } from 'lightning/actions';

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
  @track accountListdata;
  @track currencyListdata;
  @api recordId;
  @track softwareDiscountPriceData;
  @track softwareDiscountPriceListdata;

  @wire(getAccount, { RecId: '$recordId' })
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

  @wire(getSoftwareDiscountDetails, { RecId: '$recordId' })
  softwareDiscountPriceRecord(result) {
    this.softwareDiscountPriceData = result;
    if (result.data) {
      this.softwareDiscountPriceListdata = result.data.map((row) => ({
        ...row,
        Account : row.Account__r.Name,
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


  @track isModalOpen = false;

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


  @track softwareId;
    handleSuccess(event) {
        this.softwareId = event.detail.id;
    }



}