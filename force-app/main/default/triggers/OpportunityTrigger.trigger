trigger OpportunityTrigger on Opportunity (before delete, after update, after delete) {
    new OpportunityTriggerHandler().run();
}