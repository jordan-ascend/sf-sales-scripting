/**
 * Note to come back and see if we still need this trigger and related handler, OpportunityTriggerHandler.
 */
trigger OpportunityTrigger on Opportunity (before update, after insert, after update) {
    // if(Trigger.isInsert) {
    //     OpportunityTriggerHandler.afterInsert(Trigger.newMap);
    // }
    if(Trigger.isUpdate) {
        if(Trigger.isBefore) {
            // OpportunityTriggerHandler.breforeUpdate(Trigger.oldMap);
        } else {
            OpportunityTriggerHandler.afterUpdate(Trigger.oldMap, Trigger.newMap);
        }
    }
}