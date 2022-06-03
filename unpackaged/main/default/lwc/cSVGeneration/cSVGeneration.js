import { LightningElement, api, track} from 'lwc'; 
import getSiteMetadata from '@salesforce/apex/CSVGenerationController.getSiteMetadata';
import fileUpload from '@salesforce/apex/CSVGenerationController.fileUpload';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; 
import { fireEvent } from 'c/pubsub';
import { showToast } from 'c/utils';

/**
 * This component is used to Export all the Site Metadata Records as a CSV File based on the current Plant Asset Id and store those file locally
 *      and also tag those CSV Files into the Plant Asset record. 
 * @param {string} plantAssetId - This attribute will hold the Current Plant Asset Id.
 * @param {array} siteMetadata - This attribute will have the Site Metadata List.
 * @param {map} csvInput - This attribute will have the Site Metadata List and Attribute list.
 * @param {array} attribute - This attribute will have the Attribute list.
 * @param {map} siteMetadataIdToRecordDetails - This attribute will have map of Site Metadata records based on the Record Id.
 * @param {map} baseAssetToAttrMap - This attribute will have map of Base Asset Template with the respective Core Atrributes.
 * @param {map} coreAttributePathGenerationMap -  This map will have the Concate name of Attr Name, Base Asset Name, Prompt Name for the respective Attributes. 
 */
export default class CSVGenerationController extends LightningElement {
    @api plantAssetId;
    @track siteMetadata;
    @track csvInput;
    @track attribute;
    siteMetadataIdToRecordDetails = new Map();
    baseAssetToAttrMap = new Map();
    coreAttributePathGenerationMap = new Map();
    pageRef = 'Asset Builder'; 

    /**
     * This method is to form the CSV file from all the site metadata Records based on the Plant Asset Id and attach those files to those Plant Asset Record.
     * @param {string} plantAssetIdVal - This attribute value will have the input value from the G1 prompt. 
     */
    @api
    downloadCSVFile(plantAssetIdVal) {
        getSiteMetadata({
            plantAssetId: plantAssetIdVal,
        }).then(result => {
            this.csvInput = result;
            if(result === ''){
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'There is no SiteMetadata for this Plant Asset',
                    variant: 'error',
                }));
                fireEvent(this.pageRef, 'showspinnercomp', false);
                this.dispatchEvent(new CustomEvent('close'));
            }else{
                var inputData = JSON.parse(this.csvInput);
                var siteMetadata = inputData.SiteMetadataRecords;
                var attribute = inputData.Attributes;
                
                let rowEnd = '\n';
                let csvString = ''; // csvString - This attribute will be passed as a input to form a CSV File.
                let rowData = new Set(); // rowData - This will have the static Column Headers.
                let attrSet = new Set(); // attrSet - This will have the Dynamic column Headers from Site Metadata Attribute Info Field (Key).

                for (var attrRecordKey in attribute) {
                    let attributeRecordInstance = [];
                    let attributeRecord = attribute[attrRecordKey];
                    let baseAssetId = attributeRecord.Base_Asset_Name__c;
                    if(attributeRecord.Show_Path_in_CSV_Generation__c){
                        let conCatName = attributeRecord.Attribute_Master__r.Name+
                                            attributeRecord.Base_Asset_Name__r.Name+
                                            attributeRecord.Prompt_Information__r.Name;
                        this.coreAttributePathGenerationMap.set(conCatName, attributeRecord.Name);
                    }
                    if(attributeRecord.Default_value__c !== '' && attributeRecord.Default_value__c !== undefined){
                        if(!this.baseAssetToAttrMap.has(baseAssetId)){
                            this.baseAssetToAttrMap.set(baseAssetId, attributeRecordInstance);
                        }
                        this.baseAssetToAttrMap.get(baseAssetId).push({
                            attributeRecord:attributeRecord
                        });
                    }
                }

                for (var siteMetadataRecordKey in siteMetadata) {
                    let siteMetadataRecord = siteMetadata[siteMetadataRecordKey];
                    this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
                }

                let plantId = siteMetadata[0].Account_Plant__r.Customer_Plant_Asset_ID__c;
                let plantName = siteMetadata[0].Account_Plant__r.Customer_Plant_Name__c;
                var today = new Date();
                var date = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
                var time = today.getHours() + ":" + today.getMinutes();
                
                rowData.add('Selected(x)'); // Static column Headers for the CSV File.
                rowData.add('Parent'); // Static column Headers for the CSV File.
                rowData.add('Name'); // Static column Headers for the CSV File.
                rowData.add('ObjectType'); // Static column Headers for the CSV File.
                rowData.add('Description'); // Static column Headers for the CSV File.
                rowData.add('Template'); // Static column Headers for the CSV File.
                siteMetadata.forEach(function(record) {
                    Object.keys(record).forEach(function (key) {
                        if(key === 'Attribute_Info__c'){    
                            if (record.hasOwnProperty(key)) {
                                let attrInfoJSON = record[key];
                                JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
                                    if(attrJSONKey.trim() !== '' && attrJSONKey !== 'Inverter Name' && attrJSONKey !== 'SUBARRAY_BIFACIAL'){
                                        var pipeSym = '|';
                                        attrSet.add(pipeSym.concat(attrJSONKey));
                                    }
                                });
                            }
                        }
                    });
                });
                rowData = Array.from(rowData).concat(Array.from(new Set(attrSet)).sort()); // rowData - This will have the Column Headers for the CSV File.

                csvString += rowData.join(',');
                csvString += rowEnd;
                for(let i=0; i < siteMetadata.length; i++){
                    let colValue = 0;

                    // start
                    // To filter the _Generic Subarray Bifacial records in P7 prompt and change the Baset Asset Template Name to "_Generic Subarray Bifacial" from "_Generic Subarray"
                    let bAtrName = 'Attribute_Info__c';
                    let bAttrValues = siteMetadata[i][bAtrName];
                    let bifacialSubarrayValue = false;
                    let bValue = siteMetadata[i].Base_Asset_Template__r.Name !== '' ? siteMetadata[i].Base_Asset_Template__r.Name : '';

                    if(bValue === '_Generic Subarray'){
                        if(bAttrValues !== undefined){    
                            JSON.parse(bAttrValues, (attrJSONKey, attrJSONValue) => {
                                if(attrJSONKey === 'SUBARRAY_BIFACIAL'){
                                    bifacialSubarrayValue = attrJSONValue;
                                }
                            });
                        }
                    }
                    // end

                    for(let key in rowData) {
                        if(rowData.hasOwnProperty(key)) {
                        let keyname = rowData[key] === 'Parent'?'Parent_Asset_Short_Name__c' : // Replacing the Static Column Headers with the Site Metadata Field Name.
                                        rowData[key] === 'Name'?'Asset_Short_Name__c' : 
                                        rowData[key] === 'ObjectType'?'Name' : 
                                        rowData[key] === 'Description'?'Asset_Name__c' : 
                                        rowData[key] === 'Template'?'Base_Asset_Template__r.Name' : rowData[key];
                            if(keyname === 'Selected(x)' ){
                                if(colValue > 0){
                                    csvString += ',';
                                }
                                let value = '';
                                csvString += '"'+ value +'"';
                                colValue++;
                            }else if(keyname === 'Parent_Asset_Short_Name__c' || keyname === 'Asset_Short_Name__c' || 
                                    keyname === 'Name' || keyname === 'Asset_Name__c'){
                                let rowKey = keyname;
                                if(colValue > 0){
                                    csvString += ',';
                                }
                                // If the column is undefined, it as blank in the CSV file.
                                let value = '';
                                if(rowKey === 'Name'){
                                    value = 'Element';
                                }else{
                                    value = siteMetadata[i][rowKey] === undefined ? '' : siteMetadata[i][rowKey];
                                }
                                csvString += '"'+ value +'"';
                                colValue++;
                            }else if(keyname === 'Base_Asset_Template__r.Name'){
                                let sitemetadatacount = i;
                                if(colValue > 0){
                                    csvString += ',';
                                }
                                let value = siteMetadata[sitemetadatacount].Base_Asset_Template__r.Name !== '' ? siteMetadata[sitemetadatacount].Base_Asset_Template__r.Name : '';

                                csvString += '"'+ ((value === '_Generic Subarray' && bifacialSubarrayValue) ? '_Generic Subarray Bifacial' : value)  +'"';
                                colValue++;
                            }else if(keyname !== 'Parent_Asset_Short_Name__c' && keyname !== 'Asset_Short_Name__c' && keyname !== 'Name' && 
                            keyname !== 'Asset_Name__c' && keyname !== 'Base_Asset_Template__r.Name' && keyname !== 'Selected(x)'){
                                let rowKeyWithSym = rowData[key];
                                let rowKey = rowKeyWithSym.slice(1);
                                let attrName = 'Attribute_Info__c';
                                if(colValue > 0){
                                    csvString += ',';
                                }
                                let attrValues = siteMetadata[i][attrName];
                                if(attrValues !== undefined){    
                                    // eslint-disable-next-line no-loop-func
                                    JSON.parse(attrValues, (attrJSONKey, attrJSONValue) => {
                                        if(attrJSONKey === rowKey){
                                            let value = attrJSONValue;
                                            let sitemetadatacount = i;
                                            
                                            if(attrJSONValue === '' && siteMetadata[i].Base_Asset_Template__c !== ''){
                                                if(siteMetadata[i].Base_Asset_Template__r.Name === '_Generic Subarray'){
                                                    let isBifacialAttr = this.fetchBifacialAttrCheckbox(siteMetadata[i].Base_Asset_Template__c, attrJSONKey);
                                                    if(isBifacialAttr){
                                                        if(bifacialSubarrayValue){
                                                            value = this.fetchDefaultValue(siteMetadata[i].Base_Asset_Template__c, attrJSONKey);
                                                        }
                                                    }else{
                                                        value = this.fetchDefaultValue(siteMetadata[i].Base_Asset_Template__c, attrJSONKey);
                                                    }
                                                }else{
                                                    value = this.fetchDefaultValue(siteMetadata[i].Base_Asset_Template__c, attrJSONKey);
                                                }
                                            }else if(this.salesforceRecorIdCheck(attrJSONValue)){
                                                if(attrJSONValue !== '' && siteMetadata[i].Base_Asset_Template__c !== ''){
                                                    value = this.fetchAttributePath(attrJSONKey,siteMetadata[sitemetadatacount].Base_Asset_Template__r.Name,
                                                        siteMetadata[sitemetadatacount].Prompt_Information__r.Name,
                                                        siteMetadata[sitemetadatacount].Asset_Short_Name__c,
                                                        siteMetadata[sitemetadatacount].Parent_Asset_Short_Name__c,
                                                        attrJSONValue);
                                                }else{
                                                    value = this.fetchAssetName(attrJSONValue);
                                                }
                                            }else{
                                                value = attrJSONValue === undefined ? '' : attrJSONValue;
                                            }
                                            csvString += '"'+ value +'"';
                                            colValue++;
                                        }
                                    });
                                }
                            }
                        }
                    }
                    csvString += rowEnd;
                }
                // CSV File Name
                var fileName = plantId+'_'+plantName+'_'+'Asset_Build'+'_'+date+' '+time+'.csv';
                
                // Method to save the file under the Plant Asset Object.
                fileUpload({
                    csvString: csvString,
                    plantAssetId: plantAssetIdVal,
                    fileName: fileName,
                }).then(result => {
                    if(result){
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Success',
                            message: 'CSV File Downloaded Successfully',
                            variant: 'success',
                        }));
                        this.dispatchEvent(new CustomEvent('close'));
                        let downloadElement = document.createElement('a');

                        // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
                        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvString);
                        downloadElement.target = '_self';
                        // CSV File Name
                        downloadElement.download = fileName;
                        // below statement is required if you are using firefox browser
                        document.body.appendChild(downloadElement);
                        // click() Javascript function to download CSV file
                        downloadElement.click();
                        fireEvent(this.pageRef, 'showspinnercomp', false);
                    }
                }).catch(error => { 
                    showToast(this, error.body.message, 'Error', 'error');   
                    fireEvent(this.pageRef, 'showspinnercomp', false);
                });
            }
        }).catch(error => { 
            showToast(this, error.body.message, 'Error', 'error');   
            fireEvent(this.pageRef, 'showspinnercomp', false);
        });
    }

    /**
     * This method is used to check the Salesforce record Id. 
     * @param {string} siteMetadatRecordId  - This attribute will have the Site Metadata Record Id
     */
    salesforceRecorIdCheck(siteMetadatRecordId) {
        if(siteMetadatRecordId){
            var recordId = siteMetadatRecordId;
            var patt = /^[0-9a-zA-Z]{15}[0-9a-zA-Z]{3}|[0-9a-zA-Z]{15}?$/;
            return patt.test(recordId);
        }
    }

    /**
     * This method is to fetch the asset name field value for a particular Site Metadata Record.
     * @param {string} siteMetadataId - This will ahev th site Metadata Record Id 
     */
    fetchAssetName(siteMetadataId){
        if(siteMetadataId){
            if(this.siteMetadataIdToRecordDetails.has(siteMetadataId)){
                return this.siteMetadataIdToRecordDetails.get(siteMetadataId).Asset_Short_Name__c;
            }
        }
    }

    /**
     * This method is to return the default value for a attribute if there is no value present in the Site Metadata Record.
     * @param {string} baseAssetId - This attribute will have the Base Asset Id.
     * @param {string} AttributeName - This attribute will have the Attribute Master Name.
     */
    fetchDefaultValue(baseAssetId, AttributeName){
        let defaultValue = '';
        if(this.baseAssetToAttrMap.has(baseAssetId)){
            let attrRecord = this.baseAssetToAttrMap.get(baseAssetId);
            // eslint-disable-next-line guard-for-in
            for (let attributeRecordKey in attrRecord) {
                let attributeRecord = attrRecord[attributeRecordKey];
                let attributeMasterName = attributeRecord.attributeRecord.Attribute_Master__r.Name;
                let attrDefaultValue = attributeRecord.attributeRecord.Default_value__c;
                if(attributeMasterName === AttributeName){
                    defaultValue = attrDefaultValue;
                    return defaultValue;
                }
            }
        }
            return defaultValue;    
    }

    /**
     * This method is to return the default value for a attribute if there is no value present in the Site Metadata Record.
     * @param {string} baseAssetId - This attribute will have the Base Asset Id.
     * @param {string} AttributeName - This attribute will have the Attribute Master Name.
     */
    fetchBifacialAttrCheckbox(baseAssetId, AttributeName){
        let defaultValue = false;
        if(this.baseAssetToAttrMap.has(baseAssetId)){
            let attrRecord = this.baseAssetToAttrMap.get(baseAssetId);
            // eslint-disable-next-line guard-for-in
            for (let attributeRecordKey in attrRecord) {
                let attributeRecord = attrRecord[attributeRecordKey];
                let attributeMasterName = attributeRecord.attributeRecord.Attribute_Master__r.Name;
                let attrDefaultValue = attributeRecord.attributeRecord.Is_Related_Subarray_Bifacial__c;
                if(attributeMasterName === AttributeName){
                    defaultValue = attrDefaultValue;
                    return defaultValue;
                }
            }
        }
        return defaultValue;    
    }

    /**
     * This method is used to fetch the Asset Short name and Parent Asset Short Name for a specific Core Attributes.
     * @param {string} AttributeName - This Attribute will have the JSON Key of Core Attributes. 
     * @param {String} baseAssetName - This attribute will have the Base Asset Name. 
     * @param {String} promptName - This Attribute will have the Prompt Information Name.
     * @param {String} assetShortName - This attribute will have the Asset Short Name of Site Metadata.
     * @param {String} parentAssetShortName - This attribute will have the Parent Asset Short Name of Site Matedata.
     */
    fetchAttributePath(AttributeName, baseAssetName, promptName, assetShortName, parentAssetShortName, attrJSONValue){
        let value = '';
        let concatName = AttributeName+baseAssetName+promptName;
        if(this.coreAttributePathGenerationMap.has(concatName)){
            if(this.siteMetadataIdToRecordDetails.has(attrJSONValue)){
                value = this.siteMetadataIdToRecordDetails.get(attrJSONValue).Parent_Asset_Short_Name__c+'\\'+this.siteMetadataIdToRecordDetails.get(attrJSONValue).Asset_Short_Name__c;
            }
        }
        return value;
    }
}