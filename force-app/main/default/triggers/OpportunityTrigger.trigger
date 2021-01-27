/**
 * Note to come back and see if we still need this trigger and related handler, OpportunityTriggerHandler.
 */
trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if(Trigger.isInsert) {
        OpportunityTriggerHandler.afterInsert(Trigger.newMap);
    }
    if(Trigger.isUpdate) {
        OpportunityTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.oldMap);
    }
}