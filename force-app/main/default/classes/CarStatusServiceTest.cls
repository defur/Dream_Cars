@isTest
private class CarStatusServiceTest {

    @isTest
    static void testContractSentSetsCarToReserved() {
        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('New');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 20000);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Negotiation/Review', Date.today().addDays(10));
        TestDataFactory.createLineItem(opp.Id, pbe.Id, 20000);

        Test.startTest();
        opp.StageName = 'Contract Sent';
        update opp;
        Test.stopTest();

        Product2 result = [SELECT Car_Status__c, Reserved_Sold_Opportunity__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('Reserved', result.Car_Status__c, 'Car should become Reserved');
        System.assertEquals(opp.Id, result.Reserved_Sold_Opportunity__c, 'Car should be tied to this opportunity');
    }

    @isTest
    static void testClosedWonSetsCarToSoldAndSwitchesRecordType() {
        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('New');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 20000);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Contract Sent', Date.today().addDays(5));
        TestDataFactory.createLineItem(opp.Id, pbe.Id, 20000);

        Test.startTest();
        opp.StageName = 'Close Won';
        update opp;
        Test.stopTest();

        Product2 result = [SELECT Car_Status__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('Sold', result.Car_Status__c, 'Car should become Sold');

        PricebookEntry pbeResult = [SELECT IsActive FROM PricebookEntry WHERE Id = :pbe.Id];
        System.assertEquals(false, pbeResult.IsActive, 'Price book entry should be deactivated');
    }

    @isTest
    static void testClosedLostReturnsCarToAvailable() {
        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('New');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 20000);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Contract Sent', Date.today().addDays(5));
        TestDataFactory.createLineItem(opp.Id, pbe.Id, 20000);

        Test.startTest();
        opp.StageName = 'Close Lost';
        update opp;
        Test.stopTest();

        Product2 result = [SELECT Car_Status__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('Available', result.Car_Status__c, 'Car should return to Available');
    }

    @isTest
    static void testMovingAwayFromContractSentReturnsCarToAvailable() {
        Account acc = TestDataFactory.createAccount();
        Product2 prod = TestDataFactory.createProduct('New');
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 20000);
        Opportunity opp = TestDataFactory.createOpportunity(acc.Id, 'Contract Sent', Date.today().addDays(5));
        TestDataFactory.createLineItem(opp.Id, pbe.Id, 20000);

        Test.startTest();
        opp.StageName = 'Negotiation/Review';
        update opp;
        Test.stopTest();

        Product2 result = [SELECT Car_Status__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals('Available', result.Car_Status__c, 'Car should return to Available');
    }

//     @isTest
//     static void testConflictFlagSetOnOtherOpportunity() {
//         Account acc = TestDataFactory.createAccount();
//         Product2 prod = TestDataFactory.createProduct('New');
//         PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 20000);

//         Opportunity opp1 = TestDataFactory.createOpportunity(acc.Id, 'Prospecting', Date.today().addDays(5));
//         TestDataFactory.createLineItem(opp1.Id, pbe.Id, 20000);
//         opp1.StageName = 'Contract Sent';
// update opp1;

//         Opportunity opp2 = TestDataFactory.createOpportunity(acc.Id, 'Prospecting', Date.today().addDays(20));

//         // Реактивируем PricebookEntry вручную, потому что после Reserved она ещё активна
//         // (мы деактивируем только при Sold), так что тут добавление пройдёт нормально.
//         Test.startTest();
//         OpportunityLineItem secondLine = new OpportunityLineItem(
//             OpportunityId = opp2.Id,
//             PricebookEntryId = pbe.Id,
//             UnitPrice = 20000
//         );
//         insert secondLine;
//         Test.stopTest();

//         Opportunity result = [SELECT Has_Car_Conflict__c FROM Opportunity WHERE Id = :opp2.Id];
//         System.assertEquals(true, result.Has_Car_Conflict__c, 'Opp2 should show a conflict since the car belongs to opp1');

//         Opportunity ownerOppResult = [SELECT Has_Car_Conflict__c FROM Opportunity WHERE Id = :opp1.Id];
//         System.assertEquals(false, ownerOppResult.Has_Car_Conflict__c, 'Owner opportunity should not show a conflict');
//     }

    @isTest
static void testCannotAddSoldCarToAnotherOpportunity() {
    Account acc = TestDataFactory.createAccount();
    Product2 prod = TestDataFactory.createProduct('New');
    PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 20000);

    Opportunity opp1 = TestDataFactory.createOpportunity(acc.Id, 'Prospecting', Date.today().addDays(5));
    TestDataFactory.createLineItem(opp1.Id, pbe.Id, 20000);

    opp1.StageName = 'Contract Sent';
    update opp1;

    opp1.StageName = 'Close Won';
    update opp1;

    Opportunity opp2 = TestDataFactory.createOpportunity(acc.Id, 'Prospecting', Date.today().addDays(20));

    Test.startTest();
    Boolean exceptionThrown = false;
    try {
        OpportunityLineItem secondLine = new OpportunityLineItem(
            OpportunityId = opp2.Id,
            PricebookEntryId = pbe.Id,
            UnitPrice = 20000
        );
        insert secondLine;
    } catch (DmlException e) {
        exceptionThrown = true;
    }
    Test.stopTest();

    System.assertEquals(true, exceptionThrown, 'Should not be able to add a sold car to another opportunity');

    Integer lineItemCount = [SELECT COUNT() FROM OpportunityLineItem WHERE OpportunityId = :opp2.Id];
    System.assertEquals(0, lineItemCount, 'No line item should actually be created for opp2');
}
//     @isTest
//     static void testConflictClearsWhenCarBecomesAvailableAgain() {
//         Account acc = TestDataFactory.createAccount();
//         Product2 prod = TestDataFactory.createProduct('New');
//         PricebookEntry pbe = TestDataFactory.createPricebookEntry(prod.Id, 20000);

//         Opportunity opp1 = TestDataFactory.createOpportunity(acc.Id, 'Prospecting', Date.today().addDays(5));
// TestDataFactory.createLineItem(opp1.Id, pbe.Id, 20000);
// opp1.StageName = 'Contract Sent';
// update opp1;

//         Opportunity opp2 = TestDataFactory.createOpportunity(acc.Id, 'Prospecting', Date.today().addDays(20));
//         OpportunityLineItem secondLine = new OpportunityLineItem(
//             OpportunityId = opp2.Id,
//             PricebookEntryId = pbe.Id,
//             UnitPrice = 20000
//         );
//         insert secondLine;

//         Opportunity beforeResult = [SELECT Has_Car_Conflict__c FROM Opportunity WHERE Id = :opp2.Id];
//         System.assertEquals(true, beforeResult.Has_Car_Conflict__c, 'Should have conflict initially');

//         Test.startTest();
//         opp1.StageName = 'Close Lost';
//         update opp1;
//         Test.stopTest();

//         Opportunity afterResult = [SELECT Has_Car_Conflict__c FROM Opportunity WHERE Id = :opp2.Id];
//         System.assertEquals(false, afterResult.Has_Car_Conflict__c, 'Conflict should clear once car is available again');
//     }

    @isTest
    static void testBulkStageChangesToContractSent() {
        Account acc = TestDataFactory.createAccount();

        List<Opportunity> opps = new List<Opportunity>();
        List<Product2> products = new List<Product2>();
        List<PricebookEntry> pbes = new List<PricebookEntry>();

        for (Integer i = 0; i < 20; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Car Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Negotiation/Review',
                CloseDate = Date.today().addDays(10)
            ));
        }
        insert opps;

        for (Integer i = 0; i < 20; i++) {
            products.add(new Product2(
                Name = 'Bulk Car ' + i,
                IsActive = true,
                Brand__c = 'Toyota',
                Model__c = 'Corolla',
                VIN_Number__c = 'VIN' + i + '000000000000',
                Condition__c = 'New',
                Mileage__c = 0
            ));
        }
        insert products;

        Id pbId = Test.getStandardPricebookId();
        for (Product2 p : products) {
            pbes.add(new PricebookEntry(
                Pricebook2Id = pbId,
                Product2Id = p.Id,
                UnitPrice = 20000,
                IsActive = true
            ));
        }
        insert pbes;

        List<OpportunityLineItem> items = new List<OpportunityLineItem>();
        for (Integer i = 0; i < 20; i++) {
            items.add(new OpportunityLineItem(
                OpportunityId = opps[i].Id,
                PricebookEntryId = pbes[i].Id,
                UnitPrice = 20000
            ));
        }
        insert items;

        Test.startTest();
        for (Opportunity o : opps) {
            o.StageName = 'Contract Sent';
        }
        update opps;
        Test.stopTest();

        List<Product2> results = [SELECT Car_Status__c FROM Product2 WHERE Id IN :products];
        for (Product2 p : results) {
            System.assertEquals('Reserved', p.Car_Status__c, 'Every car should become Reserved');
        }
    }
}