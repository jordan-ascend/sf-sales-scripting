import { LightningElement, wire } from 'lwc';
import getScriptsInfo from '@salesforce/apex/ScriptChartsController.getScriptsThatWinForTable';
const columns = [
    { label: 'No. Opportunities Won', fieldName: 'count', type: 'number' },
    { label: 'Script Name', fieldName: 'name', type: 'text' },
    { label: 'Script Record Page', fieldName: 'url', type: 'url' }
];
const comboBoxOptions = [
    { label: '10', value: 10},
    { label: '25', value: 25},
    { label: '50', value: 50}
];

export default class ScriptTable extends LightningElement {
    scriptsInfo;
    error;
    columns = columns;
    pageNumber;
    keyword;
    sortedField;
    sortDirection;
    sortType;
    recordsPerPage;
    isFirstPage;
    isLastPage;
    totalRecordCount;
    totalPageCount;

    @wire(getScriptsInfo, {pageNumber: 1, recordsPerPage: comboBoxOptions[0].value, keyword: null})
    initialPageSetup({error, data}) {
        if (data) {
            this.scriptsInfo = data;
            if(data.length > 0) {
                this.totalPageCount = data[0].totalPages;
                this.totalRecordCount = data[0].totalRecords;
            } else {
                this.totalPageCount = 1;
                this.totalRecordCount = 0;
            }
            this.updatePageButtons();
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    connectedCallback() {
        this.pageNumber = 1;
        this.recordsPerPage = comboBoxOptions[0].value;
    }

    get comboBoxOptions() {
        return comboBoxOptions;
    }

    handleKeyWordChange(event) {
        this.pageNumber = 1;
        this.keyword = event.target.value;
        this.handlePageChange();
    }

    handleSort(event) {
        this.pageNumber = 1;
        this.sortedField = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortType = this.columns.find(column => this.sortedField === column.fieldName).type;
        this.handlePageChange();
    }

    handleCombooxChange(event) {
        this.pageNumber = 1;
        this.recordsPerPage = event.target.value;
        console.log('number per page: ' + this.recordsPerPage);
        this.handlePageChange();
    }

    handlePrevPage(event) {
        if(this.pageNumber > 1) {
            this.pageNumber = this.pageNumber - 1;
        }
        this.handlePageChange();
    }

    handleNextPage(event) {
        if(this.pageNumber < this.totalPageCount) {
            this.pageNumber = this.pageNumber + 1;
        }
        this.handlePageChange();
    }

    handlePageChange() {
        // Get scriptInfo if I need to get it every time.
        getScriptsInfo({pageNumber: this.pageNumber, recordsPerPage: this.recordsPerPage, keyword: this.keyword})
        .then(result => {
            this.scriptsInfo = result;
            if(result.length > 0) {
                this.totalPageCount = result[0].totalPages;
                this.totalRecordCount = result[0].totalRecords;
            } else {
                this.totalPageCount = 1;
                this.totalRecordCount = 0;
            }
            this.updatePageButtons();
        })
        .catch(error => {
            this.error = error;
            console.log('Error: ' + this.error);
        })
    }

    updatePageButtons() {
        if(this.pageNumber === 1) {
            this.isFirstPage = true;
        } else {
            this.isFirstPage = false;
        }
        if(this.pageNumber >= this.totalPageCount) {
            this.isLastPage = true;
        } else {
            this.isLastPage = false;
        }
    }
}