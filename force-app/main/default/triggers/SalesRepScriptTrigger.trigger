trigger SalesRepScriptTrigger on Sales_Rep_Script__c (before insert, before update) {
    if(Trigger.isInsert) {
        SalesRepScriptTriggerHandler.beforeInsert(Trigger.new);
    }
    if(Trigger.isUpdate) {
        SalesRepScriptTriggerHandler.beforeUpdate(Trigger.oldMap, Trigger.new);
    }
}