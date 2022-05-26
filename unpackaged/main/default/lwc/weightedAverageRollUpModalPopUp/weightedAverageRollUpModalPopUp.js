import { LightningElement, api, track } from 'lwc';
import { fireEvent } from 'c/pubsub';
import pageCount from '@salesforce/label/c.PageCount';
import getCustomDatatableCompInput from "@salesforce/apex/WeightedAverageRollUpModalPopUp.getCustomDatatableCompInput";
import saveSiteMetadataRecords from "@salesforce/apex/WeightedAverageRollUpModalPopUp.saveSiteMetadataRecords";
import { loadScript } from 'lightning/platformResourceLoader';
import momentLib from '@salesforce/resourceUrl/Moment';
import jQueryLib from '@salesforce/resourceUrl/jQuery';
import LOCALE from '@salesforce/i18n/locale';
import dateFormatToLocale from '@salesforce/resourceUrl/DateFormatToLocale';

import {
    allowOnlyWholeNumber,
    validateDecimalInput,
    findDuplicateInArray,
    isEmptyOrSpaces,
    showToast,
    getcustomDataTable,
    replaceOldAttrbuiteValueWithNewValue,
    replaceOldAttrbuiteValueWithNewValueForUpdate,
    getModifiedMetadataRecordsArray
} from "c/utils";

export default class WeightedAverageRollUpModalPopUp extends LightningElement {
    @api plantAssetId;
    @api inputsToFormDatatable;
    @api isVertical = false;
    @api countOfRecords = false;
    @track dataTableOutput = [];
    @track tableHeaders = [];
    @track header = [];
    isNameUnique = true;
    picklistFieldAndValue = new Map();
    totalRowCount = 0;
    @track endingRecord = 0; //end record position per page
    @track pageSize = 25;
    @track totalRecountCount = 0; //total record count received from all retrieved records
    @track totalPage = 0; //total number of page is needed to display all records
    data = [];
    oldSiteMetadataValueArray = [];
    pageRef = 'Asset Builder';
    smOldValueMap = new Map();
    uniqueValidationColName = new Set();
    @api jsonInputParametersAndValues={};

    dateFormatBasedLocale = 'MM-DD-YYYY';
    siteMetadataIdToRecordDetails = new Map();
    siteMetadataIdToRecordDetailsForUpdate = new Map();

    clearDate(event) {
        let cellIndex = event.target.dataset.cellindex;
        let rowIndex = event.target.dataset.rowindex;
        let parsedRowIndex = parseInt(rowIndex, 10);
        const constantInt = 1;
        let datatableRowIndex = parsedRowIndex + constantInt;
        let element;

        if (this.isVertical) {
            element = this.template.querySelector('table').rows[cellIndex].cells.item(1);
        } else {
            element = this.template.querySelector('table').rows[datatableRowIndex].cells.item(cellIndex);
        }

        element.children[0].value = '';
        element.children[0].dataset.date = '';
        let onChangeEvent = new Event('change');
        element.children[0].dispatchEvent(onChangeEvent);
    }

    connectedCallback() {
        /**
         * Registers a callback to retrieve Attribute Requirement from custom metadata
         */
        this.jsonInputParametersAndValues = {
            isBulkUpload : 'false',
            isBulkUploadMultipleBAT : 'false',
            isImpWizUpLoad : 'false',
            isOverride : 'false',
        };
        fireEvent(this.pageRef, 'showspinnercomp', true);
        getCustomDatatableCompInput({
            plantAssetId: this.plantAssetId,
            jsonInputParametersAndValues : JSON.stringify(this.jsonInputParametersAndValues)
        }).then(result => {
            if(result != 'call Finish Popup'){
                this.inputsToFormDatatable = result;
                let inputDataResult = JSON.parse(result);

                if (inputDataResult.SiteMetadataRecords) {
                    var siteMetadataRecords = inputDataResult.SiteMetadataRecords;
                    
                    for (var siteMetadataRecordKey in siteMetadataRecords) {
                        let siteMetadataRecord = siteMetadataRecords[siteMetadataRecordKey];
                        this.siteMetadataIdToRecordDetails.set(siteMetadataRecord.Id, siteMetadataRecord);
                    }
                    
                }
                
                this.isVertical = true;
                let inputData = JSON.parse(this.inputsToFormDatatable);
                let inputDataFromUtils;
                let additionalParams = {
                    selectedAttrVal: 'None',
                    isReadOnly: false
                };
                inputDataFromUtils = getcustomDataTable(inputData, additionalParams);

                this.data = inputDataFromUtils.data;
                this.oldSiteMetadataValueArray = inputDataFromUtils.data;
                this.tableHeaders = inputDataFromUtils.tableHeaders[0];
                this.header = inputDataFromUtils.header;
                this.picklistFieldAndValue = inputDataFromUtils.picklistFieldAndValueMap
                this.pageSize = parseInt(pageCount);
                this.totalRecountCount = this.data.length;
                if (this.totalRecountCount > 100) {
                    this.countOfRecords = true;
                }
                this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); //here it is 5
                this.dataTableOutput = this.data.slice(0, this.pageSize);
                this.endingRecord = this.pageSize;
                this.totalRowCount = inputDataFromUtils.rowCount;
                fireEvent(this.pageRef, 'showspinnercomp', false);
            }
        }).catch(error => {
            if (error) {
                showToast(this, error.body.message, 'Error', 'error');
                fireEvent(this.pageRef, 'showspinnercomp', false);
            }
        });
    }

    /**
     * This method is used to check whether the attribute name is present in the JSON File.
     * @param {string} attrHeader - This attribute will have the Attribute Name. 
     * @param {object} attrInfoJSON - This attribute will have the Attribute Name and Attribute Value.
     */
    checkAttrNameInSiteMetadatAttrJSON(attrHeader, attrInfoJSON) {
        if (attrInfoJSON && attrHeader) {
            let attrValueArray = [];

            JSON.parse(attrInfoJSON, (attrJSONKey, attrJSONValue) => {
                attrValueArray.push(attrJSONKey);
            });
            return !attrValueArray.includes(attrHeader);
        }
    }

    //This method is used to fire an event to get the Old and New Attribute values of a Site Metadata Record along with the Site Metadata Record Id.
    inputChangeHandler(event) {
        let rowIndex = event.target.dataset.rowindex;
        let cellIndex = event.target.dataset.cellindex;

        let siteMetadataRecordId = this.data[rowIndex].siteMetadataRecordId;
        let isPromptSpecificAttr = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.isPromptSpecificAttr;

        let attributeName = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeHeaderName;
        let attributeHeaderAndUOM = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeHeaderAndUOM;

        let keyFieldToGenerateRowCheckValue = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.keyFieldToGenerateRowCheck;
        let isUnique = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.isUnique;
        let attributeDataType = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeDataType;
        let newAttributeValue = (typeof event.target.value !== 'undefined') ? event.target.value : '';
        let oldAttributeValue;

        let sitemetadataIdAndAttrName = siteMetadataRecordId + attributeName;
        if (!this.smOldValueMap.has(sitemetadataIdAndAttrName)) {
            oldAttributeValue = this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeValue;
            this.smOldValueMap.set(sitemetadataIdAndAttrName, oldAttributeValue);
        } else {
            oldAttributeValue = this.smOldValueMap.get(sitemetadataIdAndAttrName);
        }

        this.data[rowIndex].attrMetadata[cellIndex].attrMetadataObj.attributeValue = (attributeDataType === 'Checkbox') ? event.target.checked : newAttributeValue.trim();

        if (isUnique) {
            this.isNameUnique = this.uniqueNameValidation(this, rowIndex, cellIndex, newAttributeValue.toLowerCase());

            if (!this.isNameUnique) {
                this.uniqueValidationColName.add(attributeHeaderAndUOM);
            } else {
                this.uniqueValidationColName.delete(attributeHeaderAndUOM);
            }
        }

        let attrDetails = {
            attributeName: attributeName,
            attributeHeaderAndUOM: attributeHeaderAndUOM,
            newAttributeValue: (attributeDataType === 'Checkbox') ? event.target.checked : newAttributeValue.trim(),
            oldAttributeValue: oldAttributeValue,
            isPromptSpecificAttr: isPromptSpecificAttr,
            isAssetNameUnique: this.isNameUnique,
            keyFieldToGenerateRowCheckValue: keyFieldToGenerateRowCheckValue,
            attributeDataType: attributeDataType,
            uniqueValidationColName: this.uniqueValidationColName,
        }

        // This is used to get the modified attribute values in the Modal popup
        
        this.siteMetadataIdToRecordDetails = replaceOldAttrbuiteValueWithNewValue(
            this.siteMetadataIdToRecordDetails,
            siteMetadataRecordId,
            attrDetails.isPromptSpecificAttr,
            attrDetails.attributeName,
            attrDetails.newAttributeValue
        );

        this.siteMetadataIdToRecordDetailsForUpdate = replaceOldAttrbuiteValueWithNewValueForUpdate(
            this.siteMetadataIdToRecordDetails,
            siteMetadataRecordId,
            attrDetails.isPromptSpecificAttr,
            attrDetails.attributeName,
            attrDetails.newAttributeValue,
            this.siteMetadataIdToRecordDetailsForUpdate
        );
        
    }

    /**
     * This method is used to restrict the user from entering the Decimal Values in Number Data Type
     * and validating the Decimal values entered by the user.
     */
    renderedCallback() {
        Promise.all([
                loadScript(this, jQueryLib + '/jQuery/jquery-2.2.4.min.js'),
                loadScript(this, momentLib + '/Moment/moment.min.js'),
                loadScript(this, dateFormatToLocale)
            ])
            .then(() => {
                let templateDate = this.template.querySelectorAll('.Date');
                if (templateDate.length > 0) {
                    for (let dateFieldCount = 0; dateFieldCount < templateDate.length; dateFieldCount++) {
                        $(templateDate[dateFieldCount]).on("change", function () {
                            if (window.DateFormatToLocaleMap.hasOwnProperty(LOCALE)) {
                                this.dateFormatBasedLocale = window.DateFormatToLocaleMap[LOCALE].toString();
                            }

                            let dateValueFormat = moment(this.value, "YYYY-MM-DD").format(this.dateFormatBasedLocale);
                            this.setAttribute(
                                "data-date", (dateValueFormat === 'Invalid date' ? this.dateFormatBasedLocale : dateValueFormat)
                            )
                        }).trigger("change")
                    }
                }
            }).catch(() => {
                console.log(`jQuery loading was failed.`);
            });

        let inputTagNumberComponents = this.template.querySelectorAll(".Number");
        allowOnlyWholeNumber(inputTagNumberComponents);

        let inputTagDecimalComponents = this.template.querySelectorAll(".Decimal");
        validateDecimalInput(inputTagDecimalComponents);
    }

    handleOk(event){
        let modifiedMetadataRecords = [];
        modifiedMetadataRecords = getModifiedMetadataRecordsArray(
            this.siteMetadataIdToRecordDetails
        );
        fireEvent(this.pageRef, 'showspinnercomp', true);
        saveSiteMetadataRecords({
            siteMetadataRecordsToSave: JSON.stringify(modifiedMetadataRecords)
        }).then(result => {
            fireEvent(this.pageRef, 'showspinnercomp', false);
            showToast(this, 'Record Updated Successfully', 'Success', 'success');
            const selectedEvent = new CustomEvent("confirm", {
                detail: {
                   closeModalPopup : true
                }
            });
            this.dispatchEvent(selectedEvent);
        }).catch(error => {
            fireEvent(this.pageRef, 'showspinnercomp', false);
            showToast(this, error.body.message, 'Error', 'error'); 
        });
    }

    handleCancel(event){
        const selectedEvent = new CustomEvent("cancel", {
            detail: {
               closeModalPopup : true
            }
        });
        this.dispatchEvent(selectedEvent);
    }
    /**
     * This method is used to check the Unique values of a Attribute Already existed or not. 
     * self - This attribute will have the Curren position of the Cell.
     * @param {number} rowIndex - This attribute will have the Row Index Number.
     * @param {number} cellIndex - This attribute will have the Cell Index Number. 
     * @param {string} newAttributeValue - This will have the New Attribute Value.
     */
    uniqueNameValidation(self, rowIndex, cellIndex, newAttributeValue) {
        let isValidData = true;
        let attrValueToRowIndexMap = new Map();
        let attrValueArray = [];
        let parsedRowIndex = parseInt(rowIndex, 10);

        if (this.dataTableOutput.length > 1) {
            for (let i = 0; i < this.dataTableOutput.length; i++) {
                const constantInt = 1;
                let datatableRowIndex = i + constantInt;

                let element = self.template.querySelector('table').rows[datatableRowIndex].getElementsByClassName('uniqueValidationClass');
                let cellValue = element.item(cellIndex).value.toLowerCase();

                if (!isEmptyOrSpaces(cellValue)) {
                    attrValueArray.push(cellValue.trim());
                    attrValueToRowIndexMap.set(cellValue.trim(), datatableRowIndex);
                } else {
                    self.template.querySelector('table').rows[datatableRowIndex].getElementsByClassName('uniqueValidationClass').item(cellIndex).classList.remove('dupeValueHighlighter');
                }
            }
            let dupeValueArray = findDuplicateInArray(attrValueArray);

            if (attrValueArray.length > 0) {
                attrValueArray.forEach((attrValue) => {
                    if (dupeValueArray.includes(attrValue)) {
                        isValidData = false;
                        if (newAttributeValue.trim() === attrValue) {
                            self.template.querySelector('table').rows[parsedRowIndex + 1].getElementsByClassName('uniqueValidationClass').item(cellIndex).classList.add('dupeValueHighlighter');
                        }
                    } else {
                        if (attrValueToRowIndexMap.has(attrValue)) {
                            let rowIndex = attrValueToRowIndexMap.get(attrValue);
                            self.template.querySelector('table').rows[rowIndex].getElementsByClassName('uniqueValidationClass').item(cellIndex).classList.remove('dupeValueHighlighter');
                        }
                    }
                })
            }
        }
        return isValidData;
    }
}