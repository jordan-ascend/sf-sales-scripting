/**
 * Copied from example for ChartJs. Will modify for our use.
 */
public class ScriptChartsController {
    @AuraEnabled(cacheable=true)
    public static List<ScriptChartsController.ScriptCount> getScriptsThatWin(Boolean capScripts){

        List<Opporunity_Script_Junction__c> juncts = [SELECT Sales_Rep_Script__r.Name, Sales_Rep_Script__c FROM Opporunity_Script_Junction__c WHERE Opporunity_Won__c = true];
        
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

    @AuraEnabled(cacheable=true)
    public static List<ScriptChartsController.AggregatedScriptCount> getAggregatedScripts(Boolean capScripts) {
        List<ScriptChartsController.AggregatedScriptCount> aggrScrCount = new List<ScriptChartsController.AggregatedScriptCount>();
        List<AggregateResult> metricsAggregate = [SELECT Scripts_Used__c scriptsUsed, COUNT(Id)cnt FROM Script_Metric__c GROUP BY Scripts_Used__c ORDER BY COUNT(Id) DESC LIMIT 100];
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

        List<Sales_Rep_Script__c> scripts = new List<Sales_Rep_Script__c>();
        scripts = [SELECT Name, Script__c FROM Sales_Rep_Script__c WHERE Id = :scriptIds];

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
                        count.namesAndUrls.add(nameAndUrl);
                        // count.names.add(scr.Name);
                        // count.urls.add(URL.getSalesforceBaseUrl().toExternalForm() + '/' + scr.Id);
                    }
                }
            }
            aggrScrCount.add(count);
        }

        aggrScrCount.sort();

        if(capScripts) {
            List<ScriptChartsController.AggregatedScriptCount> subset = (List<ScriptChartsController.AggregatedScriptCount>)AscendUtils.slice(aggrScrCount, 0, 10);
            return subset;
        } 

        return aggrScrCount;
    }

    public class ScriptCount implements Comparable{
        @AuraEnabled public String name;
        @AuraEnabled public Integer count;
        @AuraEnabled public String url;

        public Integer compareTo(Object compareTo) {
            ScriptChartsController.ScriptCount scriptCntToComapre = (ScriptChartsController.ScriptCount)compareTo;
            if (count == scriptCntToComapre.count) return 0;
            if (count < scriptCntToComapre.count) return 1;
            return -1;
        }
    }

    public class AggregatedScriptCount implements Comparable{
        @AuraEnabled public String groupName;
        @AuraEnabled public List<ScriptChartsController.NameAndURL> namesAndUrls;
        @AuraEnabled public Integer count;
        
        public Integer compareTo(Object compareTo) {
            ScriptChartsController.AggregatedScriptCount scriptCntToComapre = (ScriptChartsController.AggregatedScriptCount)compareTo;
            if (count == scriptCntToComapre.count) return 0;
            if (count < scriptCntToComapre.count) return 1;
            return -1;
        }
    }

    public class NameAndURL {
        @AuraEnabled public String name;
        @AuraEnabled public String url;
        @AuraEnabled public String script;
    }
}
