/**
 * Copied from example for ChartJs. Will modify for our use.
 */
public class ScriptChartsController {
    @AuraEnabled(cacheable=true)
    public static List<ScriptChartsController.ScriptCount> getScriptsThatWin(Boolean capScripts){
        // List<AggregateResult> juncts = [SELECT COUNT(Id)cnt, jgaude__Sales_Rep_Script__r.Name, jgaude__Sales_Rep_Script__r.Id FROM jgaude__Opporunity_Script_Junction__c 
        //                                                 GROUP BY jgaude__Sales_Rep_Script__r.Name, jgaude__Sales_Rep_Script__r.Id ORDER BY COUNT(id) DESC];

        // for(AggregateResult aggr: juncts) {
        //     scriptCounts.put((String)aggr.get('jgaude__Sales_Rep_Script__r.Name'), (Integer)aggr.get('cnt'));
        // }

        List<Opporunity_Script_Junction__c> juncts = [SELECT Sales_Rep_Script__r.Name, Sales_Rep_Script__c FROM Opporunity_Script_Junction__c WHERE Opporunity_Won__c = true];
        
        // Map<String,List<Opporunity_Script_Junction__c>> junctionMap = new Map<String,List<Opporunity_Script_Junction__c>>();
        Map<String,ScriptChartsController.ScriptCount> junctionMap = new Map<String,ScriptChartsController.ScriptCount>();
        List<ScriptChartsController.ScriptCount> scriptCntObj = new List<ScriptChartsController.ScriptCount>();

        // for(Opporunity_Script_Junction__c j: juncts) {
        //     if(junctionMap.get(j.Sales_Rep_Script__r.Name) == null || junctionMap.get(j.Sales_Rep_Script__r.Name).isEmpty()) {
        //         junctionMap.put(j.Sales_Rep_Script__r.Name, new List<Opporunity_Script_Junction__c>{j});
        //     }
        //     else {
        //         junctionMap.get(j.Sales_Rep_Script__r.Name).add(j);
        //     }
        // }

        for(Opporunity_Script_Junction__c j: juncts) {
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
        
        // Map<String,Integer> scriptCounts = new Map<String,Integer>();
        // for(String scriptName: junctionMap.keySet()) {
        //     scriptCounts.put(scriptName, junctionMap.get(scriptName).size());
        // }
        // return scriptCounts;
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
}
