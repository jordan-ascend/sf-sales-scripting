public without sharing class ScriptEditorControllerHelper {

    /**
     * In general a script user is not allowed to create a script. The exception is when 
     * the user is "moddifying" the script to personalize it. In this case we are
     * duplicating the script and associating it with this user if a personalized one
     * does not already exist to be updated. This duplication requires a record to be
     * inserted.
     * 
     * The record can only be inserted buy a script user through the script editor page
     * and the scriptUser__c must the user's Id. 
     */
    public static void saveScript(Sales_Rep_Script__c script) {
        if(Sales_Rep_Script__c.sObjectType.getDescribe().isAccessible() &&
        (Sales_Rep_Script__c.sObjectType.getDescribe().isCreateable() || script.scriptUser__c == UserInfo.getUserId()) &&
        Sales_Rep_Script__c.sObjectType.getDescribe().isUpdateable()) {
            upsert script;
        }
    }
}
