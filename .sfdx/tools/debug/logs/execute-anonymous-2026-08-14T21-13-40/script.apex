Account acc = new Account(
    Name = 'DEBUG3 Account',
    BillingStreet = '1 Test', BillingCity = 'Test', BillingCountry = 'Germany'
);
insert acc;

Product2 prod = new Product2(
    Name = 'DEBUG3 Car', IsActive = true,
    Brand__c = 'Toyota', Model__c = 'Corolla',
    VIN_Number__c = 'DEBUG3VIN123456789', Condition__c = 'New', Mileage__c = 0
);
insert prod;

Id standardPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

PricebookEntry pbe = new PricebookEntry(
    Pricebook2Id = standardPbId,
    Product2Id = prod.Id, UnitPrice = 20000, IsActive = true
);
insert pbe;

Opportunity opp = new Opportunity(
    Name = 'DEBUG3 Opp', AccountId = acc.Id,
    StageName = 'Prospecting', CloseDate = Date.today().addDays(5)
);
insert opp;

OpportunityLineItem li = new OpportunityLineItem(
    OpportunityId = opp.Id, PricebookEntryId = pbe.Id, UnitPrice = 20000
);
insert li;

opp.StageName = 'Close Won';

try {
    update opp;
    System.debug('=== UPDATE УСПЕШЕН ===');
} catch (Exception e) {
    System.debug('=== UPDATE УПАЛ С ОШИБКОЙ ===');
    System.debug(e.getMessage());
}

Product2 checkProd = [SELECT Car_Status__c, RecordTypeId FROM Product2 WHERE Id = :prod.Id];
System.debug('Car_Status__c = ' + checkProd.Car_Status__c);

PricebookEntry checkPbe = [SELECT IsActive FROM PricebookEntry WHERE Id = :pbe.Id];
System.debug('PricebookEntry IsActive = ' + checkPbe.IsActive);