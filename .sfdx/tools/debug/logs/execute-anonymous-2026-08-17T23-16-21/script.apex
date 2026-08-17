Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setToAddresses(new String[] { 'tktn78@gmail.com' });
email.setSubject('Test email from Salesforce');
email.setPlainTextBody('This is a test.');
Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
System.debug('Success: ' + results[0].isSuccess());
if (!results[0].isSuccess()) {
    for (Messaging.SendEmailError err : results[0].getErrors()) {
        System.debug('Error: ' + err.getMessage());
    }
}