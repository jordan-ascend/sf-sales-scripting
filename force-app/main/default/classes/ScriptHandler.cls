public with sharing class ScriptHandler {
    private Id userId;
    private String userRoleName;
    private Opportunity opp;

    public ScriptHandler(Opportunity opp) {
        if(opp.Id == null) {
            throw new ScriptHandlerException('Opportunity must have Id.');
        }
        this.opp = opp;
        this.userId = UserInfo.getUserId();
        this.userRoleName = AscendUtils.getUserRoleFromId(UserInfo.getUserRoleId())?.Name;
        this.userRoleName = this.userRoleName == null? '-- Any --' : this.userRoleName;
    }

    public List<Sales_Rep_Script__c> getScriptObjects(String oppType) {
        List<Sales_Rep_Script__c> scripts;
        if(
            Sales_Rep_Script__c.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Name.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Script__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.scriptUser__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.UserRole__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Opportunity__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.OpportunityType__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.OpportunityStage__c.isAccessible()
        ) {
            scripts = [SELECT Name, Script__c, scriptUser__c, UserRole__c, Opportunity__c, OpportunityType__c, OpportunityStage__c
                FROM Sales_Rep_Script__c 
                WHERE /*OpportunityStage__c = :stage AND*/ (scriptUser__c = :this.userId OR scriptUser__c = null)
                AND (Opportunity__c =: this.opp.Id OR Opportunity__c = null)
                AND (UserRole__c = :this.userRoleName OR UserRole__c = '-- Any --')
                AND (OpportunityType__c = :oppType OR OpportunityType__c = '-- Any --')];
        }
        return scripts;
    }

    public List<Sales_Rep_Script__c> getScriptObjects(String oppType, String stage) {
        List<Sales_Rep_Script__c> scripts;
        if(
            Sales_Rep_Script__c.SObjectType.getDescribe().isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Name.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Script__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.scriptUser__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.UserRole__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.Opportunity__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.OpportunityType__c.isAccessible() &&
            Schema.SObjectType.Sales_Rep_Script__c.fields.OpportunityStage__c.isAccessible()
        ) {
        scripts = [SELECT Name, Script__c, scriptUser__c, UserRole__c, Opportunity__c, OpportunityType__c, OpportunityStage__c
                FROM Sales_Rep_Script__c 
                WHERE OpportunityStage__c = :stage AND (scriptUser__c = :this.userId OR scriptUser__c = null)
                AND (Opportunity__c =: this.opp.Id OR Opportunity__c = null)
                AND (UserRole__c = :this.userRoleName OR UserRole__c = '-- Any --')
                AND (OpportunityType__c = :oppType OR OpportunityType__c = '-- Any --')];
        }
        return scripts;
    }
}
