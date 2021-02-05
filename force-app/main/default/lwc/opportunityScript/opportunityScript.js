import { LightningElement, track, wire, api } from 'lwc';
import getScript from '@salesforce/apex/ScriptDisplayController.getScript';
import recordScriptUse from '@salesforce/apex/ScriptDisplayController.handleMetricObject';
import buttonEnabled from '@salesforce/apex/ScriptDisplayController.shouldButtonBeDisabled';
import getNewScript from '@salesforce/apex/ScriptDisplayController.getNewScript';
import { refreshApex } from '@salesforce/apex';

export default class OpportunityScript extends LightningElement {

    searchKey = '';
    errorMsg = '';
    buttonDisabledBool = true;
    @api recordId;

    @wire(getScript, {oppId:'$searchKey'}) scriptObject;
    error;

    connectedCallback(){
        this.searchKey = this.recordId;
        
        buttonEnabled({oppId:this.searchKey})
        .then(result => {
            this.buttonDisabledBool = result;
            let readButton = this.template.querySelector('lightning-button');
            readButton.disabled = this.buttonDisabledBool;
        })
        .catch(error =>{
            this.error = error;
        });
    }

    markRead(event) {
        recordScriptUse({oppId:this.searchKey})
        .then(result =>{
            readButton.disabled = true;
        })
        .catch(error =>{
            this.error = error;
        });
    }

    getNewScript(event) {
        console.log('::Refresh::');
        refreshApex(this.scriptObject);
        this.connectedCallback()
    }
}