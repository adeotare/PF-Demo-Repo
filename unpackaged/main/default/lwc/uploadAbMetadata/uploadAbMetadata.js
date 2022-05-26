import { LightningElement, api } from 'lwc';
import { fireEvent } from 'c/pubsub';
import { showToast, isEmptyOrSpaces, downloadCSV } from "c/utils";
import createPE from "@salesforce/apex/TriggerPEForReports.createPE";
import datauploadedsuccessfullyandReportGeneration from '@salesforce/label/c.DatauploadedsuccessfullyandReportGeneration';
import uploadfileWithErrorMessagecolumn from '@salesforce/label/c.UploadfileWithErrorMessagecolumn';
import fileUploadSuccessMessage from '@salesforce/label/c.FileUploadSuccessMessage';
import noSiteMetadataForThisPlantAsset from '@salesforce/label/c.NoSiteMetadataForThisPlantAsset';
import dataNotValidErrorMessage from '@salesforce/label/c.DataNotValidErrorMessage';
import getSiteMetadata from '@salesforce/apex/DownloadAbMetadataCsv.getSiteMetadata';
import sendDataSiteMetadata from '@salesforce/apex/DownloadAbMetadataCsv.sendDataSiteMetadata';

export default class UploadAbMetadata extends LightningElement {
    @api plantAssetId;
    @api parentComp;
    csvFileData; //excel file from button click
    csvDataLines1;
    smRecordsToAttrInfoObj = new Map();
    pageRef = 'Asset Builder';
    siteMetadataMap = new Map();
    attributeNameToAttrDetailsMap = new Map();
    picklistDetailMap = new Map();
    siteMetadataUpdateArray = [];
    plantId; plantName; noOfRecordProcessed = 0; totalNoOfRecords;
    isLoading = false;

    get acceptedFormats() { 
        return ['.csv']; // allow on csv format
    }

    connectedCallback() {
        fireEvent(this.pageRef, 'showspinnercomp', true);

        getSiteMetadata({
            plantAssetId: this.plantAssetId,
        }).then(result => {
            this.csvInput = result;
            if(result === ''){
                showToast(this, noSiteMetadataForThisPlantAsset, 'Error', 'error', 'sticky');                   
                fireEvent(this.pageRef, 'showspinnercomp', false);
                this.parentComp.showUploadMetadata = false;
            }else{
                var inputData = JSON.parse(this.csvInput);
                var siteMetadata = inputData.SiteMetadataRecords;
                var attributeNameAndDataType = inputData.Attributes;
                var picklistDetails = inputData.picklistDetails;

                picklistDetails.forEach((value, index) => {
                    if(!this.picklistDetailMap.has(value.Picklist_Master__c)){
                        this.picklistDetailMap.set(value.Picklist_Master__c, new Set());
                    }

                    this.picklistDetailMap.get(value.Picklist_Master__c).add(value.Name);
                });

                this.attributeNameToAttrDetailsMap = new Map(attributeNameAndDataType.map(coreAttr => 
                    [coreAttr.Attribute_Master__r.Name, coreAttr]
                ));

                this.siteMetadataMap = new Map(siteMetadata.map(siteMetadata => 
                    [siteMetadata.Id, JSON.stringify(siteMetadata)]
                ));

                this.plantId = siteMetadata[0].Account_Plant__r.Customer_Plant_Asset_ID__c;
                this.plantName = siteMetadata[0].Account_Plant__r.Plant_Name__c;

                this.formSitemetadaArrayOfObj(siteMetadata);
                fireEvent(this.pageRef, 'showspinnercomp', false);
            }
        }).catch(error => { 
            showToast(this, error.body.message, 'Error', 'error');   
            fireEvent(this.pageRef, 'showspinnercomp', false);
        });
    }

    formSitemetadaArrayOfObj(siteMetadata){
        siteMetadata.forEach((smRecords, index) =>{
            if(!this.smRecordsToAttrInfoObj.has(smRecords.Id)){
                this.smRecordsToAttrInfoObj.set(smRecords.Id, new Object());
            }
            this.smRecordsToAttrInfoObj.set(smRecords.Id, JSON.parse(smRecords.Attribute_Info__c));
        });
    }

    handleFileChange(event) {
        showToast(this, fileUploadSuccessMessage, 'Success', 'success'); 
        fireEvent(this.pageRef, 'showspinnercomp', true);
        
        var uploadedCsvFile = event.target.files[0];
        //To check the selected file in csv format
        var validExts = new Array(".csv");
        var fileExt = uploadedCsvFile.name;
        
        fileExt = fileExt.substring(fileExt.lastIndexOf('.'));
        if (validExts.indexOf(fileExt) >= 0) {
            if (uploadedCsvFile) {
                var reader = new FileReader();
                reader.readAsText(uploadedCsvFile);

                reader.onload = e => {
                    let csvStr = reader.result;
                    this.csvDataLines = csvStr.split('\n');
                }
                fireEvent(this.pageRef, 'showspinnercomp', false);

            } else {
                fireEvent(this.pageRef, 'showspinnercomp', false);
                showToast(this, FailedToLoadFile, 'Error', 'error');
            }
        }
        else{
            fireEvent(this.pageRef, 'showspinnercomp', false);
            showToast(this, InvalidFileSelectedKindlySelectFileTypeRelateTo+validExts.toString(), 'Error', 'error');
        } 
    }

    handleProceed(){
        let csvStringBackup = this.csvDataLines;
        let csvStringForErroMessage = '';
        let csvHeaders = this.replaceNewLineAndCR(this.csvDataLines[0]);
        let csvColumnName = csvHeaders.split(',');
        
        if(csvColumnName[0] !== 'SFId'){
            showToast(this, uploadfileWithErrorMessagecolumn, 'Error', 'error');
        }else{
            let smRecordsToAttrInfoObjMap = this.smRecordsToAttrInfoObj;
            let sitemetadataArray = [];
            let smRecordIdset = new Set();
            let dataRow = 3;
            let endRow = '\n';
            let isValid = true;
            let chunk = 100;

            // Add csv headers for error file generation
            for (var i = 0; i < dataRow; i++) {
                let csvHeaderLineNewLineRemoved = this.replaceNewLineAndCR(this.csvDataLines[i]);
                let prependText = '"Error Message",' + csvHeaderLineNewLineRemoved + endRow; 
                csvStringForErroMessage += prependText;
            }
            
            for (var i = dataRow; i < this.csvDataLines.length; i++) {
                let csvDataColumns = this.csvDataLines[i].split(',');
                let smRecordId = csvDataColumns[0].replace(/['"]+/g, '');
                let attrObj = {};
                let errorMessage = 'Data given in ';
                let isValidRecord = true;

                if(smRecordsToAttrInfoObjMap.has(smRecordId)){
                    attrObj = smRecordsToAttrInfoObjMap.get(smRecordId);
                }

                if(attrObj){
                    Object.keys(attrObj).forEach((attrName, index) => {
                        let attrNameWithoutQuote = this.replaceNewLineAndCR(attrName);
                        
                        if(csvColumnName.includes(attrName)){
                            let attrColIndex = csvColumnName.indexOf(attrNameWithoutQuote.trim());
                            let attrValue = csvDataColumns[attrColIndex];
                            let dataType;
                            let aliasName;
                            let validationResult;

                            if(this.attributeNameToAttrDetailsMap.has(attrNameWithoutQuote)){
                                dataType = this.attributeNameToAttrDetailsMap.get(attrNameWithoutQuote).Attribute_Master__r.Data_Type__c;
                                aliasName = this.attributeNameToAttrDetailsMap.get(attrNameWithoutQuote).Attribute_Master__r.Alias__c;
                            }

                            if(!isEmptyOrSpaces(attrValue)){
                                validationResult = this.validateData(dataType, attrValue, attrNameWithoutQuote);
                                if((!validationResult.isValid)){
                                    errorMessage += aliasName +', ' ;
                                    isValidRecord = isValid = false;
                                }else{
                                    attrValue = validationResult.attrValue;
                                } 
                            }    

                            if(attrValue != attrObj[attrNameWithoutQuote]){
                                attrObj[attrNameWithoutQuote] = this.replaceNewLineAndCR(attrValue);                        
                            }  
                        }          
                    });

                    let csvStringNewLineRemoved = this.replaceNewLineAndCR(csvStringBackup[i]);
                    errorMessage = errorMessage.slice(0, -2); // remove last two characters <space> and comma

                    if(!isValidRecord){
                        errorMessage += ' is either not matching the data type or incorrect format.';
                        let csvErrorPrependText = '"'+ errorMessage +'",' + csvStringNewLineRemoved;
                        csvStringNewLineRemoved = csvErrorPrependText;
                    }else{
                        let csvErrorPrependText = '"'+ '' +'",' + csvStringNewLineRemoved;
                        csvStringNewLineRemoved = csvErrorPrependText;
                    }
                    csvStringNewLineRemoved += endRow; 
                    csvStringForErroMessage += csvStringNewLineRemoved;

                    if(this.siteMetadataMap.has(smRecordId) && !smRecordIdset.has(smRecordId)){
                        let siteMetadataRecObj = JSON.parse(this.siteMetadataMap.get(smRecordId));
                        siteMetadataRecObj['Attribute_Info__c'] = '"'+JSON.stringify(attrObj)+'"';
                        sitemetadataArray.push(siteMetadataRecObj);
                        smRecordIdset.add(smRecordId);
                    }
                }
            }

            if(!isValid){
                var today = new Date();
                var date = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
                var time = today.getHours() + ":" + today.getMinutes();
                var fileName = this.plantId+'_'+this.plantName+'_'+'BulkUpload_ErrorFile'+'_'+date+' '+time+'.csv';

                downloadCSV(csvStringForErroMessage, fileName);
                showToast(this, dataNotValidErrorMessage, 'Error', 'error', 'sticky'); 
            }

            if(sitemetadataArray.length > 0 && sitemetadataArray && isValid){
                this.totalNoOfRecords = sitemetadataArray.length;
                if(sitemetadataArray.length > 0) {
                    var count = 0;
                    var finalBatch = 0;
                    if(sitemetadataArray.length % 100 == 0) {
                        finalBatch = sitemetadataArray.length / 100;
                    }
                    for(var k = 0; k < sitemetadataArray.length; k += chunk) {
                        this.siteMetadataUpdateArray = [];
                        count = count + 1;
                        this.siteMetadataUpdateArray = sitemetadataArray.slice(k, k + chunk);
                        this.noOfRecordProcessed += this.siteMetadataUpdateArray.length;

                        if(this.siteMetadataUpdateArray.length == 100){
                            if(finalBatch > 0 && (finalBatch == count)){
                                this.sendDataToServerSide(this.siteMetadataUpdateArray, true);
                            }else{
                                this.sendDataToServerSide(this.siteMetadataUpdateArray, false);
                            }
                        }else if(this.siteMetadataUpdateArray.length < 100){
                            this.sendDataToServerSide(this.siteMetadataUpdateArray, true);
                        }
                    }
                }
            }
        }
    }

    validateData(dataType, attrValue, attrNameWithoutQuote){
        let picklistMasterId;
        let isValid = true;
        let dataTypeMistached = '';

        if(dataType == 'Date'){
            if(attrValue.includes('-') && attrValue.length == 10){
                let dateSplit = attrValue.split('-');
                if(dateSplit.length <= 0 || dateSplit.length > 3){
                    isValid = false;
                    dataTypeMistached = dataType;
                }else{
                    attrValue = dateSplit[2] + '-' + dateSplit[1] + '-' + dateSplit[0];
                }
            }else{
                isValid = false;
                dataTypeMistached = dataType;
            }
        }else if(dataType == 'Number'){
            if(attrValue.includes('.')){
                isValid = false;
                dataTypeMistached = dataType;
                attrValue = '';
            }
            if(!this.isNumericOnly(attrValue)){
                isValid = false;
                dataTypeMistached = dataType;
                attrValue = '';
            }
        }else if(dataType == 'Decimal'){
            if(attrValue.includes('.')){
                let decimalValArray = attrValue.split('.'); 
                if(decimalValArray.length == 2){
                    if(!this.isNumericOnly(decimalValArray[0])){
                        isValid = false;
                        dataTypeMistached = dataType;
                        attrValue = '';
                    }

                    if(!this.isNumericOnly(decimalValArray[1])){
                        isValid = false;
                        dataTypeMistached = dataType;
                        attrValue = '';
                    }
                }else if(decimalValArray.length == 1){
                    if(!this.isNumericOnly(decimalValArray[0])){
                        isValid = false;
                        dataTypeMistached = dataType;
                        attrValue = '';
                    }
                }
            }else{        
                if(!this.isNumericOnly(attrValue)){
                    isValid = false;
                    dataTypeMistached = dataType;
                    attrValue = '';
                }
            }
        }else if(dataType == 'Checkbox'){
            if(attrValue.toLowerCase() != 'true' && attrValue.toLowerCase() != 'false'){
                isValid = false;
                dataTypeMistached = dataType;
                attrValue = '';
            }else{
                attrValue = (attrValue.toLowerCase() == 'true') ? 'TRUE' : 'FALSE';
            }
        }else if(dataType == 'Picklist'){
            if(this.attributeNameToAttrDetailsMap.has(attrNameWithoutQuote)){
                picklistMasterId = this.attributeNameToAttrDetailsMap.get(attrNameWithoutQuote).Attribute_Master__r.Picklist_Master__c;
                if(this.picklistDetailMap.has(picklistMasterId)){
                    if(!(this.picklistDetailMap.get(picklistMasterId)).has(attrValue)){
                        isValid = false;
                        dataTypeMistached = dataType;
                    }
                }
            }
        }

        return {isValid : isValid, attrValue : attrValue, dataTypeMistached : dataTypeMistached}
    }

    isAlphaOnly(inputtxt){
        let letters = /^[a-zA-Z]+$/;
        return ((inputtxt.match(letters)) ? true : false);
    }

    isNumericOnly(inputtxt){
        let letters = /^[0-9]+$/;
        return ((inputtxt.match(letters)) ? true : false);
    }

    sendDataToServerSide(sitemetadataArray, isLastBatch){
        this.isLoading = true;
        sendDataSiteMetadata({
            siteMetadataLstString : JSON.stringify(sitemetadataArray),
        }).then(result => {
            if (isLastBatch) {
                this.isLoading = false;
                this.parentComp.showUploadMetadata = false;
                showToast(this, datauploadedsuccessfullyandReportGeneration, 'Success', 'success');
                
                //calling the Report Generation Process
                createPE({ 
                    plantAssetId : this.plantAssetId
                }).then(result =>{
                    
                }).catch(error => {
                    if (error) {
                        showAndHideSpinner(this, 'hidespinner');
                        showToast(this, error, 'Error', 'error');
                    }
                });
            }
        }).catch(error => { 
            showToast(this, error.body.message, 'Error', 'error', 'sticky');   
            this.isLoading = false;
        });
    }

    handleCancel(){
        this.parentComp.showUploadMetadata = false;
    }

    replaceNewLineAndCR(str){
        return str.replace(/(\r\n|\n|\r)/gm, "")
    }
}