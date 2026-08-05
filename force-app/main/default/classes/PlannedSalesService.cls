public without sharing class PlannedSalesService {

    public class PlannedSalesServiceException extends Exception {}

    public static void recalculateForPlannedSales(Set<Id> plannedSalesIds) {
        List<Planned_Sales__c> plannedSalesList = [
            SELECT Id, Year__c, Month__c, Car_Type__c
            FROM Planned_Sales__c
            WHERE Id IN :plannedSalesIds
        ];
        recalculate(plannedSalesList);
    }

    public static void recalculateForKeys(Set<String> keys) {
        if (keys.isEmpty()) {
            return;
        }
        List<Planned_Sales__c> allPlannedSales = [
            SELECT Id, Year__c, Month__c, Car_Type__c
            FROM Planned_Sales__c
        ];
        List<Planned_Sales__c> toRecalc = new List<Planned_Sales__c>();
        for (Planned_Sales__c ps : allPlannedSales) {
            if (keys.contains(buildKey(ps.Year__c, ps.Month__c, ps.Car_Type__c))) {
                toRecalc.add(ps);
            }
        }
        recalculate(toRecalc);
    }

    private static void recalculate(List<Planned_Sales__c> plannedSalesList) {
        if (plannedSalesList.isEmpty()) {
            return;
        }

        List<OpportunityLineItem> lineItems = [
            SELECT TotalPrice, Opportunity.CloseDate, PricebookEntry.Product2.Condition__c
            FROM OpportunityLineItem
            WHERE Opportunity.StageName = 'Close Won'
        ];

        Map<String, Integer> countMap = new Map<String, Integer>();
        Map<String, Decimal> amountMap = new Map<String, Decimal>();

        for (OpportunityLineItem oli : lineItems) {
            if (oli.Opportunity.CloseDate == null || oli.PricebookEntry.Product2.Condition__c == null) {
                continue;
            }
            String key = buildKey(
                oli.Opportunity.CloseDate.year(),
                oli.Opportunity.CloseDate.month(),
                oli.PricebookEntry.Product2.Condition__c
            );
            countMap.put(key, (countMap.containsKey(key) ? countMap.get(key) : 0) + 1);
            Decimal price = oli.TotalPrice == null ? 0 : oli.TotalPrice;
            amountMap.put(key, (amountMap.containsKey(key) ? amountMap.get(key) : 0) + price);
        }

        List<Planned_Sales__c> toUpdate = new List<Planned_Sales__c>();
        for (Planned_Sales__c ps : plannedSalesList) {
            String key = buildKey(ps.Year__c, ps.Month__c, ps.Car_Type__c);
            toUpdate.add(new Planned_Sales__c(
                Id = ps.Id,
                Count_of_Cars_Sold__c = countMap.containsKey(key) ? countMap.get(key) : 0,
                Total_Amount_Earned__c = amountMap.containsKey(key) ? amountMap.get(key) : 0
            ));
        }

        updateSafely(toUpdate);
    }

    private static void updateSafely(List<Planned_Sales__c> records) {
    if (records.isEmpty()) {
        return;
    }

    Savepoint sp = Database.setSavepoint();
    try {
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, records);
        List<SObject> safeRecords = decision.getRecords();

        Database.SaveResult[] results = Database.update(safeRecords, false);
        List<String> errorMessages = new List<String>();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                for (Database.Error err : result.getErrors()) {
                    errorMessages.add(err.getMessage());
                }
            }
        }
        if (!errorMessages.isEmpty()) {
            throw new PlannedSalesServiceException('Update failed: ' + String.join(errorMessages, '; '));
        }
    } catch (Exception e) {
        Database.rollback(sp);
        throw new PlannedSalesServiceException('Failed to update Planned Sales: ' + e.getMessage());
    }
}
    private static String buildKey(Decimal year, Decimal month, String carType) {
        return buildKey(Integer.valueOf(year), Integer.valueOf(month), carType);
    }

    private static String buildKey(Integer year, Integer month, String carType) {
        return String.valueOf(year) + '-' + String.valueOf(month) + '-' + carType;
    }
}