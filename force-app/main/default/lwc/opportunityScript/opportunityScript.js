import { LightningElement, track, wire, api } from 'lwc';
import getScript from '@salesforce/apex/ScriptDisplayController.getScript';

export default class OpportunityScript extends LightningElement {

    searchKey = '';
    @api recordId;

    @wire(getScript, {OppId:'$searchKey'}) scriptObject;
    error;

    connectedCallback(){
        this.searchKey = this.recordId;
    }
}