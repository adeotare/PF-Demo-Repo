/**
 * TODO - Calls from upload button click 
 * Uploads csv file when upload button is clicked and delete created csv files when there is any error occured during Upload
 * */ 
public with sharing class ReadExcelAsCSV {
    /*
    * Upload the csv files to G1 plant asset prompt detail
    * @param {String} plantAssetIdFromBtn - csv file to upload
    * @param {String} papdId - plant asset prompt detail id
    * @param {String} fileName - Name of file should be uploaded
    */
    @AuraEnabled
    public static String fileUpload(String csvToShow, String papdId, String fileName){
        String returnValue = '';
        try{    
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = Blob.valueOf(csvToShow);
            cv.IsMajorVersion = true;
            Insert cv;

            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = papdId;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            Insert cdl;

            returnValue = String.valueOf(conDocId);
        }catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
        return returnValue;
    }
    /*
    * Delete csv files whenever there is any error occured while file upload
    * Deletes all uploaded file related to plant asset prompt detail
    * @param {List<String>} currentCSVInPAPD - List of Content Document Id
    */
    @AuraEnabled
    public static Boolean deleteContentDocument(List<String> currentCSVInPAPD){
        Boolean deleteProcess = false;
        try{
            List<ContentDocument> cdList = new List<ContentDocument>();
            for(ContentDocument cd : [SELECT Id FROM ContentDocument WHERE Id IN: currentCSVInPAPD]){
                cdList.add(cd);
            }
            if(cdList.size() > 0){
                delete cdList;
                deleteProcess = true;
            }
        }catch(Exception exceptionDetails){
            String errorMessage = System.Label.AssetBuilderExceptionMessage + ' - ' + exceptionDetails.getMessage();
            System.debug(' Error Message -> ' + exceptionDetails.getMessage() + ' Line # ' + exceptionDetails.getLineNumber());
            throw new AuraHandledException(errorMessage);
        }
        return deleteProcess;
    }
}