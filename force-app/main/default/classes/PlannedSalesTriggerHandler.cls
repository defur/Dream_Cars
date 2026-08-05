public class PlannedSalesTriggerHandler extends TriggerHandler {

    protected override String getHandlerName() {
        return 'PlannedSalesTriggerHandler';
    }
    
    private static Boolean isRecalculating = false;

    protected override void afterInsert() {
        recalc();
    }

    protected override void afterUpdate() {
        recalc();
    }

    private void recalc() {
        if (isRecalculating) {
            return; 
        }

        isRecalculating = true;
        try {
            Set<Id> ids = new Set<Id>();
            for (SObject rec : Trigger.new) {
                ids.add(rec.Id);
            }
            PlannedSalesService.recalculateForPlannedSales(ids);
        } finally {
            isRecalculating = false;
        }
    }
}