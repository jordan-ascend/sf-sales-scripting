import { LightningElement, track, wire, api } from 'lwc';
import getScript from '@salesforce/apex/ScriptDisplayController.getScript';
import recordScriptUse from '@salesforce/apex/MetricObjectHandler.handleMetricObject';
import buttonEnabled from '@salesforce/apex/ScriptDisplayController.shouldButtonBeDisabled';
import getOppStage from '@salesforce/apex/ScriptDisplayController.getOppStage';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled }  from 'lightning/empApi';
// import getNewScript from '@salesforce/apex/ScriptDisplayController.getNewScript';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import MailingPostalCode from '@salesforce/schema/Contact.MailingPostalCode';

export default class OpportunityScript extends NavigationMixin(LightningElement) {

    subscription = {};
    channelName = '/event/Opportunity_Listen__e';
    isSubscribed = false;

    @track scriptMap;
    @track lightningCardName = '';
    @track scriptObject = '';

    // Tracks changes to channelName text field
    handleChannelName(event) {
        this.channelName = event.target.value;
    }

    searchKey;
    errorMsg = '';
    buttonDisabledBool = true;
    @track opportunityStage = '';

    @api recordId;

    @wire(getScript, {oppId:'$searchKey'}) 
    wiredResult(data, error) { 
        if(error) {
            this.error = error;
            console.log('error => ' + JSON.stringify(error));
        }
        if(data) {
            console.log('data::Line40');
            console.log(data.data);

            // this.scriptMap = data.data;
            for(let key in data.data) {
                // Preventing unexcepted data
                if (data.data.hasOwnProperty(key)) { // Filtering the data in the loop
                    console.log('Key::' + key);
                    console.log('value::'+data.data[key].Name);
                    // this.scriptMap.push({value:data.data[key], key:key});
                    if(key == this.opportunityStage) {
                        this.scriptObject = data.data[key];
                        this.lightningCardName = data.data[key].Name;
                    }
                }
            }
            if(typeof data.data !== 'undefined') {
                console.log('scriptMap::');
                this.scriptMap = data.data;
                console.log(this.scriptMap['Prospecting'].Name);
            }
        }
    }
        //scriptMap;
    error;

    connectedCallback(){
        // this.scriptMap = new Map();
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
        console.log('::Search key:::', this.recordId);
        getOppStage({oppId:this.recordId})
        .then(result => {
            console.log('::getting stage name::');
            this.opportunityStage = result;
            console.log(this.opportunityStage);
        })
        .catch(error =>{
            this.error = error;
        });
    }

    // markRead(event) {
    //     recordScriptUse({oppId:this.searchKey})
    //     .then(result =>{
    //         readButton.disabled = true;
    //     })
    //     .catch(error =>{
    //         this.error = error;
    //     });
    // }

    // getNewScript(event) {
    //     console.log('::Refresh::');
    //     console.log(this.scriptMap);
    //     console.log(this.opportunityStage);

    //     // refreshApex(this.scriptObject);
    //     // this.connectedCallback()
    // }

    goToScriptRecord(event) {
        // Navigate to the script editor page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Sales_Rep_Script__c',
                recordId: this.scriptObject.Id,
                actionName: 'edit',
            },
        });
    }

    handleSubscribe() {
        // Callback invoked whenever a new event message is received
        const messageCallback = function(response) {
            
            console.log('New message received: ', JSON.stringify(response));
            
            console.log('::Record Id:::');
            console.log(this.recordId);
            
            console.log('::Search key:::');
            console.log(this.searchKey);
            // console.log('Stage name: '+ JSON.parse(response));
            // Want to specifically see that event has fired successfully before refreshing apex.
            // var resObj = JSON.parse(response);
            // console.log('Parsed object: '+ resObj);
            // console.log('Extracted message: '+ resObj.data.payload.createdDate);
            console.log('Refreshing apex...');
            // refreshApex(this.scriptObject);
            // this.connectedCallback();
            getOppStage({oppId:this.searchKey})
            .then(result => {
                console.log('::getting stage name::');
                this.opportunityStage = result;
                if(typeof this.scriptMap !== 'undefined') {
                    this.scriptObject = this.scriptMap[result];
                }
                console.log(this.opportunityStage);
            })
            .catch(error =>{
                this.error = error;
            });
        }.bind(this);

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then(response => {
            // Response contains the subscription information on subscribe call
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
            this.isSubscribed = true;
        });
    }
}