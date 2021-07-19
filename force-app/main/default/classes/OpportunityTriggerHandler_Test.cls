@isTest
public class OpportunityTriggerHandler_Test {
    
    @TestSetup
    static void makeData(){
        Sales_Rep_Script__c script = AscendTestDataFactory.createScript(null);
        Sales_Rep_Script__c script2 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.OpportunityStage__c => 'Qualification'
        });
        Opportunity opp = AscendTestDataFactory.createOpportunity(null);
        Script_Metric__c metric = new Script_Metric__c(
            Opportunity__c = opp.Id,
            Scripts_Used__c = opp.StageName + ':' + script.Id,
            Opportunity_Stage__c = 'Prospecting'
        );
        Opporunity_Script_Junction__c junct = new Opporunity_Script_Junction__c(
            Opportunity__c = opp.Id,
            Sales_Rep_Script__c = script.Id,
            Opporunity_Stage__c = 'Prospecting'
        );
        //Opporunity_Script_Junction__c junct2 = new Opporunity_Script_Junction__c(
        //    Opportunity__c = opp.Id,
        //    Sales_Rep_Script__c = script.Id,
        //    Opporunity_Stage__c = 'Closed Won'
        //);
        insert new List<SObject>{metric, junct};
    }

    static User getAdminUser() {
        User u = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        AscendTestDataFactory.assignPermissionSets(new Set<User>{u}, new Set<String>{'Script_Admin', 'Script_User'});
        return u;
    }

    @isTest
    static void testFirePlatformEvent() {
        System.runAs(getAdminUser()) {
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

            Test.startTest();
            opp.StageName = 'Qualification';
            update opp;
            Test.stopTest();

            List<Opportunity_Listen__e> olList = OpportunityTriggerHandler.events;

            System.assertEquals(1, olList.size(), 'One Opportunity_Listen__e should have been created');
            System.assertEquals('Stage updated.', olList[0].Message__c, 'Event\'s message should be "Stage updated."');
            System.assertEquals('Qualification', olList[0].Stage__c, 'Event\'s stage should be "Qualification"');
            System.assertEquals(String.valueOf(opp.Id),olList[0].OpportunityId__c, 'Event\'s opportunity Id stored does not match the Id of the opportunity updated.');
        }
    }

    @isTest
    static void testUpdateMetricObject() {
        System.runAs(getAdminUser()) {
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

            Test.startTest();
            opp.StageName = 'Qualification';
            update opp;

            Script_Metric__c metric = [SELECT Opportunity_Won__c FROM Script_Metric__c LIMIT 1];
            System.assertEquals(false, metric.Opportunity_Won__c, 'The metric should record false for Opportunity_Won__c');

            opp.StageName = 'Closed Won';
            update opp;
            Test.stopTest();

            metric = [SELECT Opportunity_Won__c FROM Script_Metric__c LIMIT 1];
            System.assertEquals(true, metric.Opportunity_Won__c, 'The metric should record true for Opportunity_Won__c');
        }
    }

    @isTest 
    static void testUpdateScriptJunction() {
        System.runAs(getAdminUser()) {
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

            Test.startTest();
            opp.StageName = 'Qualification';
            update opp;

            Opporunity_Script_Junction__c junct = [SELECT Date_Won__c, Opporunity_Won__c FROM Opporunity_Script_Junction__c LIMIT 1];
            System.assertEquals(false, junct.Opporunity_Won__c, 'The junction should record false for Opporunity_Won__c');
            System.assertEquals(null, junct.Date_Won__c, 'A date should only be set when the opportunity is won.');

            opp.StageName = 'Closed Won';
            update opp;
            Test.stopTest();

            junct = [SELECT Date_Won__c, Opporunity_Won__c FROM Opporunity_Script_Junction__c][1];
            System.assertEquals(true, junct.Opporunity_Won__c, 'The junction should record true for Opporunity_Won__c');
            System.assertEquals(Date.today(), junct.Date_Won__c, 'A date should only be set when the opportunity is won.');
        }
    }

}