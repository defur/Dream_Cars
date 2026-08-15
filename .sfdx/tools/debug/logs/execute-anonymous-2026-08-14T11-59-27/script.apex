Account acc = new Account(
    Name = 'DEBUG2 Account',
    BillingStreet = '1 Test', BillingCity = 'Test', BillingCountry = 'Germany'
);
insert acc;

Product2 prod = new Product2(
    Name = 'DEBUG2 Car', IsActive = true,
    Brand__c = 'Toyota', Model__c = 'Corolla',
    VIN_Number__c = 'DEBUG2VIN123456789', Condition__c = 'New', Mileage__c = 0
);
insert prod;

Id standardPbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;

PricebookEntry pbe = new PricebookEntry(
    Pricebook2Id = standardPbId,
    Product2Id = prod.Id, UnitPrice = 20000, IsActive = true
);
insert pbe;

Opportunity opp = new Opportunity(
    Name = 'DEBUG2 Opp', AccountId = acc.Id,
    StageName = 'Prospecting', CloseDate = Date.today().addDays(5)
);
insert opp;

OpportunityLineItem li = new OpportunityLineItem(
    OpportunityId = opp.Id, PricebookEntryId = pbe.Id, UnitPrice = 20000
);
insert li;

System.debug('=== ДО смены Stage ===');
System.debug('Product Id = ' + prod.Id);

opp.StageName = 'Close Won';
update opp;

Product2 checkProd = [SELECT Car_Status__c, RecordTypeId, Reserved_Sold_Opportunity__c FROM Product2 WHERE Id = :prod.Id];
System.debug('=== ПОСЛЕ смены Stage на Close Won ===');
System.debug('Car_Status__c = ' + checkProd.Car_Status__c);
System.debug('RecordTypeId = ' + checkProd.RecordTypeId);
System.debug('Reserved_Sold_Opportunity__c = ' + checkProd.Reserved_Sold_Opportunity__c);

PricebookEntry checkPbe = [SELECT IsActive FROM PricebookEntry WHERE Id = :pbe.Id];
System.debug('PricebookEntry IsActive = ' + checkPbe.IsActive);

// Чистим
delete li;
delete opp;
delete pbe;
delete prod;
delete acc;