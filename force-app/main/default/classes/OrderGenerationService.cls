public with sharing class OrderGenerationService {

    public class OrderGenerationException extends Exception {}


    public class OrderResult {
        @AuraEnabled public Id orderId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    }

    @AuraEnabled
    public static OrderResult generateOrderWithPdf(Id opportunityId) {
        OrderResult result = new OrderResult();

        try {
            // Шаг 1: берём саму Opportunity со всеми нужными полями.
            Opportunity opp = [
                SELECT Id, Name, AccountId, CloseDate, StageName, Pricebook2Id,
                       Account.Name
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            Id primaryContactId = getPrimaryContactId(opportunityId);

            Order newOrder = new Order(
                OpportunityId = opp.Id,
                AccountId = opp.AccountId,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = opp.Pricebook2Id
            );
            Database.insert(newOrder, AccessLevel.SYSTEM_MODE);

            Blob pdfBlob = generatePdfBlob(opp.Id);

            attachPdfToOrder(pdfBlob, newOrder.Id, opp.Name);

            if (primaryContactId != null) {
                sendOrderEmail(primaryContactId, pdfBlob, opp.Name);
            }

            result.orderId = newOrder.Id;
            result.success = true;
            result.message = 'Order created successfully.';

        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to generate order: ' + e.getMessage();
            throw new AuraHandledException(result.message);
        }

        return result;
    }

    private static Id getPrimaryContactId(Id opportunityId) {
        List<OpportunityContactRole> roles = [
            SELECT ContactId
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunityId AND IsPrimary = true
            LIMIT 1
        ];
        if (roles.isEmpty()) {
            return null;
        }
        return roles[0].ContactId;
    }

    private static Blob generatePdfBlob(Id opportunityId) {
        PageReference pdfPage = Page.OrderPdfPreview;
        pdfPage.getParameters().put('id', opportunityId);

        Blob pdfBlob;
        if (Test.isRunningTest()) {

            pdfBlob = Blob.valueOf('Test PDF content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
        }
        return pdfBlob;
    }

    private static void attachPdfToOrder(Blob pdfBlob, Id orderId, String oppName) {
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Order - ' + oppName;
        cv.PathOnClient = 'Order_' + oppName + '.pdf';
        cv.VersionData = pdfBlob;
        insert cv;

        ContentVersion insertedCv = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1
        ];

        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = insertedCv.ContentDocumentId;
        link.LinkedEntityId = orderId;
        link.ShareType = 'V';
        insert link;
    }

    private static void sendOrderEmail(Id contactId, Blob pdfBlob, String oppName) {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Order_' + oppName + '.pdf');
        attachment.setBody(pdfBlob);
        attachment.setContentType('application/pdf');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(contactId);
        email.setSubject('Your Order Confirmation - ' + oppName);
        email.setPlainTextBody(
            'Dear Customer,\n\n' +
            'Thank you for your purchase with Dream Cars. Please find attached your order confirmation.\n\n' +
            'Best regards,\nDream Cars Sales Team'
        );
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attachment });
        email.setSaveAsActivity(false);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}