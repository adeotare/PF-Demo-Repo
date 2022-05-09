import { LightningElement,wire,track,api } from 'lwc';  
import {refreshApex} from '@salesforce/apex';  
import getAllPlants from '@salesforce/apex/PlantProductController.fetchPlantProductList';  
import addPlantProductList from '@salesforce/apex/PlantProductController.addPlantProductList';  
import getAllAccountPlants from '@salesforce/apex/PlantProductController.fetchAccountPlant';  
import deletePlantProduct from '@salesforce/apex/PlantProductController.deletePlantProduct';  
import updateQuoteLineItem from '@salesforce/apex/PlantProductController.updateQuantityOnQuoteLineItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

const COLS=[  
    // {label:'Name',fieldName:'Name', type:'text'}, 
    {label:'Name',fieldName:'PlantName', type:'text'},  
    {label:'Country',fieldName:'PlantCountry', type:'text', cellAttributes: { alignment: 'center' }},
    {label:'Renewable Type',fieldName:'PlantRenewableType', type:'text', cellAttributes: { alignment: 'center' }},
  /*   {label:'Account',fieldName:'AccountName', type:'text'},  
    {label:'Account Plant',fieldName:'AccountPlantName', type:'text'},
	{label:'Plant',fieldName:'PlantName', type:'text'}, */
	{label:'MWh',fieldName:'PlantMWH', type:'text', cellAttributes: { alignment: 'center' }},
	{label:'MWp',fieldName:'PlantMWP', type:'text', cellAttributes: { alignment: 'center' }},
	{label:'# of Turbines',fieldName:'NumberofTurbines', type:'text', cellAttributes: { alignment: 'center' }}
	
	
  ];

const AccountPlantCOLS=[  
   // {label:'Name',fieldName:'Name', type:'text'},
   {label:'Name',fieldName:'PlantName', type:'text'},
   /*  {label:'Account',fieldName:'AccountName', type:'text'},  
    {label:'Plant',fieldName:'PlantName', type:'text'}, */
	{label:'Country',fieldName:'PlantCountry', type:'text', cellAttributes: { alignment: 'center' }},
  {label:'Renewable',fieldName:'PlantRenewableType', type:'text', cellAttributes: { alignment: 'center' }},
  {label:'MWh',fieldName:'PlantMWH', type:'text', cellAttributes: { alignment: 'center' }},
	{label:'MWp',fieldName:'PlantMWP', type:'text', cellAttributes: { alignment: 'center' }},
	{label:'# of Turbines',fieldName:'NumberofTurbines', type:'text', cellAttributes: { alignment: 'center' }},
/* 	{label:'Plant Asset Class',fieldName:'PlantAssetClass', type:'text'} */
	
  ];

export default class PlatProductDataTable extends LightningElement {
    @track accountplantList;
    @track plantListdata;
    @api recordId;
    @track quoteLineId;
    @track result;
    @track deleteButtontrue=true;
    @track saveButtontrue=true;
    cols=COLS; 
    acccols = AccountPlantCOLS;
	@track data = [];
    handleSuccess(e) {
        console.log('id::'+this.recordId);
        this.quoteLineId = this.recordId;       
    }
    //@wire(getAllPlants,{qLineItemId:'$recordId'}) plantList;
	@wire(getAllPlants,{qLineItemId:'$recordId'})
	plantList(result){
    this.plantListdata = result;
		if(result.data){
			/* let currentData = [];
			result.data.forEach((row) => {
				let rowData = {};
        if(row.Id){
					
					rowData.Id = row.Id;
				}
				if(row.Name){
					console.log('row.Name::',row.Name);
					rowData.Name = row.Name;
				}
				if (row.Account__c) {
					rowData.Account__c = row.Account__r.Name;
				}
				if (row.Plant__c) {
					rowData.Plant__c = row.Plant__r.Name;
				}
				currentData.push(rowData);
			}); */
      this.data = result.data.map((row) => ({
                  ...row,
                  AccountName : row.Account__r.Name,
                  // AccountPlantName : row.Plant__r.Name,
				  // PlantName : row.Plant__r.Plant_Name__c,
          PlantName : row.Plant__r.Plant__r.Name,
				  PlantMWH :  row.Plant__r.Plant_MWH__c,
				  PlantMWP : row.Plant__r.Plant_MWP__c,
				  PlantCountry : row.Plant__r.Plant_Country__c,
				  PlantNoOfDevices : row.Plant__r.Number_of_Turbines__c,
				  PlantRenewableType : row.Plant__r.Renewable_Type__c
                
                }));
			//this.data = currentData;
		}else if(result.error) {
            window.console.log(result.error);
        }
	}
   
    @track isModalOpen = false;
    
    //@wire(getAllAccountPlants) accountplantList;
    @wire(getAllAccountPlants,{qLineItemId:'$recordId'})
    fetchaccountplantList(result){
      if(result.data){
        this.accountplantList = result.data.map((row) => ({
          ...row,
          AccountName : row.Account__r.Name,
          PlantName : row.Plant__r.Name,
		  PlantCountry : row.Plant__r.Country__c,
		  PlantMWP : row.Plant__r.MWp__c,
		  PlantMWH : row.Plant__r.MW_Energy_Capacity_MWh__c,
		  PlantDevices : row.Plant__r.Number_of_Turbines__c,
		  PlantAssetClass : row.Plant__r.Asset_Class__c,
      PlantRenewableType : row.Renewable_Type__c    
      }));
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
    submitDetails() {
        var selectedRecords =  
         this.template.querySelector('[data-id="overview"]').getSelectedRows();  
         console.log('selectedRecords::',selectedRecords);
         console.log('this.recordId::'+this.recordId);
         var that = this;
         addPlantProductList({plantList: selectedRecords, quoteLineId:this.recordId})  
        .then(result=>{  
          //return refreshApex(this.plantList);  
          this.result = result;
          console.log('result::',this.result);
          const evt = new ShowToastEvent({
              title: 'Success!',
              message: 'Successfully Updated',
              variant: 'success',
              mode: 'dismissable'
          });
          this.dispatchEvent(evt);
          return refreshApex(that.plantListdata);

        })  
        .catch(error=>{  
          alert('Cloud not able to add'+JSON.stringify(error));  
        });  
        this.isModalOpen = false;
    }

    deleteRecord(){  
      var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();  
      console.log('selectedRecords for delete::',selectedRecords);
      deletePlantProduct({pptList: selectedRecords, quoteLineId:this.recordId})  
      .then(result=>{  
        const evt = new ShowToastEvent({
            title: 'Success!',
            message: 'Successfully Deleted',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
        return refreshApex(this.plantListdata);  
      })  
      .catch(error=>{  
        alert('Could not delete'+JSON.stringify(error));  
      })  
    }

    handleSelectPlantProduct(event){
      const selRows = event.detail.selectedRows;
      console.log( 'Selected Rows are ' + JSON.stringify(selRows));
      //console.log( 'selRows.length: ' + selRows.length);
      if(selRows.length>0){
        this.deleteButtontrue = false;
      }else{
        this.deleteButtontrue = true;
      }
      
    }

    handleSelectAccountPlant(event){
      const selRows = event.detail.selectedRows;
      console.log( 'Selected Rows are ' + JSON.stringify(selRows));
      //console.log( 'selRows.length: ' + selRows.length);
      if(selRows.length>0){
        this.saveButtontrue = false;
      }else{
        this.saveButtontrue = true;
      }
      
    }
    /*addRecord(){  
        var selectedRecords =  
         this.template.querySelector("lightning-datatable").getSelectedRows();  
         console.log('selectedRecords::',selectedRecords);
         addPlantProductList({plantList: selectedRecords})  
        .then(result=>{  
          return refreshApex(this.plantList);  
        })  
        .catch(error=>{  
          alert('Cloud not able to add'+JSON.stringify(error));  
        })  
      }   */

      closeQuickAction() {
        updateQuoteLineItem({quoteLineId: this.recordId}).then(result =>{

        }).catch(error => {

        });
        
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}