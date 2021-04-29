import { LightningElement, api, track } from 'lwc';
import { fireEvent } from 'c/pubsubNoPageRef';
import { isEmpty } from 'c/utilCommon';

export default class geModalPrompt extends LightningElement {

    @api variant = '';
    @api title;
    @api message;
    @api buttons = [];

    @track enrichedButtons = [];

    connectedCallback() {
        for (const button of this.buttons) {
            let enrichedButton = { ...button };
            if (isEmpty(enrichedButton.action)) {
                enrichedButton.action = this.handleCloseModal;
            }
            this.enrichedButtons.push(enrichedButton);
        }
    }  

    handleCloseModal() {
        fireEvent(this.pageRef, 'geModalCloseEvent', {});
    }

    get titleSectionComputedClass() {

        let allowedVariants = ['warning', 'shade', 'inverse', 'alt-inverse', 
            'success', 'info', 'error', 'offline', 'default'];

        let baseClass = ['slds-box', 'slds-theme_alert-texture', 'slds-box_extension'];

        if (isEmpty(this.variant) || !allowedVariants.includes(this.variant)) {
            baseClass.push('slds-theme_default');
            return baseClass.join(' ');
        }

        baseClass.push('slds-theme_'+ this.variant);
        return baseClass.join(' ');
    }
}