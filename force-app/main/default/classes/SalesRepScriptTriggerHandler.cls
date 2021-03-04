public with sharing class SalesRepScriptTriggerHandler {
    public static void beforeInsert(List<SObject> newObjs) {
        System.debug('Checkpoint 1');
        validateUniqueScript(newObjs, new List<Id>());
        // validateTemplateTags(newObjs);
    }

    public static void beforeUpdate(Map<Id,SObject> oldObjs,List<SObject> newObjs) {
        List<Id> ids = new List<Id>();
        ids.addAll(oldObjs.keySet());
        validateUniqueScript(newObjs, ids);
        // validateTemplateTags(newObjs);
    }

    /**
     * Will retrieve all scripts with UniqueKey__c in scriptKeys and none with an Id in scriptIds
     */
    public static List<Sales_Rep_Script__c> getScripts(List<String> scriptKeys, List<Id> scriptIds) {
        List<Sales_Rep_Script__c> scripts = new List<Sales_Rep_Script__c>();
        if(
            Sales_Rep_Script__c.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Name.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Active__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.UniqueKey__c.isAccessible()
        ) {
            scripts = [SELECT Name, UniqueKey__c, Active__c FROM Sales_Rep_Script__c 
            WHERE UniqueKey__c IN :scriptKeys AND Id NOT IN :scriptIds AND Active__c = true];
        }
        return scripts;
    }

    // private static void validateTemplateTags(List<SObject> newTriggerObjs) {
    //     Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    //     for(SObject o: newTriggerObjs) {
    //         try{
    //             ScriptTemplateHandler.interpolateScript((String)o.get('Script__c'), opp.Id);
    //         } catch(ScriptInterpolationException e) {
    //             System.debug(e.getMessage());
    //             o.addError(e.getMessage() + ' Error thorwn.');
    //         } catch(Exception e) {
    //             System.debug(e.getMessage() + '\n' + e.getStackTraceString());
    //             o.addError(e.getMessage() + '\n' + e.getStackTraceString());
    //         }
    //     }
    // }

    private static void validateUniqueScript(List<SObject> newTriggerObjs, List<Id> scriptIds) {
        System.debug('Checkpoint 2');
        List<String> scriptKeys = new List<String>();
        for(SObject o: newTriggerObjs) {
            scriptKeys.add((String)o.get('UniqueKey__c'));
        }

        for(SObject o: newTriggerObjs) {
            for(Sales_Rep_Script__c existingScript: getScripts(scriptKeys, scriptIds)) {
                if((String)o.get('UniqueKey__c') == existingScript.UniqueKey__c && (Boolean)o.get('Active__c')) {
                    o.addError('The script called "' + existingScript.Name + '" is already using the combination of filters that you are trying to select. ' +
                    'You must select a unique combination of filters, or mark this script or "' + existingScript.Name + '" as inactive.');
                }
            }
        }
    }
}
