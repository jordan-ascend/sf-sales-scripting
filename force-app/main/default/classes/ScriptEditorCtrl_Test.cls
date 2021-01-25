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
        ctrl.scriptObject.jgaude__Script__c = getScriptMessage();
        ctrl.scriptObject.jgaude__OpportunityStage__c = ctrl.getStageList()[0].getValue();
        ctrl.scriptObject.jgaude__OpportunityType__c = ctrl.getOppTypeList()[0].getValue();
        ctrl.scriptObject.jgaude__UserRole__c = ctrl.getUserRoleList()[0].getValue();
        ctrl.scriptObject.jgaude__scriptUser__c = u.Id;
        ctrl.saveScript();
        Test.stopTest();

        jgaude__Sales_Rep_Script__c scriptObject = [SELECT Name, jgaude__Script__c, jgaude__OpportunityStage__c, jgaude__OpportunityType__c, jgaude__UserRole__c, jgaude__scriptUser__c FROM jgaude__Sales_Rep_Script__c WHERE Id = :ctrl.scriptObject.Id];
        System.debug(scriptObject.Name);
        System.debug(scriptObject.jgaude__Script__c);
        System.debug(scriptObject.jgaude__OpportunityStage__c);
        System.debug(scriptObject.jgaude__OpportunityType__c);
        System.debug(scriptObject.jgaude__UserRole__c);
        System.debug(scriptObject.jgaude__scriptUser__c);
        System.assertEquals('Preamble to the Constitution', scriptObject.Name);
    }

    static String getScriptMessage() {
        return '<div style="text-align: center;"><b><u>Preamble to the Constitution</u></b><br> </div><div>          '+
        'We the People of the United States, in Order to form a more perfect Union, establish Justice, insure domestic '+
        'Tranquility, provide for the common defense, promote the general Welfare, and secure the Blessings of Liberty '+
        'to ourselves and our Posterity, do ordain and establish this Constitution for the United States of America.</div>';
    }
}