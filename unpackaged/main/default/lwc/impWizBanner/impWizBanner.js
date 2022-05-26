import { LightningElement, api, track } from 'lwc';

export default class ImpWizBanner extends LightningElement {
    @api bannerTitle;
    @api bannerContent;
}