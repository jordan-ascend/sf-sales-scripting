public with sharing class MetricObjectHandler {
    /**
     * Handle creation or update of a Script_Metric__c record that will keep track of the scripts used for an opportunity
     */
    @AuraEnabled
    public static void handleMetricObject(Opportunity opp) {
        System.debug('Running after update.');
        
        // Id userId = UserInfo.getUserId();
        // String userRoleName = AscendUtils.getUserRoleFromId(UserInfo.getUserRoleId())?.Name;
        // userRoleName = userRoleName == null? '-- Any --' : userRoleName;

        ScriptHandler sh = new ScriptHandler(opp);
        
        // Opportunity opp = getOpportunity(oppId);
        
        List<Sales_Rep_Script__c> scripts = sh.getScriptObjects(opp.Type, opp.StageName);
        if(scripts.isEmpty()) {
            return;
        }
        Sales_Rep_Script__c script = ScriptDisplayController.getMostSpecific(scripts);
        
        Script_Metric__c metric = ScriptDisplayController.getMetricRecord(opp.Id);

        if(metric == null) {
            metric = new Script_Metric__c();
            metric.Opportunity__c = opp.Id;
            metric.Opportunity_Stage__c = opp.StageName;
            metric.Scripts_Used__c = AscendUtils.addToDelimitedSet(metric.Scripts_Used__c, opp.StageName + ':' + script.Id, ';');
            if(opp.StageName == 'Closed Won') {
                metric.jgaude__Opportunity_Won__c = true;
            }
            else {
                metric.jgaude__Opportunity_Won__c = false;
            }
            if(script.scriptUser__c == UserInfo.getUserId()) {
                metric.Related_User__c = script.scriptUser__c;
            }

            if(Script_Metric__c.sObjectType.getDescribe().isCreateable()) {
                insert metric;
            }
        } else if(metric != null && metric.Related_User__c == null && script.scriptUser__c == UserInfo.getUserId()) {
            Script_Metric__c newMetric = new Script_Metric__c();
            newMetric.Opportunity__c = opp.Id;
            newMetric.Opportunity_Stage__c = opp.StageName;
            newMetric.Scripts_Used__c = AscendUtils.addToDelimitedSet(metric.Scripts_Used__c, opp.StageName + ':' + script.Id, ';');
            newMetric.Related_User__c = script.scriptUser__c;
            if(opp.StageName == 'Closed Won') {
                newMetric.jgaude__Opportunity_Won__c = true;
            }
            else {
                newMetric.jgaude__Opportunity_Won__c = false;
            }
            if(Script_Metric__c.sObjectType.getDescribe().isCreateable()) {
                insert newMetric;
            }
        } else {
            metric.Opportunity_Stage__c = opp.StageName;
            metric.Scripts_Used__c = AscendUtils.addToDelimitedSet(metric.Scripts_Used__c, opp.StageName + ':' + script.Id, ';');
            if(opp.StageName == 'Closed Won') {
                metric.jgaude__Opportunity_Won__c = true;
            }
            else {
                metric.jgaude__Opportunity_Won__c = false;
            }
            if(Script_Metric__c.sObjectType.getDescribe().isUpdateable()) {
                update metric;
            }
        }

        Opporunity_Script_Junction__c junct = ScriptDisplayController.getJunctionRecord(opp.Id, script.Id);
        
        if(junct == null) {
            junct = new Opporunity_Script_Junction__c();
            junct.Opporunity_Stage__c = opp.StageName;
            junct.Opportunity__c = opp.Id;
            junct.Sales_Rep_Script__c = script.Id;
            if(Opporunity_Script_Junction__c.sObjectType.getDescribe().isCreateable()) {
                insert junct;
            }
        }
        else if(junct != null && junct.Related_User_Id__c == null && script.scriptUser__c == UserInfo.getUserId()) {
            junct = new Opporunity_Script_Junction__c();
            junct.Opporunity_Stage__c = opp.StageName;
            junct.Opportunity__c = opp.Id;
            junct.Sales_Rep_Script__c = script.Id;
            if(Opporunity_Script_Junction__c.sObjectType.getDescribe().isCreateable()) {
                insert junct;
            }
        }
        else {
            junct.Opporunity_Stage__c = opp.StageName;
            if(Opporunity_Script_Junction__c.sObjectType.getDescribe().isUpdateable()) {
                update junct;
            }
        }

    }
    
}
