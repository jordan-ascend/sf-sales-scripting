import { LightningElement, wire, track, api } from 'lwc';
import getScriptInfo from '@salesforce/apex/ScriptInfoController.getScriptsWinsOverTime';

export default class ScriptOpportunityWinsOverTime extends LightningElement {
    @track chartConfiguration;

    searchKey = '';
    @api recordId;

    @wire(getScriptInfo, {scriptId:'$searchKey'})
    getScriptInfo({data, error}) {
        if (error) {
        this.error = error;
        console.log('error => ' + JSON.stringify(error));
        this.chartConfiguration = undefined;
        } else if (data) {
            console.log('data::');
            console.log(data);
            let chartData = [];
            let chartLabels = [];
            // for(let key in data) {
            //     chartLabels.push(key);
            //     chartData.push(data[key]);
            // }

            data.forEach(obj => {
                chartData.push(obj.count);
                chartLabels.push(obj.month);
               });

            this.chartConfiguration = {
                type: 'bar',
                data: {
                    labels: chartLabels,
                    datasets: [
                        {
                            label: 'Closed Won Last Week',
                            barPercentage: 0.5,
                            barThickness: 6,
                            maxBarThickness: 8,
                            minBarLength: 2,
                            backgroundColor: "green",
                            data: chartData,
                        },
                    ],
                },
                options: {
                    scales: {
                        yAxes: [{
                            ticks: {
                                beginAtZero: true,
                                stepSize: 1
                            }
                        }]
                    }
                },
            };
            console.log('data => ', data);
            this.error = undefined;
        }
    }

    connectedCallback(){
        console.log(':: record id ::');
        console.log(this.recordId);
        this.searchKey = this.recordId;
    }
}