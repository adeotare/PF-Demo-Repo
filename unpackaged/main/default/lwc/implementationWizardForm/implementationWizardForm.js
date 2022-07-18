import { LightningElement, api, wire } from 'lwc';
import impWizTitle from '@salesforce/label/c.ImplementationWizFormTitle';
import apiRequestForm from '@salesforce/label/c.API_Request_Form';
import impWizSuccessMessage from '@salesforce/label/c.ImpWizSuccessMessage';
import unsupportedFileFormatImpWiz from '@salesforce/label/c.UnsupportedFileFormatImpWiz';
import noItemsToDisplayImpWiz from '@salesforce/label/c.NoItemsToDisplayImpWiz';
import enterValidIdInPlantIdAPI from '@salesforce/label/c.EnterValidIdInPlantIdAPI';
import aPIHistoryTableTitle from '@salesforce/label/c.APIHistoryTableTitle';
import impWizPageLoading from '@salesforce/label/c.ImpWizPageLoading';
import impWizAccessDenied from '@salesforce/label/c.ImpWizAccessDenied';
import queryInformation from "@salesforce/apex/ImplementationWizardForm.queryInformation";
import sendRequest from "@salesforce/apex/ImplementationWizardForm.sendRequest";
import impWizAccessToCommunityUsers from '@salesforce/customPermission/ImpWizAccessToCommunityUsers';
import fileUpload from "@salesforce/apex/ImplementationWizardForm.fileUpload";
import deleteCSV from '@salesforce/apex/ReadExcelAsCSV.deleteContentDocument';
import getContentVersion from "@salesforce/apex/ImplementationWizardForm.getContentVersion";
import createImpWizFormDetail from "@salesforce/apex/ImplementationWizardForm.createImpWizFormDetail";
import plantAssetStatus from "@salesforce/apex/ImplementationWizardForm.plantAssetStatus";
import plantAssetStatusCompleted from "@salesforce/apex/ImplementationWizardForm.plantAssetStatusCompleted";
import showHideImpWizBanner from "@salesforce/apex/ImplementationWizardForm.showHideImpWizBanner";
import InvalidFileSelectedKindlySelectFileTypeRelateTo from '@salesforce/label/c.InvalidFileSelectedKindlySelectFileTypeRelateTo';
import FailedToLoadFile from '@salesforce/label/c.FailedToLoadFile';
import FileUploadSuccessMessage from '@salesforce/label/c.FileUploadSuccessMessage';
import CSVFileUploadSuccessMessage from '@salesforce/label/c.CSVFileUploadSuccessMessage';
import CSVConversionInProgress from '@salesforce/label/c.CSVConversionInProgress';
import NoRevisedFileUploaded from '@salesforce/label/c.NoRevisedFileUploaded';
import ErrorWhileDeletingCsvFileInImplementationWizardForm from '@salesforce/label/c.ErrorWhileDeletingCsvFileInImplementationWizardForm';
import ErrorWhileUploadingCsvFileInImplementationWizardForm from '@salesforce/label/c.ErrorWhileUploadingCsvFileInImplementationWizardForm';
import FileReceivedSuccessfullyImpWiz from '@salesforce/label/c.FileReceivedSuccessfullyImpWiz';
import PleaseWaitRequestSendingImpWiz from '@salesforce/label/c.PleaseWaitRequestSendingImpWiz';
import PreSATInfoMessage from '@salesforce/label/c.PreSATInfoMessage';
import { registerListener } from 'c/pubsub';
import { showAndHideSpinner, showToast, generateNeuronTemplate }from "c/utils";
import DateRangeErrorMessage from '@salesforce/label/c.Date_Range_Error_Message';
import PreSATHelpText from '@salesforce/label/c.PreSATHelpText';
import momentLib from '@salesforce/resourceUrl/Moment';
import { loadScript } from 'lightning/platformResourceLoader';
import { storeGlobalValueOfComps, convertDateToCurrentUserTimeZone } from 'c/utilsImpWiz';
import ABNavigationChannel from '@salesforce/messageChannel/ABNavigationChannel__c';
import { publish , MessageContext } from 'lightning/messageService';

export default class ImplementationWizardForm extends LightningElement {
    @api xlsFileData; //excel file from button click
    @api impWizStatus;
    currentCSVInPAPD = [];
    selectedvalues;
    labels = {
        impWizTitle : impWizTitle, 
        apiRequestForm : apiRequestForm,
        impWizSuccessMessage : impWizSuccessMessage,
        unsupportedFileFormatImpWiz : unsupportedFileFormatImpWiz,
        noItemsToDisplayImpWiz : noItemsToDisplayImpWiz,
        enterValidIdInPlantIdAPI : enterValidIdInPlantIdAPI,
        apiHistoryTableTitle : aPIHistoryTableTitle,
        impWizAccessDenied : impWizAccessDenied,
        impWizPageLoading : impWizPageLoading,
        FileReceivedSuccessfullyImpWiz : FileReceivedSuccessfullyImpWiz,
        PleaseWaitRequestSendingImpWiz : PleaseWaitRequestSendingImpWiz,
        CSVConversionInProgress : CSVConversionInProgress,
        dateRangeErrorMessage : DateRangeErrorMessage,
        preSATHelpText : PreSATHelpText,
        preSATInfoMessage : PreSATInfoMessage
    }
    apiTypeAndFileFormatMap = new Map();
    acceptableFormats = [];
    controllingPicklistValue = '';
    dependentPicklistValue = '';
    disableFileUpload = true;
    disableRequestBtn = true;
    disableDownloadBtn = false;
    isRequiredFileUpload = false;
    plantIdApi = '';
    plantIdPf = '';
    uploadedFileName = '';
    revisedUploadedFileName = '';
    uploadedFileNameBackUp = '';
    isUploadedSuccess = false;
    plantIdApiRequired = true;
    plantAPIIdToDetails = new Map();
    plantPFIdToDetails = new Map();
    impDetailIdToContentDocId = new Map();
    impDetailIdToContentDocIdDownloadLink = new Map();
    historyTableData = [];
    blob;
    fileContent;
    base64File;
    plantAssetId;
    isLoading;
    documentDownloadLinkBtn;
    baseUrlForBtn;
    showNoRecordsAvailable = true;
    countOfRecords = false;
    page = 1;
    totalRecountCount;
    endingRecord;
    pageSize;
    startingRecord;
    data = [];
    showTable = false;
    showMessageNoValidId = false;
    divClassName = '';
    impWizDetailsList = [];
    apiHistoryTitle = 'API Request History';
    impWizAccessToCommunityUsers = false;
    accessDeniedMessage = this.labels.impWizPageLoading;
    className;
    iconName;
    title;
    impWizFormDetailParam={};
    plantAssetStatus;
    isShowNavigateModal = false;
    isOverrideABDataMessage;
    isNoABData = false;
    spinnerLoadingMessage = '';
    resultNeuron = "";
    pageRef = 'utilsEvent';
    isShowGenerateNeuronModal = false;
    fileURL;
    popUpMessage;
    showDatePicker = false;
    isShowImpWizBanner = false;
    bannerTitle;
    bannerContent;

    columns = [
        { label: 'FUNCTION', fieldName: 'Function_To_On_Screen__c', type: 'text', initialWidth : 130 },
        { label: 'PLANT ID API', fieldName: 'Plant_API_Id__c', type: 'text', initialWidth : 130 },
        { label: 'DATA INTERFACE', fieldName: 'Data_Interface__c', type: 'text', initialWidth : 130 },
        { label: 'API TYPE', fieldName: 'API_Type__c', type: 'text', initialWidth : 130 },
        { label: 'REQUESTED DATE TIME', fieldName: 'CreatedDate', type: 'datetime', initialWidth : 200 },
        { label: 'STATUS', fieldName: 'Status__c', type: 'text', initialWidth : 100 },
        { label: 'RESPONSE MESSAGE', fieldName: 'Response_Message__c', type: 'text', initialWidth : 250, wrapText: true },
        { 
            label: 'ACTION', fieldName: 'documentDownloadLink', type: 'url', initialWidth : 150, 
            typeAttributes: { 
                label: 'Download',
                tooltip: { 
                    fieldName: 'documentDownloadLink'
                } 
            }
        }
    ];

    disableFileUploadForIWFD = true;
    currentCSVInIWFD = [];
    get acceptedFormats() { 
        return ['.xlsx']; // allow on xlsx format
    }
    revisedUploadedFile; file; fileContents; fileReader; content; fileName; fileExt;
    isRevisedFileUploaded = false;
    isHandleRevisedFileUploaded = false;
    disabledRevisedFileUpload = true;
    disableGenerateNeuronTemplate = true;
    plantAssetStatusCompleted = false;        
    previousDate;
    fromDateDefaultValue;
    toDateDefaultValue;
    dateRangeIsValid = true;
    dateErrorMessage = '';
    fromDateVal;
    toDateVal;

    //used for message Channel
    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.defaultDateValue();
        registerListener('generateNeuronDetail', this.neuronDetails, this);
                
        queryInformation().then(result => {
            if(result) {
                let dataFromApex = JSON.parse(result);  
                
                dataFromApex.contentDocLink.forEach((currentValue) => {
                    if(!this.impDetailIdToContentDocId.has(currentValue.LinkedEntityId)){
                        this.impDetailIdToContentDocId.set(currentValue.LinkedEntityId, currentValue);
                    }
                });

                dataFromApex.apiTypeAndFileFormat.forEach((currentValue) => {
                    if(currentValue.File_Format__c){
                        if(!this.apiTypeAndFileFormatMap.has(currentValue.DeveloperName)){
                            let formatsArray = [];
                            this.apiTypeAndFileFormatMap.set(currentValue.DeveloperName, formatsArray);
                        }
                        
                        currentValue.File_Format__c.split(',').forEach((value) => {
                            let valueLowerCase =  '.'+(value.trim()).toLowerCase();
                            if(!(this.apiTypeAndFileFormatMap.get(currentValue.DeveloperName)).includes(valueLowerCase)){
                                this.apiTypeAndFileFormatMap.get(currentValue.DeveloperName).push(valueLowerCase);
                            }
                        });
                    }
                });
                
                let baseUrl = dataFromApex.baseURL;

                this.baseUrlForBtn = ((dataFromApex.userType == 'PowerCustomerSuccess') ? ((dataFromApex.isSandbox.toLowerCase() === 'true') ? (baseUrl + '/customer') : baseUrl) : baseUrl);
                this.plantAPIIdToDetails = new Map();
                this.impWizDetailsList = dataFromApex.impWizDetailsList;   
                
                if(dataFromApex.userType === 'PowerCustomerSuccess'){
                    this.impWizAccessToCommunityUsers = impWizAccessToCommunityUsers;
                    this.accessDeniedMessage = this.labels.impWizAccessDenied;
                    this.className = 'successBox';
                    this.iconName = 'utility:info';
                    this.title = 'Info';
                }else{
                    this.impWizAccessToCommunityUsers = true;
                }

                this.impWizDetailsList.forEach((currentValue) => {
                    let hasFile = this.impDetailIdToContentDocId.has(currentValue.Id);
        
                    let detailsObj = {
                        Id : currentValue.Id,
                        Data_Interface__c : currentValue.Data_Interface__c,
                        API_Type__c : currentValue.API_Type__c,
                        Plant_API_Id__c : currentValue.Plant_API_Id__c,
                        Plant_Asset__c : currentValue.Plant_Asset__c, 
                        Function_To_On_Screen__c : currentValue.Function_To_On_Screen__c,
                        CreatedDate : convertDateToCurrentUserTimeZone(currentValue.CreatedDate),
                        Status__c : currentValue.Status__c, 
                        Response_Message__c : currentValue.Response_Message__c,
                        documentDownloadName : (hasFile) ? this.impDetailIdToContentDocId.get(currentValue.Id).ContentDocument.Title : '',
                        documentDownloadLink : (hasFile) ? this.baseUrlForBtn+'/sfc/servlet.shepherd/document/download/'+this.impDetailIdToContentDocId.get(currentValue.Id).ContentDocumentId : '',
                        hasFile : hasFile
                    }
        
                    if(!this.impDetailIdToContentDocIdDownloadLink.has(currentValue.Id)){
                        this.impDetailIdToContentDocIdDownloadLink.set(currentValue.Id, detailsObj.documentDownloadLink);
                    }        
        
                    if(!this.plantAPIIdToDetails.has(currentValue.Plant_API_Id__c)){
                        let detailsObjArray = [];
                        this.plantAPIIdToDetails.set(currentValue.Plant_API_Id__c, detailsObjArray);
                    }
        
                    if(!this.plantAPIIdToDetails.has(currentValue.Plant_Asset__c)){
                        let detailsObjArray = [];
                        this.plantAPIIdToDetails.set(currentValue.Plant_Asset__c, detailsObjArray);
                    }

                    if(!this.plantAPIIdToDetails.has(currentValue.Plant_Id_PF_Text__c)){
                        let detailsObjArray = [];
                        this.plantAPIIdToDetails.set(currentValue.Plant_Id_PF_Text__c, detailsObjArray);
                    }
                    
                    this.plantAPIIdToDetails.get(currentValue.Plant_Id_PF_Text__c).push(detailsObj);
                    this.plantAPIIdToDetails.get(currentValue.Plant_API_Id__c).push(detailsObj);
                    this.plantAPIIdToDetails.get(currentValue.Plant_Asset__c).push(detailsObj);
                });

                storeGlobalValueOfComps(this);
            }
        }).catch(error => {      
            showToast(this, error.body.message, 'Error', 'error', 'sticky');
            this.isShowGenerateNeuronModal = true;
        });

        plantAssetStatusCompleted(
            {plantAssetId : this.plantAssetId
            }).then(result => {
                if(result === 'Completed')  {
                    this.plantAssetStatusCompleted = true;
                }
            }).catch(error => {
              console.log('plantAssetStatusCompleted Error', error);
            });
        showHideImpWizBanner()
        	.then(result => {
        		if(result){
        			var impWizBannerSetting = JSON.parse(result);
        			if(impWizBannerSetting.showBanner){
        			    var impWizBannerSettingShow = impWizBannerSetting.showBanner;
        			    this.isShowImpWizBanner = true;
        			    this.bannerTitle = impWizBannerSettingShow.Banner_Title__c;
        			    this.bannerContent = impWizBannerSettingShow.Banner_Content__c;
                    } else {
                        this.isShowImpWizBanner = false;
                    }
        		}
        	}).catch(error => {
        		showToast(this, 'No banner found', 'Error', 'error', 'sticky');
        	});
    }

    neuronDetails(eventDetails){
        if(eventDetails.status === 'success'){
            this.isShowGenerateNeuronModal = true;
            this.fileURL = eventDetails.fileURL;
            this.popUpMessage = eventDetails.message;
        } else if(eventDetails.status === 'error') {
            showToast(this, eventDetails.message, 'Error', 'error', 'sticky');
            this.isShowGenerateNeuronModal = true;
            this.fileURL = eventDetails.fileURL;
        }
    }

    fireSpinnerEvent(showOrHideSpinner, pubSubEventName){
        fireEvent(this.pageRef, pubSubEventName, showOrHideSpinner);
    }

    handlePicklist(event) {
        this.acceptableFormats = [];
        this.controllingPicklistValue = '';
        this.dependentPicklistValue = '';
        this.disableFileUpload = true;
        this.isRequiredFileUpload = false;
        this.plantIdApiRequired = true;

        if(this.apiTypeAndFileFormatMap.has(event.detail.pickListValue.dependent)){
            let acceptableFormatsSet = this.apiTypeAndFileFormatMap.get(event.detail.pickListValue.dependent);
            this.acceptableFormats = acceptableFormatsSet;
            this.disableFileUpload = false;
            this.isRequiredFileUpload = true;
        }

        this.controllingPicklistValue = event.detail.pickListValue.controlling;
        this.dependentPicklistValue = event.detail.pickListValue.dependent;

        if(this.controllingPicklistValue === 'Datalogger'){
            this.plantIdApiRequired = false;
            this.uploadedFileName = (this.uploadedFileNameBackUp) ? this.uploadedFileNameBackUp : ''; 
            this.showTableGridForDataloggerType(); 
        }else{
            if(this.isUploadedSuccess){
                this.uploadedFileName = '';
            }
            this.showTableGridForApiType(this.plantIdApi);
        }

        this.showRequestButton();
    }   

    handleUploadFinished(event){
        this.isUploadedSuccess = false;
        this.uploadedFileName = '';
        this.showRequestButton();

        let file = event.target.files[0];

        let reader = new FileReader();

        reader.readAsDataURL(file);
        let uploadFileExtension = '.'+file.name.split('.').pop().toLowerCase();
        let acceptableFormatsArray = [];

        for(const [key, value] of Object.entries(this.acceptableFormats)){
            acceptableFormatsArray[key] = value;
        }

        if(!acceptableFormatsArray.includes(uploadFileExtension)){
            showToast(this, this.labels.unsupportedFileFormatImpWiz + ' ' + this.dependentPicklistValue + '. Please upload files in ' + acceptableFormatsArray + ' formats.'  ,'Error','error', 'sticky');
            return;
        }

        reader.onload = () => {
            this.fileContent = reader.result;
            var base64 = 'base64,';
            var fileStart = this.fileContent.indexOf(base64) + base64.length;
            var fileEnd = this.fileContent.length;
            var base64FileCnt = this.fileContent.substring(fileStart, fileEnd);
            this.base64File = base64FileCnt;

            this.isUploadedSuccess = true;
            this.uploadedFileName = file.name;
            this.uploadedFileNameBackUp = file.name;
            this.showRequestButton();
        };

        reader.onerror = () => {
        };
    }

    inputHandler(event){
        if(event){
            this.plantIdApi = event.target.value;
        }  

        this.showRequestButton();
        //this.showTableGridForApiType(this.plantIdApi);
    }

    showTableGridForApiType(plantIdApi){
        if(this.controllingPicklistValue === 'API'){
            this.resetPaginationsAttr();
            this.apiHistoryTitle = 'API Request History';

            if(plantIdApi){
                this.apiHistoryTitle = this.labels.apiHistoryTableTitle +' Plant Id API field value - ' + plantIdApi;
            }
        }

        if(this.plantAPIIdToDetails.has(plantIdApi) && this.controllingPicklistValue === 'API'){
            this.data = this.plantAPIIdToDetails.get(plantIdApi);
            this.paginator();
        }
    }

    resetPaginationsAttr(){
        this.startingRecord = 1;
        this.endingRecord = 1;
        this.page = 1;
        this.showTable = false;
        this.showMessageNoValidId = false;
        this.historyTableData = [];
        this.data = [];
        this.divClassName = 'noHeight';
        this.totalRecountCount = 0;
        this.countOfRecords = false;
    }

    paginator(){
        this.pageSize = 10;
        this.totalRecountCount = this.data.length;
        this.countOfRecords = false;

        if(this.totalRecountCount > 10){
            this.countOfRecords = true;
        }
        this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
        if(this.data.length > 0){
            this.historyTableData = this.data.slice(0, this.pageSize);
        }
        this.endingRecord = this.pageSize;
        
        if(this.historyTableData.length > 0){
            this.showTable = true;
            this.divClassName = 'tableDiv';
        }else{
            this.showMessageNoValidId = true;
        }
    }

    previousHandler() {
        if (this.page > 1) {
            this.historyTableData = this.data.slice((this.page - 2) * this.pageSize, (this.page - 1) * this.pageSize);
            if (this.historyTableData.length != 0) {
                this.page = this.page - 1; //decrease page by 1
                this.displayRecordPerPage(this.page);
            }
        }
    } 

    nextHandler() {
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            this.historyTableData = this.data.slice(this.page * this.pageSize, (this.page + 1) * this.pageSize);
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);
        }
    }

    displayRecordPerPage(page) {
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount)
            ? this.totalRecountCount : this.endingRecord;
        this.startingRecord = this.startingRecord + 1;
    }

    handlePlantIdSelected(event){
        this.plantIdPf = '';
        this.plantAssetId = '';
        this.plantIdPf = event.detail.record.Drive_Id__c;
        this.plantAssetId = event.detail.record.Id;
        this.disableFileUploadForIWFD = false;

        this.showRequestButton();
        this.showTableGridForDataloggerType();
    }

    showTableGridForDataloggerType(){
        this.showAPIDetailsGrid();
        /*if(this.controllingPicklistValue === 'Datalogger'){
            this.showAPIDetailsGrid();
        }*/
    }

    showAPIDetailsGrid(){
        this.resetPaginationsAttr();
        this.apiHistoryTitle = 'API Request History';
            
        if(this.plantIdPf){
            this.apiHistoryTitle = this.labels.apiHistoryTableTitle +' Plant Id PF field value - ' + this.plantIdPf;
        }

        if(this.plantAPIIdToDetails.has(this.plantAssetId)){
            this.data = this.plantAPIIdToDetails.get(this.plantAssetId);
        }
        this.paginator();
    }

    showRequestButton(){
        this.disableRequestBtn = true;
        this.disableDownloadBtn = false;
        this.disabledRevisedFileUpload = true;
        this.disableGenerateNeuronTemplate = true;

        if(this.disableFileUpload === false && this.isUploadedSuccess  
            && this.isEmptyOrSpaces(this.controllingPicklistValue) !== true && 
            this.isEmptyOrSpaces(this.dependentPicklistValue) !== true && 
            this.plantIdPf !== '' && typeof this.plantIdPf !== 'undefined'){
            this.disableRequestBtn = false;
            this.disabledRevisedFileUpload = false;
            if(plantAssetStatusCompleted) {
                this.disableGenerateNeuronTemplate = false;
            }
        }   
        
        if(this.disableFileUpload === false  
            && this.isEmptyOrSpaces(this.controllingPicklistValue) !== true && 
            this.isEmptyOrSpaces(this.dependentPicklistValue) !== true && 
            this.plantIdPf !== '' && typeof this.plantIdPf !== 'undefined'){
            this.disabledRevisedFileUpload = false;
            if(plantAssetStatusCompleted) {
                this.disableGenerateNeuronTemplate = false;
            }
        }
        
        if(this.disableFileUpload === true  
            && this.isEmptyOrSpaces(this.controllingPicklistValue) !== true && 
            this.isEmptyOrSpaces(this.dependentPicklistValue) !== true &&
            this.plantIdPf !== '' && typeof this.plantIdPf !== 'undefined'){
            this.disableRequestBtn = false;
            this.disabledRevisedFileUpload = false;
            if(plantAssetStatusCompleted) {
                this.disableGenerateNeuronTemplate = false;
            }
        }

        if(this.plantIdApiRequired && (this.plantIdApi === '' || typeof this.plantIdApi === 'undefined')){
            this.disableRequestBtn = true;
            this.disableGenerateNeuronTemplate = true;
        }

        if(this.dateRangeIsValid === false && this.showDatePicker){
            this.disableRequestBtn = true;
            this.disabledRevisedFileUpload = true;
            this.disableGenerateNeuronTemplate = true;
        }

        return {
            disableRequestBtn : this.disableRequestBtn,
            disabledRevisedFileUpload : this.disabledRevisedFileUpload,
            disableGenerateNeuronTemplate : this.disableGenerateNeuronTemplate
        };
    }

    clearUplodedFiles(event){
        this.isUploadedSuccess = false;
        this.disableRequestBtn = this.showRequestButton().disableRequestBtn;
        this.disabledRevisedFileUpload = this.showRequestButton().disabledRevisedFileUpload;
        this.disableGenerateNeuronTemplate = this.showRequestButton().disableGenerateNeuronTemplate;
        this.uploadedFileName = '';
        this.handleUploadFinished(event, true);
    }

    isEmptyOrSpaces(str){
        if(typeof str != 'undefined'){
            return str === null || str.match(/^ *$/) !== null;
        }
        return true;
    }

    handleSearchString(event){
        this.plantIdPf = '';
        this.plantAssetId = '';
        this.plantIdPf = event.detail.searchString;        
        this.showRequestButton();
    }

    sendRequest(){
        this.fireSpinnerEvent(true, this.labels.PleaseWaitRequestSendingImpWiz);
        this.isRevisedFileUploaded = false;
        let requestParameters;

        if(this.controllingPicklistValue === 'Datalogger'){
            requestParameters = {
                controllingPicklistValue : this.controllingPicklistValue,
                dependentPicklistValue : this.dependentPicklistValue,
                plantIdPf : this.plantIdPf,
                plantIdApi : this.plantIdApi,
                fileContentBlob : this.base64File,
                plantAssetId : this.plantAssetId,
                fromDate : this.fromDateVal,
                toDate : this.toDateVal,
                runPreSAT : (this.showDatePicker) ? 'true' : 'false'
            } 
        }else{
            requestParameters = {
                controllingPicklistValue : this.controllingPicklistValue,
                dependentPicklistValue : this.dependentPicklistValue,
                plantIdPf : this.plantIdPf,
                plantIdApi : this.plantIdApi,
                plantAssetId : this.plantAssetId,
                fromDate : this.fromDateVal,
                toDate : this.toDateVal,
                runPreSAT : (this.showDatePicker) ? 'true' : 'false'
            }
        }

        sendRequest({
            requestParameters : JSON.stringify(requestParameters)
        }).then(result => {
            if(result){
                let res = JSON.parse(result);

                if(res.status === 'success'){
                    res.cdl;
                    this.documentDownloadLink = (res.cdl) ? this.baseUrlForBtn +'/sfc/servlet.shepherd/document/download/'+res.cdl.ContentDocumentId : '';
                    if(res.cdl){
                        this.impWizStatus = res.impWizStatus;
                        this.handleFileChange(res.cdl.Id);
                    }
                    this.disableDownloadBtn = true;
                }else if(res.status === 'error'){
                    let errorMessage = res.errorMesage;
                    this.disableDownloadBtn = false;
                    showToast(this, errorMessage, 'Error', 'error', 'sticky');
                    this.fireSpinnerEvent(false, '');
                }
            }
        }).catch(error => {      
            showToast(this, error.body.message, 'Error', 'error', 'sticky');
        });
    }

    fireSpinnerEvent(valueBoolean, spinnerLoadingMessage){  
        this.disableRequestBtn = valueBoolean;
        this.disabledRevisedFileUpload = valueBoolean;
        this.disableGenerateNeuronTemplate = valueBoolean;

        this.dispatchEvent(
            new CustomEvent("loadspinner", {
                detail: {
                    showOrHideSpinner: valueBoolean,
                    spinnerLoadingMessage: spinnerLoadingMessage
                }
            })
        );
    }

    /*
    This function is used to get the data from the uploaded file and send xlsxMain component for csv convertion
    */
    handleFileChange(contentDocumnetLink) {
        this.fireSpinnerEvent(true, this.labels.FileReceivedSuccessfullyImpWiz);

        getContentVersion({
            contentDocumnetLink : contentDocumnetLink
        }).then(result => {
            if(result){
                var contentDocumentResult = JSON.parse(result);
                var uploadedXlsFile = contentDocumentResult.xlsxAsString;
                //To check the selected file in xlsx format
                var validExts = new Array(".EXCEL_X");
                var fileName = contentDocumentResult.contentVersion.ContentDocument.Title;
                var extension = contentDocumentResult.contentVersion.ContentDocument.LatestPublishedVersion.FileType;
                var fileExt = fileName + '.' + extension;
                fileExt = fileExt.substring(fileExt.lastIndexOf('.'));
                if (validExts.indexOf(fileExt) >= 0) {
                    if (uploadedXlsFile) {
                        this.template.querySelector('c-xlsx-main').processExcelToCSVForImpWiz(uploadedXlsFile);
                    } else {
                        this.fireSpinnerEvent(false, '');
                        showToast(this, FailedToLoadFile, 'Error', 'error');
                    }
                }
                else{
                    this.fireSpinnerEvent(false, '');
                    showToast(this, InvalidFileSelectedKindlySelectFileTypeRelateTo+validExts.toString(), 'Error', 'error');
                }

            }
        }).catch(error => {      
            showToast(this, error.body.message, 'Error', 'error', 'sticky');
        });
    }

    /* 
    * Method to pass csv file to server side controller(apex class), to upload files in plant asset prompt detail
    */ 
    handleconvertcsv(event){
        try{
            this.currentCSVInIWFD = [];
            var csvFiles = event.detail.csvFiles;

            for(let nameOfCsv in csvFiles){
                let fileName = nameOfCsv+'.csv';
                fileUpload({
                    csvToShow : csvFiles[nameOfCsv],
                    impWizStatus : this.impWizStatus,
                    fileName: fileName,
                }).then(result => {
                    if(result.length >0){
                        this.currentCSVInIWFD.push(result);
                        if(this.currentCSVInIWFD.length === Object.keys(csvFiles).length){
                            this.fireSpinnerEvent(false, '');
                            showToast(this, ((this.isRevisedFileUploaded) ? CSVFileUploadSuccessMessage : FileUploadSuccessMessage), 'Success', 'success');
                        }
                    }
                }).catch(error => {
                    deleteCSV({currentCSVInIWFD : this.currentCSVInIWFD})
                    .then(result => {
                    }).catch(error => {
                        this.fireSpinnerEvent(false, '');
                        showToast(this, ErrorWhileDeletingCsvFileInImplementationWizardForm, 'Error', 'error');
                    });
                    this.currentCSVInIWFD.length = 0;
                    this.fireSpinnerEvent(false, '');
                    showToast(this, ErrorWhileUploadingCsvFileInImplementationWizardForm, 'Error', 'error');
                });
            }
        }catch(error){
            this.fireSpinnerEvent(false);
            showToast(this, ErrorWhileUploadingCsvFileInImplementationWizardForm, 'Error', 'error');
        }
    }

    handleRevisedFileUpload(event){
        this.uploadedFiles = event.target.files;
        this.revisedUploadedFile = event.target.files[0];
        this.fileExt = this.revisedUploadedFile.name;
        this.revisedUploadedFileName = this.revisedUploadedFile.name;
        this.isHandleRevisedFileUploaded = true;

        this.impWizFormDetailParam={
            plantIdPf : this.plantIdPf,
            plantAssetId : this.plantAssetId
        };
    }

    uploadRevisedFile(){
        this.isRevisedFileUploaded = true;

        if(this.isHandleRevisedFileUploaded){
            this.fireSpinnerEvent(true, this.labels.CSVConversionInProgress);
            createImpWizFormDetail({
                impWizFormDetailParam : JSON.stringify(this.impWizFormDetailParam)
            }).then(result => {
                if(result){
                    this.impWizStatus = result;
                    //To check the selected file in xlsx format
                    var validExts = new Array(".xlsx");
                    this.fileExt = this.fileExt.substring(this.fileExt.lastIndexOf('.'));
                    if (validExts.indexOf(this.fileExt) >= 0) {
                        if (this.revisedUploadedFile) {
                            this.fileReader = new FileReader();
                            this.fileReader.onloadend = (() => {  
                                this.fileContents = this.fileReader.result;
                                this.template.querySelector('c-xlsx-main').processExcelToCSVForImpWiz(this.fileContents);
                            });
                            this.fileReader.readAsBinaryString(this.revisedUploadedFile);
                        } else {
                            this.fireSpinnerEvent(false, '');
                            showToast(this, FailedToLoadFile, 'Error', 'error');
                        }
                    }else{
                        this.fireSpinnerEvent(false, '');
                        showToast(this, InvalidFileSelectedKindlySelectFileTypeRelateTo+validExts.toString(), 'Error', 'error');
                    }
                }
            }).catch(error => {      
                showToast(this, error.body.message, 'Error', 'error', 'sticky');
            });
        }else{
            showToast(this, NoRevisedFileUploaded, 'Error', 'error', 'sticky');
        }
    }   

    plantassetonblur(event){
        this.disableFileUploadForIWFD = true;
    }

    navigateToAB() {
        this.fireSpinnerEvent(true, 'Checking the record status, please wait...');
        plantAssetStatus({
            plantAssetId: this.plantAssetId
        }).then(result => {
            //if(result) {
                this.plantAssetStatus = result;
                this.fireSpinnerEvent(false, '');

                if(this.plantAssetStatus == 'Navigate to AB - Partner with AB Initiated'){
                    this.isShowNavigateModal = true;
                    this.isNoABData = false;
                    this.isOverrideABDataMessage = 'Asset Builder record for this plant has been found. Do you want to Overwrite the value?  WARNING: If you overwrite previous Asset Builder configuration will be lost';
                }else if(this.plantAssetStatus == 'Navigate to AB - Partner with AB Not Initiated'){
                    this.isShowNavigateModal = true;
                    this.isNoABData = true;
                    this.isOverrideABDataMessage = 'Asset Builder process has not started yet for this plant. Would you like to continue?';
                }else if(this.plantAssetStatus == 'PF Service Not Contains - Partner'){
                    showToast(this, 'PF Service Product and Partner Implementation Scope not contains Implementation Asset Building to Procced for AB Process', 'Info', 'info', 'sticky');
                }else if(this.plantAssetStatus == 'PLCS not contains - Partner User'){
                    showToast(this, 'Project Lifecycle Status not acceptable for AB Process', 'Info', 'info', 'sticky');
                }else if(this.plantAssetStatus == 'Navigate to AB - PF Service  - Salesforce with AB Initiated'){
                    this.isShowNavigateModal = true;
                    this.isNoABData = false;
                    this.isOverrideABDataMessage = 'Asset Builder record for this plant has been found. Do you want to Overwrite the value?  WARNING: If you overwrite previous Asset Builder configuration will be lost';
                }else if(this.plantAssetStatus == 'Navigate to AB - PF Service  - Salesforce with AB Not Initiated'){
                    this.isShowNavigateModal = true;
                    this.isNoABData = true;
                    this.isOverrideABDataMessage = 'Asset Builder process has not started yet for this plant. Would you like to continue?';
                }else if(this.plantAssetStatus == 'PF Service not contains - Salesforce'){
                    showToast(this, 'PF Service Product not contains Implementation Asset Building to Procced for AB Process', 'Info', 'info', 'sticky');
                }else if(this.plantAssetStatus == 'Submitted For Approval'){
                    this.isShowNavigateModal = true;
                    this.isNoABData = false;
                    this.isOverrideABDataMessage = 'Asset Builder record for this plant has been found. Do you want to Overwrite the value?  WARNING: If you overwrite previous Asset Builder configuration will be lost';
                }else if(this.plantAssetStatus == 'Navigate to AB - PF Service  - Community with AB Initiated'){
                    this.isShowNavigateModal = true;
                    this.isNoABData = false;
                    this.isOverrideABDataMessage = 'Asset Builder record for this plant has been found. Do you want to Overwrite the value?  WARNING: If you overwrite previous Asset Builder configuration will be lost';
                }else if(this.plantAssetStatus == 'Navigate to AB - PF Service  - Community with AB Not Initiated'){
                    this.isShowNavigateModal = true;
                    this.isNoABData = true;
                    this.isOverrideABDataMessage = 'Asset Builder process has not started yet for this plant. Would you like to continue?';
                }else if(this.plantAssetStatus == 'PLCS not Applicable'){
                    showToast(this, 'Project Lifecycle Status not Applicable to proceed for AB Process', 'Info', 'info', 'sticky');
                }else if(this.plantAssetStatus == 'No Customer Plant Asset Available'){
                    showToast(this, 'Choose Customer Plant Asset for AB Process', 'Info', 'info', 'sticky');
                }
            });
        //this.navigateToABEvent(true, true, this.plantAssetId);
    }

    navigateToModalAB(event) {
        if(event.detail.action === 'close'){
            this.isShowNavigateModal = false;
        }else{
            this.isShowNavigateModal = false;
            this.navigateToABEvent(true, true, event.detail.isOverride, this.plantAssetId);
        }
    }

    navigateToABEvent(isShowAB, isImpWizUpLoad, isOverride, plantAssetId){
        const successMessage = { 
            isShowAB: isShowAB,
            isImpWizUpLoad: isImpWizUpLoad,
            isOverride: isOverride,
            plantAssetId: plantAssetId,
        };
        publish(this.messageContext, ABNavigationChannel, successMessage);
    }

    showDatePickerFun(event){
        this.showDatePicker = event.target.checked;
        if(!this.showDatePicker){
            this.dateErrorMessage = '';
            this.dateRangeIsValid = true;
        }else{
            this.defaultDateValue(); // To set From and To date value to default 
        }
        
        this.showRequestButton();
    }

    defaultDateValue(){
        Promise.all([
            loadScript(this, momentLib + '/Moment/moment.min.js')
        ]).then(() => {
            this.fromDateVal = this.fromDateDefaultValue = moment().subtract(3, 'days').format("YYYY-MM-DD");
            this.toDateVal = this.toDateDefaultValue = moment().subtract(1, 'days').format("YYYY-MM-DD");
        })
        .catch(error => {
            console.log('Moment JS Loading Error');
        });
    }

    dateValueChange(event) {
        this.dateRangeIsValid = false;
        let elementName = event.target.name;
        let elementLabel = event.target.label;
        let elementValue = event.target.value;
        let toDateValue = this.template.querySelector('.to').value; 
        let fromDateVale = this.template.querySelector('.from').value;
        let dateDifference;
        this.dateErrorMessage = '';

        this.dateRangeIsValid = this.compareTwoDates(elementValue, elementLabel, (elementName === 'from' ? toDateValue : fromDateVale));

        if(this.dateRangeIsValid){
            if(elementName === 'from'){
                dateDifference = this.calculateDifferenceBtwTwoDates(toDateValue, elementValue);
            }else if(elementName === 'to'){
                dateDifference = this.calculateDifferenceBtwTwoDates(elementValue, fromDateVale);
            }
    
            if(dateDifference <= 1 || dateDifference >= 7){
                this.dateErrorMessage = this.labels.dateRangeErrorMessage;
                this.dateRangeIsValid = false;
            }else{
                this.dateRangeIsValid = true;
                this.fromDateVal = fromDateVale;
                this.toDateVal = toDateValue;
            }
        }
        this.showRequestButton();
    }

    calculateDifferenceBtwTwoDates(toDate, fromDate){
        const oneDay = 24 * 60 * 60 * 1000; // hours*minutes*seconds*milliseconds
        const firstDate = new Date(toDate);
        const secondDate = new Date(fromDate);
        const diffDays = Math.round(Math.abs((firstDate - secondDate) / oneDay));

        return diffDays;
    }

    compareTwoDates(dateValue, elementLabel, anotherDateValue){
        let isValid = true;
        let todayDate = moment().format("YYYY-MM-DD");
        let toDateDefaultValue = moment().format("MMM DD, YYYY");

        if(moment(dateValue).isSame(todayDate) || moment(dateValue).isAfter(todayDate)){
            this.dateErrorMessage = 'Selected '+ elementLabel +' date should be less than '+ toDateDefaultValue; 
            isValid = false;
        }else if(moment(dateValue).isBefore(anotherDateValue) && elementLabel === 'To'){
            this.dateErrorMessage = 'Selected '+ elementLabel +' date should be greater than From date'; 
            isValid = false;
        }else if(moment(dateValue).isAfter(anotherDateValue) && elementLabel === 'From'){
            this.dateErrorMessage = 'Selected '+ elementLabel +' date should be less than To date'; 
            isValid = false;
        }else if(moment(anotherDateValue).isSame(todayDate) || moment(anotherDateValue).isAfter(todayDate)){
            this.dateErrorMessage = 'Selected '+ (elementLabel === 'From' ? 'To' : (elementLabel === 'To' ? 'From' : elementLabel)) +' date should be less than '+ toDateDefaultValue; 
            isValid = false;
        }
        return isValid;
    }
    
    generateNeuron() {
        generateNeuronTemplate(this.plantAssetId, true);
    }
}