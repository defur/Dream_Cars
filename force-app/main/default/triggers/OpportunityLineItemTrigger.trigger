trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update) {
    new OpportunityLineItemTriggerHandler().run();
}