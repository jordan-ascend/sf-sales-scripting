@isTest
public class ScriptChartsController_Test {
    
    @TestSetup
    static void makeData(){
        AscendTestDataFactory.autoCommit = false;
        List<Opportunity> opps = AscendTestDataFactory.createOpportunities(3, new Map<SObjectField,Object>{Opportunity.StageName => 'Closed Won'});
        Sales_Rep_Script__c script = AscendTestDataFactory.createScript(null);
        Sales_Rep_Script__c script2 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{Sales_Rep_Script__c.OpportunityStage__c => 'Qualification'});
        AscendTestDataFactory.autoCommit = true;

        List<Opporunity_Script_Junction__c> juncts = new List<Opporunity_Script_Junction__c>();
        for(Opportunity opp: opps) {
            Opporunity_Script_Junction__c j = new Opporunity_Script_Junction__c();
            j.Opportunity__c = opp.Id;
            j.Sales_Rep_Script__c = script.Id;
            j.Opporunity_Stage__c = 'Closed Won';
            juncts.add(j);
        }
        Opporunity_Script_Junction__c j = new Opporunity_Script_Junction__c();
        j.Opportunity__c = opps[0].Id;
        j.Sales_Rep_Script__c = script2.Id;
        j.Opporunity_Stage__c = 'Closed Won';
        juncts.add(j);
        insert juncts;

        Script_Metric__c obj = new Script_Metric__c(
            Opportunity__c = opps[0].Id,
            Opportunity_Stage__c = 'Closed Won',
            Opportunity_Won__c = true,
            Scripts_Used__c = script.OpportunityStage__c + ':' + script.Id + ';' + script2.OpportunityStage__c + ':' + script2.Id
        );
        insert obj;
    }

    @isTest
    static void testGetScriptsThatWin() {
        Sales_Rep_Script__c script = [SELECT Id FROM Sales_Rep_Script__c LIMIT 1];

        Test.startTest();
        List<ScriptChartsController.ScriptCount> count = ScriptChartsController.getScriptsThatWin(true);
        Test.stopTest();

        for(ScriptChartsController.ScriptCount c: count) {
            System.debug(c.count);
            System.debug(c.url);
            System.debug(c.name);
        }

        System.assertEquals(3, count[0].count);
        System.assertEquals(URL.getSalesforceBaseUrl().toExternalForm() + '/' + script.Id, count[0].url);
        System.assertEquals(script.Id, count[0].name);
    }

    @isTest
    static void testGetAggregatedScripts() {
        List<Sales_Rep_Script__c> scripts = [SELECT Name FROM Sales_Rep_Script__c];

        Test.startTest();
        List<ScriptChartsController.AggregatedScriptCount> count = ScriptChartsController.getAggregatedScripts(true);
        Test.stopTest();

        for(ScriptChartsController.AggregatedScriptCount c: count) {
            System.debug(c.count);
            System.debug(c.groupName);
            for(ScriptChartsController.NameAndURL nu: c.namesAndUrls) {
                System.debug(nu.name);
                System.debug(nu.stage);
                System.debug(nu.url);
            }
        }
        System.assertEquals(1, count[0].count);
        System.assertEquals('Set 1', count[0].groupName);
        System.assertEquals(scripts[0].name, count[0].namesAndUrls[0].name);
        System.assertEquals('Prospecting', count[0].namesAndUrls[0].stage);
        System.assert(count[0].namesAndUrls[0].url.contains(scripts[0].name));
        System.assertEquals(scripts[1].name, count[0].namesAndUrls[1].name);
        System.assertEquals('Qualification', count[0].namesAndUrls[1].stage);
        System.assert(count[0].namesAndUrls[1].url.contains(scripts[1].name));
    }
}
