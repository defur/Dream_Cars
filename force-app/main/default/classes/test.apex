Account acc = new Account(
    Name = 'DEBUG Account',
    BillingStreet = '1 Test', BillingCity = 'Test', BillingCountry = 'Germany'
);
insert acc;

Product2 prod = new Product2(
    Name = 'DEBUG Car', IsActive = true,
    Brand__c = 'Toyota', Model__c = 'Corolla',
    VIN_Number__c = 'DEBUGVIN123456789', Condition__c = 'New', Mileage__c = 0
);
insert prod;

// Вместо Test.getStandardPricebookId() - берём реальный Standard Pricebook из org
Id standardPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

PricebookEntry pbe = new PricebookEntry(
    Pricebook2Id = standardPbId,
    Product2Id = prod.Id, UnitPrice = 20000, IsActive = true
);
insert pbe;

Opportunity opp1 = new Opportunity(
    Name = 'DEBUG Opp1', AccountId = acc.Id,
    StageName = 'Prospecting', CloseDate = Date.today().addDays(5)
);
insert opp1;

OpportunityLineItem li1 = new OpportunityLineItem(
    OpportunityId = opp1.Id, PricebookEntryId = pbe.Id, UnitPrice = 20000
);
insert li1;

opp1.StageName = 'Contract Sent';
update opp1;

Product2 checkProd = [SELECT Car_Status__c, Reserved_Sold_Opportunity__c FROM Product2 WHERE Id = :prod.Id];
System.debug('=== ПРОВЕРКА 1: статус машины после Contract Sent ===');
System.debug('Car_Status__c = ' + checkProd.Car_Status__c);
System.debug('Reserved_Sold_Opportunity__c = ' + checkProd.Reserved_Sold_Opportunity__c);
System.debug('opp1.Id (для сравнения) = ' + opp1.Id);

Opportunity opp2 = new Opportunity(
    Name = 'DEBUG Opp2', AccountId = acc.Id,
    StageName = 'Prospecting', CloseDate = Date.today().addDays(20)
);
insert opp2;

OpportunityLineItem li2 = new OpportunityLineItem(
    OpportunityId = opp2.Id, PricebookEntryId = pbe.Id, UnitPrice = 20000
);
insert li2;

Opportunity checkOpp2 = [SELECT Has_Car_Conflict__c FROM Opportunity WHERE Id = :opp2.Id];
System.debug('=== ПРОВЕРКА 2: конфликт на opp2 ===');
System.debug('Has_Car_Conflict__c = ' + checkOpp2.Has_Car_Conflict__c);

delete li2;
delete opp2;
delete li1;
delete opp1;
delete pbe;
delete prod;
delete acc;





// Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
// email.setToAddresses(new String[] { 'tktn78@gmail.com' });
// email.setSubject('Test email from Salesforce');
// email.setPlainTextBody('This is a test.');
// Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
// System.debug('Success: ' + results[0].isSuccess());
// if (!results[0].isSuccess()) {
//     for (Messaging.SendEmailError err : results[0].getErrors()) {
//         System.debug('Error: ' + err.getMessage());
//     }
// }