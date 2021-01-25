public class ScriptDisplayController {
    public ScriptDisplayController() {}

    @AuraEnabled(cacheable=true)
    public static jgaude__Sales_Rep_Script__c getScript(Id OppId) {
        System.debug(UserInfo.getUserId());
        System.debug(UserInfo.getUserName());
        // System.debug(userRoleName);

        Id userId = UserInfo.getUserId();
        String userRoleName = AscendUtils.getUserRoleFromId(UserInfo.getUserRoleId())?.Name;
        userRoleName = userRoleName == null? '-- Any --' : userRoleName;
        Opportunity opp = getOpportunity(OppId);

        
        System.debug(opp);
        System.debug(opp.Type);
        System.debug(opp.StageName);
        
        List<jgaude__Sales_Rep_Script__c> scripts = getScriptObjects(oppId, userId, userRoleName, opp.Type, opp.StageName);
        jgaude__Sales_Rep_Script__c scriptToDeliver = getMostSpecific(scripts);

        // for(jgaude__Sales_Rep_Script__c script: scripts)
        //     System.debug(script);
        // List<jgaude__Sales_Rep_Script__c> scripts = getScriptObjects(opp.StageName);
        // if(scripts.isEmpty())
        //     return null;
        System.debug(scriptToDeliver);
        return scriptToDeliver;
    }

    /**
     * Returns a list of scripts that the current user is assigned to. If none of them are, then we return the original list.
     * If any are for other users then we want to remove those before returning.
     * Because if none of the scripts are associated with the user then we assume that the are for any user.
     */
    private static List<jgaude__Sales_Rep_Script__c> getScriptsWithUser(List<jgaude__Sales_Rep_Script__c> scripts) {
        List<jgaude__Sales_Rep_Script__c> matchingScripts = new List<jgaude__Sales_Rep_Script__c>();

        for(jgaude__Sales_Rep_Script__c script: scripts) {
            if(script.jgaude__scriptUser__c != null) 
                matchingScripts.add(script);
        }

        if(matchingScripts.isEmpty()) {
            return scripts;
        }

        return matchingScripts;
    }

    /**
     * Returns the script with the most specific requirements given. I.e. A script with both a user role and an opp type
     * is more specific than a script with just a user role. Each script is given points based off this. Points start at 1 so 
     * the first script will have 3 points and the second will have 2 points. The script or scripts with the most points will
     * be returned.
     */
    private static jgaude__Sales_Rep_Script__c getMostSpecific(List<jgaude__Sales_Rep_Script__c> scripts) {
        Map<jgaude__Sales_Rep_Script__c,Integer> scriptMap = new Map<jgaude__Sales_Rep_Script__c,Integer>();
        jgaude__Sales_Rep_Script__c mostSpecificScript = new jgaude__Sales_Rep_Script__c();
        mostSpecificScript.jgaude__Script__c = 'No script for this stage.';

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
        for(jgaude__Sales_Rep_Script__c script: scripts) {
            Integer i = 1;
            if(script.jgaude__scriptUser__c != null)
                i+=8;
            if(script.jgaude__Opportunity__c != null)
                i+=4;
            if(script.jgaude__UserRole__c != '-- Any --')
                i+=2;
            if(script.jgaude__OpportunityType__c != '-- Any --')
                i+=1;
            scriptMap.put(script, i);
        }

        Integer largestNumber = 0;
        for(jgaude__Sales_Rep_Script__c script: scriptMap.keyset()) {
            if(scriptMap.get(script) > largestNumber) {
                largestNumber = scriptMap.get(script);
                mostSpecificScript = script;
            }            
        }

        return mostSpecificScript;
    }

    private static List<jgaude__Sales_Rep_Script__c> getHighestPriorirtyScript(List<jgaude__Sales_Rep_Script__c> scripts) {
        scripts = getScriptsWithUser(scripts);
        scripts = getScriptsForOpp(scripts);
        return scripts;
    }

    /**
     * Get a list of scripts that the opportunity is related to. 
     * If none are related to the opportunity then return the original list.
     * If any are for other opporunities then we want to remove those before returning.
     */
    private static List<jgaude__Sales_Rep_Script__c> getScriptsForOpp(List<jgaude__Sales_Rep_Script__c> scripts) {
        List<jgaude__Sales_Rep_Script__c> matchingScripts = new List<jgaude__Sales_Rep_Script__c>();

        for(jgaude__Sales_Rep_Script__c script: scripts) {
            if(script.jgaude__Opportunity__c != null) 
                matchingScripts.add(script);
        }

        if(matchingScripts.isEmpty()) {
            return scripts;
        }
            
        return matchingScripts;
    }

    private static List<jgaude__Sales_Rep_Script__c> getScriptObjects(Id oppId, Id userId, String userRoleName, String oppType, String stage) {
        return [SELECT Name, jgaude__Script__c, jgaude__scriptUser__c, jgaude__UserRole__c, jgaude__Opportunity__c, jgaude__OpportunityType__c
                FROM jgaude__Sales_Rep_Script__c 
                WHERE jgaude__OpportunityStage__c = :stage AND (jgaude__scriptUser__c = :userId OR jgaude__scriptUser__c = null)
                AND (jgaude__Opportunity__c =: OppId OR jgaude__Opportunity__c = null)
                AND (jgaude__UserRole__c = :userRoleName OR jgaude__UserRole__c = '-- Any --')
                AND (jgaude__OpportunityType__c = :oppType OR jgaude__OpportunityType__c = '-- Any --')];
    }

    private static Opportunity getOpportunity(Id OppId) {
        return [SELECT StageName, Type FROM Opportunity WHERE Id = :OppId];
    }
}
