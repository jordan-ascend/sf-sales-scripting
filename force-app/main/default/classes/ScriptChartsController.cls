/**
 * Copied from example for ChartJs. Will modify for our use.
 */
public with sharing class ScriptChartsController {
    @AuraEnabled(cacheable=true)
    public static List<ScriptChartsController.ScriptCount> getScriptsThatWin(Boolean capScripts) {
        return getScriptsThatWin(capScripts, null);
    }

    /**
     * Get stats for how many opportunities with each script. 
     * 
     * Parameters:
     * Boolean capScripts - Caps the number of ScriptChartsController.ScriptCount to top 10.
     * String keyword - Optional - Used to get metrics for scripts with names that contain keyword.
     */
    public static List<ScriptChartsController.ScriptCount> getScriptsThatWin(Boolean capScripts, String keyword){
        List<Opporunity_Script_Junction__c> juncts;
        if(
            Opporunity_Script_Junction__c.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.Opporunity_Script_Junction__c.fields.Sales_Rep_Script__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Name.isAccessible() &&
            Schema.SObjectType.Opporunity_Script_Junction__c.fields.Sales_Rep_Script__c.isAccessible()
        ) {
            if(String.isNotBlank(keyword)) {
                juncts = [SELECT Sales_Rep_Script__r.Name, Sales_Rep_Script__c FROM Opporunity_Script_Junction__c WHERE Opporunity_Won__c = true AND Sales_Rep_Script__r.Name LIKE :('%'+keyword+'%')];
            } else {
                juncts = [SELECT Sales_Rep_Script__r.Name, Sales_Rep_Script__c FROM Opporunity_Script_Junction__c WHERE Opporunity_Won__c = true];
            }
        }
        
        Map<String,ScriptChartsController.ScriptCount> junctionMap = new Map<String,ScriptChartsController.ScriptCount>();
        List<ScriptChartsController.ScriptCount> scriptCntObj = new List<ScriptChartsController.ScriptCount>();

        for(Opporunity_Script_Junction__c j: juncts) {
            System.debug(j.Sales_Rep_Script__r.Name);
            if(junctionMap.get(j.Sales_Rep_Script__r.Name) == null) {
                ScriptChartsController.ScriptCount cntObj = new ScriptChartsController.ScriptCount();
                cntObj.count = 1;
                cntObj.name = j.Sales_Rep_Script__r.Name;
                cntObj.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + j.Sales_Rep_Script__c;
                junctionMap.put(j.Sales_Rep_Script__r.Name, cntObj);
            }
            else {
                junctionMap.get(j.Sales_Rep_Script__r.Name).count++;
            }
        }
        
        System.debug(junctionMap.values());
        scriptCntObj = junctionMap.values();
        scriptCntObj.sort();
        System.debug(scriptCntObj);
        // Capping the number of bars on the bar graph to 10.
        if(capScripts) {
            List<ScriptChartsController.ScriptCount> subset = (List<ScriptChartsController.ScriptCount>)AscendUtils.slice(scriptCntObj, 0, 10);
            System.debug(subset);
            return subset;
        } 
        return scriptCntObj;
    }

    /**
     * Gets stats for a specific page of a paginated table based on how many records are on the page.
     * 
     * Parameters:
     * Integer pageNumber - The page to get records for.
     * Integer recordsPerPage - The number of records viewable on a page. Accounts for if number of records does not fill page.
     * String keyword - Optional - Used to get metrics for scripts with names that contain keyword.
     */
    @AuraEnabled(cacheable=true)
    public static List<ScriptChartsController.ScriptCount> getScriptsThatWinForTable(Integer pageNumber, Integer recordsPerPage, String keyword) {
        List<ScriptChartsController.ScriptCount> counts = getScriptsThatWin(false, keyword);

        if(counts.isEmpty()) {
            return counts;
        }
        
        Integer numberOfPages = counts.size() / recordsPerPage;
        if(Math.mod(counts.size(), recordsPerPage) != 0) {
            numberOfPages++;
        }

        Integer stopIndex = recordsPerPage * pageNumber;
        Integer startIndex = stopIndex - recordsPerPage;
        stopIndex = stopIndex > counts.size() ? counts.size() : stopIndex;

        List<ScriptChartsController.ScriptCount> newCounts = (List<ScriptChartsController.ScriptCount>)AscendUtils.slice(counts, startIndex, stopIndex);

        for(ScriptChartsController.ScriptCount c: newCounts) {
            c.totalPages = numberOfPages;
            c.totalRecords = counts.size();
        }
        
        return newCounts;
    }

    /**
     * Gets stats for combinations of scripts that lead to an opportunity being won. I.e. Scripts A, B, and C for stages 
     * prospecting, qualification, and proposal where used in ten opportunities that went on to be won.
     * 
     * Parameters:
     * Boolean capScripts - Caps the number of ScriptChartsController.ScriptCount to top 10.
     */
    @AuraEnabled(cacheable=true)
    public static List<ScriptChartsController.AggregatedScriptCount> getAggregatedScripts(Boolean capScripts) {
        List<ScriptChartsController.AggregatedScriptCount> aggrScrCount = new List<ScriptChartsController.AggregatedScriptCount>();
        List<AggregateResult> metricsAggregate;
        if(
            Script_Metric__c.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.Script_Metric__c.fields.Scripts_Used__c.isAccessible()
        ) {
            metricsAggregate = [SELECT Scripts_Used__c scriptsUsed, COUNT(Id)cnt FROM Script_Metric__c WHERE Opportunity_Won__c = true GROUP BY Scripts_Used__c ORDER BY COUNT(Id) DESC LIMIT 100];
        }
        Map<String,Integer> scriptsMap = new Map<String,Integer>();

        for (AggregateResult aggregate: metricsAggregate) {
            scriptsMap.put((String)aggregate.get('scriptsUsed'), (Integer)aggregate.get('cnt'));
        }

        Set<Id> scriptIds = new Set<Id>();
        for(String scriptListString: scriptsMap.keySet()) {
            List<String> stageScriptPairs = scriptListString.split(';');
            for(String pair: stageScriptPairs) {
                List<String> pairSplit = pair.split(':');
                scriptIds.add(pairSplit[1]);
            }
        }
        aggrScrCount = createAggrScrCount(scriptsMap, scriptIds);

        aggrScrCount.sort();

        if(capScripts) {
            List<ScriptChartsController.AggregatedScriptCount> subset = (List<ScriptChartsController.AggregatedScriptCount>)AscendUtils.slice(aggrScrCount, 0, 10);
            return subset;
        } 

        return aggrScrCount;
    }

    /**
     * creates List<ScriptChartsController.AggregatedScriptCount> for getAggregatedScripts().
     */
    private static List<ScriptChartsController.AggregatedScriptCount> createAggrScrCount(Map<String,Integer> scriptsMap, Set<Id> scriptIds) {
        List<ScriptChartsController.AggregatedScriptCount> aggrScrCount = new List<ScriptChartsController.AggregatedScriptCount>();
        List<Sales_Rep_Script__c> scripts = new List<Sales_Rep_Script__c>();
        if(
            Sales_Rep_Script__c.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Name.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Script__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.OpportunityStage__c.isAccessible()
        ) {
            scripts = [SELECT Name, Script__c, OpportunityStage__c FROM Sales_Rep_Script__c WHERE Id IN :scriptIds];
        }
        System.debug(scriptsMap.keySet());

        Integer increment = 1;
        for(String scriptListString: scriptsMap.keySet()) {
            ScriptChartsController.AggregatedScriptCount count = new ScriptChartsController.AggregatedScriptCount();

            count.count = scriptsMap.get(scriptListString);
            count.groupName = 'Set ' + increment++;
            count.namesAndUrls = new List<ScriptChartsController.NameAndURL>();

            List<String> stageScriptPairs = scriptListString.split(';');
            List<Id> scriptIdsHere = new List<Id>();
            for(String pair: stageScriptPairs) {
                List<String> pairSplit = pair.split(':');
                scriptIdsHere.add(pairSplit[1]);
            }

            for(Id scriptId: scriptIdsHere) {
                for(Sales_Rep_Script__c scr: scripts) {
                    if(scr.Id == scriptId) {
                        ScriptChartsController.NameAndURL nameAndUrl = new ScriptChartsController.NameAndURL();
                        nameAndUrl.name = scr.Name;
                        nameAndUrl.url =  '/' + scr.Id;
                        nameAndUrl.script = scr.Script__c;
                        nameAndUrl.stage = scr.OpportunityStage__c;
                        count.namesAndUrls.add(nameAndUrl);
                    }
                }
            }
            aggrScrCount.add(count);
        }

        return aggrScrCount;
    }

    public class ScriptCount implements Comparable{
        @AuraEnabled public String name;
        @AuraEnabled public Integer count;
        @AuraEnabled public String url;
        @auraEnabled public Integer totalPages;
        @auraEnabled public Integer totalRecords;

        public Integer compareTo(Object compareTo) {
            ScriptChartsController.ScriptCount scriptCntToComapre = (ScriptChartsController.ScriptCount)compareTo;
            if (count == scriptCntToComapre.count) {return 0;}
            if (count < scriptCntToComapre.count) {return 1;}
            return -1;
        }
    }

    public class AggregatedScriptCount implements Comparable{
        @AuraEnabled public String groupName;
        @AuraEnabled public List<ScriptChartsController.NameAndURL> namesAndUrls;
        @AuraEnabled public Integer count;
        
        public Integer compareTo(Object compareTo) {
            ScriptChartsController.AggregatedScriptCount scriptCntToComapre = (ScriptChartsController.AggregatedScriptCount)compareTo;
            if (count == scriptCntToComapre.count) {return 0;}
            if (count < scriptCntToComapre.count) {return 1;}
            return -1;
        }
    }

    public class NameAndURL {
        @AuraEnabled public String name;
        @AuraEnabled public String url;
        @AuraEnabled public String stage;
        @AuraEnabled public String script;
    }
}
