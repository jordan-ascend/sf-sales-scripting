public with sharing class MetricObjectHandler {
    /**
     * Handle creation or update of a Script_Metric__c record that will keep track of the scripts used for an opportunity
     */
    @AuraEnabled
    public static void handleMetricObject(Opportunity opp, Opportunity newOpp) {
        System.debug('Running after update.');
        ScriptHandler sh = new ScriptHandler(opp);
        
        List<Sales_Rep_Script__c> scripts = sh.getScriptObjects(opp.Type, opp.StageName);
        if(scripts == null || scripts.isEmpty()) {
            return;
        }
        Sales_Rep_Script__c script = ScriptDisplayController.getMostSpecific(scripts);
        System.debug(script.Name);

        upsertMetric(opp, newOpp, script);
        upsertJunctionObject(opp, newOpp, script);
    } 

    private static Script_Metric__c setCommonFieldAssignments(Script_Metric__c metric, Opportunity opp, Opportunity newOpp, Sales_Rep_Script__c script) {
        if(metric == null) {
            metric = new Script_Metric__c();
        }
        if(metric.Opportunity__c == null) {
            metric.Opportunity__c = opp.Id;
        }
        metric.Opportunity_Stage__c = newOpp.StageName;
        metric.Scripts_Used__c = AscendUtils.addToDelimitedSet(metric.Scripts_Used__c, opp.StageName + ':' + script.Id, ';');
        if(newOpp.StageName == 'Closed Won') {
            metric.Opportunity_Won__c = true;
        }
        else {
            metric.Opportunity_Won__c = false;
        }
        return metric;
    } 

    private static void upsertMetric(Opportunity opp, Opportunity newOpp, Sales_Rep_Script__c script) {
        Script_Metric__c metric = ScriptDisplayController.getMetricRecord(opp.Id);

        if(metric == null) { 

            metric = setCommonFieldAssignments(metric, opp, newOpp, script);
            if(script.scriptUser__c == UserInfo.getUserId()) {
                metric.Related_User__c = script.scriptUser__c;
            }

            if(Script_Metric__c.sObjectType.getDescribe().isCreateable()) {
                insert metric;
            }
        } else if(metric != null && metric.Related_User__c == null && script.scriptUser__c == UserInfo.getUserId()) {

            Script_Metric__c newMetric = setCommonFieldAssignments(null, opp, newOpp, script);
            newMetric.Related_User__c = script.scriptUser__c;
            if(Script_Metric__c.sObjectType.getDescribe().isCreateable()) {
                insert newMetric;
            }
        } else {
            metric = setCommonFieldAssignments(metric, opp, newOpp, script);
            if(Script_Metric__c.sObjectType.getDescribe().isUpdateable()) {
                update metric;
            }
        }
    }

    private static void upsertJunctionObject(Opportunity opp, Opportunity newOpp, Sales_Rep_Script__c script) {
        Opporunity_Script_Junction__c junct = ScriptDisplayController.getJunctionRecord(opp.Id, script.Id);
        
        if(junct == null) {
            junct = new Opporunity_Script_Junction__c();
            junct.Date_Won__c = getCloseWonDate(opp.StageName, newOpp.StageName, opp.Id);
            junct.Opporunity_Stage__c = opp.StageName;
            junct.Opportunity__c = opp.Id;
            junct.Sales_Rep_Script__c = script.Id;
            if(Opporunity_Script_Junction__c.sObjectType.getDescribe().isCreateable()) {
                insert junct;
            }
        }
        else if(junct != null && junct.Related_User_Id__c == null && script.scriptUser__c == UserInfo.getUserId()) {
            junct = new Opporunity_Script_Junction__c();
            junct.Date_Won__c = getCloseWonDate(opp.StageName, newOpp.StageName, opp.Id);
            junct.Opporunity_Stage__c = opp.StageName;
            junct.Opportunity__c = opp.Id;
            junct.Sales_Rep_Script__c = script.Id;
            if(Opporunity_Script_Junction__c.sObjectType.getDescribe().isCreateable()) {
                insert junct;
            }
        }
        else {
            // Date d = Date.today();
            // if(opp.StageName != 'Closed Won' && newOpp.StageName == 'Closed Won') {
            //     junct.Date_Won__c = d;
            // }
            junct.Date_Won__c = getCloseWonDate(opp.StageName, newOpp.StageName, opp.Id);
            junct.Opporunity_Stage__c = opp.StageName;
            if(Opporunity_Script_Junction__c.sObjectType.getDescribe().isUpdateable()) {
                update junct;
            }
        }
    }

    private static Date getCloseWonDate(String stageName, String newStageName, Id oppId) {
        if(stageName != 'Closed Won' && newStageName == 'Closed Won') {
            Date d = Date.today();
            // If the opportunity is won, then we need to update all junction records related to opp to have to update their Date_Won__c.
            List<Opporunity_Script_Junction__c> junctList = [SELECT Id FROM Opporunity_Script_Junction__c WHERE Opportunity__c = :oppId];
            for(Opporunity_Script_Junction__c junct: junctList) {
                junct.Date_Won__c = d;
            }
            update junctList;

            return d;
        }
        return null;
    } 
    
}