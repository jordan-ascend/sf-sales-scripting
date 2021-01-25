public class SalesRepScriptTriggerHandler {
    public static void beforeInsert(List<SObject> newObjs) {
        validateUniqueScript(newObjs, null);
    }

    public static void beforeUpdate(Map<Id,SObject> oldObjs,List<SObject> newObjs) {
        List<Id> ids = new List<Id>();
        ids.addAll(oldObjs.keySet());
        validateUniqueScript(newObjs, ids);
    }

    /**
     * Will retrieve all scripts with UniqueKey__c in scriptKeys and none with an Id in scriptIds
     */
    public static List<jgaude__Sales_Rep_Script__c> getScripts(List<String> scriptKeys, List<Id> scriptIds) {
        List<jgaude__Sales_Rep_Script__c> scripts = new List<jgaude__Sales_Rep_Script__c>();
        scripts = [SELECT Name, jgaude__UniqueKey__c, jgaude__Active__c FROM jgaude__Sales_Rep_Script__c 
        WHERE jgaude__UniqueKey__c IN :scriptKeys AND Id NOT IN :scriptIds AND jgaude__Active__c = true];
        return scripts;
    }

    private static void validateUniqueScript(List<SObject> newTriggerObjs, List<Id> scriptIds) {
        List<Id> ids = new List<Id>();
        if(scriptIds == null || scriptIds.isEmpty())
            ids.add('');
        else
            ids.addAll(scriptIds);
        
        List<String> scriptKeys = new List<String>();
        for(SObject o: newTriggerObjs) {
            scriptKeys.add((String)o.get('jgaude__UniqueKey__c'));
        }

        for(SObject o: newTriggerObjs) {
            for(jgaude__Sales_Rep_Script__c existingScript: getScripts(scriptKeys, ids)) {
                if((String)o.get('jgaude__UniqueKey__c') == existingScript.jgaude__UniqueKey__c && (Boolean)o.get('Active__c')) {
                    o.addError('The script called "' + existingScript.Name + '" is already using the combination of filters that you are trying to select. ' +
                    'You must select a unique combination of filters, or mark this script or "' + existingScript.Name + '" as inactive.');
                }
            }
        }
    }
}