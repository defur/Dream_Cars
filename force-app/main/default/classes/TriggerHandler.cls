public virtual class TriggerHandler {

    public enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, AFTER_UNDELETE
    }

    public static Boolean isTriggerDisabled = false;

    public void run() {
        if (isTriggerDisabled) {
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