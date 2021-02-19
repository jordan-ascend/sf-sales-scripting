@isTest
public class ScriptDisplayController_Test {

    @TestSetup
    static void makeData(){
        User u = AscendTestDataFactory.createUser(new Map<SObjectField,Object>{User.FirstName => 'John', User.LastName => 'Doe'});
        AscendTestDataFactory.autoCommit = false;
        AscendTestDataFactory.createOpportunity(null);
        AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.Name => 'Script 1',
            Sales_Rep_Script__c.Script__c => 'The script for the test opportunity {Opportunity.Name}'
        });
        AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.Name => 'Script 2',
            Sales_Rep_Script__c.scriptUser__c => u.Id,
            Sales_Rep_Script__c.Script__c => 'The script for the test opportunity {Opportunity.Name}'
        });
        AscendTestDataFactory.autoCommit = true;
    }
    
    @isTest
    static void getScript() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Sales_Rep_Script__c script = ScriptDisplayController.getScript(opp.Id);
        Test.stopTest();

        System.assertEquals('Script 1', script.Name);
    }

    @isTest
    static void getScriptWithUser() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        User u = [SELECT Id FROM User WHERE Email LIKE 'testUser%'];

        Sales_Rep_Script__c script;
        System.runAs(u) {
            Test.startTest();
            script = ScriptDisplayController.getScript(opp.Id);
            Test.stopTest();
        }

        System.assertEquals('Script 2', script.Name);
    }
}
