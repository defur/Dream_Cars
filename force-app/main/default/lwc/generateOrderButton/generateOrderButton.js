
import { LightningElement, api } from 'lwc';

import generateOrderWithPdf from '@salesforce/apex/OrderGenerationService.generateOrderWithPdf';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GenerateOrderButton extends LightningElement {

    @api recordId;


    isModalOpen = false;
    isLoading = false;

    
    get pdfPreviewUrl() {
        return '/apex/OrderPdfPreview?id=' + this.recordId;
    }


    handleGenerateOrderClick() {
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }

    handleCreateOrder() {
        this.isLoading = true;

        generateOrderWithPdf({ opportunityId: this.recordId })
            .then((result) => {
                this.isLoading = false;
                this.isModalOpen = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Order created and email sent to the customer.',
                        variant: 'success'
                    })
                );


                setTimeout(() => {
                    eval("$A.get('e.force:refreshView').fire();");
                }, 500);
            })
            .catch((error) => {
                this.isLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating order',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            });
    }
}