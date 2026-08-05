public class OpportunityLineItemTriggerHandler extends TriggerHandler {

    protected override void beforeInsert() {
        validateAndSetQuantity(Trigger.new);
    }

    protected override void beforeUpdate() {
        validateAndSetQuantity(Trigger.new);
    }

    protected override String getHandlerName() {
    return 'OpportunityLineItemTriggerHandler';
}

    private void validateAndSetQuantity(List<OpportunityLineItem> items) {
        for (OpportunityLineItem oli : items) {
            if (oli.Quantity == null) {
                oli.Quantity = 1;
            } else if (oli.Quantity != 1) {
                oli.Quantity.addError('Quantity must be exactly 1 for each car. Each car sale must be tracked individually.');
            }
        }
    }
}