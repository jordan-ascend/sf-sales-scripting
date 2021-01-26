@isTest
public class ScriptEditorCtrl_Test {
    @TestSetup
    static void makeData(){
        AscendTestDataFactory.autoCommit = false;
        AscendTestDataFactory.createUser(new Map<SObjectField,Object>{User.FirstName => 'John', User.LastName => 'Doe'});
        AscendTestDataFactory.autoCommit = true;
    }

    @isTest
    static void createScript() {
        User u = [SELECT id FROM User WHERE Email LIKE 'testUser%'];

        Test.startTest();
        ScriptEditorController ctrl = new ScriptEditorController();
        ctrl.scriptObject.Name = 'Preamble to the Constitution';
        ctrl.scriptObject.Script__c = getScriptMessage();
        ctrl.scriptObject.OpportunityStage__c = ctrl.getStageList()[0].getValue();
        ctrl.scriptObject.OpportunityType__c = ctrl.getOppTypeList()[0].getValue();
        ctrl.scriptObject.UserRole__c = ctrl.getUserRoleList()[0].getValue();
        ctrl.scriptObject.scriptUser__c = u.Id;
        ctrl.saveScript();
        Test.stopTest();

        Sales_Rep_Script__c scriptObject = [SELECT Name, Script__c, OpportunityStage__c, OpportunityType__c, UserRole__c, scriptUser__c FROM Sales_Rep_Script__c WHERE Id = :ctrl.scriptObject.Id];
        System.debug(scriptObject.Name);
        System.debug(scriptObject.Script__c);
        System.debug(scriptObject.OpportunityStage__c);
        System.debug(scriptObject.OpportunityType__c);
        System.debug(scriptObject.UserRole__c);
        System.debug(scriptObject.scriptUser__c);
        System.assertEquals('Preamble to the Constitution', scriptObject.Name);
    }

    static String getScriptMessage() {
        return '<div style="text-align: center;"><b><u>Preamble to the Constitution</u></b><br> </div><div>          '+
        'We the People of the United States, in Order to form a more perfect Union, establish Justice, insure domestic '+
        'Tranquility, provide for the common defense, promote the general Welfare, and secure the Blessings of Liberty '+
        'to ourselves and our Posterity, do ordain and establish this Constitution for the United States of America.</div>';
    }
}