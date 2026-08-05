@isTest
public class TestDataFactory {

    public static Account createAccount() {
    Account acc = new Account(
        Name = 'Test Account ' + Math.random(),
        BillingStreet = '123 Test St',
        BillingCity = 'Stuttgart',
        BillingPostalCode = '70173',
        BillingCountry = 'Germany'
    );
    insert acc;
    return acc;
}

    public static Product2 createProduct(String condition) {
        Product2 prod = new Product2(
            Name = 'Test Car ' + Math.random(),
            IsActive = true,
            Brand__c = 'Toyota',
            Model__c = 'Corolla',
            VIN_Number__c = 'VIN' + String.valueOf(Math.random()).right(15),
            Condition__c = condition,
            Mileage__c = 0
        );
        insert prod;
        return prod;
    }

    public static PricebookEntry createPricebookEntry(Id productId, Decimal price) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = productId,
            UnitPrice = price,
            IsActive = true
        );
        insert pbe;
        return pbe;
    }

    public static Opportunity createOpportunity(Id accountId, String stageName, Date closeDate) {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp ' + Math.random(),
            AccountId = accountId,
            StageName = stageName,
            CloseDate = closeDate
        );
        insert opp;
        return opp;
    }

    public static OpportunityLineItem createLineItem(Id opportunityId, Id pricebookEntryId, Decimal price) {
    OpportunityLineItem oli = new OpportunityLineItem(
        OpportunityId = opportunityId,
        PricebookEntryId = pricebookEntryId,
        UnitPrice = price,
        Quantity = 1
    );
    insert oli;
    return oli;
}

    public static Planned_Sales__c createPlannedSales(Integer year, Integer month, String carType) {
        Planned_Sales__c ps = new Planned_Sales__c(
            Year__c = year,
            Month__c = month,
            Car_Type__c = carType,
            Planned_Count__c = 10,
            Planned_Total_Amount__c = 100000
        );
        insert ps;
        return ps;
    }
}