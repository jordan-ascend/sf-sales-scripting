@isTest
public class ScriptDisplayCtrl_Test {
    
    @TestSetup
    static void makeData(){
        Opportunity opp = AscendTestDataFactory.createOpportunity(null);

        AscendTestDataFactory.autoCommit = false;
        Sales_Rep_Script__c script1 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.OpportunityType__c => 'New Customer'
        });
        Sales_Rep_Script__c script2 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.Opportunity__c => opp.Id
        });
        AscendTestDataFactory.autoCommit = true;
    }

    @isTest
    static void testGetScript() {
        Opportunity opp = [SELECT Id FROM Opportunity];
        Sales_Rep_Script__c script1 = [SELECT Id FROM Sales_Rep_Script__c WHERE Opportunity__c = :opp.Id];

        Test.startTest();
        Map<String,Sales_Rep_Script__c> scriptMap = ScriptDisplayController.getScript(opp.Id);
        Test.stopTest();

        System.assertEquals(script1.Id, scriptMap.get('Prospecting').Id);
    }

    @isTest
    static void testHandleMetric() {
        Opportunity opp = [SELECT StageName, Type FROM Opportunity];
        Sales_Rep_Script__c script1 = [SELECT Id FROM Sales_Rep_Script__c WHERE Opportunity__c = :opp.Id];
        Test.startTest();
        ScriptDisplayController.handleMetricObject(opp);
        Test.stopTest();

        Script_Metric__c metric = [SELECT Opportunity_Stage__c, Opportunity_Won__c, Scripts_Used__c FROM Script_Metric__c WHERE Opportunity__c = :opp.Id];

        System.assertEquals('Prospecting', metric.Opportunity_Stage__c);
        System.assertEquals(false, metric.Opportunity_Won__c);
        System.assertEquals(opp.StageName + ':' + script1.Id, metric.Scripts_Used__c);
    }

    @isTest
    static void testHandleMetricWithUserId() {
        Opportunity opp = [SELECT StageName, Type FROM Opportunity];
        Sales_Rep_Script__c script1 = [SELECT Id FROM Sales_Rep_Script__c WHERE Opportunity__c = :opp.Id];
        
        Test.startTest();
        ScriptDisplayController.handleMetricObject(opp);
        script1.scriptUser__c = UserInfo.getUserId();
        update script1;
        ScriptDisplayController.handleMetricObject(opp);
        script1.scriptUser__c = null;
        update script1;
        ScriptDisplayController.handleMetricObject(opp);
        Test.stopTest();

        Script_Metric__c metric = [SELECT Opportunity_Stage__c, Opportunity_Won__c, Scripts_Used__c, Related_User__c FROM Script_Metric__c 
        WHERE Opportunity__c = :opp.Id AND Related_User__c = :UserInfo.getUserId()];

        System.assertEquals('Prospecting', metric.Opportunity_Stage__c);
        System.assertEquals(false, metric.Opportunity_Won__c);
        System.assertEquals(opp.StageName + ':' + script1.Id, metric.Scripts_Used__c);
        System.assertEquals(UserInfo.getUserId(), metric.Related_User__c);
        System.assertEquals(2, [SELECT Opportunity_Stage__c, Opportunity_Won__c, Scripts_Used__c, Related_User__c FROM Script_Metric__c].size());
    }

    @isTest
    static void testShouldButtonBeDisabled() {
        Opportunity opp = [SELECT StageName, Type FROM Opportunity];

        Test.startTest();
        ScriptDisplayController.handleMetricObject(opp);
        Boolean btnDisabled = ScriptDisplayController.shouldButtonBeDisabled(opp.Id);
        Test.stopTest();

        System.assert(btnDisabled);
    }

    @isTest
    static void testShouldButtonBeDisabledNoScript() {
        Opportunity opp = [SELECT StageName, Type FROM Opportunity];

        Test.startTest();
        ScriptDisplayController.handleMetricObject(opp);
        opp.StageName = 'Qualification';
        update opp;
        Boolean btnDisabled = ScriptDisplayController.shouldButtonBeDisabled(opp.Id);
        Test.stopTest();

        System.assert(btnDisabled);
    }

    @isTest
    static void testShouldButtonBeDisabledFalse() {
        Opportunity opp = [SELECT StageName FROM Opportunity];

        Test.startTest();
        Boolean btnDisabled = ScriptDisplayController.shouldButtonBeDisabled(opp.Id);
        Test.stopTest();

        System.assertEquals(false, btnDisabled);
    }
}
