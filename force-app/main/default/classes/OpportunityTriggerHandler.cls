/**
 * Note to come back and see if we still need this trigger handler and related trigger, OpportunityTrigger.
 */
public class OpportunityTriggerHandler {
    public static void afterInsert(Map<Id,SObject> newOpps) {

    }

    public static void afterUpdate(Map<Id,SObject> oldOpps, Map<Id,SObject> newOpps) {
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

    
}
