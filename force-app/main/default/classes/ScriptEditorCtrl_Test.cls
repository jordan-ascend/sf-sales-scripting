@isTest
public class ScriptEditorCtrl_Test {
    @TestSetup
    static void makeData(){
        Account acc = AscendTestDataFactory.createAccount(new Map<SObjectField,Object>{Account.Name => 'Test Acc'});
        AscendTestDataFactory.autoCommit = false;
        AscendTestDataFactory.createUser(new Map<SObjectField,Object>{User.FirstName => 'John', User.LastName => 'Doe'});
        AscendTestDataFactory.createOpportunity(new Map<SObjectField,Object>{
            Opportunity.Name => 'Test Opp', 
            Opportunity.StageName => 'Prospecting',
            Opportunity.AccountId => acc.Id
        });
        AscendTestDataFactory.autoCommit = true;
    }

    static ScriptEditorController getScriptCtrl() {
        User u = [SELECT id FROM User WHERE Email LIKE 'testUser%'];

        ScriptEditorController ctrl = new ScriptEditorController();
        ctrl.scriptObject.Name = 'Preamble to the Constitution';
        ctrl.scriptObject.Script__c = getScriptMessage();
        ctrl.scriptObject.OpportunityStage__c = ctrl.getStageList()[0].getValue();
        ctrl.scriptObject.OpportunityType__c = ctrl.getOppTypeList()[0].getValue();
        ctrl.scriptObject.UserRole__c = ctrl.getUserRoleList()[0].getValue();
        ctrl.scriptObject.scriptUser__c = u.Id;
        ctrl.Active = true;
        return ctrl;
    }

    @isTest
    static void createScript() {
        Test.startTest();
        ScriptEditorController ctrl = getScriptCtrl();
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

    @isTest
    static void createScriptTemplate() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // ScriptTemplateHandler hndlr = new ScriptTemplateHandler();
        String interpMsg;

        Test.startTest();
        ScriptEditorController ctrl = getScriptCtrl();
        ctrl.scriptObject.Script__c = 'Opp name: {Opportunity.Name} Account name: {Opportunity.Account.Name}';
        ctrl.scriptObject.OpportunityStage__c = 'Prospecting';
        ctrl.saveScript();

        Sales_Rep_Script__c scriptObject = [SELECT Name, Script__c, OpportunityStage__c, OpportunityType__c, UserRole__c, scriptUser__c FROM Sales_Rep_Script__c WHERE Id = :ctrl.scriptObject.Id];
        interpMsg = ScriptTemplateHandler.interpolateScript(scriptObject.Script__c, opp.Id);
        Test.stopTest();

        System.assertEquals('Preamble to the Constitution', scriptObject.Name);
        System.assertEquals('Opp name: Test Opp Account name: Test Acc', interpMsg);
    }

    @isTest
    static void createScriptTemplateUnauthorizedTag() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // ScriptTemplateHandler hndlr = new ScriptTemplateHandler();
        String interpMsg;

        Test.startTest();
        ScriptEditorController ctrl = getScriptCtrl();
        ctrl.scriptObject.Script__c = '{Opportunity.Description}';
        ctrl.scriptObject.OpportunityStage__c = 'Prospecting';
        ctrl.saveScript();

        Integer scriptObjectCount = [SELECT Id FROM Sales_Rep_Script__c].size();
        Test.stopTest();

        System.assertEquals(0, scriptObjectCount);
        System.assert(ctrl.tagsToAdd.contains('{Opportunity.Description}'));
        System.assertEquals(true, ctrl.displayModel);
        System.assertEquals(true, ctrl.showToAddList);

        ctrl.closeModal();

        System.assert(ctrl.tagsToAdd.isEmpty());
    }

    @isTest
    static void testSaveNewTags() {
        Test.startTest();
        ScriptEditorController ctrl = getScriptCtrl();
        ctrl.tagsToAdd.add('{TestTest.TestTest}');
        ctrl.saveNewTags();
        MetadataCallback m = new MetadataCallback();
        Metadata.DeployResult dr = new Metadata.DeployResult();
        Metadata.DeployCallbackContext dcc = new Metadata.DeployCallbackContext();
        m.handleResult(dr, dcc);
        Test.stopTest();
        // Can't assert that custom metadata has been deployed.
    }

    @isTest
    static void testInvalidTags() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        // ScriptTemplateHandler hndlr = new ScriptTemplateHandler();
        String interpMsg;

        Test.startTest();
        ScriptEditorController ctrl = getScriptCtrl();
        ctrl.scriptObject.Script__c = '{Invalid.Description}{Opportunity.Invalid} {Opportunity.Description__r} {Opportunity.Account__c.Name} {Opportunity.Description.Too.Many} {Opportunity} {Opportunity.Account.invalid}';
        ctrl.scriptObject.OpportunityStage__c = 'Prospecting';
        ctrl.saveScript();

        Integer scriptObjectCount = [SELECT Id FROM Sales_Rep_Script__c].size();
        Test.stopTest();

        System.assertEquals(0, scriptObjectCount);
        System.assert(ctrl.invalidTags.contains('{Invalid.Description}'));
        System.assert(ctrl.invalidTags.contains('{Opportunity.Invalid}'));
        System.assert(ctrl.invalidTags.contains('{Opportunity.Description__r}'));
        System.assert(ctrl.invalidTags.contains('{Opportunity.Account__c.Name}'));
        System.assert(ctrl.invalidTags.contains('{Opportunity.Description.Too.Many}'));
        System.assert(ctrl.invalidTags.contains('{Opportunity.Account.invalid}'));
        System.assert(ctrl.invalidTags.contains('{Opportunity}'));
        System.assertEquals(true, ctrl.displayModel);

        ctrl.closeModal();

        System.assert(ctrl.tagsToAdd.isEmpty());
    }

    static String getScriptMessage() {
        return '<div style="text-align: center;"><b><u>Preamble to the Constitution</u></b><br> </div><div>          '+
        'We the People of the United States, in Order to form a more perfect Union, establish Justice, insure domestic '+
        'Tranquility, provide for the common defense, promote the general Welfare, and secure the Blessings of Liberty '+
        'to ourselves and our Posterity, do ordain and establish this Constitution for the United States of America.</div>';
    }
}