import { LightningElement, wire } from 'lwc';
import getScriptsInfo from '@salesforce/apex/ScriptChartsController.getScriptsThatWin';
const columns = [
    { label: 'No. Opportunities Won', fieldName: 'count', type: 'number' },
    { label: 'Script Name', fieldName: 'name', type: 'text' },
    { label: 'Script Record Page', fieldName: 'url', type: 'url' }
];

export default class ScriptTable extends LightningElement {
    error;
    columns = columns;

    @wire(getScriptsInfo, {capScripts:false})scriptsInfo;
}