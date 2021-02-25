/**
 * TODO: Write tests.
 */
public class ScriptDisplayController {

    /**
     * Retreives script for opportunity.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String,jgaude__Sales_Rep_Script__c> getScript(Id oppId) {
        Id userId = UserInfo.getUserId();
        String userRoleName = AscendUtils.getUserRoleFromId(UserInfo.getUserRoleId())?.Name;
        userRoleName = userRoleName == null? '-- Any --' : userRoleName;
        Opportunity opp = getOpportunity(oppId);

        String oppType = opp.Type == null? '-- Any --' : opp.Type;

        List<Sales_Rep_Script__c> scripts = getScriptObjects(oppId, userId, userRoleName, oppType);
        Map<String,List<Sales_Rep_Script__c>> buckets = putScriptsInBuckets(scripts);
        Map<String,Sales_Rep_Script__c> scriptsMap = new Map<String,Sales_Rep_Script__c>();
        for(String oppStage: buckets.keyset()) {
            scriptsMap.put(oppStage, getMostSpecific(buckets.get(oppStage)));
        }
        // Sales_Rep_Script__c scriptToDeliver = getMostSpecific(scripts);
        for(String oppStage: scriptsMap.keyset()) {
            Sales_Rep_Script__c temp = scriptsMap.get(oppStage);
            temp.Script__c = ScriptTemplateHandler.interpolateScript(temp.Script__c, oppId);
            scriptsMap.put(oppStage, temp);
        }
        // scriptToDeliver.Script__c = ScriptTemplateHandler.interpolateScript(scriptToDeliver.Script__c, oppId);
        // System.debug(scriptToDeliver);
        // return scriptToDeliver;
        System.debug(scriptsMap);
        return scriptsMap;
    }

    /**
     * Looks at the metric object to see if this script has already been read (the 'read' button has been clicked). If so, 
     * then grey out the button.
     */
    @AuraEnabled//(cacheable=true)
    public static boolean shouldButtonBeDisabled(Id oppId) {
        System.debug('Checking if button should be disabled...');
        Id userId = UserInfo.getUserId();
        String userRoleName = AscendUtils.getUserRoleFromId(UserInfo.getUserRoleId())?.Name;
        userRoleName = userRoleName == null? '-- Any --' : userRoleName;

        Script_Metric__c metric = getMetricRecord(oppId);
        if(metric == null || metric.Scripts_Used__c == null)
            return false;
        Opportunity opp = getOpportunity(oppId);
        List<Sales_Rep_Script__c> scripts = getScriptObjects(oppId, userId, userRoleName, opp.Type, opp.StageName);
        if(scripts.isEmpty())
            return true;
        Sales_Rep_Script__c script = getMostSpecific(scripts);
        System.debug(metric.Scripts_Used__c.contains(opp.StageName + ':' + script.Id));
        System.debug(opp.StageName + ':' + script.Id);
        return metric.Scripts_Used__c.contains(opp.StageName + ':' + script.Id);
    }

    // @AuraEnabled(cacheable=true)
    // public static jgaude__Sales_Rep_Script__c getNewScript(Id oppId) {
    //     System.debug(oppId);
    //     return getScript(oppId);
    // }

    @AuraEnabled
    public static String getOppStage(Id oppId) {
        System.debug(oppId);
        Opportunity opp = getOpportunity(oppId);
        return opp.StageName;
    }

    /**
     * Returns a list of scripts that the current user is assigned to. If none of them are, then we return the original list.
     * If any are for other users then we want to remove those before returning.
     * Because if none of the scripts are associated with the user then we assume that the are for any user.
     */
    // private static List<Sales_Rep_Script__c> getScriptsWithUser(List<Sales_Rep_Script__c> scripts) {
    //     List<Sales_Rep_Script__c> matchingScripts = new List<Sales_Rep_Script__c>();

    //     for(Sales_Rep_Script__c script: scripts) {
    //         if(script.scriptUser__c != null) 
    //             matchingScripts.add(script);
    //     }

    //     if(matchingScripts.isEmpty()) {
    //         return scripts;
    //     }

    //     return matchingScripts;
    // }

    /**
     * Returns the script with the most specific requirements given. I.e. A script with both a user role and an opp type
     * is more specific than a script with just a user role. Each script is given points based off this. Points start at 1 so 
     * the first script will have 3 points and the second will have 2 points. The script or scripts with the most points will
     * be returned.
     */
    private static Sales_Rep_Script__c getMostSpecific(List<Sales_Rep_Script__c> scripts) {
        Map<Sales_Rep_Script__c,Integer> scriptMap = new Map<Sales_Rep_Script__c,Integer>();
        Sales_Rep_Script__c mostSpecificScript = new Sales_Rep_Script__c();
        mostSpecificScript.Script__c = 'No script for this stage.';

        /**
         * Points are awarded for how high of a priority a filter is. Right now Assigning a user to a script is the highest 
         * priority. That should not be eclipsed. With the points below, no script with any combination of filters can take a 
         * higher priority than a script that specifies a user. It also allows for tie breakers. If there are two scripts that
         * have an assigned user, one with an assigned opportunity, the other with an assigned user role, the one with the 
         * opportunity will beat out the one with the user role.
         * 
         * Note for later, will need to require the combination of filters for a script unique iff the script is active
         * Another note for later, create "Active" field for script object.
         * 
         * These point values are determined in powers of two with the exception of the initializer. Which means we can possibly 
         * make this process dynamic with a list of filters, their priority in order of increasing index, then we can assign
         * point values to them with (index)^2. 
         * 
         * This could also allow for the application's users to set the priority of different filters to their needs.
         */
        for(Sales_Rep_Script__c script: scripts) {
            Integer i = 1;
            if(script.scriptUser__c != null)
                i+=8;
            if(script.Opportunity__c != null)
                i+=4;
            if(script.UserRole__c != '-- Any --')
                i+=2;
            if(script.OpportunityType__c != '-- Any --')
                i+=1;
            scriptMap.put(script, i);
        }

        Integer largestNumber = 0;
        for(Sales_Rep_Script__c script: scriptMap.keyset()) {
            if(scriptMap.get(script) > largestNumber) {
                largestNumber = scriptMap.get(script);
                mostSpecificScript = script;
            }            
        }

        return mostSpecificScript;
    }

    private static List<Sales_Rep_Script__c> getScriptObjects(Id oppId, Id userId, String userRoleName, String oppType) {
        return [SELECT Name, Script__c, scriptUser__c, UserRole__c, Opportunity__c, OpportunityType__c, OpportunityStage__c
                FROM Sales_Rep_Script__c 
                WHERE /*OpportunityStage__c = :stage AND*/ (scriptUser__c = :userId OR scriptUser__c = null)
                AND (Opportunity__c =: OppId OR Opportunity__c = null)
                AND (UserRole__c = :userRoleName OR UserRole__c = '-- Any --')
                AND (OpportunityType__c = :oppType OR OpportunityType__c = '-- Any --')];
    }

    private static List<Sales_Rep_Script__c> getScriptObjects(Id oppId, Id userId, String userRoleName, String oppType, String stage) {
        return [SELECT Name, Script__c, scriptUser__c, UserRole__c, Opportunity__c, OpportunityType__c, OpportunityStage__c
                FROM Sales_Rep_Script__c 
                WHERE OpportunityStage__c = :stage AND (scriptUser__c = :userId OR scriptUser__c = null)
                AND (Opportunity__c =: OppId OR Opportunity__c = null)
                AND (UserRole__c = :userRoleName OR UserRole__c = '-- Any --')
                AND (OpportunityType__c = :oppType OR OpportunityType__c = '-- Any --')];
    }

    private static Opportunity getOpportunity(Id OppId) {
        return [SELECT StageName, Type FROM Opportunity WHERE Id = :OppId];
    }

    /**
     * Sort scripts into buckets based on what opportunity stage they are for.
     */
    private static Map<String,List<Sales_Rep_Script__c>> putScriptsInBuckets(List<Sales_Rep_Script__c> scripts) {
        Map<String,List<Sales_Rep_Script__c>> buckets = new Map<String,List<Sales_Rep_Script__c>>();
        for(Sales_Rep_Script__c script: scripts) {
            if(buckets.get(script.OpportunityStage__c) == null) {
                buckets.put(script.OpportunityStage__c, new List<Sales_Rep_Script__c>{script});
            }
            else {
                buckets.get(script.OpportunityStage__c).add(script);
            }
        }
        return buckets;
    }

    /**
     * Handle creation or update of a Script_Metric__c record that will keep track of the scripts used for an opportunity
     */
    @AuraEnabled
    public static void handleMetricObject(Opportunity opp) {
        System.debug('Running after update.');
        
        Id userId = UserInfo.getUserId();
        String userRoleName = AscendUtils.getUserRoleFromId(UserInfo.getUserRoleId())?.Name;
        userRoleName = userRoleName == null? '-- Any --' : userRoleName;
        
        // Opportunity opp = getOpportunity(oppId);
        
        List<Sales_Rep_Script__c> scripts = getScriptObjects(opp.Id, userId, userRoleName, opp.Type, opp.StageName);
        if(scripts.isEmpty())
            return;
        
        Sales_Rep_Script__c script = getMostSpecific(scripts);
        
        Script_Metric__c metric = getMetricRecord(opp.Id);

        if(metric == null) {
            metric = new Script_Metric__c();
            metric.Opportunity__c = opp.Id;
            metric.Opportunity_Stage__c = opp.StageName;
            metric.Scripts_Used__c = AscendUtils.addToDelimitedSet(metric.Scripts_Used__c, opp.StageName + ':' + script.Id, ';');
            if(opp.StageName == 'Closed Won')
                metric.jgaude__Opportunity_Won__c = true;
            else
                metric.jgaude__Opportunity_Won__c = false;
            if(script.scriptUser__c == UserInfo.getUserId())
                metric.Related_User__c = script.scriptUser__c;

            insert metric;
        } else if(metric != null && metric.Related_User__c == null && script.scriptUser__c == UserInfo.getUserId()) {
            Script_Metric__c newMetric = new Script_Metric__c();
            newMetric.Opportunity__c = opp.Id;
            newMetric.Opportunity_Stage__c = opp.StageName;
            newMetric.Scripts_Used__c = AscendUtils.addToDelimitedSet(metric.Scripts_Used__c, opp.StageName + ':' + script.Id, ';');
            newMetric.Related_User__c = script.scriptUser__c;
            if(opp.StageName == 'Closed Won')
                newMetric.jgaude__Opportunity_Won__c = true;
            else
                newMetric.jgaude__Opportunity_Won__c = false;
            insert newMetric;
        } else {
            metric.Opportunity_Stage__c = opp.StageName;
            metric.Scripts_Used__c = AscendUtils.addToDelimitedSet(metric.Scripts_Used__c, opp.StageName + ':' + script.Id, ';');
            if(opp.StageName == 'Closed Won')
                metric.jgaude__Opportunity_Won__c = true;
            else
                metric.jgaude__Opportunity_Won__c = false;
            
            update metric;
        }

        Opporunity_Script_Junction__c junct = getJunctionRecord(opp.Id, script.Id);
        
        if(junct == null) {
            junct = new Opporunity_Script_Junction__c();
            junct.Opporunity_Stage__c = opp.StageName;
            junct.Opportunity__c = opp.Id;
            junct.Sales_Rep_Script__c = script.Id;
            insert junct;
        }
        else if(junct != null && junct.Related_User_Id__c == null && script.scriptUser__c == UserInfo.getUserId()) {
            junct = new Opporunity_Script_Junction__c();
            junct.Opporunity_Stage__c = opp.StageName;
            junct.Opportunity__c = opp.Id;
            junct.Sales_Rep_Script__c = script.Id;
            insert junct;
        }
        else {
            junct.Opporunity_Stage__c = opp.StageName;
            update junct;
        }

    }

    /**
     * Will try to retrieve a metric object, if there is one associated with this user (i.e. the user is looking at a script 
     * for him or her specifically) then it will return that one. Otherwise return one not associated with a user, there 
     * should only be one per opportunity. There can also be one metric per user per opportunity.
     */
    private static Opporunity_Script_Junction__c getJunctionRecord(Id oppId, Id scriptId) {
        List<Opporunity_Script_Junction__c> oppScriptJuncts = [SELECT Opporunity_Stage__c, Related_User__c, Related_User_Id__c, Sales_Rep_Script__r.Name, Sales_Rep_Script__c FROM Opporunity_Script_Junction__c 
        WHERE Opportunity__c = :oppId AND Sales_Rep_Script__c = :scriptId];
        Opporunity_Script_Junction__c junct;

        // We should only find one of these per user per opportunity or one without a user per opportunity.
        for(Opporunity_Script_Junction__c j: oppScriptJuncts) {
            if(j.Related_User_Id__c  == UserInfo.getUserId()) {
                junct = j;
                break;
            } else if(j.Related_User__c == null) {
                junct = j;
            }
        }

        return junct;
    }

    /**
     * Will try to retrieve a metric object, if there is one associated with this user (i.e. the user is looking at a script 
     * for him or her specifically) then it will return that one. Otherwise return one not associated with a user, there 
     * should only be one per opportunity. There can also be one metric per user per opportunity.
     */
    private static Script_Metric__c getMetricRecord(Id oppId) {
        List<Script_Metric__c> metrics = [SELECT Related_User__c, Scripts_Used__c FROM Script_Metric__c WHERE Opportunity__c = :oppId];
        Script_Metric__c metric;
        
        // We should only find one of these per user per opportunity or one without a user per opportunity.
        for(Script_Metric__c m: metrics) {
            if(m.Related_User__c == UserInfo.getUserId()) {
                metric = m;
                break;
            } else if(m.Related_User__c == null) {
                metric = m;
            }
        }

        return metric;
    }
}