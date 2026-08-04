@isTest
private class OpportunityLineItemTriggerHandlerTest {

    @TestSetup
static void setupData() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Product2 prod = new Product2(
        Name = 'Test Car',
        IsActive = true,
        Brand__c = 'Toyota',
        Model__c = 'Corolla',
        VIN_Number__c = 'TESTVIN123456789',
        Condition__c = 'New',
        Mileage__c = 0
    );
    insert prod;

    Id standardPBId = Test.getStandardPricebookId();
    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = standardPBId,
        Product2Id = prod.Id,
        UnitPrice = 20000,
        IsActive = true
    );
    insert pbe;

    Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        AccountId = acc.Id,
        StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30)
    );
    insert opp;
}

    @isTest
    static void testQuantityDefaultsToOneOnInsert() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            UnitPrice = 20000
            // Quantity сознательно не указана - должна проставиться автоматически
        );

        Test.startTest();
        insert oli;
        Test.stopTest();

        OpportunityLineItem inserted = [SELECT Quantity FROM OpportunityLineItem WHERE Id = :oli.Id];
        System.assertEquals(1, inserted.Quantity, 'Quantity should default to 1');
    }

    @isTest
    static void testQuantityOtherThanOneThrowsErrorOnInsert() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            UnitPrice = 20000,
            Quantity = 3
        );

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            insert oli;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Quantity must be exactly 1'), 'Error message should mention quantity restriction');
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Expected an exception when quantity is not 1');
    }

    @isTest
    static void testQuantityCannotBeChangedOnUpdate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            UnitPrice = 20000
        );
        insert oli;

        oli.Quantity = 5;

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            update oli;
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Expected an exception when trying to update quantity to non-1 value');
    }

    @isTest
    static void testBulkInsertMultipleLineItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        List<OpportunityLineItem> items = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 50; i++) {
            items.add(new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = pbe.Id,
                UnitPrice = 20000
            ));
        }

        Test.startTest();
        insert items;
        Test.stopTest();

        List<OpportunityLineItem> inserted = [SELECT Quantity FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertEquals(50, inserted.size(), 'All 50 records should be inserted');
        for (OpportunityLineItem item : inserted) {
            System.assertEquals(1, item.Quantity, 'Every item should have quantity 1');
        }
    }
}