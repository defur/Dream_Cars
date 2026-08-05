@isTest
private class PlannedSalesServiceTest {

    @isTest
    static void testPlannedSalesCreatedAfterClosedWonOpp_countsPopulate() {
        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('New');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 25000);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Close Won', Date.newInstance(2026, 8, 15));
        TestDataFactory.createLineItem(opp.Id, pbe.Id, 25000);

        Test.startTest();
        Planned_Sales__c ps = TestDataFactory.createPlannedSales(2026, 8, 'New');
        Test.stopTest();

        Planned_Sales__c result = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Id = :ps.Id];
        System.assertEquals(1, result.Count_of_Cars_Sold__c, 'Should count 1 matching car');
        System.assertEquals(25000, result.Total_Amount_Earned__c, 'Should sum matching amount');
    }

    @isTest
    static void testNoMatchingOpportunities_fieldsAreZero() {
        Test.startTest();
        Planned_Sales__c ps = TestDataFactory.createPlannedSales(2030, 1, 'Used');
        Test.stopTest();

        Planned_Sales__c result = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Id = :ps.Id];
        System.assertEquals(0, result.Count_of_Cars_Sold__c, 'No matches should give 0');
        System.assertEquals(0, result.Total_Amount_Earned__c, 'No matches should give 0');
    }

    @isTest
    static void testOpportunityBecomesClosedWon_triggersRecalc() {
        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('Used');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 15000);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Prospecting', Date.newInstance(2026, 9, 10));
        TestDataFactory.createLineItem(opp.Id, pbe.Id, 15000);

        Planned_Sales__c ps = TestDataFactory.createPlannedSales(2026, 9, 'Used');

        Planned_Sales__c before = [SELECT Count_of_Cars_Sold__c FROM Planned_Sales__c WHERE Id = :ps.Id];
        System.assertEquals(0, before.Count_of_Cars_Sold__c, 'Before close, should be 0');

        Test.startTest();
        opp.StageName = 'Close Won';
        update opp;
        Test.stopTest();

        Planned_Sales__c after = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Id = :ps.Id];
        System.assertEquals(1, after.Count_of_Cars_Sold__c, 'After close won, should count 1');
        System.assertEquals(15000, after.Total_Amount_Earned__c, 'Amount should match');
    }

    @isTest
    static void testDeletingClosedWonOpportunity_decrementsCounts() {
        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('New');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 30000);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Close Won', Date.newInstance(2026, 10, 5));
        TestDataFactory.createLineItem(opp.Id, pbe.Id, 30000);

        Planned_Sales__c ps = TestDataFactory.createPlannedSales(2026, 10, 'New');
        Planned_Sales__c before = [SELECT Count_of_Cars_Sold__c FROM Planned_Sales__c WHERE Id = :ps.Id];
        System.assertEquals(1, before.Count_of_Cars_Sold__c, 'Before delete, should be 1');

        Test.startTest();
        delete opp;
        Test.stopTest();

        Planned_Sales__c after = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Id = :ps.Id];
        System.assertEquals(0, after.Count_of_Cars_Sold__c, 'After delete, should be 0');
        System.assertEquals(0, after.Total_Amount_Earned__c, 'After delete, should be 0');
    }

    @isTest
    static void testBulkClosedWonOpportunities() {
        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('New');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 20000);

        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 20; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.newInstance(2026, 11, 1)
            ));
        }
        insert opps;

        List<OpportunityLineItem> items = new List<OpportunityLineItem>();
        for (Opportunity o : opps) {
            items.add(new OpportunityLineItem(
                OpportunityId = o.Id,
                PricebookEntryId = pbe.Id,
                UnitPrice = 20000
            ));
        }
        insert items;

        Planned_Sales__c ps = TestDataFactory.createPlannedSales(2026, 11, 'New');

        Test.startTest();
        for (Opportunity o : opps) {
            o.StageName = 'Close Won';
        }
        update opps;
        Test.stopTest();

        Planned_Sales__c result = [SELECT Count_of_Cars_Sold__c, Total_Amount_Earned__c FROM Planned_Sales__c WHERE Id = :ps.Id];
        System.assertEquals(20, result.Count_of_Cars_Sold__c, 'Should count all 20');
        System.assertEquals(400000, result.Total_Amount_Earned__c, 'Should sum all amounts');
    }

    @isTest
    static void testTriggerCanBeDisabled() {
        TriggerHandler.isTriggerDisabled = true;

        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('New');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 10000);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Close Won', Date.newInstance(2026, 12, 1));
        TestDataFactory.createLineItem(opp.Id, pbe.Id, 10000);

        Test.startTest();
        Planned_Sales__c ps = TestDataFactory.createPlannedSales(2026, 12, 'New');
        Test.stopTest();

        Planned_Sales__c result = [SELECT Count_of_Cars_Sold__c FROM Planned_Sales__c WHERE Id = :ps.Id];
        System.assertEquals(null, result.Count_of_Cars_Sold__c, 'Trigger disabled, should not recalc, field stays null');

        TriggerHandler.isTriggerDisabled = false;
    }
}