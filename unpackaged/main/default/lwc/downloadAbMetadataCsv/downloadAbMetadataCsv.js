import { LightningElement, api, track} from 'lwc'; 
import getSiteMetadata from '@salesforce/apex/DownloadAbMetadataCsv.getSiteMetadata';
import fileUpload from '@salesforce/apex/DownloadAbMetadataCsv.fileUpload';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; 
import { showToast, downloadCSV } from 'c/utils';

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

export default class DownloadAbMetadataCsv extends LightningElement {
    @api plantAssetId;
    @track siteMetadata;
    @track csvInput;
    @track attribute;
    siteMetadataIdToRecordDetails = new Map();
    baseAssetToAttrMap = new Map();
    baseAssetToAttrAPINameToAliasMap = new Map();
    coreAttributePathGenerationMap = new Map();
    pageRef = 'Asset Builder'; 
    totalNoOfRecords = 0;
    noOfRecordProcessed = 0;
    isLoading = false;

    /**
     * This method is to form the CSV file from all the site metadata Records based on the Plant Asset Id and attach those files to those Plant Asset Record.
     * @param {string} plantAssetIdVal - This attribute value will have the input value from the G1 prompt. 
     */
    @api
    downloadAbMetadataCsv(plantAssetIdVal) {
        this.isLoading = true;
        getSiteMetadata({
            plantAssetId: plantAssetIdVal,
        }).then(result => {
            this.csvInput = result;
            if(result === ''){
                showToast(this, 'There is no SiteMetadata for this Plant Asset', 'Error', 'error', 'sticky');                   
            }else{
                var inputData = JSON.parse(this.csvInput);
                var siteMetadata = inputData.SiteMetadataRecords;
                var attribute = inputData.Attributes;
                this.totalNoOfRecords = siteMetadata.length;
                
                let rowEnd = '\n';
                let csvString = ''; // csvString - This attribute will be passed as a input to form a CSV File.
                let rowData = new Set(); // rowData - This will have the static Column Headers.

                let attrSet = new Set(); // attrSet - This will have the Dynamic column Headers from Site Metadata Attribute Info Field (Key).
                let attrNameAliasMap = new Map(); // To map API name and alias of the attribute  

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
                            attributeRecord : attributeRecord
                        });
                    }

                    let attrAPINameToAlias = new Map();

                    if(!this.baseAssetToAttrAPINameToAliasMap.has(baseAssetId)){
                        this.baseAssetToAttrAPINameToAliasMap.set(baseAssetId, attrAPINameToAlias);
                    }

                    this.baseAssetToAttrAPINameToAliasMap.get(baseAssetId).set(attributeRecord.Attribute_Master__r.Name, attributeRecord);
                }

                for (var siteMetadataRecordKey in siteMetadata) {
                    let siteMetadataRecord = siteMetadata[siteMetadataRecordKey];
                    this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
                }

                let plantId = siteMetadata[0].Account_Plant__r.Customer_Plant_Asset_ID__c;
                let plantName = siteMetadata[0].Account_Plant__r.Plant_Name__c;
                var today = new Date();
                var date = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
                var time = today.getHours() + ":" + today.getMinutes();
                
                rowData.add('SFId'); // Static column Headers for the CSV File.
                rowData.add('Parent'); // Static column Headers for the CSV File.
                rowData.add('Name'); // Static column Headers for the CSV File.
                rowData.add('ObjectType'); // Static column Headers for the CSV File.
                rowData.add('Description'); // Static column Headers for the CSV File.
                rowData.add('Template'); // Static column Headers for the CSV File.

                let baseAssetToAttrAPINameToAlias = new Map();   
                baseAssetToAttrAPINameToAlias = this.baseAssetToAttrAPINameToAliasMap;                 

                let columnsNotToDisplay = ['Inverter Name','Pad Name','Subarray Name'];

                siteMetadata.forEach(function(record) {
                    let key  = 'Attribute_Info__c';
                    let batKey  = 'Base_Asset_Template__c';
                    let attrNameToAlias = new Map();   
                    let batId;                 
                    if (record.hasOwnProperty(batKey)) {
                        batId = record.Base_Asset_Template__c;
                        if(baseAssetToAttrAPINameToAlias.has(batId)){
                            attrNameToAlias = baseAssetToAttrAPINameToAlias.get(batId);
                        }
                    }

                    if (record.hasOwnProperty(key)) {
                        let attrInfoJSON = record.Attribute_Info__c;
                        JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
                            if(attrJSONKey.trim() !== '' && (!columnsNotToDisplay.includes(attrJSONKey))){
                                if(attrNameToAlias.has(attrJSONKey)){
                                    attrSet.add(attrJSONKey); 
                                    attrNameAliasMap.set(attrJSONKey, attrNameToAlias.get(attrJSONKey));
                                }                              
                            }
                        });
                    }
                });
                rowData = Array.from(rowData).concat(Array.from(new Set(attrSet)).sort()); // rowData - This will have the Column Headers for the CSV File.
                csvString += rowData.join(',');
                csvString += rowEnd;
                let aliasNameCount = 0;

                // To show Alias Name as row next to the header 
                let attrAliasRow = ''; 
                let attrTypeRow = ''; 

                for (let item of rowData) {
                    if(aliasNameCount > 0){
                        attrAliasRow += ',';
                        attrTypeRow += ',';
                    }
                    if(attrNameAliasMap.has(item)){
                        attrAliasRow += '"'+ attrNameAliasMap.get(item).Attribute_Master__r.Alias__c +'"';
                        let dataType = attrNameAliasMap.get(item).Attribute_Master__r.Data_Type__c;

                        if(dataType === 'Date'){
                            attrTypeRow += '"'+ 'Date (DD-MM-YYYY)' +'"';
                        }else if(dataType === 'Decimal' || dataType === 'Number'){
                            attrTypeRow += '"'+ dataType + ' (no commas allowed)' +'"';
                        }else {
                            attrTypeRow += '"'+  dataType +'"';
                        }   
                    }
                    aliasNameCount++;
                }
                attrAliasRow += rowEnd;
                attrTypeRow += rowEnd;

                csvString += attrAliasRow;
                csvString += attrTypeRow;

                for(let i=0; i < siteMetadata.length; i++){
                    let attrNameToAlias = new Map(); 
                    let baseAssetTempId = siteMetadata[i].Base_Asset_Template__c;

                    if(baseAssetToAttrAPINameToAlias.has(baseAssetTempId)){
                        attrNameToAlias = baseAssetToAttrAPINameToAlias.get(baseAssetTempId);
                    }
                    
                    let colValue = 0;       
                    for(let key in rowData) {
                        if(rowData.hasOwnProperty(key)) {
                        let keyname = rowData[key] === 'Parent'?'Parent_Asset_Short_Name__c' : // Replacing the Static Column Headers with the Site Metadata Field Name.
                                        rowData[key] === 'Name'?'Asset_Short_Name__c' : 
                                        rowData[key] === 'ObjectType'?'Name' : 
                                        rowData[key] === 'Description'?'Asset_Name__c' : 
                                        rowData[key] === 'Template'?'Base_Asset_Template__r.Name' : rowData[key];
                            if(keyname === 'SFId' ){
                                let rowKey = keyname;

                                if(colValue > 0){
                                    csvString += ',';
                                }

                                let value = '';
                                if(rowKey === 'SFId'){
                                    value = siteMetadata[i]['Id'] === undefined ? '' : siteMetadata[i]['Id'];
                                }
                                
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
                                let value = siteMetadata[sitemetadatacount].Base_Asset_Template__r.Name !== ''?siteMetadata[sitemetadatacount].Base_Asset_Template__r.Name : '';
                                csvString += '"'+ value +'"';
                                colValue++;
                            }else if(keyname !== 'Parent_Asset_Short_Name__c' && keyname !== 'Asset_Short_Name__c' && keyname !== 'Name' && 
                            keyname !== 'Asset_Name__c' && keyname !== 'Base_Asset_Template__r.Name' && keyname !== 'SFId'){
                                let rowKeyWithSym = rowData[key];
                                let rowKey = rowKeyWithSym;
                                let attrName = 'Attribute_Info__c';
                                if(colValue > 0){
                                    csvString += ',';
                                }
                                let attrValues = siteMetadata[i][attrName];
                                if(attrValues !== undefined){    
                                    let parseAttrInfo = JSON.parse(attrValues);
                                    if(parseAttrInfo.hasOwnProperty(rowKey) && attrNameToAlias.has(rowKey)){
                                        let attrJSONValue = parseAttrInfo[rowKey];
                                        let value = attrJSONValue === undefined ? '' : attrJSONValue;
                                        csvString += '"'+ value +'"';
                                        colValue++;
                                    }
                                }
                            }
                        }
                    }
                    csvString += rowEnd;
                    this.noOfRecordProcessed = (i+1);            
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
                        downloadCSV(csvString, fileName);
                        this.isLoading = false;
                    }
                }).catch(error => { 
                    showToast(this, error.body.message, 'Error', 'error');   
                    this.isLoading = false;
                });
            }
        }).catch(error => { 
            showToast(this, error.body.message, 'Error', 'error');   
            this.isLoading = false;
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
            var attrRecord = this.baseAssetToAttrMap.get(baseAssetId);
            for (var attributeRecordKey in attrRecord) {
                let attributeRecord = attrRecord[attributeRecordKey];
                var attributeMasterName = attributeRecord.attributeRecord.Attribute_Master__r.Name;
                var attrDefaultValue = attributeRecord.attributeRecord.Default_value__c;
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