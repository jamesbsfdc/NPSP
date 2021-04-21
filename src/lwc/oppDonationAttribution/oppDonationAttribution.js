import { LightningElement, api, wire } from 'lwc';
import getHardCreditDonorsFor 
    from '@salesforce/apex/DonorService.getHardCreditDonorsFor';


export default class OppDonationAttribution extends LightningElement {

    @api recordId;
    
    donors = []; 
    donorNames = '';
    error;

    @wire(getHardCreditDonorsFor, { opportunityId: '$recordId' }) 
    wiredDonors({data, error}) {
        if (data) {
            this.donors = data;
            if(this.donors.length > 0) {
                this.donorNames = this.donors[0].fullName;
            }
        } else if (error) {
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
    };

    /***
    async connectedCallback() {
        this.donorNames = await getHardCreditDonorsFor({ recordId: this.recordId });
    }
    get displayText() {
        if(this.donorNames) {
            return this.donorNames;
        } else {
            return 'Not Found';
        }
    }
    */
}