public class OpportunityTriggerHandler extends TriggerHandler {

    protected override String getHandlerName() {
        return 'OpportunityTriggerHandler';
    }

    private static Set<String> keysFromDeletedOpportunities = new Set<String>();

    protected override void beforeDelete() {
        captureKeysForDeletedOpportunities((List<Opportunity>) Trigger.old);
    }

    protected override void afterDelete() {
        if (!keysFromDeletedOpportunities.isEmpty()) {
            PlannedSalesService.recalculateForKeys(keysFromDeletedOpportunities);
            keysFromDeletedOpportunities.clear();
        }
    }

    protected override void afterUpdate() {
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
        List<Opportunity> newList = (List<Opportunity>) Trigger.new;

        Set<Id> relevantOppIds = new Set<Id>();
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            Boolean becameClosedWon = opp.StageName == 'Close Won' && oldOpp.StageName != 'Close Won';
            Boolean wasClosedWon = oldOpp.StageName == 'Close Won' && opp.StageName != 'Close Won';
            Boolean closeDateChangedWhileWon = opp.StageName == 'Close Won' && opp.CloseDate != oldOpp.CloseDate;

            if (becameClosedWon || wasClosedWon || closeDateChangedWhileWon) {
                relevantOppIds.add(opp.Id);
            }
        }

        if (!relevantOppIds.isEmpty()) {
            Map<Id, Set<String>> carTypesByOppId = new Map<Id, Set<String>>();
            for (OpportunityLineItem oli : [
                SELECT OpportunityId, PricebookEntry.Product2.Condition__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN :relevantOppIds
            ]) {
                if (oli.PricebookEntry.Product2.Condition__c == null) {
                    continue;
                }
                if (!carTypesByOppId.containsKey(oli.OpportunityId)) {
                    carTypesByOppId.put(oli.OpportunityId, new Set<String>());
                }
                carTypesByOppId.get(oli.OpportunityId).add(oli.PricebookEntry.Product2.Condition__c);
            }

            Set<String> affectedKeys = new Set<String>();
            for (Id oppId : relevantOppIds) {
                Opportunity opp = (Opportunity) Trigger.newMap.get(oppId);
                Opportunity oldOpp = oldMap.get(oppId);
                Set<String> carTypes = carTypesByOppId.get(oppId);
                if (carTypes == null) {
                    continue;
                }
                for (String carType : carTypes) {
                    if (opp.CloseDate != null) {
                        affectedKeys.add(buildKey(opp.CloseDate, carType));
                    }
                    if (oldOpp.CloseDate != null && oldOpp.CloseDate != opp.CloseDate) {
                        affectedKeys.add(buildKey(oldOpp.CloseDate, carType));
                    }
                }
            }

            if (!affectedKeys.isEmpty()) {
                PlannedSalesService.recalculateForKeys(affectedKeys);
            }
        }

        // Новая часть для Task 2.3
        CarStatusService.handleStageChange(newList, oldMap);
        
    }

    private void captureKeysForDeletedOpportunities(List<Opportunity> deletedOpps) {
        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : deletedOpps) {
            if (opp.StageName == 'Close Won') {
                oppIds.add(opp.Id);
            }
        }
        if (oppIds.isEmpty()) {
            return;
        }

        for (OpportunityLineItem oli : [
            SELECT Opportunity.CloseDate, PricebookEntry.Product2.Condition__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ]) {
            if (oli.Opportunity.CloseDate == null || oli.PricebookEntry.Product2.Condition__c == null) {
                continue;
            }
            keysFromDeletedOpportunities.add(buildKey(oli.Opportunity.CloseDate, oli.PricebookEntry.Product2.Condition__c));
        }
    }

    private String buildKey(Date d, String carType) {
        return String.valueOf(d.year()) + '-' + String.valueOf(d.month()) + '-' + carType;
    }
}