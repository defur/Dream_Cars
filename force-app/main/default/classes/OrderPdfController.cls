
public with sharing class OrderPdfController {

    private final Opportunity opp;


    public OrderPdfController(ApexPages.StandardController controller) {
        this.opp = (Opportunity) controller.getRecord();
    }


    public List<OpportunityLineItem> getLineItems() {
        return [
            SELECT Product2.Name, Quantity, UnitPrice, TotalPrice
            FROM OpportunityLineItem
            WHERE OpportunityId = :opp.Id
        ];
    }


    public Decimal getTotalAmount() {
        Decimal total = 0;
        for (OpportunityLineItem item : getLineItems()) {
            total += item.TotalPrice;
        }
        return total;
    }
}