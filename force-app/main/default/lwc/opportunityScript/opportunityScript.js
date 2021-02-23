import { LightningElement, track, wire, api } from 'lwc';
import getScript from '@salesforce/apex/ScriptDisplayController.getScript';
import recordScriptUse from '@salesforce/apex/ScriptDisplayController.handleMetricObject';
import buttonEnabled from '@salesforce/apex/ScriptDisplayController.shouldButtonBeDisabled';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled }  from 'lightning/empApi';
import getNewScript from '@salesforce/apex/ScriptDisplayController.getNewScript';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class OpportunityScript extends NavigationMixin(LightningElement) {

    subscription = {};
    channelName = '/event/Opportunity_Listen__e';
    isSubscribed = false;

    // Tracks changes to channelName text field
    handleChannelName(event) {
        this.channelName = event.target.value;
    }

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

        if(this.isSubscribed == false) {
            this.handleSubscribe();
        }
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

    goToScriptRecord(event) {
        // Navigate to the script editor page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Sales_Rep_Script__c',
                recordId: this.scriptObject.data.Id,
                actionName: 'edit',
            },
        });
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = function(response) {
            console.log('New message received: ', JSON.stringify(response));
            // Want to specifically see that event has fired successfully before refreshing apex.
            // var resObj = JSON.parse(response);
            // console.log('Parsed object: '+ resObj);
            // console.log('Extracted message: '+ resObj.data.payload.createdDate);
            console.log('Refreshing apex...');
            refreshApex(this.scriptObject);
            this.connectedCallback();
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
            this.isSubscribed = true;
        });
    }
}