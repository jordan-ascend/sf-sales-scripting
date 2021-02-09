import {LightningElement, wire, track} from 'lwc';
import getScripts from '@salesforce/apex/ScriptChartsController.getAggregatedScripts';

export default class AggregatedScripts extends LightningElement {
    @track chartConfiguration;
    @track countObjs;

    @wire(getScripts, {capScripts:true})
    getScripts({data, error}) {
        if (error) {
        this.error = error;
        console.log('error => ' + JSON.stringify(error));
        this.chartConfiguration = undefined;
        } else if (data) {
            this.countObjs = data;
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
                chartLabels.push(obj.groupName);
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

    handleToggleSection(event) {
    }
}