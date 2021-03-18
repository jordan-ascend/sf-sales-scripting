/**
 * Note to come back and see if we still need this trigger handler and related trigger, OpportunityTrigger.
 */
public with sharing class OpportunityTriggerHandler {

    // public static void breforeUpdate(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
        // for(Id oppId: oldOpps.keySet()) {
        //     if(oldOpps.get(oppId).get('StageName') != newOpps.get(oppId).get('StageName')) {
        //         MetricObjectHandler.handleMetricObject((Opportunity)oldOpps.get(oppId));
        //     }
        // }
    // }

    // public static void afterInsert(Map<Id,SObject> newOpps) {

    // }

    public static void afterUpdate(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
        firePlatformEvents(oldOpps, newOpps);
        // updateMetricObject(oldOpps, newOpps);
        // updateScriptJunctionObject(oldOpps, newOpps);
    }

    @testVisible private static List<Opportunity_Listen__e> events = new List<Opportunity_Listen__e>();
    private static void firePlatformEvents(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
        events.clear();

        for(Id oppId: oldOpps.keySet()) {
            if(oldOpps.get(oppId).get('StageName') != newOpps.get(oppId).get('StageName')) {
                MetricObjectHandler.handleMetricObject((Opportunity)oldOpps.get(oppId), (Opportunity)newOpps.get(oppId));

                Opportunity_Listen__e ol = new Opportunity_Listen__e(
                    Message__c = 'Stage updated.',
                    Stage__c = (String)newOpps.get(oppId).get('StageName'),
                    OpportunityId__c = String.valueOf(oppId)
                );
                events.add(ol);
            }
        }
        List<Database.SaveResult> saveResults = Eventbus.publish(events);
        for(Database.SaveResult sr: saveResults) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event. ID: ' + sr.getId());
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                                err.getStatusCode() +
                                ' - ' +
                                err.getMessage());
                }
            }
        }
        
    }

    // private static void updateMetricObject(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
    //     System.debug(newOpps.keyset());
    //     System.debug(oldOpps.keyset());
    //     List<Script_Metric__c> metrics;
    //     if(
    //         Script_Metric__c.SObjectType.getDescribe().isAccessible() &&
    //         Schema.SObjectType.Script_Metric__c.fields.Opportunity__c.isAccessible() &&
    //         Schema.SObjectType.Script_Metric__c.fields.Opportunity_Won__c.isAccessible()
    //     ) {
    //         metrics = [SELECT Opportunity__c, Opportunity_Won__c FROM Script_Metric__c WHERE Opportunity__c IN :newOpps.keyset()];
    //     }
    //     System.debug(metrics);
    //     for(Script_Metric__c metric: metrics) {
    //         Opportunity opp = (Opportunity)newOpps.get(metric.Opportunity__c);
    //         if(opp == null) {
    //             continue;
    //         }
    //         if(opp.StageName == 'Closed Won') {
    //             metric.Opportunity_Won__c = true;
    //         } else {
    //             metric.Opportunity_Won__c = false;
    //         }
    //     }
    //     if(Script_Metric__c.sObjectType.getDescribe().isUpdateable()) {
    //         update metrics;
    //     }
    // }

    // private static void updateScriptJunctionObject(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
    //     List<Id> oppIds = new List<Id>();
    //     oppIds.addAll(oldOpps.keySet());
    //     Date d = Date.today();
    //     List<Opporunity_Script_Junction__c> junctions;
    //     if(
    //         Opporunity_Script_Junction__c.SObjectType.getDescribe().isAccessible() &&
    //         Schema.SObjectType.Opporunity_Script_Junction__c.fields.Opportunity__c.isAccessible()
    //     ) {
    //         junctions = [SELECT Opportunity__c FROM Opporunity_Script_Junction__c WHERE Opportunity__c IN :oppIds];
    //     }
        
    //     for(Opporunity_Script_Junction__c j: junctions) {
    //         System.debug(j.Id);
    //         System.debug(j.Opportunity__c);
    //         System.debug(oldOpps.get(j.Opportunity__c).get('StageName'));
    //         System.debug(newOpps.get(j.Opportunity__c).get('StageName'));
    //         if(oldOpps.get(j.Opportunity__c).get('StageName') != 'Closed Won' && newOpps.get(j.Opportunity__c).get('StageName') == 'Closed Won') {
    //             System.debug('updating date won');
    //             j.Date_Won__c = d;
    //         }
    //     }
    //     if(Opporunity_Script_Junction__c.sObjectType.getDescribe().isUpdateable()) {
    //         update junctions;
    //     }
    // }
}
