import { LightningElement, track, api, wire } from "lwc";
import getLookupSearchRecords from "@salesforce/apex/LookupWithDynamicFieldFilterCont.getLookupSearchRecords";
import { assignValueToGlobalAttrOfComps } from 'c/utilsImpWiz'; //- commented to remove, entering the plant asset id not exist in Salesforce

export default class LookupWithDynamicFieldFilter extends LightningElement {
    // Tracked properties
    records;
    noRecordsFlag = false;
    showoptions = true;
    searchString = "";
    // searchStringToPass = ""; - commented to remove, entering the plant asset id not exist in Salesforce
    @api selectedsobject;
    @api recordlimit;
    @api selectedName = "";
    @api isdisabled;
    @api recordId;
    @api placeHolderText;
    @api isShowSelectedRecord;
    @api fieldsToReturn;
    @api filterFieldApiName;
    resetName = "reset name";

    //This method accepts the Search String, SObject, Search Field
    @wire(getLookupSearchRecords, {
        searchString: "$searchString",
        selectedSObject: "$selectedsobject",
        recordLimit: "$recordlimit",
        fieldsToShowList: "$fieldsToReturn",
        filterFieldAPIName: "$filterFieldApiName"
    })
    wiredRecords({ error, data }) {
        this.noRecordsFlag = 0;

        if (data) {
            this.records = data;
            this.error = undefined;
            //this.searchStringToPass = this.searchString; - commented to remove, entering the plant asset id not exist in Salesforce
            this.noRecordsFlag = this.records.length === 0 ? true : false;
            this.showoptions = this.records.length === 0 ? false : true;
        } else if (error) {
            this.error = error;
            this.records = undefined;
        }
    }

    connectedCallback(){
        this.resetName = this.selectedName;
    }
    // handle event called lookupselect
    handlelookupselect(event) {
        this.showoptions = false;
        this.searchString = "";
        this.selectedName =  event.currentTarget.dataset.id;
        this.resetName = this.selectedName;
        this.template.querySelector("form").reset();
    }

    // key change on the text field
    handleKeyChange(event) {
        //this.resetName = event.target.value; - commented to remove, entering the plant asset id not exist in Salesforce
        //this.searchStringToPass = event.target.value; - commented to remove, entering the plant asset id not exist in Salesforce
        this.searchString = event.target.value;
        this.selectedName =  event.target.value;
        this.showoptions = this.searchString.length == 0 ? false : true;
        assignValueToGlobalAttrOfComps(this.searchString); //- commented to remove, entering the plant asset id not exist in Salesforce 
    }

    handleOnBlur(){
        this.selectedName = "";
        const passPlantAssetRemoveBoolean = new CustomEvent('plantassetonblur', {
            detail: true
        });
        this.dispatchEvent(passPlantAssetRemoveBoolean);
        //assignValueToGlobalAttrOfComps(this.searchString); //- commented to remove, entering the plant asset id not exist in Salesforce 

        //this.searchStringToPass = this.resetName; - commented to remove, entering the plant asset id not exist in Salesforce
    }
}