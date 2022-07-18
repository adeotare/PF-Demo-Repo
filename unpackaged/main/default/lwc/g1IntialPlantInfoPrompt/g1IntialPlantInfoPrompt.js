import { LightningElement, track, api, wire } from "lwc";
import getPlantAssetList from "@salesforce/apex/G1IntialPlantInfoPrompt.queryPlantAssetList";
import getPlantAssetListAcc from "@salesforce/apex/G1IntialPlantInfoPrompt.queryPlantAssetListAcc"
import savePlantAsset from "@salesforce/apex/G1IntialPlantInfoPrompt.savePlantAsset";
import findNextPromptId from "@salesforce/apex/G1IntialPlantInfoPrompt.findNextPromptId";
import getSiteMetadata from "@salesforce/apex/G1IntialPlantInfoPrompt.getSiteMetadata";
import getConfirmationMessageOnNext from "@salesforce/apex/Utils.getConfirmationMessageOnNext";
import assetBuilderNextConfirmationMessage from '@salesforce/label/c.AssetBuilderNextConfirmationMessage';
import confirmationPopupTitleOnClear from '@salesforce/label/c.ConfirmationPopupTitleOnClear';
import confirmationPopupTitleOnNext from '@salesforce/label/c.ConfirmationPopupTitleOnNext';
import selectPlantAssetFromDropDown from '@salesforce/label/c.SelectPlantAssetFromDropDown';
import assetBuilderStatusClosedMessage from '@salesforce/label/c.AssetBuilderStatusClosedMessage';
import bifacialWarningInfo from '@salesforce/label/c.Bifacial_Warning_Info';

import hasG1RefreshCstmPermission from '@salesforce/customPermission/AB_G1RefreshCustomPermission';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';

import { 
  showToast,
  showAndHideSpinner,
  allowOnlyWholeNumber,
  isEmptyOrSpaces
} from "c/utils";
export default class G1IntialPlantInfoPrompt extends LightningElement {
  @api isBulkUploadMultipleBAT = false;
  @api isBulkUpload = false;
  @api isImpWizUpLoad = false;
  @api isOverride = false;
  @api plantAssetId = '';
  @api accountId = '';
  @api fromPreviousPrompt = false;
  @api g1OpenFromFinishBtn = false;
  @api isSitemetadata ='';
 

  // Used for IsReadOnly
  @track isReadOnly = false;
  @track showNext = false;
  @track showSave = false;
  @track buttonVisibled = false;
  @track isInputFieldDisabled = false;

  @track plantAssetList = [];
  @track accountList = [];
  @track selectedPlantAssetDetails;
  @track selectedAccDetails;
  @track selectedPlantAssetId = '';
  @track validPlantAsset = '';
  @track error;
  @track selectedPlantAssetByDefault=false;
  @track metMastCount = '0';
  @track renewableType = '';
  @track pfServiceProduct = '';
  @track switchgearsSubstationCount = '0';
  @track accountWithPlantAsset = '';
  @track onClickNextMessage;
  @track showConfirmPopupOnNext = false;
  @track currentPromptName = 'G.1.0 Plant Info and Renewable Type Prompt';
  @track showRefresh = false; //To hide Refresh button in the g1Prompt Action Buttons
  bifacialModule = false;
  showBifacialModule = false;
  temVerisonName = 'No Tem Version Tagged';
  showTemVerisonName = false;

  pageRef = 'Asset Builder'; 
  jsonInputParametersAndValues={};
  
  promptInfoRecord;
  label = {
    confirmationPopupTitleOnClear,
    confirmationPopupTitleOnNext,
    bifacialWarningInfo
  };

  refreshG1(plantAssetId){
    this.plantAssetId = plantAssetId;
    this.connectedCallback();
  }

  showandhidesaveandnextbutton(event){
    this.isReadOnly = event.detail.isReadOnly;
    this.showSave = event.detail.showSave;
    this.isInputFieldDisabled = event.detail.isInputFieldDisabled;
    this.showNext = event.detail.showNext;
    this.dispatchEvent(new CustomEvent('readonlyconfirm', {
      detail: {
        confirmationOutput: this.isReadOnly,
      }
    }));
  }

  connectedCallback() {
    /**
   * Registers a callback to retrieve the plant asset to component
   * 
   */
    registerListener('refreshG1', this.refreshG1, this);
    registerListener('callG1NextFromBulkUpload', this.callG1NextFromBulkUpload, this);//to handle call g1 next logic from bulk import component
    registerListener('callG1NextFromBulkUploadForMultipleBAT', this.callG1NextFromBulkUploadForMultipleBAT, this);//to handle call g1 next logic from bulk import component for multiple BAT
    fireEvent(this.pageRef, 'g1CompChange', false);
    this.selectedPlantAssetId = (this.plantAssetId !== '' && typeof this.plantAssetId !== 'undefined') ? this.plantAssetId : undefined;  
    showAndHideSpinner(this,'showspinner');
    
    getPlantAssetList({
      recordId: this.plantAssetId,
      fromPlantAssetList: false,
    })
    .then(result => {
      if (result) {
        this.accountWithPlantAsset = result;
        var g1Data = JSON.parse(this.accountWithPlantAsset);  
        var accountRecords = g1Data.Account;
        var plantAssetRecords = g1Data.PlantAssetList;
        console.log('--plantAssetRecords---'+JSON.stringify(plantAssetRecords));
        for(var plantAssetRecKey in plantAssetRecords){
                   
          this.plantAssetList.push({            
            key : plantAssetRecords[plantAssetRecKey].Id,
            Id : plantAssetRecords[plantAssetRecKey].Id,
            Name : plantAssetRecords[plantAssetRecKey].Name,
            isSelected : (this.plantAssetId === plantAssetRecords[plantAssetRecKey].Id),
            plantAssetDet : plantAssetRecords[plantAssetRecKey]
          });
          if(this.plantAssetId === plantAssetRecords[plantAssetRecKey].Id){
            this.temVerisonName = (plantAssetRecords[plantAssetRecKey].TEM_Version__c) ? plantAssetRecords[plantAssetRecKey].TEM_Version__r.Name : 'No Tem Version Tagged';
          }
        }
        if(this.plantAssetId){
          Object.entries(this.plantAssetList).forEach(
            ([key]) => {
              if(this.plantAssetId === this.plantAssetList[key].Id){
                this.selectedPlantAssetDetails = this.plantAssetList[key].plantAssetDet;
                this.hideAndShowButtonsFunc(this.selectedPlantAssetDetails); 
              };
            }
          ); 
        
          this.accountId=(this.selectedPlantAssetDetails != '' && typeof this.selectedPlantAssetDetails !== 'undefined')?this.selectedPlantAssetDetails.Account__c:'';
          if(this.accountId !== null && this.accountId !== 'None'){
            this.plantAssetList = [];
            getPlantAssetListAcc({
              fromPlantAssetList: false,
              accId: this.accountId
            })
            .then(result => {
              for(var plantAssetRecKey in result){
                this.plantAssetList.push({
                key : result[plantAssetRecKey].Id,
                  Id : result[plantAssetRecKey].Id,
                  Name : result[plantAssetRecKey].Name,
                  isSelected : (this.plantAssetId === result[plantAssetRecKey].Id),
                  plantAssetDet : result[plantAssetRecKey]
                })
              }
              showAndHideSpinner(this,'hidespinner'); 
            })
            .catch(error => {      
              showToast(this,error.body.message,'Error','error');
            });
          }
        }
        for (var accountRecKey in accountRecords) {
          this.accountList.push({
            key : accountRecords[accountRecKey].Id,
            Id : accountRecords[accountRecKey].Id,
            Name : accountRecords[accountRecKey].Name,
            isSelected :(this.accountId === accountRecords[accountRecKey].Id),
            accountdet:accountRecords[accountRecKey]
          })
        }
        showAndHideSpinner(this,'hidespinner'); 
      }
     })
    .catch(error => {      
      showToast(this,error.body.message,'Error','error');
    });

    /*
    Get the site metadata record
    */
    getSiteMetadata({
      plantId : this.selectedPlantAssetId
    }).then(result=>{
      this.switchgearsSubstationCount = '0'; 
      this.metMastCount = '0';
      JSON.parse(result, (attrJSONKey, attrJSONValue) => {
        if (attrJSONKey === 'Metmast')  this.metMastCount = attrJSONValue;
        if (attrJSONKey === 'Switchgear Substation')  this.switchgearsSubstationCount = attrJSONValue;
        if (attrJSONKey === 'Renewable Type') this.renewableType = attrJSONValue;
        if (attrJSONKey === 'PF Service Product')  this.pfServiceProduct = attrJSONValue;
        if (attrJSONKey === 'Bifacial Modules'){
          this.bifacialModule = (attrJSONValue === 'true' ? true : false);
        }
        if (attrJSONKey === 'plantTemVersion'){
          this.temVerisonName = attrJSONValue;
        }
      });

      let versionNoText;
      let versionNoInt;
      let bifacialVersionSupport = false;
      if(this.temVerisonName.includes('-')){
        this.showTemVerisonName = true;
        let tenVersionArray = this.temVerisonName.split('-');
        if(tenVersionArray.length > 0){
          versionNoText = tenVersionArray[1];
          versionNoInt = parseInt(versionNoText, 10);
          if(versionNoInt > 15){
            bifacialVersionSupport = true;
          }
        }
      }else if(this.temVerisonName === 'No Tem Version Tagged'){
        bifacialVersionSupport = true;
      }

      if(bifacialVersionSupport && (this.renewableType.includes('Solar - PV') 
        || this.renewableType.includes('Hybrid - Solar PV / BESS'))){
          this.showBifacialModule = true;
      }

      //To Show Refresh button, if the plant asset has Site metadata selected on page load(On click of previous btn in P1 prompt,plant asset is selected)
      if(result !== null && hasG1RefreshCstmPermission){
        this.showRefresh = true;
      }
     }).catch(error => {
      if (error) {
        showToast(this, error.body.message, 'Error', 'error');
      }
    });

    /*
    * If the confirm_Message_On_Next__c field is true in Prompt Information record, then the confimation modal dialog box,
      will be displayed on click of next to get the next confirmation from the user
    */
    getConfirmationMessageOnNext({
      promptName : this.currentPromptName
    }).then(result => {
      if(result){
        this.promptInfoRecord = result;
      }
    }).catch(error => {
      if(error){
      showToast(this,error.body.message,'Error','error');
      }
    });

  }
  
  goToNext(event, isDataBulkUpload){
    //if there are any validation has to be done in this func, pls execed the below block of code after valition is done
    let isDataFromBulkImportButton = (typeof isDataBulkUpload == 'undefined' || isDataBulkUpload == false) ? false : true;
    if((typeof this.selectedPlantAssetId === 'undefined' || this.selectedPlantAssetId === 'None' 
      || this.validPlantAsset === 'None' || this.selectedPlantAssetId === '') 
      && isDataFromBulkImportButton == false){
      showToast(this, selectPlantAssetFromDropDown, 'Info', 'info');
    }else if(this.metmastCountValidation() == false && isDataFromBulkImportButton == false && !this.isReadOnly){
      return;
    }else if(this.promptInfoRecord.Show_Popup_On_Next_Button__c && isDataFromBulkImportButton == false && !this.isReadOnly){
      this.onClickNextMessage = ((typeof this.promptInfoRecord.Confirm_Message_On_Next__c === 'undefined')) ? assetBuilderNextConfirmationMessage : this.promptInfoRecord.Confirm_Message_On_Next__c;
      this.showConfirmPopupOnNext = true;
    }else{
      this.hanldeNextOnConfirm(event, true);
    }
  }
  
  /*
  Navigates to the next prompt, passes the current prompt id, current prompt name, plant Asset Id to the nexxt prompt
  */
  hanldeNextOnConfirm(event, executeNextLogic) {
    let allowNextLogic = (executeNextLogic) ? executeNextLogic : event.detail.confirmationOutput;
    let additionalParamsForNext = {isReadOnly: this.isReadOnly, bifacialModules : this.bifacialModule.toString()};
    fireEvent(this.pageRef, 'g1CompChange', false);

    if(allowNextLogic){
      this.jsonInputParametersAndValues = {
        isBulkUpload : this.isBulkUpload.toString(),
        isBulkUploadMultipleBAT : this.isBulkUploadMultipleBAT.toString(),
        isImpWizUpLoad : this.isImpWizUpLoad.toString(),
        isOverride : this.isOverride.toString()
      };
      showAndHideSpinner(this,'showspinner'); 
      findNextPromptId({
        plantAssetId: this.selectedPlantAssetDetails.Id,
        metMastCount : this.metMastCount,
        switchgearsSubstationCount : this.switchgearsSubstationCount,
        renewableType:this.renewableType,
        pfServiceProduct:this.pfServiceProduct,
        additionalParamsForNext: JSON.stringify(additionalParamsForNext),
        jsonInputParametersAndValues : JSON.stringify(this.jsonInputParametersAndValues)
      })
      .then(result => {
        if(result){
          let nextPromptFinderRes = JSON.parse(result);
          this.dispatchEvent(
            new CustomEvent("next", {
              detail: {
                action: "next",
                currentPromptId: nextPromptFinderRes.currentPromptId,
                nextPromptId: nextPromptFinderRes.nextPromptId,
                plantAssetId: nextPromptFinderRes.plantAssetId,
                previousPromptName: nextPromptFinderRes.plantAssetPromptDetailId,
                isBulkUpload: this.isBulkUpload,
                isBulkUploadMultipleBAT: this.isBulkUploadMultipleBAT,
                isImpWizUpLoad : this.isImpWizUpLoad,
                isOverride : this.isOverride,
              }
            })
          );
          showAndHideSpinner(this,'hidespinner'); 
        }else{
          showAndHideSpinner(this,'hidespinner'); 
          showToast(this,'Please contact administrator','Error','error');
        }
      }).catch(error => {
        showAndHideSpinner(this,'hidespinner'); 
        showToast(this,error.body.message,'Error','error');
      });
    }else{
      this.showConfirmPopupOnNext = false;
    }
  }

  /*
  Any change in the Account is handled here
   */
  accountNameChangeHandler(event){
    showAndHideSpinner(this,'showspinner'); 

    this.plantAssetList = [];
    let accId = event.target.value;
    this.accountId = accId;
    this.selectedPlantAssetDetails = '';
    this.validPlantAsset = 'None'; 
    this.selectedPlantAssetId = 'None'; //This value is passed to callActionButtonCompFun to rerender the child component
    this.buttonVisibled = false; //To disable the assetBuilderStatusClosedMessage 
    this.showSave = false;
    this.showNext = false;  
       
      getPlantAssetListAcc({
        fromPlantAssetList: false,
        accId: accId
      })
    .then(result => {
      for(var plantAssetRecKey in result){
        this.plantAssetList.push({
          key : result[plantAssetRecKey].Id,
          Id : result[plantAssetRecKey].Id,
          Name : result[plantAssetRecKey].Name,
          Account__c : result[plantAssetRecKey].Account__c,
          plantAssetDet : result[plantAssetRecKey]
        })
      }
      showAndHideSpinner(this,'hidespinner'); 
    })
    .catch(error => {      
      showToast(this,error.body.message,'Error','error');
    });

    this.callActionButtonCompFun(this.selectedPlantAssetId);
    this.showRefresh = false; // Hide the Refresh btn whenever account is changed or changed to None

  }
  /*
  Any change in the component is handled here
   */
  plantNameChangeHandler(event){
    showAndHideSpinner(this,'showspinner'); 
    this.showBifacialModule = false;
    this.bifacialModule = false;
    let plantId = event.target.value;
    this.selectedPlantAssetId = plantId;
    this.validPlantAsset = '';
    if(plantId === 'None'){
      this.selectedPlantAssetDetails = ''; 
      this.validPlantAsset = 'None'; 
      this.buttonVisibled = false;//To disable the assetBuilderStatusClosedMessage 
      this.showNext = false;
      this.showSave = false;
    }
    
    let plantAssetName = '';
    Object.entries(this.plantAssetList).forEach(
      ([key, value]) => {
        if(plantId === this.plantAssetList[key].Id){
          this.selectedPlantAssetId = plantId;
          this.selectedPlantAssetDetails = this.plantAssetList[key].plantAssetDet;
          plantAssetName = this.plantAssetList[key].plantAssetDet.Name;
          this.renewableType = this.plantAssetList[key].plantAssetDet.Renewable_Type__c;
          this.pfServiceProduct = this.plantAssetList[key].plantAssetDet.PF_Service_Product__c;
          this.temVerisonName = (this.plantAssetList[key].plantAssetDet.TEM_Version__c) ? this.plantAssetList[key].plantAssetDet.TEM_Version__r.Name : 'No Tem Version Tagged';
          this.hideAndShowButtonsFunc(this.selectedPlantAssetDetails);          
        }
      }
    );

    let eveDetails = {
      plantAssetName : plantAssetName,
      plantAssetTemVersion : this.temVerisonName
    }
    fireEvent(this.pageRef, 'showPlantAssetDetails', eveDetails);
    
      /*
      Get the site metadata record
      */
    getSiteMetadata({
      plantId : this.selectedPlantAssetId
    }).then(result=>{
      this.switchgearsSubstationCount = '0'; 
      this.metMastCount = '0';
      JSON.parse(result, (attrJSONKey, attrJSONValue) => {
        if (attrJSONKey === 'Metmast')  this.metMastCount = attrJSONValue;
        if (attrJSONKey === 'Switchgear Substation')  this.switchgearsSubstationCount = attrJSONValue;
        if (attrJSONKey === 'Renewable Type') this.renewableType = attrJSONValue;
        if (attrJSONKey === 'PF Service Product')  this.pfServiceProduct = attrJSONValue;

        if (attrJSONKey === 'Bifacial Modules'){
          this.bifacialModule = (attrJSONValue === 'true' ? true : false);
        }
      });

      let versionNoText;
      let versionNoInt;
      let bifacialVersionSupport = false;
      if(this.temVerisonName.includes('-')){
        this.showTemVerisonName = true;
        let tenVersionArray = this.temVerisonName.split('-');
        if(tenVersionArray.length > 0){
          versionNoText = tenVersionArray[1];
          versionNoInt = parseInt(versionNoText, 10);
          if(versionNoInt > 15){
            bifacialVersionSupport = true;
          }
        }
      }else if(this.temVerisonName === 'No Tem Version Tagged'){
        bifacialVersionSupport = true;
      }
      
      if(bifacialVersionSupport && (this.renewableType.includes('Solar - PV') 
        || this.renewableType.includes('Hybrid - Solar PV / BESS'))){
          this.showBifacialModule = true;
      }

      this.callActionButtonCompFun(this.selectedPlantAssetId); //To rerender the child component with new plantassetId
      //To Hide or show Refresh button if the G1 Site Meta data is available for the selected plant asset
      if(result !== null && result !== '{}' && hasG1RefreshCstmPermission){
        this.showRefresh = true;
      }else{
        this.showRefresh = false;
      }
      showAndHideSpinner(this,'hidespinner'); 
    }).catch(error => {
      if (error) {
        showToast(this, error.body.message, 'Error', 'error');
      }
    });
  }
 
  callActionButtonCompFun(selectedPlantAssetId){
    fireEvent(this.pageRef, 'plantAssetIdChg', false);
    fireEvent(this.pageRef, 'g1CompChange', false);

    let g1PromptActionButtons = this.template.querySelectorAll('c-g1-prompt-action-buttons');
    if(g1PromptActionButtons.length > 0){
      g1PromptActionButtons[0].getSelectPlantAssetId(selectedPlantAssetId);
    }
  }

  hideAndShowButtonsFunc(plantAssetSODetails){
    let plantAssetSOABStatus = plantAssetSODetails.Asset_Builder_Status__c;
    let plantAssetSOApprovalStatus = plantAssetSODetails.AB_Approval_Status__c;         
    if(plantAssetSOABStatus === 'Closed'){
      this.buttonVisibled = true;
      this.assetBuilderInfoMessage = assetBuilderStatusClosedMessage;
      this.className = 'infoBox';
      this.iconName = 'utility:info_alt';
      this.title = 'Info';
      if(plantAssetSOApprovalStatus === 'Submitted' || plantAssetSOApprovalStatus === 'Approved'){
        this.isReadOnly = true;
        this.showNext = true; 
        this.dispatchEvent(new CustomEvent('readonlyconfirm', {
          detail: {
            confirmationOutput: true,
          }
        }));            
      }else{
        this.isReadOnly = false;
        this.showNext = false;
      }
      this.showSave = false;
      this.isInputFieldDisabled = true;      
    }else{
      this.buttonVisibled = false;
      if(plantAssetSOApprovalStatus === 'Submitted' || plantAssetSOApprovalStatus === 'Approved'){
        this.isReadOnly = true;
        this.showNext = true;
        this.showSave = false;
        this.isInputFieldDisabled = true;
      }else{
        this.isReadOnly = false;
        this.showNext = true;
        this.showSave = true;
        this.isInputFieldDisabled = false;        
      }
    }  
    this.dispatchEvent(new CustomEvent('readonlyconfirm', {
      detail: {
        confirmationOutput: this.isReadOnly,
      }
    }));
  }

  inputTagValueChangeHandler(event){
    if(event.target.name === 'Met Mast') this.metMastCount = isEmptyOrSpaces(event.target.value) ? '0' : event.target.value;
    if(event.target.name === 'Switchgear Substation') this.switchgearsSubstationCount = isEmptyOrSpaces(event.target.value) ? '0' : event.target.value;
    if(event.target.name === 'Bifacial Module') this.bifacialModule = event.target.checked;

    if(this.bifacialModule === true){
      this.template.querySelector(".pTagCls").classList.remove("shake-false");
      this.template.querySelector(".pTagCls").classList.add("shake-true");
    }

    if(this.bifacialModule === false){
      this.template.querySelector(".pTagCls").classList.remove("shake-true");
      this.template.querySelector(".pTagCls").classList.add("shake-false");
    }
  }
  
  metmastCountValidation(){
    let isValid = true;

    if(this.bifacialModule && (this.metMastCount === '0' || this.metMastCount === '')){
      showToast(this, 'Atleast 1 met mast count should be entered as this plant has Bifacial Modules', 'Error', 'error');
      isValid = false;
    }
    return isValid;
  }
  /*
  The plant Asset id, Metmast count, switchgearsubstation count are passed to the prompt controller to update these values in plant asset 
  and sitemetadata records.
  */
  savePlantAssetHandler(event){
    if(this.metmastCountValidation()){
      let fromExportButton= (typeof event.detail.fromExportButton === 'undefined') ? 'false' : event.detail.fromExportButton;
      let updateG1Record = (typeof event.detail.updateG1Record === 'undefined') ? 'false' : event.detail.updateG1Record;
      fireEvent(this.pageRef, 'g1CompChange', false);
      if(typeof this.selectedPlantAssetId === 'undefined' || this.selectedPlantAssetId === 'None' || this.validPlantAsset === 'None'
        || this.selectedPlantAssetId === ''){
        showToast(this, selectPlantAssetFromDropDown, 'Info', 'info');
      }else{
        showAndHideSpinner(this,'showspinner'); 
        savePlantAsset({
          plantAssetId: this.selectedPlantAssetDetails.Id,
          renewableType: this.selectedPlantAssetDetails.Renewable_Type__c, 
          pfServiceProduct: this.selectedPlantAssetDetails.PF_Service_Product__c,
          metMastCount : this.metMastCount,
          switchgearsSubstationCount : this.switchgearsSubstationCount,
          bifacialModules : this.bifacialModule
        })
      .then(result => {
        /* 
        @param {fromExportButton} is set to true
        - if g1 prompt save action called from Export button of g1ActionButtons component
        */
        if(result){
          if(fromExportButton === true){
            this.template.querySelector("c-g1-prompt-action-buttons").exportSiteMetadata((this.metMastCount >0), (this.switchgearsSubstationCount > 0));
          }else if(updateG1Record === true){
            this.template.querySelector("c-g1-prompt-action-buttons").handleExportClick();
          }
          else if(fromExportButton !== true && updateG1Record !== true){
            showAndHideSpinner(this,'hidespinner'); 
            showToast(this,'Record Saved Successfully','Info','success');
            if(hasG1RefreshCstmPermission){
              this.showRefresh = true; //Showing the Refresh, button
            }
          }
        }else{
          showAndHideSpinner(this,'hidespinner'); 
          showToast(this,'Please contact administrator','Error','error');
        }
      }).catch(error => {
        showAndHideSpinner(this,'hidespinner'); 
        showToast(this,error.body.message,'Error','error');
      });
      }
    }
  }

  renderedCallback(){
    let inputTagComponents = this.template.querySelectorAll(".Number");
    allowOnlyWholeNumber(inputTagComponents);
  }

  /*To call G1 next logic from bulk import button*/
  callG1NextFromBulkUpload(variableForNext){
    if(variableForNext){
      this.isBulkUpload = true;
      this.goToNext(event, true);
    }
  }

  /*To call G1 next logic from bulk import button for Multiple BAT*/
  callG1NextFromBulkUploadForMultipleBAT(variableForNext){
    if(variableForNext){
      this.isBulkUploadMultipleBAT = true;
      this.goToNext(event, true);
    }
  }
}