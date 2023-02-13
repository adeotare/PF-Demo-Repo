import { LightningElement,wire,track,api} from 'lwc';
import {refreshApex} from '@salesforce/apex';  
import getAllPlants from '@salesforce/apex/PlantProductController.fetchPlantProductList';  
import addPlantProductList from '@salesforce/apex/PlantProductController.addPlantProductList';  
import getAllAccountPlants from '@salesforce/apex/PlantProductController.fetchAccountPlant';  
import deletePlantProduct from '@salesforce/apex/PlantProductController.deletePlantProduct';  
import updateQuoteLineItem from '@salesforce/apex/PlantProductController.updateQuantityOnQuoteLineItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
const COLS = [
    {label:'Name',fieldName:'PlantName', type:'text', sortable: true},  
    {label:'Country',fieldName:'PlantCountry', type:'text', sortable: true, cellAttributes: { alignment: 'center'}},
    {label:'Asset Class',fieldName:'AssetClass', type:'text', sortable: true, cellAttributes: { alignment: 'center'}},
    {label:'MWh',fieldName:'PlantMWH', type:'text', sortable: true, cellAttributes: { alignment: 'center' }},
    {label:'MWp',fieldName:'PlantMWP', type:'text', sortable: true,  cellAttributes: { alignment: 'center' }},
];
const AccountPlantCOLS=[  
    {label:'Name',fieldName:'PlantName',sortable: true, type:'text'},
    {label:'Country',fieldName:'PlantCountry', type:'text',sortable: true, cellAttributes: { alignment: 'center' }},
    {label:'Asset Class',fieldName:'AssetClass', type:'text',sortable: true, cellAttributes: { alignment: 'center' }},
    {label:'MWh',fieldName:'PlantMWH', type:'text',sortable: true, cellAttributes: { alignment: 'center' }},
    {label:'MWp',fieldName:'PlantMWP', type:'text',sortable: true, cellAttributes: { alignment: 'center' }},    
   ];
export default class PW_PlantProductDataTable extends LightningElement {  
    @track accountplantList;
    @track plantListdata;
    @api recordId;
    @track quoteLineId;
    @track result;
    @track deleteButtontrue=true;
    @track saveButtontrue=true;
	  @track accountplantListdata;
    @track sortBy;
    @track sortDirection;
    @track plantData;
    cols=COLS; 
    acccols = AccountPlantCOLS;
	@track data = [];
		handleSuccess(e) {
        console.log('id::'+this.recordId);
        this.quoteLineId = this.recordId;      
    }    @wire(getAllPlants,{qLineItemId:'$recordId'})
	plantList(result){
    this.plantListdata = result;
		if(result.data){
      this.data = result.data.map((row) => ({
                  ...row,
                  AccountName : row.Account__r.Name,
                  PlantName : row.Plant__r.Plant__r.Name,
				  PlantMWH :  row.Plant__r.Plant_MWH__c,
				  PlantMWP : row.Plant__r.Plant_MWP__c,
				  PlantCountry : row.Plant__r.Plant_Country__c,
                  AssetClass : row.Plant__r.Asset_Class__c
                
                }));
    this.plantData = this.data;        
		}else if(result.error) {
            window.console.log(result.error);
        }
	}
    @track isModalOpen = false;
    @track isModalOpenForManagePlant = true;
    @wire(getAllAccountPlants,{qLineItemId:'$recordId'})
    fetchaccountplantList(result){
		this.accountplantListdata=result;
      if(result.data){
        this.accountplantList = result.data.map((row) => ({
          ...row,
          AccountName : row.Account__r.Name,
          PlantName : row.Plant__r.Name,
		  PlantCountry : row.Plant__r.Country__c,
		  PlantMWP : row.Plant__r.MWp__c,
		  PlantMWH : row.Plant__r.MW_Energy_Capacity_MWh__c,
		  AssetClass : row.Plant__r.Asset_Class__c,  
      }));					
      }			
          return refreshApex(this.plantListdata);
    }
    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortBy = event.detail.fieldName;
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
      }
      sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
        this.plantData = this.data;
      }
      doAccountSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortBy = event.detail.fieldName;
        this.sortAccData(event.detail.fieldName, event.detail.sortDirection);
      }
      sortAccData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.accountplantList));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.accountplantList = parseData;
      }
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
        this.isModalOpenForManagePlant = false;
				
				return refreshApex(this.accountplantListdata);
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
        this.isModalOpenForManagePlant = true;
				
				return refreshApex(this.accountplantListdata);
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
    closeQuickAction() {
        updateQuoteLineItem({quoteLineId: this.recordId}).then(result =>{
         
        }).catch(error => {

        });
        
        this.dispatchEvent(new CloseActionScreenEvent());
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
						 return refreshApex(this.plantListdata);

        })  
        .catch(error=>{  
          alert('Cloud not able to add'+JSON.stringify(error));  
        });  
        this.isModalOpen = false;
        this.isModalOpenForManagePlant = true;
    }
    handleSelectPlantProduct(event){
        const selRows = event.detail.selectedRows;
        console.log( 'Selected Rows are 2@ ' + JSON.stringify(selRows));
        //console.log( 'selRows.length: ' + selRows.length);
        if(selRows.length>0){
          this.deleteButtontrue = false;
              //	return refreshApex(this.fetchaccountplantList);
        }else{
          this.deleteButtontrue = true;
        }
         
      }
      handleSelectAccountPlant(event){
        const selRows = event.detail.selectedRows;
        console.log( 'Selected Rows are1  ' + JSON.stringify(selRows));
        //console.log( 'selRows.length: ' + selRows.length);
        if(selRows.length>0){
          this.saveButtontrue = false;
                  return refreshApex(this.plantListdata);
        }else{
          this.saveButtontrue = true;
        }
        
      }
      handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();
        this.plantData = this.data;
        if (searchKey) {
            
            if (this.plantData) {
                let searchRecords = [];
 
                for (let record of this.plantData) {
                    let valuesArray = Object.values(record);
 
                    for (let val of valuesArray) {
                        console.log('val is ' + val);
                        let strVal = String(val);
 
                        if (strVal) {
 
                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
 
                console.log('Matched Accounts are ' + JSON.stringify(searchRecords));
                this.plantData = searchRecords;
            }
        } else {
            this.plantData = this.data;
        }
    }
    
}