@isTest
public class ScriptChartsController_Test {
    
    @TestSetup
    static void makeData(){
        AscendTestDataFactory.autoCommit = false;
        List<Opportunity> opps = AscendTestDataFactory.createOpportunities(3, new Map<SObjectField,Object>{Opportunity.StageName => 'Closed Won'});
        Sales_Rep_Script__c script = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.Name => 'Script1'
        });
        Sales_Rep_Script__c script2 = AscendTestDataFactory.createScript(new Map<SObjectField,Object>{
            Sales_Rep_Script__c.OpportunityStage__c => 'Qualification',
            Sales_Rep_Script__c.Name => 'Script2'
        });
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
        Sales_Rep_Script__c script = [SELECT Name FROM Sales_Rep_Script__c LIMIT 1];

        Test.startTest();
        List<ScriptChartsController.ScriptCount> count = ScriptChartsController.getScriptsThatWin(true);
        Test.stopTest();

        for(ScriptChartsController.ScriptCount c: count) {
            System.debug(c.count);
            System.debug(c.url);
            System.debug(c.name);
        }

        System.assertEquals(3, count[0].count, 'Should have three won opportunities for the script, but don\'t.');
        System.assertEquals(URL.getSalesforceBaseUrl().toExternalForm() + '/' + script.Id, count[0].url, 'Did not return the correct URL or not at all. Should be url to script.');
        System.assertEquals(script.Name, count[0].name, 'Didn\'t return correct script name.');
    }

    @isTest
    static void testGetAggregatedScripts() {
        User u = [SELECT Name FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
        AscendTestDataFactory.assignPermissionSets(new Set<User>{u}, new Set<String>{'Script_Admin', 'Script_User'});
        System.runAs(u) {
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
            System.assertEquals(1, count[0].count, 'The set of scripts should have one won opportunity.');
            System.assertEquals('Set 1', count[0].groupName, 'The group name for the set of scripts is not correct.');
            System.assertEquals(scripts[0].name, count[0].namesAndUrls[0].name, 'The name of the first script is not correct.');
            System.assertEquals('Prospecting', count[0].namesAndUrls[0].stage, 'The stage associated with the first script is not correct.');
            System.assert(count[0].namesAndUrls[0].url.contains(scripts[0].Id), 'The URL to the first script is not correct');
            System.assertEquals(scripts[1].name, count[0].namesAndUrls[1].name, 'The name of the second script is not correct.');
            System.assertEquals('Qualification', count[0].namesAndUrls[1].stage, 'The stage associated with the second script is not correct.');
            System.assert(count[0].namesAndUrls[1].url.contains(scripts[1].Id), 'The URL to the second script is not correct');
        }
    }

    @isTest
    static void testGetpaginatedList() {
        Test.startTest();
        List<ScriptChartsController.ScriptCount> count1PerPage = ScriptChartsController.getScriptsThatWinForTable(2, 1, null);
        List<ScriptChartsController.ScriptCount> count2PerPage = ScriptChartsController.getScriptsThatWinForTable(1, 2, null);
        List<ScriptChartsController.ScriptCount> countWithSearch = ScriptChartsController.getScriptsThatWinForTable(1, 2, 'Script2');
        Test.stopTest();

        // Testing one record per page, get page 2.
        System.assertEquals(1, count1PerPage.size(), 'There should be one record per page.');
        System.assertEquals(2, count1PerPage[0].totalPages, 'There should be two pages.');
        System.assertEquals('Script2', count1PerPage[0].Name, 'The name of the first record on page 2 should be "Script2".');
        System.assertEquals(2, count1PerPage[0].totalRecords, 'There should be two total records from all the pages.');

        // Testing two records per page, get page 1.
        System.assertEquals(2, count2PerPage.size(), 'There should be two records on this page.');
        System.assertEquals(1, count2PerPage[0].totalPages, 'There should be one page.');
        System.assertEquals('Script1', count2PerPage[0].Name, 'The name of the first record on page 1  should be "Script1".');
        System.assertEquals(2, count2PerPage[0].totalRecords, 'There should be two total records from all the pages.');

        // Test getting records with search word.
        System.assertEquals(1, countWithSearch.size(), 'There should be one record per page.');
        System.assertEquals(1, countWithSearch[0].totalPages, 'There should be one page.');
        System.assertEquals('Script2', countWithSearch[0].Name, 'The name of the first record on page 1 should be "Script2".');
        System.assertEquals(1, countWithSearch[0].totalRecords, 'There should be one record.');
    }
}
