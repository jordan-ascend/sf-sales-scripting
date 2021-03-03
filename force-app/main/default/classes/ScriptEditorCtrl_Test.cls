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
        ctrl.scriptObject.Active__c = true;
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
        System.assertEquals('Preamble to the Constitution', scriptObject.Name, 'Script did not save correctly');
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

        System.assertEquals('Preamble to the Constitution', scriptObject.Name, 'Script did not save correctly');
        System.assertEquals('Opp name: Test Opp Account name: Test Acc', interpMsg, 'Script was not interpolated correctly');
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

        Set<String> tagsToAdd = ctrl.getTagsToAdd();
        Boolean displayModel = ctrl.getDisplayModel();

        System.assertEquals(0, scriptObjectCount, 'A script was created when is should not have been.');
        System.assert(tagsToAdd.contains('{Opportunity.Description}'), 'Invalid tag was not caught when save was attemped.');
        System.assertEquals(true, displayModel, 'displayModel boolean should be true');
        System.assertEquals(true, ctrl.showToAddList, 'showToAddList boolean should be true');

        ctrl.closeModal();

        System.assert(ctrl.tagsToAdd.isEmpty(), 'Script was not interpolated correctly');
    }

    @isTest
    static void testSaveNewTags() {
        Test.startTest();
        try {
            ScriptEditorController ctrl = getScriptCtrl();
            ctrl.tagsToAdd.add('{TestTest.TestTest}');
            ctrl.saveNewTags();
            MetadataCallback m = new MetadataCallback();
            Metadata.DeployResult dr = new Metadata.DeployResult();
            Metadata.DeployCallbackContext dcc = new Metadata.DeployCallbackContext();
            m.handleResult(dr, dcc);
        } catch(Exception e) {
            System.assert(false, e.getMessage());
        }

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

        Set<String> tagsToAdd = ctrl.getTagsToAdd();
        Set<String> invalidTags = ctrl.getInvalidTags();
        Boolean displayModel = ctrl.getDisplayModel();

        System.assertEquals(0, scriptObjectCount, 'A script was created when is should not have been.');
        System.assert(invalidTags.contains('{Invalid.Description}'), 'Interpolator did not catch a tag that is valid but not accepted');
        System.assert(invalidTags.contains('{Opportunity.Invalid}'), 'Interpolator did not catch a tag with an invalid field');
        System.assert(invalidTags.contains('{Opportunity.Description__r}'), 'Interpolator did not catch a tag with bad relationship syntax');
        System.assert(invalidTags.contains('{Opportunity.Account__c.Name}'), 'Interpolator did not catch a tag with bad relationship syntax');
        System.assert(invalidTags.contains('{Opportunity.Description.Too.Many}'), 'Interpolator did not catch a tag with to many changed relationship fields');
        System.assert(invalidTags.contains('{Opportunity.Account.invalid}'), 'Interpolator did not catch a tag with invalid relationship field');
        System.assert(invalidTags.contains('{Opportunity}'), 'Interpolator did not catch a tag with invalid relationship field');
        System.assertEquals(true, displayModel, 'displayModel boolean should be true');

        ctrl.closeModal();

        System.assert(tagsToAdd.isEmpty(), 'Script was not interpolated correctly');
    }

    static String getScriptMessage() {
        return '<div style="text-align: center;"><b><u>Preamble to the Constitution</u></b><br> </div><div>          '+
        'We the People of the United States, in Order to form a more perfect Union, establish Justice, insure domestic '+
        'Tranquility, provide for the common defense, promote the general Welfare, and secure the Blessings of Liberty '+
        'to ourselves and our Posterity, do ordain and establish this Constitution for the United States of America.</div>';
    }
}