/**
 * Note to come back and see if we still need this trigger handler and related trigger, OpportunityTrigger.
 */
public class OpportunityTriggerHandler {
    public static void afterInsert(Map<Id,SObject> newOpps) {

    }

    public static void afterUpdate(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
        updateMetricObject(oldOpps, newOpps);
        updateScriptJunctionObject(oldOpps, newOpps);
        firePlatformEvents(oldOpps, newOpps);
    }

    private static void firePlatformEvents(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
        List<SObject> events = new List<SObject>();

        for(Id oppId: oldOpps.keySet()) {
            if(oldOpps.get(oppId).get('StageName') != newOpps.get(oppId).get('StageName')) {
                Opportunity_Listen__e ol = new Opportunity_Listen__e(
                    Message__c = 'Stage updated.',
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

    private static void updateMetricObject(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
        System.debug(newOpps.keyset());
        System.debug(oldOpps.keyset());
        List<Script_Metric__c> metrics = [SELECT Opportunity__c, Opportunity_Won__c FROM Script_Metric__c WHERE Opportunity__c IN :newOpps.keyset()];
        System.debug(metrics);
        for(Script_Metric__c metric: metrics) {
            Opportunity opp = (Opportunity)newOpps.get(metric.Opportunity__c);
            if(opp == null)
                continue;
            if(opp.StageName == 'Closed Won')
                metric.Opportunity_Won__c = true;
                else 
                metric.Opportunity_Won__c = false;
        }
        update metrics;
    }

    private static void updateScriptJunctionObject(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
        List<Id> oppIds = new List<Id>();
        oppIds.addAll(oldOpps.keySet());
        Date d = Date.today();
        List<Opporunity_Script_Junction__c> junctions = [SELECT Opportunity__c FROM Opporunity_Script_Junction__c WHERE Opportunity__c IN :oppIds];

        
        for(Opporunity_Script_Junction__c j: junctions) {
            System.debug(j.Id);
            System.debug(j.Opportunity__c);
            System.debug(oldOpps.get(j.Opportunity__c).get('StageName'));
            System.debug(newOpps.get(j.Opportunity__c).get('StageName'));
            if(oldOpps.get(j.Opportunity__c).get('StageName') != 'Closed Won' && newOpps.get(j.Opportunity__c).get('StageName') == 'Closed Won') {
                System.debug('updating date won');
                j.Date_Won__c = d;
            }
        }
        update junctions;
    }
}
