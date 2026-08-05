public virtual class TriggerHandler {

    public static Boolean isTriggerDisabled = false;

    protected virtual String getHandlerName() {
        return 'TriggerHandler';
    }

    private Boolean isDisabledByMetadata() {
        Trigger_Setting__mdt setting = Trigger_Setting__mdt.getInstance(getHandlerName());
        if (setting == null) {
            return false;
        }
        return setting.Is_Enabled__c == false;
    }

    public void run() {
        if (isTriggerDisabled || isDisabledByMetadata()) {
            return;
        }

        if (Trigger.isBefore && Trigger.isInsert) {
            beforeInsert();
        } else if (Trigger.isBefore && Trigger.isUpdate) {
            beforeUpdate();
        } else if (Trigger.isBefore && Trigger.isDelete) {
            beforeDelete();
        } else if (Trigger.isAfter && Trigger.isInsert) {
            afterInsert();
        } else if (Trigger.isAfter && Trigger.isUpdate) {
            afterUpdate();
        } else if (Trigger.isAfter && Trigger.isDelete) {
            afterDelete();
        } else if (Trigger.isAfter && Trigger.isUndelete) {
            afterUndelete();
        }
    }

    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}
}