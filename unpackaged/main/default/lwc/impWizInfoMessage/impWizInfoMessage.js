import { LightningElement, api } from 'lwc';

export default class ImpWizInfoMessage extends LightningElement {
    @api className;
    @api iconName;
    @api title;
    @api message;
}