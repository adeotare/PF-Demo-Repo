import { LightningElement, track, api, wire } from 'lwc';

import getAccount from '@salesforce/apex/ImplementationBracketPrice.fetchAccountName';
import getCurrency from '@salesforce/apex/ImplementationBracketPrice.fetchCurrency';
import getAllRecords from '@salesforce/apex/ImplementationBracketPrice.implementationBracketPriceRecords';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class MsaImplementationBracket extends LightningElement {

data = [];

cols = [
  { label: 'Name', fieldName: 'Name', type: 'text' },
  { label: 'Pricing Tier', fieldName: 'PricingTier', type: 'text', cellAttributes: { alignment: 'center' } },
  { label: 'Lower Bound', fieldName: 'LowerBound', type: 'text', cellAttributes: { alignment: 'center' } },
  { label: 'Upper Bound', fieldName: 'UpperBound', type: 'text', cellAttributes: { alignment: 'center' } },
  { label: 'Fixed Price', fieldName: 'FixedPrice', type: 'text' , cellAttributes: { alignment: 'center' }},
  { label: 'Asset Class', fieldName: 'AssetClass', type: 'text' , cellAttributes: { alignment: 'center' }},
  { label: 'Description', fieldName: 'Description', type: 'text' , cellAttributes: { alignment: 'center' }}
];

  @track accountName;
  @track currency;
  @track accountListdata;
  @track currencyListdata;
  @track implementationPriceData;
  @track implementationPriceListdata;
  @api recordId;

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

  @wire(getAllRecords, { RecId: '$recordId' })
  implementationPriceRecord(result) {
    this.implementationPriceData = result;
    if (result.data) {
      this.implementationPriceListdata = result.data.map((row) => ({
        ...row,
        Name: row.Name,
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

  closeQuickAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

}