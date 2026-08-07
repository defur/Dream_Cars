trigger OpportunityLineItemTrigger on OpportunityLineItem (
    before insert, before update,
    after insert, after update, after delete, after undelete
) {
    new OpportunityLineItemTriggerHandler().run();
}