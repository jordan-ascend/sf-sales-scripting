@isTest
public class ScriptDisplayCtrl_Test {
    
    @TestSetup
    static void makeData(){
        Opportunity opp = AscendTestDataFactory.createOpportunity(null);

        AscendTestDataFactory.autoCommit = false;
        Sales_Rep_Script__c script1 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.Name => 'Script 1',
            Sales_Rep_Script__c.OpportunityType__c => 'New Customer'
        });
        Sales_Rep_Script__c script2 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.Name => 'Script 2',
            Sales_Rep_Script__c.Opportunity__c => opp.Id
        });
        AscendTestDataFactory.autoCommit = true;
    }

    static User getAdminUser() {
        User u = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        AscendTestDataFactory.assignPermissionSets(new Set<User>{u}, new Set<String>{'Script_Admin', 'Script_User'});
        return u;
    }

    @isTest
    static void testGetScript() {
        System.runAs(getAdminUser()) {
            Opportunity opp = [SELECT Id FROM Opportunity];
            Sales_Rep_Script__c script1 = [SELECT Id FROM Sales_Rep_Script__c WHERE Opportunity__c = :opp.Id];

            Test.startTest();
            Map<String,Sales_Rep_Script__c> scriptMap = ScriptDisplayController.getScript(opp.Id);
            Test.stopTest();

            System.assertEquals(script1.Id, scriptMap.get('Prospecting').Id, 'The correct script was not retreived or not at all.');
        }
    }

    @isTest
    static void testHandleMetric() {
        System.runAs(getAdminUser()) {
            Opportunity opp = [SELECT StageName, Type FROM Opportunity];
            Sales_Rep_Script__c script1 = [SELECT Id FROM Sales_Rep_Script__c WHERE Opportunity__c = :opp.Id];
            Test.startTest();
            MetricObjectHandler.handleMetricObject(opp, opp);
            Test.stopTest();

            Script_Metric__c metric = [SELECT Opportunity_Stage__c, Opportunity_Won__c, Scripts_Used__c FROM Script_Metric__c WHERE Opportunity__c = :opp.Id];

            System.assertEquals('Prospecting', metric.Opportunity_Stage__c, 'The correct opportunity stage was not recorded in the metric object.');
            System.assertEquals(false, metric.Opportunity_Won__c, 'The correct "opportunity won" state was not recorded in the metric object.');
            System.assertEquals(opp.StageName + ':' + script1.Id, metric.Scripts_Used__c, 'The correct opportunity stage name/script id pair was not recorded in the  metric object.');
        }
    }

    @isTest
    static void testHandleMetricWithUserId() {
        System.runAs(getAdminUser()) {
            Opportunity opp = [SELECT StageName, Type FROM Opportunity];
            Sales_Rep_Script__c script1 = [SELECT Id FROM Sales_Rep_Script__c WHERE Opportunity__c = :opp.Id];
            
            Test.startTest();
            MetricObjectHandler.handleMetricObject(opp, opp);
            script1.scriptUser__c = UserInfo.getUserId();
            update script1;
            MetricObjectHandler.handleMetricObject(opp, opp);
            MetricObjectHandler.handleMetricObject(opp, opp);
            Test.stopTest();
            
            System.debug('Opp Id: ' + opp.Id);
            System.debug('User Id: ' + UserInfo.getUserId());

            Script_Metric__c metric = [SELECT Opportunity_Stage__c, Opportunity_Won__c, Scripts_Used__c, Related_User__c FROM Script_Metric__c 
            WHERE Opportunity__c = :opp.Id AND Related_User__c = :UserInfo.getUserId()];

            System.assertEquals('Prospecting', metric.Opportunity_Stage__c, 'The correct opportunity stage was not recorded in the metric object.');
            System.assertEquals(false, metric.Opportunity_Won__c, 'The correct "opportunity won" state was not recorded in the metric object.');
            System.assertEquals(opp.StageName + ':' + script1.Id, metric.Scripts_Used__c, 'The correct opportunity stage name/script id pair was not recorded in the  metric object.');
            System.assertEquals(UserInfo.getUserId(), metric.Related_User__c,'The user Id was not recorded in the metric\'s related user field.');
            System.assertEquals(2, [SELECT Opportunity_Stage__c, Opportunity_Won__c, Scripts_Used__c, Related_User__c FROM Script_Metric__c].size(), 'Two metric objects should have been created.');
        }
    }

    // @isTest
    // static void testShouldButtonBeDisabled() {
    //     Opportunity opp = [SELECT StageName, Type FROM Opportunity];

    //     Test.startTest();
    //     MetricObjectHandler.handleMetricObject(opp);
    //     Boolean btnDisabled = ScriptDisplayController.shouldButtonBeDisabled(opp.Id);
    //     Test.stopTest();

    //     System.assert(btnDisabled, 'Button should be disabled, but isn\'t.');
    // }

    // @isTest
    // static void testShouldButtonBeDisabledNoScript() {
    //     Opportunity opp = [SELECT StageName, Type FROM Opportunity];

    //     Test.startTest();
    //     MetricObjectHandler.handleMetricObject(opp);
    //     opp.StageName = 'Qualification';
    //     update opp;
    //     Boolean btnDisabled = ScriptDisplayController.shouldButtonBeDisabled(opp.Id);
    //     Test.stopTest();

    //     System.assert(btnDisabled, 'Button should be disabled, but isn\'t.');
    // }

    // @isTest
    // static void testShouldButtonBeDisabledFalse() {
    //     Opportunity opp = [SELECT StageName FROM Opportunity];

    //     Test.startTest();
    //     Boolean btnDisabled = ScriptDisplayController.shouldButtonBeDisabled(opp.Id);
    //     Test.stopTest();

    //     System.assertEquals(false, btnDisabled, 'Button shouldn\'t be disabled, but is.');
    // }
}