trigger PlannedSalesTrigger on Planned_Sales__c (after insert, after update) {
    new PlannedSalesTriggerHandler().run();
}