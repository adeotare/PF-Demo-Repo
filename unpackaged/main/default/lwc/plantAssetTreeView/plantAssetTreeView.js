import { LightningElement, api, track } from 'lwc';
import formTreeView from '@salesforce/apex/PlantAssetABTreeViewHandler.formTreeView';
import noDataForAssetbuilderHierarchy from '@salesforce/label/c.NoDataForAssetbuilderHierarchy';

export default class PlantAssetTreeView extends LightningElement {
    @api plantAssetId;
    @track items;
    @track showNoDataInfoMsg = false;
    noDataMsg = noDataForAssetbuilderHierarchy;

    connectedCallback(){
        formTreeView({
            plantAssetId : this.plantAssetId
        }).then(result => {
            if(result != 'NoData'){
                this.items = JSON.parse(result);
            }else{
                this.showNoDataInfoMsg = true;
            }
        })
    }                       
}