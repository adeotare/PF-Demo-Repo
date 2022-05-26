//xlsxMain.js
import { LightningElement, api } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import workbook from "@salesforce/resourceUrl/xlsx"; 
import ErrorWhileReadingExcel from '@salesforce/label/c.ErrorWhileReadingExcel';
import {
  showToast
} from "c/utils";

export default class XlsxMain extends LightningElement { 
  @api headerList;
  @api filename;
  @api worksheetNameList;
  @api sheetData;
  @api saveFile;
  librariesLoaded = false;

  renderedCallback() {
    console.log("renderedCallback xlsx");
    if (this.librariesLoaded) return;
    this.librariesLoaded = true;
    Promise.all([loadScript(this, workbook + "/xlsx/xlsx.full.min.js")])
      .then(() => {
        console.log("success");
      })
      .catch(error => {
        console.log("failure");
      });
  }

  @api download() {
    const XLSX = window.XLSX;
    let xlsData = this.sheetData;
    let xlsHeader = this.headerList;
    let ws_name = this.worksheetNameList;
    let createXLSLFormatObj = Array(xlsData.length).fill([]);
  
    /* form header list */
      xlsHeader.forEach((item, index) => createXLSLFormatObj[index] = [item])
    
    /* form data key list */
      xlsData.forEach((item, selectedRowIndex)=> {
          let xlsRowKey = Object.keys(item[0]);
          item.forEach((value, index) => {
              var innerRowData = [];
              xlsRowKey.forEach(item=>{
                  innerRowData.push(value[item]);
              })
              createXLSLFormatObj[selectedRowIndex].push(innerRowData);
          })

      });
    /* creating new Excel */
    var wb = XLSX.utils.book_new();

    /* creating new worksheet */
    var ws = Array(createXLSLFormatObj.length).fill([]);
    for (let i = 0; i < ws.length; i++) {
      /* converting data to excel format and pushing to worksheet */
      let data = XLSX.utils.aoa_to_sheet(createXLSLFormatObj[i]);
      ws[i] = [...ws[i], data];
      
      /* Add worksheet to Excel */
      XLSX.utils.book_append_sheet(wb, ws[i][0], ws_name[i]);
    }
    /* Write Excel and Download */
    if(this.saveFile != false){
      var wbout = XLSX.write(wb, {bookType:'xlsx',  type: 'binary'});
      var encodedData = window.btoa(wbout);
    
      this.dispatchEvent(
        new CustomEvent("save", {
            detail: {
                file :  encodedData,
                filename : this.filename
            }
        })
      );
    }
    else{
      XLSX.writeFile(wb, this.filename);
      this.dispatchEvent(new CustomEvent('success'));
    }
  }   

  /* 
  * On click of bulk import button, it convert the excel to csv
  */
  @api
  processExcelToCSV(content) {
    try{
      var result = {};
      const XLSX = window.XLSX;
      var workbook = XLSX.read(content, {  
        type: 'binary'
      });
      
      workbook.SheetNames.forEach(function(sheetName) {
        var singleCSV = XLSX.utils.sheet_to_csv(workbook.Sheets[sheetName], {
          header: 1
        });
        if (singleCSV.length) {
          result[sheetName] = singleCSV;
        }
      }.bind(this));
      const passCSVFilesForUpload = new CustomEvent('hanldeuploadcsv', {
        detail: {csvFiles : result}
      });
      this.dispatchEvent(passCSVFilesForUpload);
    }catch(err){
      showToast(this, ErrorWhileReadingExcel, 'Error', 'error');
    }
  }

  /* 
  * On click of bulk import button, it convert the excel to csv
  */
  @api
  processExcelToCSVForImpWiz(content) {
    try{
      var result = {};
      const XLSX = window.XLSX;
      var workbook = XLSX.read(content, {  
        type: 'binary'
      });
      
      workbook.SheetNames.forEach(function(sheetName) {
        var singleCSV = XLSX.utils.sheet_to_csv(workbook.Sheets[sheetName], {
          header: 1
        });
        if (singleCSV.length) {
          result[sheetName] = singleCSV;
        }
      }.bind(this));
      const passCSVFilesForUpload = new CustomEvent('handleconvertcsv', {
        detail: {csvFiles : result}
      });
      this.dispatchEvent(passCSVFilesForUpload);
    }catch(err){
      showToast(this, ErrorWhileReadingExcel, 'Error', 'error');
    }
  }
}