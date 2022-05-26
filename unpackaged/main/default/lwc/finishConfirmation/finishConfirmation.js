import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import createPE from "@salesforce/apex/TriggerPEForReports.createPE";
import queryDetailAttributes from "@salesforce/apex/ExportAssetBuilderPromptsTemplate.queryDetailPromptAttributes";
import getSiteMetadata from '@salesforce/apex/TemplateGenerationController.getSiteMetadata';
import callNeuronAPI from '@salesforce/apex/SendNeuronTemplateDetail.callNeuronAPI';
import { fireEvent, registerListener } from 'c/pubsub';
import APIIDNotPresentInAPIType from '@salesforce/label/c.APIIDNotPresentInAPIType';
import { showAndHideSpinner, showToast, coreAttributeSorting, generateNeuronTemplate } from 'c/utils';
//import { registerListener } from 'c/pubsub';
import IWFDNavigationChannel from '@salesforce/messageChannel/IWFDNavigationChannel__c';
import { publish , MessageContext} from 'lightning/messageService';


export default class FinishConfirmation extends NavigationMixin (LightningElement) {
  @api title;
  @api popUpMessage;
  @api plantAssetId;
  @api bulkExport = false;
  pageRef = 'Asset Builder'; 
  @track xlsHeader = [];
  @track workSheetNameList = []; 
  @track xlsData = []; 
  @track filename ;
  @track saveFile = false;
  pageRefIWFD = 'Implementation Wizard From';

  @api templateFile;
  @api piTemplateFile;
  @api isImpWizUpLoad;
  @track csvInput;
  @track showFinishConfirmCmp = true;
  @track showSendNeuronCmp = false;
  @track fileURL;
  @track impWizURL;
  siteMetadataIdToRecordDetails = new Map();
  baseAssetToAttrMap = new Map();
  coreAttributePathGenerationMap = new Map();

  //Used for navigation Message Channel
  @wire(MessageContext)
    messageContext;

  successMessage = { 
    isHideIWFD: false,
    isShowAB: false
  };

  connectedCallback() {
        registerListener('generateNeuronDetailOnFinish', this.neuronDetailsOnFinish, this);
  }

  neuronDetailsOnFinish(eventDetails){
      if(eventDetails.status === 'success'){
          this.fileURL = eventDetails.fileURL;
          this.impWizURL = '/lightning/n/Implementation_Wizard_From';
          this.popUpMessage = eventDetails.message;
          this.showFinishConfirmCmp = false;
          this.showSendNeuronCmp = true;
          fireEvent(this.pageRef, 'showspinnercomp', false);
          this.fireSpinnerEvent(false, 'showspinnercompwithmessageWithDriveconversion');
      } else if(eventDetails.status === 'error') {
          this.popUpMessage = eventDetails.errorMessage +' , click proceed to try again';
          fireEvent(this.pageRef, 'showspinnercomp', false);
          this.fireSpinnerEvent(false, 'showspinnercompwithmessageWithDriveconversion');
      }
  }

  handleOk(event){
    fireEvent(this.pageRef, 'showspinnercomp', true);
    if(this.bulkExport){
      queryDetailAttributes({
        plantAssetId : this.plantAssetId
      })
      .then(result =>{
        this.excelInputValue = JSON.parse(result);
        this.excelInput = this.excelInputValue.ExcelInputsMap;
        this.assetNameLst = this.excelInputValue.AssetNameLst;
        var valueMap = new Map();
        var assetNameMap = new Map(); 
        let plantId;
        for(let value in this.assetNameLst){
          this.assetNameLst.forEach(function(record){
            Object.keys(record).forEach(function (key){
              assetNameMap.set(record['Id'], record['Asset_Name__c']);   
            })
          })
        }

        for(let value in this.excelInput){
          let inputData = this.excelInput[value];
          var siteMetadata = inputData.SiteMetadataRecords;
          var coreAttrLst = inputData.allCoreAttrLst;
          coreAttrLst.sort(coreAttributeSorting);
          var promptSpecificattrLst = inputData.promptSpecificattribute;
          var attrName = new Set();
          var arrayObject =[];
          var dataTypeObj ={};
          var attributeType ={};
          var customerFacingNotesObj ={};
          var isUnique = {};
          var reference= {};
          var aliasName = {};
          
          dataTypeObj['Core Attribute API Name'] = 'Data Type';
          attributeType['Core Attribute API Name'] = 'Attribute Type';
          customerFacingNotesObj['Core Attribute API Name'] = 'Customer Facing Notes';
          isUnique['Core Attribute API Name'] = 'Is Unique';
          reference['Core Attribute API Name'] = 'Reference';
          aliasName['Core Attribute API Name'] ='Alias Name';

          for (var promptSpecificattrkey in promptSpecificattrLst) {
            let promptSpecificRecord = promptSpecificattrLst[promptSpecificattrkey];
            let attrMasterRecord = promptSpecificRecord['Attribute_Master__r'];
            dataTypeObj[attrMasterRecord['Name']] = attrMasterRecord['Data_Type__c'];
            attributeType[attrMasterRecord['Name']] = 'Prompt Attribute';
            customerFacingNotesObj[attrMasterRecord['Name']] = 
                    (attrMasterRecord['Customer_Facing_Notes__c']) ? attrMasterRecord['Customer_Facing_Notes__c'] : (promptSpecificRecord['Customer_Facing_Notes__c']) ? (promptSpecificRecord['Customer_Facing_Notes__c']):'';
            isUnique[attrMasterRecord['Name']] = promptSpecificRecord.Is_Unique__c;
            aliasName[attrMasterRecord['Name']] = attrMasterRecord['Alias__c'];
            let plantAssetFieldName = promptSpecificRecord.hasOwnProperty('Plant_Asset_Field_Name__c');

            if(promptSpecificRecord.Is_Asset_Name__c){
              reference[attrMasterRecord['Name']] = 'Asset Name';
            }
            else if(promptSpecificRecord.Is_Parent_Asset__c){
              reference[attrMasterRecord['Name']] = 'Parent Asset';
            }
            else if(promptSpecificRecord.Is_Alternate_Parent__c){
              reference[attrMasterRecord['Name']] = 'Alternate Parent Asset';
            }else if(promptSpecificRecord.Is_Read_Only__c && !promptSpecificRecord.Is_Parent_Asset__c
                && plantAssetFieldName == false){
              reference[attrMasterRecord['Name']] = 'readOnly';
            }else{
              reference[attrMasterRecord['Name']] = 'rowGenAttribute';
            }
          }

          for (var CoreAttributekey in coreAttrLst) {
            let coreAttributeRecord = coreAttrLst[CoreAttributekey];
            let attrMasterRecord = coreAttributeRecord['Attribute_Master__r'];
            attrName.add(attrMasterRecord['Name']);
            dataTypeObj[attrMasterRecord['Name']] = attrMasterRecord['Data_Type__c'];
            attributeType[attrMasterRecord['Name']] = 'CoreAttribute';
            customerFacingNotesObj[attrMasterRecord['Name']] = 
                  (attrMasterRecord['Customer_Facing_Notes__c']) ? attrMasterRecord['Customer_Facing_Notes__c'] : (coreAttributeRecord['Customer_Facing_Notes__c']) ? (coreAttributeRecord['Customer_Facing_Notes__c']):'';
            isUnique[attrMasterRecord['Name']] = (coreAttributeRecord.Is_Unique__c) ? coreAttributeRecord.Is_Unique__c :'FALSE';
            aliasName[attrMasterRecord['Name']] = attrMasterRecord['Alias__c'];
            reference[attrMasterRecord['Name']] = (attrMasterRecord['Alias__c'] === 'Subarray Name') ? 'SFID' : 'Value';
          }

          siteMetadata.forEach(function(record){
            let recordId ={};
            let promptInfo = {};
            let attrInfo = {};
            var sheetName;
            Object.keys(record).forEach(function (key) {
              let plantAssetRecord = record['Account_Plant__r']
              plantId = plantAssetRecord['Customer_Plant_Asset_ID__c'];
              recordId['Core Attribute API Name'] = record['Id'];
              if (record.hasOwnProperty('Prompt_Specific_Info__c')) {
                let attrInfoJSON = record['Prompt_Specific_Info__c'];
                promptInfo = JSON.parse(attrInfoJSON); 
                for(let attrInfoKey in promptInfo){
                  if(promptInfo[attrInfoKey] !== ''){
                    if(assetNameMap.has(promptInfo[attrInfoKey])){
                      promptInfo[attrInfoKey] = assetNameMap.get(promptInfo[attrInfoKey]);
                    }
                  }
                }
              }
            
              if (record.hasOwnProperty('Attribute_Info__c')) {
                let attrInfoJSON = record['Attribute_Info__c'];
                let attrInfoObject;
                attrInfoObject = JSON.parse(attrInfoJSON);
                attrName.forEach(element => {
                  if(attrInfoObject.hasOwnProperty(element)){
                    attrInfo[element] = attrInfoObject[element];
                    if(attrInfoObject[element] !== '' &&  (assetNameMap.has(attrInfoObject[element]))){
                      attrInfo[element] = assetNameMap.get(attrInfoObject[element]) ;
                    }
                  }
                  else{
                    attrInfo[element] = null;
                  }
                });
              }
        
              if(key === 'Prompt_Information__r'){
                if (record.hasOwnProperty('Prompt_Information__r')) {
                  let attrInfoJSON = record['Prompt_Information__r'];
                  sheetName = attrInfoJSON['Name'].replaceAll('/','-').substring(0, 31);
                }
              }
            }) 
          
            let obj = {...recordId,...promptInfo, ...attrInfo};
            arrayObject.push(obj);  
            valueMap.set(sheetName, arrayObject);
          });  

          arrayObject.splice(0,0,dataTypeObj);
          arrayObject.splice(1,0,attributeType);
          arrayObject.splice(2,0,customerFacingNotesObj);
          arrayObject.splice(3,0,isUnique);
          arrayObject.splice(4,0,reference);
          arrayObject.splice(5,0,aliasName);
        }

        for (const [key, value] of valueMap) {
          this.xlsFormatter(value, key);
        } 

        //Excel File Name 
        var today = new Date();
        var date = today.getFullYear()+'-'+(today.getMonth()+1)+'-'+today.getDate();
        var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();
        this.filename = plantId +' '+ 'DetailPromptExport'+' '+ date +' '+ time +'.xlsx';
        fireEvent(this.pageRef, 'showspinnercomp', false);
        this.handleFinish(true);
      })
    }
    else if(this.isImpWizUpLoad){
      fireEvent(this.pageRef, 'showspinnercomp', false);
      generateNeuronTemplate(this.plantAssetId, false);
    }
    else{
      this.handleFinish(false);
    }
  }

  xlsFormatter(data, sheetName) {
    let Header = Object.keys(data[0]);
    this.xlsHeader.push(Header);
    this.workSheetNameList.push(sheetName);
    this.xlsData.push(data);
  }

  handleFinish(detailPromptExport) {
    fireEvent(this.pageRef, 'showspinnercomp', true);
    createPE({ 
      plantAssetId : this.plantAssetId
    })
    .then(response => {
      let res = JSON.parse(response);
      if (res.result) {
        let eventDet = {
          plantAssetId : this.plantAssetId,
          promptId : res.g1PromptId
        }

        if(detailPromptExport){
          this.template.querySelector("c-xlsx-main").download();
        }

        fireEvent(this.pageRef, 'redirectToG1Prompt', eventDet);
        fireEvent(this.pageRef, 'plantAssetIdChg', false);

        const selectedEvent = new CustomEvent("confirm", {
          detail: {
            confirmationOutput: true,
          }
        });
        this.dispatchEvent(selectedEvent);
        fireEvent(this.pageRef, 'showspinnercomp', false);
      }
    }).catch(error => {
      if (error) {
        fireEvent(this.pageRef, 'showspinnercomp', false);
        showToast(this, error, 'Error', 'error');
      }
    });
  }

  handleCancel(event) {
    const selectedEvent = new CustomEvent("confirm", {
      detail: {
        confirmationOutput: false,
      }
    });
    this.dispatchEvent(selectedEvent); 
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

  fireSpinnerEvent(showOrHideSpinner, pubSubEventName){  
    fireEvent(this.pageRef, pubSubEventName, showOrHideSpinner);
  }

  b64EncodeUnicode(str) {
    return btoa(encodeURIComponent(str).replace(/%([0-9A-F]{2})/g, function(match, p1) {
        return String.fromCharCode('0x' + p1);
    }));
  }

    showImpWizForm(){
      publish(this.messageContext, IWFDNavigationChannel, this.successMessage);
      const selectedEvent = new CustomEvent("confirm", {
          detail: {
              confirmationOutput: true,
          }
      });
      this.dispatchEvent(selectedEvent);
    }
}