/**
 * Copied from example for ChartJs. Will modify for our use.
 * https://www.forcetrails.com/2020/04/bar-chart-in-lightning-web-component-lwc-bar-chartjs.html
 */
import {LightningElement, wire, track} from 'lwc';
import getOpportunities from '@salesforce/apex/ScriptChartsController.getScriptsThatWin';
export default class opporunityWonScriptChart extends LightningElement {
    @track chartConfiguration;

    @wire(getOpportunities, {capScripts:true})
    getOpportunities({data, error}) {
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
                chartLabels.push(obj.name);
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
}