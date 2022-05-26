import { LightningElement, track, api } from 'lwc';
import getPromptNotes from "@salesforce/apex/PromptNotes.queryPromptNotes";

export default class PromptNotes extends LightningElement {
    @api promptName;
    @track promptNote = '';

 // Accordion   
    handleSectionToggle(event) {
        const openSections = event.detail.openSections;      
    }
//Accordion

    connectedCallback(){
        getPromptNotes({
            promptName: this.promptName,
        }).then(result => {
          if (result) {
            this.promptNote = result;
          }
        })  
        .catch(error => {
          this.error = error;
        });
    }
}