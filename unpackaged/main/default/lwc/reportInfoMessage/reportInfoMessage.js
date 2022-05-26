import { LightningElement, api } from 'lwc';

export default class ReportInfoMessage extends LightningElement {
  @api className;
  @api iconName;
  @api title;
  @api message;
}