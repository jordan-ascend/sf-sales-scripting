@isTest
public class ScriptDisplayController_Test {

    @TestSetup
    static void makeData(){
        User u = AscendTestDataFactory.createUser(new Map<SObjectField,Object>{User.FirstName => 'John', User.LastName => 'Doe'});

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Script_User'];
        System.runas(new User(ID = UserInfo.getUserID())) {
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps.Id, AssigneeId = u.Id);
            insert psa;
        }
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
        Map<String,Sales_Rep_Script__c> scriptMap = ScriptDisplayController.getScript(opp.Id);
        Test.stopTest();

        System.assertEquals('Script 1', scriptMap.get('Prospecting').Name, 'Script 1 should have been selected but was not.');
    }

    @isTest
    static void getScriptWithUser() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        User u = [SELECT Id FROM User WHERE Email LIKE 'testUser%'];

        Map<String,Sales_Rep_Script__c> scriptMap;
        System.runAs(u) {
            Test.startTest();
            scriptMap = ScriptDisplayController.getScript(opp.Id);
            Test.stopTest();
        }

        System.assertEquals('Script 2', scriptMap.get('Prospecting').Name, 'Script 2 should have been selected but was not.');
    }
}