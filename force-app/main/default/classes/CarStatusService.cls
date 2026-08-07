public without sharing class CarStatusService {

    public class CarStatusServiceException extends Exception {}
    private static Id soldRecordTypeId;

    private static Id getSoldRecordTypeId() {
        if (soldRecordTypeId == null) {
            List<RecordType> rtList = [
                SELECT Id FROM RecordType
                WHERE SObjectType = 'Product2' AND DeveloperName = 'Sold'
                LIMIT 1
            ];
            if (!rtList.isEmpty()) {
                soldRecordTypeId = rtList[0].Id;
            }
        }
        return soldRecordTypeId;
    }

    public static void handleStageChange(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {

        
        Set<Id> oppIdsToProcess = new Set<Id>();
        for (Opportunity opp : newOpps) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.StageName != oldOpp.StageName) {
                oppIdsToProcess.add(opp.Id);
            }
        }

        if (oppIdsToProcess.isEmpty()) {
            return;
        }

        List<OpportunityLineItem> lineItems = [
            SELECT OpportunityId, PricebookEntry.Product2Id
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIdsToProcess
        ];

        Map<Id, Set<Id>> productIdsByOpp = new Map<Id, Set<Id>>();
        for (OpportunityLineItem oli : lineItems) {
            if (!productIdsByOpp.containsKey(oli.OpportunityId)) {
                productIdsByOpp.put(oli.OpportunityId, new Set<Id>());
            }
            productIdsByOpp.get(oli.OpportunityId).add(oli.PricebookEntry.Product2Id);
        }

        Map<Id, Product2> productsToUpdateMap = new Map<Id, Product2>();
        Set<Id> allTouchedProductIds = new Set<Id>();
        Id soldRtId = getSoldRecordTypeId();

        for (Id oppId : oppIdsToProcess) {
            Opportunity opp = null;
            for (Opportunity o : newOpps) {
                if (o.Id == oppId) {
                    opp = o;
                }
            }
            Opportunity oldOpp = oldMap.get(oppId);
            Set<Id> productIds = productIdsByOpp.get(oppId);

            if (productIds == null || productIds.isEmpty()) {
                continue; 
            }

            for (Id productId : productIds) {
                allTouchedProductIds.add(productId);
                Product2 prodUpdate = new Product2(Id = productId);

                if (opp.StageName == 'Contract Sent') {
                    prodUpdate.Car_Status__c = 'Reserved';
                    prodUpdate.Reserved_Sold_Opportunity__c = oppId;
                    productsToUpdateMap.put(productId, prodUpdate);

                } else if (opp.StageName == 'Close Won') {
                    prodUpdate.Car_Status__c = 'Sold';
                    prodUpdate.Reserved_Sold_Opportunity__c = oppId;
                    if (soldRtId != null) {
                        prodUpdate.RecordTypeId = soldRtId;
                    }
                    productsToUpdateMap.put(productId, prodUpdate);

                } else if (opp.StageName == 'Close Lost') {
                    prodUpdate.Car_Status__c = 'Available';
                    prodUpdate.Reserved_Sold_Opportunity__c = null;
                    productsToUpdateMap.put(productId, prodUpdate);

                } else if (oldOpp.StageName == 'Contract Sent') {
                    prodUpdate.Car_Status__c = 'Available';
                    prodUpdate.Reserved_Sold_Opportunity__c = null;
                    productsToUpdateMap.put(productId, prodUpdate);
                }
            }
        }

        List<Product2> productsToUpdate = productsToUpdateMap.values();

if (!productsToUpdate.isEmpty()) {
    updateProductsSafely(productsToUpdate);
}

deactivatePriceBookEntriesForSoldCars(productsToUpdate);
reactivatePriceBookEntriesForAvailableCars(productsToUpdate);


        if (!allTouchedProductIds.isEmpty()) {
            recalcConflictsForProducts(allTouchedProductIds);
        }
    }

    private static void deactivatePriceBookEntriesForSoldCars(List<Product2> updatedProducts) {
        Set<Id> soldProductIds = new Set<Id>();
        for (Product2 p : updatedProducts) {
            if (p.Car_Status__c == 'Sold') {
                soldProductIds.add(p.Id);
            }
        }
        if (soldProductIds.isEmpty()) {
            return;
        }

        List<PricebookEntry> entries = [
            SELECT Id, IsActive FROM PricebookEntry
            WHERE Product2Id IN :soldProductIds AND IsActive = true
        ];
        if (entries.isEmpty()) {
            return;
        }
        for (PricebookEntry pbe : entries) {
            pbe.IsActive = false;
        }
        updatePriceBookEntriesSafely(entries);
    }

    private static void reactivatePriceBookEntriesForAvailableCars(List<Product2> updatedProducts) {
        Set<Id> availableProductIds = new Set<Id>();
        for (Product2 p : updatedProducts) {
            if (p.Car_Status__c == 'Available') {
                availableProductIds.add(p.Id);
            }
        }
        if (availableProductIds.isEmpty()) {
            return;
        }

        List<PricebookEntry> entries = [
            SELECT Id, IsActive FROM PricebookEntry
            WHERE Product2Id IN :availableProductIds AND IsActive = false
        ];
        if (entries.isEmpty()) {
            return;
        }
        for (PricebookEntry pbe : entries) {
            pbe.IsActive = true;
        }
        updatePriceBookEntriesSafely(entries);
    }

    public static void recalcConflictsForProducts(Set<Id> productIds) {
        if (productIds.isEmpty()) {
            return;
        }
        List<OpportunityLineItem> items = [
            SELECT OpportunityId
            FROM OpportunityLineItem
            WHERE PricebookEntry.Product2Id IN :productIds
        ];
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : items) {
            oppIds.add(oli.OpportunityId);
        }
        recalcConflictsForOpportunities(oppIds);
    }

    public static void recalcConflictsForOpportunities(Set<Id> oppIds) {
        if (oppIds.isEmpty()) {
            return;
        }

        List<OpportunityLineItem> items = [
            SELECT OpportunityId, PricebookEntry.Product2.Car_Status__c,
                   PricebookEntry.Product2.Reserved_Sold_Opportunity__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];

        Map<Id, Boolean> conflictByOpp = new Map<Id, Boolean>();
        for (Id oppId : oppIds) {
            conflictByOpp.put(oppId, false);
        }

        for (OpportunityLineItem oli : items) {
            String status = oli.PricebookEntry.Product2.Car_Status__c;
            Id ownerOppId = oli.PricebookEntry.Product2.Reserved_Sold_Opportunity__c;

            Boolean isProblem = (status == 'Reserved' || status == 'Sold')
                                  && ownerOppId != null
                                  && ownerOppId != oli.OpportunityId;

            if (isProblem) {
                conflictByOpp.put(oli.OpportunityId, true);
            }
        }

        List<Opportunity> toUpdate = new List<Opportunity>();
        for (Id oppId : conflictByOpp.keySet()) {
            toUpdate.add(new Opportunity(
                Id = oppId,
                Has_Car_Conflict__c = conflictByOpp.get(oppId)
            ));
        }

        updateOpportunitiesSafely(toUpdate);
    }


    private static void updateProductsSafely(List<Product2> records) {
        if (records.isEmpty()) {
            return;
        }
        Savepoint sp = Database.setSavepoint();
        try {
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, records);
            Database.SaveResult[] results = Database.update(decision.getRecords(), false);
            checkForErrors(results, 'Product2');
        } catch (Exception e) {
            Database.rollback(sp);
            throw new CarStatusServiceException('Failed to update cars: ' + e.getMessage());
        }
    }

    private static void updatePriceBookEntriesSafely(List<PricebookEntry> records) {
        if (records.isEmpty()) {
            return;
        }
        Savepoint sp = Database.setSavepoint();
        try {
            Database.SaveResult[] results = Database.update(records, false);
            checkForErrors(results, 'PricebookEntry');
        } catch (Exception e) {
            Database.rollback(sp);
            throw new CarStatusServiceException('Failed to update price book entries: ' + e.getMessage());
        }
    }

    // private static void updateOpportunitiesSafely(List<Opportunity> records) {
    //     if (records.isEmpty()) {
    //         return;
    //     }
    //     Savepoint sp = Database.setSavepoint();
    //     try {
    //         SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, records);
    //         Database.SaveResult[] results = Database.update(decision.getRecords(), false);
    //         checkForErrors(results, 'Opportunity');
    //     } catch (Exception e) {
    //         Database.rollback(sp);
    //         throw new CarStatusServiceException('Failed to update opportunities: ' + e.getMessage());
    //     }
    // }
private static void updateOpportunitiesSafely(List<Opportunity> records) {
    if (records.isEmpty()) {
        return;
    }
    Savepoint sp = Database.setSavepoint();
    try {
        // ВРЕМЕННО убрали stripInaccessible для диагностики
        Database.SaveResult[] results = Database.update(records, false);
        checkForErrors(results, 'Opportunity');
    } catch (Exception e) {
        Database.rollback(sp);
        throw new CarStatusServiceException('Failed to update opportunities: ' + e.getMessage());
    }
}
    private static void checkForErrors(Database.SaveResult[] results, String objectName) {
        List<String> errors = new List<String>();
        for (Database.SaveResult r : results) {
            if (!r.isSuccess()) {
                for (Database.Error err : r.getErrors()) {
                    errors.add(err.getMessage());
                }
            }
        }
        if (!errors.isEmpty()) {
            throw new CarStatusServiceException('Errors on ' + objectName + ': ' + String.join(errors, '; '));
        }
    }
}