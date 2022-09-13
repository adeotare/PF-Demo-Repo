import { LightningElement, api, track, wire } from "lwc";
import { refreshApex } from '@salesforce/apex';
import RelatedListElement from 'c/relatedListElement';
import getPlantProductTransactionsByAccount from "@salesforce/apex/RelatedListsController.getPlantProductTransactionsByAccount";

const COLUMNS = [
  {
    label: "Record",
    fieldName: "recordUrl",
    type: "url",
    sortable: true,
    typeAttributes: {
      label: {
        fieldName: "recordName"
      }
    }
  },
  {
    label: "Plant",
    fieldName: "plantUrl",
    type: "url",
    sortable: true,
    typeAttributes: {
      label: {
        fieldName: "plantName"
      }
    }
  },
  {
    label: "Product",
    fieldName: "productUrl",
    type: "url",
    sortable: true,
    typeAttributes: {
      label: {
        fieldName: "productName"
      }
    }
  },
  {
    label: "Contract",
    fieldName: "contractUrl",
    type: "url",
    sortable: true,
    typeAttributes: {
      label: {
        fieldName: "contractName"
      }
    }
  },
  {
    label: "End Date",
    fieldName: "End_Date__c",
    type: "date-local",
    sortable: true,
    typeAttributes: {
      month: "2-digit",
      day: "2-digit",
      year: "2-digit"
    }
  }
];

export default class RelatedListAccountPlantTransactions extends RelatedListElement {

  @api recordId;
  @track search = '';
  columns = COLUMNS;

  @wire(getPlantProductTransactionsByAccount, { accountId: "$recordId", recordCount: "$numOfRecords", search: "$search" })
  wiredPlantProductTransactions(value) {
    this.wiredRecords = value;
    if (value.data) {
      let records = [];
      value.data.forEach((record) => {
        let r = { ...record };
        this.addNavigationFields(r, 'record', 'View', r.Id);
        this.addNavigationFields(r, 'plant', r.Plant_Name__c, r.Plant__c);
        this.addNavigationFields(r, 'product', r.Product__r.Name, r.Product__c);
        this.addNavigationFields(r, 'contract', r.Contract__r.ContractNumber, r.Contract__c);
        records.push(r);
      });
      this.records = records;
    }
  }

  handleRefresh(event) {
    refreshApex(this.wiredRecords);
  }

  handleSearch(event) {
    this.search = event.detail;
  }
}