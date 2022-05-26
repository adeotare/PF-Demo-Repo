import LOCALE from '@salesforce/i18n/locale';
import TIME_ZONE from '@salesforce/i18n/timeZone';
const storeSelf = [];

export function storeGlobalValueOfComps(self) {
    storeSelf[0] = self;
}

export function assignValueToGlobalAttrOfComps(value) {
    if(typeof storeSelf != 'undefined' && storeSelf.length > 0){
        if(value === ''){
            storeSelf[0].plantIdPf = value;
        }
        storeSelf[0].plantAssetId = '';
        storeSelf[0].showRequestButton();
        storeSelf[0].showTableGridForDataloggerType();
    }
}

export function convertDateToCurrentUserTimeZone(inputDate){
    var dateFormat = new Date(inputDate); 
    var options = {
        year: 'numeric', month: 'numeric', day: 'numeric',
        hour: 'numeric', minute: 'numeric', second: 'numeric',
        hour12: true,
        timeZone : TIME_ZONE
    };
    let dateValue = new Intl.DateTimeFormat(LOCALE, options).format(dateFormat); 
    return dateValue;
}